package com.toly1994.fx_install_android

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

class FxInstallFileProvider : FileProvider() {
    companion object {
        fun getUriForFile(context: Context, file: File): Uri {
            val authority = "${context.packageName}.fxInstallFileProvider"
            return getUriForFile(context, authority, file)
        }
    }
}
