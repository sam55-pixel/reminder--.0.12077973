package com.example.smart_reminder

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // The notification channel creation is now handled entirely by the
        // flutter_local_notifications plugin in the Dart code. Removing it
        // from here prevents a native crash that occurs when trying to create
        // a channel before the notification permission has been granted.

        // Check if the activity was launched from a notification.
        val intent = intent
        val extras = intent.extras
        if (extras != null && extras.containsKey("payload")) {
            val payload = extras.getString("payload")
            flutterEngine.dartExecutor.binaryMessenger.send("notification_payload", payload?.let { ByteBuffer.wrap(it.toByteArray()) })
        }
    }
}
