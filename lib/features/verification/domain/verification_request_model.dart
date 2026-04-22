import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification_request_model.freezed.dart';
part 'verification_request_model.g.dart';

/// Status verifikasi guru
enum VerificationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('verified')
  verified,
  @JsonValue('rejected')
  rejected,
}

/// Model untuk permintaan verifikasi guru
@freezed
class VerificationRequestModel with _$VerificationRequestModel {
  const factory VerificationRequestModel({
    required String id,
    required String teacherId,
    required String teacherName,
    required VerificationStatus status,
    required DateTime createdAt,
    String? rejectionReason,
    DateTime? reviewedAt,
  }) = _VerificationRequestModel;

  /// Factory constructor dari JSON (Firestore document)
  factory VerificationRequestModel.fromJson(Map<String, dynamic> json) => 
      _$VerificationRequestModelFromJson(json);
}

/// Extension untuk helper methods
extension VerificationRequestModelExtension on VerificationRequestModel {
  /// Apakah masih pending
  bool get isPending => status == VerificationStatus.pending;
  
  /// Apakah sudah diverifikasi
  bool get isVerified => status == VerificationStatus.verified;
  
  /// Apakah ditolak
  bool get isRejected => status == VerificationStatus.rejected;
  
  /// Status dalam bahasa Indonesia
  String get statusText {
    return switch (status) {
      VerificationStatus.pending => 'Menunggu',
      VerificationStatus.verified => 'Terverifikasi',
      VerificationStatus.rejected => 'Ditolak',
    };
  }
}