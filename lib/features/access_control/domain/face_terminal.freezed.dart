// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'face_terminal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FaceTerminal {

 String get id; String get name; String get host; int get port; String get username; int get doorNo; bool get useHttps; String? get branchId; String? get branchName; String get status; bool get online; DateTime? get lastSeen; Map<String, dynamic>? get deviceInfo; DateTime get createdAt;
/// Create a copy of FaceTerminal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FaceTerminalCopyWith<FaceTerminal> get copyWith => _$FaceTerminalCopyWithImpl<FaceTerminal>(this as FaceTerminal, _$identity);

  /// Serializes this FaceTerminal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaceTerminal&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.username, username) || other.username == username)&&(identical(other.doorNo, doorNo) || other.doorNo == doorNo)&&(identical(other.useHttps, useHttps) || other.useHttps == useHttps)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.status, status) || other.status == status)&&(identical(other.online, online) || other.online == online)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&const DeepCollectionEquality().equals(other.deviceInfo, deviceInfo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,host,port,username,doorNo,useHttps,branchId,branchName,status,online,lastSeen,const DeepCollectionEquality().hash(deviceInfo),createdAt);

@override
String toString() {
  return 'FaceTerminal(id: $id, name: $name, host: $host, port: $port, username: $username, doorNo: $doorNo, useHttps: $useHttps, branchId: $branchId, branchName: $branchName, status: $status, online: $online, lastSeen: $lastSeen, deviceInfo: $deviceInfo, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FaceTerminalCopyWith<$Res>  {
  factory $FaceTerminalCopyWith(FaceTerminal value, $Res Function(FaceTerminal) _then) = _$FaceTerminalCopyWithImpl;
@useResult
$Res call({
 String id, String name, String host, int port, String username, int doorNo, bool useHttps, String? branchId, String? branchName, String status, bool online, DateTime? lastSeen, Map<String, dynamic>? deviceInfo, DateTime createdAt
});




}
/// @nodoc
class _$FaceTerminalCopyWithImpl<$Res>
    implements $FaceTerminalCopyWith<$Res> {
  _$FaceTerminalCopyWithImpl(this._self, this._then);

  final FaceTerminal _self;
  final $Res Function(FaceTerminal) _then;

/// Create a copy of FaceTerminal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? host = null,Object? port = null,Object? username = null,Object? doorNo = null,Object? useHttps = null,Object? branchId = freezed,Object? branchName = freezed,Object? status = null,Object? online = null,Object? lastSeen = freezed,Object? deviceInfo = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,doorNo: null == doorNo ? _self.doorNo : doorNo // ignore: cast_nullable_to_non_nullable
as int,useHttps: null == useHttps ? _self.useHttps : useHttps // ignore: cast_nullable_to_non_nullable
as bool,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,branchName: freezed == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime?,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FaceTerminal].
extension FaceTerminalPatterns on FaceTerminal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FaceTerminal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FaceTerminal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FaceTerminal value)  $default,){
final _that = this;
switch (_that) {
case _FaceTerminal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FaceTerminal value)?  $default,){
final _that = this;
switch (_that) {
case _FaceTerminal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String host,  int port,  String username,  int doorNo,  bool useHttps,  String? branchId,  String? branchName,  String status,  bool online,  DateTime? lastSeen,  Map<String, dynamic>? deviceInfo,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FaceTerminal() when $default != null:
return $default(_that.id,_that.name,_that.host,_that.port,_that.username,_that.doorNo,_that.useHttps,_that.branchId,_that.branchName,_that.status,_that.online,_that.lastSeen,_that.deviceInfo,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String host,  int port,  String username,  int doorNo,  bool useHttps,  String? branchId,  String? branchName,  String status,  bool online,  DateTime? lastSeen,  Map<String, dynamic>? deviceInfo,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _FaceTerminal():
return $default(_that.id,_that.name,_that.host,_that.port,_that.username,_that.doorNo,_that.useHttps,_that.branchId,_that.branchName,_that.status,_that.online,_that.lastSeen,_that.deviceInfo,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String host,  int port,  String username,  int doorNo,  bool useHttps,  String? branchId,  String? branchName,  String status,  bool online,  DateTime? lastSeen,  Map<String, dynamic>? deviceInfo,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _FaceTerminal() when $default != null:
return $default(_that.id,_that.name,_that.host,_that.port,_that.username,_that.doorNo,_that.useHttps,_that.branchId,_that.branchName,_that.status,_that.online,_that.lastSeen,_that.deviceInfo,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FaceTerminal implements FaceTerminal {
  const _FaceTerminal({required this.id, required this.name, required this.host, required this.port, required this.username, required this.doorNo, this.useHttps = false, this.branchId, this.branchName, this.status = 'active', this.online = false, this.lastSeen, final  Map<String, dynamic>? deviceInfo, required this.createdAt}): _deviceInfo = deviceInfo;
  factory _FaceTerminal.fromJson(Map<String, dynamic> json) => _$FaceTerminalFromJson(json);

@override final  String id;
@override final  String name;
@override final  String host;
@override final  int port;
@override final  String username;
@override final  int doorNo;
@override@JsonKey() final  bool useHttps;
@override final  String? branchId;
@override final  String? branchName;
@override@JsonKey() final  String status;
@override@JsonKey() final  bool online;
@override final  DateTime? lastSeen;
 final  Map<String, dynamic>? _deviceInfo;
@override Map<String, dynamic>? get deviceInfo {
  final value = _deviceInfo;
  if (value == null) return null;
  if (_deviceInfo is EqualUnmodifiableMapView) return _deviceInfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime createdAt;

/// Create a copy of FaceTerminal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FaceTerminalCopyWith<_FaceTerminal> get copyWith => __$FaceTerminalCopyWithImpl<_FaceTerminal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FaceTerminalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FaceTerminal&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.username, username) || other.username == username)&&(identical(other.doorNo, doorNo) || other.doorNo == doorNo)&&(identical(other.useHttps, useHttps) || other.useHttps == useHttps)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.status, status) || other.status == status)&&(identical(other.online, online) || other.online == online)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&const DeepCollectionEquality().equals(other._deviceInfo, _deviceInfo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,host,port,username,doorNo,useHttps,branchId,branchName,status,online,lastSeen,const DeepCollectionEquality().hash(_deviceInfo),createdAt);

@override
String toString() {
  return 'FaceTerminal(id: $id, name: $name, host: $host, port: $port, username: $username, doorNo: $doorNo, useHttps: $useHttps, branchId: $branchId, branchName: $branchName, status: $status, online: $online, lastSeen: $lastSeen, deviceInfo: $deviceInfo, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FaceTerminalCopyWith<$Res> implements $FaceTerminalCopyWith<$Res> {
  factory _$FaceTerminalCopyWith(_FaceTerminal value, $Res Function(_FaceTerminal) _then) = __$FaceTerminalCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String host, int port, String username, int doorNo, bool useHttps, String? branchId, String? branchName, String status, bool online, DateTime? lastSeen, Map<String, dynamic>? deviceInfo, DateTime createdAt
});




}
/// @nodoc
class __$FaceTerminalCopyWithImpl<$Res>
    implements _$FaceTerminalCopyWith<$Res> {
  __$FaceTerminalCopyWithImpl(this._self, this._then);

  final _FaceTerminal _self;
  final $Res Function(_FaceTerminal) _then;

/// Create a copy of FaceTerminal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? host = null,Object? port = null,Object? username = null,Object? doorNo = null,Object? useHttps = null,Object? branchId = freezed,Object? branchName = freezed,Object? status = null,Object? online = null,Object? lastSeen = freezed,Object? deviceInfo = freezed,Object? createdAt = null,}) {
  return _then(_FaceTerminal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,doorNo: null == doorNo ? _self.doorNo : doorNo // ignore: cast_nullable_to_non_nullable
as int,useHttps: null == useHttps ? _self.useHttps : useHttps // ignore: cast_nullable_to_non_nullable
as bool,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,branchName: freezed == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime?,deviceInfo: freezed == deviceInfo ? _self._deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$TerminalTestResult {

 bool get online; String? get model; String? get firmware; String? get serial; String? get deviceName; String? get error;
/// Create a copy of TerminalTestResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TerminalTestResultCopyWith<TerminalTestResult> get copyWith => _$TerminalTestResultCopyWithImpl<TerminalTestResult>(this as TerminalTestResult, _$identity);

  /// Serializes this TerminalTestResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TerminalTestResult&&(identical(other.online, online) || other.online == online)&&(identical(other.model, model) || other.model == model)&&(identical(other.firmware, firmware) || other.firmware == firmware)&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,online,model,firmware,serial,deviceName,error);

@override
String toString() {
  return 'TerminalTestResult(online: $online, model: $model, firmware: $firmware, serial: $serial, deviceName: $deviceName, error: $error)';
}


}

/// @nodoc
abstract mixin class $TerminalTestResultCopyWith<$Res>  {
  factory $TerminalTestResultCopyWith(TerminalTestResult value, $Res Function(TerminalTestResult) _then) = _$TerminalTestResultCopyWithImpl;
@useResult
$Res call({
 bool online, String? model, String? firmware, String? serial, String? deviceName, String? error
});




}
/// @nodoc
class _$TerminalTestResultCopyWithImpl<$Res>
    implements $TerminalTestResultCopyWith<$Res> {
  _$TerminalTestResultCopyWithImpl(this._self, this._then);

  final TerminalTestResult _self;
  final $Res Function(TerminalTestResult) _then;

/// Create a copy of TerminalTestResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? online = null,Object? model = freezed,Object? firmware = freezed,Object? serial = freezed,Object? deviceName = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,firmware: freezed == firmware ? _self.firmware : firmware // ignore: cast_nullable_to_non_nullable
as String?,serial: freezed == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as String?,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TerminalTestResult].
extension TerminalTestResultPatterns on TerminalTestResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TerminalTestResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TerminalTestResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TerminalTestResult value)  $default,){
final _that = this;
switch (_that) {
case _TerminalTestResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TerminalTestResult value)?  $default,){
final _that = this;
switch (_that) {
case _TerminalTestResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool online,  String? model,  String? firmware,  String? serial,  String? deviceName,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TerminalTestResult() when $default != null:
return $default(_that.online,_that.model,_that.firmware,_that.serial,_that.deviceName,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool online,  String? model,  String? firmware,  String? serial,  String? deviceName,  String? error)  $default,) {final _that = this;
switch (_that) {
case _TerminalTestResult():
return $default(_that.online,_that.model,_that.firmware,_that.serial,_that.deviceName,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool online,  String? model,  String? firmware,  String? serial,  String? deviceName,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _TerminalTestResult() when $default != null:
return $default(_that.online,_that.model,_that.firmware,_that.serial,_that.deviceName,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TerminalTestResult implements TerminalTestResult {
  const _TerminalTestResult({required this.online, this.model, this.firmware, this.serial, this.deviceName, this.error});
  factory _TerminalTestResult.fromJson(Map<String, dynamic> json) => _$TerminalTestResultFromJson(json);

@override final  bool online;
@override final  String? model;
@override final  String? firmware;
@override final  String? serial;
@override final  String? deviceName;
@override final  String? error;

/// Create a copy of TerminalTestResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TerminalTestResultCopyWith<_TerminalTestResult> get copyWith => __$TerminalTestResultCopyWithImpl<_TerminalTestResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TerminalTestResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TerminalTestResult&&(identical(other.online, online) || other.online == online)&&(identical(other.model, model) || other.model == model)&&(identical(other.firmware, firmware) || other.firmware == firmware)&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,online,model,firmware,serial,deviceName,error);

@override
String toString() {
  return 'TerminalTestResult(online: $online, model: $model, firmware: $firmware, serial: $serial, deviceName: $deviceName, error: $error)';
}


}

/// @nodoc
abstract mixin class _$TerminalTestResultCopyWith<$Res> implements $TerminalTestResultCopyWith<$Res> {
  factory _$TerminalTestResultCopyWith(_TerminalTestResult value, $Res Function(_TerminalTestResult) _then) = __$TerminalTestResultCopyWithImpl;
@override @useResult
$Res call({
 bool online, String? model, String? firmware, String? serial, String? deviceName, String? error
});




}
/// @nodoc
class __$TerminalTestResultCopyWithImpl<$Res>
    implements _$TerminalTestResultCopyWith<$Res> {
  __$TerminalTestResultCopyWithImpl(this._self, this._then);

  final _TerminalTestResult _self;
  final $Res Function(_TerminalTestResult) _then;

/// Create a copy of TerminalTestResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? online = null,Object? model = freezed,Object? firmware = freezed,Object? serial = freezed,Object? deviceName = freezed,Object? error = freezed,}) {
  return _then(_TerminalTestResult(
online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,firmware: freezed == firmware ? _self.firmware : firmware // ignore: cast_nullable_to_non_nullable
as String?,serial: freezed == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as String?,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
