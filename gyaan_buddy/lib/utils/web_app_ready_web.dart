import 'dart:html' as html;

void markAppReadyForWeb() {
  html.window.dispatchEvent(html.Event('gyanbuddy-app-ready'));
}
