// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttendanceEvent {

 String get id; String get userId; String? get userFullName; String? get branchId; String get direction;// in | out
 String get occurredAt; String get source;// faceid | manual
 String? get note; String? get recordedById; String? get createdAt;
/// Create a copy of AttendanceEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceEventCopyWith<AttendanceEvent> get copyWith => _$AttendanceEventCopyWithImpl<AttendanceEvent>(this as AttendanceEvent, _$identity);

  /// Serializes this AttendanceEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userFullName, userFullName) || other.userFullName == userFullName)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.note, note) || other.note == note)&&(identical(other.recordedById, recordedById) || other.recordedById == recordedById)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,userFullName,branchId,direction,occurredAt,source,note,recordedById,createdAt);

@override
String toString() {
  return 'AttendanceEvent(id: $id, userId: $userId, userFullName: $userFullName, branchId: $branchId, direction: $direction, occurredAt: $occurredAt, source: $source, note: $note, recordedById: $recordedById, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AttendanceEventCopyWith<$Res>  {
  factory $AttendanceEventCopyWith(AttendanceEvent value, $Res Function(AttendanceEvent) _then) = _$AttendanceEventCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String? userFullName, String? branchId, String direction, String occurredAt, String source, String? note, String? recordedById, String? createdAt
});




}
/// @nodoc
class _$AttendanceEventCopyWithImpl<$Res>
    implements $AttendanceEventCopyWith<$Res> {
  _$AttendanceEventCopyWithImpl(this._self, this._then);

  final AttendanceEvent _self;
  final $Res Function(AttendanceEvent) _then;

/// Create a copy of AttendanceEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? userFullName = freezed,Object? branchId = freezed,Object? direction = null,Object? occurredAt = null,Object? source = null,Object? note = freezed,Object? recordedById = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userFullName: freezed == userFullName ? _self.userFullName : userFullName // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,recordedById: freezed == recordedById ? _self.recordedById : recordedById // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceEvent].
extension AttendanceEventPatterns on AttendanceEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceEvent value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String? userFullName,  String? branchId,  String direction,  String occurredAt,  String source,  String? note,  String? recordedById,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceEvent() when $default != null:
return $default(_that.id,_that.userId,_that.userFullName,_that.branchId,_that.direction,_that.occurredAt,_that.source,_that.note,_that.recordedById,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String? userFullName,  String? branchId,  String direction,  String occurredAt,  String source,  String? note,  String? recordedById,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AttendanceEvent():
return $default(_that.id,_that.userId,_that.userFullName,_that.branchId,_that.direction,_that.occurredAt,_that.source,_that.note,_that.recordedById,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String? userFullName,  String? branchId,  String direction,  String occurredAt,  String source,  String? note,  String? recordedById,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceEvent() when $default != null:
return $default(_that.id,_that.userId,_that.userFullName,_that.branchId,_that.direction,_that.occurredAt,_that.source,_that.note,_that.recordedById,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceEvent extends AttendanceEvent {
  const _AttendanceEvent({required this.id, required this.userId, this.userFullName, this.branchId, required this.direction, required this.occurredAt, required this.source, this.note, this.recordedById, this.createdAt}): super._();
  factory _AttendanceEvent.fromJson(Map<String, dynamic> json) => _$AttendanceEventFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String? userFullName;
@override final  String? branchId;
@override final  String direction;
// in | out
@override final  String occurredAt;
@override final  String source;
// faceid | manual
@override final  String? note;
@override final  String? recordedById;
@override final  String? createdAt;

/// Create a copy of AttendanceEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceEventCopyWith<_AttendanceEvent> get copyWith => __$AttendanceEventCopyWithImpl<_AttendanceEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userFullName, userFullName) || other.userFullName == userFullName)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.note, note) || other.note == note)&&(identical(other.recordedById, recordedById) || other.recordedById == recordedById)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,userFullName,branchId,direction,occurredAt,source,note,recordedById,createdAt);

@override
String toString() {
  return 'AttendanceEvent(id: $id, userId: $userId, userFullName: $userFullName, branchId: $branchId, direction: $direction, occurredAt: $occurredAt, source: $source, note: $note, recordedById: $recordedById, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AttendanceEventCopyWith<$Res> implements $AttendanceEventCopyWith<$Res> {
  factory _$AttendanceEventCopyWith(_AttendanceEvent value, $Res Function(_AttendanceEvent) _then) = __$AttendanceEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String? userFullName, String? branchId, String direction, String occurredAt, String source, String? note, String? recordedById, String? createdAt
});




}
/// @nodoc
class __$AttendanceEventCopyWithImpl<$Res>
    implements _$AttendanceEventCopyWith<$Res> {
  __$AttendanceEventCopyWithImpl(this._self, this._then);

  final _AttendanceEvent _self;
  final $Res Function(_AttendanceEvent) _then;

/// Create a copy of AttendanceEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? userFullName = freezed,Object? branchId = freezed,Object? direction = null,Object? occurredAt = null,Object? source = null,Object? note = freezed,Object? recordedById = freezed,Object? createdAt = freezed,}) {
  return _then(_AttendanceEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userFullName: freezed == userFullName ? _self.userFullName : userFullName // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,recordedById: freezed == recordedById ? _self.recordedById : recordedById // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
