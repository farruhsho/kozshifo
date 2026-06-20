// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QueueTicket {

 String get id; String get ticketNumber; String get track; String get patientId; String get patientName; String? get patientMrn; String get branchId; String? get visitId; String? get serviceId; String? get room; String get status; int get priority; String? get calledAt; String? get calledById;// Адресная маршрутизация: id специалиста, к кому направлен талон
// (null = общий пул). Имя резолвится через queueSpecialistsProvider.
 String? get assignedUserId; String get createdAt;
/// Create a copy of QueueTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueTicketCopyWith<QueueTicket> get copyWith => _$QueueTicketCopyWithImpl<QueueTicket>(this as QueueTicket, _$identity);

  /// Serializes this QueueTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketNumber, ticketNumber) || other.ticketNumber == ticketNumber)&&(identical(other.track, track) || other.track == track)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.patientMrn, patientMrn) || other.patientMrn == patientMrn)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.room, room) || other.room == room)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.calledAt, calledAt) || other.calledAt == calledAt)&&(identical(other.calledById, calledById) || other.calledById == calledById)&&(identical(other.assignedUserId, assignedUserId) || other.assignedUserId == assignedUserId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketNumber,track,patientId,patientName,patientMrn,branchId,visitId,serviceId,room,status,priority,calledAt,calledById,assignedUserId,createdAt);

@override
String toString() {
  return 'QueueTicket(id: $id, ticketNumber: $ticketNumber, track: $track, patientId: $patientId, patientName: $patientName, patientMrn: $patientMrn, branchId: $branchId, visitId: $visitId, serviceId: $serviceId, room: $room, status: $status, priority: $priority, calledAt: $calledAt, calledById: $calledById, assignedUserId: $assignedUserId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $QueueTicketCopyWith<$Res>  {
  factory $QueueTicketCopyWith(QueueTicket value, $Res Function(QueueTicket) _then) = _$QueueTicketCopyWithImpl;
@useResult
$Res call({
 String id, String ticketNumber, String track, String patientId, String patientName, String? patientMrn, String branchId, String? visitId, String? serviceId, String? room, String status, int priority, String? calledAt, String? calledById, String? assignedUserId, String createdAt
});




}
/// @nodoc
class _$QueueTicketCopyWithImpl<$Res>
    implements $QueueTicketCopyWith<$Res> {
  _$QueueTicketCopyWithImpl(this._self, this._then);

  final QueueTicket _self;
  final $Res Function(QueueTicket) _then;

/// Create a copy of QueueTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ticketNumber = null,Object? track = null,Object? patientId = null,Object? patientName = null,Object? patientMrn = freezed,Object? branchId = null,Object? visitId = freezed,Object? serviceId = freezed,Object? room = freezed,Object? status = null,Object? priority = null,Object? calledAt = freezed,Object? calledById = freezed,Object? assignedUserId = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketNumber: null == ticketNumber ? _self.ticketNumber : ticketNumber // ignore: cast_nullable_to_non_nullable
as String,track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,patientMrn: freezed == patientMrn ? _self.patientMrn : patientMrn // ignore: cast_nullable_to_non_nullable
as String?,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,visitId: freezed == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,calledAt: freezed == calledAt ? _self.calledAt : calledAt // ignore: cast_nullable_to_non_nullable
as String?,calledById: freezed == calledById ? _self.calledById : calledById // ignore: cast_nullable_to_non_nullable
as String?,assignedUserId: freezed == assignedUserId ? _self.assignedUserId : assignedUserId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueTicket].
extension QueueTicketPatterns on QueueTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueTicket value)  $default,){
final _that = this;
switch (_that) {
case _QueueTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueTicket value)?  $default,){
final _that = this;
switch (_that) {
case _QueueTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ticketNumber,  String track,  String patientId,  String patientName,  String? patientMrn,  String branchId,  String? visitId,  String? serviceId,  String? room,  String status,  int priority,  String? calledAt,  String? calledById,  String? assignedUserId,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueTicket() when $default != null:
return $default(_that.id,_that.ticketNumber,_that.track,_that.patientId,_that.patientName,_that.patientMrn,_that.branchId,_that.visitId,_that.serviceId,_that.room,_that.status,_that.priority,_that.calledAt,_that.calledById,_that.assignedUserId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ticketNumber,  String track,  String patientId,  String patientName,  String? patientMrn,  String branchId,  String? visitId,  String? serviceId,  String? room,  String status,  int priority,  String? calledAt,  String? calledById,  String? assignedUserId,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _QueueTicket():
return $default(_that.id,_that.ticketNumber,_that.track,_that.patientId,_that.patientName,_that.patientMrn,_that.branchId,_that.visitId,_that.serviceId,_that.room,_that.status,_that.priority,_that.calledAt,_that.calledById,_that.assignedUserId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ticketNumber,  String track,  String patientId,  String patientName,  String? patientMrn,  String branchId,  String? visitId,  String? serviceId,  String? room,  String status,  int priority,  String? calledAt,  String? calledById,  String? assignedUserId,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _QueueTicket() when $default != null:
return $default(_that.id,_that.ticketNumber,_that.track,_that.patientId,_that.patientName,_that.patientMrn,_that.branchId,_that.visitId,_that.serviceId,_that.room,_that.status,_that.priority,_that.calledAt,_that.calledById,_that.assignedUserId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueTicket extends QueueTicket {
  const _QueueTicket({required this.id, required this.ticketNumber, this.track = 'doctor', required this.patientId, this.patientName = '', this.patientMrn, required this.branchId, this.visitId, this.serviceId, this.room, required this.status, this.priority = 0, this.calledAt, this.calledById, this.assignedUserId, required this.createdAt}): super._();
  factory _QueueTicket.fromJson(Map<String, dynamic> json) => _$QueueTicketFromJson(json);

@override final  String id;
@override final  String ticketNumber;
@override@JsonKey() final  String track;
@override final  String patientId;
@override@JsonKey() final  String patientName;
@override final  String? patientMrn;
@override final  String branchId;
@override final  String? visitId;
@override final  String? serviceId;
@override final  String? room;
@override final  String status;
@override@JsonKey() final  int priority;
@override final  String? calledAt;
@override final  String? calledById;
// Адресная маршрутизация: id специалиста, к кому направлен талон
// (null = общий пул). Имя резолвится через queueSpecialistsProvider.
@override final  String? assignedUserId;
@override final  String createdAt;

/// Create a copy of QueueTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueTicketCopyWith<_QueueTicket> get copyWith => __$QueueTicketCopyWithImpl<_QueueTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketNumber, ticketNumber) || other.ticketNumber == ticketNumber)&&(identical(other.track, track) || other.track == track)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.patientMrn, patientMrn) || other.patientMrn == patientMrn)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.room, room) || other.room == room)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.calledAt, calledAt) || other.calledAt == calledAt)&&(identical(other.calledById, calledById) || other.calledById == calledById)&&(identical(other.assignedUserId, assignedUserId) || other.assignedUserId == assignedUserId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketNumber,track,patientId,patientName,patientMrn,branchId,visitId,serviceId,room,status,priority,calledAt,calledById,assignedUserId,createdAt);

@override
String toString() {
  return 'QueueTicket(id: $id, ticketNumber: $ticketNumber, track: $track, patientId: $patientId, patientName: $patientName, patientMrn: $patientMrn, branchId: $branchId, visitId: $visitId, serviceId: $serviceId, room: $room, status: $status, priority: $priority, calledAt: $calledAt, calledById: $calledById, assignedUserId: $assignedUserId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$QueueTicketCopyWith<$Res> implements $QueueTicketCopyWith<$Res> {
  factory _$QueueTicketCopyWith(_QueueTicket value, $Res Function(_QueueTicket) _then) = __$QueueTicketCopyWithImpl;
@override @useResult
$Res call({
 String id, String ticketNumber, String track, String patientId, String patientName, String? patientMrn, String branchId, String? visitId, String? serviceId, String? room, String status, int priority, String? calledAt, String? calledById, String? assignedUserId, String createdAt
});




}
/// @nodoc
class __$QueueTicketCopyWithImpl<$Res>
    implements _$QueueTicketCopyWith<$Res> {
  __$QueueTicketCopyWithImpl(this._self, this._then);

  final _QueueTicket _self;
  final $Res Function(_QueueTicket) _then;

/// Create a copy of QueueTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ticketNumber = null,Object? track = null,Object? patientId = null,Object? patientName = null,Object? patientMrn = freezed,Object? branchId = null,Object? visitId = freezed,Object? serviceId = freezed,Object? room = freezed,Object? status = null,Object? priority = null,Object? calledAt = freezed,Object? calledById = freezed,Object? assignedUserId = freezed,Object? createdAt = null,}) {
  return _then(_QueueTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketNumber: null == ticketNumber ? _self.ticketNumber : ticketNumber // ignore: cast_nullable_to_non_nullable
as String,track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,patientMrn: freezed == patientMrn ? _self.patientMrn : patientMrn // ignore: cast_nullable_to_non_nullable
as String?,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,visitId: freezed == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,calledAt: freezed == calledAt ? _self.calledAt : calledAt // ignore: cast_nullable_to_non_nullable
as String?,calledById: freezed == calledById ? _self.calledById : calledById // ignore: cast_nullable_to_non_nullable
as String?,assignedUserId: freezed == assignedUserId ? _self.assignedUserId : assignedUserId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
