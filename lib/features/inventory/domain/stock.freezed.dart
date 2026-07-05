// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockBatch {

 String get id; String? get batchNo; String? get expiryDate; String get quantity; String get unitCost; String get receivedAt; bool get expired;// Поставщик партии (для возврата поставщику → ref_id движения). Может быть
// null: партия без поставщика или бэкенд ещё не отдаёт поле в BatchOut.
 String? get supplierId;
/// Create a copy of StockBatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockBatchCopyWith<StockBatch> get copyWith => _$StockBatchCopyWithImpl<StockBatch>(this as StockBatch, _$identity);

  /// Serializes this StockBatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockBatch&&(identical(other.id, id) || other.id == id)&&(identical(other.batchNo, batchNo) || other.batchNo == batchNo)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitCost, unitCost) || other.unitCost == unitCost)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.expired, expired) || other.expired == expired)&&(identical(other.supplierId, supplierId) || other.supplierId == supplierId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,batchNo,expiryDate,quantity,unitCost,receivedAt,expired,supplierId);

@override
String toString() {
  return 'StockBatch(id: $id, batchNo: $batchNo, expiryDate: $expiryDate, quantity: $quantity, unitCost: $unitCost, receivedAt: $receivedAt, expired: $expired, supplierId: $supplierId)';
}


}

/// @nodoc
abstract mixin class $StockBatchCopyWith<$Res>  {
  factory $StockBatchCopyWith(StockBatch value, $Res Function(StockBatch) _then) = _$StockBatchCopyWithImpl;
@useResult
$Res call({
 String id, String? batchNo, String? expiryDate, String quantity, String unitCost, String receivedAt, bool expired, String? supplierId
});




}
/// @nodoc
class _$StockBatchCopyWithImpl<$Res>
    implements $StockBatchCopyWith<$Res> {
  _$StockBatchCopyWithImpl(this._self, this._then);

  final StockBatch _self;
  final $Res Function(StockBatch) _then;

/// Create a copy of StockBatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? batchNo = freezed,Object? expiryDate = freezed,Object? quantity = null,Object? unitCost = null,Object? receivedAt = null,Object? expired = null,Object? supplierId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,batchNo: freezed == batchNo ? _self.batchNo : batchNo // ignore: cast_nullable_to_non_nullable
as String?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitCost: null == unitCost ? _self.unitCost : unitCost // ignore: cast_nullable_to_non_nullable
as String,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as String,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,supplierId: freezed == supplierId ? _self.supplierId : supplierId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StockBatch].
extension StockBatchPatterns on StockBatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockBatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockBatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockBatch value)  $default,){
final _that = this;
switch (_that) {
case _StockBatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockBatch value)?  $default,){
final _that = this;
switch (_that) {
case _StockBatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? batchNo,  String? expiryDate,  String quantity,  String unitCost,  String receivedAt,  bool expired,  String? supplierId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockBatch() when $default != null:
return $default(_that.id,_that.batchNo,_that.expiryDate,_that.quantity,_that.unitCost,_that.receivedAt,_that.expired,_that.supplierId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? batchNo,  String? expiryDate,  String quantity,  String unitCost,  String receivedAt,  bool expired,  String? supplierId)  $default,) {final _that = this;
switch (_that) {
case _StockBatch():
return $default(_that.id,_that.batchNo,_that.expiryDate,_that.quantity,_that.unitCost,_that.receivedAt,_that.expired,_that.supplierId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? batchNo,  String? expiryDate,  String quantity,  String unitCost,  String receivedAt,  bool expired,  String? supplierId)?  $default,) {final _that = this;
switch (_that) {
case _StockBatch() when $default != null:
return $default(_that.id,_that.batchNo,_that.expiryDate,_that.quantity,_that.unitCost,_that.receivedAt,_that.expired,_that.supplierId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockBatch extends StockBatch {
  const _StockBatch({required this.id, this.batchNo, this.expiryDate, required this.quantity, required this.unitCost, required this.receivedAt, this.expired = false, this.supplierId}): super._();
  factory _StockBatch.fromJson(Map<String, dynamic> json) => _$StockBatchFromJson(json);

@override final  String id;
@override final  String? batchNo;
@override final  String? expiryDate;
@override final  String quantity;
@override final  String unitCost;
@override final  String receivedAt;
@override@JsonKey() final  bool expired;
// Поставщик партии (для возврата поставщику → ref_id движения). Может быть
// null: партия без поставщика или бэкенд ещё не отдаёт поле в BatchOut.
@override final  String? supplierId;

/// Create a copy of StockBatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockBatchCopyWith<_StockBatch> get copyWith => __$StockBatchCopyWithImpl<_StockBatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockBatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockBatch&&(identical(other.id, id) || other.id == id)&&(identical(other.batchNo, batchNo) || other.batchNo == batchNo)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitCost, unitCost) || other.unitCost == unitCost)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.expired, expired) || other.expired == expired)&&(identical(other.supplierId, supplierId) || other.supplierId == supplierId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,batchNo,expiryDate,quantity,unitCost,receivedAt,expired,supplierId);

@override
String toString() {
  return 'StockBatch(id: $id, batchNo: $batchNo, expiryDate: $expiryDate, quantity: $quantity, unitCost: $unitCost, receivedAt: $receivedAt, expired: $expired, supplierId: $supplierId)';
}


}

/// @nodoc
abstract mixin class _$StockBatchCopyWith<$Res> implements $StockBatchCopyWith<$Res> {
  factory _$StockBatchCopyWith(_StockBatch value, $Res Function(_StockBatch) _then) = __$StockBatchCopyWithImpl;
@override @useResult
$Res call({
 String id, String? batchNo, String? expiryDate, String quantity, String unitCost, String receivedAt, bool expired, String? supplierId
});




}
/// @nodoc
class __$StockBatchCopyWithImpl<$Res>
    implements _$StockBatchCopyWith<$Res> {
  __$StockBatchCopyWithImpl(this._self, this._then);

  final _StockBatch _self;
  final $Res Function(_StockBatch) _then;

/// Create a copy of StockBatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? batchNo = freezed,Object? expiryDate = freezed,Object? quantity = null,Object? unitCost = null,Object? receivedAt = null,Object? expired = null,Object? supplierId = freezed,}) {
  return _then(_StockBatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,batchNo: freezed == batchNo ? _self.batchNo : batchNo // ignore: cast_nullable_to_non_nullable
as String?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitCost: null == unitCost ? _self.unitCost : unitCost // ignore: cast_nullable_to_non_nullable
as String,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as String,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,supplierId: freezed == supplierId ? _self.supplierId : supplierId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$StockRow {

 Product get product; String get onHand; bool get lowStock; List<StockBatch> get batches;
/// Create a copy of StockRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockRowCopyWith<StockRow> get copyWith => _$StockRowCopyWithImpl<StockRow>(this as StockRow, _$identity);

  /// Serializes this StockRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockRow&&(identical(other.product, product) || other.product == product)&&(identical(other.onHand, onHand) || other.onHand == onHand)&&(identical(other.lowStock, lowStock) || other.lowStock == lowStock)&&const DeepCollectionEquality().equals(other.batches, batches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,product,onHand,lowStock,const DeepCollectionEquality().hash(batches));

@override
String toString() {
  return 'StockRow(product: $product, onHand: $onHand, lowStock: $lowStock, batches: $batches)';
}


}

/// @nodoc
abstract mixin class $StockRowCopyWith<$Res>  {
  factory $StockRowCopyWith(StockRow value, $Res Function(StockRow) _then) = _$StockRowCopyWithImpl;
@useResult
$Res call({
 Product product, String onHand, bool lowStock, List<StockBatch> batches
});


$ProductCopyWith<$Res> get product;

}
/// @nodoc
class _$StockRowCopyWithImpl<$Res>
    implements $StockRowCopyWith<$Res> {
  _$StockRowCopyWithImpl(this._self, this._then);

  final StockRow _self;
  final $Res Function(StockRow) _then;

/// Create a copy of StockRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? product = null,Object? onHand = null,Object? lowStock = null,Object? batches = null,}) {
  return _then(_self.copyWith(
product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as Product,onHand: null == onHand ? _self.onHand : onHand // ignore: cast_nullable_to_non_nullable
as String,lowStock: null == lowStock ? _self.lowStock : lowStock // ignore: cast_nullable_to_non_nullable
as bool,batches: null == batches ? _self.batches : batches // ignore: cast_nullable_to_non_nullable
as List<StockBatch>,
  ));
}
/// Create a copy of StockRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCopyWith<$Res> get product {
  
  return $ProductCopyWith<$Res>(_self.product, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}


/// Adds pattern-matching-related methods to [StockRow].
extension StockRowPatterns on StockRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockRow value)  $default,){
final _that = this;
switch (_that) {
case _StockRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockRow value)?  $default,){
final _that = this;
switch (_that) {
case _StockRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Product product,  String onHand,  bool lowStock,  List<StockBatch> batches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockRow() when $default != null:
return $default(_that.product,_that.onHand,_that.lowStock,_that.batches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Product product,  String onHand,  bool lowStock,  List<StockBatch> batches)  $default,) {final _that = this;
switch (_that) {
case _StockRow():
return $default(_that.product,_that.onHand,_that.lowStock,_that.batches);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Product product,  String onHand,  bool lowStock,  List<StockBatch> batches)?  $default,) {final _that = this;
switch (_that) {
case _StockRow() when $default != null:
return $default(_that.product,_that.onHand,_that.lowStock,_that.batches);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockRow implements StockRow {
  const _StockRow({required this.product, required this.onHand, this.lowStock = false, final  List<StockBatch> batches = const <StockBatch>[]}): _batches = batches;
  factory _StockRow.fromJson(Map<String, dynamic> json) => _$StockRowFromJson(json);

@override final  Product product;
@override final  String onHand;
@override@JsonKey() final  bool lowStock;
 final  List<StockBatch> _batches;
@override@JsonKey() List<StockBatch> get batches {
  if (_batches is EqualUnmodifiableListView) return _batches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_batches);
}


/// Create a copy of StockRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockRowCopyWith<_StockRow> get copyWith => __$StockRowCopyWithImpl<_StockRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockRow&&(identical(other.product, product) || other.product == product)&&(identical(other.onHand, onHand) || other.onHand == onHand)&&(identical(other.lowStock, lowStock) || other.lowStock == lowStock)&&const DeepCollectionEquality().equals(other._batches, _batches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,product,onHand,lowStock,const DeepCollectionEquality().hash(_batches));

@override
String toString() {
  return 'StockRow(product: $product, onHand: $onHand, lowStock: $lowStock, batches: $batches)';
}


}

/// @nodoc
abstract mixin class _$StockRowCopyWith<$Res> implements $StockRowCopyWith<$Res> {
  factory _$StockRowCopyWith(_StockRow value, $Res Function(_StockRow) _then) = __$StockRowCopyWithImpl;
@override @useResult
$Res call({
 Product product, String onHand, bool lowStock, List<StockBatch> batches
});


@override $ProductCopyWith<$Res> get product;

}
/// @nodoc
class __$StockRowCopyWithImpl<$Res>
    implements _$StockRowCopyWith<$Res> {
  __$StockRowCopyWithImpl(this._self, this._then);

  final _StockRow _self;
  final $Res Function(_StockRow) _then;

/// Create a copy of StockRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? product = null,Object? onHand = null,Object? lowStock = null,Object? batches = null,}) {
  return _then(_StockRow(
product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as Product,onHand: null == onHand ? _self.onHand : onHand // ignore: cast_nullable_to_non_nullable
as String,lowStock: null == lowStock ? _self.lowStock : lowStock // ignore: cast_nullable_to_non_nullable
as bool,batches: null == batches ? _self._batches : batches // ignore: cast_nullable_to_non_nullable
as List<StockBatch>,
  ));
}

/// Create a copy of StockRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCopyWith<$Res> get product {
  
  return $ProductCopyWith<$Res>(_self.product, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}

// dart format on
