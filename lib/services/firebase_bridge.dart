import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_options.dart';

/// Thin resilience wrapper around Firebase. EVERY method here is designed to
/// never throw and never block the UI — if Firebase isn't configured yet
/// (placeholder values still in firebase_options.dart), or the device is
/// offline, or any call fails for any reason, methods simply no-op / return
/// null. This guarantees the app's core demo experience keeps working
/// exactly as before even with zero Firebase setup — cloud sync is a
/// pure bonus layer on top of the local-first AppState.
class FirebaseBridge {
  static bool available = false;
  static bool _initTried = false;

  static Future<void> init() async {
    if (_initTried) return;
    _initTried = true;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      available = true;
    } catch (e) {
      available = false;
    }
  }

  /// Uploads a file to Firebase Storage under [storagePath] and returns its
  /// public download URL, or null if unavailable/offline/failed.
  static Future<String?> uploadFile(File file, String storagePath) async {
    if (!available) return null;
    try {
      final ref = FirebaseStorage.instance.ref(storagePath);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveCapturedUpdate(String id, Map<String, dynamic> data) async {
    if (!available) return false;
    try {
      await FirebaseFirestore.instance
          .collection('captured_updates')
          .doc(id)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> saveTask(String id, Map<String, dynamic> data) async {
    if (!available) return false;
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(id)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateTaskFields(String id, Map<String, dynamic> data) async {
    if (!available) return false;
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(id).update(data);
      return true;
    } catch (_) {
      // Doc may not exist yet (e.g. created before Firebase was configured)
      // — fall back to a merge-set so the update is never silently lost.
      try {
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(id)
            .set(data, SetOptions(merge: true));
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Mirrors the local demo credential list into Firestore ONCE, so
  /// credentials are genuinely "kept" in Firebase. Login itself still
  /// validates against the local list synchronously (zero network
  /// dependency during a live demo) — this is a one-way backup, not a
  /// runtime dependency.
  static Future<void> seedAccountsIfNeeded(List<Map<String, dynamic>> accounts) async {
    if (!available) return;
    try {
      final col = FirebaseFirestore.instance.collection('demo_accounts');
      final existing = await col.limit(1).get();
      if (existing.docs.isEmpty) {
        for (final a in accounts) {
          await col.doc(a['username'] as String).set(a);
        }
      }
    } catch (_) {
      // Non-fatal — credentials simply won't be mirrored this session.
    }
  }
}
