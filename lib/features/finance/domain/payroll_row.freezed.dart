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

 String get userId; String get fullName; String get salaryPercent; String get revenue; String get salary; bool get paid; String? get paidAt;
/// Create a copy of PayrollRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollRowCopyWith<PayrollRow> get copyWith => _$PayrollRowCopyWithImpl<PayrollRow>(this as PayrollRow, _$identity);

  /// Serializes this PayrollRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollRow&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.salaryPercent, salaryPercent) || other.salaryPercent == salaryPercent)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.salary, salary) || other.salary == salary)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,salaryPercent,revenue,salary,paid,paidAt);

@override
String toString() {
  return 'PayrollRow(userId: $userId, fullName: $fullName, salaryPercent: $salaryPercent, revenue: $revenue, salary: $salary, paid: $paid, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class $PayrollRowCopyWith<$Res>  {
  factory $PayrollRowCopyWith(PayrollRow value, $Res Function(PayrollRow) _then) = _$PayrollRowCopyWithImpl;
@useResult
$Res call({
 String userId, String fullName, String salaryPercent, String revenue, String salary, bool paid, String? paidAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? salaryPercent = null,Object? revenue = null,Object? salary = null,Object? paid = null,Object? paidAt = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,salaryPercent: null == salaryPercent ? _self.salaryPercent : salaryPercent // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,salary: null == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fullName,  String salaryPercent,  String revenue,  String salary,  bool paid,  String? paidAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollRow() when $default != null:
return $default(_that.userId,_that.fullName,_that.salaryPercent,_that.revenue,_that.salary,_that.paid,_that.paidAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fullName,  String salaryPercent,  String revenue,  String salary,  bool paid,  String? paidAt)  $default,) {final _that = this;
switch (_that) {
case _PayrollRow():
return $default(_that.userId,_that.fullName,_that.salaryPercent,_that.revenue,_that.salary,_that.paid,_that.paidAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fullName,  String salaryPercent,  String revenue,  String salary,  bool paid,  String? paidAt)?  $default,) {final _that = this;
switch (_that) {
case _PayrollRow() when $default != null:
return $default(_that.userId,_that.fullName,_that.salaryPercent,_that.revenue,_that.salary,_that.paid,_that.paidAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayrollRow implements PayrollRow {
  const _PayrollRow({required this.userId, required this.fullName, required this.salaryPercent, required this.revenue, required this.salary, required this.paid, this.paidAt});
  factory _PayrollRow.fromJson(Map<String, dynamic> json) => _$PayrollRowFromJson(json);

@override final  String userId;
@override final  String fullName;
@override final  String salaryPercent;
@override final  String revenue;
@override final  String salary;
@override final  bool paid;
@override final  String? paidAt;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollRow&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.salaryPercent, salaryPercent) || other.salaryPercent == salaryPercent)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.salary, salary) || other.salary == salary)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,salaryPercent,revenue,salary,paid,paidAt);

@override
String toString() {
  return 'PayrollRow(userId: $userId, fullName: $fullName, salaryPercent: $salaryPercent, revenue: $revenue, salary: $salary, paid: $paid, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class _$PayrollRowCopyWith<$Res> implements $PayrollRowCopyWith<$Res> {
  factory _$PayrollRowCopyWith(_PayrollRow value, $Res Function(_PayrollRow) _then) = __$PayrollRowCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fullName, String salaryPercent, String revenue, String salary, bool paid, String? paidAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? salaryPercent = null,Object? revenue = null,Object? salary = null,Object? paid = null,Object? paidAt = freezed,}) {
  return _then(_PayrollRow(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,salaryPercent: null == salaryPercent ? _self.salaryPercent : salaryPercent // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,salary: null == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
