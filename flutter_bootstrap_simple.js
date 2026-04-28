// Clean Flutter bootstrap that doesn't try to load CanvasKit
if (!window._flutter) {
  window._flutter = {};
}

_flutter.buildConfig = {
  "engineRevision": "59aa584fdf100e6c78c785d8a5b565d1de4b48ab",
  "builds": [
    {
      "compileTarget": "dart2js",
      "renderer": "html",
      "mainJsPath": "main.dart.js"
    },
    {}
  ]
};

// Directly load main.dart.js without the complex bootstrap logic
var script = document.createElement('script');
script.src = 'main.dart.js';
script.onload = function() {
  // Wait for main function to be available
  if (window.dartProgram) {
    window.dartProgram();
  }
};
document.head.appendChild(script);