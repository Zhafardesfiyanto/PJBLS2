// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      uid: json['uid'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      photoUrl: json['photoUrl'] as String?,
      fcmToken: json['fcmToken'] as String?,
      verificationStatus: json['verificationStatus'] as String?,
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'fullName': instance.fullName,
      'email': instance.email,
      'role': instance.role,
      'photoUrl': instance.photoUrl,
      'fcmToken': instance.fcmToken,
      'verificationStatus': instance.verificationStatus,
    };
