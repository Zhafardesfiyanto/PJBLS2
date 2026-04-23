import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Model untuk data pengguna aplikasi dengan Freezed serialization
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String fullName,
    required String email,
    required String role, // 'guru' | 'murid' | 'admin'
    String? photoUrl,
    String? fcmToken,
    String? verificationStatus, // null untuk murid, 'pending'|'verified'|'rejected' untuk guru
  }) = _UserModel;

  /// Factory constructor dari JSON (Firestore document)
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

/// Extension untuk helper methods
extension UserModelExtension on UserModel {
  /// Helper methods untuk role checking
  bool get isGuru => role == 'guru';
  bool get isMurid => role == 'murid';
  bool get isAdmin => role == 'admin';
  
  /// Helper untuk status verifikasi guru
  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
  
  /// Apakah guru sudah terverifikasi atau bukan guru
  bool get canCreateContent => !isGuru || isVerified;

  /// Convert ke Map untuk Firestore (tanpa uid)
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('uid'); // UID tidak disimpan di document, tapi sebagai document ID
    return json;
  }
}