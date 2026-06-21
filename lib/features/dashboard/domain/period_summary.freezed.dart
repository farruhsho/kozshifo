// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PeriodSummary {

 String get period; String get dateFrom; String get dateTo; String get revenue; String get expenses; String get profit; int get newPatients; int get visits; int get operations; int get diagnostics; int get treatments;
/// Create a copy of PeriodSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodSummaryCopyWith<PeriodSummary> get copyWith => _$PeriodSummaryCopyWithImpl<PeriodSummary>(this as PeriodSummary, _$identity);

  /// Serializes this PeriodSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodSummary&&(identical(other.period, period) || other.period == period)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.expenses, expenses) || other.expenses == expenses)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.newPatients, newPatients) || other.newPatients == newPatients)&&(identical(other.visits, visits) || other.visits == visits)&&(identical(other.operations, operations) || other.operations == operations)&&(identical(other.diagnostics, diagnostics) || other.diagnostics == diagnostics)&&(identical(other.treatments, treatments) || other.treatments == treatments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,dateFrom,dateTo,revenue,expenses,profit,newPatients,visits,operations,diagnostics,treatments);

@override
String toString() {
  return 'PeriodSummary(period: $period, dateFrom: $dateFrom, dateTo: $dateTo, revenue: $revenue, expenses: $expenses, profit: $profit, newPatients: $newPatients, visits: $visits, operations: $operations, diagnostics: $diagnostics, treatments: $treatments)';
}


}

/// @nodoc
abstract mixin class $PeriodSummaryCopyWith<$Res>  {
  factory $PeriodSummaryCopyWith(PeriodSummary value, $Res Function(PeriodSummary) _then) = _$PeriodSummaryCopyWithImpl;
@useResult
$Res call({
 String period, String dateFrom, String dateTo, String revenue, String expenses, String profit, int newPatients, int visits, int operations, int diagnostics, int treatments
});




}
/// @nodoc
class _$PeriodSummaryCopyWithImpl<$Res>
    implements $PeriodSummaryCopyWith<$Res> {
  _$PeriodSummaryCopyWithImpl(this._self, this._then);

  final PeriodSummary _self;
  final $Res Function(PeriodSummary) _then;

/// Create a copy of PeriodSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? dateFrom = null,Object? dateTo = null,Object? revenue = null,Object? expenses = null,Object? profit = null,Object? newPatients = null,Object? visits = null,Object? operations = null,Object? diagnostics = null,Object? treatments = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,dateFrom: null == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as String,dateTo: null == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,newPatients: null == newPatients ? _self.newPatients : newPatients // ignore: cast_nullable_to_non_nullable
as int,visits: null == visits ? _self.visits : visits // ignore: cast_nullable_to_non_nullable
as int,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as int,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as int,treatments: null == treatments ? _self.treatments : treatments // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodSummary].
extension PeriodSummaryPatterns on PeriodSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodSummary value)  $default,){
final _that = this;
switch (_that) {
case _PeriodSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String period,  String dateFrom,  String dateTo,  String revenue,  String expenses,  String profit,  int newPatients,  int visits,  int operations,  int diagnostics,  int treatments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodSummary() when $default != null:
return $default(_that.period,_that.dateFrom,_that.dateTo,_that.revenue,_that.expenses,_that.profit,_that.newPatients,_that.visits,_that.operations,_that.diagnostics,_that.treatments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String period,  String dateFrom,  String dateTo,  String revenue,  String expenses,  String profit,  int newPatients,  int visits,  int operations,  int diagnostics,  int treatments)  $default,) {final _that = this;
switch (_that) {
case _PeriodSummary():
return $default(_that.period,_that.dateFrom,_that.dateTo,_that.revenue,_that.expenses,_that.profit,_that.newPatients,_that.visits,_that.operations,_that.diagnostics,_that.treatments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String period,  String dateFrom,  String dateTo,  String revenue,  String expenses,  String profit,  int newPatients,  int visits,  int operations,  int diagnostics,  int treatments)?  $default,) {final _that = this;
switch (_that) {
case _PeriodSummary() when $default != null:
return $default(_that.period,_that.dateFrom,_that.dateTo,_that.revenue,_that.expenses,_that.profit,_that.newPatients,_that.visits,_that.operations,_that.diagnostics,_that.treatments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodSummary implements PeriodSummary {
  const _PeriodSummary({required this.period, required this.dateFrom, required this.dateTo, required this.revenue, required this.expenses, required this.profit, required this.newPatients, required this.visits, required this.operations, required this.diagnostics, required this.treatments});
  factory _PeriodSummary.fromJson(Map<String, dynamic> json) => _$PeriodSummaryFromJson(json);

@override final  String period;
@override final  String dateFrom;
@override final  String dateTo;
@override final  String revenue;
@override final  String expenses;
@override final  String profit;
@override final  int newPatients;
@override final  int visits;
@override final  int operations;
@override final  int diagnostics;
@override final  int treatments;

/// Create a copy of PeriodSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodSummaryCopyWith<_PeriodSummary> get copyWith => __$PeriodSummaryCopyWithImpl<_PeriodSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodSummary&&(identical(other.period, period) || other.period == period)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.expenses, expenses) || other.expenses == expenses)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.newPatients, newPatients) || other.newPatients == newPatients)&&(identical(other.visits, visits) || other.visits == visits)&&(identical(other.operations, operations) || other.operations == operations)&&(identical(other.diagnostics, diagnostics) || other.diagnostics == diagnostics)&&(identical(other.treatments, treatments) || other.treatments == treatments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,dateFrom,dateTo,revenue,expenses,profit,newPatients,visits,operations,diagnostics,treatments);

@override
String toString() {
  return 'PeriodSummary(period: $period, dateFrom: $dateFrom, dateTo: $dateTo, revenue: $revenue, expenses: $expenses, profit: $profit, newPatients: $newPatients, visits: $visits, operations: $operations, diagnostics: $diagnostics, treatments: $treatments)';
}


}

/// @nodoc
abstract mixin class _$PeriodSummaryCopyWith<$Res> implements $PeriodSummaryCopyWith<$Res> {
  factory _$PeriodSummaryCopyWith(_PeriodSummary value, $Res Function(_PeriodSummary) _then) = __$PeriodSummaryCopyWithImpl;
@override @useResult
$Res call({
 String period, String dateFrom, String dateTo, String revenue, String expenses, String profit, int newPatients, int visits, int operations, int diagnostics, int treatments
});




}
/// @nodoc
class __$PeriodSummaryCopyWithImpl<$Res>
    implements _$PeriodSummaryCopyWith<$Res> {
  __$PeriodSummaryCopyWithImpl(this._self, this._then);

  final _PeriodSummary _self;
  final $Res Function(_PeriodSummary) _then;

/// Create a copy of PeriodSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? dateFrom = null,Object? dateTo = null,Object? revenue = null,Object? expenses = null,Object? profit = null,Object? newPatients = null,Object? visits = null,Object? operations = null,Object? diagnostics = null,Object? treatments = null,}) {
  return _then(_PeriodSummary(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,dateFrom: null == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as String,dateTo: null == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,newPatients: null == newPatients ? _self.newPatients : newPatients // ignore: cast_nullable_to_non_nullable
as int,visits: null == visits ? _self.visits : visits // ignore: cast_nullable_to_non_nullable
as int,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as int,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as int,treatments: null == treatments ? _self.treatments : treatments // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
