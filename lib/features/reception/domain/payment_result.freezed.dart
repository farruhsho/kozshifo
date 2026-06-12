// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentResult {

 ReceptionPayment get payment; String get visitStatus; String get visitBalance; String? get queueTicketNumber;
/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentResultCopyWith<PaymentResult> get copyWith => _$PaymentResultCopyWithImpl<PaymentResult>(this as PaymentResult, _$identity);

  /// Serializes this PaymentResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentResult&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.visitStatus, visitStatus) || other.visitStatus == visitStatus)&&(identical(other.visitBalance, visitBalance) || other.visitBalance == visitBalance)&&(identical(other.queueTicketNumber, queueTicketNumber) || other.queueTicketNumber == queueTicketNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,payment,visitStatus,visitBalance,queueTicketNumber);

@override
String toString() {
  return 'PaymentResult(payment: $payment, visitStatus: $visitStatus, visitBalance: $visitBalance, queueTicketNumber: $queueTicketNumber)';
}


}

/// @nodoc
abstract mixin class $PaymentResultCopyWith<$Res>  {
  factory $PaymentResultCopyWith(PaymentResult value, $Res Function(PaymentResult) _then) = _$PaymentResultCopyWithImpl;
@useResult
$Res call({
 ReceptionPayment payment, String visitStatus, String visitBalance, String? queueTicketNumber
});


$ReceptionPaymentCopyWith<$Res> get payment;

}
/// @nodoc
class _$PaymentResultCopyWithImpl<$Res>
    implements $PaymentResultCopyWith<$Res> {
  _$PaymentResultCopyWithImpl(this._self, this._then);

  final PaymentResult _self;
  final $Res Function(PaymentResult) _then;

/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? payment = null,Object? visitStatus = null,Object? visitBalance = null,Object? queueTicketNumber = freezed,}) {
  return _then(_self.copyWith(
payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as ReceptionPayment,visitStatus: null == visitStatus ? _self.visitStatus : visitStatus // ignore: cast_nullable_to_non_nullable
as String,visitBalance: null == visitBalance ? _self.visitBalance : visitBalance // ignore: cast_nullable_to_non_nullable
as String,queueTicketNumber: freezed == queueTicketNumber ? _self.queueTicketNumber : queueTicketNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReceptionPaymentCopyWith<$Res> get payment {
  
  return $ReceptionPaymentCopyWith<$Res>(_self.payment, (value) {
    return _then(_self.copyWith(payment: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaymentResult].
extension PaymentResultPatterns on PaymentResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentResult value)  $default,){
final _that = this;
switch (_that) {
case _PaymentResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentResult value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReceptionPayment payment,  String visitStatus,  String visitBalance,  String? queueTicketNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentResult() when $default != null:
return $default(_that.payment,_that.visitStatus,_that.visitBalance,_that.queueTicketNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReceptionPayment payment,  String visitStatus,  String visitBalance,  String? queueTicketNumber)  $default,) {final _that = this;
switch (_that) {
case _PaymentResult():
return $default(_that.payment,_that.visitStatus,_that.visitBalance,_that.queueTicketNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReceptionPayment payment,  String visitStatus,  String visitBalance,  String? queueTicketNumber)?  $default,) {final _that = this;
switch (_that) {
case _PaymentResult() when $default != null:
return $default(_that.payment,_that.visitStatus,_that.visitBalance,_that.queueTicketNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentResult implements PaymentResult {
  const _PaymentResult({required this.payment, required this.visitStatus, required this.visitBalance, this.queueTicketNumber});
  factory _PaymentResult.fromJson(Map<String, dynamic> json) => _$PaymentResultFromJson(json);

@override final  ReceptionPayment payment;
@override final  String visitStatus;
@override final  String visitBalance;
@override final  String? queueTicketNumber;

/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentResultCopyWith<_PaymentResult> get copyWith => __$PaymentResultCopyWithImpl<_PaymentResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentResult&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.visitStatus, visitStatus) || other.visitStatus == visitStatus)&&(identical(other.visitBalance, visitBalance) || other.visitBalance == visitBalance)&&(identical(other.queueTicketNumber, queueTicketNumber) || other.queueTicketNumber == queueTicketNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,payment,visitStatus,visitBalance,queueTicketNumber);

@override
String toString() {
  return 'PaymentResult(payment: $payment, visitStatus: $visitStatus, visitBalance: $visitBalance, queueTicketNumber: $queueTicketNumber)';
}


}

/// @nodoc
abstract mixin class _$PaymentResultCopyWith<$Res> implements $PaymentResultCopyWith<$Res> {
  factory _$PaymentResultCopyWith(_PaymentResult value, $Res Function(_PaymentResult) _then) = __$PaymentResultCopyWithImpl;
@override @useResult
$Res call({
 ReceptionPayment payment, String visitStatus, String visitBalance, String? queueTicketNumber
});


@override $ReceptionPaymentCopyWith<$Res> get payment;

}
/// @nodoc
class __$PaymentResultCopyWithImpl<$Res>
    implements _$PaymentResultCopyWith<$Res> {
  __$PaymentResultCopyWithImpl(this._self, this._then);

  final _PaymentResult _self;
  final $Res Function(_PaymentResult) _then;

/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? payment = null,Object? visitStatus = null,Object? visitBalance = null,Object? queueTicketNumber = freezed,}) {
  return _then(_PaymentResult(
payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as ReceptionPayment,visitStatus: null == visitStatus ? _self.visitStatus : visitStatus // ignore: cast_nullable_to_non_nullable
as String,visitBalance: null == visitBalance ? _self.visitBalance : visitBalance // ignore: cast_nullable_to_non_nullable
as String,queueTicketNumber: freezed == queueTicketNumber ? _self.queueTicketNumber : queueTicketNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReceptionPaymentCopyWith<$Res> get payment {
  
  return $ReceptionPaymentCopyWith<$Res>(_self.payment, (value) {
    return _then(_self.copyWith(payment: value));
  });
}
}


/// @nodoc
mixin _$ReceptionPayment {

 String get id; String get receiptNo; String get amount; String get method; String get createdAt;
/// Create a copy of ReceptionPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceptionPaymentCopyWith<ReceptionPayment> get copyWith => _$ReceptionPaymentCopyWithImpl<ReceptionPayment>(this as ReceptionPayment, _$identity);

  /// Serializes this ReceptionPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceptionPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,receiptNo,amount,method,createdAt);

@override
String toString() {
  return 'ReceptionPayment(id: $id, receiptNo: $receiptNo, amount: $amount, method: $method, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ReceptionPaymentCopyWith<$Res>  {
  factory $ReceptionPaymentCopyWith(ReceptionPayment value, $Res Function(ReceptionPayment) _then) = _$ReceptionPaymentCopyWithImpl;
@useResult
$Res call({
 String id, String receiptNo, String amount, String method, String createdAt
});




}
/// @nodoc
class _$ReceptionPaymentCopyWithImpl<$Res>
    implements $ReceptionPaymentCopyWith<$Res> {
  _$ReceptionPaymentCopyWithImpl(this._self, this._then);

  final ReceptionPayment _self;
  final $Res Function(ReceptionPayment) _then;

/// Create a copy of ReceptionPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? receiptNo = null,Object? amount = null,Object? method = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,receiptNo: null == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceptionPayment].
extension ReceptionPaymentPatterns on ReceptionPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceptionPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceptionPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceptionPayment value)  $default,){
final _that = this;
switch (_that) {
case _ReceptionPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceptionPayment value)?  $default,){
final _that = this;
switch (_that) {
case _ReceptionPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String receiptNo,  String amount,  String method,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceptionPayment() when $default != null:
return $default(_that.id,_that.receiptNo,_that.amount,_that.method,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String receiptNo,  String amount,  String method,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _ReceptionPayment():
return $default(_that.id,_that.receiptNo,_that.amount,_that.method,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String receiptNo,  String amount,  String method,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ReceptionPayment() when $default != null:
return $default(_that.id,_that.receiptNo,_that.amount,_that.method,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceptionPayment implements ReceptionPayment {
  const _ReceptionPayment({required this.id, required this.receiptNo, required this.amount, required this.method, required this.createdAt});
  factory _ReceptionPayment.fromJson(Map<String, dynamic> json) => _$ReceptionPaymentFromJson(json);

@override final  String id;
@override final  String receiptNo;
@override final  String amount;
@override final  String method;
@override final  String createdAt;

/// Create a copy of ReceptionPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceptionPaymentCopyWith<_ReceptionPayment> get copyWith => __$ReceptionPaymentCopyWithImpl<_ReceptionPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceptionPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceptionPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,receiptNo,amount,method,createdAt);

@override
String toString() {
  return 'ReceptionPayment(id: $id, receiptNo: $receiptNo, amount: $amount, method: $method, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ReceptionPaymentCopyWith<$Res> implements $ReceptionPaymentCopyWith<$Res> {
  factory _$ReceptionPaymentCopyWith(_ReceptionPayment value, $Res Function(_ReceptionPayment) _then) = __$ReceptionPaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String receiptNo, String amount, String method, String createdAt
});




}
/// @nodoc
class __$ReceptionPaymentCopyWithImpl<$Res>
    implements _$ReceptionPaymentCopyWith<$Res> {
  __$ReceptionPaymentCopyWithImpl(this._self, this._then);

  final _ReceptionPayment _self;
  final $Res Function(_ReceptionPayment) _then;

/// Create a copy of ReceptionPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? receiptNo = null,Object? amount = null,Object? method = null,Object? createdAt = null,}) {
  return _then(_ReceptionPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,receiptNo: null == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
