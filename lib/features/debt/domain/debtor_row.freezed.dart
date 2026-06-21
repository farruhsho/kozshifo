// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debtor_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DebtorRow {

 String get patientId; String get patientName; String? get phone; String? get patientNo; String get totalDebt;// decimal string, e.g. "150000.00"
 int get visitCount; String get oldestDebtAt;// ISO datetime
 String? get lastPaymentAt;
/// Create a copy of DebtorRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebtorRowCopyWith<DebtorRow> get copyWith => _$DebtorRowCopyWithImpl<DebtorRow>(this as DebtorRow, _$identity);

  /// Serializes this DebtorRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebtorRow&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.patientNo, patientNo) || other.patientNo == patientNo)&&(identical(other.totalDebt, totalDebt) || other.totalDebt == totalDebt)&&(identical(other.visitCount, visitCount) || other.visitCount == visitCount)&&(identical(other.oldestDebtAt, oldestDebtAt) || other.oldestDebtAt == oldestDebtAt)&&(identical(other.lastPaymentAt, lastPaymentAt) || other.lastPaymentAt == lastPaymentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,patientId,patientName,phone,patientNo,totalDebt,visitCount,oldestDebtAt,lastPaymentAt);

@override
String toString() {
  return 'DebtorRow(patientId: $patientId, patientName: $patientName, phone: $phone, patientNo: $patientNo, totalDebt: $totalDebt, visitCount: $visitCount, oldestDebtAt: $oldestDebtAt, lastPaymentAt: $lastPaymentAt)';
}


}

/// @nodoc
abstract mixin class $DebtorRowCopyWith<$Res>  {
  factory $DebtorRowCopyWith(DebtorRow value, $Res Function(DebtorRow) _then) = _$DebtorRowCopyWithImpl;
@useResult
$Res call({
 String patientId, String patientName, String? phone, String? patientNo, String totalDebt, int visitCount, String oldestDebtAt, String? lastPaymentAt
});




}
/// @nodoc
class _$DebtorRowCopyWithImpl<$Res>
    implements $DebtorRowCopyWith<$Res> {
  _$DebtorRowCopyWithImpl(this._self, this._then);

  final DebtorRow _self;
  final $Res Function(DebtorRow) _then;

/// Create a copy of DebtorRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? patientId = null,Object? patientName = null,Object? phone = freezed,Object? patientNo = freezed,Object? totalDebt = null,Object? visitCount = null,Object? oldestDebtAt = null,Object? lastPaymentAt = freezed,}) {
  return _then(_self.copyWith(
patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,patientNo: freezed == patientNo ? _self.patientNo : patientNo // ignore: cast_nullable_to_non_nullable
as String?,totalDebt: null == totalDebt ? _self.totalDebt : totalDebt // ignore: cast_nullable_to_non_nullable
as String,visitCount: null == visitCount ? _self.visitCount : visitCount // ignore: cast_nullable_to_non_nullable
as int,oldestDebtAt: null == oldestDebtAt ? _self.oldestDebtAt : oldestDebtAt // ignore: cast_nullable_to_non_nullable
as String,lastPaymentAt: freezed == lastPaymentAt ? _self.lastPaymentAt : lastPaymentAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DebtorRow].
extension DebtorRowPatterns on DebtorRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebtorRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebtorRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebtorRow value)  $default,){
final _that = this;
switch (_that) {
case _DebtorRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebtorRow value)?  $default,){
final _that = this;
switch (_that) {
case _DebtorRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String patientId,  String patientName,  String? phone,  String? patientNo,  String totalDebt,  int visitCount,  String oldestDebtAt,  String? lastPaymentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebtorRow() when $default != null:
return $default(_that.patientId,_that.patientName,_that.phone,_that.patientNo,_that.totalDebt,_that.visitCount,_that.oldestDebtAt,_that.lastPaymentAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String patientId,  String patientName,  String? phone,  String? patientNo,  String totalDebt,  int visitCount,  String oldestDebtAt,  String? lastPaymentAt)  $default,) {final _that = this;
switch (_that) {
case _DebtorRow():
return $default(_that.patientId,_that.patientName,_that.phone,_that.patientNo,_that.totalDebt,_that.visitCount,_that.oldestDebtAt,_that.lastPaymentAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String patientId,  String patientName,  String? phone,  String? patientNo,  String totalDebt,  int visitCount,  String oldestDebtAt,  String? lastPaymentAt)?  $default,) {final _that = this;
switch (_that) {
case _DebtorRow() when $default != null:
return $default(_that.patientId,_that.patientName,_that.phone,_that.patientNo,_that.totalDebt,_that.visitCount,_that.oldestDebtAt,_that.lastPaymentAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DebtorRow implements DebtorRow {
  const _DebtorRow({required this.patientId, required this.patientName, this.phone, this.patientNo, required this.totalDebt, required this.visitCount, required this.oldestDebtAt, this.lastPaymentAt});
  factory _DebtorRow.fromJson(Map<String, dynamic> json) => _$DebtorRowFromJson(json);

@override final  String patientId;
@override final  String patientName;
@override final  String? phone;
@override final  String? patientNo;
@override final  String totalDebt;
// decimal string, e.g. "150000.00"
@override final  int visitCount;
@override final  String oldestDebtAt;
// ISO datetime
@override final  String? lastPaymentAt;

/// Create a copy of DebtorRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebtorRowCopyWith<_DebtorRow> get copyWith => __$DebtorRowCopyWithImpl<_DebtorRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebtorRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebtorRow&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.patientNo, patientNo) || other.patientNo == patientNo)&&(identical(other.totalDebt, totalDebt) || other.totalDebt == totalDebt)&&(identical(other.visitCount, visitCount) || other.visitCount == visitCount)&&(identical(other.oldestDebtAt, oldestDebtAt) || other.oldestDebtAt == oldestDebtAt)&&(identical(other.lastPaymentAt, lastPaymentAt) || other.lastPaymentAt == lastPaymentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,patientId,patientName,phone,patientNo,totalDebt,visitCount,oldestDebtAt,lastPaymentAt);

@override
String toString() {
  return 'DebtorRow(patientId: $patientId, patientName: $patientName, phone: $phone, patientNo: $patientNo, totalDebt: $totalDebt, visitCount: $visitCount, oldestDebtAt: $oldestDebtAt, lastPaymentAt: $lastPaymentAt)';
}


}

/// @nodoc
abstract mixin class _$DebtorRowCopyWith<$Res> implements $DebtorRowCopyWith<$Res> {
  factory _$DebtorRowCopyWith(_DebtorRow value, $Res Function(_DebtorRow) _then) = __$DebtorRowCopyWithImpl;
@override @useResult
$Res call({
 String patientId, String patientName, String? phone, String? patientNo, String totalDebt, int visitCount, String oldestDebtAt, String? lastPaymentAt
});




}
/// @nodoc
class __$DebtorRowCopyWithImpl<$Res>
    implements _$DebtorRowCopyWith<$Res> {
  __$DebtorRowCopyWithImpl(this._self, this._then);

  final _DebtorRow _self;
  final $Res Function(_DebtorRow) _then;

/// Create a copy of DebtorRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? patientId = null,Object? patientName = null,Object? phone = freezed,Object? patientNo = freezed,Object? totalDebt = null,Object? visitCount = null,Object? oldestDebtAt = null,Object? lastPaymentAt = freezed,}) {
  return _then(_DebtorRow(
patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,patientNo: freezed == patientNo ? _self.patientNo : patientNo // ignore: cast_nullable_to_non_nullable
as String?,totalDebt: null == totalDebt ? _self.totalDebt : totalDebt // ignore: cast_nullable_to_non_nullable
as String,visitCount: null == visitCount ? _self.visitCount : visitCount // ignore: cast_nullable_to_non_nullable
as int,oldestDebtAt: null == oldestDebtAt ? _self.oldestDebtAt : oldestDebtAt // ignore: cast_nullable_to_non_nullable
as String,lastPaymentAt: freezed == lastPaymentAt ? _self.lastPaymentAt : lastPaymentAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
