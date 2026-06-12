// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Expense {

 String get id; String get branchId; String get category; String get amount; String get expenseDate;// YYYY-MM-DD
 String? get note; String get kind;// regular | payroll
 String? get payrollUserId; String? get payrollMonth;// YYYY-MM
 String? get createdByName; String? get createdAt;
/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCopyWith<Expense> get copyWith => _$ExpenseCopyWithImpl<Expense>(this as Expense, _$identity);

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.expenseDate, expenseDate) || other.expenseDate == expenseDate)&&(identical(other.note, note) || other.note == note)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.payrollUserId, payrollUserId) || other.payrollUserId == payrollUserId)&&(identical(other.payrollMonth, payrollMonth) || other.payrollMonth == payrollMonth)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,branchId,category,amount,expenseDate,note,kind,payrollUserId,payrollMonth,createdByName,createdAt);

@override
String toString() {
  return 'Expense(id: $id, branchId: $branchId, category: $category, amount: $amount, expenseDate: $expenseDate, note: $note, kind: $kind, payrollUserId: $payrollUserId, payrollMonth: $payrollMonth, createdByName: $createdByName, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ExpenseCopyWith<$Res>  {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) _then) = _$ExpenseCopyWithImpl;
@useResult
$Res call({
 String id, String branchId, String category, String amount, String expenseDate, String? note, String kind, String? payrollUserId, String? payrollMonth, String? createdByName, String? createdAt
});




}
/// @nodoc
class _$ExpenseCopyWithImpl<$Res>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._self, this._then);

  final Expense _self;
  final $Res Function(Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? branchId = null,Object? category = null,Object? amount = null,Object? expenseDate = null,Object? note = freezed,Object? kind = null,Object? payrollUserId = freezed,Object? payrollMonth = freezed,Object? createdByName = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,expenseDate: null == expenseDate ? _self.expenseDate : expenseDate // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,payrollUserId: freezed == payrollUserId ? _self.payrollUserId : payrollUserId // ignore: cast_nullable_to_non_nullable
as String?,payrollMonth: freezed == payrollMonth ? _self.payrollMonth : payrollMonth // ignore: cast_nullable_to_non_nullable
as String?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Expense].
extension ExpensePatterns on Expense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Expense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Expense value)  $default,){
final _that = this;
switch (_that) {
case _Expense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Expense value)?  $default,){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String branchId,  String category,  String amount,  String expenseDate,  String? note,  String kind,  String? payrollUserId,  String? payrollMonth,  String? createdByName,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.branchId,_that.category,_that.amount,_that.expenseDate,_that.note,_that.kind,_that.payrollUserId,_that.payrollMonth,_that.createdByName,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String branchId,  String category,  String amount,  String expenseDate,  String? note,  String kind,  String? payrollUserId,  String? payrollMonth,  String? createdByName,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Expense():
return $default(_that.id,_that.branchId,_that.category,_that.amount,_that.expenseDate,_that.note,_that.kind,_that.payrollUserId,_that.payrollMonth,_that.createdByName,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String branchId,  String category,  String amount,  String expenseDate,  String? note,  String kind,  String? payrollUserId,  String? payrollMonth,  String? createdByName,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.branchId,_that.category,_that.amount,_that.expenseDate,_that.note,_that.kind,_that.payrollUserId,_that.payrollMonth,_that.createdByName,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Expense extends Expense {
  const _Expense({required this.id, required this.branchId, required this.category, required this.amount, required this.expenseDate, this.note, this.kind = 'regular', this.payrollUserId, this.payrollMonth, this.createdByName, this.createdAt}): super._();
  factory _Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

@override final  String id;
@override final  String branchId;
@override final  String category;
@override final  String amount;
@override final  String expenseDate;
// YYYY-MM-DD
@override final  String? note;
@override@JsonKey() final  String kind;
// regular | payroll
@override final  String? payrollUserId;
@override final  String? payrollMonth;
// YYYY-MM
@override final  String? createdByName;
@override final  String? createdAt;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCopyWith<_Expense> get copyWith => __$ExpenseCopyWithImpl<_Expense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.expenseDate, expenseDate) || other.expenseDate == expenseDate)&&(identical(other.note, note) || other.note == note)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.payrollUserId, payrollUserId) || other.payrollUserId == payrollUserId)&&(identical(other.payrollMonth, payrollMonth) || other.payrollMonth == payrollMonth)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,branchId,category,amount,expenseDate,note,kind,payrollUserId,payrollMonth,createdByName,createdAt);

@override
String toString() {
  return 'Expense(id: $id, branchId: $branchId, category: $category, amount: $amount, expenseDate: $expenseDate, note: $note, kind: $kind, payrollUserId: $payrollUserId, payrollMonth: $payrollMonth, createdByName: $createdByName, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$ExpenseCopyWith(_Expense value, $Res Function(_Expense) _then) = __$ExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id, String branchId, String category, String amount, String expenseDate, String? note, String kind, String? payrollUserId, String? payrollMonth, String? createdByName, String? createdAt
});




}
/// @nodoc
class __$ExpenseCopyWithImpl<$Res>
    implements _$ExpenseCopyWith<$Res> {
  __$ExpenseCopyWithImpl(this._self, this._then);

  final _Expense _self;
  final $Res Function(_Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? branchId = null,Object? category = null,Object? amount = null,Object? expenseDate = null,Object? note = freezed,Object? kind = null,Object? payrollUserId = freezed,Object? payrollMonth = freezed,Object? createdByName = freezed,Object? createdAt = freezed,}) {
  return _then(_Expense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,expenseDate: null == expenseDate ? _self.expenseDate : expenseDate // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,payrollUserId: freezed == payrollUserId ? _self.payrollUserId : payrollUserId // ignore: cast_nullable_to_non_nullable
as String?,payrollMonth: freezed == payrollMonth ? _self.payrollMonth : payrollMonth // ignore: cast_nullable_to_non_nullable
as String?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
