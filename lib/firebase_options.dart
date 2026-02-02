import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios; // Added iOS configuration if needed
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBnXX5fQ7gwnHVDoh3PigDDC-l5ccv9XdM',
    appId: '1:62974724756:web:d7a9cdf544b995ba0d0281',
    messagingSenderId: '62974724756',
    projectId: 'calorie-tracker-proj',
    authDomain: 'calorie-tracker-proj.firebaseapp.com',
    storageBucket: 'calorie-tracker-proj.firebasestorage.app',
    measurementId: 'G-EG646EPZPN',
    databaseURL: 'https://calorie-tracker-proj-default-rtdb.firebaseio.com', // Added Realtime Database URL for Web
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBN0JrKNqzUV0MmxTDYXZJnXvMK9Pa6Bs8',
    appId: '1:62974724756:android:c5df20b0d8bd775d0d0281',
    messagingSenderId: '62974724756',
    projectId: 'calorie-tracker-proj',
    storageBucket: 'calorie-tracker-proj.firebasestorage.app',
    measurementId: 'G-0E6E77LZ7J', // Added measurementId for Analytics on Android
    databaseURL: 'https://calorie-tracker-proj-default-rtdb.firebaseio.com', // Added Realtime Database URL for Android
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBnXX5fQ7gwnHVDoh3PigDDC-l5ccv9XdM',
    appId: '1:62974724756:ios:9a8a8d5cb888a8298',
    messagingSenderId: '62974724756',
    projectId: 'calorie-tracker-proj',
    storageBucket: 'calorie-tracker-proj.firebasestorage.app',
    measurementId: 'G-0E6E77LZ7J', // Added measurementId for Analytics on iOS
    databaseURL: 'https://calorie-tracker-proj-default-rtdb.firebaseio.com', // Added Realtime Database URL for iOS
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBnXX5fQ7gwnHVDoh3PigDDC-l5ccv9XdM',
    appId: '1:62974724756:web:f648ff83f5e9474c0d0281',
    messagingSenderId: '62974724756',
    projectId: 'calorie-tracker-proj',
    authDomain: 'calorie-tracker-proj.firebaseapp.com',
    storageBucket: 'calorie-tracker-proj.firebasestorage.app',
    measurementId: 'G-0E6E77LZ7J',
    databaseURL: 'https://calorie-tracker-proj-default-rtdb.firebaseio.com', // Added Realtime Database URL for Windows
  );
}
