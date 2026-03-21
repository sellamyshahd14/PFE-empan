import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyDjjngPxja_ybf9z-2jQbcoVwAJl-kKIlQ',
    appId: '1:565082023487:android:d06df83f2099f596563a8a',
    messagingSenderId: '565082023487',
    projectId: 'pfe-empan-tunisie',
    storageBucket: 'pfe-empan-tunisie.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjjngPxja_ybf9z-2jQbcoVwAJl-kKIlQ',
    appId: '1:565082023487:ios:741f2f8b5f3d4a6f8b5f3d', // Placeholder for iOS if needed, but primary is Android
    messagingSenderId: '565082023487',
    projectId: 'pfe-empan-tunisie',
    storageBucket: 'pfe-empan-tunisie.firebasestorage.app',
    iosBundleId: 'com.example.flutter_application_1',
  );
}
