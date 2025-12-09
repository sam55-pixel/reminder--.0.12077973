package com.example.smart_reminder

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        // Check if the activity was launched from a notification.
        val intent = intent
        val extras = intent.extras
        if (extras != null && extras.containsKey("payload")) {
            val payload = extras.getString("payload")
            flutterEngine.dartExecutor.binaryMessenger.send("notification_payload", payload?.let { ByteBuffer.wrap(it.toByteArray()) })
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Stoic Oracle Alarms"
            val descriptionText = "Critical reminders that bypass Do Not Disturb"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel("stoic_alarm_channel", name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
