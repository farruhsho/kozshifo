// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExpenseCategory {

 String get id; String get name; bool get isActive; bool get isSystem; int get sortOrder;
/// Create a copy of ExpenseCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCategoryCopyWith<ExpenseCategory> get copyWith => _$ExpenseCategoryCopyWithImpl<ExpenseCategory>(this as ExpenseCategory, _$identity);

  /// Serializes this ExpenseCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isActive,isSystem,sortOrder);

@override
String toString() {
  return 'ExpenseCategory(id: $id, name: $name, isActive: $isActive, isSystem: $isSystem, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ExpenseCategoryCopyWith<$Res>  {
  factory $ExpenseCategoryCopyWith(ExpenseCategory value, $Res Function(ExpenseCategory) _then) = _$ExpenseCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool isActive, bool isSystem, int sortOrder
});




}
/// @nodoc
class _$ExpenseCategoryCopyWithImpl<$Res>
    implements $ExpenseCategoryCopyWith<$Res> {
  _$ExpenseCategoryCopyWithImpl(this._self, this._then);

  final ExpenseCategory _self;
  final $Res Function(ExpenseCategory) _then;

/// Create a copy of ExpenseCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isActive = null,Object? isSystem = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseCategory].
extension ExpenseCategoryPatterns on ExpenseCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseCategory value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseCategory value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool isActive,  bool isSystem,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseCategory() when $default != null:
return $default(_that.id,_that.name,_that.isActive,_that.isSystem,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool isActive,  bool isSystem,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ExpenseCategory():
return $default(_that.id,_that.name,_that.isActive,_that.isSystem,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool isActive,  bool isSystem,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseCategory() when $default != null:
return $default(_that.id,_that.name,_that.isActive,_that.isSystem,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpenseCategory implements ExpenseCategory {
  const _ExpenseCategory({required this.id, required this.name, this.isActive = true, this.isSystem = false, this.sortOrder = 0});
  factory _ExpenseCategory.fromJson(Map<String, dynamic> json) => _$ExpenseCategoryFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  bool isSystem;
@override@JsonKey() final  int sortOrder;

/// Create a copy of ExpenseCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCategoryCopyWith<_ExpenseCategory> get copyWith => __$ExpenseCategoryCopyWithImpl<_ExpenseCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isActive,isSystem,sortOrder);

@override
String toString() {
  return 'ExpenseCategory(id: $id, name: $name, isActive: $isActive, isSystem: $isSystem, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCategoryCopyWith<$Res> implements $ExpenseCategoryCopyWith<$Res> {
  factory _$ExpenseCategoryCopyWith(_ExpenseCategory value, $Res Function(_ExpenseCategory) _then) = __$ExpenseCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isActive, bool isSystem, int sortOrder
});




}
/// @nodoc
class __$ExpenseCategoryCopyWithImpl<$Res>
    implements _$ExpenseCategoryCopyWith<$Res> {
  __$ExpenseCategoryCopyWithImpl(this._self, this._then);

  final _ExpenseCategory _self;
  final $Res Function(_ExpenseCategory) _then;

/// Create a copy of ExpenseCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isActive = null,Object? isSystem = null,Object? sortOrder = null,}) {
  return _then(_ExpenseCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RecurringExpense {

 String get id; String get category; String get name; String? get amount; bool get isFixed; bool get isActive; bool get posted; String? get postedAmount;
/// Create a copy of RecurringExpense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringExpenseCopyWith<RecurringExpense> get copyWith => _$RecurringExpenseCopyWithImpl<RecurringExpense>(this as RecurringExpense, _$identity);

  /// Serializes this RecurringExpense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isFixed, isFixed) || other.isFixed == isFixed)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.posted, posted) || other.posted == posted)&&(identical(other.postedAmount, postedAmount) || other.postedAmount == postedAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,name,amount,isFixed,isActive,posted,postedAmount);

@override
String toString() {
  return 'RecurringExpense(id: $id, category: $category, name: $name, amount: $amount, isFixed: $isFixed, isActive: $isActive, posted: $posted, postedAmount: $postedAmount)';
}


}

/// @nodoc
abstract mixin class $RecurringExpenseCopyWith<$Res>  {
  factory $RecurringExpenseCopyWith(RecurringExpense value, $Res Function(RecurringExpense) _then) = _$RecurringExpenseCopyWithImpl;
@useResult
$Res call({
 String id, String category, String name, String? amount, bool isFixed, bool isActive, bool posted, String? postedAmount
});




}
/// @nodoc
class _$RecurringExpenseCopyWithImpl<$Res>
    implements $RecurringExpenseCopyWith<$Res> {
  _$RecurringExpenseCopyWithImpl(this._self, this._then);

  final RecurringExpense _self;
  final $Res Function(RecurringExpense) _then;

/// Create a copy of RecurringExpense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? name = null,Object? amount = freezed,Object? isFixed = null,Object? isActive = null,Object? posted = null,Object? postedAmount = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,isFixed: null == isFixed ? _self.isFixed : isFixed // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,posted: null == posted ? _self.posted : posted // ignore: cast_nullable_to_non_nullable
as bool,postedAmount: freezed == postedAmount ? _self.postedAmount : postedAmount // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringExpense].
extension RecurringExpensePatterns on RecurringExpense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringExpense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringExpense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringExpense value)  $default,){
final _that = this;
switch (_that) {
case _RecurringExpense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringExpense value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringExpense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String category,  String name,  String? amount,  bool isFixed,  bool isActive,  bool posted,  String? postedAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringExpense() when $default != null:
return $default(_that.id,_that.category,_that.name,_that.amount,_that.isFixed,_that.isActive,_that.posted,_that.postedAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String category,  String name,  String? amount,  bool isFixed,  bool isActive,  bool posted,  String? postedAmount)  $default,) {final _that = this;
switch (_that) {
case _RecurringExpense():
return $default(_that.id,_that.category,_that.name,_that.amount,_that.isFixed,_that.isActive,_that.posted,_that.postedAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String category,  String name,  String? amount,  bool isFixed,  bool isActive,  bool posted,  String? postedAmount)?  $default,) {final _that = this;
switch (_that) {
case _RecurringExpense() when $default != null:
return $default(_that.id,_that.category,_that.name,_that.amount,_that.isFixed,_that.isActive,_that.posted,_that.postedAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurringExpense implements RecurringExpense {
  const _RecurringExpense({required this.id, required this.category, required this.name, this.amount, this.isFixed = true, this.isActive = true, this.posted = false, this.postedAmount});
  factory _RecurringExpense.fromJson(Map<String, dynamic> json) => _$RecurringExpenseFromJson(json);

@override final  String id;
@override final  String category;
@override final  String name;
@override final  String? amount;
@override@JsonKey() final  bool isFixed;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  bool posted;
@override final  String? postedAmount;

/// Create a copy of RecurringExpense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringExpenseCopyWith<_RecurringExpense> get copyWith => __$RecurringExpenseCopyWithImpl<_RecurringExpense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isFixed, isFixed) || other.isFixed == isFixed)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.posted, posted) || other.posted == posted)&&(identical(other.postedAmount, postedAmount) || other.postedAmount == postedAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,name,amount,isFixed,isActive,posted,postedAmount);

@override
String toString() {
  return 'RecurringExpense(id: $id, category: $category, name: $name, amount: $amount, isFixed: $isFixed, isActive: $isActive, posted: $posted, postedAmount: $postedAmount)';
}


}

/// @nodoc
abstract mixin class _$RecurringExpenseCopyWith<$Res> implements $RecurringExpenseCopyWith<$Res> {
  factory _$RecurringExpenseCopyWith(_RecurringExpense value, $Res Function(_RecurringExpense) _then) = __$RecurringExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id, String category, String name, String? amount, bool isFixed, bool isActive, bool posted, String? postedAmount
});




}
/// @nodoc
class __$RecurringExpenseCopyWithImpl<$Res>
    implements _$RecurringExpenseCopyWith<$Res> {
  __$RecurringExpenseCopyWithImpl(this._self, this._then);

  final _RecurringExpense _self;
  final $Res Function(_RecurringExpense) _then;

/// Create a copy of RecurringExpense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? name = null,Object? amount = freezed,Object? isFixed = null,Object? isActive = null,Object? posted = null,Object? postedAmount = freezed,}) {
  return _then(_RecurringExpense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,isFixed: null == isFixed ? _self.isFixed : isFixed // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,posted: null == posted ? _self.posted : posted // ignore: cast_nullable_to_non_nullable
as bool,postedAmount: freezed == postedAmount ? _self.postedAmount : postedAmount // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
