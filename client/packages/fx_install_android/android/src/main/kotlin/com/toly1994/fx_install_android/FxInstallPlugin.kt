package com.toly1994.fx_install_android

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.lang.ref.WeakReference

class FxInstallPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activityReference = WeakReference<Activity>(null)
    private val activity get() = activityReference.get()

    private var pendingResult: MethodChannel.Result? = null
    private var pendingFilePath: String = ""
    private var awaitingPermission = false

    companion object {
        private const val REQUEST_CODE = 1024
    }

    // ─── FlutterPlugin ───

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "fx_install_android")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = null
        channel.setMethodCallHandler(null)
        pendingResult = null
    }

    // ─── ActivityAware ───

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityReference = WeakReference(binding.activity)
        binding.addActivityResultListener { requestCode, resultCode, _ ->
            handleActivityResult(requestCode, resultCode)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityReference.clear()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityReference = WeakReference(binding.activity)
        binding.addActivityResultListener { requestCode, resultCode, _ ->
            handleActivityResult(requestCode, resultCode)
        }
    }

    override fun onDetachedFromActivity() {
        activityReference.clear()
    }

    // ─── MethodCallHandler ───

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installApk" -> {
                val filePath = call.argument<String>("filePath")
                if (filePath.isNullOrEmpty()) {
                    result.success(resultMap(false, "filePath is required"))
                    return
                }
                pendingResult = result
                pendingFilePath = filePath
                installApk(filePath)
            }
            else -> result.notImplemented()
        }
    }

    // ─── 核心逻辑 ───

    private fun installApk(filePath: String) {
        val file = File(filePath)
        if (!file.exists()) {
            finishWithResult(false, "APK file not found: $filePath")
            return
        }

        if (!hasInstallPermission()) {
            awaitingPermission = true
            requestInstallPermission()
            return
        }

        awaitingPermission = false
        val intent = buildInstallIntent(file) ?: run {
            finishWithResult(false, "Failed to build install intent")
            return
        }

        intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
        activity?.startActivityForResult(intent, REQUEST_CODE)
            ?: run { finishWithResult(false, "No activity available") }
    }

    private fun buildInstallIntent(file: File): Intent? {
        val ctx = context ?: return null
        var targetFile = file

        // Android 6.0 及以下：复制到 Downloads 目录（兼容旧版本 URI 机制）
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.M) {
            val downloadsDir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                ctx.packageName
            ).apply { if (!exists()) mkdirs() }
            targetFile = File(downloadsDir, file.name)
            file.copyTo(targetFile, overwrite = true)
        }

        val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            FxInstallFileProvider.getUriForFile(ctx, targetFile)
        } else {
            Uri.fromFile(targetFile)
        }

        return Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }

    // ─── 权限处理 ───

    private fun hasInstallPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context?.packageManager?.canRequestPackageInstalls() ?: false
        } else {
            true
        }
    }

    private fun requestInstallPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                data = Uri.parse("package:${context?.packageName}")
            }
            activity?.startActivityForResult(intent, REQUEST_CODE)
                ?: run { finishWithResult(false, "No activity available for permission request") }
        }
    }

    // ─── ActivityResult 回调 ───

    private fun handleActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_CODE) return false

        if (awaitingPermission) {
            // 从权限设置页返回
            if (hasInstallPermission()) {
                // 权限已授予，继续安装
                installApk(pendingFilePath)
            } else {
                finishWithResult(false, "Install permission denied")
            }
        } else {
            // 从安装界面返回
            if (resultCode == Activity.RESULT_OK) {
                finishWithResult(true, "Install success")
            } else {
                finishWithResult(false, "Install cancelled")
            }
        }
        return true
    }

    // ─── 工具方法 ───

    private fun finishWithResult(success: Boolean, message: String) {
        pendingResult?.success(resultMap(success, message))
        pendingResult = null
    }

    private fun resultMap(success: Boolean, message: String): HashMap<String, Any?> {
        return hashMapOf("isSuccess" to success, "errorMessage" to message)
    }
}
