package com.veralume.veralume

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "veralume/quiet_reading")
      .setMethodCallHandler { call, result ->
        if (call.method == "setKeepScreenOn") {
          val enabled = call.argument<Boolean>("enabled") ?: false
          runOnUiThread {
            if (enabled) window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            else window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
          }
          result.success(null)
        } else result.notImplemented()
      }
  }
}
