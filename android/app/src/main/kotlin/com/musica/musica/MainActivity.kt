package com.musica.musica

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "musica/saf"

    lateinit var treeLauncher: androidx.activity.result.ActivityResultLauncher<Intent>

    private var safHelper: SafHelper? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        treeLauncher = registerForActivityResult(
            androidx.activity.result.contract.ActivityResultContracts.StartActivityForResult()
        ) { result ->
            val uri: Uri? = if (result.resultCode == RESULT_OK) result.data?.data else null
            safHelper?.onTreePicked(uri)
        }
        safHelper = SafHelper(this)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel.setMethodCallHandler { call, result ->
            safHelper?.handle(call, result)
        }
    }
}