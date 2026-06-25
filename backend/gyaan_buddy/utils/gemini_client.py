"""
Gemini Client for Vertex AI integration.

This module provides a simple interface to generate content using Google's Gemini models
via Vertex AI.

Setup:
    1. Set GOOGLE_CLOUD_PROJECT environment variable (or it defaults to 'caramel-goal-473111-t3')
    2. Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON file path
    3. Optionally set GOOGLE_CLOUD_LOCATION (defaults to 'us-central1')

Usage:
    from gyaan_buddy.utils.gemini_client import gemini_generate
    
    response = gemini_generate("Your prompt here")
"""

import os
import logging
import base64
import tempfile
from typing import Optional, Dict, Any

logger = logging.getLogger('gyaan_buddy.gemini')

PROJECT_ID = os.environ.get('GOOGLE_CLOUD_PROJECT', 'caramel-goal-473111-t3')
LOCATION = os.environ.get('GOOGLE_CLOUD_LOCATION', 'us-central1')
MODEL_ID = os.environ.get('GEMINI_MODEL', 'gemini-2.0-flash-001')
IMAGEN_MODEL_ID = 'imagen-3.0-generate-001'

GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', 'AQ.Ab8RN6KqvMUyVvIRuJHY3IsT5KyUScJYfL6Hu_BRkbBFP4Wxqw')
GEMINI_API_MODEL = os.environ.get('GEMINI_API_MODEL', 'gemini-2.0-flash')

_initialized = False
_gemini_api_initialized = False

LEARN_MODE_PROMPT = """You are an expert teacher creating a very short Learn Mode intro for Class 6-12 students.

Your goal is not to teach, but to prepare the mind to learn.

Generate a concise opener for the topic "{topic_name}".

NON-NEGOTIABLE RULES

- Total length under 90 words (not counting diagram code)
- Short, simple sentences
- Natural, conversational tone
- No textbook language
- No derivations, history, or full explanations
- Do NOT resolve curiosity or give answers
- Stop immediately after the final line
- NO emojis anywhere in the output
- NO LaTeX or backslash notation — write plain text (e.g. "a/b" not "\\frac{a}{b}", "angle ABC" not "\\angle ABC")
- NO markdown formatting (no **, *, _, #, etc.)
- Plain text only — the output will be displayed on a mobile app

STRUCTURE (use exactly these plain-text headings, in this order)

LOOK AROUND
One real-life situation students notice daily. One sentence only.

THINK
One sharp prediction question. One sentence only. Must remain unanswered. Must activate prior experience, not facts.

FOCUS
2-3 boundary-defining key ideas, each under 7 words.
OPTIONALLY include ONE relationship, rule, or condition ONLY IF it naturally clarifies the idea.
Write all math and science using plain English notation only.
One plain-English sentence explaining what kind of idea this topic is about.
No examples, no expansion.

DIAGRAM RULE (VERY STRICT)

Diagrams are FORBIDDEN by default.

Include a diagram ONLY IF ALL are true:
- The idea cannot be understood without seeing spatial layout, motion, or structure
- The topic explicitly involves geometry, rays, motion, graphs, or position
- A teacher would definitely draw this on the board

If a diagram is included:
- Wrap the Python matplotlib code in: ```python ... ```
- Keep it extremely simple — shapes, lines, and single-letter labels only
- No plt.savefig() or plt.show()
- No plt.title() or ax.set_title() in the code
- No text annotations showing answers or values
- No decorative elements

If unsure — do NOT generate a diagram.
Do not include a DIAGRAM heading unless a diagram is actually generated.

HARD BANS

Do NOT:
- Add summaries or conclusions
- Repeat ideas
- Add examples beyond the first line
- Use multiple analogies
- Sound motivational or comforting
- Generate charts, graphs, timelines, or mind maps (especially for SST)
- Use emojis, LaTeX, or markdown anywhere in the output

FINAL INSTRUCTION

Generate one single Learn Mode block following all rules above without exception."""


def _init_vertex_ai():
    """Initialize Vertex AI SDK."""
    global _initialized
    if _initialized:
        return True

    try:
        import vertexai
        vertexai.init(project=PROJECT_ID, location=LOCATION)
        _initialized = True
        logger.info(f"Vertex AI initialized with project={PROJECT_ID}, location={LOCATION}")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize Vertex AI: {e}")
        return False


def _clean_theory_text(text: str) -> str:
    """Strip emojis, markdown, and LaTeX from theory text for mobile display."""
    import re
    import unicodedata

    # Remove markdown code blocks (```...```) entirely — diagram code is extracted separately
    text = re.sub(r'```[\s\S]*?```', '', text)

    # Remove markdown bold/italic/underline (**x**, *x*, _x_, __x__)
    text = re.sub(r'\*{1,2}(.+?)\*{1,2}', r'\1', text)
    text = re.sub(r'_{1,2}(.+?)_{1,2}', r'\1', text)

    # Remove inline LaTeX ($...$) — keep the inner text
    text = re.sub(r'\$(.+?)\$', r'\1', text)

    # Remove emojis (Unicode emoji ranges)
    text = re.sub(
        r'[\U0001F300-\U0001F9FF\U0001FA00-\U0001FA6F\U0001FA70-\U0001FAFF'
        r'\U00002702-\U000027B0\U000024C2-\U0001F251]+',
        '', text
    )

    # Remove markdown headings (#, ##, ###)
    text = re.sub(r'^#{1,6}\s*', '', text, flags=re.MULTILINE)

    # Collapse multiple blank lines to one
    text = re.sub(r'\n{3,}', '\n\n', text)

    return text.strip()


def generate_chapter_theory(
    chapter_name: str,
    subject: Optional[str] = None,
    grade_level: Optional[str] = None,
    min_length: int = 600,
    max_length: int = 650,
    temperature: float = 0.7
) -> Dict[str, Any]:
    """
    Generate a Learn Mode intro for a chapter using Vertex AI Gemini.

    Returns dict with:
      - 'theory_text': cleaned plain-text theory (mobile-safe, no emojis/LaTeX/markdown)
      - 'matplotlib_code': extracted Python diagram code if the AI included one, else None
      - 'character_count': length of theory_text
    Or 'error' on failure.
    """
    import re

    if not _init_vertex_ai():
        return {"error": "Vertex AI not initialized. Check GOOGLE_APPLICATION_CREDENTIALS."}

    try:
        from vertexai.generative_models import GenerativeModel, GenerationConfig

        topic_name = chapter_name
        if subject:
            topic_name = f"{chapter_name} ({subject})"

        prompt = LEARN_MODE_PROMPT.replace("{topic_name}", topic_name)

        model = GenerativeModel(MODEL_ID)
        response = model.generate_content(
            prompt,
            generation_config=GenerationConfig(
                temperature=temperature,
                max_output_tokens=512,
            ),
        )

        if not response.text:
            logger.warning(f"Empty response for Learn Mode intro: {chapter_name}")
            return {"error": "Empty response from model"}

        raw_text = response.text.strip()

        # Extract matplotlib code block before cleaning
        matplotlib_code = None
        code_match = re.search(r'```python\s*([\s\S]*?)```', raw_text, re.IGNORECASE)
        if code_match:
            matplotlib_code = code_match.group(1).strip()

        # Clean theory text for mobile display
        theory_text = _clean_theory_text(raw_text)

        logger.info(
            f"Generated Learn Mode intro for '{chapter_name}': "
            f"{len(theory_text)} chars, diagram={'yes' if matplotlib_code else 'no'}"
        )

        return {
            "theory_text": theory_text,
            "matplotlib_code": matplotlib_code,
            "character_count": len(theory_text),
        }

    except Exception as e:
        logger.error(f"Error generating Learn Mode intro for chapter '{chapter_name}': {str(e)}")
        return {"error": f"Failed to generate theory: {str(e)}"}


def generate_chapter_image(
    chapter_name: str, 
    theory_text: str,
    aspect_ratio: str = "16:9"
) -> Dict[str, Any]:
    """
    Generate a single educational image using Vertex AI Imagen based on chapter name and theory.
    
    Args:
        chapter_name (str): Name of the chapter
        theory_text (str): Theory content (will be truncated to 650 characters if longer)
        aspect_ratio (str): Aspect ratio for the image. Default "16:9"
                           Options: "1:1", "9:16", "16:9", "4:3", "3:4"
    
    Returns:
        dict: Contains 'image_base64', 'mime_type' on success, or 'error' on failure
    """
    if not _init_vertex_ai():
        return {"error": "Vertex AI not initialized. Check GOOGLE_APPLICATION_CREDENTIALS."}
    
    try:
        from vertexai.preview.vision_models import ImageGenerationModel
        
        if len(theory_text) > 650:
            theory_text = theory_text[:647] + "..."
        
        prompt = f"""Create an educational, visually appealing illustration for a chapter titled "{chapter_name}".

Based on this theory content:
{theory_text}

Requirements:
- Create a clear, educational diagram or illustration
- Use clean, professional visual style suitable for students
- Include relevant symbols, diagrams, or visual representations of the concepts
- Make it colorful but not distracting
- Ensure the image helps explain and visualize the theory
- The style should be modern, flat design appropriate for educational materials"""

        model = ImageGenerationModel.from_pretrained(IMAGEN_MODEL_ID)
        
        response = model.generate_images(
            prompt=prompt,
            number_of_images=1,
            aspect_ratio=aspect_ratio,
            safety_filter_level="block_some",
            person_generation="allow_adult",
        )
        
        try:
            images_list = list(response) if response else []
        except (TypeError, AttributeError):
            images_list = getattr(response, 'images', []) if response else []
        
        if images_list and len(images_list) > 0:
            image = images_list[0]
            
            image_bytes = image._image_bytes
            
            image_base64 = base64.b64encode(image_bytes).decode('utf-8')
            
            logger.info(f"Successfully generated image for chapter: {chapter_name}")
            
            return {
                "image_base64": image_base64,
                "mime_type": "image/png"
            }
        else:
            logger.warning(f"No images generated for chapter: {chapter_name}")
            return {"error": "No images were generated"}
            
    except ImportError:
        error_msg = "vision_models not available. Run: pip install google-cloud-aiplatform[vision]"
        logger.error(error_msg)
        return {"error": error_msg}
    except Exception as e:
        logger.error(f"Error generating image for chapter '{chapter_name}': {str(e)}")
        return {"error": f"Failed to generate image: {str(e)}"}


def generate_chapter_content(
    chapter_name: str,
    subject: Optional[str] = None,
    grade_level: Optional[str] = None,
    aspect_ratio: str = "16:9",
    theory_length_min: int = 600,
    theory_length_max: int = 650
) -> Dict[str, Any]:
    """
    Generate both theory text and an educational image for a chapter.
    
    This is a convenience function that combines theory generation and image generation
    in a single call.
    
    Args:
        chapter_name (str): Name of the chapter
        subject (str, optional): Subject area (e.g., "Physics", "Biology")
        grade_level (str, optional): Target grade level (e.g., "Grade 10")
        aspect_ratio (str): Aspect ratio for the image. Default "16:9"
        theory_length_min (int): Minimum theory character length. Default 600
        theory_length_max (int): Maximum theory character length. Default 650
    
    Returns:
        dict: Contains 'theory_text', 'image_base64', 'mime_type', 'character_count' on success,
              or 'error' with details on failure
    """
    theory_result = generate_chapter_theory(
        chapter_name=chapter_name,
        subject=subject,
        grade_level=grade_level,
        min_length=theory_length_min,
        max_length=theory_length_max
    )
    
    if "error" in theory_result:
        return {
            "error": f"Theory generation failed: {theory_result['error']}",
            "theory_error": theory_result['error']
        }
    
    theory_text = theory_result["theory_text"]
    
    image_result = generate_chapter_image(
        chapter_name=chapter_name,
        theory_text=theory_text,
        aspect_ratio=aspect_ratio
    )
    
    if "error" in image_result:
        return {
            "error": f"Image generation failed: {image_result['error']}",
            "theory_text": theory_text,
            "character_count": theory_result["character_count"],
            "image_error": image_result['error']
        }
    
    return {
        "theory_text": theory_text,
        "character_count": theory_result["character_count"],
        "image_base64": image_result["image_base64"],
        "mime_type": image_result["mime_type"]
    }


def generate_chapter_content_to_files(
    chapter_name: str,
    output_image_path: str,
    subject: Optional[str] = None,
    grade_level: Optional[str] = None,
    aspect_ratio: str = "16:9",
    save_theory_temp: bool = True
) -> Dict[str, Any]:
    """
    Generate chapter content and save to files.
    
    Args:
        chapter_name (str): Name of the chapter
        output_image_path (str): Path where to save the generated image
        subject (str, optional): Subject area
        grade_level (str, optional): Target grade level
        aspect_ratio (str): Aspect ratio for the image. Default "16:9"
        save_theory_temp (bool): If True, saves theory to a temporary file. Default True
    
    Returns:
        dict: Contains 'theory_text', 'image_path', 'theory_temp_path' (if saved) on success,
              or 'error' on failure. The temp file will be automatically cleaned up when
              the file object is closed or the program exits.
    """
    result = generate_chapter_content(
        chapter_name=chapter_name,
        subject=subject,
        grade_level=grade_level,
        aspect_ratio=aspect_ratio
    )
    
    if "error" in result:
        return result
    
    response = {
        "theory_text": result["theory_text"],
        "character_count": result["character_count"]
    }
    
    try:
        image_data = base64.b64decode(result["image_base64"])
        os.makedirs(os.path.dirname(output_image_path) if os.path.dirname(output_image_path) else ".", exist_ok=True)
        
        with open(output_image_path, "wb") as f:
            f.write(image_data)
        
        response["image_path"] = output_image_path
        logger.info(f"Image saved to {output_image_path}")
        
    except Exception as e:
        logger.error(f"Failed to save image: {e}")
        response["image_error"] = f"Failed to save image: {str(e)}"
    
    if save_theory_temp:
        try:
            temp_file = tempfile.NamedTemporaryFile(
                mode='w',
                encoding='utf-8',
                suffix='.txt',
                prefix=f'theory_{chapter_name.replace(" ", "_")}_',
                delete=False
            )
            
            temp_file.write(result["theory_text"])
            temp_file.close()
            
            response["theory_temp_path"] = temp_file.name
            logger.info(f"Theory saved to temporary file: {temp_file.name}")
            
        except Exception as e:
            logger.error(f"Failed to save theory to temp file: {e}")
            response["theory_error"] = f"Failed to save theory: {str(e)}"
    
    return response


def generate_chapter_image_to_file(
    chapter_name: str,
    theory_text: str,
    output_path: str,
    aspect_ratio: str = "16:9"
) -> Optional[str]:
    """
    Generate an educational image and save it to a file.
    
    Args:
        chapter_name (str): Name of the chapter
        theory_text (str): Theory content
        output_path (str): Path where to save the generated image
        aspect_ratio (str): Aspect ratio for the image. Default "16:9"
    
    Returns:
        Optional[str]: Path to saved image, or None if generation failed
    """
    result = generate_chapter_image(chapter_name, theory_text, aspect_ratio)
    
    if "error" in result:
        logger.error(f"Failed to generate image: {result['error']}")
        return None
    
    try:
        image_data = base64.b64decode(result["image_base64"])
        
        os.makedirs(os.path.dirname(output_path) if os.path.dirname(output_path) else ".", exist_ok=True)
        
        with open(output_path, "wb") as f:
            f.write(image_data)
        
        logger.info(f"Image saved to {output_path}")
        return output_path
        
    except Exception as e:
        logger.error(f"Failed to save image to {output_path}: {e}")
        return None



def generate_image(prompt: str, output_path: str, aspect_ratio: str = "1:1") -> Optional[str]:
    """
    Generate an image using Vertex AI Imagen.
    
    Args:
        prompt (str): The image generation prompt
        output_path (str): Path where to save the generated image
        aspect_ratio (str): Aspect ratio for the image. Default "1:1"
    
    Returns:
        Optional[str]: Path to saved image, or None if generation failed
    
    Raises:
        Exception: If Vertex AI is not initialized
    """
    if not _init_vertex_ai():
        raise Exception("Vertex AI not initialized. Check GOOGLE_APPLICATION_CREDENTIALS.")
    
    try:
        from vertexai.preview.vision_models import ImageGenerationModel
        
        model = ImageGenerationModel.from_pretrained(IMAGEN_MODEL_ID)
        
        response = model.generate_images(
            prompt=prompt,
            number_of_images=1,
            aspect_ratio=aspect_ratio,
            safety_filter_level="block_some",
        )
        
        try:
            images_list = list(response) if response else []
        except (TypeError, AttributeError):
            images_list = getattr(response, 'images', []) if response else []
        
        if images_list and len(images_list) > 0:
            image = images_list[0]
            image_bytes = image._image_bytes
            
            os.makedirs(os.path.dirname(output_path) if os.path.dirname(output_path) else ".", exist_ok=True)
            
            with open(output_path, "wb") as f:
                f.write(image_bytes)
            
            logger.info(f"Image saved to {output_path}")
            return output_path
        
        logger.warning("No image data found in response")
        return None
        
    except Exception as e:
        logger.error(f"Image generation failed: {e}")
        return None

def gemini_generate(prompt: str, temperature: float = 0.7, max_output_tokens: int = 8192) -> str:
    """
    Generate content using Gemini via Vertex AI.
    
    Args:
        prompt (str): The prompt to send to Gemini
        temperature (float): Controls randomness (0.0-1.0). Default 0.7
        max_output_tokens (int): Maximum tokens in response. Default 4000
    
    Returns:
        str: The generated text response
    
    Raises:
        Exception: If Vertex AI is not available or generation fails
    """
    if not _init_vertex_ai():
        raise Exception("Vertex AI not initialized. Check GOOGLE_APPLICATION_CREDENTIALS.")
    
    from vertexai.generative_models import GenerativeModel, GenerationConfig
    
    model = GenerativeModel(MODEL_ID)
    
    response = model.generate_content(
        prompt,
        generation_config=GenerationConfig(
            temperature=temperature,
            max_output_tokens=max_output_tokens,
        )
    )
    
    return response.text


def gemini_generate_json(prompt: str, temperature: float = 0.7, max_output_tokens: int = 8192) -> dict:
    """
    Generate content and parse as JSON.
    
    Args:
        prompt (str): The prompt to send to Gemini (should request JSON output)
        temperature (float): Controls randomness (0.0-1.0). Default 0.7
        max_output_tokens (int): Maximum tokens in response. Default 4000
    
    Returns:
        dict: Parsed JSON response
    
    Raises:
        Exception: If generation fails or response is not valid JSON
    """
    import json
    
    response_text = gemini_generate(prompt, temperature, max_output_tokens)
    
    import re

    text = response_text.strip()
    if '```json' in text:
        text = text.split('```json')[1].split('```')[0].strip()
    elif '```' in text:
        text = text.split('```')[1].split('```')[0].strip()

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # AI-generated code (e.g. matplotlib_code) often contains backslash sequences
        # that are valid Python but invalid JSON (e.g. \alpha, \sum, \frac, \p, \s).
        # Fix: escape any backslash not followed by a valid JSON escape character.
        fixed = re.sub(r'\\(?!["\\/bfnrtu])', r'\\\\', text)
        return json.loads(fixed)

