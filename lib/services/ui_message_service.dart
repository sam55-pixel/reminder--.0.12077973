import 'package:flutter/material.dart';

// A simple service to decouple UI messaging from background services.
class UiMessageService {
  // A ValueNotifier that will hold the message to be displayed on the UI.
  static final ValueNotifier<String?> userMessage = ValueNotifier(null);

  // Method to post a new message for the UI to display.
  static void showMessage(String message) {
    userMessage.value = message;
  }

  // Method to clear the message after it has been shown.
  static void clearMessage() {
    userMessage.value = null;
  }
}
