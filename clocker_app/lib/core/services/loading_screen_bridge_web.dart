// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void dismissHtmlLoadingScreen() {
  try {
    final el = html.querySelector('#loading-screen');
    if (el != null) {
      el.classes.add('fade-out');
      Future.delayed(const Duration(milliseconds: 600), () {
        el.style.display = 'none';
      });
    }
  } catch (_) {}
}
