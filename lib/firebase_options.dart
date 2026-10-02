import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase project: vecino-app-devsignx (Android + iOS apps registered via
/// `firebase apps:create`, config pulled via `firebase apps:sdkconfig`).
/// Regenerate by re-running those commands, or `flutterfire configure`,
/// if the apps are ever recreated.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const bool isConfigured = true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions has not been configured for web. '
        'Run `flutterfire configure` or `firebase apps:create web`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for ${Platform.operatingSystem}.',
        );
    }
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDBdvkbRo97vJixoByOrWBk-B-vMA-KASg',
    appId: '1:169245053017:android:ed455d24e9b3305fa6a148',
    messagingSenderId: '169245053017',
    projectId: 'vecino-app-devsignx',
    storageBucket: 'vecino-app-devsignx.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyBIQefGkX8HJGfd7_QOlmR4oNEiQ0aUoME',
    appId: '1:169245053017:ios:507f1b384e6ecfd6a6a148',
    messagingSenderId: '169245053017',
    projectId: 'vecino-app-devsignx',
    storageBucket: 'vecino-app-devsignx.firebasestorage.app',
    iosBundleId: 'app.vecinoo.app',
  );
}
