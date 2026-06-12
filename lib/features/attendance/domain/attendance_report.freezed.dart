// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttendanceDay {

 String get day;// YYYY-MM-DD
 String? get firstIn; String? get lastOut; int get workedMinutes; bool get late;
/// Create a copy of AttendanceDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceDayCopyWith<AttendanceDay> get copyWith => _$AttendanceDayCopyWithImpl<AttendanceDay>(this as AttendanceDay, _$identity);

  /// Serializes this AttendanceDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceDay&&(identical(other.day, day) || other.day == day)&&(identical(other.firstIn, firstIn) || other.firstIn == firstIn)&&(identical(other.lastOut, lastOut) || other.lastOut == lastOut)&&(identical(other.workedMinutes, workedMinutes) || other.workedMinutes == workedMinutes)&&(identical(other.late, late) || other.late == late));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,firstIn,lastOut,workedMinutes,late);

@override
String toString() {
  return 'AttendanceDay(day: $day, firstIn: $firstIn, lastOut: $lastOut, workedMinutes: $workedMinutes, late: $late)';
}


}

/// @nodoc
abstract mixin class $AttendanceDayCopyWith<$Res>  {
  factory $AttendanceDayCopyWith(AttendanceDay value, $Res Function(AttendanceDay) _then) = _$AttendanceDayCopyWithImpl;
@useResult
$Res call({
 String day, String? firstIn, String? lastOut, int workedMinutes, bool late
});




}
/// @nodoc
class _$AttendanceDayCopyWithImpl<$Res>
    implements $AttendanceDayCopyWith<$Res> {
  _$AttendanceDayCopyWithImpl(this._self, this._then);

  final AttendanceDay _self;
  final $Res Function(AttendanceDay) _then;

/// Create a copy of AttendanceDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? firstIn = freezed,Object? lastOut = freezed,Object? workedMinutes = null,Object? late = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,firstIn: freezed == firstIn ? _self.firstIn : firstIn // ignore: cast_nullable_to_non_nullable
as String?,lastOut: freezed == lastOut ? _self.lastOut : lastOut // ignore: cast_nullable_to_non_nullable
as String?,workedMinutes: null == workedMinutes ? _self.workedMinutes : workedMinutes // ignore: cast_nullable_to_non_nullable
as int,late: null == late ? _self.late : late // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceDay].
extension AttendanceDayPatterns on AttendanceDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceDay value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceDay value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String day,  String? firstIn,  String? lastOut,  int workedMinutes,  bool late)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceDay() when $default != null:
return $default(_that.day,_that.firstIn,_that.lastOut,_that.workedMinutes,_that.late);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String day,  String? firstIn,  String? lastOut,  int workedMinutes,  bool late)  $default,) {final _that = this;
switch (_that) {
case _AttendanceDay():
return $default(_that.day,_that.firstIn,_that.lastOut,_that.workedMinutes,_that.late);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String day,  String? firstIn,  String? lastOut,  int workedMinutes,  bool late)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceDay() when $default != null:
return $default(_that.day,_that.firstIn,_that.lastOut,_that.workedMinutes,_that.late);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceDay implements AttendanceDay {
  const _AttendanceDay({required this.day, this.firstIn, this.lastOut, required this.workedMinutes, required this.late});
  factory _AttendanceDay.fromJson(Map<String, dynamic> json) => _$AttendanceDayFromJson(json);

@override final  String day;
// YYYY-MM-DD
@override final  String? firstIn;
@override final  String? lastOut;
@override final  int workedMinutes;
@override final  bool late;

/// Create a copy of AttendanceDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceDayCopyWith<_AttendanceDay> get copyWith => __$AttendanceDayCopyWithImpl<_AttendanceDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceDay&&(identical(other.day, day) || other.day == day)&&(identical(other.firstIn, firstIn) || other.firstIn == firstIn)&&(identical(other.lastOut, lastOut) || other.lastOut == lastOut)&&(identical(other.workedMinutes, workedMinutes) || other.workedMinutes == workedMinutes)&&(identical(other.late, late) || other.late == late));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,firstIn,lastOut,workedMinutes,late);

@override
String toString() {
  return 'AttendanceDay(day: $day, firstIn: $firstIn, lastOut: $lastOut, workedMinutes: $workedMinutes, late: $late)';
}


}

/// @nodoc
abstract mixin class _$AttendanceDayCopyWith<$Res> implements $AttendanceDayCopyWith<$Res> {
  factory _$AttendanceDayCopyWith(_AttendanceDay value, $Res Function(_AttendanceDay) _then) = __$AttendanceDayCopyWithImpl;
@override @useResult
$Res call({
 String day, String? firstIn, String? lastOut, int workedMinutes, bool late
});




}
/// @nodoc
class __$AttendanceDayCopyWithImpl<$Res>
    implements _$AttendanceDayCopyWith<$Res> {
  __$AttendanceDayCopyWithImpl(this._self, this._then);

  final _AttendanceDay _self;
  final $Res Function(_AttendanceDay) _then;

/// Create a copy of AttendanceDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? firstIn = freezed,Object? lastOut = freezed,Object? workedMinutes = null,Object? late = null,}) {
  return _then(_AttendanceDay(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,firstIn: freezed == firstIn ? _self.firstIn : firstIn // ignore: cast_nullable_to_non_nullable
as String?,lastOut: freezed == lastOut ? _self.lastOut : lastOut // ignore: cast_nullable_to_non_nullable
as String?,workedMinutes: null == workedMinutes ? _self.workedMinutes : workedMinutes // ignore: cast_nullable_to_non_nullable
as int,late: null == late ? _self.late : late // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$AttendanceUserReport {

 String get userId; String get fullName; List<AttendanceDay> get days; int get daysPresent; int get daysAbsent; int get totalMinutes; int get lateCount;
/// Create a copy of AttendanceUserReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceUserReportCopyWith<AttendanceUserReport> get copyWith => _$AttendanceUserReportCopyWithImpl<AttendanceUserReport>(this as AttendanceUserReport, _$identity);

  /// Serializes this AttendanceUserReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceUserReport&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&const DeepCollectionEquality().equals(other.days, days)&&(identical(other.daysPresent, daysPresent) || other.daysPresent == daysPresent)&&(identical(other.daysAbsent, daysAbsent) || other.daysAbsent == daysAbsent)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&(identical(other.lateCount, lateCount) || other.lateCount == lateCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,const DeepCollectionEquality().hash(days),daysPresent,daysAbsent,totalMinutes,lateCount);

@override
String toString() {
  return 'AttendanceUserReport(userId: $userId, fullName: $fullName, days: $days, daysPresent: $daysPresent, daysAbsent: $daysAbsent, totalMinutes: $totalMinutes, lateCount: $lateCount)';
}


}

/// @nodoc
abstract mixin class $AttendanceUserReportCopyWith<$Res>  {
  factory $AttendanceUserReportCopyWith(AttendanceUserReport value, $Res Function(AttendanceUserReport) _then) = _$AttendanceUserReportCopyWithImpl;
@useResult
$Res call({
 String userId, String fullName, List<AttendanceDay> days, int daysPresent, int daysAbsent, int totalMinutes, int lateCount
});




}
/// @nodoc
class _$AttendanceUserReportCopyWithImpl<$Res>
    implements $AttendanceUserReportCopyWith<$Res> {
  _$AttendanceUserReportCopyWithImpl(this._self, this._then);

  final AttendanceUserReport _self;
  final $Res Function(AttendanceUserReport) _then;

/// Create a copy of AttendanceUserReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? days = null,Object? daysPresent = null,Object? daysAbsent = null,Object? totalMinutes = null,Object? lateCount = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<AttendanceDay>,daysPresent: null == daysPresent ? _self.daysPresent : daysPresent // ignore: cast_nullable_to_non_nullable
as int,daysAbsent: null == daysAbsent ? _self.daysAbsent : daysAbsent // ignore: cast_nullable_to_non_nullable
as int,totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,lateCount: null == lateCount ? _self.lateCount : lateCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceUserReport].
extension AttendanceUserReportPatterns on AttendanceUserReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceUserReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceUserReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceUserReport value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceUserReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceUserReport value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceUserReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fullName,  List<AttendanceDay> days,  int daysPresent,  int daysAbsent,  int totalMinutes,  int lateCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceUserReport() when $default != null:
return $default(_that.userId,_that.fullName,_that.days,_that.daysPresent,_that.daysAbsent,_that.totalMinutes,_that.lateCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fullName,  List<AttendanceDay> days,  int daysPresent,  int daysAbsent,  int totalMinutes,  int lateCount)  $default,) {final _that = this;
switch (_that) {
case _AttendanceUserReport():
return $default(_that.userId,_that.fullName,_that.days,_that.daysPresent,_that.daysAbsent,_that.totalMinutes,_that.lateCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fullName,  List<AttendanceDay> days,  int daysPresent,  int daysAbsent,  int totalMinutes,  int lateCount)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceUserReport() when $default != null:
return $default(_that.userId,_that.fullName,_that.days,_that.daysPresent,_that.daysAbsent,_that.totalMinutes,_that.lateCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceUserReport implements AttendanceUserReport {
  const _AttendanceUserReport({required this.userId, required this.fullName, final  List<AttendanceDay> days = const <AttendanceDay>[], required this.daysPresent, required this.daysAbsent, required this.totalMinutes, required this.lateCount}): _days = days;
  factory _AttendanceUserReport.fromJson(Map<String, dynamic> json) => _$AttendanceUserReportFromJson(json);

@override final  String userId;
@override final  String fullName;
 final  List<AttendanceDay> _days;
@override@JsonKey() List<AttendanceDay> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

@override final  int daysPresent;
@override final  int daysAbsent;
@override final  int totalMinutes;
@override final  int lateCount;

/// Create a copy of AttendanceUserReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceUserReportCopyWith<_AttendanceUserReport> get copyWith => __$AttendanceUserReportCopyWithImpl<_AttendanceUserReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceUserReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceUserReport&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&const DeepCollectionEquality().equals(other._days, _days)&&(identical(other.daysPresent, daysPresent) || other.daysPresent == daysPresent)&&(identical(other.daysAbsent, daysAbsent) || other.daysAbsent == daysAbsent)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&(identical(other.lateCount, lateCount) || other.lateCount == lateCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,const DeepCollectionEquality().hash(_days),daysPresent,daysAbsent,totalMinutes,lateCount);

@override
String toString() {
  return 'AttendanceUserReport(userId: $userId, fullName: $fullName, days: $days, daysPresent: $daysPresent, daysAbsent: $daysAbsent, totalMinutes: $totalMinutes, lateCount: $lateCount)';
}


}

/// @nodoc
abstract mixin class _$AttendanceUserReportCopyWith<$Res> implements $AttendanceUserReportCopyWith<$Res> {
  factory _$AttendanceUserReportCopyWith(_AttendanceUserReport value, $Res Function(_AttendanceUserReport) _then) = __$AttendanceUserReportCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fullName, List<AttendanceDay> days, int daysPresent, int daysAbsent, int totalMinutes, int lateCount
});




}
/// @nodoc
class __$AttendanceUserReportCopyWithImpl<$Res>
    implements _$AttendanceUserReportCopyWith<$Res> {
  __$AttendanceUserReportCopyWithImpl(this._self, this._then);

  final _AttendanceUserReport _self;
  final $Res Function(_AttendanceUserReport) _then;

/// Create a copy of AttendanceUserReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? days = null,Object? daysPresent = null,Object? daysAbsent = null,Object? totalMinutes = null,Object? lateCount = null,}) {
  return _then(_AttendanceUserReport(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<AttendanceDay>,daysPresent: null == daysPresent ? _self.daysPresent : daysPresent // ignore: cast_nullable_to_non_nullable
as int,daysAbsent: null == daysAbsent ? _self.daysAbsent : daysAbsent // ignore: cast_nullable_to_non_nullable
as int,totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,lateCount: null == lateCount ? _self.lateCount : lateCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AttendanceReport {

 String get dateFrom; String get dateTo; String get workDayStart;// "HH:MM" lateness threshold
 List<AttendanceUserReport> get users;
/// Create a copy of AttendanceReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceReportCopyWith<AttendanceReport> get copyWith => _$AttendanceReportCopyWithImpl<AttendanceReport>(this as AttendanceReport, _$identity);

  /// Serializes this AttendanceReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceReport&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.workDayStart, workDayStart) || other.workDayStart == workDayStart)&&const DeepCollectionEquality().equals(other.users, users));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dateFrom,dateTo,workDayStart,const DeepCollectionEquality().hash(users));

@override
String toString() {
  return 'AttendanceReport(dateFrom: $dateFrom, dateTo: $dateTo, workDayStart: $workDayStart, users: $users)';
}


}

/// @nodoc
abstract mixin class $AttendanceReportCopyWith<$Res>  {
  factory $AttendanceReportCopyWith(AttendanceReport value, $Res Function(AttendanceReport) _then) = _$AttendanceReportCopyWithImpl;
@useResult
$Res call({
 String dateFrom, String dateTo, String workDayStart, List<AttendanceUserReport> users
});




}
/// @nodoc
class _$AttendanceReportCopyWithImpl<$Res>
    implements $AttendanceReportCopyWith<$Res> {
  _$AttendanceReportCopyWithImpl(this._self, this._then);

  final AttendanceReport _self;
  final $Res Function(AttendanceReport) _then;

/// Create a copy of AttendanceReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dateFrom = null,Object? dateTo = null,Object? workDayStart = null,Object? users = null,}) {
  return _then(_self.copyWith(
dateFrom: null == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as String,dateTo: null == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as String,workDayStart: null == workDayStart ? _self.workDayStart : workDayStart // ignore: cast_nullable_to_non_nullable
as String,users: null == users ? _self.users : users // ignore: cast_nullable_to_non_nullable
as List<AttendanceUserReport>,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceReport].
extension AttendanceReportPatterns on AttendanceReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceReport value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceReport value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String dateFrom,  String dateTo,  String workDayStart,  List<AttendanceUserReport> users)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceReport() when $default != null:
return $default(_that.dateFrom,_that.dateTo,_that.workDayStart,_that.users);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String dateFrom,  String dateTo,  String workDayStart,  List<AttendanceUserReport> users)  $default,) {final _that = this;
switch (_that) {
case _AttendanceReport():
return $default(_that.dateFrom,_that.dateTo,_that.workDayStart,_that.users);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String dateFrom,  String dateTo,  String workDayStart,  List<AttendanceUserReport> users)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceReport() when $default != null:
return $default(_that.dateFrom,_that.dateTo,_that.workDayStart,_that.users);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceReport implements AttendanceReport {
  const _AttendanceReport({required this.dateFrom, required this.dateTo, required this.workDayStart, final  List<AttendanceUserReport> users = const <AttendanceUserReport>[]}): _users = users;
  factory _AttendanceReport.fromJson(Map<String, dynamic> json) => _$AttendanceReportFromJson(json);

@override final  String dateFrom;
@override final  String dateTo;
@override final  String workDayStart;
// "HH:MM" lateness threshold
 final  List<AttendanceUserReport> _users;
// "HH:MM" lateness threshold
@override@JsonKey() List<AttendanceUserReport> get users {
  if (_users is EqualUnmodifiableListView) return _users;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_users);
}


/// Create a copy of AttendanceReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceReportCopyWith<_AttendanceReport> get copyWith => __$AttendanceReportCopyWithImpl<_AttendanceReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceReport&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.workDayStart, workDayStart) || other.workDayStart == workDayStart)&&const DeepCollectionEquality().equals(other._users, _users));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dateFrom,dateTo,workDayStart,const DeepCollectionEquality().hash(_users));

@override
String toString() {
  return 'AttendanceReport(dateFrom: $dateFrom, dateTo: $dateTo, workDayStart: $workDayStart, users: $users)';
}


}

/// @nodoc
abstract mixin class _$AttendanceReportCopyWith<$Res> implements $AttendanceReportCopyWith<$Res> {
  factory _$AttendanceReportCopyWith(_AttendanceReport value, $Res Function(_AttendanceReport) _then) = __$AttendanceReportCopyWithImpl;
@override @useResult
$Res call({
 String dateFrom, String dateTo, String workDayStart, List<AttendanceUserReport> users
});




}
/// @nodoc
class __$AttendanceReportCopyWithImpl<$Res>
    implements _$AttendanceReportCopyWith<$Res> {
  __$AttendanceReportCopyWithImpl(this._self, this._then);

  final _AttendanceReport _self;
  final $Res Function(_AttendanceReport) _then;

/// Create a copy of AttendanceReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dateFrom = null,Object? dateTo = null,Object? workDayStart = null,Object? users = null,}) {
  return _then(_AttendanceReport(
dateFrom: null == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as String,dateTo: null == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as String,workDayStart: null == workDayStart ? _self.workDayStart : workDayStart // ignore: cast_nullable_to_non_nullable
as String,users: null == users ? _self._users : users // ignore: cast_nullable_to_non_nullable
as List<AttendanceUserReport>,
  ));
}


}

// dart format on
