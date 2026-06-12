// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cash_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyReport {

 String get date;// YYYY-MM-DD
 Map<String, String> get incomeByMethod; String get incomeTotal; String get refundTotal; String get expenseTotal; String get net;
/// Create a copy of DailyReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyReportCopyWith<DailyReport> get copyWith => _$DailyReportCopyWithImpl<DailyReport>(this as DailyReport, _$identity);

  /// Serializes this DailyReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyReport&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.incomeByMethod, incomeByMethod)&&(identical(other.incomeTotal, incomeTotal) || other.incomeTotal == incomeTotal)&&(identical(other.refundTotal, refundTotal) || other.refundTotal == refundTotal)&&(identical(other.expenseTotal, expenseTotal) || other.expenseTotal == expenseTotal)&&(identical(other.net, net) || other.net == net));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(incomeByMethod),incomeTotal,refundTotal,expenseTotal,net);

@override
String toString() {
  return 'DailyReport(date: $date, incomeByMethod: $incomeByMethod, incomeTotal: $incomeTotal, refundTotal: $refundTotal, expenseTotal: $expenseTotal, net: $net)';
}


}

/// @nodoc
abstract mixin class $DailyReportCopyWith<$Res>  {
  factory $DailyReportCopyWith(DailyReport value, $Res Function(DailyReport) _then) = _$DailyReportCopyWithImpl;
@useResult
$Res call({
 String date, Map<String, String> incomeByMethod, String incomeTotal, String refundTotal, String expenseTotal, String net
});




}
/// @nodoc
class _$DailyReportCopyWithImpl<$Res>
    implements $DailyReportCopyWith<$Res> {
  _$DailyReportCopyWithImpl(this._self, this._then);

  final DailyReport _self;
  final $Res Function(DailyReport) _then;

/// Create a copy of DailyReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? incomeByMethod = null,Object? incomeTotal = null,Object? refundTotal = null,Object? expenseTotal = null,Object? net = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,incomeByMethod: null == incomeByMethod ? _self.incomeByMethod : incomeByMethod // ignore: cast_nullable_to_non_nullable
as Map<String, String>,incomeTotal: null == incomeTotal ? _self.incomeTotal : incomeTotal // ignore: cast_nullable_to_non_nullable
as String,refundTotal: null == refundTotal ? _self.refundTotal : refundTotal // ignore: cast_nullable_to_non_nullable
as String,expenseTotal: null == expenseTotal ? _self.expenseTotal : expenseTotal // ignore: cast_nullable_to_non_nullable
as String,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyReport].
extension DailyReportPatterns on DailyReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyReport value)  $default,){
final _that = this;
switch (_that) {
case _DailyReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyReport value)?  $default,){
final _that = this;
switch (_that) {
case _DailyReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  Map<String, String> incomeByMethod,  String incomeTotal,  String refundTotal,  String expenseTotal,  String net)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyReport() when $default != null:
return $default(_that.date,_that.incomeByMethod,_that.incomeTotal,_that.refundTotal,_that.expenseTotal,_that.net);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  Map<String, String> incomeByMethod,  String incomeTotal,  String refundTotal,  String expenseTotal,  String net)  $default,) {final _that = this;
switch (_that) {
case _DailyReport():
return $default(_that.date,_that.incomeByMethod,_that.incomeTotal,_that.refundTotal,_that.expenseTotal,_that.net);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  Map<String, String> incomeByMethod,  String incomeTotal,  String refundTotal,  String expenseTotal,  String net)?  $default,) {final _that = this;
switch (_that) {
case _DailyReport() when $default != null:
return $default(_that.date,_that.incomeByMethod,_that.incomeTotal,_that.refundTotal,_that.expenseTotal,_that.net);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyReport implements DailyReport {
  const _DailyReport({required this.date, required final  Map<String, String> incomeByMethod, required this.incomeTotal, required this.refundTotal, required this.expenseTotal, required this.net}): _incomeByMethod = incomeByMethod;
  factory _DailyReport.fromJson(Map<String, dynamic> json) => _$DailyReportFromJson(json);

@override final  String date;
// YYYY-MM-DD
 final  Map<String, String> _incomeByMethod;
// YYYY-MM-DD
@override Map<String, String> get incomeByMethod {
  if (_incomeByMethod is EqualUnmodifiableMapView) return _incomeByMethod;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_incomeByMethod);
}

@override final  String incomeTotal;
@override final  String refundTotal;
@override final  String expenseTotal;
@override final  String net;

/// Create a copy of DailyReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyReportCopyWith<_DailyReport> get copyWith => __$DailyReportCopyWithImpl<_DailyReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyReport&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._incomeByMethod, _incomeByMethod)&&(identical(other.incomeTotal, incomeTotal) || other.incomeTotal == incomeTotal)&&(identical(other.refundTotal, refundTotal) || other.refundTotal == refundTotal)&&(identical(other.expenseTotal, expenseTotal) || other.expenseTotal == expenseTotal)&&(identical(other.net, net) || other.net == net));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_incomeByMethod),incomeTotal,refundTotal,expenseTotal,net);

@override
String toString() {
  return 'DailyReport(date: $date, incomeByMethod: $incomeByMethod, incomeTotal: $incomeTotal, refundTotal: $refundTotal, expenseTotal: $expenseTotal, net: $net)';
}


}

/// @nodoc
abstract mixin class _$DailyReportCopyWith<$Res> implements $DailyReportCopyWith<$Res> {
  factory _$DailyReportCopyWith(_DailyReport value, $Res Function(_DailyReport) _then) = __$DailyReportCopyWithImpl;
@override @useResult
$Res call({
 String date, Map<String, String> incomeByMethod, String incomeTotal, String refundTotal, String expenseTotal, String net
});




}
/// @nodoc
class __$DailyReportCopyWithImpl<$Res>
    implements _$DailyReportCopyWith<$Res> {
  __$DailyReportCopyWithImpl(this._self, this._then);

  final _DailyReport _self;
  final $Res Function(_DailyReport) _then;

/// Create a copy of DailyReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? incomeByMethod = null,Object? incomeTotal = null,Object? refundTotal = null,Object? expenseTotal = null,Object? net = null,}) {
  return _then(_DailyReport(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,incomeByMethod: null == incomeByMethod ? _self._incomeByMethod : incomeByMethod // ignore: cast_nullable_to_non_nullable
as Map<String, String>,incomeTotal: null == incomeTotal ? _self.incomeTotal : incomeTotal // ignore: cast_nullable_to_non_nullable
as String,refundTotal: null == refundTotal ? _self.refundTotal : refundTotal // ignore: cast_nullable_to_non_nullable
as String,expenseTotal: null == expenseTotal ? _self.expenseTotal : expenseTotal // ignore: cast_nullable_to_non_nullable
as String,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MonthlyReport {

 String get month;// YYYY-MM
 Map<String, String> get incomeByMethod; String get incomeTotal; String get refundTotal; String get expenseTotal; String get net; String get payrollTotal;
/// Create a copy of MonthlyReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlyReportCopyWith<MonthlyReport> get copyWith => _$MonthlyReportCopyWithImpl<MonthlyReport>(this as MonthlyReport, _$identity);

  /// Serializes this MonthlyReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlyReport&&(identical(other.month, month) || other.month == month)&&const DeepCollectionEquality().equals(other.incomeByMethod, incomeByMethod)&&(identical(other.incomeTotal, incomeTotal) || other.incomeTotal == incomeTotal)&&(identical(other.refundTotal, refundTotal) || other.refundTotal == refundTotal)&&(identical(other.expenseTotal, expenseTotal) || other.expenseTotal == expenseTotal)&&(identical(other.net, net) || other.net == net)&&(identical(other.payrollTotal, payrollTotal) || other.payrollTotal == payrollTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,const DeepCollectionEquality().hash(incomeByMethod),incomeTotal,refundTotal,expenseTotal,net,payrollTotal);

@override
String toString() {
  return 'MonthlyReport(month: $month, incomeByMethod: $incomeByMethod, incomeTotal: $incomeTotal, refundTotal: $refundTotal, expenseTotal: $expenseTotal, net: $net, payrollTotal: $payrollTotal)';
}


}

/// @nodoc
abstract mixin class $MonthlyReportCopyWith<$Res>  {
  factory $MonthlyReportCopyWith(MonthlyReport value, $Res Function(MonthlyReport) _then) = _$MonthlyReportCopyWithImpl;
@useResult
$Res call({
 String month, Map<String, String> incomeByMethod, String incomeTotal, String refundTotal, String expenseTotal, String net, String payrollTotal
});




}
/// @nodoc
class _$MonthlyReportCopyWithImpl<$Res>
    implements $MonthlyReportCopyWith<$Res> {
  _$MonthlyReportCopyWithImpl(this._self, this._then);

  final MonthlyReport _self;
  final $Res Function(MonthlyReport) _then;

/// Create a copy of MonthlyReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? incomeByMethod = null,Object? incomeTotal = null,Object? refundTotal = null,Object? expenseTotal = null,Object? net = null,Object? payrollTotal = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,incomeByMethod: null == incomeByMethod ? _self.incomeByMethod : incomeByMethod // ignore: cast_nullable_to_non_nullable
as Map<String, String>,incomeTotal: null == incomeTotal ? _self.incomeTotal : incomeTotal // ignore: cast_nullable_to_non_nullable
as String,refundTotal: null == refundTotal ? _self.refundTotal : refundTotal // ignore: cast_nullable_to_non_nullable
as String,expenseTotal: null == expenseTotal ? _self.expenseTotal : expenseTotal // ignore: cast_nullable_to_non_nullable
as String,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as String,payrollTotal: null == payrollTotal ? _self.payrollTotal : payrollTotal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlyReport].
extension MonthlyReportPatterns on MonthlyReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlyReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlyReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlyReport value)  $default,){
final _that = this;
switch (_that) {
case _MonthlyReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlyReport value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlyReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month,  Map<String, String> incomeByMethod,  String incomeTotal,  String refundTotal,  String expenseTotal,  String net,  String payrollTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlyReport() when $default != null:
return $default(_that.month,_that.incomeByMethod,_that.incomeTotal,_that.refundTotal,_that.expenseTotal,_that.net,_that.payrollTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month,  Map<String, String> incomeByMethod,  String incomeTotal,  String refundTotal,  String expenseTotal,  String net,  String payrollTotal)  $default,) {final _that = this;
switch (_that) {
case _MonthlyReport():
return $default(_that.month,_that.incomeByMethod,_that.incomeTotal,_that.refundTotal,_that.expenseTotal,_that.net,_that.payrollTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month,  Map<String, String> incomeByMethod,  String incomeTotal,  String refundTotal,  String expenseTotal,  String net,  String payrollTotal)?  $default,) {final _that = this;
switch (_that) {
case _MonthlyReport() when $default != null:
return $default(_that.month,_that.incomeByMethod,_that.incomeTotal,_that.refundTotal,_that.expenseTotal,_that.net,_that.payrollTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthlyReport implements MonthlyReport {
  const _MonthlyReport({required this.month, required final  Map<String, String> incomeByMethod, required this.incomeTotal, required this.refundTotal, required this.expenseTotal, required this.net, required this.payrollTotal}): _incomeByMethod = incomeByMethod;
  factory _MonthlyReport.fromJson(Map<String, dynamic> json) => _$MonthlyReportFromJson(json);

@override final  String month;
// YYYY-MM
 final  Map<String, String> _incomeByMethod;
// YYYY-MM
@override Map<String, String> get incomeByMethod {
  if (_incomeByMethod is EqualUnmodifiableMapView) return _incomeByMethod;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_incomeByMethod);
}

@override final  String incomeTotal;
@override final  String refundTotal;
@override final  String expenseTotal;
@override final  String net;
@override final  String payrollTotal;

/// Create a copy of MonthlyReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlyReportCopyWith<_MonthlyReport> get copyWith => __$MonthlyReportCopyWithImpl<_MonthlyReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthlyReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlyReport&&(identical(other.month, month) || other.month == month)&&const DeepCollectionEquality().equals(other._incomeByMethod, _incomeByMethod)&&(identical(other.incomeTotal, incomeTotal) || other.incomeTotal == incomeTotal)&&(identical(other.refundTotal, refundTotal) || other.refundTotal == refundTotal)&&(identical(other.expenseTotal, expenseTotal) || other.expenseTotal == expenseTotal)&&(identical(other.net, net) || other.net == net)&&(identical(other.payrollTotal, payrollTotal) || other.payrollTotal == payrollTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,const DeepCollectionEquality().hash(_incomeByMethod),incomeTotal,refundTotal,expenseTotal,net,payrollTotal);

@override
String toString() {
  return 'MonthlyReport(month: $month, incomeByMethod: $incomeByMethod, incomeTotal: $incomeTotal, refundTotal: $refundTotal, expenseTotal: $expenseTotal, net: $net, payrollTotal: $payrollTotal)';
}


}

/// @nodoc
abstract mixin class _$MonthlyReportCopyWith<$Res> implements $MonthlyReportCopyWith<$Res> {
  factory _$MonthlyReportCopyWith(_MonthlyReport value, $Res Function(_MonthlyReport) _then) = __$MonthlyReportCopyWithImpl;
@override @useResult
$Res call({
 String month, Map<String, String> incomeByMethod, String incomeTotal, String refundTotal, String expenseTotal, String net, String payrollTotal
});




}
/// @nodoc
class __$MonthlyReportCopyWithImpl<$Res>
    implements _$MonthlyReportCopyWith<$Res> {
  __$MonthlyReportCopyWithImpl(this._self, this._then);

  final _MonthlyReport _self;
  final $Res Function(_MonthlyReport) _then;

/// Create a copy of MonthlyReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? incomeByMethod = null,Object? incomeTotal = null,Object? refundTotal = null,Object? expenseTotal = null,Object? net = null,Object? payrollTotal = null,}) {
  return _then(_MonthlyReport(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,incomeByMethod: null == incomeByMethod ? _self._incomeByMethod : incomeByMethod // ignore: cast_nullable_to_non_nullable
as Map<String, String>,incomeTotal: null == incomeTotal ? _self.incomeTotal : incomeTotal // ignore: cast_nullable_to_non_nullable
as String,refundTotal: null == refundTotal ? _self.refundTotal : refundTotal // ignore: cast_nullable_to_non_nullable
as String,expenseTotal: null == expenseTotal ? _self.expenseTotal : expenseTotal // ignore: cast_nullable_to_non_nullable
as String,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as String,payrollTotal: null == payrollTotal ? _self.payrollTotal : payrollTotal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
