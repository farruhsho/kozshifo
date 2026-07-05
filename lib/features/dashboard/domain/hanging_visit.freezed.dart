// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hanging_visit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HangingVisitRow {

 String get visitId; String get visitNo; String get patientId; String get patientName; String get flowStatus; String get openedAt; String get detail;
/// Create a copy of HangingVisitRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HangingVisitRowCopyWith<HangingVisitRow> get copyWith => _$HangingVisitRowCopyWithImpl<HangingVisitRow>(this as HangingVisitRow, _$identity);

  /// Serializes this HangingVisitRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HangingVisitRow&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.flowStatus, flowStatus) || other.flowStatus == flowStatus)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,visitId,visitNo,patientId,patientName,flowStatus,openedAt,detail);

@override
String toString() {
  return 'HangingVisitRow(visitId: $visitId, visitNo: $visitNo, patientId: $patientId, patientName: $patientName, flowStatus: $flowStatus, openedAt: $openedAt, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $HangingVisitRowCopyWith<$Res>  {
  factory $HangingVisitRowCopyWith(HangingVisitRow value, $Res Function(HangingVisitRow) _then) = _$HangingVisitRowCopyWithImpl;
@useResult
$Res call({
 String visitId, String visitNo, String patientId, String patientName, String flowStatus, String openedAt, String detail
});




}
/// @nodoc
class _$HangingVisitRowCopyWithImpl<$Res>
    implements $HangingVisitRowCopyWith<$Res> {
  _$HangingVisitRowCopyWithImpl(this._self, this._then);

  final HangingVisitRow _self;
  final $Res Function(HangingVisitRow) _then;

/// Create a copy of HangingVisitRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? visitId = null,Object? visitNo = null,Object? patientId = null,Object? patientName = null,Object? flowStatus = null,Object? openedAt = null,Object? detail = null,}) {
  return _then(_self.copyWith(
visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,flowStatus: null == flowStatus ? _self.flowStatus : flowStatus // ignore: cast_nullable_to_non_nullable
as String,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HangingVisitRow].
extension HangingVisitRowPatterns on HangingVisitRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HangingVisitRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HangingVisitRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HangingVisitRow value)  $default,){
final _that = this;
switch (_that) {
case _HangingVisitRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HangingVisitRow value)?  $default,){
final _that = this;
switch (_that) {
case _HangingVisitRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String visitId,  String visitNo,  String patientId,  String patientName,  String flowStatus,  String openedAt,  String detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HangingVisitRow() when $default != null:
return $default(_that.visitId,_that.visitNo,_that.patientId,_that.patientName,_that.flowStatus,_that.openedAt,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String visitId,  String visitNo,  String patientId,  String patientName,  String flowStatus,  String openedAt,  String detail)  $default,) {final _that = this;
switch (_that) {
case _HangingVisitRow():
return $default(_that.visitId,_that.visitNo,_that.patientId,_that.patientName,_that.flowStatus,_that.openedAt,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String visitId,  String visitNo,  String patientId,  String patientName,  String flowStatus,  String openedAt,  String detail)?  $default,) {final _that = this;
switch (_that) {
case _HangingVisitRow() when $default != null:
return $default(_that.visitId,_that.visitNo,_that.patientId,_that.patientName,_that.flowStatus,_that.openedAt,_that.detail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HangingVisitRow implements HangingVisitRow {
  const _HangingVisitRow({required this.visitId, required this.visitNo, required this.patientId, required this.patientName, required this.flowStatus, required this.openedAt, required this.detail});
  factory _HangingVisitRow.fromJson(Map<String, dynamic> json) => _$HangingVisitRowFromJson(json);

@override final  String visitId;
@override final  String visitNo;
@override final  String patientId;
@override final  String patientName;
@override final  String flowStatus;
@override final  String openedAt;
@override final  String detail;

/// Create a copy of HangingVisitRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HangingVisitRowCopyWith<_HangingVisitRow> get copyWith => __$HangingVisitRowCopyWithImpl<_HangingVisitRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HangingVisitRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HangingVisitRow&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.visitNo, visitNo) || other.visitNo == visitNo)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.flowStatus, flowStatus) || other.flowStatus == flowStatus)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,visitId,visitNo,patientId,patientName,flowStatus,openedAt,detail);

@override
String toString() {
  return 'HangingVisitRow(visitId: $visitId, visitNo: $visitNo, patientId: $patientId, patientName: $patientName, flowStatus: $flowStatus, openedAt: $openedAt, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$HangingVisitRowCopyWith<$Res> implements $HangingVisitRowCopyWith<$Res> {
  factory _$HangingVisitRowCopyWith(_HangingVisitRow value, $Res Function(_HangingVisitRow) _then) = __$HangingVisitRowCopyWithImpl;
@override @useResult
$Res call({
 String visitId, String visitNo, String patientId, String patientName, String flowStatus, String openedAt, String detail
});




}
/// @nodoc
class __$HangingVisitRowCopyWithImpl<$Res>
    implements _$HangingVisitRowCopyWith<$Res> {
  __$HangingVisitRowCopyWithImpl(this._self, this._then);

  final _HangingVisitRow _self;
  final $Res Function(_HangingVisitRow) _then;

/// Create a copy of HangingVisitRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? visitId = null,Object? visitNo = null,Object? patientId = null,Object? patientName = null,Object? flowStatus = null,Object? openedAt = null,Object? detail = null,}) {
  return _then(_HangingVisitRow(
visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,visitNo: null == visitNo ? _self.visitNo : visitNo // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,flowStatus: null == flowStatus ? _self.flowStatus : flowStatus // ignore: cast_nullable_to_non_nullable
as String,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$HangingCategory {

 String get category; String get label; String get severity;// info | warning | critical
 int get count; String? get route; List<HangingVisitRow> get visits;
/// Create a copy of HangingCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HangingCategoryCopyWith<HangingCategory> get copyWith => _$HangingCategoryCopyWithImpl<HangingCategory>(this as HangingCategory, _$identity);

  /// Serializes this HangingCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HangingCategory&&(identical(other.category, category) || other.category == category)&&(identical(other.label, label) || other.label == label)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.count, count) || other.count == count)&&(identical(other.route, route) || other.route == route)&&const DeepCollectionEquality().equals(other.visits, visits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,label,severity,count,route,const DeepCollectionEquality().hash(visits));

@override
String toString() {
  return 'HangingCategory(category: $category, label: $label, severity: $severity, count: $count, route: $route, visits: $visits)';
}


}

/// @nodoc
abstract mixin class $HangingCategoryCopyWith<$Res>  {
  factory $HangingCategoryCopyWith(HangingCategory value, $Res Function(HangingCategory) _then) = _$HangingCategoryCopyWithImpl;
@useResult
$Res call({
 String category, String label, String severity, int count, String? route, List<HangingVisitRow> visits
});




}
/// @nodoc
class _$HangingCategoryCopyWithImpl<$Res>
    implements $HangingCategoryCopyWith<$Res> {
  _$HangingCategoryCopyWithImpl(this._self, this._then);

  final HangingCategory _self;
  final $Res Function(HangingCategory) _then;

/// Create a copy of HangingCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? label = null,Object? severity = null,Object? count = null,Object? route = freezed,Object? visits = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,visits: null == visits ? _self.visits : visits // ignore: cast_nullable_to_non_nullable
as List<HangingVisitRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [HangingCategory].
extension HangingCategoryPatterns on HangingCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HangingCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HangingCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HangingCategory value)  $default,){
final _that = this;
switch (_that) {
case _HangingCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HangingCategory value)?  $default,){
final _that = this;
switch (_that) {
case _HangingCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String category,  String label,  String severity,  int count,  String? route,  List<HangingVisitRow> visits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HangingCategory() when $default != null:
return $default(_that.category,_that.label,_that.severity,_that.count,_that.route,_that.visits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String category,  String label,  String severity,  int count,  String? route,  List<HangingVisitRow> visits)  $default,) {final _that = this;
switch (_that) {
case _HangingCategory():
return $default(_that.category,_that.label,_that.severity,_that.count,_that.route,_that.visits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String category,  String label,  String severity,  int count,  String? route,  List<HangingVisitRow> visits)?  $default,) {final _that = this;
switch (_that) {
case _HangingCategory() when $default != null:
return $default(_that.category,_that.label,_that.severity,_that.count,_that.route,_that.visits);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HangingCategory extends HangingCategory {
  const _HangingCategory({required this.category, required this.label, required this.severity, required this.count, this.route, final  List<HangingVisitRow> visits = const <HangingVisitRow>[]}): _visits = visits,super._();
  factory _HangingCategory.fromJson(Map<String, dynamic> json) => _$HangingCategoryFromJson(json);

@override final  String category;
@override final  String label;
@override final  String severity;
// info | warning | critical
@override final  int count;
@override final  String? route;
 final  List<HangingVisitRow> _visits;
@override@JsonKey() List<HangingVisitRow> get visits {
  if (_visits is EqualUnmodifiableListView) return _visits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_visits);
}


/// Create a copy of HangingCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HangingCategoryCopyWith<_HangingCategory> get copyWith => __$HangingCategoryCopyWithImpl<_HangingCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HangingCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HangingCategory&&(identical(other.category, category) || other.category == category)&&(identical(other.label, label) || other.label == label)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.count, count) || other.count == count)&&(identical(other.route, route) || other.route == route)&&const DeepCollectionEquality().equals(other._visits, _visits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,label,severity,count,route,const DeepCollectionEquality().hash(_visits));

@override
String toString() {
  return 'HangingCategory(category: $category, label: $label, severity: $severity, count: $count, route: $route, visits: $visits)';
}


}

/// @nodoc
abstract mixin class _$HangingCategoryCopyWith<$Res> implements $HangingCategoryCopyWith<$Res> {
  factory _$HangingCategoryCopyWith(_HangingCategory value, $Res Function(_HangingCategory) _then) = __$HangingCategoryCopyWithImpl;
@override @useResult
$Res call({
 String category, String label, String severity, int count, String? route, List<HangingVisitRow> visits
});




}
/// @nodoc
class __$HangingCategoryCopyWithImpl<$Res>
    implements _$HangingCategoryCopyWith<$Res> {
  __$HangingCategoryCopyWithImpl(this._self, this._then);

  final _HangingCategory _self;
  final $Res Function(_HangingCategory) _then;

/// Create a copy of HangingCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? label = null,Object? severity = null,Object? count = null,Object? route = freezed,Object? visits = null,}) {
  return _then(_HangingCategory(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,visits: null == visits ? _self._visits : visits // ignore: cast_nullable_to_non_nullable
as List<HangingVisitRow>,
  ));
}


}

// dart format on
