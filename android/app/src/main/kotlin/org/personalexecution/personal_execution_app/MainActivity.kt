package org.personalexecution.personal_execution_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingImage: MethodChannel.Result? = null
    private val imageRequest = 2402

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Keep account details, prompts and output out of Android recents/captures.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "personal_execution/chatgpt")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBrowser" -> {
                        val uri = Uri.parse(call.arguments as? String ?: "")
                        if (uri.scheme != "https" || uri.host !in listOf("auth.openai.com", "chatgpt.com", "help.openai.com")) {
                            result.error("invalid_uri", "Unsupported browser address.", null)
                        } else try {
                            startActivity(Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE))
                            result.success(null)
                        } catch (_: Exception) {
                            result.error("browser_unavailable", "System browser unavailable.", null)
                        }
                    }
                    "pickScreenshot" -> {
                        if (pendingImage != null) {
                            result.error("busy", "An image picker is already open.", null)
                        } else try {
                            pendingImage = result
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "image/*"
                                putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/png", "image/jpeg", "image/webp"))
                            }
                            startActivityForResult(intent, imageRequest)
                        } catch (_: Exception) {
                            pendingImage = null
                            result.error("picker_unavailable", "Image picker unavailable.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Android activity result bridge for Flutter")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != imageRequest) return
        val result = pendingImage ?: return
        pendingImage = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        // Read at most 5 MiB + 1; never trust provider size metadata. No broad
        // storage permission, persistent URI grant, filename, or path is saved.
        Thread {
            try {
                val bytes = contentResolver.openInputStream(uri)?.use { input ->
                    val output = java.io.ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    while (output.size() <= 5 * 1024 * 1024) {
                        val n = input.read(buffer, 0, minOf(buffer.size, 5 * 1024 * 1024 + 1 - output.size()))
                        if (n < 0) break
                        output.write(buffer, 0, n)
                    }
                    output.toByteArray()
                } ?: throw IllegalArgumentException()
                val mime = when {
                    bytes.size >= 8 && bytes.take(8).toByteArray().contentEquals(byteArrayOf(0x89.toByte(), 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)) -> "image/png"
                    bytes.size >= 3 && bytes[0] == 0xff.toByte() && bytes[1] == 0xd8.toByte() && bytes[2] == 0xff.toByte() -> "image/jpeg"
                    bytes.size >= 12 && String(bytes, 0, 4, Charsets.US_ASCII) == "RIFF" && String(bytes, 8, 4, Charsets.US_ASCII) == "WEBP" -> "image/webp"
                    else -> throw IllegalArgumentException()
                }
                if (bytes.size > 5 * 1024 * 1024) throw IllegalArgumentException()
                runOnUiThread { result.success(mapOf("bytes" to bytes, "mime" to mime)) }
            } catch (_: Exception) {
                runOnUiThread { result.error("invalid_image", "Choose a PNG, JPEG, or WebP screenshot under 5 MiB.", null) }
            }
        }.start()
    }
}
