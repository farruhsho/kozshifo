// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calls_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CallDeviceStat {

 String? get deviceId; String get label; int get total; int get answered; int get missed; int get avgWaitSeconds;
/// Create a copy of CallDeviceStat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallDeviceStatCopyWith<CallDeviceStat> get copyWith => _$CallDeviceStatCopyWithImpl<CallDeviceStat>(this as CallDeviceStat, _$identity);

  /// Serializes this CallDeviceStat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallDeviceStat&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.label, label) || other.label == label)&&(identical(other.total, total) || other.total == total)&&(identical(other.answered, answered) || other.answered == answered)&&(identical(other.missed, missed) || other.missed == missed)&&(identical(other.avgWaitSeconds, avgWaitSeconds) || other.avgWaitSeconds == avgWaitSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,label,total,answered,missed,avgWaitSeconds);

@override
String toString() {
  return 'CallDeviceStat(deviceId: $deviceId, label: $label, total: $total, answered: $answered, missed: $missed, avgWaitSeconds: $avgWaitSeconds)';
}


}

/// @nodoc
abstract mixin class $CallDeviceStatCopyWith<$Res>  {
  factory $CallDeviceStatCopyWith(CallDeviceStat value, $Res Function(CallDeviceStat) _then) = _$CallDeviceStatCopyWithImpl;
@useResult
$Res call({
 String? deviceId, String label, int total, int answered, int missed, int avgWaitSeconds
});




}
/// @nodoc
class _$CallDeviceStatCopyWithImpl<$Res>
    implements $CallDeviceStatCopyWith<$Res> {
  _$CallDeviceStatCopyWithImpl(this._self, this._then);

  final CallDeviceStat _self;
  final $Res Function(CallDeviceStat) _then;

/// Create a copy of CallDeviceStat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = freezed,Object? label = null,Object? total = null,Object? answered = null,Object? missed = null,Object? avgWaitSeconds = null,}) {
  return _then(_self.copyWith(
deviceId: freezed == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,answered: null == answered ? _self.answered : answered // ignore: cast_nullable_to_non_nullable
as int,missed: null == missed ? _self.missed : missed // ignore: cast_nullable_to_non_nullable
as int,avgWaitSeconds: null == avgWaitSeconds ? _self.avgWaitSeconds : avgWaitSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CallDeviceStat].
extension CallDeviceStatPatterns on CallDeviceStat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallDeviceStat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallDeviceStat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallDeviceStat value)  $default,){
final _that = this;
switch (_that) {
case _CallDeviceStat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallDeviceStat value)?  $default,){
final _that = this;
switch (_that) {
case _CallDeviceStat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? deviceId,  String label,  int total,  int answered,  int missed,  int avgWaitSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallDeviceStat() when $default != null:
return $default(_that.deviceId,_that.label,_that.total,_that.answered,_that.missed,_that.avgWaitSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? deviceId,  String label,  int total,  int answered,  int missed,  int avgWaitSeconds)  $default,) {final _that = this;
switch (_that) {
case _CallDeviceStat():
return $default(_that.deviceId,_that.label,_that.total,_that.answered,_that.missed,_that.avgWaitSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? deviceId,  String label,  int total,  int answered,  int missed,  int avgWaitSeconds)?  $default,) {final _that = this;
switch (_that) {
case _CallDeviceStat() when $default != null:
return $default(_that.deviceId,_that.label,_that.total,_that.answered,_that.missed,_that.avgWaitSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CallDeviceStat implements CallDeviceStat {
  const _CallDeviceStat({this.deviceId, required this.label, this.total = 0, this.answered = 0, this.missed = 0, this.avgWaitSeconds = 0});
  factory _CallDeviceStat.fromJson(Map<String, dynamic> json) => _$CallDeviceStatFromJson(json);

@override final  String? deviceId;
@override final  String label;
@override@JsonKey() final  int total;
@override@JsonKey() final  int answered;
@override@JsonKey() final  int missed;
@override@JsonKey() final  int avgWaitSeconds;

/// Create a copy of CallDeviceStat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallDeviceStatCopyWith<_CallDeviceStat> get copyWith => __$CallDeviceStatCopyWithImpl<_CallDeviceStat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CallDeviceStatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallDeviceStat&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.label, label) || other.label == label)&&(identical(other.total, total) || other.total == total)&&(identical(other.answered, answered) || other.answered == answered)&&(identical(other.missed, missed) || other.missed == missed)&&(identical(other.avgWaitSeconds, avgWaitSeconds) || other.avgWaitSeconds == avgWaitSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,label,total,answered,missed,avgWaitSeconds);

@override
String toString() {
  return 'CallDeviceStat(deviceId: $deviceId, label: $label, total: $total, answered: $answered, missed: $missed, avgWaitSeconds: $avgWaitSeconds)';
}


}

/// @nodoc
abstract mixin class _$CallDeviceStatCopyWith<$Res> implements $CallDeviceStatCopyWith<$Res> {
  factory _$CallDeviceStatCopyWith(_CallDeviceStat value, $Res Function(_CallDeviceStat) _then) = __$CallDeviceStatCopyWithImpl;
@override @useResult
$Res call({
 String? deviceId, String label, int total, int answered, int missed, int avgWaitSeconds
});




}
/// @nodoc
class __$CallDeviceStatCopyWithImpl<$Res>
    implements _$CallDeviceStatCopyWith<$Res> {
  __$CallDeviceStatCopyWithImpl(this._self, this._then);

  final _CallDeviceStat _self;
  final $Res Function(_CallDeviceStat) _then;

/// Create a copy of CallDeviceStat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = freezed,Object? label = null,Object? total = null,Object? answered = null,Object? missed = null,Object? avgWaitSeconds = null,}) {
  return _then(_CallDeviceStat(
deviceId: freezed == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,answered: null == answered ? _self.answered : answered // ignore: cast_nullable_to_non_nullable
as int,missed: null == missed ? _self.missed : missed // ignore: cast_nullable_to_non_nullable
as int,avgWaitSeconds: null == avgWaitSeconds ? _self.avgWaitSeconds : avgWaitSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CallHourBucket {

 int get hour; int get total; int get missed;
/// Create a copy of CallHourBucket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallHourBucketCopyWith<CallHourBucket> get copyWith => _$CallHourBucketCopyWithImpl<CallHourBucket>(this as CallHourBucket, _$identity);

  /// Serializes this CallHourBucket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallHourBucket&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.total, total) || other.total == total)&&(identical(other.missed, missed) || other.missed == missed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hour,total,missed);

@override
String toString() {
  return 'CallHourBucket(hour: $hour, total: $total, missed: $missed)';
}


}

/// @nodoc
abstract mixin class $CallHourBucketCopyWith<$Res>  {
  factory $CallHourBucketCopyWith(CallHourBucket value, $Res Function(CallHourBucket) _then) = _$CallHourBucketCopyWithImpl;
@useResult
$Res call({
 int hour, int total, int missed
});




}
/// @nodoc
class _$CallHourBucketCopyWithImpl<$Res>
    implements $CallHourBucketCopyWith<$Res> {
  _$CallHourBucketCopyWithImpl(this._self, this._then);

  final CallHourBucket _self;
  final $Res Function(CallHourBucket) _then;

/// Create a copy of CallHourBucket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hour = null,Object? total = null,Object? missed = null,}) {
  return _then(_self.copyWith(
hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,missed: null == missed ? _self.missed : missed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CallHourBucket].
extension CallHourBucketPatterns on CallHourBucket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallHourBucket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallHourBucket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallHourBucket value)  $default,){
final _that = this;
switch (_that) {
case _CallHourBucket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallHourBucket value)?  $default,){
final _that = this;
switch (_that) {
case _CallHourBucket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int hour,  int total,  int missed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallHourBucket() when $default != null:
return $default(_that.hour,_that.total,_that.missed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int hour,  int total,  int missed)  $default,) {final _that = this;
switch (_that) {
case _CallHourBucket():
return $default(_that.hour,_that.total,_that.missed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int hour,  int total,  int missed)?  $default,) {final _that = this;
switch (_that) {
case _CallHourBucket() when $default != null:
return $default(_that.hour,_that.total,_that.missed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CallHourBucket implements CallHourBucket {
  const _CallHourBucket({required this.hour, this.total = 0, this.missed = 0});
  factory _CallHourBucket.fromJson(Map<String, dynamic> json) => _$CallHourBucketFromJson(json);

@override final  int hour;
@override@JsonKey() final  int total;
@override@JsonKey() final  int missed;

/// Create a copy of CallHourBucket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallHourBucketCopyWith<_CallHourBucket> get copyWith => __$CallHourBucketCopyWithImpl<_CallHourBucket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CallHourBucketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallHourBucket&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.total, total) || other.total == total)&&(identical(other.missed, missed) || other.missed == missed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hour,total,missed);

@override
String toString() {
  return 'CallHourBucket(hour: $hour, total: $total, missed: $missed)';
}


}

/// @nodoc
abstract mixin class _$CallHourBucketCopyWith<$Res> implements $CallHourBucketCopyWith<$Res> {
  factory _$CallHourBucketCopyWith(_CallHourBucket value, $Res Function(_CallHourBucket) _then) = __$CallHourBucketCopyWithImpl;
@override @useResult
$Res call({
 int hour, int total, int missed
});




}
/// @nodoc
class __$CallHourBucketCopyWithImpl<$Res>
    implements _$CallHourBucketCopyWith<$Res> {
  __$CallHourBucketCopyWithImpl(this._self, this._then);

  final _CallHourBucket _self;
  final $Res Function(_CallHourBucket) _then;

/// Create a copy of CallHourBucket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hour = null,Object? total = null,Object? missed = null,}) {
  return _then(_CallHourBucket(
hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,missed: null == missed ? _self.missed : missed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CallsSummary {

 int get total; int get incoming; int get answered; int get missed; int get rejected; int get outgoing; double get missedRate; int get avgWaitSeconds; int get maxWaitSeconds; List<CallDeviceStat> get byDevice; List<CallHourBucket> get byHour; List<CallDevice> get offlineDevices;
/// Create a copy of CallsSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallsSummaryCopyWith<CallsSummary> get copyWith => _$CallsSummaryCopyWithImpl<CallsSummary>(this as CallsSummary, _$identity);

  /// Serializes this CallsSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallsSummary&&(identical(other.total, total) || other.total == total)&&(identical(other.incoming, incoming) || other.incoming == incoming)&&(identical(other.answered, answered) || other.answered == answered)&&(identical(other.missed, missed) || other.missed == missed)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&(identical(other.outgoing, outgoing) || other.outgoing == outgoing)&&(identical(other.missedRate, missedRate) || other.missedRate == missedRate)&&(identical(other.avgWaitSeconds, avgWaitSeconds) || other.avgWaitSeconds == avgWaitSeconds)&&(identical(other.maxWaitSeconds, maxWaitSeconds) || other.maxWaitSeconds == maxWaitSeconds)&&const DeepCollectionEquality().equals(other.byDevice, byDevice)&&const DeepCollectionEquality().equals(other.byHour, byHour)&&const DeepCollectionEquality().equals(other.offlineDevices, offlineDevices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,incoming,answered,missed,rejected,outgoing,missedRate,avgWaitSeconds,maxWaitSeconds,const DeepCollectionEquality().hash(byDevice),const DeepCollectionEquality().hash(byHour),const DeepCollectionEquality().hash(offlineDevices));

@override
String toString() {
  return 'CallsSummary(total: $total, incoming: $incoming, answered: $answered, missed: $missed, rejected: $rejected, outgoing: $outgoing, missedRate: $missedRate, avgWaitSeconds: $avgWaitSeconds, maxWaitSeconds: $maxWaitSeconds, byDevice: $byDevice, byHour: $byHour, offlineDevices: $offlineDevices)';
}


}

/// @nodoc
abstract mixin class $CallsSummaryCopyWith<$Res>  {
  factory $CallsSummaryCopyWith(CallsSummary value, $Res Function(CallsSummary) _then) = _$CallsSummaryCopyWithImpl;
@useResult
$Res call({
 int total, int incoming, int answered, int missed, int rejected, int outgoing, double missedRate, int avgWaitSeconds, int maxWaitSeconds, List<CallDeviceStat> byDevice, List<CallHourBucket> byHour, List<CallDevice> offlineDevices
});




}
/// @nodoc
class _$CallsSummaryCopyWithImpl<$Res>
    implements $CallsSummaryCopyWith<$Res> {
  _$CallsSummaryCopyWithImpl(this._self, this._then);

  final CallsSummary _self;
  final $Res Function(CallsSummary) _then;

/// Create a copy of CallsSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? incoming = null,Object? answered = null,Object? missed = null,Object? rejected = null,Object? outgoing = null,Object? missedRate = null,Object? avgWaitSeconds = null,Object? maxWaitSeconds = null,Object? byDevice = null,Object? byHour = null,Object? offlineDevices = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,incoming: null == incoming ? _self.incoming : incoming // ignore: cast_nullable_to_non_nullable
as int,answered: null == answered ? _self.answered : answered // ignore: cast_nullable_to_non_nullable
as int,missed: null == missed ? _self.missed : missed // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,outgoing: null == outgoing ? _self.outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as int,missedRate: null == missedRate ? _self.missedRate : missedRate // ignore: cast_nullable_to_non_nullable
as double,avgWaitSeconds: null == avgWaitSeconds ? _self.avgWaitSeconds : avgWaitSeconds // ignore: cast_nullable_to_non_nullable
as int,maxWaitSeconds: null == maxWaitSeconds ? _self.maxWaitSeconds : maxWaitSeconds // ignore: cast_nullable_to_non_nullable
as int,byDevice: null == byDevice ? _self.byDevice : byDevice // ignore: cast_nullable_to_non_nullable
as List<CallDeviceStat>,byHour: null == byHour ? _self.byHour : byHour // ignore: cast_nullable_to_non_nullable
as List<CallHourBucket>,offlineDevices: null == offlineDevices ? _self.offlineDevices : offlineDevices // ignore: cast_nullable_to_non_nullable
as List<CallDevice>,
  ));
}

}


/// Adds pattern-matching-related methods to [CallsSummary].
extension CallsSummaryPatterns on CallsSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallsSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallsSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallsSummary value)  $default,){
final _that = this;
switch (_that) {
case _CallsSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallsSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CallsSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  int incoming,  int answered,  int missed,  int rejected,  int outgoing,  double missedRate,  int avgWaitSeconds,  int maxWaitSeconds,  List<CallDeviceStat> byDevice,  List<CallHourBucket> byHour,  List<CallDevice> offlineDevices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallsSummary() when $default != null:
return $default(_that.total,_that.incoming,_that.answered,_that.missed,_that.rejected,_that.outgoing,_that.missedRate,_that.avgWaitSeconds,_that.maxWaitSeconds,_that.byDevice,_that.byHour,_that.offlineDevices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  int incoming,  int answered,  int missed,  int rejected,  int outgoing,  double missedRate,  int avgWaitSeconds,  int maxWaitSeconds,  List<CallDeviceStat> byDevice,  List<CallHourBucket> byHour,  List<CallDevice> offlineDevices)  $default,) {final _that = this;
switch (_that) {
case _CallsSummary():
return $default(_that.total,_that.incoming,_that.answered,_that.missed,_that.rejected,_that.outgoing,_that.missedRate,_that.avgWaitSeconds,_that.maxWaitSeconds,_that.byDevice,_that.byHour,_that.offlineDevices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  int incoming,  int answered,  int missed,  int rejected,  int outgoing,  double missedRate,  int avgWaitSeconds,  int maxWaitSeconds,  List<CallDeviceStat> byDevice,  List<CallHourBucket> byHour,  List<CallDevice> offlineDevices)?  $default,) {final _that = this;
switch (_that) {
case _CallsSummary() when $default != null:
return $default(_that.total,_that.incoming,_that.answered,_that.missed,_that.rejected,_that.outgoing,_that.missedRate,_that.avgWaitSeconds,_that.maxWaitSeconds,_that.byDevice,_that.byHour,_that.offlineDevices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CallsSummary extends CallsSummary {
  const _CallsSummary({this.total = 0, this.incoming = 0, this.answered = 0, this.missed = 0, this.rejected = 0, this.outgoing = 0, this.missedRate = 0, this.avgWaitSeconds = 0, this.maxWaitSeconds = 0, final  List<CallDeviceStat> byDevice = const <CallDeviceStat>[], final  List<CallHourBucket> byHour = const <CallHourBucket>[], final  List<CallDevice> offlineDevices = const <CallDevice>[]}): _byDevice = byDevice,_byHour = byHour,_offlineDevices = offlineDevices,super._();
  factory _CallsSummary.fromJson(Map<String, dynamic> json) => _$CallsSummaryFromJson(json);

@override@JsonKey() final  int total;
@override@JsonKey() final  int incoming;
@override@JsonKey() final  int answered;
@override@JsonKey() final  int missed;
@override@JsonKey() final  int rejected;
@override@JsonKey() final  int outgoing;
@override@JsonKey() final  double missedRate;
@override@JsonKey() final  int avgWaitSeconds;
@override@JsonKey() final  int maxWaitSeconds;
 final  List<CallDeviceStat> _byDevice;
@override@JsonKey() List<CallDeviceStat> get byDevice {
  if (_byDevice is EqualUnmodifiableListView) return _byDevice;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byDevice);
}

 final  List<CallHourBucket> _byHour;
@override@JsonKey() List<CallHourBucket> get byHour {
  if (_byHour is EqualUnmodifiableListView) return _byHour;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byHour);
}

 final  List<CallDevice> _offlineDevices;
@override@JsonKey() List<CallDevice> get offlineDevices {
  if (_offlineDevices is EqualUnmodifiableListView) return _offlineDevices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_offlineDevices);
}


/// Create a copy of CallsSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallsSummaryCopyWith<_CallsSummary> get copyWith => __$CallsSummaryCopyWithImpl<_CallsSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CallsSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallsSummary&&(identical(other.total, total) || other.total == total)&&(identical(other.incoming, incoming) || other.incoming == incoming)&&(identical(other.answered, answered) || other.answered == answered)&&(identical(other.missed, missed) || other.missed == missed)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&(identical(other.outgoing, outgoing) || other.outgoing == outgoing)&&(identical(other.missedRate, missedRate) || other.missedRate == missedRate)&&(identical(other.avgWaitSeconds, avgWaitSeconds) || other.avgWaitSeconds == avgWaitSeconds)&&(identical(other.maxWaitSeconds, maxWaitSeconds) || other.maxWaitSeconds == maxWaitSeconds)&&const DeepCollectionEquality().equals(other._byDevice, _byDevice)&&const DeepCollectionEquality().equals(other._byHour, _byHour)&&const DeepCollectionEquality().equals(other._offlineDevices, _offlineDevices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,incoming,answered,missed,rejected,outgoing,missedRate,avgWaitSeconds,maxWaitSeconds,const DeepCollectionEquality().hash(_byDevice),const DeepCollectionEquality().hash(_byHour),const DeepCollectionEquality().hash(_offlineDevices));

@override
String toString() {
  return 'CallsSummary(total: $total, incoming: $incoming, answered: $answered, missed: $missed, rejected: $rejected, outgoing: $outgoing, missedRate: $missedRate, avgWaitSeconds: $avgWaitSeconds, maxWaitSeconds: $maxWaitSeconds, byDevice: $byDevice, byHour: $byHour, offlineDevices: $offlineDevices)';
}


}

/// @nodoc
abstract mixin class _$CallsSummaryCopyWith<$Res> implements $CallsSummaryCopyWith<$Res> {
  factory _$CallsSummaryCopyWith(_CallsSummary value, $Res Function(_CallsSummary) _then) = __$CallsSummaryCopyWithImpl;
@override @useResult
$Res call({
 int total, int incoming, int answered, int missed, int rejected, int outgoing, double missedRate, int avgWaitSeconds, int maxWaitSeconds, List<CallDeviceStat> byDevice, List<CallHourBucket> byHour, List<CallDevice> offlineDevices
});




}
/// @nodoc
class __$CallsSummaryCopyWithImpl<$Res>
    implements _$CallsSummaryCopyWith<$Res> {
  __$CallsSummaryCopyWithImpl(this._self, this._then);

  final _CallsSummary _self;
  final $Res Function(_CallsSummary) _then;

/// Create a copy of CallsSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? incoming = null,Object? answered = null,Object? missed = null,Object? rejected = null,Object? outgoing = null,Object? missedRate = null,Object? avgWaitSeconds = null,Object? maxWaitSeconds = null,Object? byDevice = null,Object? byHour = null,Object? offlineDevices = null,}) {
  return _then(_CallsSummary(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,incoming: null == incoming ? _self.incoming : incoming // ignore: cast_nullable_to_non_nullable
as int,answered: null == answered ? _self.answered : answered // ignore: cast_nullable_to_non_nullable
as int,missed: null == missed ? _self.missed : missed // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,outgoing: null == outgoing ? _self.outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as int,missedRate: null == missedRate ? _self.missedRate : missedRate // ignore: cast_nullable_to_non_nullable
as double,avgWaitSeconds: null == avgWaitSeconds ? _self.avgWaitSeconds : avgWaitSeconds // ignore: cast_nullable_to_non_nullable
as int,maxWaitSeconds: null == maxWaitSeconds ? _self.maxWaitSeconds : maxWaitSeconds // ignore: cast_nullable_to_non_nullable
as int,byDevice: null == byDevice ? _self._byDevice : byDevice // ignore: cast_nullable_to_non_nullable
as List<CallDeviceStat>,byHour: null == byHour ? _self._byHour : byHour // ignore: cast_nullable_to_non_nullable
as List<CallHourBucket>,offlineDevices: null == offlineDevices ? _self._offlineDevices : offlineDevices // ignore: cast_nullable_to_non_nullable
as List<CallDevice>,
  ));
}


}

// dart format on
