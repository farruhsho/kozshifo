// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reception_visit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReceptionVisit {

 String get id; String get visitNo; String get status; String get totalAmount; String get paidAmount; String get balance; List<ReceptionVisitItem> get items;
/// Create a copy of ReceptionVisit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceptionVisitCopyWith<ReceptionVisit> get copyWith => _$ReceptionVisitCopyWithImpl<ReceptionVisit>(this as ReceptionVisit, _$identity);

  /// Serializes this ReceptionVisit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceptionVisit&&(identical(other.id, id) || other.id == id)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.balance, balance) || other.balance == balance)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,visitNo,status,totalAmount,paidAmount,balance,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'ReceptionVisit(id: $id, visitNo: $visitNo, status: $status, totalAmount: $totalAmount, paidAmount: $paidAmount, balance: $balance, items: $items)';
}


}

/// @nodoc
abstract mixin class $ReceptionVisitCopyWith<$Res>  {
  factory $ReceptionVisitCopyWith(ReceptionVisit value, $Res Function(ReceptionVisit) _then) = _$ReceptionVisitCopyWithImpl;
@useResult
$Res call({
 String id, String visitNo, String status, String totalAmount, String paidAmount, String balance, List<ReceptionVisitItem> items
});




}
/// @nodoc
class _$ReceptionVisitCopyWithImpl<$Res>
    implements $ReceptionVisitCopyWith<$Res> {
  _$ReceptionVisitCopyWithImpl(this._self, this._then);

  final ReceptionVisit _self;
  final $Res Function(ReceptionVisit) _then;

/// Create a copy of ReceptionVisit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? visitNo = null,Object? status = null,Object? totalAmount = null,Object? paidAmount = null,Object? balance = null,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ReceptionVisitItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceptionVisit].
extension ReceptionVisitPatterns on ReceptionVisit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceptionVisit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceptionVisit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceptionVisit value)  $default,){
final _that = this;
switch (_that) {
case _ReceptionVisit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceptionVisit value)?  $default,){
final _that = this;
switch (_that) {
case _ReceptionVisit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String visitNo,  String status,  String totalAmount,  String paidAmount,  String balance,  List<ReceptionVisitItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceptionVisit() when $default != null:
return $default(_that.id,_that.visitNo,_that.status,_that.totalAmount,_that.paidAmount,_that.balance,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String visitNo,  String status,  String totalAmount,  String paidAmount,  String balance,  List<ReceptionVisitItem> items)  $default,) {final _that = this;
switch (_that) {
case _ReceptionVisit():
return $default(_that.id,_that.visitNo,_that.status,_that.totalAmount,_that.paidAmount,_that.balance,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String visitNo,  String status,  String totalAmount,  String paidAmount,  String balance,  List<ReceptionVisitItem> items)?  $default,) {final _that = this;
switch (_that) {
case _ReceptionVisit() when $default != null:
return $default(_that.id,_that.visitNo,_that.status,_that.totalAmount,_that.paidAmount,_that.balance,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceptionVisit implements ReceptionVisit {
  const _ReceptionVisit({required this.id, required this.visitNo, required this.status, required this.totalAmount, required this.paidAmount, required this.balance, final  List<ReceptionVisitItem> items = const <ReceptionVisitItem>[]}): _items = items;
  factory _ReceptionVisit.fromJson(Map<String, dynamic> json) => _$ReceptionVisitFromJson(json);

@override final  String id;
@override final  String visitNo;
@override final  String status;
@override final  String totalAmount;
@override final  String paidAmount;
@override final  String balance;
 final  List<ReceptionVisitItem> _items;
@override@JsonKey() List<ReceptionVisitItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ReceptionVisit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceptionVisitCopyWith<_ReceptionVisit> get copyWith => __$ReceptionVisitCopyWithImpl<_ReceptionVisit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceptionVisitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceptionVisit&&(identical(other.id, id) || other.id == id)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.balance, balance) || other.balance == balance)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,visitNo,status,totalAmount,paidAmount,balance,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'ReceptionVisit(id: $id, visitNo: $visitNo, status: $status, totalAmount: $totalAmount, paidAmount: $paidAmount, balance: $balance, items: $items)';
}


}

/// @nodoc
abstract mixin class _$ReceptionVisitCopyWith<$Res> implements $ReceptionVisitCopyWith<$Res> {
  factory _$ReceptionVisitCopyWith(_ReceptionVisit value, $Res Function(_ReceptionVisit) _then) = __$ReceptionVisitCopyWithImpl;
@override @useResult
$Res call({
 String id, String visitNo, String status, String totalAmount, String paidAmount, String balance, List<ReceptionVisitItem> items
});




}
/// @nodoc
class __$ReceptionVisitCopyWithImpl<$Res>
    implements _$ReceptionVisitCopyWith<$Res> {
  __$ReceptionVisitCopyWithImpl(this._self, this._then);

  final _ReceptionVisit _self;
  final $Res Function(_ReceptionVisit) _then;

/// Create a copy of ReceptionVisit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? visitNo = null,Object? status = null,Object? totalAmount = null,Object? paidAmount = null,Object? balance = null,Object? items = null,}) {
  return _then(_ReceptionVisit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ReceptionVisitItem>,
  ));
}


}


/// @nodoc
mixin _$ReceptionVisitItem {

 String get id; String get serviceName; String get unitPrice; int get quantity; String get total; String get status;
/// Create a copy of ReceptionVisitItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceptionVisitItemCopyWith<ReceptionVisitItem> get copyWith => _$ReceptionVisitItemCopyWithImpl<ReceptionVisitItem>(this as ReceptionVisitItem, _$identity);

  /// Serializes this ReceptionVisitItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceptionVisitItem&&(identical(other.id, id) || other.id == id)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.total, total) || other.total == total)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,serviceName,unitPrice,quantity,total,status);

@override
String toString() {
  return 'ReceptionVisitItem(id: $id, serviceName: $serviceName, unitPrice: $unitPrice, quantity: $quantity, total: $total, status: $status)';
}


}

/// @nodoc
abstract mixin class $ReceptionVisitItemCopyWith<$Res>  {
  factory $ReceptionVisitItemCopyWith(ReceptionVisitItem value, $Res Function(ReceptionVisitItem) _then) = _$ReceptionVisitItemCopyWithImpl;
@useResult
$Res call({
 String id, String serviceName, String unitPrice, int quantity, String total, String status
});




}
/// @nodoc
class _$ReceptionVisitItemCopyWithImpl<$Res>
    implements $ReceptionVisitItemCopyWith<$Res> {
  _$ReceptionVisitItemCopyWithImpl(this._self, this._then);

  final ReceptionVisitItem _self;
  final $Res Function(ReceptionVisitItem) _then;

/// Create a copy of ReceptionVisitItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? serviceName = null,Object? unitPrice = null,Object? quantity = null,Object? total = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceptionVisitItem].
extension ReceptionVisitItemPatterns on ReceptionVisitItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceptionVisitItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceptionVisitItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceptionVisitItem value)  $default,){
final _that = this;
switch (_that) {
case _ReceptionVisitItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceptionVisitItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReceptionVisitItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String serviceName,  String unitPrice,  int quantity,  String total,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceptionVisitItem() when $default != null:
return $default(_that.id,_that.serviceName,_that.unitPrice,_that.quantity,_that.total,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String serviceName,  String unitPrice,  int quantity,  String total,  String status)  $default,) {final _that = this;
switch (_that) {
case _ReceptionVisitItem():
return $default(_that.id,_that.serviceName,_that.unitPrice,_that.quantity,_that.total,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String serviceName,  String unitPrice,  int quantity,  String total,  String status)?  $default,) {final _that = this;
switch (_that) {
case _ReceptionVisitItem() when $default != null:
return $default(_that.id,_that.serviceName,_that.unitPrice,_that.quantity,_that.total,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceptionVisitItem implements ReceptionVisitItem {
  const _ReceptionVisitItem({required this.id, required this.serviceName, required this.unitPrice, required this.quantity, required this.total, required this.status});
  factory _ReceptionVisitItem.fromJson(Map<String, dynamic> json) => _$ReceptionVisitItemFromJson(json);

@override final  String id;
@override final  String serviceName;
@override final  String unitPrice;
@override final  int quantity;
@override final  String total;
@override final  String status;

/// Create a copy of ReceptionVisitItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceptionVisitItemCopyWith<_ReceptionVisitItem> get copyWith => __$ReceptionVisitItemCopyWithImpl<_ReceptionVisitItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceptionVisitItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceptionVisitItem&&(identical(other.id, id) || other.id == id)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.total, total) || other.total == total)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,serviceName,unitPrice,quantity,total,status);

@override
String toString() {
  return 'ReceptionVisitItem(id: $id, serviceName: $serviceName, unitPrice: $unitPrice, quantity: $quantity, total: $total, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ReceptionVisitItemCopyWith<$Res> implements $ReceptionVisitItemCopyWith<$Res> {
  factory _$ReceptionVisitItemCopyWith(_ReceptionVisitItem value, $Res Function(_ReceptionVisitItem) _then) = __$ReceptionVisitItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String serviceName, String unitPrice, int quantity, String total, String status
});




}
/// @nodoc
class __$ReceptionVisitItemCopyWithImpl<$Res>
    implements _$ReceptionVisitItemCopyWith<$Res> {
  __$ReceptionVisitItemCopyWithImpl(this._self, this._then);

  final _ReceptionVisitItem _self;
  final $Res Function(_ReceptionVisitItem) _then;

/// Create a copy of ReceptionVisitItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? serviceName = null,Object? unitPrice = null,Object? quantity = null,Object? total = null,Object? status = null,}) {
  return _then(_ReceptionVisitItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
