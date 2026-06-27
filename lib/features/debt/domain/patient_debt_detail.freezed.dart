// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient_debt_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DebtVisitRow {

 String get visitId; String get visitNo; String get openedAt;// ISO datetime
 String get payable;// decimal string
 String get paid;// decimal string
 String get remaining;// decimal string
 String get services; String get flowStatus;
/// Create a copy of DebtVisitRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebtVisitRowCopyWith<DebtVisitRow> get copyWith => _$DebtVisitRowCopyWithImpl<DebtVisitRow>(this as DebtVisitRow, _$identity);

  /// Serializes this DebtVisitRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebtVisitRow&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.payable, payable) || other.payable == payable)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.services, services) || other.services == services)&&(identical(other.flowStatus, flowStatus) || other.flowStatus == flowStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,visitId,visitNo,openedAt,payable,paid,remaining,services,flowStatus);

@override
String toString() {
  return 'DebtVisitRow(visitId: $visitId, visitNo: $visitNo, openedAt: $openedAt, payable: $payable, paid: $paid, remaining: $remaining, services: $services, flowStatus: $flowStatus)';
}


}

/// @nodoc
abstract mixin class $DebtVisitRowCopyWith<$Res>  {
  factory $DebtVisitRowCopyWith(DebtVisitRow value, $Res Function(DebtVisitRow) _then) = _$DebtVisitRowCopyWithImpl;
@useResult
$Res call({
 String visitId, String visitNo, String openedAt, String payable, String paid, String remaining, String services, String flowStatus
});




}
/// @nodoc
class _$DebtVisitRowCopyWithImpl<$Res>
    implements $DebtVisitRowCopyWith<$Res> {
  _$DebtVisitRowCopyWithImpl(this._self, this._then);

  final DebtVisitRow _self;
  final $Res Function(DebtVisitRow) _then;

/// Create a copy of DebtVisitRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? visitId = null,Object? visitNo = null,Object? openedAt = null,Object? payable = null,Object? paid = null,Object? remaining = null,Object? services = null,Object? flowStatus = null,}) {
  return _then(_self.copyWith(
visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String,payable: null == payable ? _self.payable : payable // ignore: cast_nullable_to_non_nullable
as String,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as String,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as String,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as String,flowStatus: null == flowStatus ? _self.flowStatus : flowStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DebtVisitRow].
extension DebtVisitRowPatterns on DebtVisitRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebtVisitRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebtVisitRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebtVisitRow value)  $default,){
final _that = this;
switch (_that) {
case _DebtVisitRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebtVisitRow value)?  $default,){
final _that = this;
switch (_that) {
case _DebtVisitRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String visitId,  String visitNo,  String openedAt,  String payable,  String paid,  String remaining,  String services,  String flowStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebtVisitRow() when $default != null:
return $default(_that.visitId,_that.visitNo,_that.openedAt,_that.payable,_that.paid,_that.remaining,_that.services,_that.flowStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String visitId,  String visitNo,  String openedAt,  String payable,  String paid,  String remaining,  String services,  String flowStatus)  $default,) {final _that = this;
switch (_that) {
case _DebtVisitRow():
return $default(_that.visitId,_that.visitNo,_that.openedAt,_that.payable,_that.paid,_that.remaining,_that.services,_that.flowStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String visitId,  String visitNo,  String openedAt,  String payable,  String paid,  String remaining,  String services,  String flowStatus)?  $default,) {final _that = this;
switch (_that) {
case _DebtVisitRow() when $default != null:
return $default(_that.visitId,_that.visitNo,_that.openedAt,_that.payable,_that.paid,_that.remaining,_that.services,_that.flowStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DebtVisitRow implements DebtVisitRow {
  const _DebtVisitRow({required this.visitId, required this.visitNo, required this.openedAt, required this.payable, required this.paid, required this.remaining, required this.services, required this.flowStatus});
  factory _DebtVisitRow.fromJson(Map<String, dynamic> json) => _$DebtVisitRowFromJson(json);

@override final  String visitId;
@override final  String visitNo;
@override final  String openedAt;
// ISO datetime
@override final  String payable;
// decimal string
@override final  String paid;
// decimal string
@override final  String remaining;
// decimal string
@override final  String services;
@override final  String flowStatus;

/// Create a copy of DebtVisitRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebtVisitRowCopyWith<_DebtVisitRow> get copyWith => __$DebtVisitRowCopyWithImpl<_DebtVisitRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebtVisitRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebtVisitRow&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.payable, payable) || other.payable == payable)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.services, services) || other.services == services)&&(identical(other.flowStatus, flowStatus) || other.flowStatus == flowStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,visitId,visitNo,openedAt,payable,paid,remaining,services,flowStatus);

@override
String toString() {
  return 'DebtVisitRow(visitId: $visitId, visitNo: $visitNo, openedAt: $openedAt, payable: $payable, paid: $paid, remaining: $remaining, services: $services, flowStatus: $flowStatus)';
}


}

/// @nodoc
abstract mixin class _$DebtVisitRowCopyWith<$Res> implements $DebtVisitRowCopyWith<$Res> {
  factory _$DebtVisitRowCopyWith(_DebtVisitRow value, $Res Function(_DebtVisitRow) _then) = __$DebtVisitRowCopyWithImpl;
@override @useResult
$Res call({
 String visitId, String visitNo, String openedAt, String payable, String paid, String remaining, String services, String flowStatus
});




}
/// @nodoc
class __$DebtVisitRowCopyWithImpl<$Res>
    implements _$DebtVisitRowCopyWith<$Res> {
  __$DebtVisitRowCopyWithImpl(this._self, this._then);

  final _DebtVisitRow _self;
  final $Res Function(_DebtVisitRow) _then;

/// Create a copy of DebtVisitRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? visitId = null,Object? visitNo = null,Object? openedAt = null,Object? payable = null,Object? paid = null,Object? remaining = null,Object? services = null,Object? flowStatus = null,}) {
  return _then(_DebtVisitRow(
visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String,payable: null == payable ? _self.payable : payable // ignore: cast_nullable_to_non_nullable
as String,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as String,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as String,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as String,flowStatus: null == flowStatus ? _self.flowStatus : flowStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DebtPaymentRow {

 String get paidAt;// ISO datetime
 String get amount;// decimal string
 String get method;// cash | card | qr | transfer
 String? get cashierName; String? get note; String get visitNo; String get status;
/// Create a copy of DebtPaymentRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebtPaymentRowCopyWith<DebtPaymentRow> get copyWith => _$DebtPaymentRowCopyWithImpl<DebtPaymentRow>(this as DebtPaymentRow, _$identity);

  /// Serializes this DebtPaymentRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebtPaymentRow&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.cashierName, cashierName) || other.cashierName == cashierName)&&(identical(other.note, note) || other.note == note)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paidAt,amount,method,cashierName,note,visitNo,status);

@override
String toString() {
  return 'DebtPaymentRow(paidAt: $paidAt, amount: $amount, method: $method, cashierName: $cashierName, note: $note, visitNo: $visitNo, status: $status)';
}


}

/// @nodoc
abstract mixin class $DebtPaymentRowCopyWith<$Res>  {
  factory $DebtPaymentRowCopyWith(DebtPaymentRow value, $Res Function(DebtPaymentRow) _then) = _$DebtPaymentRowCopyWithImpl;
@useResult
$Res call({
 String paidAt, String amount, String method, String? cashierName, String? note, String visitNo, String status
});




}
/// @nodoc
class _$DebtPaymentRowCopyWithImpl<$Res>
    implements $DebtPaymentRowCopyWith<$Res> {
  _$DebtPaymentRowCopyWithImpl(this._self, this._then);

  final DebtPaymentRow _self;
  final $Res Function(DebtPaymentRow) _then;

/// Create a copy of DebtPaymentRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paidAt = null,Object? amount = null,Object? method = null,Object? cashierName = freezed,Object? note = freezed,Object? visitNo = null,Object? status = null,}) {
  return _then(_self.copyWith(
paidAt: null == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,cashierName: freezed == cashierName ? _self.cashierName : cashierName // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DebtPaymentRow].
extension DebtPaymentRowPatterns on DebtPaymentRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebtPaymentRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebtPaymentRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebtPaymentRow value)  $default,){
final _that = this;
switch (_that) {
case _DebtPaymentRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebtPaymentRow value)?  $default,){
final _that = this;
switch (_that) {
case _DebtPaymentRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String paidAt,  String amount,  String method,  String? cashierName,  String? note,  String visitNo,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebtPaymentRow() when $default != null:
return $default(_that.paidAt,_that.amount,_that.method,_that.cashierName,_that.note,_that.visitNo,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String paidAt,  String amount,  String method,  String? cashierName,  String? note,  String visitNo,  String status)  $default,) {final _that = this;
switch (_that) {
case _DebtPaymentRow():
return $default(_that.paidAt,_that.amount,_that.method,_that.cashierName,_that.note,_that.visitNo,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String paidAt,  String amount,  String method,  String? cashierName,  String? note,  String visitNo,  String status)?  $default,) {final _that = this;
switch (_that) {
case _DebtPaymentRow() when $default != null:
return $default(_that.paidAt,_that.amount,_that.method,_that.cashierName,_that.note,_that.visitNo,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DebtPaymentRow implements DebtPaymentRow {
  const _DebtPaymentRow({required this.paidAt, required this.amount, required this.method, this.cashierName, this.note, required this.visitNo, required this.status});
  factory _DebtPaymentRow.fromJson(Map<String, dynamic> json) => _$DebtPaymentRowFromJson(json);

@override final  String paidAt;
// ISO datetime
@override final  String amount;
// decimal string
@override final  String method;
// cash | card | qr | transfer
@override final  String? cashierName;
@override final  String? note;
@override final  String visitNo;
@override final  String status;

/// Create a copy of DebtPaymentRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebtPaymentRowCopyWith<_DebtPaymentRow> get copyWith => __$DebtPaymentRowCopyWithImpl<_DebtPaymentRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebtPaymentRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebtPaymentRow&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.cashierName, cashierName) || other.cashierName == cashierName)&&(identical(other.note, note) || other.note == note)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paidAt,amount,method,cashierName,note,visitNo,status);

@override
String toString() {
  return 'DebtPaymentRow(paidAt: $paidAt, amount: $amount, method: $method, cashierName: $cashierName, note: $note, visitNo: $visitNo, status: $status)';
}


}

/// @nodoc
abstract mixin class _$DebtPaymentRowCopyWith<$Res> implements $DebtPaymentRowCopyWith<$Res> {
  factory _$DebtPaymentRowCopyWith(_DebtPaymentRow value, $Res Function(_DebtPaymentRow) _then) = __$DebtPaymentRowCopyWithImpl;
@override @useResult
$Res call({
 String paidAt, String amount, String method, String? cashierName, String? note, String visitNo, String status
});




}
/// @nodoc
class __$DebtPaymentRowCopyWithImpl<$Res>
    implements _$DebtPaymentRowCopyWith<$Res> {
  __$DebtPaymentRowCopyWithImpl(this._self, this._then);

  final _DebtPaymentRow _self;
  final $Res Function(_DebtPaymentRow) _then;

/// Create a copy of DebtPaymentRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paidAt = null,Object? amount = null,Object? method = null,Object? cashierName = freezed,Object? note = freezed,Object? visitNo = null,Object? status = null,}) {
  return _then(_DebtPaymentRow(
paidAt: null == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,cashierName: freezed == cashierName ? _self.cashierName : cashierName // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PatientDebtDetail {

 String get patientId; String get patientName; String? get phone; String get totalDebt;// decimal string
 List<DebtVisitRow> get visits; List<DebtPaymentRow> get payments;
/// Create a copy of PatientDebtDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientDebtDetailCopyWith<PatientDebtDetail> get copyWith => _$PatientDebtDetailCopyWithImpl<PatientDebtDetail>(this as PatientDebtDetail, _$identity);

  /// Serializes this PatientDebtDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientDebtDetail&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.totalDebt, totalDebt) || other.totalDebt == totalDebt)&&const DeepCollectionEquality().equals(other.visits, visits)&&const DeepCollectionEquality().equals(other.payments, payments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,patientId,patientName,phone,totalDebt,const DeepCollectionEquality().hash(visits),const DeepCollectionEquality().hash(payments));

@override
String toString() {
  return 'PatientDebtDetail(patientId: $patientId, patientName: $patientName, phone: $phone, totalDebt: $totalDebt, visits: $visits, payments: $payments)';
}


}

/// @nodoc
abstract mixin class $PatientDebtDetailCopyWith<$Res>  {
  factory $PatientDebtDetailCopyWith(PatientDebtDetail value, $Res Function(PatientDebtDetail) _then) = _$PatientDebtDetailCopyWithImpl;
@useResult
$Res call({
 String patientId, String patientName, String? phone, String totalDebt, List<DebtVisitRow> visits, List<DebtPaymentRow> payments
});




}
/// @nodoc
class _$PatientDebtDetailCopyWithImpl<$Res>
    implements $PatientDebtDetailCopyWith<$Res> {
  _$PatientDebtDetailCopyWithImpl(this._self, this._then);

  final PatientDebtDetail _self;
  final $Res Function(PatientDebtDetail) _then;

/// Create a copy of PatientDebtDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? patientId = null,Object? patientName = null,Object? phone = freezed,Object? totalDebt = null,Object? visits = null,Object? payments = null,}) {
  return _then(_self.copyWith(
patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,totalDebt: null == totalDebt ? _self.totalDebt : totalDebt // ignore: cast_nullable_to_non_nullable
as String,visits: null == visits ? _self.visits : visits // ignore: cast_nullable_to_non_nullable
as List<DebtVisitRow>,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<DebtPaymentRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientDebtDetail].
extension PatientDebtDetailPatterns on PatientDebtDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientDebtDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientDebtDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientDebtDetail value)  $default,){
final _that = this;
switch (_that) {
case _PatientDebtDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientDebtDetail value)?  $default,){
final _that = this;
switch (_that) {
case _PatientDebtDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String patientId,  String patientName,  String? phone,  String totalDebt,  List<DebtVisitRow> visits,  List<DebtPaymentRow> payments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientDebtDetail() when $default != null:
return $default(_that.patientId,_that.patientName,_that.phone,_that.totalDebt,_that.visits,_that.payments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String patientId,  String patientName,  String? phone,  String totalDebt,  List<DebtVisitRow> visits,  List<DebtPaymentRow> payments)  $default,) {final _that = this;
switch (_that) {
case _PatientDebtDetail():
return $default(_that.patientId,_that.patientName,_that.phone,_that.totalDebt,_that.visits,_that.payments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String patientId,  String patientName,  String? phone,  String totalDebt,  List<DebtVisitRow> visits,  List<DebtPaymentRow> payments)?  $default,) {final _that = this;
switch (_that) {
case _PatientDebtDetail() when $default != null:
return $default(_that.patientId,_that.patientName,_that.phone,_that.totalDebt,_that.visits,_that.payments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatientDebtDetail implements PatientDebtDetail {
  const _PatientDebtDetail({required this.patientId, required this.patientName, this.phone, required this.totalDebt, required final  List<DebtVisitRow> visits, required final  List<DebtPaymentRow> payments}): _visits = visits,_payments = payments;
  factory _PatientDebtDetail.fromJson(Map<String, dynamic> json) => _$PatientDebtDetailFromJson(json);

@override final  String patientId;
@override final  String patientName;
@override final  String? phone;
@override final  String totalDebt;
// decimal string
 final  List<DebtVisitRow> _visits;
// decimal string
@override List<DebtVisitRow> get visits {
  if (_visits is EqualUnmodifiableListView) return _visits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_visits);
}

 final  List<DebtPaymentRow> _payments;
@override List<DebtPaymentRow> get payments {
  if (_payments is EqualUnmodifiableListView) return _payments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_payments);
}


/// Create a copy of PatientDebtDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientDebtDetailCopyWith<_PatientDebtDetail> get copyWith => __$PatientDebtDetailCopyWithImpl<_PatientDebtDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientDebtDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientDebtDetail&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.totalDebt, totalDebt) || other.totalDebt == totalDebt)&&const DeepCollectionEquality().equals(other._visits, _visits)&&const DeepCollectionEquality().equals(other._payments, _payments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,patientId,patientName,phone,totalDebt,const DeepCollectionEquality().hash(_visits),const DeepCollectionEquality().hash(_payments));

@override
String toString() {
  return 'PatientDebtDetail(patientId: $patientId, patientName: $patientName, phone: $phone, totalDebt: $totalDebt, visits: $visits, payments: $payments)';
}


}

/// @nodoc
abstract mixin class _$PatientDebtDetailCopyWith<$Res> implements $PatientDebtDetailCopyWith<$Res> {
  factory _$PatientDebtDetailCopyWith(_PatientDebtDetail value, $Res Function(_PatientDebtDetail) _then) = __$PatientDebtDetailCopyWithImpl;
@override @useResult
$Res call({
 String patientId, String patientName, String? phone, String totalDebt, List<DebtVisitRow> visits, List<DebtPaymentRow> payments
});




}
/// @nodoc
class __$PatientDebtDetailCopyWithImpl<$Res>
    implements _$PatientDebtDetailCopyWith<$Res> {
  __$PatientDebtDetailCopyWithImpl(this._self, this._then);

  final _PatientDebtDetail _self;
  final $Res Function(_PatientDebtDetail) _then;

/// Create a copy of PatientDebtDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? patientId = null,Object? patientName = null,Object? phone = freezed,Object? totalDebt = null,Object? visits = null,Object? payments = null,}) {
  return _then(_PatientDebtDetail(
patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,totalDebt: null == totalDebt ? _self.totalDebt : totalDebt // ignore: cast_nullable_to_non_nullable
as String,visits: null == visits ? _self._visits : visits // ignore: cast_nullable_to_non_nullable
as List<DebtVisitRow>,payments: null == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<DebtPaymentRow>,
  ));
}


}

// dart format on
