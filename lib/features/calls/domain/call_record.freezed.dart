// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CallPatientBrief {

 String get id; String get lastName; String get firstName;
/// Create a copy of CallPatientBrief
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallPatientBriefCopyWith<CallPatientBrief> get copyWith => _$CallPatientBriefCopyWithImpl<CallPatientBrief>(this as CallPatientBrief, _$identity);

  /// Serializes this CallPatientBrief to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallPatientBrief&&(identical(other.id, id) || other.id == id)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.firstName, firstName) || other.firstName == firstName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lastName,firstName);

@override
String toString() {
  return 'CallPatientBrief(id: $id, lastName: $lastName, firstName: $firstName)';
}


}

/// @nodoc
abstract mixin class $CallPatientBriefCopyWith<$Res>  {
  factory $CallPatientBriefCopyWith(CallPatientBrief value, $Res Function(CallPatientBrief) _then) = _$CallPatientBriefCopyWithImpl;
@useResult
$Res call({
 String id, String lastName, String firstName
});




}
/// @nodoc
class _$CallPatientBriefCopyWithImpl<$Res>
    implements $CallPatientBriefCopyWith<$Res> {
  _$CallPatientBriefCopyWithImpl(this._self, this._then);

  final CallPatientBrief _self;
  final $Res Function(CallPatientBrief) _then;

/// Create a copy of CallPatientBrief
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lastName = null,Object? firstName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CallPatientBrief].
extension CallPatientBriefPatterns on CallPatientBrief {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallPatientBrief value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallPatientBrief() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallPatientBrief value)  $default,){
final _that = this;
switch (_that) {
case _CallPatientBrief():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallPatientBrief value)?  $default,){
final _that = this;
switch (_that) {
case _CallPatientBrief() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String lastName,  String firstName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallPatientBrief() when $default != null:
return $default(_that.id,_that.lastName,_that.firstName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String lastName,  String firstName)  $default,) {final _that = this;
switch (_that) {
case _CallPatientBrief():
return $default(_that.id,_that.lastName,_that.firstName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String lastName,  String firstName)?  $default,) {final _that = this;
switch (_that) {
case _CallPatientBrief() when $default != null:
return $default(_that.id,_that.lastName,_that.firstName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CallPatientBrief extends CallPatientBrief {
  const _CallPatientBrief({required this.id, required this.lastName, required this.firstName}): super._();
  factory _CallPatientBrief.fromJson(Map<String, dynamic> json) => _$CallPatientBriefFromJson(json);

@override final  String id;
@override final  String lastName;
@override final  String firstName;

/// Create a copy of CallPatientBrief
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallPatientBriefCopyWith<_CallPatientBrief> get copyWith => __$CallPatientBriefCopyWithImpl<_CallPatientBrief>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CallPatientBriefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallPatientBrief&&(identical(other.id, id) || other.id == id)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.firstName, firstName) || other.firstName == firstName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lastName,firstName);

@override
String toString() {
  return 'CallPatientBrief(id: $id, lastName: $lastName, firstName: $firstName)';
}


}

/// @nodoc
abstract mixin class _$CallPatientBriefCopyWith<$Res> implements $CallPatientBriefCopyWith<$Res> {
  factory _$CallPatientBriefCopyWith(_CallPatientBrief value, $Res Function(_CallPatientBrief) _then) = __$CallPatientBriefCopyWithImpl;
@override @useResult
$Res call({
 String id, String lastName, String firstName
});




}
/// @nodoc
class __$CallPatientBriefCopyWithImpl<$Res>
    implements _$CallPatientBriefCopyWith<$Res> {
  __$CallPatientBriefCopyWithImpl(this._self, this._then);

  final _CallPatientBrief _self;
  final $Res Function(_CallPatientBrief) _then;

/// Create a copy of CallPatientBrief
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lastName = null,Object? firstName = null,}) {
  return _then(_CallPatientBrief(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CallRecord {

 String get id; String get direction;// in | out
 String get phone; String get startedAt; int get durationSeconds; String? get recordingUrl; String? get note; CallPatientBrief? get patient;
/// Create a copy of CallRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallRecordCopyWith<CallRecord> get copyWith => _$CallRecordCopyWithImpl<CallRecord>(this as CallRecord, _$identity);

  /// Serializes this CallRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.recordingUrl, recordingUrl) || other.recordingUrl == recordingUrl)&&(identical(other.note, note) || other.note == note)&&(identical(other.patient, patient) || other.patient == patient));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,direction,phone,startedAt,durationSeconds,recordingUrl,note,patient);

@override
String toString() {
  return 'CallRecord(id: $id, direction: $direction, phone: $phone, startedAt: $startedAt, durationSeconds: $durationSeconds, recordingUrl: $recordingUrl, note: $note, patient: $patient)';
}


}

/// @nodoc
abstract mixin class $CallRecordCopyWith<$Res>  {
  factory $CallRecordCopyWith(CallRecord value, $Res Function(CallRecord) _then) = _$CallRecordCopyWithImpl;
@useResult
$Res call({
 String id, String direction, String phone, String startedAt, int durationSeconds, String? recordingUrl, String? note, CallPatientBrief? patient
});


$CallPatientBriefCopyWith<$Res>? get patient;

}
/// @nodoc
class _$CallRecordCopyWithImpl<$Res>
    implements $CallRecordCopyWith<$Res> {
  _$CallRecordCopyWithImpl(this._self, this._then);

  final CallRecord _self;
  final $Res Function(CallRecord) _then;

/// Create a copy of CallRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? direction = null,Object? phone = null,Object? startedAt = null,Object? durationSeconds = null,Object? recordingUrl = freezed,Object? note = freezed,Object? patient = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,recordingUrl: freezed == recordingUrl ? _self.recordingUrl : recordingUrl // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,patient: freezed == patient ? _self.patient : patient // ignore: cast_nullable_to_non_nullable
as CallPatientBrief?,
  ));
}
/// Create a copy of CallRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CallPatientBriefCopyWith<$Res>? get patient {
    if (_self.patient == null) {
    return null;
  }

  return $CallPatientBriefCopyWith<$Res>(_self.patient!, (value) {
    return _then(_self.copyWith(patient: value));
  });
}
}


/// Adds pattern-matching-related methods to [CallRecord].
extension CallRecordPatterns on CallRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallRecord value)  $default,){
final _that = this;
switch (_that) {
case _CallRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallRecord value)?  $default,){
final _that = this;
switch (_that) {
case _CallRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String direction,  String phone,  String startedAt,  int durationSeconds,  String? recordingUrl,  String? note,  CallPatientBrief? patient)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallRecord() when $default != null:
return $default(_that.id,_that.direction,_that.phone,_that.startedAt,_that.durationSeconds,_that.recordingUrl,_that.note,_that.patient);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String direction,  String phone,  String startedAt,  int durationSeconds,  String? recordingUrl,  String? note,  CallPatientBrief? patient)  $default,) {final _that = this;
switch (_that) {
case _CallRecord():
return $default(_that.id,_that.direction,_that.phone,_that.startedAt,_that.durationSeconds,_that.recordingUrl,_that.note,_that.patient);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String direction,  String phone,  String startedAt,  int durationSeconds,  String? recordingUrl,  String? note,  CallPatientBrief? patient)?  $default,) {final _that = this;
switch (_that) {
case _CallRecord() when $default != null:
return $default(_that.id,_that.direction,_that.phone,_that.startedAt,_that.durationSeconds,_that.recordingUrl,_that.note,_that.patient);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CallRecord extends CallRecord {
  const _CallRecord({required this.id, required this.direction, required this.phone, required this.startedAt, this.durationSeconds = 0, this.recordingUrl, this.note, this.patient}): super._();
  factory _CallRecord.fromJson(Map<String, dynamic> json) => _$CallRecordFromJson(json);

@override final  String id;
@override final  String direction;
// in | out
@override final  String phone;
@override final  String startedAt;
@override@JsonKey() final  int durationSeconds;
@override final  String? recordingUrl;
@override final  String? note;
@override final  CallPatientBrief? patient;

/// Create a copy of CallRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallRecordCopyWith<_CallRecord> get copyWith => __$CallRecordCopyWithImpl<_CallRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CallRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.recordingUrl, recordingUrl) || other.recordingUrl == recordingUrl)&&(identical(other.note, note) || other.note == note)&&(identical(other.patient, patient) || other.patient == patient));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,direction,phone,startedAt,durationSeconds,recordingUrl,note,patient);

@override
String toString() {
  return 'CallRecord(id: $id, direction: $direction, phone: $phone, startedAt: $startedAt, durationSeconds: $durationSeconds, recordingUrl: $recordingUrl, note: $note, patient: $patient)';
}


}

/// @nodoc
abstract mixin class _$CallRecordCopyWith<$Res> implements $CallRecordCopyWith<$Res> {
  factory _$CallRecordCopyWith(_CallRecord value, $Res Function(_CallRecord) _then) = __$CallRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String direction, String phone, String startedAt, int durationSeconds, String? recordingUrl, String? note, CallPatientBrief? patient
});


@override $CallPatientBriefCopyWith<$Res>? get patient;

}
/// @nodoc
class __$CallRecordCopyWithImpl<$Res>
    implements _$CallRecordCopyWith<$Res> {
  __$CallRecordCopyWithImpl(this._self, this._then);

  final _CallRecord _self;
  final $Res Function(_CallRecord) _then;

/// Create a copy of CallRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? direction = null,Object? phone = null,Object? startedAt = null,Object? durationSeconds = null,Object? recordingUrl = freezed,Object? note = freezed,Object? patient = freezed,}) {
  return _then(_CallRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,recordingUrl: freezed == recordingUrl ? _self.recordingUrl : recordingUrl // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,patient: freezed == patient ? _self.patient : patient // ignore: cast_nullable_to_non_nullable
as CallPatientBrief?,
  ));
}

/// Create a copy of CallRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CallPatientBriefCopyWith<$Res>? get patient {
    if (_self.patient == null) {
    return null;
  }

  return $CallPatientBriefCopyWith<$Res>(_self.patient!, (value) {
    return _then(_self.copyWith(patient: value));
  });
}
}

// dart format on
