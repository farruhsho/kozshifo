// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'access_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccessEvent {

 String get id; String get userId; String? get userFullName; String get direction;// in | out
 DateTime get occurredAt; String get source;
/// Create a copy of AccessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccessEventCopyWith<AccessEvent> get copyWith => _$AccessEventCopyWithImpl<AccessEvent>(this as AccessEvent, _$identity);

  /// Serializes this AccessEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccessEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userFullName, userFullName) || other.userFullName == userFullName)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,userFullName,direction,occurredAt,source);

@override
String toString() {
  return 'AccessEvent(id: $id, userId: $userId, userFullName: $userFullName, direction: $direction, occurredAt: $occurredAt, source: $source)';
}


}

/// @nodoc
abstract mixin class $AccessEventCopyWith<$Res>  {
  factory $AccessEventCopyWith(AccessEvent value, $Res Function(AccessEvent) _then) = _$AccessEventCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String? userFullName, String direction, DateTime occurredAt, String source
});




}
/// @nodoc
class _$AccessEventCopyWithImpl<$Res>
    implements $AccessEventCopyWith<$Res> {
  _$AccessEventCopyWithImpl(this._self, this._then);

  final AccessEvent _self;
  final $Res Function(AccessEvent) _then;

/// Create a copy of AccessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? userFullName = freezed,Object? direction = null,Object? occurredAt = null,Object? source = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userFullName: freezed == userFullName ? _self.userFullName : userFullName // ignore: cast_nullable_to_non_nullable
as String?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AccessEvent].
extension AccessEventPatterns on AccessEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccessEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccessEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccessEvent value)  $default,){
final _that = this;
switch (_that) {
case _AccessEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccessEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AccessEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String? userFullName,  String direction,  DateTime occurredAt,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccessEvent() when $default != null:
return $default(_that.id,_that.userId,_that.userFullName,_that.direction,_that.occurredAt,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String? userFullName,  String direction,  DateTime occurredAt,  String source)  $default,) {final _that = this;
switch (_that) {
case _AccessEvent():
return $default(_that.id,_that.userId,_that.userFullName,_that.direction,_that.occurredAt,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String? userFullName,  String direction,  DateTime occurredAt,  String source)?  $default,) {final _that = this;
switch (_that) {
case _AccessEvent() when $default != null:
return $default(_that.id,_that.userId,_that.userFullName,_that.direction,_that.occurredAt,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccessEvent implements AccessEvent {
  const _AccessEvent({required this.id, required this.userId, this.userFullName, required this.direction, required this.occurredAt, required this.source});
  factory _AccessEvent.fromJson(Map<String, dynamic> json) => _$AccessEventFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String? userFullName;
@override final  String direction;
// in | out
@override final  DateTime occurredAt;
@override final  String source;

/// Create a copy of AccessEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccessEventCopyWith<_AccessEvent> get copyWith => __$AccessEventCopyWithImpl<_AccessEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccessEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccessEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userFullName, userFullName) || other.userFullName == userFullName)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,userFullName,direction,occurredAt,source);

@override
String toString() {
  return 'AccessEvent(id: $id, userId: $userId, userFullName: $userFullName, direction: $direction, occurredAt: $occurredAt, source: $source)';
}


}

/// @nodoc
abstract mixin class _$AccessEventCopyWith<$Res> implements $AccessEventCopyWith<$Res> {
  factory _$AccessEventCopyWith(_AccessEvent value, $Res Function(_AccessEvent) _then) = __$AccessEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String? userFullName, String direction, DateTime occurredAt, String source
});




}
/// @nodoc
class __$AccessEventCopyWithImpl<$Res>
    implements _$AccessEventCopyWith<$Res> {
  __$AccessEventCopyWithImpl(this._self, this._then);

  final _AccessEvent _self;
  final $Res Function(_AccessEvent) _then;

/// Create a copy of AccessEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? userFullName = freezed,Object? direction = null,Object? occurredAt = null,Object? source = null,}) {
  return _then(_AccessEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userFullName: freezed == userFullName ? _self.userFullName : userFullName // ignore: cast_nullable_to_non_nullable
as String?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
