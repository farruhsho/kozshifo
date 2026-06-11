// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Patient {

 String get id; String get mrn; String get firstName; String get lastName; String? get middleName; String get fullName; String? get birthDate; String? get gender; String? get phone; String? get email; String? get address; String? get notes; String? get branchId;
/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientCopyWith<Patient> get copyWith => _$PatientCopyWithImpl<Patient>(this as Patient, _$identity);

  /// Serializes this Patient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Patient&&(identical(other.id, id) || other.id == id)&&(identical(other.mrn, mrn) || other.mrn == mrn)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.middleName, middleName) || other.middleName == middleName)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.branchId, branchId) || other.branchId == branchId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mrn,firstName,lastName,middleName,fullName,birthDate,gender,phone,email,address,notes,branchId);

@override
String toString() {
  return 'Patient(id: $id, mrn: $mrn, firstName: $firstName, lastName: $lastName, middleName: $middleName, fullName: $fullName, birthDate: $birthDate, gender: $gender, phone: $phone, email: $email, address: $address, notes: $notes, branchId: $branchId)';
}


}

/// @nodoc
abstract mixin class $PatientCopyWith<$Res>  {
  factory $PatientCopyWith(Patient value, $Res Function(Patient) _then) = _$PatientCopyWithImpl;
@useResult
$Res call({
 String id, String mrn, String firstName, String lastName, String? middleName, String fullName, String? birthDate, String? gender, String? phone, String? email, String? address, String? notes, String? branchId
});




}
/// @nodoc
class _$PatientCopyWithImpl<$Res>
    implements $PatientCopyWith<$Res> {
  _$PatientCopyWithImpl(this._self, this._then);

  final Patient _self;
  final $Res Function(Patient) _then;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mrn = null,Object? firstName = null,Object? lastName = null,Object? middleName = freezed,Object? fullName = null,Object? birthDate = freezed,Object? gender = freezed,Object? phone = freezed,Object? email = freezed,Object? address = freezed,Object? notes = freezed,Object? branchId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mrn: null == mrn ? _self.mrn : mrn // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,middleName: freezed == middleName ? _self.middleName : middleName // ignore: cast_nullable_to_non_nullable
as String?,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Patient].
extension PatientPatterns on Patient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Patient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Patient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Patient value)  $default,){
final _that = this;
switch (_that) {
case _Patient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Patient value)?  $default,){
final _that = this;
switch (_that) {
case _Patient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String mrn,  String firstName,  String lastName,  String? middleName,  String fullName,  String? birthDate,  String? gender,  String? phone,  String? email,  String? address,  String? notes,  String? branchId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that.id,_that.mrn,_that.firstName,_that.lastName,_that.middleName,_that.fullName,_that.birthDate,_that.gender,_that.phone,_that.email,_that.address,_that.notes,_that.branchId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String mrn,  String firstName,  String lastName,  String? middleName,  String fullName,  String? birthDate,  String? gender,  String? phone,  String? email,  String? address,  String? notes,  String? branchId)  $default,) {final _that = this;
switch (_that) {
case _Patient():
return $default(_that.id,_that.mrn,_that.firstName,_that.lastName,_that.middleName,_that.fullName,_that.birthDate,_that.gender,_that.phone,_that.email,_that.address,_that.notes,_that.branchId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String mrn,  String firstName,  String lastName,  String? middleName,  String fullName,  String? birthDate,  String? gender,  String? phone,  String? email,  String? address,  String? notes,  String? branchId)?  $default,) {final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that.id,_that.mrn,_that.firstName,_that.lastName,_that.middleName,_that.fullName,_that.birthDate,_that.gender,_that.phone,_that.email,_that.address,_that.notes,_that.branchId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Patient extends Patient {
  const _Patient({required this.id, required this.mrn, required this.firstName, required this.lastName, this.middleName, required this.fullName, this.birthDate, this.gender, this.phone, this.email, this.address, this.notes, this.branchId}): super._();
  factory _Patient.fromJson(Map<String, dynamic> json) => _$PatientFromJson(json);

@override final  String id;
@override final  String mrn;
@override final  String firstName;
@override final  String lastName;
@override final  String? middleName;
@override final  String fullName;
@override final  String? birthDate;
@override final  String? gender;
@override final  String? phone;
@override final  String? email;
@override final  String? address;
@override final  String? notes;
@override final  String? branchId;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientCopyWith<_Patient> get copyWith => __$PatientCopyWithImpl<_Patient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Patient&&(identical(other.id, id) || other.id == id)&&(identical(other.mrn, mrn) || other.mrn == mrn)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.middleName, middleName) || other.middleName == middleName)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.branchId, branchId) || other.branchId == branchId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mrn,firstName,lastName,middleName,fullName,birthDate,gender,phone,email,address,notes,branchId);

@override
String toString() {
  return 'Patient(id: $id, mrn: $mrn, firstName: $firstName, lastName: $lastName, middleName: $middleName, fullName: $fullName, birthDate: $birthDate, gender: $gender, phone: $phone, email: $email, address: $address, notes: $notes, branchId: $branchId)';
}


}

/// @nodoc
abstract mixin class _$PatientCopyWith<$Res> implements $PatientCopyWith<$Res> {
  factory _$PatientCopyWith(_Patient value, $Res Function(_Patient) _then) = __$PatientCopyWithImpl;
@override @useResult
$Res call({
 String id, String mrn, String firstName, String lastName, String? middleName, String fullName, String? birthDate, String? gender, String? phone, String? email, String? address, String? notes, String? branchId
});




}
/// @nodoc
class __$PatientCopyWithImpl<$Res>
    implements _$PatientCopyWith<$Res> {
  __$PatientCopyWithImpl(this._self, this._then);

  final _Patient _self;
  final $Res Function(_Patient) _then;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mrn = null,Object? firstName = null,Object? lastName = null,Object? middleName = freezed,Object? fullName = null,Object? birthDate = freezed,Object? gender = freezed,Object? phone = freezed,Object? email = freezed,Object? address = freezed,Object? notes = freezed,Object? branchId = freezed,}) {
  return _then(_Patient(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mrn: null == mrn ? _self.mrn : mrn // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,middleName: freezed == middleName ? _self.middleName : middleName // ignore: cast_nullable_to_non_nullable
as String?,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
