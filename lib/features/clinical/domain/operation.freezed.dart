// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Operation {

 String get id; String get visitId; String get patientId; String get patientName; String? get referringDoctorId; String? get referringDoctorName; String? get surgeonId; String? get surgeonName; String get operationTypeId; String get typeName; String get eye; String get priority; String get status; String? get price; String? get scheduledAt; String? get performedAt; String? get completedAt; String? get notes; String? get result; String get createdAt;
/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationCopyWith<Operation> get copyWith => _$OperationCopyWithImpl<Operation>(this as Operation, _$identity);

  /// Serializes this Operation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Operation&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.referringDoctorId, referringDoctorId) || other.referringDoctorId == referringDoctorId)&&(identical(other.referringDoctorName, referringDoctorName) || other.referringDoctorName == referringDoctorName)&&(identical(other.surgeonId, surgeonId) || other.surgeonId == surgeonId)&&(identical(other.surgeonName, surgeonName) || other.surgeonName == surgeonName)&&(identical(other.operationTypeId, operationTypeId) || other.operationTypeId == operationTypeId)&&(identical(other.typeName, typeName) || other.typeName == typeName)&&(identical(other.eye, eye) || other.eye == eye)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.price, price) || other.price == price)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.performedAt, performedAt) || other.performedAt == performedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.result, result) || other.result == result)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,visitId,patientId,patientName,referringDoctorId,referringDoctorName,surgeonId,surgeonName,operationTypeId,typeName,eye,priority,status,price,scheduledAt,performedAt,completedAt,notes,result,createdAt]);

@override
String toString() {
  return 'Operation(id: $id, visitId: $visitId, patientId: $patientId, patientName: $patientName, referringDoctorId: $referringDoctorId, referringDoctorName: $referringDoctorName, surgeonId: $surgeonId, surgeonName: $surgeonName, operationTypeId: $operationTypeId, typeName: $typeName, eye: $eye, priority: $priority, status: $status, price: $price, scheduledAt: $scheduledAt, performedAt: $performedAt, completedAt: $completedAt, notes: $notes, result: $result, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OperationCopyWith<$Res>  {
  factory $OperationCopyWith(Operation value, $Res Function(Operation) _then) = _$OperationCopyWithImpl;
@useResult
$Res call({
 String id, String visitId, String patientId, String patientName, String? referringDoctorId, String? referringDoctorName, String? surgeonId, String? surgeonName, String operationTypeId, String typeName, String eye, String priority, String status, String? price, String? scheduledAt, String? performedAt, String? completedAt, String? notes, String? result, String createdAt
});




}
/// @nodoc
class _$OperationCopyWithImpl<$Res>
    implements $OperationCopyWith<$Res> {
  _$OperationCopyWithImpl(this._self, this._then);

  final Operation _self;
  final $Res Function(Operation) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? visitId = null,Object? patientId = null,Object? patientName = null,Object? referringDoctorId = freezed,Object? referringDoctorName = freezed,Object? surgeonId = freezed,Object? surgeonName = freezed,Object? operationTypeId = null,Object? typeName = null,Object? eye = null,Object? priority = null,Object? status = null,Object? price = freezed,Object? scheduledAt = freezed,Object? performedAt = freezed,Object? completedAt = freezed,Object? notes = freezed,Object? result = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,referringDoctorId: freezed == referringDoctorId ? _self.referringDoctorId : referringDoctorId // ignore: cast_nullable_to_non_nullable
as String?,referringDoctorName: freezed == referringDoctorName ? _self.referringDoctorName : referringDoctorName // ignore: cast_nullable_to_non_nullable
as String?,surgeonId: freezed == surgeonId ? _self.surgeonId : surgeonId // ignore: cast_nullable_to_non_nullable
as String?,surgeonName: freezed == surgeonName ? _self.surgeonName : surgeonName // ignore: cast_nullable_to_non_nullable
as String?,operationTypeId: null == operationTypeId ? _self.operationTypeId : operationTypeId // ignore: cast_nullable_to_non_nullable
as String,typeName: null == typeName ? _self.typeName : typeName // ignore: cast_nullable_to_non_nullable
as String,eye: null == eye ? _self.eye : eye // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String?,scheduledAt: freezed == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as String?,performedAt: freezed == performedAt ? _self.performedAt : performedAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Operation].
extension OperationPatterns on Operation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Operation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Operation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Operation value)  $default,){
final _that = this;
switch (_that) {
case _Operation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Operation value)?  $default,){
final _that = this;
switch (_that) {
case _Operation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String visitId,  String patientId,  String patientName,  String? referringDoctorId,  String? referringDoctorName,  String? surgeonId,  String? surgeonName,  String operationTypeId,  String typeName,  String eye,  String priority,  String status,  String? price,  String? scheduledAt,  String? performedAt,  String? completedAt,  String? notes,  String? result,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Operation() when $default != null:
return $default(_that.id,_that.visitId,_that.patientId,_that.patientName,_that.referringDoctorId,_that.referringDoctorName,_that.surgeonId,_that.surgeonName,_that.operationTypeId,_that.typeName,_that.eye,_that.priority,_that.status,_that.price,_that.scheduledAt,_that.performedAt,_that.completedAt,_that.notes,_that.result,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String visitId,  String patientId,  String patientName,  String? referringDoctorId,  String? referringDoctorName,  String? surgeonId,  String? surgeonName,  String operationTypeId,  String typeName,  String eye,  String priority,  String status,  String? price,  String? scheduledAt,  String? performedAt,  String? completedAt,  String? notes,  String? result,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _Operation():
return $default(_that.id,_that.visitId,_that.patientId,_that.patientName,_that.referringDoctorId,_that.referringDoctorName,_that.surgeonId,_that.surgeonName,_that.operationTypeId,_that.typeName,_that.eye,_that.priority,_that.status,_that.price,_that.scheduledAt,_that.performedAt,_that.completedAt,_that.notes,_that.result,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String visitId,  String patientId,  String patientName,  String? referringDoctorId,  String? referringDoctorName,  String? surgeonId,  String? surgeonName,  String operationTypeId,  String typeName,  String eye,  String priority,  String status,  String? price,  String? scheduledAt,  String? performedAt,  String? completedAt,  String? notes,  String? result,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Operation() when $default != null:
return $default(_that.id,_that.visitId,_that.patientId,_that.patientName,_that.referringDoctorId,_that.referringDoctorName,_that.surgeonId,_that.surgeonName,_that.operationTypeId,_that.typeName,_that.eye,_that.priority,_that.status,_that.price,_that.scheduledAt,_that.performedAt,_that.completedAt,_that.notes,_that.result,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Operation extends Operation {
  const _Operation({required this.id, required this.visitId, required this.patientId, required this.patientName, this.referringDoctorId, this.referringDoctorName, this.surgeonId, this.surgeonName, required this.operationTypeId, required this.typeName, required this.eye, this.priority = 'normal', required this.status, this.price, this.scheduledAt, this.performedAt, this.completedAt, this.notes, this.result, required this.createdAt}): super._();
  factory _Operation.fromJson(Map<String, dynamic> json) => _$OperationFromJson(json);

@override final  String id;
@override final  String visitId;
@override final  String patientId;
@override final  String patientName;
@override final  String? referringDoctorId;
@override final  String? referringDoctorName;
@override final  String? surgeonId;
@override final  String? surgeonName;
@override final  String operationTypeId;
@override final  String typeName;
@override final  String eye;
@override@JsonKey() final  String priority;
@override final  String status;
@override final  String? price;
@override final  String? scheduledAt;
@override final  String? performedAt;
@override final  String? completedAt;
@override final  String? notes;
@override final  String? result;
@override final  String createdAt;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperationCopyWith<_Operation> get copyWith => __$OperationCopyWithImpl<_Operation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OperationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Operation&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.referringDoctorId, referringDoctorId) || other.referringDoctorId == referringDoctorId)&&(identical(other.referringDoctorName, referringDoctorName) || other.referringDoctorName == referringDoctorName)&&(identical(other.surgeonId, surgeonId) || other.surgeonId == surgeonId)&&(identical(other.surgeonName, surgeonName) || other.surgeonName == surgeonName)&&(identical(other.operationTypeId, operationTypeId) || other.operationTypeId == operationTypeId)&&(identical(other.typeName, typeName) || other.typeName == typeName)&&(identical(other.eye, eye) || other.eye == eye)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.price, price) || other.price == price)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.performedAt, performedAt) || other.performedAt == performedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.result, result) || other.result == result)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,visitId,patientId,patientName,referringDoctorId,referringDoctorName,surgeonId,surgeonName,operationTypeId,typeName,eye,priority,status,price,scheduledAt,performedAt,completedAt,notes,result,createdAt]);

@override
String toString() {
  return 'Operation(id: $id, visitId: $visitId, patientId: $patientId, patientName: $patientName, referringDoctorId: $referringDoctorId, referringDoctorName: $referringDoctorName, surgeonId: $surgeonId, surgeonName: $surgeonName, operationTypeId: $operationTypeId, typeName: $typeName, eye: $eye, priority: $priority, status: $status, price: $price, scheduledAt: $scheduledAt, performedAt: $performedAt, completedAt: $completedAt, notes: $notes, result: $result, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OperationCopyWith<$Res> implements $OperationCopyWith<$Res> {
  factory _$OperationCopyWith(_Operation value, $Res Function(_Operation) _then) = __$OperationCopyWithImpl;
@override @useResult
$Res call({
 String id, String visitId, String patientId, String patientName, String? referringDoctorId, String? referringDoctorName, String? surgeonId, String? surgeonName, String operationTypeId, String typeName, String eye, String priority, String status, String? price, String? scheduledAt, String? performedAt, String? completedAt, String? notes, String? result, String createdAt
});




}
/// @nodoc
class __$OperationCopyWithImpl<$Res>
    implements _$OperationCopyWith<$Res> {
  __$OperationCopyWithImpl(this._self, this._then);

  final _Operation _self;
  final $Res Function(_Operation) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? visitId = null,Object? patientId = null,Object? patientName = null,Object? referringDoctorId = freezed,Object? referringDoctorName = freezed,Object? surgeonId = freezed,Object? surgeonName = freezed,Object? operationTypeId = null,Object? typeName = null,Object? eye = null,Object? priority = null,Object? status = null,Object? price = freezed,Object? scheduledAt = freezed,Object? performedAt = freezed,Object? completedAt = freezed,Object? notes = freezed,Object? result = freezed,Object? createdAt = null,}) {
  return _then(_Operation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,referringDoctorId: freezed == referringDoctorId ? _self.referringDoctorId : referringDoctorId // ignore: cast_nullable_to_non_nullable
as String?,referringDoctorName: freezed == referringDoctorName ? _self.referringDoctorName : referringDoctorName // ignore: cast_nullable_to_non_nullable
as String?,surgeonId: freezed == surgeonId ? _self.surgeonId : surgeonId // ignore: cast_nullable_to_non_nullable
as String?,surgeonName: freezed == surgeonName ? _self.surgeonName : surgeonName // ignore: cast_nullable_to_non_nullable
as String?,operationTypeId: null == operationTypeId ? _self.operationTypeId : operationTypeId // ignore: cast_nullable_to_non_nullable
as String,typeName: null == typeName ? _self.typeName : typeName // ignore: cast_nullable_to_non_nullable
as String,eye: null == eye ? _self.eye : eye // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String?,scheduledAt: freezed == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as String?,performedAt: freezed == performedAt ? _self.performedAt : performedAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
