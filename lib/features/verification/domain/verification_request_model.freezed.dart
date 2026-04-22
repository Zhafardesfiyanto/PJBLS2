// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VerificationRequestModel _$VerificationRequestModelFromJson(
  Map<String, dynamic> json,
) {
  return _VerificationRequestModel.fromJson(json);
}

/// @nodoc
mixin _$VerificationRequestModel {
  String get id => throw _privateConstructorUsedError;
  String get teacherId => throw _privateConstructorUsedError;
  String get teacherName => throw _privateConstructorUsedError;
  VerificationStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get rejectionReason => throw _privateConstructorUsedError;
  DateTime? get reviewedAt => throw _privateConstructorUsedError;

  /// Serializes this VerificationRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VerificationRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VerificationRequestModelCopyWith<VerificationRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VerificationRequestModelCopyWith<$Res> {
  factory $VerificationRequestModelCopyWith(
    VerificationRequestModel value,
    $Res Function(VerificationRequestModel) then,
  ) = _$VerificationRequestModelCopyWithImpl<$Res, VerificationRequestModel>;
  @useResult
  $Res call({
    String id,
    String teacherId,
    String teacherName,
    VerificationStatus status,
    DateTime createdAt,
    String? rejectionReason,
    DateTime? reviewedAt,
  });
}

/// @nodoc
class _$VerificationRequestModelCopyWithImpl<
  $Res,
  $Val extends VerificationRequestModel
>
    implements $VerificationRequestModelCopyWith<$Res> {
  _$VerificationRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VerificationRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? teacherId = null,
    Object? teacherName = null,
    Object? status = null,
    Object? createdAt = null,
    Object? rejectionReason = freezed,
    Object? reviewedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            teacherId: null == teacherId
                ? _value.teacherId
                : teacherId // ignore: cast_nullable_to_non_nullable
                      as String,
            teacherName: null == teacherName
                ? _value.teacherName
                : teacherName // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as VerificationStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            rejectionReason: freezed == rejectionReason
                ? _value.rejectionReason
                : rejectionReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            reviewedAt: freezed == reviewedAt
                ? _value.reviewedAt
                : reviewedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VerificationRequestModelImplCopyWith<$Res>
    implements $VerificationRequestModelCopyWith<$Res> {
  factory _$$VerificationRequestModelImplCopyWith(
    _$VerificationRequestModelImpl value,
    $Res Function(_$VerificationRequestModelImpl) then,
  ) = __$$VerificationRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String teacherId,
    String teacherName,
    VerificationStatus status,
    DateTime createdAt,
    String? rejectionReason,
    DateTime? reviewedAt,
  });
}

/// @nodoc
class __$$VerificationRequestModelImplCopyWithImpl<$Res>
    extends
        _$VerificationRequestModelCopyWithImpl<
          $Res,
          _$VerificationRequestModelImpl
        >
    implements _$$VerificationRequestModelImplCopyWith<$Res> {
  __$$VerificationRequestModelImplCopyWithImpl(
    _$VerificationRequestModelImpl _value,
    $Res Function(_$VerificationRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VerificationRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? teacherId = null,
    Object? teacherName = null,
    Object? status = null,
    Object? createdAt = null,
    Object? rejectionReason = freezed,
    Object? reviewedAt = freezed,
  }) {
    return _then(
      _$VerificationRequestModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        teacherId: null == teacherId
            ? _value.teacherId
            : teacherId // ignore: cast_nullable_to_non_nullable
                  as String,
        teacherName: null == teacherName
            ? _value.teacherName
            : teacherName // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as VerificationStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        rejectionReason: freezed == rejectionReason
            ? _value.rejectionReason
            : rejectionReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        reviewedAt: freezed == reviewedAt
            ? _value.reviewedAt
            : reviewedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VerificationRequestModelImpl implements _VerificationRequestModel {
  const _$VerificationRequestModelImpl({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.reviewedAt,
  });

  factory _$VerificationRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VerificationRequestModelImplFromJson(json);

  @override
  final String id;
  @override
  final String teacherId;
  @override
  final String teacherName;
  @override
  final VerificationStatus status;
  @override
  final DateTime createdAt;
  @override
  final String? rejectionReason;
  @override
  final DateTime? reviewedAt;

  @override
  String toString() {
    return 'VerificationRequestModel(id: $id, teacherId: $teacherId, teacherName: $teacherName, status: $status, createdAt: $createdAt, rejectionReason: $rejectionReason, reviewedAt: $reviewedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationRequestModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.teacherId, teacherId) ||
                other.teacherId == teacherId) &&
            (identical(other.teacherName, teacherName) ||
                other.teacherName == teacherName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    teacherId,
    teacherName,
    status,
    createdAt,
    rejectionReason,
    reviewedAt,
  );

  /// Create a copy of VerificationRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VerificationRequestModelImplCopyWith<_$VerificationRequestModelImpl>
  get copyWith =>
      __$$VerificationRequestModelImplCopyWithImpl<
        _$VerificationRequestModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VerificationRequestModelImplToJson(this);
  }
}

abstract class _VerificationRequestModel implements VerificationRequestModel {
  const factory _VerificationRequestModel({
    required final String id,
    required final String teacherId,
    required final String teacherName,
    required final VerificationStatus status,
    required final DateTime createdAt,
    final String? rejectionReason,
    final DateTime? reviewedAt,
  }) = _$VerificationRequestModelImpl;

  factory _VerificationRequestModel.fromJson(Map<String, dynamic> json) =
      _$VerificationRequestModelImpl.fromJson;

  @override
  String get id;
  @override
  String get teacherId;
  @override
  String get teacherName;
  @override
  VerificationStatus get status;
  @override
  DateTime get createdAt;
  @override
  String? get rejectionReason;
  @override
  DateTime? get reviewedAt;

  /// Create a copy of VerificationRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VerificationRequestModelImplCopyWith<_$VerificationRequestModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
