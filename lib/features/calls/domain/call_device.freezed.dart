// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CallDevice {

 String get id; String get label; String? get phoneNumber; String? get branchId; bool get isActive; String? get lastSeenAt; String? get appVersion; bool get online;
/// Create a copy of CallDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallDeviceCopyWith<CallDevice> get copyWith => _$CallDeviceCopyWithImpl<CallDevice>(this as CallDevice, _$identity);

  /// Serializes this CallDevice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.online, online) || other.online == online));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,phoneNumber,branchId,isActive,lastSeenAt,appVersion,online);

@override
String toString() {
  return 'CallDevice(id: $id, label: $label, phoneNumber: $phoneNumber, branchId: $branchId, isActive: $isActive, lastSeenAt: $lastSeenAt, appVersion: $appVersion, online: $online)';
}


}

/// @nodoc
abstract mixin class $CallDeviceCopyWith<$Res>  {
  factory $CallDeviceCopyWith(CallDevice value, $Res Function(CallDevice) _then) = _$CallDeviceCopyWithImpl;
@useResult
$Res call({
 String id, String label, String? phoneNumber, String? branchId, bool isActive, String? lastSeenAt, String? appVersion, bool online
});




}
/// @nodoc
class _$CallDeviceCopyWithImpl<$Res>
    implements $CallDeviceCopyWith<$Res> {
  _$CallDeviceCopyWithImpl(this._self, this._then);

  final CallDevice _self;
  final $Res Function(CallDevice) _then;

/// Create a copy of CallDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? phoneNumber = freezed,Object? branchId = freezed,Object? isActive = null,Object? lastSeenAt = freezed,Object? appVersion = freezed,Object? online = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as String?,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CallDevice].
extension CallDevicePatterns on CallDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallDevice value)  $default,){
final _that = this;
switch (_that) {
case _CallDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallDevice value)?  $default,){
final _that = this;
switch (_that) {
case _CallDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String? phoneNumber,  String? branchId,  bool isActive,  String? lastSeenAt,  String? appVersion,  bool online)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallDevice() when $default != null:
return $default(_that.id,_that.label,_that.phoneNumber,_that.branchId,_that.isActive,_that.lastSeenAt,_that.appVersion,_that.online);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String? phoneNumber,  String? branchId,  bool isActive,  String? lastSeenAt,  String? appVersion,  bool online)  $default,) {final _that = this;
switch (_that) {
case _CallDevice():
return $default(_that.id,_that.label,_that.phoneNumber,_that.branchId,_that.isActive,_that.lastSeenAt,_that.appVersion,_that.online);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String? phoneNumber,  String? branchId,  bool isActive,  String? lastSeenAt,  String? appVersion,  bool online)?  $default,) {final _that = this;
switch (_that) {
case _CallDevice() when $default != null:
return $default(_that.id,_that.label,_that.phoneNumber,_that.branchId,_that.isActive,_that.lastSeenAt,_that.appVersion,_that.online);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CallDevice extends CallDevice {
  const _CallDevice({required this.id, required this.label, this.phoneNumber, this.branchId, this.isActive = true, this.lastSeenAt, this.appVersion, this.online = false}): super._();
  factory _CallDevice.fromJson(Map<String, dynamic> json) => _$CallDeviceFromJson(json);

@override final  String id;
@override final  String label;
@override final  String? phoneNumber;
@override final  String? branchId;
@override@JsonKey() final  bool isActive;
@override final  String? lastSeenAt;
@override final  String? appVersion;
@override@JsonKey() final  bool online;

/// Create a copy of CallDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallDeviceCopyWith<_CallDevice> get copyWith => __$CallDeviceCopyWithImpl<_CallDevice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CallDeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.online, online) || other.online == online));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,phoneNumber,branchId,isActive,lastSeenAt,appVersion,online);

@override
String toString() {
  return 'CallDevice(id: $id, label: $label, phoneNumber: $phoneNumber, branchId: $branchId, isActive: $isActive, lastSeenAt: $lastSeenAt, appVersion: $appVersion, online: $online)';
}


}

/// @nodoc
abstract mixin class _$CallDeviceCopyWith<$Res> implements $CallDeviceCopyWith<$Res> {
  factory _$CallDeviceCopyWith(_CallDevice value, $Res Function(_CallDevice) _then) = __$CallDeviceCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String? phoneNumber, String? branchId, bool isActive, String? lastSeenAt, String? appVersion, bool online
});




}
/// @nodoc
class __$CallDeviceCopyWithImpl<$Res>
    implements _$CallDeviceCopyWith<$Res> {
  __$CallDeviceCopyWithImpl(this._self, this._then);

  final _CallDevice _self;
  final $Res Function(_CallDevice) _then;

/// Create a copy of CallDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? phoneNumber = freezed,Object? branchId = freezed,Object? isActive = null,Object? lastSeenAt = freezed,Object? appVersion = freezed,Object? online = null,}) {
  return _then(_CallDevice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as String?,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
