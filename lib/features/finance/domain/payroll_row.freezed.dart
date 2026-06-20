// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayrollRow {

 String get userId; String get fullName;// Consultation side
 String? get consultSalaryType;// percent | fixed | null
 String? get consultSalaryValue; String get consultRevenue; String get consultPay;// Operation side (as surgeon)
 String? get operationSalaryType; String? get operationSalaryValue; String get operationRevenue; int get operationCount; String get operationPay;// Total + payout state
 String get salary; bool get paid; String? get paidAt; String? get paidAmount;
/// Create a copy of PayrollRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollRowCopyWith<PayrollRow> get copyWith => _$PayrollRowCopyWithImpl<PayrollRow>(this as PayrollRow, _$identity);

  /// Serializes this PayrollRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollRow&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.consultSalaryType, consultSalaryType) || other.consultSalaryType == consultSalaryType)&&(identical(other.consultSalaryValue, consultSalaryValue) || other.consultSalaryValue == consultSalaryValue)&&(identical(other.consultRevenue, consultRevenue) || other.consultRevenue == consultRevenue)&&(identical(other.consultPay, consultPay) || other.consultPay == consultPay)&&(identical(other.operationSalaryType, operationSalaryType) || other.operationSalaryType == operationSalaryType)&&(identical(other.operationSalaryValue, operationSalaryValue) || other.operationSalaryValue == operationSalaryValue)&&(identical(other.operationRevenue, operationRevenue) || other.operationRevenue == operationRevenue)&&(identical(other.operationCount, operationCount) || other.operationCount == operationCount)&&(identical(other.operationPay, operationPay) || other.operationPay == operationPay)&&(identical(other.salary, salary) || other.salary == salary)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,consultSalaryType,consultSalaryValue,consultRevenue,consultPay,operationSalaryType,operationSalaryValue,operationRevenue,operationCount,operationPay,salary,paid,paidAt,paidAmount);

@override
String toString() {
  return 'PayrollRow(userId: $userId, fullName: $fullName, consultSalaryType: $consultSalaryType, consultSalaryValue: $consultSalaryValue, consultRevenue: $consultRevenue, consultPay: $consultPay, operationSalaryType: $operationSalaryType, operationSalaryValue: $operationSalaryValue, operationRevenue: $operationRevenue, operationCount: $operationCount, operationPay: $operationPay, salary: $salary, paid: $paid, paidAt: $paidAt, paidAmount: $paidAmount)';
}


}

/// @nodoc
abstract mixin class $PayrollRowCopyWith<$Res>  {
  factory $PayrollRowCopyWith(PayrollRow value, $Res Function(PayrollRow) _then) = _$PayrollRowCopyWithImpl;
@useResult
$Res call({
 String userId, String fullName, String? consultSalaryType, String? consultSalaryValue, String consultRevenue, String consultPay, String? operationSalaryType, String? operationSalaryValue, String operationRevenue, int operationCount, String operationPay, String salary, bool paid, String? paidAt, String? paidAmount
});




}
/// @nodoc
class _$PayrollRowCopyWithImpl<$Res>
    implements $PayrollRowCopyWith<$Res> {
  _$PayrollRowCopyWithImpl(this._self, this._then);

  final PayrollRow _self;
  final $Res Function(PayrollRow) _then;

/// Create a copy of PayrollRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? consultSalaryType = freezed,Object? consultSalaryValue = freezed,Object? consultRevenue = null,Object? consultPay = null,Object? operationSalaryType = freezed,Object? operationSalaryValue = freezed,Object? operationRevenue = null,Object? operationCount = null,Object? operationPay = null,Object? salary = null,Object? paid = null,Object? paidAt = freezed,Object? paidAmount = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,consultSalaryType: freezed == consultSalaryType ? _self.consultSalaryType : consultSalaryType // ignore: cast_nullable_to_non_nullable
as String?,consultSalaryValue: freezed == consultSalaryValue ? _self.consultSalaryValue : consultSalaryValue // ignore: cast_nullable_to_non_nullable
as String?,consultRevenue: null == consultRevenue ? _self.consultRevenue : consultRevenue // ignore: cast_nullable_to_non_nullable
as String,consultPay: null == consultPay ? _self.consultPay : consultPay // ignore: cast_nullable_to_non_nullable
as String,operationSalaryType: freezed == operationSalaryType ? _self.operationSalaryType : operationSalaryType // ignore: cast_nullable_to_non_nullable
as String?,operationSalaryValue: freezed == operationSalaryValue ? _self.operationSalaryValue : operationSalaryValue // ignore: cast_nullable_to_non_nullable
as String?,operationRevenue: null == operationRevenue ? _self.operationRevenue : operationRevenue // ignore: cast_nullable_to_non_nullable
as String,operationCount: null == operationCount ? _self.operationCount : operationCount // ignore: cast_nullable_to_non_nullable
as int,operationPay: null == operationPay ? _self.operationPay : operationPay // ignore: cast_nullable_to_non_nullable
as String,salary: null == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,paidAmount: freezed == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PayrollRow].
extension PayrollRowPatterns on PayrollRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayrollRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayrollRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayrollRow value)  $default,){
final _that = this;
switch (_that) {
case _PayrollRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayrollRow value)?  $default,){
final _that = this;
switch (_that) {
case _PayrollRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fullName,  String? consultSalaryType,  String? consultSalaryValue,  String consultRevenue,  String consultPay,  String? operationSalaryType,  String? operationSalaryValue,  String operationRevenue,  int operationCount,  String operationPay,  String salary,  bool paid,  String? paidAt,  String? paidAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollRow() when $default != null:
return $default(_that.userId,_that.fullName,_that.consultSalaryType,_that.consultSalaryValue,_that.consultRevenue,_that.consultPay,_that.operationSalaryType,_that.operationSalaryValue,_that.operationRevenue,_that.operationCount,_that.operationPay,_that.salary,_that.paid,_that.paidAt,_that.paidAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fullName,  String? consultSalaryType,  String? consultSalaryValue,  String consultRevenue,  String consultPay,  String? operationSalaryType,  String? operationSalaryValue,  String operationRevenue,  int operationCount,  String operationPay,  String salary,  bool paid,  String? paidAt,  String? paidAmount)  $default,) {final _that = this;
switch (_that) {
case _PayrollRow():
return $default(_that.userId,_that.fullName,_that.consultSalaryType,_that.consultSalaryValue,_that.consultRevenue,_that.consultPay,_that.operationSalaryType,_that.operationSalaryValue,_that.operationRevenue,_that.operationCount,_that.operationPay,_that.salary,_that.paid,_that.paidAt,_that.paidAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fullName,  String? consultSalaryType,  String? consultSalaryValue,  String consultRevenue,  String consultPay,  String? operationSalaryType,  String? operationSalaryValue,  String operationRevenue,  int operationCount,  String operationPay,  String salary,  bool paid,  String? paidAt,  String? paidAmount)?  $default,) {final _that = this;
switch (_that) {
case _PayrollRow() when $default != null:
return $default(_that.userId,_that.fullName,_that.consultSalaryType,_that.consultSalaryValue,_that.consultRevenue,_that.consultPay,_that.operationSalaryType,_that.operationSalaryValue,_that.operationRevenue,_that.operationCount,_that.operationPay,_that.salary,_that.paid,_that.paidAt,_that.paidAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayrollRow implements PayrollRow {
  const _PayrollRow({required this.userId, required this.fullName, this.consultSalaryType, this.consultSalaryValue, required this.consultRevenue, required this.consultPay, this.operationSalaryType, this.operationSalaryValue, required this.operationRevenue, required this.operationCount, required this.operationPay, required this.salary, required this.paid, this.paidAt, this.paidAmount});
  factory _PayrollRow.fromJson(Map<String, dynamic> json) => _$PayrollRowFromJson(json);

@override final  String userId;
@override final  String fullName;
// Consultation side
@override final  String? consultSalaryType;
// percent | fixed | null
@override final  String? consultSalaryValue;
@override final  String consultRevenue;
@override final  String consultPay;
// Operation side (as surgeon)
@override final  String? operationSalaryType;
@override final  String? operationSalaryValue;
@override final  String operationRevenue;
@override final  int operationCount;
@override final  String operationPay;
// Total + payout state
@override final  String salary;
@override final  bool paid;
@override final  String? paidAt;
@override final  String? paidAmount;

/// Create a copy of PayrollRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollRowCopyWith<_PayrollRow> get copyWith => __$PayrollRowCopyWithImpl<_PayrollRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayrollRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollRow&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.consultSalaryType, consultSalaryType) || other.consultSalaryType == consultSalaryType)&&(identical(other.consultSalaryValue, consultSalaryValue) || other.consultSalaryValue == consultSalaryValue)&&(identical(other.consultRevenue, consultRevenue) || other.consultRevenue == consultRevenue)&&(identical(other.consultPay, consultPay) || other.consultPay == consultPay)&&(identical(other.operationSalaryType, operationSalaryType) || other.operationSalaryType == operationSalaryType)&&(identical(other.operationSalaryValue, operationSalaryValue) || other.operationSalaryValue == operationSalaryValue)&&(identical(other.operationRevenue, operationRevenue) || other.operationRevenue == operationRevenue)&&(identical(other.operationCount, operationCount) || other.operationCount == operationCount)&&(identical(other.operationPay, operationPay) || other.operationPay == operationPay)&&(identical(other.salary, salary) || other.salary == salary)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,consultSalaryType,consultSalaryValue,consultRevenue,consultPay,operationSalaryType,operationSalaryValue,operationRevenue,operationCount,operationPay,salary,paid,paidAt,paidAmount);

@override
String toString() {
  return 'PayrollRow(userId: $userId, fullName: $fullName, consultSalaryType: $consultSalaryType, consultSalaryValue: $consultSalaryValue, consultRevenue: $consultRevenue, consultPay: $consultPay, operationSalaryType: $operationSalaryType, operationSalaryValue: $operationSalaryValue, operationRevenue: $operationRevenue, operationCount: $operationCount, operationPay: $operationPay, salary: $salary, paid: $paid, paidAt: $paidAt, paidAmount: $paidAmount)';
}


}

/// @nodoc
abstract mixin class _$PayrollRowCopyWith<$Res> implements $PayrollRowCopyWith<$Res> {
  factory _$PayrollRowCopyWith(_PayrollRow value, $Res Function(_PayrollRow) _then) = __$PayrollRowCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fullName, String? consultSalaryType, String? consultSalaryValue, String consultRevenue, String consultPay, String? operationSalaryType, String? operationSalaryValue, String operationRevenue, int operationCount, String operationPay, String salary, bool paid, String? paidAt, String? paidAmount
});




}
/// @nodoc
class __$PayrollRowCopyWithImpl<$Res>
    implements _$PayrollRowCopyWith<$Res> {
  __$PayrollRowCopyWithImpl(this._self, this._then);

  final _PayrollRow _self;
  final $Res Function(_PayrollRow) _then;

/// Create a copy of PayrollRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? consultSalaryType = freezed,Object? consultSalaryValue = freezed,Object? consultRevenue = null,Object? consultPay = null,Object? operationSalaryType = freezed,Object? operationSalaryValue = freezed,Object? operationRevenue = null,Object? operationCount = null,Object? operationPay = null,Object? salary = null,Object? paid = null,Object? paidAt = freezed,Object? paidAmount = freezed,}) {
  return _then(_PayrollRow(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,consultSalaryType: freezed == consultSalaryType ? _self.consultSalaryType : consultSalaryType // ignore: cast_nullable_to_non_nullable
as String?,consultSalaryValue: freezed == consultSalaryValue ? _self.consultSalaryValue : consultSalaryValue // ignore: cast_nullable_to_non_nullable
as String?,consultRevenue: null == consultRevenue ? _self.consultRevenue : consultRevenue // ignore: cast_nullable_to_non_nullable
as String,consultPay: null == consultPay ? _self.consultPay : consultPay // ignore: cast_nullable_to_non_nullable
as String,operationSalaryType: freezed == operationSalaryType ? _self.operationSalaryType : operationSalaryType // ignore: cast_nullable_to_non_nullable
as String?,operationSalaryValue: freezed == operationSalaryValue ? _self.operationSalaryValue : operationSalaryValue // ignore: cast_nullable_to_non_nullable
as String?,operationRevenue: null == operationRevenue ? _self.operationRevenue : operationRevenue // ignore: cast_nullable_to_non_nullable
as String,operationCount: null == operationCount ? _self.operationCount : operationCount // ignore: cast_nullable_to_non_nullable
as int,operationPay: null == operationPay ? _self.operationPay : operationPay // ignore: cast_nullable_to_non_nullable
as String,salary: null == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,paidAmount: freezed == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
