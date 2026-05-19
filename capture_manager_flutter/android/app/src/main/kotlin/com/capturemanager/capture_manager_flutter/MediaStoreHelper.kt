package com.capturemanager.capture_manager_flutter

import android.content.Context
import android.net.Uri
import java.io.File

object MediaStoreHelper {
    /// Copies a content URI to the app cache directory, returning the absolute path.
    /// Required for Android 10+ where MediaStore.Images.Media.DATA is empty.
    fun copyUriToTemp(context: Context, uri: Uri, fileName: String): String? {
        val tempFile = File(context.cacheDir, "capture_$fileName")
        return try {
            context.contentResolver.openInputStream(uri)?.use { input ->
                tempFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            tempFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}
