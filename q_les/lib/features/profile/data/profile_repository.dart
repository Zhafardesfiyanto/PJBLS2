import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../auth/domain/user_model.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_exception.dart';

/// Abstract repository for profile operations
abstract class ProfileRepository {
  /// Update user profile data
  Future<void> updateProfile(UserModel user);
  
  /// Upload profile photo and return download URL
  Future<String> uploadProfilePhoto(File file, String uid);
  
  /// Update profile photo URL in Firestore
  Future<void> updateProfilePhotoUrl(String uid, String photoUrl);
  
  /// Update profile photo in all chat messages (denormalization)
  Future<void> updatePhotoInChatMessages(String uid, String photoUrl, String userName);
}

/// Firebase implementation of ProfileRepository
class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<void> updateProfile(UserModel user) async {
    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(user.uid)
          .update(user.toFirestore());
    } catch (e) {
      throw AppException('Gagal memperbarui profil: $e');
    }
  }

  @override
  Future<String> uploadProfilePhoto(File file, String uid) async {
    try {
      // Validasi ukuran file (max 5MB)
      final sizeInMB = file.lengthSync() / (1024 * 1024);
      if (sizeInMB > 5) {
        throw const AppException('Ukuran file terlalu besar. Maksimal 5 MB.');
      }

      // Validasi format file
      final ext = path.extension(file.path).toLowerCase();
      const allowedFormats = ['.jpg', '.jpeg', '.png', '.webp'];
      if (!allowedFormats.contains(ext)) {
        throw const AppException('Format file tidak didukung. Gunakan JPEG, PNG, atau WebP.');
      }

      // Upload ke Firebase Storage
      final ref = _storage.ref(StoragePaths.profilePhoto(uid));
      await ref.putFile(file);
      
      // Get download URL
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw AppException('Gagal mengunggah foto: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Gagal mengunggah foto: $e');
    }
  }

  @override
  Future<void> updateProfilePhotoUrl(String uid, String photoUrl) async {
    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .update({'photoUrl': photoUrl});
    } catch (e) {
      throw AppException('Gagal memperbarui URL foto profil: $e');
    }
  }

  @override
  Future<void> updatePhotoInChatMessages(String uid, String photoUrl, String userName) async {
    try {
      final batch = _firestore.batch();

      // Update class messages
      final classMessagesQuery = await _firestore
          .collection(FirestorePaths.classMessages)
          .where('senderId', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .orderBy('sentAt', descending: true)
          .limit(100) // Update only recent messages for performance
          .get();

      for (final doc in classMessagesQuery.docs) {
        batch.update(doc.reference, {
          'senderPhotoUrl': photoUrl,
          'senderName': userName, // Also update name in case it changed
        });
      }

      // Update assignment messages
      final assignmentMessagesQuery = await _firestore
          .collection(FirestorePaths.assignmentMessages)
          .where('senderId', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .orderBy('sentAt', descending: true)
          .limit(100) // Update only recent messages for performance
          .get();

      for (final doc in assignmentMessagesQuery.docs) {
        batch.update(doc.reference, {
          'senderName': userName, // Assignment messages don't have photo, but update name
        });
      }

      await batch.commit();
    } catch (e) {
      // Don't throw error for chat message updates as it's not critical
      // Just log the error (in production, use proper logging)
      print('Warning: Failed to update chat messages: $e');
    }
  }
}