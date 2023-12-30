// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4tIcB17xlozLerfykdroUd8_NEyh8LqM',
    appId: '1:854468667727:android:4c6dde55e2877e141d3d3a',
    messagingSenderId: '854468667727',
    projectId: 'instahelp-sardja',
    storageBucket: 'instahelp-sardja.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBE5VqiE73bvUNP5Fh2_o_1RU164bT5qgE',
    appId: '1:854468667727:ios:29e4534a3d6a71a01d3d3a',
    messagingSenderId: '854468667727',
    projectId: 'instahelp-sardja',
    storageBucket: 'instahelp-sardja.appspot.com',
    androidClientId: '854468667727-4295sdrt45f6d5mr2tfrkh88ju16365t.apps.googleusercontent.com',
    iosClientId: '854468667727-uvqujej61j12i3qiomvri4dq54mc4vpl.apps.googleusercontent.com',
    iosBundleId: 'com.example.instahelp',
  );
}
