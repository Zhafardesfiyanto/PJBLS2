// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VerificationRequestModelImpl _$$VerificationRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$VerificationRequestModelImpl(
  id: json['id'] as String,
  teacherId: json['teacherId'] as String,
  teacherName: json['teacherName'] as String,
  status: $enumDecode(_$VerificationStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  rejectionReason: json['rejectionReason'] as String?,
  reviewedAt: json['reviewedAt'] == null
      ? null
      : DateTime.parse(json['reviewedAt'] as String),
);

Map<String, dynamic> _$$VerificationRequestModelImplToJson(
  _$VerificationRequestModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'teacherId': instance.teacherId,
  'teacherName': instance.teacherName,
  'status': _$VerificationStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'rejectionReason': instance.rejectionReason,
  'reviewedAt': instance.reviewedAt?.toIso8601String(),
};

const _$VerificationStatusEnumMap = {
  VerificationStatus.pending: 'pending',
  VerificationStatus.verified: 'verified',
  VerificationStatus.rejected: 'rejected',
};
