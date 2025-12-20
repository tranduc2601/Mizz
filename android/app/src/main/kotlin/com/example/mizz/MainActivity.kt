package com.example.mizz

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceFragmentActivity() {
    private val CHANNEL = "com.example.mizz/newpipe"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "downloadAudio" -> {
                    val videoUrl = call.argument<String>("videoUrl")
                    val outputPath = call.argument<String>("outputPath")
                    
                    if (videoUrl == null || outputPath == null) {
                        result.error("INVALID_ARGS", "Missing arguments", null)
                        return@setMethodCallHandler
                    }
                    
                    // Return immediately to prevent blocking
                    result.success("STARTED")
                    
                    // Run download in background
                    NewPipeDownloader.downloadAudio(
                        videoUrl = videoUrl,
                        outputPath = outputPath,
                        onProgress = { progress ->
                            runOnUiThread {
                                MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                                    .invokeMethod("onProgress", progress)
                            }
                        },
                        onComplete = { path ->
                            runOnUiThread {
                                MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                                    .invokeMethod("onComplete", path)
                            }
                        },
                        onError = { error ->
                            runOnUiThread {
                                MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                                    .invokeMethod("onError", error)
                            }
                        }
                    )
                }
                
                "getVideoInfo" -> {
                    val videoUrl = call.argument<String>("videoUrl")
                    
                    if (videoUrl == null) {
                        result.error("INVALID_ARGS", "Missing videoUrl", null)
                        return@setMethodCallHandler
                    }
                    
                    NewPipeDownloader.getVideoInfo(
                        videoUrl = videoUrl,
                        onSuccess = { info ->
                            runOnUiThread {
                                result.success(info)
                            }
                        },
                        onError = { error ->
                            runOnUiThread {
                                result.error("INFO_ERROR", error, null)
                            }
                        }
                    )
                }
                
                else -> result.notImplemented()
            }
        }
    }
}
