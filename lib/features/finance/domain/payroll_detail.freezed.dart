// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayrollDetail {

 String get userId; String get fullName; String get month; String? get consultSalaryType; String? get consultSalaryValue; String? get operationSalaryType; String? get operationSalaryValue; List<PayrollDetailDay> get days; List<PayrollDetailOperation> get operations; String get consultRevenue; String get consultPay; String get operationRevenue; int get operationCount; String get operationPay; String get salary;
/// Create a copy of PayrollDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollDetailCopyWith<PayrollDetail> get copyWith => _$PayrollDetailCopyWithImpl<PayrollDetail>(this as PayrollDetail, _$identity);

  /// Serializes this PayrollDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollDetail&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.month, month) || other.month == month)&&(identical(other.consultSalaryType, consultSalaryType) || other.consultSalaryType == consultSalaryType)&&(identical(other.consultSalaryValue, consultSalaryValue) || other.consultSalaryValue == consultSalaryValue)&&(identical(other.operationSalaryType, operationSalaryType) || other.operationSalaryType == operationSalaryType)&&(identical(other.operationSalaryValue, operationSalaryValue) || other.operationSalaryValue == operationSalaryValue)&&const DeepCollectionEquality().equals(other.days, days)&&const DeepCollectionEquality().equals(other.operations, operations)&&(identical(other.consultRevenue, consultRevenue) || other.consultRevenue == consultRevenue)&&(identical(other.consultPay, consultPay) || other.consultPay == consultPay)&&(identical(other.operationRevenue, operationRevenue) || other.operationRevenue == operationRevenue)&&(identical(other.operationCount, operationCount) || other.operationCount == operationCount)&&(identical(other.operationPay, operationPay) || other.operationPay == operationPay)&&(identical(other.salary, salary) || other.salary == salary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,month,consultSalaryType,consultSalaryValue,operationSalaryType,operationSalaryValue,const DeepCollectionEquality().hash(days),const DeepCollectionEquality().hash(operations),consultRevenue,consultPay,operationRevenue,operationCount,operationPay,salary);

@override
String toString() {
  return 'PayrollDetail(userId: $userId, fullName: $fullName, month: $month, consultSalaryType: $consultSalaryType, consultSalaryValue: $consultSalaryValue, operationSalaryType: $operationSalaryType, operationSalaryValue: $operationSalaryValue, days: $days, operations: $operations, consultRevenue: $consultRevenue, consultPay: $consultPay, operationRevenue: $operationRevenue, operationCount: $operationCount, operationPay: $operationPay, salary: $salary)';
}


}

/// @nodoc
abstract mixin class $PayrollDetailCopyWith<$Res>  {
  factory $PayrollDetailCopyWith(PayrollDetail value, $Res Function(PayrollDetail) _then) = _$PayrollDetailCopyWithImpl;
@useResult
$Res call({
 String userId, String fullName, String month, String? consultSalaryType, String? consultSalaryValue, String? operationSalaryType, String? operationSalaryValue, List<PayrollDetailDay> days, List<PayrollDetailOperation> operations, String consultRevenue, String consultPay, String operationRevenue, int operationCount, String operationPay, String salary
});




}
/// @nodoc
class _$PayrollDetailCopyWithImpl<$Res>
    implements $PayrollDetailCopyWith<$Res> {
  _$PayrollDetailCopyWithImpl(this._self, this._then);

  final PayrollDetail _self;
  final $Res Function(PayrollDetail) _then;

/// Create a copy of PayrollDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? month = null,Object? consultSalaryType = freezed,Object? consultSalaryValue = freezed,Object? operationSalaryType = freezed,Object? operationSalaryValue = freezed,Object? days = null,Object? operations = null,Object? consultRevenue = null,Object? consultPay = null,Object? operationRevenue = null,Object? operationCount = null,Object? operationPay = null,Object? salary = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,consultSalaryType: freezed == consultSalaryType ? _self.consultSalaryType : consultSalaryType // ignore: cast_nullable_to_non_nullable
as String?,consultSalaryValue: freezed == consultSalaryValue ? _self.consultSalaryValue : consultSalaryValue // ignore: cast_nullable_to_non_nullable
as String?,operationSalaryType: freezed == operationSalaryType ? _self.operationSalaryType : operationSalaryType // ignore: cast_nullable_to_non_nullable
as String?,operationSalaryValue: freezed == operationSalaryValue ? _self.operationSalaryValue : operationSalaryValue // ignore: cast_nullable_to_non_nullable
as String?,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<PayrollDetailDay>,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as List<PayrollDetailOperation>,consultRevenue: null == consultRevenue ? _self.consultRevenue : consultRevenue // ignore: cast_nullable_to_non_nullable
as String,consultPay: null == consultPay ? _self.consultPay : consultPay // ignore: cast_nullable_to_non_nullable
as String,operationRevenue: null == operationRevenue ? _self.operationRevenue : operationRevenue // ignore: cast_nullable_to_non_nullable
as String,operationCount: null == operationCount ? _self.operationCount : operationCount // ignore: cast_nullable_to_non_nullable
as int,operationPay: null == operationPay ? _self.operationPay : operationPay // ignore: cast_nullable_to_non_nullable
as String,salary: null == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PayrollDetail].
extension PayrollDetailPatterns on PayrollDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayrollDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayrollDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayrollDetail value)  $default,){
final _that = this;
switch (_that) {
case _PayrollDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayrollDetail value)?  $default,){
final _that = this;
switch (_that) {
case _PayrollDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fullName,  String month,  String? consultSalaryType,  String? consultSalaryValue,  String? operationSalaryType,  String? operationSalaryValue,  List<PayrollDetailDay> days,  List<PayrollDetailOperation> operations,  String consultRevenue,  String consultPay,  String operationRevenue,  int operationCount,  String operationPay,  String salary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollDetail() when $default != null:
return $default(_that.userId,_that.fullName,_that.month,_that.consultSalaryType,_that.consultSalaryValue,_that.operationSalaryType,_that.operationSalaryValue,_that.days,_that.operations,_that.consultRevenue,_that.consultPay,_that.operationRevenue,_that.operationCount,_that.operationPay,_that.salary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fullName,  String month,  String? consultSalaryType,  String? consultSalaryValue,  String? operationSalaryType,  String? operationSalaryValue,  List<PayrollDetailDay> days,  List<PayrollDetailOperation> operations,  String consultRevenue,  String consultPay,  String operationRevenue,  int operationCount,  String operationPay,  String salary)  $default,) {final _that = this;
switch (_that) {
case _PayrollDetail():
return $default(_that.userId,_that.fullName,_that.month,_that.consultSalaryType,_that.consultSalaryValue,_that.operationSalaryType,_that.operationSalaryValue,_that.days,_that.operations,_that.consultRevenue,_that.consultPay,_that.operationRevenue,_that.operationCount,_that.operationPay,_that.salary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fullName,  String month,  String? consultSalaryType,  String? consultSalaryValue,  String? operationSalaryType,  String? operationSalaryValue,  List<PayrollDetailDay> days,  List<PayrollDetailOperation> operations,  String consultRevenue,  String consultPay,  String operationRevenue,  int operationCount,  String operationPay,  String salary)?  $default,) {final _that = this;
switch (_that) {
case _PayrollDetail() when $default != null:
return $default(_that.userId,_that.fullName,_that.month,_that.consultSalaryType,_that.consultSalaryValue,_that.operationSalaryType,_that.operationSalaryValue,_that.days,_that.operations,_that.consultRevenue,_that.consultPay,_that.operationRevenue,_that.operationCount,_that.operationPay,_that.salary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayrollDetail implements PayrollDetail {
  const _PayrollDetail({required this.userId, required this.fullName, required this.month, this.consultSalaryType, this.consultSalaryValue, this.operationSalaryType, this.operationSalaryValue, final  List<PayrollDetailDay> days = const <PayrollDetailDay>[], final  List<PayrollDetailOperation> operations = const <PayrollDetailOperation>[], required this.consultRevenue, required this.consultPay, required this.operationRevenue, required this.operationCount, required this.operationPay, required this.salary}): _days = days,_operations = operations;
  factory _PayrollDetail.fromJson(Map<String, dynamic> json) => _$PayrollDetailFromJson(json);

@override final  String userId;
@override final  String fullName;
@override final  String month;
@override final  String? consultSalaryType;
@override final  String? consultSalaryValue;
@override final  String? operationSalaryType;
@override final  String? operationSalaryValue;
 final  List<PayrollDetailDay> _days;
@override@JsonKey() List<PayrollDetailDay> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

 final  List<PayrollDetailOperation> _operations;
@override@JsonKey() List<PayrollDetailOperation> get operations {
  if (_operations is EqualUnmodifiableListView) return _operations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_operations);
}

@override final  String consultRevenue;
@override final  String consultPay;
@override final  String operationRevenue;
@override final  int operationCount;
@override final  String operationPay;
@override final  String salary;

/// Create a copy of PayrollDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollDetailCopyWith<_PayrollDetail> get copyWith => __$PayrollDetailCopyWithImpl<_PayrollDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayrollDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollDetail&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.month, month) || other.month == month)&&(identical(other.consultSalaryType, consultSalaryType) || other.consultSalaryType == consultSalaryType)&&(identical(other.consultSalaryValue, consultSalaryValue) || other.consultSalaryValue == consultSalaryValue)&&(identical(other.operationSalaryType, operationSalaryType) || other.operationSalaryType == operationSalaryType)&&(identical(other.operationSalaryValue, operationSalaryValue) || other.operationSalaryValue == operationSalaryValue)&&const DeepCollectionEquality().equals(other._days, _days)&&const DeepCollectionEquality().equals(other._operations, _operations)&&(identical(other.consultRevenue, consultRevenue) || other.consultRevenue == consultRevenue)&&(identical(other.consultPay, consultPay) || other.consultPay == consultPay)&&(identical(other.operationRevenue, operationRevenue) || other.operationRevenue == operationRevenue)&&(identical(other.operationCount, operationCount) || other.operationCount == operationCount)&&(identical(other.operationPay, operationPay) || other.operationPay == operationPay)&&(identical(other.salary, salary) || other.salary == salary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,month,consultSalaryType,consultSalaryValue,operationSalaryType,operationSalaryValue,const DeepCollectionEquality().hash(_days),const DeepCollectionEquality().hash(_operations),consultRevenue,consultPay,operationRevenue,operationCount,operationPay,salary);

@override
String toString() {
  return 'PayrollDetail(userId: $userId, fullName: $fullName, month: $month, consultSalaryType: $consultSalaryType, consultSalaryValue: $consultSalaryValue, operationSalaryType: $operationSalaryType, operationSalaryValue: $operationSalaryValue, days: $days, operations: $operations, consultRevenue: $consultRevenue, consultPay: $consultPay, operationRevenue: $operationRevenue, operationCount: $operationCount, operationPay: $operationPay, salary: $salary)';
}


}

/// @nodoc
abstract mixin class _$PayrollDetailCopyWith<$Res> implements $PayrollDetailCopyWith<$Res> {
  factory _$PayrollDetailCopyWith(_PayrollDetail value, $Res Function(_PayrollDetail) _then) = __$PayrollDetailCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fullName, String month, String? consultSalaryType, String? consultSalaryValue, String? operationSalaryType, String? operationSalaryValue, List<PayrollDetailDay> days, List<PayrollDetailOperation> operations, String consultRevenue, String consultPay, String operationRevenue, int operationCount, String operationPay, String salary
});




}
/// @nodoc
class __$PayrollDetailCopyWithImpl<$Res>
    implements _$PayrollDetailCopyWith<$Res> {
  __$PayrollDetailCopyWithImpl(this._self, this._then);

  final _PayrollDetail _self;
  final $Res Function(_PayrollDetail) _then;

/// Create a copy of PayrollDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? month = null,Object? consultSalaryType = freezed,Object? consultSalaryValue = freezed,Object? operationSalaryType = freezed,Object? operationSalaryValue = freezed,Object? days = null,Object? operations = null,Object? consultRevenue = null,Object? consultPay = null,Object? operationRevenue = null,Object? operationCount = null,Object? operationPay = null,Object? salary = null,}) {
  return _then(_PayrollDetail(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,consultSalaryType: freezed == consultSalaryType ? _self.consultSalaryType : consultSalaryType // ignore: cast_nullable_to_non_nullable
as String?,consultSalaryValue: freezed == consultSalaryValue ? _self.consultSalaryValue : consultSalaryValue // ignore: cast_nullable_to_non_nullable
as String?,operationSalaryType: freezed == operationSalaryType ? _self.operationSalaryType : operationSalaryType // ignore: cast_nullable_to_non_nullable
as String?,operationSalaryValue: freezed == operationSalaryValue ? _self.operationSalaryValue : operationSalaryValue // ignore: cast_nullable_to_non_nullable
as String?,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<PayrollDetailDay>,operations: null == operations ? _self._operations : operations // ignore: cast_nullable_to_non_nullable
as List<PayrollDetailOperation>,consultRevenue: null == consultRevenue ? _self.consultRevenue : consultRevenue // ignore: cast_nullable_to_non_nullable
as String,consultPay: null == consultPay ? _self.consultPay : consultPay // ignore: cast_nullable_to_non_nullable
as String,operationRevenue: null == operationRevenue ? _self.operationRevenue : operationRevenue // ignore: cast_nullable_to_non_nullable
as String,operationCount: null == operationCount ? _self.operationCount : operationCount // ignore: cast_nullable_to_non_nullable
as int,operationPay: null == operationPay ? _self.operationPay : operationPay // ignore: cast_nullable_to_non_nullable
as String,salary: null == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PayrollDetailDay {

 String get date;// YYYY-MM-DD
 List<PayrollDetailPatient> get patients; String get revenue; String get share;
/// Create a copy of PayrollDetailDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollDetailDayCopyWith<PayrollDetailDay> get copyWith => _$PayrollDetailDayCopyWithImpl<PayrollDetailDay>(this as PayrollDetailDay, _$identity);

  /// Serializes this PayrollDetailDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollDetailDay&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.patients, patients)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.share, share) || other.share == share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(patients),revenue,share);

@override
String toString() {
  return 'PayrollDetailDay(date: $date, patients: $patients, revenue: $revenue, share: $share)';
}


}

/// @nodoc
abstract mixin class $PayrollDetailDayCopyWith<$Res>  {
  factory $PayrollDetailDayCopyWith(PayrollDetailDay value, $Res Function(PayrollDetailDay) _then) = _$PayrollDetailDayCopyWithImpl;
@useResult
$Res call({
 String date, List<PayrollDetailPatient> patients, String revenue, String share
});




}
/// @nodoc
class _$PayrollDetailDayCopyWithImpl<$Res>
    implements $PayrollDetailDayCopyWith<$Res> {
  _$PayrollDetailDayCopyWithImpl(this._self, this._then);

  final PayrollDetailDay _self;
  final $Res Function(PayrollDetailDay) _then;

/// Create a copy of PayrollDetailDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? patients = null,Object? revenue = null,Object? share = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,patients: null == patients ? _self.patients : patients // ignore: cast_nullable_to_non_nullable
as List<PayrollDetailPatient>,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PayrollDetailDay].
extension PayrollDetailDayPatterns on PayrollDetailDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayrollDetailDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayrollDetailDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayrollDetailDay value)  $default,){
final _that = this;
switch (_that) {
case _PayrollDetailDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayrollDetailDay value)?  $default,){
final _that = this;
switch (_that) {
case _PayrollDetailDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  List<PayrollDetailPatient> patients,  String revenue,  String share)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollDetailDay() when $default != null:
return $default(_that.date,_that.patients,_that.revenue,_that.share);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  List<PayrollDetailPatient> patients,  String revenue,  String share)  $default,) {final _that = this;
switch (_that) {
case _PayrollDetailDay():
return $default(_that.date,_that.patients,_that.revenue,_that.share);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  List<PayrollDetailPatient> patients,  String revenue,  String share)?  $default,) {final _that = this;
switch (_that) {
case _PayrollDetailDay() when $default != null:
return $default(_that.date,_that.patients,_that.revenue,_that.share);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayrollDetailDay implements PayrollDetailDay {
  const _PayrollDetailDay({required this.date, final  List<PayrollDetailPatient> patients = const <PayrollDetailPatient>[], required this.revenue, required this.share}): _patients = patients;
  factory _PayrollDetailDay.fromJson(Map<String, dynamic> json) => _$PayrollDetailDayFromJson(json);

@override final  String date;
// YYYY-MM-DD
 final  List<PayrollDetailPatient> _patients;
// YYYY-MM-DD
@override@JsonKey() List<PayrollDetailPatient> get patients {
  if (_patients is EqualUnmodifiableListView) return _patients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_patients);
}

@override final  String revenue;
@override final  String share;

/// Create a copy of PayrollDetailDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollDetailDayCopyWith<_PayrollDetailDay> get copyWith => __$PayrollDetailDayCopyWithImpl<_PayrollDetailDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayrollDetailDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollDetailDay&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._patients, _patients)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.share, share) || other.share == share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_patients),revenue,share);

@override
String toString() {
  return 'PayrollDetailDay(date: $date, patients: $patients, revenue: $revenue, share: $share)';
}


}

/// @nodoc
abstract mixin class _$PayrollDetailDayCopyWith<$Res> implements $PayrollDetailDayCopyWith<$Res> {
  factory _$PayrollDetailDayCopyWith(_PayrollDetailDay value, $Res Function(_PayrollDetailDay) _then) = __$PayrollDetailDayCopyWithImpl;
@override @useResult
$Res call({
 String date, List<PayrollDetailPatient> patients, String revenue, String share
});




}
/// @nodoc
class __$PayrollDetailDayCopyWithImpl<$Res>
    implements _$PayrollDetailDayCopyWith<$Res> {
  __$PayrollDetailDayCopyWithImpl(this._self, this._then);

  final _PayrollDetailDay _self;
  final $Res Function(_PayrollDetailDay) _then;

/// Create a copy of PayrollDetailDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? patients = null,Object? revenue = null,Object? share = null,}) {
  return _then(_PayrollDetailDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,patients: null == patients ? _self._patients : patients // ignore: cast_nullable_to_non_nullable
as List<PayrollDetailPatient>,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PayrollDetailPatient {

 String get visitId; String get patientName; String get amount; String get share;
/// Create a copy of PayrollDetailPatient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollDetailPatientCopyWith<PayrollDetailPatient> get copyWith => _$PayrollDetailPatientCopyWithImpl<PayrollDetailPatient>(this as PayrollDetailPatient, _$identity);

  /// Serializes this PayrollDetailPatient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollDetailPatient&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.share, share) || other.share == share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,visitId,patientName,amount,share);

@override
String toString() {
  return 'PayrollDetailPatient(visitId: $visitId, patientName: $patientName, amount: $amount, share: $share)';
}


}

/// @nodoc
abstract mixin class $PayrollDetailPatientCopyWith<$Res>  {
  factory $PayrollDetailPatientCopyWith(PayrollDetailPatient value, $Res Function(PayrollDetailPatient) _then) = _$PayrollDetailPatientCopyWithImpl;
@useResult
$Res call({
 String visitId, String patientName, String amount, String share
});




}
/// @nodoc
class _$PayrollDetailPatientCopyWithImpl<$Res>
    implements $PayrollDetailPatientCopyWith<$Res> {
  _$PayrollDetailPatientCopyWithImpl(this._self, this._then);

  final PayrollDetailPatient _self;
  final $Res Function(PayrollDetailPatient) _then;

/// Create a copy of PayrollDetailPatient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? visitId = null,Object? patientName = null,Object? amount = null,Object? share = null,}) {
  return _then(_self.copyWith(
visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PayrollDetailPatient].
extension PayrollDetailPatientPatterns on PayrollDetailPatient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayrollDetailPatient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayrollDetailPatient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayrollDetailPatient value)  $default,){
final _that = this;
switch (_that) {
case _PayrollDetailPatient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayrollDetailPatient value)?  $default,){
final _that = this;
switch (_that) {
case _PayrollDetailPatient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String visitId,  String patientName,  String amount,  String share)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollDetailPatient() when $default != null:
return $default(_that.visitId,_that.patientName,_that.amount,_that.share);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String visitId,  String patientName,  String amount,  String share)  $default,) {final _that = this;
switch (_that) {
case _PayrollDetailPatient():
return $default(_that.visitId,_that.patientName,_that.amount,_that.share);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String visitId,  String patientName,  String amount,  String share)?  $default,) {final _that = this;
switch (_that) {
case _PayrollDetailPatient() when $default != null:
return $default(_that.visitId,_that.patientName,_that.amount,_that.share);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayrollDetailPatient implements PayrollDetailPatient {
  const _PayrollDetailPatient({required this.visitId, required this.patientName, required this.amount, required this.share});
  factory _PayrollDetailPatient.fromJson(Map<String, dynamic> json) => _$PayrollDetailPatientFromJson(json);

@override final  String visitId;
@override final  String patientName;
@override final  String amount;
@override final  String share;

/// Create a copy of PayrollDetailPatient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollDetailPatientCopyWith<_PayrollDetailPatient> get copyWith => __$PayrollDetailPatientCopyWithImpl<_PayrollDetailPatient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayrollDetailPatientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollDetailPatient&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.share, share) || other.share == share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,visitId,patientName,amount,share);

@override
String toString() {
  return 'PayrollDetailPatient(visitId: $visitId, patientName: $patientName, amount: $amount, share: $share)';
}


}

/// @nodoc
abstract mixin class _$PayrollDetailPatientCopyWith<$Res> implements $PayrollDetailPatientCopyWith<$Res> {
  factory _$PayrollDetailPatientCopyWith(_PayrollDetailPatient value, $Res Function(_PayrollDetailPatient) _then) = __$PayrollDetailPatientCopyWithImpl;
@override @useResult
$Res call({
 String visitId, String patientName, String amount, String share
});




}
/// @nodoc
class __$PayrollDetailPatientCopyWithImpl<$Res>
    implements _$PayrollDetailPatientCopyWith<$Res> {
  __$PayrollDetailPatientCopyWithImpl(this._self, this._then);

  final _PayrollDetailPatient _self;
  final $Res Function(_PayrollDetailPatient) _then;

/// Create a copy of PayrollDetailPatient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? visitId = null,Object? patientName = null,Object? amount = null,Object? share = null,}) {
  return _then(_PayrollDetailPatient(
visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PayrollDetailOperation {

 String get date; String get patientName; String get typeName; String get price; String get share;
/// Create a copy of PayrollDetailOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollDetailOperationCopyWith<PayrollDetailOperation> get copyWith => _$PayrollDetailOperationCopyWithImpl<PayrollDetailOperation>(this as PayrollDetailOperation, _$identity);

  /// Serializes this PayrollDetailOperation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollDetailOperation&&(identical(other.date, date) || other.date == date)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.typeName, typeName) || other.typeName == typeName)&&(identical(other.price, price) || other.price == price)&&(identical(other.share, share) || other.share == share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,patientName,typeName,price,share);

@override
String toString() {
  return 'PayrollDetailOperation(date: $date, patientName: $patientName, typeName: $typeName, price: $price, share: $share)';
}


}

/// @nodoc
abstract mixin class $PayrollDetailOperationCopyWith<$Res>  {
  factory $PayrollDetailOperationCopyWith(PayrollDetailOperation value, $Res Function(PayrollDetailOperation) _then) = _$PayrollDetailOperationCopyWithImpl;
@useResult
$Res call({
 String date, String patientName, String typeName, String price, String share
});




}
/// @nodoc
class _$PayrollDetailOperationCopyWithImpl<$Res>
    implements $PayrollDetailOperationCopyWith<$Res> {
  _$PayrollDetailOperationCopyWithImpl(this._self, this._then);

  final PayrollDetailOperation _self;
  final $Res Function(PayrollDetailOperation) _then;

/// Create a copy of PayrollDetailOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? patientName = null,Object? typeName = null,Object? price = null,Object? share = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,typeName: null == typeName ? _self.typeName : typeName // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PayrollDetailOperation].
extension PayrollDetailOperationPatterns on PayrollDetailOperation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayrollDetailOperation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayrollDetailOperation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayrollDetailOperation value)  $default,){
final _that = this;
switch (_that) {
case _PayrollDetailOperation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayrollDetailOperation value)?  $default,){
final _that = this;
switch (_that) {
case _PayrollDetailOperation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  String patientName,  String typeName,  String price,  String share)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollDetailOperation() when $default != null:
return $default(_that.date,_that.patientName,_that.typeName,_that.price,_that.share);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  String patientName,  String typeName,  String price,  String share)  $default,) {final _that = this;
switch (_that) {
case _PayrollDetailOperation():
return $default(_that.date,_that.patientName,_that.typeName,_that.price,_that.share);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  String patientName,  String typeName,  String price,  String share)?  $default,) {final _that = this;
switch (_that) {
case _PayrollDetailOperation() when $default != null:
return $default(_that.date,_that.patientName,_that.typeName,_that.price,_that.share);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayrollDetailOperation implements PayrollDetailOperation {
  const _PayrollDetailOperation({required this.date, required this.patientName, required this.typeName, required this.price, required this.share});
  factory _PayrollDetailOperation.fromJson(Map<String, dynamic> json) => _$PayrollDetailOperationFromJson(json);

@override final  String date;
@override final  String patientName;
@override final  String typeName;
@override final  String price;
@override final  String share;

/// Create a copy of PayrollDetailOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollDetailOperationCopyWith<_PayrollDetailOperation> get copyWith => __$PayrollDetailOperationCopyWithImpl<_PayrollDetailOperation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayrollDetailOperationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollDetailOperation&&(identical(other.date, date) || other.date == date)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.typeName, typeName) || other.typeName == typeName)&&(identical(other.price, price) || other.price == price)&&(identical(other.share, share) || other.share == share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,patientName,typeName,price,share);

@override
String toString() {
  return 'PayrollDetailOperation(date: $date, patientName: $patientName, typeName: $typeName, price: $price, share: $share)';
}


}

/// @nodoc
abstract mixin class _$PayrollDetailOperationCopyWith<$Res> implements $PayrollDetailOperationCopyWith<$Res> {
  factory _$PayrollDetailOperationCopyWith(_PayrollDetailOperation value, $Res Function(_PayrollDetailOperation) _then) = __$PayrollDetailOperationCopyWithImpl;
@override @useResult
$Res call({
 String date, String patientName, String typeName, String price, String share
});




}
/// @nodoc
class __$PayrollDetailOperationCopyWithImpl<$Res>
    implements _$PayrollDetailOperationCopyWith<$Res> {
  __$PayrollDetailOperationCopyWithImpl(this._self, this._then);

  final _PayrollDetailOperation _self;
  final $Res Function(_PayrollDetailOperation) _then;

/// Create a copy of PayrollDetailOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? patientName = null,Object? typeName = null,Object? price = null,Object? share = null,}) {
  return _then(_PayrollDetailOperation(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,typeName: null == typeName ? _self.typeName : typeName // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
