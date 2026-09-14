package com.example.hieuphuong_technology_app

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "hieuphuong_technology/pdf_helper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName") ?: "BangBaoGia.pdf"

                    if (bytes == null) {
                        result.error("INVALID_ARGS", "Dữ liệu bytes không được null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val saveResult = savePdfToDownloads(bytes, fileName)
                        result.success(saveResult)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.localizedMessage ?: "Lỗi lưu file", null)
                    }
                }
                "openPdf" -> {
                    val uriString = call.argument<String>("uri")
                    val filePath = call.argument<String>("filePath")

                    try {
                        openPdfFile(uriString, filePath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_FAILED", e.localizedMessage ?: "Không thể mở file PDF", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun savePdfToDownloads(bytes: ByteArray, fileName: String): Map<String, String> {
        val resolver = applicationContext.contentResolver

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw IllegalStateException("Không thể tạo file trong thư mục Downloads")

            resolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            }

            contentValues.clear()
            contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, contentValues, null, null)

            val displayPath = "/storage/emulated/0/Download/$fileName"
            return mapOf(
                "uri" to uri.toString(),
                "displayPath" to displayPath,
                "fileName" to fileName
            )
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            val file = File(downloadsDir, fileName)
            FileOutputStream(file).use { out ->
                out.write(bytes)
                out.flush()
            }

            val uri = Uri.fromFile(file)
            return mapOf(
                "uri" to uri.toString(),
                "displayPath" to file.absolutePath,
                "fileName" to fileName
            )
        }
    }

    private fun openPdfFile(uriString: String?, filePath: String?) {
        val uri: Uri = if (!uriString.isNullOrEmpty()) {
            Uri.parse(uriString)
        } else if (!filePath.isNullOrEmpty()) {
            Uri.fromFile(File(filePath))
        } else {
            throw IllegalArgumentException("URI hoặc filePath không được để trống")
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/pdf")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val chooser = Intent.createChooser(intent, "Mở file Báo giá PDF bằng...")
        chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(chooser)
    }
}
