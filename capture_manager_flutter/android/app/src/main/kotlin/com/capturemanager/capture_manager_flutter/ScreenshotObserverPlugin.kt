package com.capturemanager.capture_manager_flutter

import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import java.io.File

class ScreenshotObserverPlugin(private val context: Context) :
    FlutterPlugin, EventChannel.StreamHandler {

    private val channelName = "com.capturemanager/screenshot_stream"
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var contentObserver: ContentObserver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel = EventChannel(binding.binaryMessenger, channelName)
        eventChannel?.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
        registerContentObserver()
    }

    override fun onCancel(arguments: Any?) {
        unregisterContentObserver()
        eventSink = null
    }

    private fun registerContentObserver() {
        contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                uri ?: return
                resolveScreenshotPath(uri)?.let { path ->
                    eventSink?.success(path)
                }
            }
        }
        context.contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            contentObserver!!
        )
    }

    private fun resolveScreenshotPath(uri: Uri): String? {
        val projection = arrayOf(
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.RELATIVE_PATH
        )
        context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (!cursor.moveToFirst()) return null

            val relativePathIdx = cursor.getColumnIndex(MediaStore.Images.Media.RELATIVE_PATH)
            val relativePath = if (relativePathIdx >= 0) cursor.getString(relativePathIdx) ?: "" else ""

            // Filter: only screenshots (Pixel: DCIM/Screenshots/, Samsung: Pictures/Screenshots/)
            if (!relativePath.contains("screenshot", ignoreCase = true)) return null

            val dataIdx = cursor.getColumnIndex(MediaStore.Images.Media.DATA)
            val dataPath = if (dataIdx >= 0) cursor.getString(dataIdx) else null

            // Android 10+: DATA column may be empty — copy URI to cache
            if (!dataPath.isNullOrEmpty() && File(dataPath).exists()) {
                return dataPath
            }

            val nameIdx = cursor.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
            val displayName = if (nameIdx >= 0) cursor.getString(nameIdx) ?: "screenshot.png" else "screenshot.png"
            return MediaStoreHelper.copyUriToTemp(context, uri, displayName)
        }
        return null
    }

    private fun unregisterContentObserver() {
        contentObserver?.let { context.contentResolver.unregisterContentObserver(it) }
        contentObserver = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel?.setStreamHandler(null)
        unregisterContentObserver()
    }
}
