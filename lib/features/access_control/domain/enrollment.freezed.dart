// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enrollment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EnrollmentRow {

 String get userId; String get fullName; String get email; String? get branchId; String? get faceidEmployeeNo; bool get enrolled;
/// Create a copy of EnrollmentRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrollmentRowCopyWith<EnrollmentRow> get copyWith => _$EnrollmentRowCopyWithImpl<EnrollmentRow>(this as EnrollmentRow, _$identity);

  /// Serializes this EnrollmentRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrollmentRow&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.faceidEmployeeNo, faceidEmployeeNo) || other.faceidEmployeeNo == faceidEmployeeNo)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,email,branchId,faceidEmployeeNo,enrolled);

@override
String toString() {
  return 'EnrollmentRow(userId: $userId, fullName: $fullName, email: $email, branchId: $branchId, faceidEmployeeNo: $faceidEmployeeNo, enrolled: $enrolled)';
}


}

/// @nodoc
abstract mixin class $EnrollmentRowCopyWith<$Res>  {
  factory $EnrollmentRowCopyWith(EnrollmentRow value, $Res Function(EnrollmentRow) _then) = _$EnrollmentRowCopyWithImpl;
@useResult
$Res call({
 String userId, String fullName, String email, String? branchId, String? faceidEmployeeNo, bool enrolled
});




}
/// @nodoc
class _$EnrollmentRowCopyWithImpl<$Res>
    implements $EnrollmentRowCopyWith<$Res> {
  _$EnrollmentRowCopyWithImpl(this._self, this._then);

  final EnrollmentRow _self;
  final $Res Function(EnrollmentRow) _then;

/// Create a copy of EnrollmentRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? email = null,Object? branchId = freezed,Object? faceidEmployeeNo = freezed,Object? enrolled = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,faceidEmployeeNo: freezed == faceidEmployeeNo ? _self.faceidEmployeeNo : faceidEmployeeNo // ignore: cast_nullable_to_non_nullable
as String?,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EnrollmentRow].
extension EnrollmentRowPatterns on EnrollmentRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnrollmentRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnrollmentRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnrollmentRow value)  $default,){
final _that = this;
switch (_that) {
case _EnrollmentRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnrollmentRow value)?  $default,){
final _that = this;
switch (_that) {
case _EnrollmentRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fullName,  String email,  String? branchId,  String? faceidEmployeeNo,  bool enrolled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnrollmentRow() when $default != null:
return $default(_that.userId,_that.fullName,_that.email,_that.branchId,_that.faceidEmployeeNo,_that.enrolled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fullName,  String email,  String? branchId,  String? faceidEmployeeNo,  bool enrolled)  $default,) {final _that = this;
switch (_that) {
case _EnrollmentRow():
return $default(_that.userId,_that.fullName,_that.email,_that.branchId,_that.faceidEmployeeNo,_that.enrolled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fullName,  String email,  String? branchId,  String? faceidEmployeeNo,  bool enrolled)?  $default,) {final _that = this;
switch (_that) {
case _EnrollmentRow() when $default != null:
return $default(_that.userId,_that.fullName,_that.email,_that.branchId,_that.faceidEmployeeNo,_that.enrolled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnrollmentRow implements EnrollmentRow {
  const _EnrollmentRow({required this.userId, required this.fullName, required this.email, this.branchId, this.faceidEmployeeNo, required this.enrolled});
  factory _EnrollmentRow.fromJson(Map<String, dynamic> json) => _$EnrollmentRowFromJson(json);

@override final  String userId;
@override final  String fullName;
@override final  String email;
@override final  String? branchId;
@override final  String? faceidEmployeeNo;
@override final  bool enrolled;

/// Create a copy of EnrollmentRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrollmentRowCopyWith<_EnrollmentRow> get copyWith => __$EnrollmentRowCopyWithImpl<_EnrollmentRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnrollmentRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrollmentRow&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.faceidEmployeeNo, faceidEmployeeNo) || other.faceidEmployeeNo == faceidEmployeeNo)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,email,branchId,faceidEmployeeNo,enrolled);

@override
String toString() {
  return 'EnrollmentRow(userId: $userId, fullName: $fullName, email: $email, branchId: $branchId, faceidEmployeeNo: $faceidEmployeeNo, enrolled: $enrolled)';
}


}

/// @nodoc
abstract mixin class _$EnrollmentRowCopyWith<$Res> implements $EnrollmentRowCopyWith<$Res> {
  factory _$EnrollmentRowCopyWith(_EnrollmentRow value, $Res Function(_EnrollmentRow) _then) = __$EnrollmentRowCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fullName, String email, String? branchId, String? faceidEmployeeNo, bool enrolled
});




}
/// @nodoc
class __$EnrollmentRowCopyWithImpl<$Res>
    implements _$EnrollmentRowCopyWith<$Res> {
  __$EnrollmentRowCopyWithImpl(this._self, this._then);

  final _EnrollmentRow _self;
  final $Res Function(_EnrollmentRow) _then;

/// Create a copy of EnrollmentRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? email = null,Object? branchId = freezed,Object? faceidEmployeeNo = freezed,Object? enrolled = null,}) {
  return _then(_EnrollmentRow(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,faceidEmployeeNo: freezed == faceidEmployeeNo ? _self.faceidEmployeeNo : faceidEmployeeNo // ignore: cast_nullable_to_non_nullable
as String?,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$EnrollResult {

 String get userId; String get faceidEmployeeNo; bool get pushedToDevice; bool get faceUploaded; String? get error;
/// Create a copy of EnrollResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrollResultCopyWith<EnrollResult> get copyWith => _$EnrollResultCopyWithImpl<EnrollResult>(this as EnrollResult, _$identity);

  /// Serializes this EnrollResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrollResult&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.faceidEmployeeNo, faceidEmployeeNo) || other.faceidEmployeeNo == faceidEmployeeNo)&&(identical(other.pushedToDevice, pushedToDevice) || other.pushedToDevice == pushedToDevice)&&(identical(other.faceUploaded, faceUploaded) || other.faceUploaded == faceUploaded)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,faceidEmployeeNo,pushedToDevice,faceUploaded,error);

@override
String toString() {
  return 'EnrollResult(userId: $userId, faceidEmployeeNo: $faceidEmployeeNo, pushedToDevice: $pushedToDevice, faceUploaded: $faceUploaded, error: $error)';
}


}

/// @nodoc
abstract mixin class $EnrollResultCopyWith<$Res>  {
  factory $EnrollResultCopyWith(EnrollResult value, $Res Function(EnrollResult) _then) = _$EnrollResultCopyWithImpl;
@useResult
$Res call({
 String userId, String faceidEmployeeNo, bool pushedToDevice, bool faceUploaded, String? error
});




}
/// @nodoc
class _$EnrollResultCopyWithImpl<$Res>
    implements $EnrollResultCopyWith<$Res> {
  _$EnrollResultCopyWithImpl(this._self, this._then);

  final EnrollResult _self;
  final $Res Function(EnrollResult) _then;

/// Create a copy of EnrollResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? faceidEmployeeNo = null,Object? pushedToDevice = null,Object? faceUploaded = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,faceidEmployeeNo: null == faceidEmployeeNo ? _self.faceidEmployeeNo : faceidEmployeeNo // ignore: cast_nullable_to_non_nullable
as String,pushedToDevice: null == pushedToDevice ? _self.pushedToDevice : pushedToDevice // ignore: cast_nullable_to_non_nullable
as bool,faceUploaded: null == faceUploaded ? _self.faceUploaded : faceUploaded // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EnrollResult].
extension EnrollResultPatterns on EnrollResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnrollResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnrollResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnrollResult value)  $default,){
final _that = this;
switch (_that) {
case _EnrollResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnrollResult value)?  $default,){
final _that = this;
switch (_that) {
case _EnrollResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String faceidEmployeeNo,  bool pushedToDevice,  bool faceUploaded,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnrollResult() when $default != null:
return $default(_that.userId,_that.faceidEmployeeNo,_that.pushedToDevice,_that.faceUploaded,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String faceidEmployeeNo,  bool pushedToDevice,  bool faceUploaded,  String? error)  $default,) {final _that = this;
switch (_that) {
case _EnrollResult():
return $default(_that.userId,_that.faceidEmployeeNo,_that.pushedToDevice,_that.faceUploaded,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String faceidEmployeeNo,  bool pushedToDevice,  bool faceUploaded,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _EnrollResult() when $default != null:
return $default(_that.userId,_that.faceidEmployeeNo,_that.pushedToDevice,_that.faceUploaded,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnrollResult implements EnrollResult {
  const _EnrollResult({required this.userId, required this.faceidEmployeeNo, required this.pushedToDevice, this.faceUploaded = false, this.error});
  factory _EnrollResult.fromJson(Map<String, dynamic> json) => _$EnrollResultFromJson(json);

@override final  String userId;
@override final  String faceidEmployeeNo;
@override final  bool pushedToDevice;
@override@JsonKey() final  bool faceUploaded;
@override final  String? error;

/// Create a copy of EnrollResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrollResultCopyWith<_EnrollResult> get copyWith => __$EnrollResultCopyWithImpl<_EnrollResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnrollResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrollResult&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.faceidEmployeeNo, faceidEmployeeNo) || other.faceidEmployeeNo == faceidEmployeeNo)&&(identical(other.pushedToDevice, pushedToDevice) || other.pushedToDevice == pushedToDevice)&&(identical(other.faceUploaded, faceUploaded) || other.faceUploaded == faceUploaded)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,faceidEmployeeNo,pushedToDevice,faceUploaded,error);

@override
String toString() {
  return 'EnrollResult(userId: $userId, faceidEmployeeNo: $faceidEmployeeNo, pushedToDevice: $pushedToDevice, faceUploaded: $faceUploaded, error: $error)';
}


}

/// @nodoc
abstract mixin class _$EnrollResultCopyWith<$Res> implements $EnrollResultCopyWith<$Res> {
  factory _$EnrollResultCopyWith(_EnrollResult value, $Res Function(_EnrollResult) _then) = __$EnrollResultCopyWithImpl;
@override @useResult
$Res call({
 String userId, String faceidEmployeeNo, bool pushedToDevice, bool faceUploaded, String? error
});




}
/// @nodoc
class __$EnrollResultCopyWithImpl<$Res>
    implements _$EnrollResultCopyWith<$Res> {
  __$EnrollResultCopyWithImpl(this._self, this._then);

  final _EnrollResult _self;
  final $Res Function(_EnrollResult) _then;

/// Create a copy of EnrollResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? faceidEmployeeNo = null,Object? pushedToDevice = null,Object? faceUploaded = null,Object? error = freezed,}) {
  return _then(_EnrollResult(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,faceidEmployeeNo: null == faceidEmployeeNo ? _self.faceidEmployeeNo : faceidEmployeeNo // ignore: cast_nullable_to_non_nullable
as String,pushedToDevice: null == pushedToDevice ? _self.pushedToDevice : pushedToDevice // ignore: cast_nullable_to_non_nullable
as bool,faceUploaded: null == faceUploaded ? _self.faceUploaded : faceUploaded // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
