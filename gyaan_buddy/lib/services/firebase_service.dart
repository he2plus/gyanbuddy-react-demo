import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();

  late FirebaseApp _app;
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;
  late FirebaseAnalytics _analytics;

  FirebaseApp get app => _app;
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseAnalytics get analytics => _analytics;

  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      _app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _analytics = FirebaseAnalytics.instance;
      
      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
        print('📱 Project ID: ${_app.options.projectId}');
        print('🌐 Storage Bucket: ${_app.options.storageBucket}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Dispose resources
  void dispose() {
    // Firebase services are automatically disposed
  }
}
