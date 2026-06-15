// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StaffNow {

 String get userId; String get fullName; String? get role; String get status;// present | left | absent
 String? get lastDirection;// in | out
 String? get lastEventAt; String? get firstIn; bool get late; int get workedMinutes;
/// Create a copy of StaffNow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffNowCopyWith<StaffNow> get copyWith => _$StaffNowCopyWithImpl<StaffNow>(this as StaffNow, _$identity);

  /// Serializes this StaffNow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffNow&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastDirection, lastDirection) || other.lastDirection == lastDirection)&&(identical(other.lastEventAt, lastEventAt) || other.lastEventAt == lastEventAt)&&(identical(other.firstIn, firstIn) || other.firstIn == firstIn)&&(identical(other.late, late) || other.late == late)&&(identical(other.workedMinutes, workedMinutes) || other.workedMinutes == workedMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,role,status,lastDirection,lastEventAt,firstIn,late,workedMinutes);

@override
String toString() {
  return 'StaffNow(userId: $userId, fullName: $fullName, role: $role, status: $status, lastDirection: $lastDirection, lastEventAt: $lastEventAt, firstIn: $firstIn, late: $late, workedMinutes: $workedMinutes)';
}


}

/// @nodoc
abstract mixin class $StaffNowCopyWith<$Res>  {
  factory $StaffNowCopyWith(StaffNow value, $Res Function(StaffNow) _then) = _$StaffNowCopyWithImpl;
@useResult
$Res call({
 String userId, String fullName, String? role, String status, String? lastDirection, String? lastEventAt, String? firstIn, bool late, int workedMinutes
});




}
/// @nodoc
class _$StaffNowCopyWithImpl<$Res>
    implements $StaffNowCopyWith<$Res> {
  _$StaffNowCopyWithImpl(this._self, this._then);

  final StaffNow _self;
  final $Res Function(StaffNow) _then;

/// Create a copy of StaffNow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? role = freezed,Object? status = null,Object? lastDirection = freezed,Object? lastEventAt = freezed,Object? firstIn = freezed,Object? late = null,Object? workedMinutes = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastDirection: freezed == lastDirection ? _self.lastDirection : lastDirection // ignore: cast_nullable_to_non_nullable
as String?,lastEventAt: freezed == lastEventAt ? _self.lastEventAt : lastEventAt // ignore: cast_nullable_to_non_nullable
as String?,firstIn: freezed == firstIn ? _self.firstIn : firstIn // ignore: cast_nullable_to_non_nullable
as String?,late: null == late ? _self.late : late // ignore: cast_nullable_to_non_nullable
as bool,workedMinutes: null == workedMinutes ? _self.workedMinutes : workedMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffNow].
extension StaffNowPatterns on StaffNow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffNow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffNow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffNow value)  $default,){
final _that = this;
switch (_that) {
case _StaffNow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffNow value)?  $default,){
final _that = this;
switch (_that) {
case _StaffNow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fullName,  String? role,  String status,  String? lastDirection,  String? lastEventAt,  String? firstIn,  bool late,  int workedMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffNow() when $default != null:
return $default(_that.userId,_that.fullName,_that.role,_that.status,_that.lastDirection,_that.lastEventAt,_that.firstIn,_that.late,_that.workedMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fullName,  String? role,  String status,  String? lastDirection,  String? lastEventAt,  String? firstIn,  bool late,  int workedMinutes)  $default,) {final _that = this;
switch (_that) {
case _StaffNow():
return $default(_that.userId,_that.fullName,_that.role,_that.status,_that.lastDirection,_that.lastEventAt,_that.firstIn,_that.late,_that.workedMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fullName,  String? role,  String status,  String? lastDirection,  String? lastEventAt,  String? firstIn,  bool late,  int workedMinutes)?  $default,) {final _that = this;
switch (_that) {
case _StaffNow() when $default != null:
return $default(_that.userId,_that.fullName,_that.role,_that.status,_that.lastDirection,_that.lastEventAt,_that.firstIn,_that.late,_that.workedMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffNow extends StaffNow {
  const _StaffNow({required this.userId, required this.fullName, this.role, required this.status, this.lastDirection, this.lastEventAt, this.firstIn, this.late = false, this.workedMinutes = 0}): super._();
  factory _StaffNow.fromJson(Map<String, dynamic> json) => _$StaffNowFromJson(json);

@override final  String userId;
@override final  String fullName;
@override final  String? role;
@override final  String status;
// present | left | absent
@override final  String? lastDirection;
// in | out
@override final  String? lastEventAt;
@override final  String? firstIn;
@override@JsonKey() final  bool late;
@override@JsonKey() final  int workedMinutes;

/// Create a copy of StaffNow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffNowCopyWith<_StaffNow> get copyWith => __$StaffNowCopyWithImpl<_StaffNow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffNowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffNow&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastDirection, lastDirection) || other.lastDirection == lastDirection)&&(identical(other.lastEventAt, lastEventAt) || other.lastEventAt == lastEventAt)&&(identical(other.firstIn, firstIn) || other.firstIn == firstIn)&&(identical(other.late, late) || other.late == late)&&(identical(other.workedMinutes, workedMinutes) || other.workedMinutes == workedMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,role,status,lastDirection,lastEventAt,firstIn,late,workedMinutes);

@override
String toString() {
  return 'StaffNow(userId: $userId, fullName: $fullName, role: $role, status: $status, lastDirection: $lastDirection, lastEventAt: $lastEventAt, firstIn: $firstIn, late: $late, workedMinutes: $workedMinutes)';
}


}

/// @nodoc
abstract mixin class _$StaffNowCopyWith<$Res> implements $StaffNowCopyWith<$Res> {
  factory _$StaffNowCopyWith(_StaffNow value, $Res Function(_StaffNow) _then) = __$StaffNowCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fullName, String? role, String status, String? lastDirection, String? lastEventAt, String? firstIn, bool late, int workedMinutes
});




}
/// @nodoc
class __$StaffNowCopyWithImpl<$Res>
    implements _$StaffNowCopyWith<$Res> {
  __$StaffNowCopyWithImpl(this._self, this._then);

  final _StaffNow _self;
  final $Res Function(_StaffNow) _then;

/// Create a copy of StaffNow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? role = freezed,Object? status = null,Object? lastDirection = freezed,Object? lastEventAt = freezed,Object? firstIn = freezed,Object? late = null,Object? workedMinutes = null,}) {
  return _then(_StaffNow(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastDirection: freezed == lastDirection ? _self.lastDirection : lastDirection // ignore: cast_nullable_to_non_nullable
as String?,lastEventAt: freezed == lastEventAt ? _self.lastEventAt : lastEventAt // ignore: cast_nullable_to_non_nullable
as String?,firstIn: freezed == firstIn ? _self.firstIn : firstIn // ignore: cast_nullable_to_non_nullable
as String?,late: null == late ? _self.late : late // ignore: cast_nullable_to_non_nullable
as bool,workedMinutes: null == workedMinutes ? _self.workedMinutes : workedMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AttendanceStatus {

 String get asOf; String get workDayStart; bool get integrationEnabled; int get totalStaff; int get presentCount; int get leftCount; int get absentCount; int get lateCount; List<StaffNow> get staff;
/// Create a copy of AttendanceStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceStatusCopyWith<AttendanceStatus> get copyWith => _$AttendanceStatusCopyWithImpl<AttendanceStatus>(this as AttendanceStatus, _$identity);

  /// Serializes this AttendanceStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceStatus&&(identical(other.asOf, asOf) || other.asOf == asOf)&&(identical(other.workDayStart, workDayStart) || other.workDayStart == workDayStart)&&(identical(other.integrationEnabled, integrationEnabled) || other.integrationEnabled == integrationEnabled)&&(identical(other.totalStaff, totalStaff) || other.totalStaff == totalStaff)&&(identical(other.presentCount, presentCount) || other.presentCount == presentCount)&&(identical(other.leftCount, leftCount) || other.leftCount == leftCount)&&(identical(other.absentCount, absentCount) || other.absentCount == absentCount)&&(identical(other.lateCount, lateCount) || other.lateCount == lateCount)&&const DeepCollectionEquality().equals(other.staff, staff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,asOf,workDayStart,integrationEnabled,totalStaff,presentCount,leftCount,absentCount,lateCount,const DeepCollectionEquality().hash(staff));

@override
String toString() {
  return 'AttendanceStatus(asOf: $asOf, workDayStart: $workDayStart, integrationEnabled: $integrationEnabled, totalStaff: $totalStaff, presentCount: $presentCount, leftCount: $leftCount, absentCount: $absentCount, lateCount: $lateCount, staff: $staff)';
}


}

/// @nodoc
abstract mixin class $AttendanceStatusCopyWith<$Res>  {
  factory $AttendanceStatusCopyWith(AttendanceStatus value, $Res Function(AttendanceStatus) _then) = _$AttendanceStatusCopyWithImpl;
@useResult
$Res call({
 String asOf, String workDayStart, bool integrationEnabled, int totalStaff, int presentCount, int leftCount, int absentCount, int lateCount, List<StaffNow> staff
});




}
/// @nodoc
class _$AttendanceStatusCopyWithImpl<$Res>
    implements $AttendanceStatusCopyWith<$Res> {
  _$AttendanceStatusCopyWithImpl(this._self, this._then);

  final AttendanceStatus _self;
  final $Res Function(AttendanceStatus) _then;

/// Create a copy of AttendanceStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? asOf = null,Object? workDayStart = null,Object? integrationEnabled = null,Object? totalStaff = null,Object? presentCount = null,Object? leftCount = null,Object? absentCount = null,Object? lateCount = null,Object? staff = null,}) {
  return _then(_self.copyWith(
asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String,workDayStart: null == workDayStart ? _self.workDayStart : workDayStart // ignore: cast_nullable_to_non_nullable
as String,integrationEnabled: null == integrationEnabled ? _self.integrationEnabled : integrationEnabled // ignore: cast_nullable_to_non_nullable
as bool,totalStaff: null == totalStaff ? _self.totalStaff : totalStaff // ignore: cast_nullable_to_non_nullable
as int,presentCount: null == presentCount ? _self.presentCount : presentCount // ignore: cast_nullable_to_non_nullable
as int,leftCount: null == leftCount ? _self.leftCount : leftCount // ignore: cast_nullable_to_non_nullable
as int,absentCount: null == absentCount ? _self.absentCount : absentCount // ignore: cast_nullable_to_non_nullable
as int,lateCount: null == lateCount ? _self.lateCount : lateCount // ignore: cast_nullable_to_non_nullable
as int,staff: null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as List<StaffNow>,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceStatus].
extension AttendanceStatusPatterns on AttendanceStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceStatus value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceStatus value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String asOf,  String workDayStart,  bool integrationEnabled,  int totalStaff,  int presentCount,  int leftCount,  int absentCount,  int lateCount,  List<StaffNow> staff)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceStatus() when $default != null:
return $default(_that.asOf,_that.workDayStart,_that.integrationEnabled,_that.totalStaff,_that.presentCount,_that.leftCount,_that.absentCount,_that.lateCount,_that.staff);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String asOf,  String workDayStart,  bool integrationEnabled,  int totalStaff,  int presentCount,  int leftCount,  int absentCount,  int lateCount,  List<StaffNow> staff)  $default,) {final _that = this;
switch (_that) {
case _AttendanceStatus():
return $default(_that.asOf,_that.workDayStart,_that.integrationEnabled,_that.totalStaff,_that.presentCount,_that.leftCount,_that.absentCount,_that.lateCount,_that.staff);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String asOf,  String workDayStart,  bool integrationEnabled,  int totalStaff,  int presentCount,  int leftCount,  int absentCount,  int lateCount,  List<StaffNow> staff)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceStatus() when $default != null:
return $default(_that.asOf,_that.workDayStart,_that.integrationEnabled,_that.totalStaff,_that.presentCount,_that.leftCount,_that.absentCount,_that.lateCount,_that.staff);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceStatus implements AttendanceStatus {
  const _AttendanceStatus({required this.asOf, required this.workDayStart, required this.integrationEnabled, required this.totalStaff, required this.presentCount, required this.leftCount, required this.absentCount, required this.lateCount, final  List<StaffNow> staff = const <StaffNow>[]}): _staff = staff;
  factory _AttendanceStatus.fromJson(Map<String, dynamic> json) => _$AttendanceStatusFromJson(json);

@override final  String asOf;
@override final  String workDayStart;
@override final  bool integrationEnabled;
@override final  int totalStaff;
@override final  int presentCount;
@override final  int leftCount;
@override final  int absentCount;
@override final  int lateCount;
 final  List<StaffNow> _staff;
@override@JsonKey() List<StaffNow> get staff {
  if (_staff is EqualUnmodifiableListView) return _staff;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_staff);
}


/// Create a copy of AttendanceStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceStatusCopyWith<_AttendanceStatus> get copyWith => __$AttendanceStatusCopyWithImpl<_AttendanceStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceStatus&&(identical(other.asOf, asOf) || other.asOf == asOf)&&(identical(other.workDayStart, workDayStart) || other.workDayStart == workDayStart)&&(identical(other.integrationEnabled, integrationEnabled) || other.integrationEnabled == integrationEnabled)&&(identical(other.totalStaff, totalStaff) || other.totalStaff == totalStaff)&&(identical(other.presentCount, presentCount) || other.presentCount == presentCount)&&(identical(other.leftCount, leftCount) || other.leftCount == leftCount)&&(identical(other.absentCount, absentCount) || other.absentCount == absentCount)&&(identical(other.lateCount, lateCount) || other.lateCount == lateCount)&&const DeepCollectionEquality().equals(other._staff, _staff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,asOf,workDayStart,integrationEnabled,totalStaff,presentCount,leftCount,absentCount,lateCount,const DeepCollectionEquality().hash(_staff));

@override
String toString() {
  return 'AttendanceStatus(asOf: $asOf, workDayStart: $workDayStart, integrationEnabled: $integrationEnabled, totalStaff: $totalStaff, presentCount: $presentCount, leftCount: $leftCount, absentCount: $absentCount, lateCount: $lateCount, staff: $staff)';
}


}

/// @nodoc
abstract mixin class _$AttendanceStatusCopyWith<$Res> implements $AttendanceStatusCopyWith<$Res> {
  factory _$AttendanceStatusCopyWith(_AttendanceStatus value, $Res Function(_AttendanceStatus) _then) = __$AttendanceStatusCopyWithImpl;
@override @useResult
$Res call({
 String asOf, String workDayStart, bool integrationEnabled, int totalStaff, int presentCount, int leftCount, int absentCount, int lateCount, List<StaffNow> staff
});




}
/// @nodoc
class __$AttendanceStatusCopyWithImpl<$Res>
    implements _$AttendanceStatusCopyWith<$Res> {
  __$AttendanceStatusCopyWithImpl(this._self, this._then);

  final _AttendanceStatus _self;
  final $Res Function(_AttendanceStatus) _then;

/// Create a copy of AttendanceStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? asOf = null,Object? workDayStart = null,Object? integrationEnabled = null,Object? totalStaff = null,Object? presentCount = null,Object? leftCount = null,Object? absentCount = null,Object? lateCount = null,Object? staff = null,}) {
  return _then(_AttendanceStatus(
asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String,workDayStart: null == workDayStart ? _self.workDayStart : workDayStart // ignore: cast_nullable_to_non_nullable
as String,integrationEnabled: null == integrationEnabled ? _self.integrationEnabled : integrationEnabled // ignore: cast_nullable_to_non_nullable
as bool,totalStaff: null == totalStaff ? _self.totalStaff : totalStaff // ignore: cast_nullable_to_non_nullable
as int,presentCount: null == presentCount ? _self.presentCount : presentCount // ignore: cast_nullable_to_non_nullable
as int,leftCount: null == leftCount ? _self.leftCount : leftCount // ignore: cast_nullable_to_non_nullable
as int,absentCount: null == absentCount ? _self.absentCount : absentCount // ignore: cast_nullable_to_non_nullable
as int,lateCount: null == lateCount ? _self.lateCount : lateCount // ignore: cast_nullable_to_non_nullable
as int,staff: null == staff ? _self._staff : staff // ignore: cast_nullable_to_non_nullable
as List<StaffNow>,
  ));
}


}

// dart format on
