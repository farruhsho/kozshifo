// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StaffUser {

 String get id; String get email; String get fullName; String? get phone; bool get isActive; bool get isSuperuser; String? get branchId;// Процентная оплата врача (доля от выручки его визитов). Decimal приходит
// строкой (например "12.50"); null = не на процентной оплате.
 String? get salaryPercent;// Кабинет врача (например «Каб. 1») — при вызове талона в очереди пациент
// направляется именно сюда. Задаёт директор. null = не клинический сотрудник.
 String? get cabinet;@JsonKey(fromJson: roleNamesFromJson) List<String> get roles;// Услуги, которые ведёт врач (бэкенд UserOut.services: [{id, code, name}]).
@JsonKey(fromJson: doctorServicesFromJson, toJson: doctorServicesToJson) List<DoctorService> get services;
/// Create a copy of StaffUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffUserCopyWith<StaffUser> get copyWith => _$StaffUserCopyWithImpl<StaffUser>(this as StaffUser, _$identity);

  /// Serializes this StaffUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffUser&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isSuperuser, isSuperuser) || other.isSuperuser == isSuperuser)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.salaryPercent, salaryPercent) || other.salaryPercent == salaryPercent)&&(identical(other.cabinet, cabinet) || other.cabinet == cabinet)&&const DeepCollectionEquality().equals(other.roles, roles)&&const DeepCollectionEquality().equals(other.services, services));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,fullName,phone,isActive,isSuperuser,branchId,salaryPercent,cabinet,const DeepCollectionEquality().hash(roles),const DeepCollectionEquality().hash(services));

@override
String toString() {
  return 'StaffUser(id: $id, email: $email, fullName: $fullName, phone: $phone, isActive: $isActive, isSuperuser: $isSuperuser, branchId: $branchId, salaryPercent: $salaryPercent, cabinet: $cabinet, roles: $roles, services: $services)';
}


}

/// @nodoc
abstract mixin class $StaffUserCopyWith<$Res>  {
  factory $StaffUserCopyWith(StaffUser value, $Res Function(StaffUser) _then) = _$StaffUserCopyWithImpl;
@useResult
$Res call({
 String id, String email, String fullName, String? phone, bool isActive, bool isSuperuser, String? branchId, String? salaryPercent, String? cabinet,@JsonKey(fromJson: roleNamesFromJson) List<String> roles,@JsonKey(fromJson: doctorServicesFromJson, toJson: doctorServicesToJson) List<DoctorService> services
});




}
/// @nodoc
class _$StaffUserCopyWithImpl<$Res>
    implements $StaffUserCopyWith<$Res> {
  _$StaffUserCopyWithImpl(this._self, this._then);

  final StaffUser _self;
  final $Res Function(StaffUser) _then;

/// Create a copy of StaffUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? fullName = null,Object? phone = freezed,Object? isActive = null,Object? isSuperuser = null,Object? branchId = freezed,Object? salaryPercent = freezed,Object? cabinet = freezed,Object? roles = null,Object? services = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isSuperuser: null == isSuperuser ? _self.isSuperuser : isSuperuser // ignore: cast_nullable_to_non_nullable
as bool,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,salaryPercent: freezed == salaryPercent ? _self.salaryPercent : salaryPercent // ignore: cast_nullable_to_non_nullable
as String?,cabinet: freezed == cabinet ? _self.cabinet : cabinet // ignore: cast_nullable_to_non_nullable
as String?,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as List<DoctorService>,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffUser].
extension StaffUserPatterns on StaffUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffUser value)  $default,){
final _that = this;
switch (_that) {
case _StaffUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffUser value)?  $default,){
final _that = this;
switch (_that) {
case _StaffUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email,  String fullName,  String? phone,  bool isActive,  bool isSuperuser,  String? branchId,  String? salaryPercent,  String? cabinet, @JsonKey(fromJson: roleNamesFromJson)  List<String> roles, @JsonKey(fromJson: doctorServicesFromJson, toJson: doctorServicesToJson)  List<DoctorService> services)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffUser() when $default != null:
return $default(_that.id,_that.email,_that.fullName,_that.phone,_that.isActive,_that.isSuperuser,_that.branchId,_that.salaryPercent,_that.cabinet,_that.roles,_that.services);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email,  String fullName,  String? phone,  bool isActive,  bool isSuperuser,  String? branchId,  String? salaryPercent,  String? cabinet, @JsonKey(fromJson: roleNamesFromJson)  List<String> roles, @JsonKey(fromJson: doctorServicesFromJson, toJson: doctorServicesToJson)  List<DoctorService> services)  $default,) {final _that = this;
switch (_that) {
case _StaffUser():
return $default(_that.id,_that.email,_that.fullName,_that.phone,_that.isActive,_that.isSuperuser,_that.branchId,_that.salaryPercent,_that.cabinet,_that.roles,_that.services);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email,  String fullName,  String? phone,  bool isActive,  bool isSuperuser,  String? branchId,  String? salaryPercent,  String? cabinet, @JsonKey(fromJson: roleNamesFromJson)  List<String> roles, @JsonKey(fromJson: doctorServicesFromJson, toJson: doctorServicesToJson)  List<DoctorService> services)?  $default,) {final _that = this;
switch (_that) {
case _StaffUser() when $default != null:
return $default(_that.id,_that.email,_that.fullName,_that.phone,_that.isActive,_that.isSuperuser,_that.branchId,_that.salaryPercent,_that.cabinet,_that.roles,_that.services);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffUser implements StaffUser {
  const _StaffUser({required this.id, required this.email, required this.fullName, this.phone, this.isActive = true, this.isSuperuser = false, this.branchId, this.salaryPercent, this.cabinet, @JsonKey(fromJson: roleNamesFromJson) final  List<String> roles = const <String>[], @JsonKey(fromJson: doctorServicesFromJson, toJson: doctorServicesToJson) final  List<DoctorService> services = const <DoctorService>[]}): _roles = roles,_services = services;
  factory _StaffUser.fromJson(Map<String, dynamic> json) => _$StaffUserFromJson(json);

@override final  String id;
@override final  String email;
@override final  String fullName;
@override final  String? phone;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  bool isSuperuser;
@override final  String? branchId;
// Процентная оплата врача (доля от выручки его визитов). Decimal приходит
// строкой (например "12.50"); null = не на процентной оплате.
@override final  String? salaryPercent;
// Кабинет врача (например «Каб. 1») — при вызове талона в очереди пациент
// направляется именно сюда. Задаёт директор. null = не клинический сотрудник.
@override final  String? cabinet;
 final  List<String> _roles;
@override@JsonKey(fromJson: roleNamesFromJson) List<String> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

// Услуги, которые ведёт врач (бэкенд UserOut.services: [{id, code, name}]).
 final  List<DoctorService> _services;
// Услуги, которые ведёт врач (бэкенд UserOut.services: [{id, code, name}]).
@override@JsonKey(fromJson: doctorServicesFromJson, toJson: doctorServicesToJson) List<DoctorService> get services {
  if (_services is EqualUnmodifiableListView) return _services;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_services);
}


/// Create a copy of StaffUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffUserCopyWith<_StaffUser> get copyWith => __$StaffUserCopyWithImpl<_StaffUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffUser&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isSuperuser, isSuperuser) || other.isSuperuser == isSuperuser)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.salaryPercent, salaryPercent) || other.salaryPercent == salaryPercent)&&(identical(other.cabinet, cabinet) || other.cabinet == cabinet)&&const DeepCollectionEquality().equals(other._roles, _roles)&&const DeepCollectionEquality().equals(other._services, _services));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,fullName,phone,isActive,isSuperuser,branchId,salaryPercent,cabinet,const DeepCollectionEquality().hash(_roles),const DeepCollectionEquality().hash(_services));

@override
String toString() {
  return 'StaffUser(id: $id, email: $email, fullName: $fullName, phone: $phone, isActive: $isActive, isSuperuser: $isSuperuser, branchId: $branchId, salaryPercent: $salaryPercent, cabinet: $cabinet, roles: $roles, services: $services)';
}


}

/// @nodoc
abstract mixin class _$StaffUserCopyWith<$Res> implements $StaffUserCopyWith<$Res> {
  factory _$StaffUserCopyWith(_StaffUser value, $Res Function(_StaffUser) _then) = __$StaffUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String email, String fullName, String? phone, bool isActive, bool isSuperuser, String? branchId, String? salaryPercent, String? cabinet,@JsonKey(fromJson: roleNamesFromJson) List<String> roles,@JsonKey(fromJson: doctorServicesFromJson, toJson: doctorServicesToJson) List<DoctorService> services
});




}
/// @nodoc
class __$StaffUserCopyWithImpl<$Res>
    implements _$StaffUserCopyWith<$Res> {
  __$StaffUserCopyWithImpl(this._self, this._then);

  final _StaffUser _self;
  final $Res Function(_StaffUser) _then;

/// Create a copy of StaffUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? fullName = null,Object? phone = freezed,Object? isActive = null,Object? isSuperuser = null,Object? branchId = freezed,Object? salaryPercent = freezed,Object? cabinet = freezed,Object? roles = null,Object? services = null,}) {
  return _then(_StaffUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isSuperuser: null == isSuperuser ? _self.isSuperuser : isSuperuser // ignore: cast_nullable_to_non_nullable
as bool,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,salaryPercent: freezed == salaryPercent ? _self.salaryPercent : salaryPercent // ignore: cast_nullable_to_non_nullable
as String?,cabinet: freezed == cabinet ? _self.cabinet : cabinet // ignore: cast_nullable_to_non_nullable
as String?,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,services: null == services ? _self._services : services // ignore: cast_nullable_to_non_nullable
as List<DoctorService>,
  ));
}


}

// dart format on
