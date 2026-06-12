// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_results.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchPatient {

 String get id; String get mrn; String get fullName; String? get phone;
/// Create a copy of SearchPatient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchPatientCopyWith<SearchPatient> get copyWith => _$SearchPatientCopyWithImpl<SearchPatient>(this as SearchPatient, _$identity);

  /// Serializes this SearchPatient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPatient&&(identical(other.id, id) || other.id == id)&&(identical(other.mrn, mrn) || other.mrn == mrn)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mrn,fullName,phone);

@override
String toString() {
  return 'SearchPatient(id: $id, mrn: $mrn, fullName: $fullName, phone: $phone)';
}


}

/// @nodoc
abstract mixin class $SearchPatientCopyWith<$Res>  {
  factory $SearchPatientCopyWith(SearchPatient value, $Res Function(SearchPatient) _then) = _$SearchPatientCopyWithImpl;
@useResult
$Res call({
 String id, String mrn, String fullName, String? phone
});




}
/// @nodoc
class _$SearchPatientCopyWithImpl<$Res>
    implements $SearchPatientCopyWith<$Res> {
  _$SearchPatientCopyWithImpl(this._self, this._then);

  final SearchPatient _self;
  final $Res Function(SearchPatient) _then;

/// Create a copy of SearchPatient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mrn = null,Object? fullName = null,Object? phone = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mrn: null == mrn ? _self.mrn : mrn // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchPatient].
extension SearchPatientPatterns on SearchPatient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchPatient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchPatient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchPatient value)  $default,){
final _that = this;
switch (_that) {
case _SearchPatient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchPatient value)?  $default,){
final _that = this;
switch (_that) {
case _SearchPatient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String mrn,  String fullName,  String? phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchPatient() when $default != null:
return $default(_that.id,_that.mrn,_that.fullName,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String mrn,  String fullName,  String? phone)  $default,) {final _that = this;
switch (_that) {
case _SearchPatient():
return $default(_that.id,_that.mrn,_that.fullName,_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String mrn,  String fullName,  String? phone)?  $default,) {final _that = this;
switch (_that) {
case _SearchPatient() when $default != null:
return $default(_that.id,_that.mrn,_that.fullName,_that.phone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchPatient implements SearchPatient {
  const _SearchPatient({required this.id, required this.mrn, required this.fullName, this.phone});
  factory _SearchPatient.fromJson(Map<String, dynamic> json) => _$SearchPatientFromJson(json);

@override final  String id;
@override final  String mrn;
@override final  String fullName;
@override final  String? phone;

/// Create a copy of SearchPatient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchPatientCopyWith<_SearchPatient> get copyWith => __$SearchPatientCopyWithImpl<_SearchPatient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchPatientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchPatient&&(identical(other.id, id) || other.id == id)&&(identical(other.mrn, mrn) || other.mrn == mrn)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mrn,fullName,phone);

@override
String toString() {
  return 'SearchPatient(id: $id, mrn: $mrn, fullName: $fullName, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$SearchPatientCopyWith<$Res> implements $SearchPatientCopyWith<$Res> {
  factory _$SearchPatientCopyWith(_SearchPatient value, $Res Function(_SearchPatient) _then) = __$SearchPatientCopyWithImpl;
@override @useResult
$Res call({
 String id, String mrn, String fullName, String? phone
});




}
/// @nodoc
class __$SearchPatientCopyWithImpl<$Res>
    implements _$SearchPatientCopyWith<$Res> {
  __$SearchPatientCopyWithImpl(this._self, this._then);

  final _SearchPatient _self;
  final $Res Function(_SearchPatient) _then;

/// Create a copy of SearchPatient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mrn = null,Object? fullName = null,Object? phone = freezed,}) {
  return _then(_SearchPatient(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mrn: null == mrn ? _self.mrn : mrn // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SearchVisit {

 String get id; String get visitNo; String get patientId; String get patientName; String get flowStatus; String get status;
/// Create a copy of SearchVisit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchVisitCopyWith<SearchVisit> get copyWith => _$SearchVisitCopyWithImpl<SearchVisit>(this as SearchVisit, _$identity);

  /// Serializes this SearchVisit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchVisit&&(identical(other.id, id) || other.id == id)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.flowStatus, flowStatus) || other.flowStatus == flowStatus)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,visitNo,patientId,patientName,flowStatus,status);

@override
String toString() {
  return 'SearchVisit(id: $id, visitNo: $visitNo, patientId: $patientId, patientName: $patientName, flowStatus: $flowStatus, status: $status)';
}


}

/// @nodoc
abstract mixin class $SearchVisitCopyWith<$Res>  {
  factory $SearchVisitCopyWith(SearchVisit value, $Res Function(SearchVisit) _then) = _$SearchVisitCopyWithImpl;
@useResult
$Res call({
 String id, String visitNo, String patientId, String patientName, String flowStatus, String status
});




}
/// @nodoc
class _$SearchVisitCopyWithImpl<$Res>
    implements $SearchVisitCopyWith<$Res> {
  _$SearchVisitCopyWithImpl(this._self, this._then);

  final SearchVisit _self;
  final $Res Function(SearchVisit) _then;

/// Create a copy of SearchVisit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? visitNo = null,Object? patientId = null,Object? patientName = null,Object? flowStatus = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,flowStatus: null == flowStatus ? _self.flowStatus : flowStatus // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchVisit].
extension SearchVisitPatterns on SearchVisit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchVisit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchVisit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchVisit value)  $default,){
final _that = this;
switch (_that) {
case _SearchVisit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchVisit value)?  $default,){
final _that = this;
switch (_that) {
case _SearchVisit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String visitNo,  String patientId,  String patientName,  String flowStatus,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchVisit() when $default != null:
return $default(_that.id,_that.visitNo,_that.patientId,_that.patientName,_that.flowStatus,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String visitNo,  String patientId,  String patientName,  String flowStatus,  String status)  $default,) {final _that = this;
switch (_that) {
case _SearchVisit():
return $default(_that.id,_that.visitNo,_that.patientId,_that.patientName,_that.flowStatus,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String visitNo,  String patientId,  String patientName,  String flowStatus,  String status)?  $default,) {final _that = this;
switch (_that) {
case _SearchVisit() when $default != null:
return $default(_that.id,_that.visitNo,_that.patientId,_that.patientName,_that.flowStatus,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchVisit implements SearchVisit {
  const _SearchVisit({required this.id, required this.visitNo, required this.patientId, required this.patientName, this.flowStatus = 'registered', required this.status});
  factory _SearchVisit.fromJson(Map<String, dynamic> json) => _$SearchVisitFromJson(json);

@override final  String id;
@override final  String visitNo;
@override final  String patientId;
@override final  String patientName;
@override@JsonKey() final  String flowStatus;
@override final  String status;

/// Create a copy of SearchVisit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchVisitCopyWith<_SearchVisit> get copyWith => __$SearchVisitCopyWithImpl<_SearchVisit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchVisitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchVisit&&(identical(other.id, id) || other.id == id)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.flowStatus, flowStatus) || other.flowStatus == flowStatus)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,visitNo,patientId,patientName,flowStatus,status);

@override
String toString() {
  return 'SearchVisit(id: $id, visitNo: $visitNo, patientId: $patientId, patientName: $patientName, flowStatus: $flowStatus, status: $status)';
}


}

/// @nodoc
abstract mixin class _$SearchVisitCopyWith<$Res> implements $SearchVisitCopyWith<$Res> {
  factory _$SearchVisitCopyWith(_SearchVisit value, $Res Function(_SearchVisit) _then) = __$SearchVisitCopyWithImpl;
@override @useResult
$Res call({
 String id, String visitNo, String patientId, String patientName, String flowStatus, String status
});




}
/// @nodoc
class __$SearchVisitCopyWithImpl<$Res>
    implements _$SearchVisitCopyWith<$Res> {
  __$SearchVisitCopyWithImpl(this._self, this._then);

  final _SearchVisit _self;
  final $Res Function(_SearchVisit) _then;

/// Create a copy of SearchVisit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? visitNo = null,Object? patientId = null,Object? patientName = null,Object? flowStatus = null,Object? status = null,}) {
  return _then(_SearchVisit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,flowStatus: null == flowStatus ? _self.flowStatus : flowStatus // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SearchReceipt {

 String get paymentId; String get receiptNo; String get amount; String? get visitId; String? get patientId;
/// Create a copy of SearchReceipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchReceiptCopyWith<SearchReceipt> get copyWith => _$SearchReceiptCopyWithImpl<SearchReceipt>(this as SearchReceipt, _$identity);

  /// Serializes this SearchReceipt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchReceipt&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientId, patientId) || other.patientId == patientId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paymentId,receiptNo,amount,visitId,patientId);

@override
String toString() {
  return 'SearchReceipt(paymentId: $paymentId, receiptNo: $receiptNo, amount: $amount, visitId: $visitId, patientId: $patientId)';
}


}

/// @nodoc
abstract mixin class $SearchReceiptCopyWith<$Res>  {
  factory $SearchReceiptCopyWith(SearchReceipt value, $Res Function(SearchReceipt) _then) = _$SearchReceiptCopyWithImpl;
@useResult
$Res call({
 String paymentId, String receiptNo, String amount, String? visitId, String? patientId
});




}
/// @nodoc
class _$SearchReceiptCopyWithImpl<$Res>
    implements $SearchReceiptCopyWith<$Res> {
  _$SearchReceiptCopyWithImpl(this._self, this._then);

  final SearchReceipt _self;
  final $Res Function(SearchReceipt) _then;

/// Create a copy of SearchReceipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paymentId = null,Object? receiptNo = null,Object? amount = null,Object? visitId = freezed,Object? patientId = freezed,}) {
  return _then(_self.copyWith(
paymentId: null == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String,receiptNo: null == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,visitId: freezed == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String?,patientId: freezed == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchReceipt].
extension SearchReceiptPatterns on SearchReceipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchReceipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchReceipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchReceipt value)  $default,){
final _that = this;
switch (_that) {
case _SearchReceipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchReceipt value)?  $default,){
final _that = this;
switch (_that) {
case _SearchReceipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String paymentId,  String receiptNo,  String amount,  String? visitId,  String? patientId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchReceipt() when $default != null:
return $default(_that.paymentId,_that.receiptNo,_that.amount,_that.visitId,_that.patientId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String paymentId,  String receiptNo,  String amount,  String? visitId,  String? patientId)  $default,) {final _that = this;
switch (_that) {
case _SearchReceipt():
return $default(_that.paymentId,_that.receiptNo,_that.amount,_that.visitId,_that.patientId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String paymentId,  String receiptNo,  String amount,  String? visitId,  String? patientId)?  $default,) {final _that = this;
switch (_that) {
case _SearchReceipt() when $default != null:
return $default(_that.paymentId,_that.receiptNo,_that.amount,_that.visitId,_that.patientId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchReceipt implements SearchReceipt {
  const _SearchReceipt({required this.paymentId, required this.receiptNo, required this.amount, this.visitId, this.patientId});
  factory _SearchReceipt.fromJson(Map<String, dynamic> json) => _$SearchReceiptFromJson(json);

@override final  String paymentId;
@override final  String receiptNo;
@override final  String amount;
@override final  String? visitId;
@override final  String? patientId;

/// Create a copy of SearchReceipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchReceiptCopyWith<_SearchReceipt> get copyWith => __$SearchReceiptCopyWithImpl<_SearchReceipt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchReceiptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchReceipt&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientId, patientId) || other.patientId == patientId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paymentId,receiptNo,amount,visitId,patientId);

@override
String toString() {
  return 'SearchReceipt(paymentId: $paymentId, receiptNo: $receiptNo, amount: $amount, visitId: $visitId, patientId: $patientId)';
}


}

/// @nodoc
abstract mixin class _$SearchReceiptCopyWith<$Res> implements $SearchReceiptCopyWith<$Res> {
  factory _$SearchReceiptCopyWith(_SearchReceipt value, $Res Function(_SearchReceipt) _then) = __$SearchReceiptCopyWithImpl;
@override @useResult
$Res call({
 String paymentId, String receiptNo, String amount, String? visitId, String? patientId
});




}
/// @nodoc
class __$SearchReceiptCopyWithImpl<$Res>
    implements _$SearchReceiptCopyWith<$Res> {
  __$SearchReceiptCopyWithImpl(this._self, this._then);

  final _SearchReceipt _self;
  final $Res Function(_SearchReceipt) _then;

/// Create a copy of SearchReceipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paymentId = null,Object? receiptNo = null,Object? amount = null,Object? visitId = freezed,Object? patientId = freezed,}) {
  return _then(_SearchReceipt(
paymentId: null == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String,receiptNo: null == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,visitId: freezed == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String?,patientId: freezed == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SearchResults {

 List<SearchPatient> get patients; List<SearchVisit> get visits; List<SearchReceipt> get receipts;
/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultsCopyWith<SearchResults> get copyWith => _$SearchResultsCopyWithImpl<SearchResults>(this as SearchResults, _$identity);

  /// Serializes this SearchResults to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResults&&const DeepCollectionEquality().equals(other.patients, patients)&&const DeepCollectionEquality().equals(other.visits, visits)&&const DeepCollectionEquality().equals(other.receipts, receipts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(patients),const DeepCollectionEquality().hash(visits),const DeepCollectionEquality().hash(receipts));

@override
String toString() {
  return 'SearchResults(patients: $patients, visits: $visits, receipts: $receipts)';
}


}

/// @nodoc
abstract mixin class $SearchResultsCopyWith<$Res>  {
  factory $SearchResultsCopyWith(SearchResults value, $Res Function(SearchResults) _then) = _$SearchResultsCopyWithImpl;
@useResult
$Res call({
 List<SearchPatient> patients, List<SearchVisit> visits, List<SearchReceipt> receipts
});




}
/// @nodoc
class _$SearchResultsCopyWithImpl<$Res>
    implements $SearchResultsCopyWith<$Res> {
  _$SearchResultsCopyWithImpl(this._self, this._then);

  final SearchResults _self;
  final $Res Function(SearchResults) _then;

/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? patients = null,Object? visits = null,Object? receipts = null,}) {
  return _then(_self.copyWith(
patients: null == patients ? _self.patients : patients // ignore: cast_nullable_to_non_nullable
as List<SearchPatient>,visits: null == visits ? _self.visits : visits // ignore: cast_nullable_to_non_nullable
as List<SearchVisit>,receipts: null == receipts ? _self.receipts : receipts // ignore: cast_nullable_to_non_nullable
as List<SearchReceipt>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResults].
extension SearchResultsPatterns on SearchResults {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResults value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResults() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResults value)  $default,){
final _that = this;
switch (_that) {
case _SearchResults():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResults value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResults() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchPatient> patients,  List<SearchVisit> visits,  List<SearchReceipt> receipts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResults() when $default != null:
return $default(_that.patients,_that.visits,_that.receipts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchPatient> patients,  List<SearchVisit> visits,  List<SearchReceipt> receipts)  $default,) {final _that = this;
switch (_that) {
case _SearchResults():
return $default(_that.patients,_that.visits,_that.receipts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchPatient> patients,  List<SearchVisit> visits,  List<SearchReceipt> receipts)?  $default,) {final _that = this;
switch (_that) {
case _SearchResults() when $default != null:
return $default(_that.patients,_that.visits,_that.receipts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchResults extends SearchResults {
  const _SearchResults({final  List<SearchPatient> patients = const <SearchPatient>[], final  List<SearchVisit> visits = const <SearchVisit>[], final  List<SearchReceipt> receipts = const <SearchReceipt>[]}): _patients = patients,_visits = visits,_receipts = receipts,super._();
  factory _SearchResults.fromJson(Map<String, dynamic> json) => _$SearchResultsFromJson(json);

 final  List<SearchPatient> _patients;
@override@JsonKey() List<SearchPatient> get patients {
  if (_patients is EqualUnmodifiableListView) return _patients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_patients);
}

 final  List<SearchVisit> _visits;
@override@JsonKey() List<SearchVisit> get visits {
  if (_visits is EqualUnmodifiableListView) return _visits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_visits);
}

 final  List<SearchReceipt> _receipts;
@override@JsonKey() List<SearchReceipt> get receipts {
  if (_receipts is EqualUnmodifiableListView) return _receipts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_receipts);
}


/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultsCopyWith<_SearchResults> get copyWith => __$SearchResultsCopyWithImpl<_SearchResults>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchResultsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResults&&const DeepCollectionEquality().equals(other._patients, _patients)&&const DeepCollectionEquality().equals(other._visits, _visits)&&const DeepCollectionEquality().equals(other._receipts, _receipts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_patients),const DeepCollectionEquality().hash(_visits),const DeepCollectionEquality().hash(_receipts));

@override
String toString() {
  return 'SearchResults(patients: $patients, visits: $visits, receipts: $receipts)';
}


}

/// @nodoc
abstract mixin class _$SearchResultsCopyWith<$Res> implements $SearchResultsCopyWith<$Res> {
  factory _$SearchResultsCopyWith(_SearchResults value, $Res Function(_SearchResults) _then) = __$SearchResultsCopyWithImpl;
@override @useResult
$Res call({
 List<SearchPatient> patients, List<SearchVisit> visits, List<SearchReceipt> receipts
});




}
/// @nodoc
class __$SearchResultsCopyWithImpl<$Res>
    implements _$SearchResultsCopyWith<$Res> {
  __$SearchResultsCopyWithImpl(this._self, this._then);

  final _SearchResults _self;
  final $Res Function(_SearchResults) _then;

/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? patients = null,Object? visits = null,Object? receipts = null,}) {
  return _then(_SearchResults(
patients: null == patients ? _self._patients : patients // ignore: cast_nullable_to_non_nullable
as List<SearchPatient>,visits: null == visits ? _self._visits : visits // ignore: cast_nullable_to_non_nullable
as List<SearchVisit>,receipts: null == receipts ? _self._receipts : receipts // ignore: cast_nullable_to_non_nullable
as List<SearchReceipt>,
  ));
}


}

// dart format on
