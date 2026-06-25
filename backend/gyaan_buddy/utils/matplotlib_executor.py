"""
Execute matplotlib code (e.g. from Vertex Gemini) and return image as base64.

Used for question image generation when use_matplot is enabled.
Runs code in a subprocess with a timeout for safety.
"""

import base64
import logging
import re
import subprocess
import sys
import tempfile

logger = logging.getLogger('gyaan_buddy.matplotlib_executor')

# Regex patterns that match calls which might reveal answer values in the image.
# We strip full lines containing these calls for question images.
_ANSWER_REVEAL_PATTERNS = [
    # plt.title(...) / ax.set_title(...)
    re.compile(r'^\s*(plt\.title|ax\d*\.set_title)\s*\(.*\)\s*$', re.MULTILINE),
    # plt.xlabel / plt.ylabel with non-axis content (optional – keep axis labels)
    # plt.suptitle
    re.compile(r'^\s*plt\.suptitle\s*\(.*\)\s*$', re.MULTILINE),
    # plt.text / ax.text calls
    re.compile(r'^\s*(plt\.text|ax\d*\.text)\s*\(.*\)\s*$', re.MULTILINE),
    # ax.annotate calls
    re.compile(r'^\s*ax\d*\.annotate\s*\(.*\)\s*$', re.MULTILINE),
    # ax.set_xlabel / ax.set_ylabel  (keep plt.xlabel/ylabel for axes)
    # plt.figtext
    re.compile(r'^\s*plt\.figtext\s*\(.*\)\s*$', re.MULTILINE),
]


def sanitize_matplotlib_code(code: str) -> str:
    """
    Strip lines from matplotlib code that could render answer values or
    question text inside the figure.

    Removes: plt.title, ax.set_title, plt.suptitle, plt.text, ax.text,
    ax.annotate, plt.figtext.

    Multi-line calls (where closing ')' is on a later line) are also removed
    using a simple parenthesis-depth scan.
    """
    if not code:
        return code

    # First pass: remove complete single-line calls via regex
    cleaned = code
    for pattern in _ANSWER_REVEAL_PATTERNS:
        cleaned = pattern.sub('', cleaned)

    # Second pass: remove multi-line calls for the same functions
    _MULTILINE_STARTS = (
        'plt.title(', 'ax.set_title(', 'plt.suptitle(',
        'plt.text(', 'ax.text(', '.annotate(', 'plt.figtext(',
    )
    lines = cleaned.splitlines()
    result_lines = []
    skip_depth = 0
    for line in lines:
        stripped = line.lstrip()
        if skip_depth > 0:
            skip_depth += line.count('(') - line.count(')')
            if skip_depth <= 0:
                skip_depth = 0
            continue
        if any(stripped.startswith(fn) or f'.{fn.split(".")[-1]}' in stripped and stripped.startswith(fn.split('.')[0])
               for fn in _MULTILINE_STARTS):
            depth = line.count('(') - line.count(')')
            if depth > 0:
                skip_depth = depth
            # skip this line regardless
            continue
        result_lines.append(line)

    return '\n'.join(result_lines)

EXECUTION_TIMEOUT = 30


def execute_matplotlib_code(matplotlib_code: str, timeout: int = EXECUTION_TIMEOUT) -> dict:
    """
    Execute matplotlib Python code and return the resulting figure as base64 PNG.

    The code should use matplotlib (plt) and optionally numpy (np). After execution,
    the current figure is saved to a buffer and returned. Uses non-interactive Agg backend.

    Args:
        matplotlib_code: Python code string that uses matplotlib to create a figure.
        timeout: Max seconds to run the code. Default 30.

    Returns:
        dict: On success {"image_base64": str, "mime_type": "image/png"}.
              On failure {"error": str}.
    """
    if not (matplotlib_code and isinstance(matplotlib_code, str)):
        return {"error": "matplotlib_code is required and must be a non-empty string"}

    if len(matplotlib_code) > 50000:
        return {"error": "matplotlib_code exceeds maximum length"}

    wrapper = r"""
import sys
import base64
import re as _re

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

def _strip_answer_text(fig):
    '''
    Remove text objects from the figure that are likely to reveal answer values.
    Keeps only single-character labels (vertex labels like A, B, C) and '?'.
    Removes: anything with digits, degree/unit symbols, or longer strings.
    Also clears titles, legends, and numeric axis labels.
    '''
    _answer_re = _re.compile(r'[0-9\u00b0\u03b1-\u03c9\u0391-\u03a9]')  # digits, °, greek
    for ax_obj in fig.get_axes():
        # Remove text objects (covers ax.text() and ax.annotate())
        for txt in list(ax_obj.texts):
            content = txt.get_text().strip()
            if _answer_re.search(content) or len(content) > 2:
                txt.remove()
        # Clear title
        ax_obj.set_title('')
        # Remove legend (legend labels often contain answer values)
        legend = ax_obj.get_legend()
        if legend:
            legend.remove()
        # Clear xlabel/ylabel if they contain numbers or units
        if _answer_re.search(ax_obj.get_xlabel()) or len(ax_obj.get_xlabel()) > 20:
            ax_obj.set_xlabel('')
        if _answer_re.search(ax_obj.get_ylabel()) or len(ax_obj.get_ylabel()) > 20:
            ax_obj.set_ylabel('')
        # Clear tick labels that look like answer values
        for label in ax_obj.get_xticklabels() + ax_obj.get_yticklabels():
            text = label.get_text().strip()
            if _answer_re.search(text) and len(text) > 3:
                label.set_text('')
    # Clear figure suptitle
    if fig._suptitle:
        fig.suptitle('')

code = sys.stdin.read()
try:
    exec(code, {'plt': plt, 'np': np, '__builtins__': __builtins__})
    _strip_answer_text(plt.gcf())
    buf = __import__('io').BytesIO()
    plt.savefig(buf, format='png', bbox_inches='tight', dpi=150)
    plt.close('all')
    sys.stdout.buffer.write(base64.b64encode(buf.getvalue()))
except Exception as e:
    sys.stderr.write(str(e))
    sys.exit(1)
"""
    try:
        proc = subprocess.run(
            [sys.executable, '-c', wrapper],
            input=matplotlib_code.encode('utf-8'),
            capture_output=True,
            timeout=timeout,
            cwd=None,
        )
        if proc.returncode != 0:
            err_msg = (proc.stderr or b'').decode('utf-8', errors='replace').strip() or 'Execution failed'
            logger.warning(f"Matplotlib execution failed: {err_msg}")
            return {"error": f"Matplotlib execution failed: {err_msg}"}
        out = proc.stdout
        if not out:
            return {"error": "No image data produced"}
        image_base64 = out.decode('ascii')
        return {"image_base64": image_base64, "mime_type": "image/png"}
    except subprocess.TimeoutExpired:
        logger.warning("Matplotlib execution timed out")
        return {"error": "Execution timed out"}
    except Exception as e:
        logger.exception("Matplotlib executor error")
        return {"error": str(e)}
