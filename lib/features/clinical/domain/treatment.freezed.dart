// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'treatment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Treatment {

 String get id; String get visitId; String get patientId; String? get doctorId; String get kind; String get name; String? get productId; String? get quantity; String? get instructions; String get status; String? get performedAt; String get createdAt; int get sessionsTotal; int get sessionsDone;
/// Create a copy of Treatment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TreatmentCopyWith<Treatment> get copyWith => _$TreatmentCopyWithImpl<Treatment>(this as Treatment, _$identity);

  /// Serializes this Treatment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Treatment&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.status, status) || other.status == status)&&(identical(other.performedAt, performedAt) || other.performedAt == performedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sessionsTotal, sessionsTotal) || other.sessionsTotal == sessionsTotal)&&(identical(other.sessionsDone, sessionsDone) || other.sessionsDone == sessionsDone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,visitId,patientId,doctorId,kind,name,productId,quantity,instructions,status,performedAt,createdAt,sessionsTotal,sessionsDone);

@override
String toString() {
  return 'Treatment(id: $id, visitId: $visitId, patientId: $patientId, doctorId: $doctorId, kind: $kind, name: $name, productId: $productId, quantity: $quantity, instructions: $instructions, status: $status, performedAt: $performedAt, createdAt: $createdAt, sessionsTotal: $sessionsTotal, sessionsDone: $sessionsDone)';
}


}

/// @nodoc
abstract mixin class $TreatmentCopyWith<$Res>  {
  factory $TreatmentCopyWith(Treatment value, $Res Function(Treatment) _then) = _$TreatmentCopyWithImpl;
@useResult
$Res call({
 String id, String visitId, String patientId, String? doctorId, String kind, String name, String? productId, String? quantity, String? instructions, String status, String? performedAt, String createdAt, int sessionsTotal, int sessionsDone
});




}
/// @nodoc
class _$TreatmentCopyWithImpl<$Res>
    implements $TreatmentCopyWith<$Res> {
  _$TreatmentCopyWithImpl(this._self, this._then);

  final Treatment _self;
  final $Res Function(Treatment) _then;

/// Create a copy of Treatment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? visitId = null,Object? patientId = null,Object? doctorId = freezed,Object? kind = null,Object? name = null,Object? productId = freezed,Object? quantity = freezed,Object? instructions = freezed,Object? status = null,Object? performedAt = freezed,Object? createdAt = null,Object? sessionsTotal = null,Object? sessionsDone = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,doctorId: freezed == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,performedAt: freezed == performedAt ? _self.performedAt : performedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,sessionsTotal: null == sessionsTotal ? _self.sessionsTotal : sessionsTotal // ignore: cast_nullable_to_non_nullable
as int,sessionsDone: null == sessionsDone ? _self.sessionsDone : sessionsDone // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Treatment].
extension TreatmentPatterns on Treatment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Treatment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Treatment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Treatment value)  $default,){
final _that = this;
switch (_that) {
case _Treatment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Treatment value)?  $default,){
final _that = this;
switch (_that) {
case _Treatment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String visitId,  String patientId,  String? doctorId,  String kind,  String name,  String? productId,  String? quantity,  String? instructions,  String status,  String? performedAt,  String createdAt,  int sessionsTotal,  int sessionsDone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Treatment() when $default != null:
return $default(_that.id,_that.visitId,_that.patientId,_that.doctorId,_that.kind,_that.name,_that.productId,_that.quantity,_that.instructions,_that.status,_that.performedAt,_that.createdAt,_that.sessionsTotal,_that.sessionsDone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String visitId,  String patientId,  String? doctorId,  String kind,  String name,  String? productId,  String? quantity,  String? instructions,  String status,  String? performedAt,  String createdAt,  int sessionsTotal,  int sessionsDone)  $default,) {final _that = this;
switch (_that) {
case _Treatment():
return $default(_that.id,_that.visitId,_that.patientId,_that.doctorId,_that.kind,_that.name,_that.productId,_that.quantity,_that.instructions,_that.status,_that.performedAt,_that.createdAt,_that.sessionsTotal,_that.sessionsDone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String visitId,  String patientId,  String? doctorId,  String kind,  String name,  String? productId,  String? quantity,  String? instructions,  String status,  String? performedAt,  String createdAt,  int sessionsTotal,  int sessionsDone)?  $default,) {final _that = this;
switch (_that) {
case _Treatment() when $default != null:
return $default(_that.id,_that.visitId,_that.patientId,_that.doctorId,_that.kind,_that.name,_that.productId,_that.quantity,_that.instructions,_that.status,_that.performedAt,_that.createdAt,_that.sessionsTotal,_that.sessionsDone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Treatment extends Treatment {
  const _Treatment({required this.id, required this.visitId, required this.patientId, this.doctorId, required this.kind, required this.name, this.productId, this.quantity, this.instructions, required this.status, this.performedAt, required this.createdAt, this.sessionsTotal = 1, this.sessionsDone = 0}): super._();
  factory _Treatment.fromJson(Map<String, dynamic> json) => _$TreatmentFromJson(json);

@override final  String id;
@override final  String visitId;
@override final  String patientId;
@override final  String? doctorId;
@override final  String kind;
@override final  String name;
@override final  String? productId;
@override final  String? quantity;
@override final  String? instructions;
@override final  String status;
@override final  String? performedAt;
@override final  String createdAt;
@override@JsonKey() final  int sessionsTotal;
@override@JsonKey() final  int sessionsDone;

/// Create a copy of Treatment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TreatmentCopyWith<_Treatment> get copyWith => __$TreatmentCopyWithImpl<_Treatment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TreatmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Treatment&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.status, status) || other.status == status)&&(identical(other.performedAt, performedAt) || other.performedAt == performedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sessionsTotal, sessionsTotal) || other.sessionsTotal == sessionsTotal)&&(identical(other.sessionsDone, sessionsDone) || other.sessionsDone == sessionsDone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,visitId,patientId,doctorId,kind,name,productId,quantity,instructions,status,performedAt,createdAt,sessionsTotal,sessionsDone);

@override
String toString() {
  return 'Treatment(id: $id, visitId: $visitId, patientId: $patientId, doctorId: $doctorId, kind: $kind, name: $name, productId: $productId, quantity: $quantity, instructions: $instructions, status: $status, performedAt: $performedAt, createdAt: $createdAt, sessionsTotal: $sessionsTotal, sessionsDone: $sessionsDone)';
}


}

/// @nodoc
abstract mixin class _$TreatmentCopyWith<$Res> implements $TreatmentCopyWith<$Res> {
  factory _$TreatmentCopyWith(_Treatment value, $Res Function(_Treatment) _then) = __$TreatmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String visitId, String patientId, String? doctorId, String kind, String name, String? productId, String? quantity, String? instructions, String status, String? performedAt, String createdAt, int sessionsTotal, int sessionsDone
});




}
/// @nodoc
class __$TreatmentCopyWithImpl<$Res>
    implements _$TreatmentCopyWith<$Res> {
  __$TreatmentCopyWithImpl(this._self, this._then);

  final _Treatment _self;
  final $Res Function(_Treatment) _then;

/// Create a copy of Treatment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? visitId = null,Object? patientId = null,Object? doctorId = freezed,Object? kind = null,Object? name = null,Object? productId = freezed,Object? quantity = freezed,Object? instructions = freezed,Object? status = null,Object? performedAt = freezed,Object? createdAt = null,Object? sessionsTotal = null,Object? sessionsDone = null,}) {
  return _then(_Treatment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,doctorId: freezed == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String?,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,performedAt: freezed == performedAt ? _self.performedAt : performedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,sessionsTotal: null == sessionsTotal ? _self.sessionsTotal : sessionsTotal // ignore: cast_nullable_to_non_nullable
as int,sessionsDone: null == sessionsDone ? _self.sessionsDone : sessionsDone // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
