// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Insight {

 String get code; String get severity;// info | warning | critical
 String get title; String get detail; String? get value;// Client deep-link: tapping the card opens this section to fix the problem.
 String? get route;
/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightCopyWith<Insight> get copyWith => _$InsightCopyWithImpl<Insight>(this as Insight, _$identity);

  /// Serializes this Insight to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Insight&&(identical(other.code, code) || other.code == code)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.title, title) || other.title == title)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.value, value) || other.value == value)&&(identical(other.route, route) || other.route == route));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,severity,title,detail,value,route);

@override
String toString() {
  return 'Insight(code: $code, severity: $severity, title: $title, detail: $detail, value: $value, route: $route)';
}


}

/// @nodoc
abstract mixin class $InsightCopyWith<$Res>  {
  factory $InsightCopyWith(Insight value, $Res Function(Insight) _then) = _$InsightCopyWithImpl;
@useResult
$Res call({
 String code, String severity, String title, String detail, String? value, String? route
});




}
/// @nodoc
class _$InsightCopyWithImpl<$Res>
    implements $InsightCopyWith<$Res> {
  _$InsightCopyWithImpl(this._self, this._then);

  final Insight _self;
  final $Res Function(Insight) _then;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? severity = null,Object? title = null,Object? detail = null,Object? value = freezed,Object? route = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Insight].
extension InsightPatterns on Insight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Insight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Insight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Insight value)  $default,){
final _that = this;
switch (_that) {
case _Insight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Insight value)?  $default,){
final _that = this;
switch (_that) {
case _Insight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String severity,  String title,  String detail,  String? value,  String? route)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Insight() when $default != null:
return $default(_that.code,_that.severity,_that.title,_that.detail,_that.value,_that.route);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String severity,  String title,  String detail,  String? value,  String? route)  $default,) {final _that = this;
switch (_that) {
case _Insight():
return $default(_that.code,_that.severity,_that.title,_that.detail,_that.value,_that.route);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String severity,  String title,  String detail,  String? value,  String? route)?  $default,) {final _that = this;
switch (_that) {
case _Insight() when $default != null:
return $default(_that.code,_that.severity,_that.title,_that.detail,_that.value,_that.route);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Insight extends Insight {
  const _Insight({required this.code, required this.severity, required this.title, required this.detail, this.value, this.route}): super._();
  factory _Insight.fromJson(Map<String, dynamic> json) => _$InsightFromJson(json);

@override final  String code;
@override final  String severity;
// info | warning | critical
@override final  String title;
@override final  String detail;
@override final  String? value;
// Client deep-link: tapping the card opens this section to fix the problem.
@override final  String? route;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightCopyWith<_Insight> get copyWith => __$InsightCopyWithImpl<_Insight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InsightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Insight&&(identical(other.code, code) || other.code == code)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.title, title) || other.title == title)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.value, value) || other.value == value)&&(identical(other.route, route) || other.route == route));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,severity,title,detail,value,route);

@override
String toString() {
  return 'Insight(code: $code, severity: $severity, title: $title, detail: $detail, value: $value, route: $route)';
}


}

/// @nodoc
abstract mixin class _$InsightCopyWith<$Res> implements $InsightCopyWith<$Res> {
  factory _$InsightCopyWith(_Insight value, $Res Function(_Insight) _then) = __$InsightCopyWithImpl;
@override @useResult
$Res call({
 String code, String severity, String title, String detail, String? value, String? route
});




}
/// @nodoc
class __$InsightCopyWithImpl<$Res>
    implements _$InsightCopyWith<$Res> {
  __$InsightCopyWithImpl(this._self, this._then);

  final _Insight _self;
  final $Res Function(_Insight) _then;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? severity = null,Object? title = null,Object? detail = null,Object? value = freezed,Object? route = freezed,}) {
  return _then(_Insight(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
