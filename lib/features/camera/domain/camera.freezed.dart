// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'camera.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Camera {

 String get id; String get name; String get host; int get port; String get username; bool get useHttps; String get vendor; int get channelNo; String? get snapshotPath; String? get branchId; String? get branchName; String get status; bool get online; String? get lastSeen; Map<String, dynamic>? get deviceInfo; String get createdAt;
/// Create a copy of Camera
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CameraCopyWith<Camera> get copyWith => _$CameraCopyWithImpl<Camera>(this as Camera, _$identity);

  /// Serializes this Camera to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Camera&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.username, username) || other.username == username)&&(identical(other.useHttps, useHttps) || other.useHttps == useHttps)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.channelNo, channelNo) || other.channelNo == channelNo)&&(identical(other.snapshotPath, snapshotPath) || other.snapshotPath == snapshotPath)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.status, status) || other.status == status)&&(identical(other.online, online) || other.online == online)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&const DeepCollectionEquality().equals(other.deviceInfo, deviceInfo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,host,port,username,useHttps,vendor,channelNo,snapshotPath,branchId,branchName,status,online,lastSeen,const DeepCollectionEquality().hash(deviceInfo),createdAt);

@override
String toString() {
  return 'Camera(id: $id, name: $name, host: $host, port: $port, username: $username, useHttps: $useHttps, vendor: $vendor, channelNo: $channelNo, snapshotPath: $snapshotPath, branchId: $branchId, branchName: $branchName, status: $status, online: $online, lastSeen: $lastSeen, deviceInfo: $deviceInfo, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CameraCopyWith<$Res>  {
  factory $CameraCopyWith(Camera value, $Res Function(Camera) _then) = _$CameraCopyWithImpl;
@useResult
$Res call({
 String id, String name, String host, int port, String username, bool useHttps, String vendor, int channelNo, String? snapshotPath, String? branchId, String? branchName, String status, bool online, String? lastSeen, Map<String, dynamic>? deviceInfo, String createdAt
});




}
/// @nodoc
class _$CameraCopyWithImpl<$Res>
    implements $CameraCopyWith<$Res> {
  _$CameraCopyWithImpl(this._self, this._then);

  final Camera _self;
  final $Res Function(Camera) _then;

/// Create a copy of Camera
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? host = null,Object? port = null,Object? username = null,Object? useHttps = null,Object? vendor = null,Object? channelNo = null,Object? snapshotPath = freezed,Object? branchId = freezed,Object? branchName = freezed,Object? status = null,Object? online = null,Object? lastSeen = freezed,Object? deviceInfo = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,useHttps: null == useHttps ? _self.useHttps : useHttps // ignore: cast_nullable_to_non_nullable
as bool,vendor: null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as String,channelNo: null == channelNo ? _self.channelNo : channelNo // ignore: cast_nullable_to_non_nullable
as int,snapshotPath: freezed == snapshotPath ? _self.snapshotPath : snapshotPath // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,branchName: freezed == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Camera].
extension CameraPatterns on Camera {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Camera value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Camera() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Camera value)  $default,){
final _that = this;
switch (_that) {
case _Camera():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Camera value)?  $default,){
final _that = this;
switch (_that) {
case _Camera() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String host,  int port,  String username,  bool useHttps,  String vendor,  int channelNo,  String? snapshotPath,  String? branchId,  String? branchName,  String status,  bool online,  String? lastSeen,  Map<String, dynamic>? deviceInfo,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Camera() when $default != null:
return $default(_that.id,_that.name,_that.host,_that.port,_that.username,_that.useHttps,_that.vendor,_that.channelNo,_that.snapshotPath,_that.branchId,_that.branchName,_that.status,_that.online,_that.lastSeen,_that.deviceInfo,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String host,  int port,  String username,  bool useHttps,  String vendor,  int channelNo,  String? snapshotPath,  String? branchId,  String? branchName,  String status,  bool online,  String? lastSeen,  Map<String, dynamic>? deviceInfo,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _Camera():
return $default(_that.id,_that.name,_that.host,_that.port,_that.username,_that.useHttps,_that.vendor,_that.channelNo,_that.snapshotPath,_that.branchId,_that.branchName,_that.status,_that.online,_that.lastSeen,_that.deviceInfo,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String host,  int port,  String username,  bool useHttps,  String vendor,  int channelNo,  String? snapshotPath,  String? branchId,  String? branchName,  String status,  bool online,  String? lastSeen,  Map<String, dynamic>? deviceInfo,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Camera() when $default != null:
return $default(_that.id,_that.name,_that.host,_that.port,_that.username,_that.useHttps,_that.vendor,_that.channelNo,_that.snapshotPath,_that.branchId,_that.branchName,_that.status,_that.online,_that.lastSeen,_that.deviceInfo,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Camera extends Camera {
  const _Camera({required this.id, required this.name, required this.host, required this.port, required this.username, this.useHttps = false, this.vendor = 'hikvision', this.channelNo = 1, this.snapshotPath, this.branchId, this.branchName, required this.status, this.online = false, this.lastSeen, final  Map<String, dynamic>? deviceInfo, required this.createdAt}): _deviceInfo = deviceInfo,super._();
  factory _Camera.fromJson(Map<String, dynamic> json) => _$CameraFromJson(json);

@override final  String id;
@override final  String name;
@override final  String host;
@override final  int port;
@override final  String username;
@override@JsonKey() final  bool useHttps;
@override@JsonKey() final  String vendor;
@override@JsonKey() final  int channelNo;
@override final  String? snapshotPath;
@override final  String? branchId;
@override final  String? branchName;
@override final  String status;
@override@JsonKey() final  bool online;
@override final  String? lastSeen;
 final  Map<String, dynamic>? _deviceInfo;
@override Map<String, dynamic>? get deviceInfo {
  final value = _deviceInfo;
  if (value == null) return null;
  if (_deviceInfo is EqualUnmodifiableMapView) return _deviceInfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String createdAt;

/// Create a copy of Camera
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CameraCopyWith<_Camera> get copyWith => __$CameraCopyWithImpl<_Camera>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CameraToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Camera&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.username, username) || other.username == username)&&(identical(other.useHttps, useHttps) || other.useHttps == useHttps)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.channelNo, channelNo) || other.channelNo == channelNo)&&(identical(other.snapshotPath, snapshotPath) || other.snapshotPath == snapshotPath)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.status, status) || other.status == status)&&(identical(other.online, online) || other.online == online)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&const DeepCollectionEquality().equals(other._deviceInfo, _deviceInfo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,host,port,username,useHttps,vendor,channelNo,snapshotPath,branchId,branchName,status,online,lastSeen,const DeepCollectionEquality().hash(_deviceInfo),createdAt);

@override
String toString() {
  return 'Camera(id: $id, name: $name, host: $host, port: $port, username: $username, useHttps: $useHttps, vendor: $vendor, channelNo: $channelNo, snapshotPath: $snapshotPath, branchId: $branchId, branchName: $branchName, status: $status, online: $online, lastSeen: $lastSeen, deviceInfo: $deviceInfo, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CameraCopyWith<$Res> implements $CameraCopyWith<$Res> {
  factory _$CameraCopyWith(_Camera value, $Res Function(_Camera) _then) = __$CameraCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String host, int port, String username, bool useHttps, String vendor, int channelNo, String? snapshotPath, String? branchId, String? branchName, String status, bool online, String? lastSeen, Map<String, dynamic>? deviceInfo, String createdAt
});




}
/// @nodoc
class __$CameraCopyWithImpl<$Res>
    implements _$CameraCopyWith<$Res> {
  __$CameraCopyWithImpl(this._self, this._then);

  final _Camera _self;
  final $Res Function(_Camera) _then;

/// Create a copy of Camera
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? host = null,Object? port = null,Object? username = null,Object? useHttps = null,Object? vendor = null,Object? channelNo = null,Object? snapshotPath = freezed,Object? branchId = freezed,Object? branchName = freezed,Object? status = null,Object? online = null,Object? lastSeen = freezed,Object? deviceInfo = freezed,Object? createdAt = null,}) {
  return _then(_Camera(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,useHttps: null == useHttps ? _self.useHttps : useHttps // ignore: cast_nullable_to_non_nullable
as bool,vendor: null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as String,channelNo: null == channelNo ? _self.channelNo : channelNo // ignore: cast_nullable_to_non_nullable
as int,snapshotPath: freezed == snapshotPath ? _self.snapshotPath : snapshotPath // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,branchName: freezed == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,deviceInfo: freezed == deviceInfo ? _self._deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
