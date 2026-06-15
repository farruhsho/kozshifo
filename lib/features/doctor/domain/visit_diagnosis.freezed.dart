// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'visit_diagnosis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VisitDiagnosis {

 String get id; String get visitId; String get patientId; String? get doctorId; String get diagnosis; String? get icd10; String? get createdAt;
/// Create a copy of VisitDiagnosis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisitDiagnosisCopyWith<VisitDiagnosis> get copyWith => _$VisitDiagnosisCopyWithImpl<VisitDiagnosis>(this as VisitDiagnosis, _$identity);

  /// Serializes this VisitDiagnosis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisitDiagnosis&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.icd10, icd10) || other.icd10 == icd10)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,visitId,patientId,doctorId,diagnosis,icd10,createdAt);

@override
String toString() {
  return 'VisitDiagnosis(id: $id, visitId: $visitId, patientId: $patientId, doctorId: $doctorId, diagnosis: $diagnosis, icd10: $icd10, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $VisitDiagnosisCopyWith<$Res>  {
  factory $VisitDiagnosisCopyWith(VisitDiagnosis value, $Res Function(VisitDiagnosis) _then) = _$VisitDiagnosisCopyWithImpl;
@useResult
$Res call({
 String id, String visitId, String patientId, String? doctorId, String diagnosis, String? icd10, String? createdAt
});




}
/// @nodoc
class _$VisitDiagnosisCopyWithImpl<$Res>
    implements $VisitDiagnosisCopyWith<$Res> {
  _$VisitDiagnosisCopyWithImpl(this._self, this._then);

  final VisitDiagnosis _self;
  final $Res Function(VisitDiagnosis) _then;

/// Create a copy of VisitDiagnosis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? visitId = null,Object? patientId = null,Object? doctorId = freezed,Object? diagnosis = null,Object? icd10 = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,doctorId: freezed == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String?,diagnosis: null == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String,icd10: freezed == icd10 ? _self.icd10 : icd10 // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VisitDiagnosis].
extension VisitDiagnosisPatterns on VisitDiagnosis {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisitDiagnosis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisitDiagnosis() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisitDiagnosis value)  $default,){
final _that = this;
switch (_that) {
case _VisitDiagnosis():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisitDiagnosis value)?  $default,){
final _that = this;
switch (_that) {
case _VisitDiagnosis() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String visitId,  String patientId,  String? doctorId,  String diagnosis,  String? icd10,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisitDiagnosis() when $default != null:
return $default(_that.id,_that.visitId,_that.patientId,_that.doctorId,_that.diagnosis,_that.icd10,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String visitId,  String patientId,  String? doctorId,  String diagnosis,  String? icd10,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _VisitDiagnosis():
return $default(_that.id,_that.visitId,_that.patientId,_that.doctorId,_that.diagnosis,_that.icd10,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String visitId,  String patientId,  String? doctorId,  String diagnosis,  String? icd10,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _VisitDiagnosis() when $default != null:
return $default(_that.id,_that.visitId,_that.patientId,_that.doctorId,_that.diagnosis,_that.icd10,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VisitDiagnosis implements VisitDiagnosis {
  const _VisitDiagnosis({required this.id, required this.visitId, required this.patientId, this.doctorId, required this.diagnosis, this.icd10, this.createdAt});
  factory _VisitDiagnosis.fromJson(Map<String, dynamic> json) => _$VisitDiagnosisFromJson(json);

@override final  String id;
@override final  String visitId;
@override final  String patientId;
@override final  String? doctorId;
@override final  String diagnosis;
@override final  String? icd10;
@override final  String? createdAt;

/// Create a copy of VisitDiagnosis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisitDiagnosisCopyWith<_VisitDiagnosis> get copyWith => __$VisitDiagnosisCopyWithImpl<_VisitDiagnosis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VisitDiagnosisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisitDiagnosis&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.icd10, icd10) || other.icd10 == icd10)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,visitId,patientId,doctorId,diagnosis,icd10,createdAt);

@override
String toString() {
  return 'VisitDiagnosis(id: $id, visitId: $visitId, patientId: $patientId, doctorId: $doctorId, diagnosis: $diagnosis, icd10: $icd10, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$VisitDiagnosisCopyWith<$Res> implements $VisitDiagnosisCopyWith<$Res> {
  factory _$VisitDiagnosisCopyWith(_VisitDiagnosis value, $Res Function(_VisitDiagnosis) _then) = __$VisitDiagnosisCopyWithImpl;
@override @useResult
$Res call({
 String id, String visitId, String patientId, String? doctorId, String diagnosis, String? icd10, String? createdAt
});




}
/// @nodoc
class __$VisitDiagnosisCopyWithImpl<$Res>
    implements _$VisitDiagnosisCopyWith<$Res> {
  __$VisitDiagnosisCopyWithImpl(this._self, this._then);

  final _VisitDiagnosis _self;
  final $Res Function(_VisitDiagnosis) _then;

/// Create a copy of VisitDiagnosis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? visitId = null,Object? patientId = null,Object? doctorId = freezed,Object? diagnosis = null,Object? icd10 = freezed,Object? createdAt = freezed,}) {
  return _then(_VisitDiagnosis(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,doctorId: freezed == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String?,diagnosis: null == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String,icd10: freezed == icd10 ? _self.icd10 : icd10 // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
