// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operation_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OperationType {

 String get id; String get code; String get name; String get serviceId; String get price; int? get durationMinutes; bool get isActive; String? get description; List<OperationConsumable> get consumables;
/// Create a copy of OperationType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationTypeCopyWith<OperationType> get copyWith => _$OperationTypeCopyWithImpl<OperationType>(this as OperationType, _$identity);

  /// Serializes this OperationType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationType&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.price, price) || other.price == price)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.consumables, consumables));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,serviceId,price,durationMinutes,isActive,description,const DeepCollectionEquality().hash(consumables));

@override
String toString() {
  return 'OperationType(id: $id, code: $code, name: $name, serviceId: $serviceId, price: $price, durationMinutes: $durationMinutes, isActive: $isActive, description: $description, consumables: $consumables)';
}


}

/// @nodoc
abstract mixin class $OperationTypeCopyWith<$Res>  {
  factory $OperationTypeCopyWith(OperationType value, $Res Function(OperationType) _then) = _$OperationTypeCopyWithImpl;
@useResult
$Res call({
 String id, String code, String name, String serviceId, String price, int? durationMinutes, bool isActive, String? description, List<OperationConsumable> consumables
});




}
/// @nodoc
class _$OperationTypeCopyWithImpl<$Res>
    implements $OperationTypeCopyWith<$Res> {
  _$OperationTypeCopyWithImpl(this._self, this._then);

  final OperationType _self;
  final $Res Function(OperationType) _then;

/// Create a copy of OperationType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? serviceId = null,Object? price = null,Object? durationMinutes = freezed,Object? isActive = null,Object? description = freezed,Object? consumables = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,consumables: null == consumables ? _self.consumables : consumables // ignore: cast_nullable_to_non_nullable
as List<OperationConsumable>,
  ));
}

}


/// Adds pattern-matching-related methods to [OperationType].
extension OperationTypePatterns on OperationType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OperationType value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OperationType() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OperationType value)  $default,){
final _that = this;
switch (_that) {
case _OperationType():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OperationType value)?  $default,){
final _that = this;
switch (_that) {
case _OperationType() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String name,  String serviceId,  String price,  int? durationMinutes,  bool isActive,  String? description,  List<OperationConsumable> consumables)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OperationType() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.serviceId,_that.price,_that.durationMinutes,_that.isActive,_that.description,_that.consumables);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String name,  String serviceId,  String price,  int? durationMinutes,  bool isActive,  String? description,  List<OperationConsumable> consumables)  $default,) {final _that = this;
switch (_that) {
case _OperationType():
return $default(_that.id,_that.code,_that.name,_that.serviceId,_that.price,_that.durationMinutes,_that.isActive,_that.description,_that.consumables);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String name,  String serviceId,  String price,  int? durationMinutes,  bool isActive,  String? description,  List<OperationConsumable> consumables)?  $default,) {final _that = this;
switch (_that) {
case _OperationType() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.serviceId,_that.price,_that.durationMinutes,_that.isActive,_that.description,_that.consumables);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OperationType implements OperationType {
  const _OperationType({required this.id, required this.code, required this.name, required this.serviceId, required this.price, this.durationMinutes, this.isActive = true, this.description, final  List<OperationConsumable> consumables = const <OperationConsumable>[]}): _consumables = consumables;
  factory _OperationType.fromJson(Map<String, dynamic> json) => _$OperationTypeFromJson(json);

@override final  String id;
@override final  String code;
@override final  String name;
@override final  String serviceId;
@override final  String price;
@override final  int? durationMinutes;
@override@JsonKey() final  bool isActive;
@override final  String? description;
 final  List<OperationConsumable> _consumables;
@override@JsonKey() List<OperationConsumable> get consumables {
  if (_consumables is EqualUnmodifiableListView) return _consumables;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_consumables);
}


/// Create a copy of OperationType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperationTypeCopyWith<_OperationType> get copyWith => __$OperationTypeCopyWithImpl<_OperationType>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OperationTypeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OperationType&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.price, price) || other.price == price)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._consumables, _consumables));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,serviceId,price,durationMinutes,isActive,description,const DeepCollectionEquality().hash(_consumables));

@override
String toString() {
  return 'OperationType(id: $id, code: $code, name: $name, serviceId: $serviceId, price: $price, durationMinutes: $durationMinutes, isActive: $isActive, description: $description, consumables: $consumables)';
}


}

/// @nodoc
abstract mixin class _$OperationTypeCopyWith<$Res> implements $OperationTypeCopyWith<$Res> {
  factory _$OperationTypeCopyWith(_OperationType value, $Res Function(_OperationType) _then) = __$OperationTypeCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String name, String serviceId, String price, int? durationMinutes, bool isActive, String? description, List<OperationConsumable> consumables
});




}
/// @nodoc
class __$OperationTypeCopyWithImpl<$Res>
    implements _$OperationTypeCopyWith<$Res> {
  __$OperationTypeCopyWithImpl(this._self, this._then);

  final _OperationType _self;
  final $Res Function(_OperationType) _then;

/// Create a copy of OperationType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? serviceId = null,Object? price = null,Object? durationMinutes = freezed,Object? isActive = null,Object? description = freezed,Object? consumables = null,}) {
  return _then(_OperationType(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,consumables: null == consumables ? _self._consumables : consumables // ignore: cast_nullable_to_non_nullable
as List<OperationConsumable>,
  ));
}


}


/// @nodoc
mixin _$OperationConsumable {

 String get productId; String get productName; String get quantity;
/// Create a copy of OperationConsumable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationConsumableCopyWith<OperationConsumable> get copyWith => _$OperationConsumableCopyWithImpl<OperationConsumable>(this as OperationConsumable, _$identity);

  /// Serializes this OperationConsumable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationConsumable&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity);

@override
String toString() {
  return 'OperationConsumable(productId: $productId, productName: $productName, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $OperationConsumableCopyWith<$Res>  {
  factory $OperationConsumableCopyWith(OperationConsumable value, $Res Function(OperationConsumable) _then) = _$OperationConsumableCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, String quantity
});




}
/// @nodoc
class _$OperationConsumableCopyWithImpl<$Res>
    implements $OperationConsumableCopyWith<$Res> {
  _$OperationConsumableCopyWithImpl(this._self, this._then);

  final OperationConsumable _self;
  final $Res Function(OperationConsumable) _then;

/// Create a copy of OperationConsumable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OperationConsumable].
extension OperationConsumablePatterns on OperationConsumable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OperationConsumable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OperationConsumable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OperationConsumable value)  $default,){
final _that = this;
switch (_that) {
case _OperationConsumable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OperationConsumable value)?  $default,){
final _that = this;
switch (_that) {
case _OperationConsumable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String productName,  String quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OperationConsumable() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String productName,  String quantity)  $default,) {final _that = this;
switch (_that) {
case _OperationConsumable():
return $default(_that.productId,_that.productName,_that.quantity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String productName,  String quantity)?  $default,) {final _that = this;
switch (_that) {
case _OperationConsumable() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OperationConsumable implements OperationConsumable {
  const _OperationConsumable({required this.productId, required this.productName, required this.quantity});
  factory _OperationConsumable.fromJson(Map<String, dynamic> json) => _$OperationConsumableFromJson(json);

@override final  String productId;
@override final  String productName;
@override final  String quantity;

/// Create a copy of OperationConsumable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperationConsumableCopyWith<_OperationConsumable> get copyWith => __$OperationConsumableCopyWithImpl<_OperationConsumable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OperationConsumableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OperationConsumable&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity);

@override
String toString() {
  return 'OperationConsumable(productId: $productId, productName: $productName, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$OperationConsumableCopyWith<$Res> implements $OperationConsumableCopyWith<$Res> {
  factory _$OperationConsumableCopyWith(_OperationConsumable value, $Res Function(_OperationConsumable) _then) = __$OperationConsumableCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, String quantity
});




}
/// @nodoc
class __$OperationConsumableCopyWithImpl<$Res>
    implements _$OperationConsumableCopyWith<$Res> {
  __$OperationConsumableCopyWithImpl(this._self, this._then);

  final _OperationConsumable _self;
  final $Res Function(_OperationConsumable) _then;

/// Create a copy of OperationConsumable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,}) {
  return _then(_OperationConsumable(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
