package com.example.q_les

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.q_les/exam_lockdown"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLockTask" -> {
                        try {
                            startLockTask()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("LOCK_TASK_ERROR", "Failed to start lock task: ${e.message}", null)
                        }
                    }
                    "stopLockTask" -> {
                        try {
                            stopLockTask()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("LOCK_TASK_ERROR", "Failed to stop lock task: ${e.message}", null)
                        }
                    }
                    "isInLockTaskMode" -> {
                        val isLocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
                        } else {
                            false
                        }
                        result.success(isLocked)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
