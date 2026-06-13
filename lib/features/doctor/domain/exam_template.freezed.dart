// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exam_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExamTemplate {

 String get id; String get doctorId; String get name; String? get diagnosis; String? get icd10; String? get recommendations; String? get createdAt;
/// Create a copy of ExamTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamTemplateCopyWith<ExamTemplate> get copyWith => _$ExamTemplateCopyWithImpl<ExamTemplate>(this as ExamTemplate, _$identity);

  /// Serializes this ExamTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExamTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.icd10, icd10) || other.icd10 == icd10)&&(identical(other.recommendations, recommendations) || other.recommendations == recommendations)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,doctorId,name,diagnosis,icd10,recommendations,createdAt);

@override
String toString() {
  return 'ExamTemplate(id: $id, doctorId: $doctorId, name: $name, diagnosis: $diagnosis, icd10: $icd10, recommendations: $recommendations, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ExamTemplateCopyWith<$Res>  {
  factory $ExamTemplateCopyWith(ExamTemplate value, $Res Function(ExamTemplate) _then) = _$ExamTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String doctorId, String name, String? diagnosis, String? icd10, String? recommendations, String? createdAt
});




}
/// @nodoc
class _$ExamTemplateCopyWithImpl<$Res>
    implements $ExamTemplateCopyWith<$Res> {
  _$ExamTemplateCopyWithImpl(this._self, this._then);

  final ExamTemplate _self;
  final $Res Function(ExamTemplate) _then;

/// Create a copy of ExamTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? doctorId = null,Object? name = null,Object? diagnosis = freezed,Object? icd10 = freezed,Object? recommendations = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,doctorId: null == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,diagnosis: freezed == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String?,icd10: freezed == icd10 ? _self.icd10 : icd10 // ignore: cast_nullable_to_non_nullable
as String?,recommendations: freezed == recommendations ? _self.recommendations : recommendations // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExamTemplate].
extension ExamTemplatePatterns on ExamTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExamTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExamTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExamTemplate value)  $default,){
final _that = this;
switch (_that) {
case _ExamTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExamTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _ExamTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String doctorId,  String name,  String? diagnosis,  String? icd10,  String? recommendations,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExamTemplate() when $default != null:
return $default(_that.id,_that.doctorId,_that.name,_that.diagnosis,_that.icd10,_that.recommendations,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String doctorId,  String name,  String? diagnosis,  String? icd10,  String? recommendations,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ExamTemplate():
return $default(_that.id,_that.doctorId,_that.name,_that.diagnosis,_that.icd10,_that.recommendations,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String doctorId,  String name,  String? diagnosis,  String? icd10,  String? recommendations,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ExamTemplate() when $default != null:
return $default(_that.id,_that.doctorId,_that.name,_that.diagnosis,_that.icd10,_that.recommendations,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExamTemplate implements ExamTemplate {
  const _ExamTemplate({required this.id, required this.doctorId, required this.name, this.diagnosis, this.icd10, this.recommendations, this.createdAt});
  factory _ExamTemplate.fromJson(Map<String, dynamic> json) => _$ExamTemplateFromJson(json);

@override final  String id;
@override final  String doctorId;
@override final  String name;
@override final  String? diagnosis;
@override final  String? icd10;
@override final  String? recommendations;
@override final  String? createdAt;

/// Create a copy of ExamTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamTemplateCopyWith<_ExamTemplate> get copyWith => __$ExamTemplateCopyWithImpl<_ExamTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExamTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.icd10, icd10) || other.icd10 == icd10)&&(identical(other.recommendations, recommendations) || other.recommendations == recommendations)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,doctorId,name,diagnosis,icd10,recommendations,createdAt);

@override
String toString() {
  return 'ExamTemplate(id: $id, doctorId: $doctorId, name: $name, diagnosis: $diagnosis, icd10: $icd10, recommendations: $recommendations, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ExamTemplateCopyWith<$Res> implements $ExamTemplateCopyWith<$Res> {
  factory _$ExamTemplateCopyWith(_ExamTemplate value, $Res Function(_ExamTemplate) _then) = __$ExamTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String doctorId, String name, String? diagnosis, String? icd10, String? recommendations, String? createdAt
});




}
/// @nodoc
class __$ExamTemplateCopyWithImpl<$Res>
    implements _$ExamTemplateCopyWith<$Res> {
  __$ExamTemplateCopyWithImpl(this._self, this._then);

  final _ExamTemplate _self;
  final $Res Function(_ExamTemplate) _then;

/// Create a copy of ExamTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? doctorId = null,Object? name = null,Object? diagnosis = freezed,Object? icd10 = freezed,Object? recommendations = freezed,Object? createdAt = freezed,}) {
  return _then(_ExamTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,doctorId: null == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,diagnosis: freezed == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String?,icd10: freezed == icd10 ? _self.icd10 : icd10 // ignore: cast_nullable_to_non_nullable
as String?,recommendations: freezed == recommendations ? _self.recommendations : recommendations // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
