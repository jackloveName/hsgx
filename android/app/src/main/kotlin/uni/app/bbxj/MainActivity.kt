package uni.app.bbxj

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "hsgx/app_update",
        ).setMethodCallHandler { call, result ->
            if (call.method != "installApk") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val filePath = call.argument<String>("path")
            val apkFile = filePath?.let(::File)
            if (apkFile == null || !apkFile.isFile) {
                result.error("FILE_NOT_FOUND", "更新包不存在，请重新下载", null)
                return@setMethodCallHandler
            }

            try {
                val authority = "${packageName}.app_update_provider"
                val apkUri = FileProvider.getUriForFile(this, authority, apkFile)
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(apkUri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                result.success(null)
            } catch (error: Exception) {
                result.error(
                    "INSTALL_FAILED",
                    "无法打开安装程序，请允许安装未知来源应用后重试",
                    error.message,
                )
            }
        }
    }
}
