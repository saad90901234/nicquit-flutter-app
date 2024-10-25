// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCIyf5HVEHqD6bPch31MwlDkuvl_1VeIag',
    appId: '1:1082428913470:web:6bed86d7c310baf48f5e6f',
    messagingSenderId: '1082428913470',
    projectId: 'nicquit-461b8',
    authDomain: 'nicquit-461b8.firebaseapp.com',
    storageBucket: 'nicquit-461b8.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCFp7Y2ZvbF7a0refrbs3xdqryw49zqS8g',
    appId: '1:1082428913470:android:97ed9e8266ef46968f5e6f',
    messagingSenderId: '1082428913470',
    projectId: 'nicquit-461b8',
    storageBucket: 'nicquit-461b8.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCwHHq4agvQ24XjmK21vv7PgHTrVGR7vSQ',
    appId: '1:1082428913470:ios:f74eff5a550fb0b18f5e6f',
    messagingSenderId: '1082428913470',
    projectId: 'nicquit-461b8',
    storageBucket: 'nicquit-461b8.appspot.com',
    iosBundleId: 'com.example.nicquit',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCwHHq4agvQ24XjmK21vv7PgHTrVGR7vSQ',
    appId: '1:1082428913470:ios:f74eff5a550fb0b18f5e6f',
    messagingSenderId: '1082428913470',
    projectId: 'nicquit-461b8',
    storageBucket: 'nicquit-461b8.appspot.com',
    iosBundleId: 'com.example.nicquit',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCIyf5HVEHqD6bPch31MwlDkuvl_1VeIag',
    appId: '1:1082428913470:web:16017b2b44dde17f8f5e6f',
    messagingSenderId: '1082428913470',
    projectId: 'nicquit-461b8',
    authDomain: 'nicquit-461b8.firebaseapp.com',
    storageBucket: 'nicquit-461b8.appspot.com',
  );

}