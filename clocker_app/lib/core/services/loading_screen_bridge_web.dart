import 'dart:js_util' as js_util;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void dismissHtmlLoadingScreen() {
  try {
    if (js_util.hasProperty(html.window, '_flutterLoadingDone')) {
      js_util.callMethod(html.window, '_flutterLoadingDone', []);
    }
  } catch (_) {}
}
