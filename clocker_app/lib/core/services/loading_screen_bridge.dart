import 'package:flutter/foundation.dart';
import 'dart:js_util' as js_util;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void dismissHtmlLoadingScreen() {
  if (!kIsWeb) return;
  try {
    if (js_util.hasProperty(html.window, '_flutterLoadingDone')) {
      js_util.callMethod(html.window, '_flutterLoadingDone', []);
    }
  } catch (_) {}
}
