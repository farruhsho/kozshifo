// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DashboardSummary {

 String get revenueToday; String get revenueMonth; int get paymentsToday; String get averageCheckToday; int get visitsToday; int get newPatientsToday; int get patientsTotal; int get queueWaiting;
/// Create a copy of DashboardSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardSummaryCopyWith<DashboardSummary> get copyWith => _$DashboardSummaryCopyWithImpl<DashboardSummary>(this as DashboardSummary, _$identity);

  /// Serializes this DashboardSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardSummary&&(identical(other.revenueToday, revenueToday) || other.revenueToday == revenueToday)&&(identical(other.revenueMonth, revenueMonth) || other.revenueMonth == revenueMonth)&&(identical(other.paymentsToday, paymentsToday) || other.paymentsToday == paymentsToday)&&(identical(other.averageCheckToday, averageCheckToday) || other.averageCheckToday == averageCheckToday)&&(identical(other.visitsToday, visitsToday) || other.visitsToday == visitsToday)&&(identical(other.newPatientsToday, newPatientsToday) || other.newPatientsToday == newPatientsToday)&&(identical(other.patientsTotal, patientsTotal) || other.patientsTotal == patientsTotal)&&(identical(other.queueWaiting, queueWaiting) || other.queueWaiting == queueWaiting));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,revenueToday,revenueMonth,paymentsToday,averageCheckToday,visitsToday,newPatientsToday,patientsTotal,queueWaiting);

@override
String toString() {
  return 'DashboardSummary(revenueToday: $revenueToday, revenueMonth: $revenueMonth, paymentsToday: $paymentsToday, averageCheckToday: $averageCheckToday, visitsToday: $visitsToday, newPatientsToday: $newPatientsToday, patientsTotal: $patientsTotal, queueWaiting: $queueWaiting)';
}


}

/// @nodoc
abstract mixin class $DashboardSummaryCopyWith<$Res>  {
  factory $DashboardSummaryCopyWith(DashboardSummary value, $Res Function(DashboardSummary) _then) = _$DashboardSummaryCopyWithImpl;
@useResult
$Res call({
 String revenueToday, String revenueMonth, int paymentsToday, String averageCheckToday, int visitsToday, int newPatientsToday, int patientsTotal, int queueWaiting
});




}
/// @nodoc
class _$DashboardSummaryCopyWithImpl<$Res>
    implements $DashboardSummaryCopyWith<$Res> {
  _$DashboardSummaryCopyWithImpl(this._self, this._then);

  final DashboardSummary _self;
  final $Res Function(DashboardSummary) _then;

/// Create a copy of DashboardSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? revenueToday = null,Object? revenueMonth = null,Object? paymentsToday = null,Object? averageCheckToday = null,Object? visitsToday = null,Object? newPatientsToday = null,Object? patientsTotal = null,Object? queueWaiting = null,}) {
  return _then(_self.copyWith(
revenueToday: null == revenueToday ? _self.revenueToday : revenueToday // ignore: cast_nullable_to_non_nullable
as String,revenueMonth: null == revenueMonth ? _self.revenueMonth : revenueMonth // ignore: cast_nullable_to_non_nullable
as String,paymentsToday: null == paymentsToday ? _self.paymentsToday : paymentsToday // ignore: cast_nullable_to_non_nullable
as int,averageCheckToday: null == averageCheckToday ? _self.averageCheckToday : averageCheckToday // ignore: cast_nullable_to_non_nullable
as String,visitsToday: null == visitsToday ? _self.visitsToday : visitsToday // ignore: cast_nullable_to_non_nullable
as int,newPatientsToday: null == newPatientsToday ? _self.newPatientsToday : newPatientsToday // ignore: cast_nullable_to_non_nullable
as int,patientsTotal: null == patientsTotal ? _self.patientsTotal : patientsTotal // ignore: cast_nullable_to_non_nullable
as int,queueWaiting: null == queueWaiting ? _self.queueWaiting : queueWaiting // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardSummary].
extension DashboardSummaryPatterns on DashboardSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardSummary value)  $default,){
final _that = this;
switch (_that) {
case _DashboardSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardSummary value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String revenueToday,  String revenueMonth,  int paymentsToday,  String averageCheckToday,  int visitsToday,  int newPatientsToday,  int patientsTotal,  int queueWaiting)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardSummary() when $default != null:
return $default(_that.revenueToday,_that.revenueMonth,_that.paymentsToday,_that.averageCheckToday,_that.visitsToday,_that.newPatientsToday,_that.patientsTotal,_that.queueWaiting);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String revenueToday,  String revenueMonth,  int paymentsToday,  String averageCheckToday,  int visitsToday,  int newPatientsToday,  int patientsTotal,  int queueWaiting)  $default,) {final _that = this;
switch (_that) {
case _DashboardSummary():
return $default(_that.revenueToday,_that.revenueMonth,_that.paymentsToday,_that.averageCheckToday,_that.visitsToday,_that.newPatientsToday,_that.patientsTotal,_that.queueWaiting);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String revenueToday,  String revenueMonth,  int paymentsToday,  String averageCheckToday,  int visitsToday,  int newPatientsToday,  int patientsTotal,  int queueWaiting)?  $default,) {final _that = this;
switch (_that) {
case _DashboardSummary() when $default != null:
return $default(_that.revenueToday,_that.revenueMonth,_that.paymentsToday,_that.averageCheckToday,_that.visitsToday,_that.newPatientsToday,_that.patientsTotal,_that.queueWaiting);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardSummary implements DashboardSummary {
  const _DashboardSummary({required this.revenueToday, required this.revenueMonth, required this.paymentsToday, required this.averageCheckToday, required this.visitsToday, required this.newPatientsToday, required this.patientsTotal, required this.queueWaiting});
  factory _DashboardSummary.fromJson(Map<String, dynamic> json) => _$DashboardSummaryFromJson(json);

@override final  String revenueToday;
@override final  String revenueMonth;
@override final  int paymentsToday;
@override final  String averageCheckToday;
@override final  int visitsToday;
@override final  int newPatientsToday;
@override final  int patientsTotal;
@override final  int queueWaiting;

/// Create a copy of DashboardSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardSummaryCopyWith<_DashboardSummary> get copyWith => __$DashboardSummaryCopyWithImpl<_DashboardSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardSummary&&(identical(other.revenueToday, revenueToday) || other.revenueToday == revenueToday)&&(identical(other.revenueMonth, revenueMonth) || other.revenueMonth == revenueMonth)&&(identical(other.paymentsToday, paymentsToday) || other.paymentsToday == paymentsToday)&&(identical(other.averageCheckToday, averageCheckToday) || other.averageCheckToday == averageCheckToday)&&(identical(other.visitsToday, visitsToday) || other.visitsToday == visitsToday)&&(identical(other.newPatientsToday, newPatientsToday) || other.newPatientsToday == newPatientsToday)&&(identical(other.patientsTotal, patientsTotal) || other.patientsTotal == patientsTotal)&&(identical(other.queueWaiting, queueWaiting) || other.queueWaiting == queueWaiting));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,revenueToday,revenueMonth,paymentsToday,averageCheckToday,visitsToday,newPatientsToday,patientsTotal,queueWaiting);

@override
String toString() {
  return 'DashboardSummary(revenueToday: $revenueToday, revenueMonth: $revenueMonth, paymentsToday: $paymentsToday, averageCheckToday: $averageCheckToday, visitsToday: $visitsToday, newPatientsToday: $newPatientsToday, patientsTotal: $patientsTotal, queueWaiting: $queueWaiting)';
}


}

/// @nodoc
abstract mixin class _$DashboardSummaryCopyWith<$Res> implements $DashboardSummaryCopyWith<$Res> {
  factory _$DashboardSummaryCopyWith(_DashboardSummary value, $Res Function(_DashboardSummary) _then) = __$DashboardSummaryCopyWithImpl;
@override @useResult
$Res call({
 String revenueToday, String revenueMonth, int paymentsToday, String averageCheckToday, int visitsToday, int newPatientsToday, int patientsTotal, int queueWaiting
});




}
/// @nodoc
class __$DashboardSummaryCopyWithImpl<$Res>
    implements _$DashboardSummaryCopyWith<$Res> {
  __$DashboardSummaryCopyWithImpl(this._self, this._then);

  final _DashboardSummary _self;
  final $Res Function(_DashboardSummary) _then;

/// Create a copy of DashboardSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? revenueToday = null,Object? revenueMonth = null,Object? paymentsToday = null,Object? averageCheckToday = null,Object? visitsToday = null,Object? newPatientsToday = null,Object? patientsTotal = null,Object? queueWaiting = null,}) {
  return _then(_DashboardSummary(
revenueToday: null == revenueToday ? _self.revenueToday : revenueToday // ignore: cast_nullable_to_non_nullable
as String,revenueMonth: null == revenueMonth ? _self.revenueMonth : revenueMonth // ignore: cast_nullable_to_non_nullable
as String,paymentsToday: null == paymentsToday ? _self.paymentsToday : paymentsToday // ignore: cast_nullable_to_non_nullable
as int,averageCheckToday: null == averageCheckToday ? _self.averageCheckToday : averageCheckToday // ignore: cast_nullable_to_non_nullable
as String,visitsToday: null == visitsToday ? _self.visitsToday : visitsToday // ignore: cast_nullable_to_non_nullable
as int,newPatientsToday: null == newPatientsToday ? _self.newPatientsToday : newPatientsToday // ignore: cast_nullable_to_non_nullable
as int,patientsTotal: null == patientsTotal ? _self.patientsTotal : patientsTotal // ignore: cast_nullable_to_non_nullable
as int,queueWaiting: null == queueWaiting ? _self.queueWaiting : queueWaiting // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
