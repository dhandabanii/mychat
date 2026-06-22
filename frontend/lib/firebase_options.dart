import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // We only support Web for now. If Android is needed later, we can add it here.
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBeUDOQGt-aJk9a2DHnYu8eGRrCk8xx-GE',
    appId: '1:566393581393:web:ce049ad6875f99c5b22d70',
    messagingSenderId: '566393581393',
    projectId: 'mychat-5993b',
    authDomain: 'mychat-5993b.firebaseapp.com',
    storageBucket: 'mychat-5993b.firebasestorage.app',
  );
}
