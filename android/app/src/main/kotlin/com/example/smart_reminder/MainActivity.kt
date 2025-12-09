package com.example.smart_reminder

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Check if the activity was launched from a notification.
        val intent = intent
        val extras = intent.extras
        if (extras != null && extras.containsKey("payload")) {
            val payload = extras.getString("payload")
            flutterEngine.dartExecutor.binaryMessenger.send("notification_payload", payload?.let { ByteBuffer.wrap(it.toByteArray()) })
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val extras = intent.extras
        if (extras != null && extras.containsKey("payload")) {
            val payload = extras.getString("payload")
            flutterEngine?.dartExecutor?.binaryMessenger?.send("notification_payload", payload?.let { ByteBuffer.wrap(it.toByteArray()) })
        }
    }
}
