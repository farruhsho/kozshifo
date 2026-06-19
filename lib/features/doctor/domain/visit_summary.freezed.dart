// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'visit_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VisitSummary {

 String get id; String get visitNo; String get status; String get flowStatus; String get openedAt; String? get branchId;// ── Enrichment for the «История визитов» panel ──────────────────────────
 String get visitType; String? get closedAt;// Money is a decimal string on the client (e.g. "150000.00"); never float.
 String get totalAmount; String get paidAmount; String get discountValue; String get payable; String get balance; String? get discountReason; int get priority; List<VisitItemSummary> get items;// ── Clinical context («История посещений»): врач/кабинет/диагнозы/лечение ──
 String? get doctorName; String? get doctorCabinet; List<String> get diagnoses; List<String> get treatments;
/// Create a copy of VisitSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisitSummaryCopyWith<VisitSummary> get copyWith => _$VisitSummaryCopyWithImpl<VisitSummary>(this as VisitSummary, _$identity);

  /// Serializes this VisitSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisitSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.flowStatus, flowStatus) || other.flowStatus == flowStatus)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.visitType, visitType) || other.visitType == visitType)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.discountValue, discountValue) || other.discountValue == discountValue)&&(identical(other.payable, payable) || other.payable == payable)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.discountReason, discountReason) || other.discountReason == discountReason)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.doctorName, doctorName) || other.doctorName == doctorName)&&(identical(other.doctorCabinet, doctorCabinet) || other.doctorCabinet == doctorCabinet)&&const DeepCollectionEquality().equals(other.diagnoses, diagnoses)&&const DeepCollectionEquality().equals(other.treatments, treatments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,visitNo,status,flowStatus,openedAt,branchId,visitType,closedAt,totalAmount,paidAmount,discountValue,payable,balance,discountReason,priority,const DeepCollectionEquality().hash(items),doctorName,doctorCabinet,const DeepCollectionEquality().hash(diagnoses),const DeepCollectionEquality().hash(treatments)]);

@override
String toString() {
  return 'VisitSummary(id: $id, visitNo: $visitNo, status: $status, flowStatus: $flowStatus, openedAt: $openedAt, branchId: $branchId, visitType: $visitType, closedAt: $closedAt, totalAmount: $totalAmount, paidAmount: $paidAmount, discountValue: $discountValue, payable: $payable, balance: $balance, discountReason: $discountReason, priority: $priority, items: $items, doctorName: $doctorName, doctorCabinet: $doctorCabinet, diagnoses: $diagnoses, treatments: $treatments)';
}


}

/// @nodoc
abstract mixin class $VisitSummaryCopyWith<$Res>  {
  factory $VisitSummaryCopyWith(VisitSummary value, $Res Function(VisitSummary) _then) = _$VisitSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String visitNo, String status, String flowStatus, String openedAt, String? branchId, String visitType, String? closedAt, String totalAmount, String paidAmount, String discountValue, String payable, String balance, String? discountReason, int priority, List<VisitItemSummary> items, String? doctorName, String? doctorCabinet, List<String> diagnoses, List<String> treatments
});




}
/// @nodoc
class _$VisitSummaryCopyWithImpl<$Res>
    implements $VisitSummaryCopyWith<$Res> {
  _$VisitSummaryCopyWithImpl(this._self, this._then);

  final VisitSummary _self;
  final $Res Function(VisitSummary) _then;

/// Create a copy of VisitSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? visitNo = null,Object? status = null,Object? flowStatus = null,Object? openedAt = null,Object? branchId = freezed,Object? visitType = null,Object? closedAt = freezed,Object? totalAmount = null,Object? paidAmount = null,Object? discountValue = null,Object? payable = null,Object? balance = null,Object? discountReason = freezed,Object? priority = null,Object? items = null,Object? doctorName = freezed,Object? doctorCabinet = freezed,Object? diagnoses = null,Object? treatments = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,flowStatus: null == flowStatus ? _self.flowStatus : flowStatus // ignore: cast_nullable_to_non_nullable
as String,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,visitType: null == visitType ? _self.visitType : visitType // ignore: cast_nullable_to_non_nullable
as String,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String,discountValue: null == discountValue ? _self.discountValue : discountValue // ignore: cast_nullable_to_non_nullable
as String,payable: null == payable ? _self.payable : payable // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String,discountReason: freezed == discountReason ? _self.discountReason : discountReason // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<VisitItemSummary>,doctorName: freezed == doctorName ? _self.doctorName : doctorName // ignore: cast_nullable_to_non_nullable
as String?,doctorCabinet: freezed == doctorCabinet ? _self.doctorCabinet : doctorCabinet // ignore: cast_nullable_to_non_nullable
as String?,diagnoses: null == diagnoses ? _self.diagnoses : diagnoses // ignore: cast_nullable_to_non_nullable
as List<String>,treatments: null == treatments ? _self.treatments : treatments // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [VisitSummary].
extension VisitSummaryPatterns on VisitSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisitSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisitSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisitSummary value)  $default,){
final _that = this;
switch (_that) {
case _VisitSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisitSummary value)?  $default,){
final _that = this;
switch (_that) {
case _VisitSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String visitNo,  String status,  String flowStatus,  String openedAt,  String? branchId,  String visitType,  String? closedAt,  String totalAmount,  String paidAmount,  String discountValue,  String payable,  String balance,  String? discountReason,  int priority,  List<VisitItemSummary> items,  String? doctorName,  String? doctorCabinet,  List<String> diagnoses,  List<String> treatments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisitSummary() when $default != null:
return $default(_that.id,_that.visitNo,_that.status,_that.flowStatus,_that.openedAt,_that.branchId,_that.visitType,_that.closedAt,_that.totalAmount,_that.paidAmount,_that.discountValue,_that.payable,_that.balance,_that.discountReason,_that.priority,_that.items,_that.doctorName,_that.doctorCabinet,_that.diagnoses,_that.treatments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String visitNo,  String status,  String flowStatus,  String openedAt,  String? branchId,  String visitType,  String? closedAt,  String totalAmount,  String paidAmount,  String discountValue,  String payable,  String balance,  String? discountReason,  int priority,  List<VisitItemSummary> items,  String? doctorName,  String? doctorCabinet,  List<String> diagnoses,  List<String> treatments)  $default,) {final _that = this;
switch (_that) {
case _VisitSummary():
return $default(_that.id,_that.visitNo,_that.status,_that.flowStatus,_that.openedAt,_that.branchId,_that.visitType,_that.closedAt,_that.totalAmount,_that.paidAmount,_that.discountValue,_that.payable,_that.balance,_that.discountReason,_that.priority,_that.items,_that.doctorName,_that.doctorCabinet,_that.diagnoses,_that.treatments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String visitNo,  String status,  String flowStatus,  String openedAt,  String? branchId,  String visitType,  String? closedAt,  String totalAmount,  String paidAmount,  String discountValue,  String payable,  String balance,  String? discountReason,  int priority,  List<VisitItemSummary> items,  String? doctorName,  String? doctorCabinet,  List<String> diagnoses,  List<String> treatments)?  $default,) {final _that = this;
switch (_that) {
case _VisitSummary() when $default != null:
return $default(_that.id,_that.visitNo,_that.status,_that.flowStatus,_that.openedAt,_that.branchId,_that.visitType,_that.closedAt,_that.totalAmount,_that.paidAmount,_that.discountValue,_that.payable,_that.balance,_that.discountReason,_that.priority,_that.items,_that.doctorName,_that.doctorCabinet,_that.diagnoses,_that.treatments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VisitSummary extends VisitSummary {
  const _VisitSummary({required this.id, required this.visitNo, required this.status, this.flowStatus = 'registered', required this.openedAt, this.branchId, this.visitType = 'consultation', this.closedAt, this.totalAmount = '0', this.paidAmount = '0', this.discountValue = '0', this.payable = '0', this.balance = '0', this.discountReason, this.priority = 0, final  List<VisitItemSummary> items = const <VisitItemSummary>[], this.doctorName, this.doctorCabinet, final  List<String> diagnoses = const <String>[], final  List<String> treatments = const <String>[]}): _items = items,_diagnoses = diagnoses,_treatments = treatments,super._();
  factory _VisitSummary.fromJson(Map<String, dynamic> json) => _$VisitSummaryFromJson(json);

@override final  String id;
@override final  String visitNo;
@override final  String status;
@override@JsonKey() final  String flowStatus;
@override final  String openedAt;
@override final  String? branchId;
// ── Enrichment for the «История визитов» panel ──────────────────────────
@override@JsonKey() final  String visitType;
@override final  String? closedAt;
// Money is a decimal string on the client (e.g. "150000.00"); never float.
@override@JsonKey() final  String totalAmount;
@override@JsonKey() final  String paidAmount;
@override@JsonKey() final  String discountValue;
@override@JsonKey() final  String payable;
@override@JsonKey() final  String balance;
@override final  String? discountReason;
@override@JsonKey() final  int priority;
 final  List<VisitItemSummary> _items;
@override@JsonKey() List<VisitItemSummary> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

// ── Clinical context («История посещений»): врач/кабинет/диагнозы/лечение ──
@override final  String? doctorName;
@override final  String? doctorCabinet;
 final  List<String> _diagnoses;
@override@JsonKey() List<String> get diagnoses {
  if (_diagnoses is EqualUnmodifiableListView) return _diagnoses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnoses);
}

 final  List<String> _treatments;
@override@JsonKey() List<String> get treatments {
  if (_treatments is EqualUnmodifiableListView) return _treatments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_treatments);
}


/// Create a copy of VisitSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisitSummaryCopyWith<_VisitSummary> get copyWith => __$VisitSummaryCopyWithImpl<_VisitSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VisitSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisitSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.flowStatus, flowStatus) || other.flowStatus == flowStatus)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.visitType, visitType) || other.visitType == visitType)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.discountValue, discountValue) || other.discountValue == discountValue)&&(identical(other.payable, payable) || other.payable == payable)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.discountReason, discountReason) || other.discountReason == discountReason)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.doctorName, doctorName) || other.doctorName == doctorName)&&(identical(other.doctorCabinet, doctorCabinet) || other.doctorCabinet == doctorCabinet)&&const DeepCollectionEquality().equals(other._diagnoses, _diagnoses)&&const DeepCollectionEquality().equals(other._treatments, _treatments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,visitNo,status,flowStatus,openedAt,branchId,visitType,closedAt,totalAmount,paidAmount,discountValue,payable,balance,discountReason,priority,const DeepCollectionEquality().hash(_items),doctorName,doctorCabinet,const DeepCollectionEquality().hash(_diagnoses),const DeepCollectionEquality().hash(_treatments)]);

@override
String toString() {
  return 'VisitSummary(id: $id, visitNo: $visitNo, status: $status, flowStatus: $flowStatus, openedAt: $openedAt, branchId: $branchId, visitType: $visitType, closedAt: $closedAt, totalAmount: $totalAmount, paidAmount: $paidAmount, discountValue: $discountValue, payable: $payable, balance: $balance, discountReason: $discountReason, priority: $priority, items: $items, doctorName: $doctorName, doctorCabinet: $doctorCabinet, diagnoses: $diagnoses, treatments: $treatments)';
}


}

/// @nodoc
abstract mixin class _$VisitSummaryCopyWith<$Res> implements $VisitSummaryCopyWith<$Res> {
  factory _$VisitSummaryCopyWith(_VisitSummary value, $Res Function(_VisitSummary) _then) = __$VisitSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String visitNo, String status, String flowStatus, String openedAt, String? branchId, String visitType, String? closedAt, String totalAmount, String paidAmount, String discountValue, String payable, String balance, String? discountReason, int priority, List<VisitItemSummary> items, String? doctorName, String? doctorCabinet, List<String> diagnoses, List<String> treatments
});




}
/// @nodoc
class __$VisitSummaryCopyWithImpl<$Res>
    implements _$VisitSummaryCopyWith<$Res> {
  __$VisitSummaryCopyWithImpl(this._self, this._then);

  final _VisitSummary _self;
  final $Res Function(_VisitSummary) _then;

/// Create a copy of VisitSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? visitNo = null,Object? status = null,Object? flowStatus = null,Object? openedAt = null,Object? branchId = freezed,Object? visitType = null,Object? closedAt = freezed,Object? totalAmount = null,Object? paidAmount = null,Object? discountValue = null,Object? payable = null,Object? balance = null,Object? discountReason = freezed,Object? priority = null,Object? items = null,Object? doctorName = freezed,Object? doctorCabinet = freezed,Object? diagnoses = null,Object? treatments = null,}) {
  return _then(_VisitSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,flowStatus: null == flowStatus ? _self.flowStatus : flowStatus // ignore: cast_nullable_to_non_nullable
as String,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,visitType: null == visitType ? _self.visitType : visitType // ignore: cast_nullable_to_non_nullable
as String,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String,discountValue: null == discountValue ? _self.discountValue : discountValue // ignore: cast_nullable_to_non_nullable
as String,payable: null == payable ? _self.payable : payable // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String,discountReason: freezed == discountReason ? _self.discountReason : discountReason // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<VisitItemSummary>,doctorName: freezed == doctorName ? _self.doctorName : doctorName // ignore: cast_nullable_to_non_nullable
as String?,doctorCabinet: freezed == doctorCabinet ? _self.doctorCabinet : doctorCabinet // ignore: cast_nullable_to_non_nullable
as String?,diagnoses: null == diagnoses ? _self._diagnoses : diagnoses // ignore: cast_nullable_to_non_nullable
as List<String>,treatments: null == treatments ? _self._treatments : treatments // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$VisitItemSummary {

 String get serviceName; int get quantity; String get total;
/// Create a copy of VisitItemSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisitItemSummaryCopyWith<VisitItemSummary> get copyWith => _$VisitItemSummaryCopyWithImpl<VisitItemSummary>(this as VisitItemSummary, _$identity);

  /// Serializes this VisitItemSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisitItemSummary&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceName,quantity,total);

@override
String toString() {
  return 'VisitItemSummary(serviceName: $serviceName, quantity: $quantity, total: $total)';
}


}

/// @nodoc
abstract mixin class $VisitItemSummaryCopyWith<$Res>  {
  factory $VisitItemSummaryCopyWith(VisitItemSummary value, $Res Function(VisitItemSummary) _then) = _$VisitItemSummaryCopyWithImpl;
@useResult
$Res call({
 String serviceName, int quantity, String total
});




}
/// @nodoc
class _$VisitItemSummaryCopyWithImpl<$Res>
    implements $VisitItemSummaryCopyWith<$Res> {
  _$VisitItemSummaryCopyWithImpl(this._self, this._then);

  final VisitItemSummary _self;
  final $Res Function(VisitItemSummary) _then;

/// Create a copy of VisitItemSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serviceName = null,Object? quantity = null,Object? total = null,}) {
  return _then(_self.copyWith(
serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VisitItemSummary].
extension VisitItemSummaryPatterns on VisitItemSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisitItemSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisitItemSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisitItemSummary value)  $default,){
final _that = this;
switch (_that) {
case _VisitItemSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisitItemSummary value)?  $default,){
final _that = this;
switch (_that) {
case _VisitItemSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serviceName,  int quantity,  String total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisitItemSummary() when $default != null:
return $default(_that.serviceName,_that.quantity,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serviceName,  int quantity,  String total)  $default,) {final _that = this;
switch (_that) {
case _VisitItemSummary():
return $default(_that.serviceName,_that.quantity,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serviceName,  int quantity,  String total)?  $default,) {final _that = this;
switch (_that) {
case _VisitItemSummary() when $default != null:
return $default(_that.serviceName,_that.quantity,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VisitItemSummary implements VisitItemSummary {
  const _VisitItemSummary({required this.serviceName, this.quantity = 1, this.total = '0'});
  factory _VisitItemSummary.fromJson(Map<String, dynamic> json) => _$VisitItemSummaryFromJson(json);

@override final  String serviceName;
@override@JsonKey() final  int quantity;
@override@JsonKey() final  String total;

/// Create a copy of VisitItemSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisitItemSummaryCopyWith<_VisitItemSummary> get copyWith => __$VisitItemSummaryCopyWithImpl<_VisitItemSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VisitItemSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisitItemSummary&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceName,quantity,total);

@override
String toString() {
  return 'VisitItemSummary(serviceName: $serviceName, quantity: $quantity, total: $total)';
}


}

/// @nodoc
abstract mixin class _$VisitItemSummaryCopyWith<$Res> implements $VisitItemSummaryCopyWith<$Res> {
  factory _$VisitItemSummaryCopyWith(_VisitItemSummary value, $Res Function(_VisitItemSummary) _then) = __$VisitItemSummaryCopyWithImpl;
@override @useResult
$Res call({
 String serviceName, int quantity, String total
});




}
/// @nodoc
class __$VisitItemSummaryCopyWithImpl<$Res>
    implements _$VisitItemSummaryCopyWith<$Res> {
  __$VisitItemSummaryCopyWithImpl(this._self, this._then);

  final _VisitItemSummary _self;
  final $Res Function(_VisitItemSummary) _then;

/// Create a copy of VisitItemSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serviceName = null,Object? quantity = null,Object? total = null,}) {
  return _then(_VisitItemSummary(
serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
