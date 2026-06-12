// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'eye_exam.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EyeExam {

 String get id; String get visitId; String get patientId; String? get doctorId; String? get examDate;// Subjective
 String? get complaints; String? get anamnesis;// Refraction per eye
 String? get odVa; String? get osVa; String? get odSph; String? get osSph; String? get odCyl; String? get osCyl; int? get odAxis; int? get osAxis; String? get odVaCc; String? get osVaCc;// VA with the patient's own glasses/lenses (TZ «своими» — optional)
 String? get odVaOwn; String? get osVaOwn;// Visual field — поле зрения (TZ Modul 4)
 String? get visualField;// Tonometry, mmHg
 String? get iopOd; String? get iopOs;// Structures, in form order
 String? get orbit; String? get eyeball; String? get eyelids; String? get conjunctiva; String? get lacrimal; String? get cornea; String? get anteriorChamber; String? get iris; String? get pupil; String? get lens; String? get vitreous; String? get fundus; String? get abScanNote;// Conclusion
 String? get diagnosis; String? get icd10; String? get recommendations; String? get createdAt; String? get updatedAt;
/// Create a copy of EyeExam
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EyeExamCopyWith<EyeExam> get copyWith => _$EyeExamCopyWithImpl<EyeExam>(this as EyeExam, _$identity);

  /// Serializes this EyeExam to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EyeExam&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.examDate, examDate) || other.examDate == examDate)&&(identical(other.complaints, complaints) || other.complaints == complaints)&&(identical(other.anamnesis, anamnesis) || other.anamnesis == anamnesis)&&(identical(other.odVa, odVa) || other.odVa == odVa)&&(identical(other.osVa, osVa) || other.osVa == osVa)&&(identical(other.odSph, odSph) || other.odSph == odSph)&&(identical(other.osSph, osSph) || other.osSph == osSph)&&(identical(other.odCyl, odCyl) || other.odCyl == odCyl)&&(identical(other.osCyl, osCyl) || other.osCyl == osCyl)&&(identical(other.odAxis, odAxis) || other.odAxis == odAxis)&&(identical(other.osAxis, osAxis) || other.osAxis == osAxis)&&(identical(other.odVaCc, odVaCc) || other.odVaCc == odVaCc)&&(identical(other.osVaCc, osVaCc) || other.osVaCc == osVaCc)&&(identical(other.odVaOwn, odVaOwn) || other.odVaOwn == odVaOwn)&&(identical(other.osVaOwn, osVaOwn) || other.osVaOwn == osVaOwn)&&(identical(other.visualField, visualField) || other.visualField == visualField)&&(identical(other.iopOd, iopOd) || other.iopOd == iopOd)&&(identical(other.iopOs, iopOs) || other.iopOs == iopOs)&&(identical(other.orbit, orbit) || other.orbit == orbit)&&(identical(other.eyeball, eyeball) || other.eyeball == eyeball)&&(identical(other.eyelids, eyelids) || other.eyelids == eyelids)&&(identical(other.conjunctiva, conjunctiva) || other.conjunctiva == conjunctiva)&&(identical(other.lacrimal, lacrimal) || other.lacrimal == lacrimal)&&(identical(other.cornea, cornea) || other.cornea == cornea)&&(identical(other.anteriorChamber, anteriorChamber) || other.anteriorChamber == anteriorChamber)&&(identical(other.iris, iris) || other.iris == iris)&&(identical(other.pupil, pupil) || other.pupil == pupil)&&(identical(other.lens, lens) || other.lens == lens)&&(identical(other.vitreous, vitreous) || other.vitreous == vitreous)&&(identical(other.fundus, fundus) || other.fundus == fundus)&&(identical(other.abScanNote, abScanNote) || other.abScanNote == abScanNote)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.icd10, icd10) || other.icd10 == icd10)&&(identical(other.recommendations, recommendations) || other.recommendations == recommendations)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,visitId,patientId,doctorId,examDate,complaints,anamnesis,odVa,osVa,odSph,osSph,odCyl,osCyl,odAxis,osAxis,odVaCc,osVaCc,odVaOwn,osVaOwn,visualField,iopOd,iopOs,orbit,eyeball,eyelids,conjunctiva,lacrimal,cornea,anteriorChamber,iris,pupil,lens,vitreous,fundus,abScanNote,diagnosis,icd10,recommendations,createdAt,updatedAt]);

@override
String toString() {
  return 'EyeExam(id: $id, visitId: $visitId, patientId: $patientId, doctorId: $doctorId, examDate: $examDate, complaints: $complaints, anamnesis: $anamnesis, odVa: $odVa, osVa: $osVa, odSph: $odSph, osSph: $osSph, odCyl: $odCyl, osCyl: $osCyl, odAxis: $odAxis, osAxis: $osAxis, odVaCc: $odVaCc, osVaCc: $osVaCc, odVaOwn: $odVaOwn, osVaOwn: $osVaOwn, visualField: $visualField, iopOd: $iopOd, iopOs: $iopOs, orbit: $orbit, eyeball: $eyeball, eyelids: $eyelids, conjunctiva: $conjunctiva, lacrimal: $lacrimal, cornea: $cornea, anteriorChamber: $anteriorChamber, iris: $iris, pupil: $pupil, lens: $lens, vitreous: $vitreous, fundus: $fundus, abScanNote: $abScanNote, diagnosis: $diagnosis, icd10: $icd10, recommendations: $recommendations, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $EyeExamCopyWith<$Res>  {
  factory $EyeExamCopyWith(EyeExam value, $Res Function(EyeExam) _then) = _$EyeExamCopyWithImpl;
@useResult
$Res call({
 String id, String visitId, String patientId, String? doctorId, String? examDate, String? complaints, String? anamnesis, String? odVa, String? osVa, String? odSph, String? osSph, String? odCyl, String? osCyl, int? odAxis, int? osAxis, String? odVaCc, String? osVaCc, String? odVaOwn, String? osVaOwn, String? visualField, String? iopOd, String? iopOs, String? orbit, String? eyeball, String? eyelids, String? conjunctiva, String? lacrimal, String? cornea, String? anteriorChamber, String? iris, String? pupil, String? lens, String? vitreous, String? fundus, String? abScanNote, String? diagnosis, String? icd10, String? recommendations, String? createdAt, String? updatedAt
});




}
/// @nodoc
class _$EyeExamCopyWithImpl<$Res>
    implements $EyeExamCopyWith<$Res> {
  _$EyeExamCopyWithImpl(this._self, this._then);

  final EyeExam _self;
  final $Res Function(EyeExam) _then;

/// Create a copy of EyeExam
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? visitId = null,Object? patientId = null,Object? doctorId = freezed,Object? examDate = freezed,Object? complaints = freezed,Object? anamnesis = freezed,Object? odVa = freezed,Object? osVa = freezed,Object? odSph = freezed,Object? osSph = freezed,Object? odCyl = freezed,Object? osCyl = freezed,Object? odAxis = freezed,Object? osAxis = freezed,Object? odVaCc = freezed,Object? osVaCc = freezed,Object? odVaOwn = freezed,Object? osVaOwn = freezed,Object? visualField = freezed,Object? iopOd = freezed,Object? iopOs = freezed,Object? orbit = freezed,Object? eyeball = freezed,Object? eyelids = freezed,Object? conjunctiva = freezed,Object? lacrimal = freezed,Object? cornea = freezed,Object? anteriorChamber = freezed,Object? iris = freezed,Object? pupil = freezed,Object? lens = freezed,Object? vitreous = freezed,Object? fundus = freezed,Object? abScanNote = freezed,Object? diagnosis = freezed,Object? icd10 = freezed,Object? recommendations = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,doctorId: freezed == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String?,examDate: freezed == examDate ? _self.examDate : examDate // ignore: cast_nullable_to_non_nullable
as String?,complaints: freezed == complaints ? _self.complaints : complaints // ignore: cast_nullable_to_non_nullable
as String?,anamnesis: freezed == anamnesis ? _self.anamnesis : anamnesis // ignore: cast_nullable_to_non_nullable
as String?,odVa: freezed == odVa ? _self.odVa : odVa // ignore: cast_nullable_to_non_nullable
as String?,osVa: freezed == osVa ? _self.osVa : osVa // ignore: cast_nullable_to_non_nullable
as String?,odSph: freezed == odSph ? _self.odSph : odSph // ignore: cast_nullable_to_non_nullable
as String?,osSph: freezed == osSph ? _self.osSph : osSph // ignore: cast_nullable_to_non_nullable
as String?,odCyl: freezed == odCyl ? _self.odCyl : odCyl // ignore: cast_nullable_to_non_nullable
as String?,osCyl: freezed == osCyl ? _self.osCyl : osCyl // ignore: cast_nullable_to_non_nullable
as String?,odAxis: freezed == odAxis ? _self.odAxis : odAxis // ignore: cast_nullable_to_non_nullable
as int?,osAxis: freezed == osAxis ? _self.osAxis : osAxis // ignore: cast_nullable_to_non_nullable
as int?,odVaCc: freezed == odVaCc ? _self.odVaCc : odVaCc // ignore: cast_nullable_to_non_nullable
as String?,osVaCc: freezed == osVaCc ? _self.osVaCc : osVaCc // ignore: cast_nullable_to_non_nullable
as String?,odVaOwn: freezed == odVaOwn ? _self.odVaOwn : odVaOwn // ignore: cast_nullable_to_non_nullable
as String?,osVaOwn: freezed == osVaOwn ? _self.osVaOwn : osVaOwn // ignore: cast_nullable_to_non_nullable
as String?,visualField: freezed == visualField ? _self.visualField : visualField // ignore: cast_nullable_to_non_nullable
as String?,iopOd: freezed == iopOd ? _self.iopOd : iopOd // ignore: cast_nullable_to_non_nullable
as String?,iopOs: freezed == iopOs ? _self.iopOs : iopOs // ignore: cast_nullable_to_non_nullable
as String?,orbit: freezed == orbit ? _self.orbit : orbit // ignore: cast_nullable_to_non_nullable
as String?,eyeball: freezed == eyeball ? _self.eyeball : eyeball // ignore: cast_nullable_to_non_nullable
as String?,eyelids: freezed == eyelids ? _self.eyelids : eyelids // ignore: cast_nullable_to_non_nullable
as String?,conjunctiva: freezed == conjunctiva ? _self.conjunctiva : conjunctiva // ignore: cast_nullable_to_non_nullable
as String?,lacrimal: freezed == lacrimal ? _self.lacrimal : lacrimal // ignore: cast_nullable_to_non_nullable
as String?,cornea: freezed == cornea ? _self.cornea : cornea // ignore: cast_nullable_to_non_nullable
as String?,anteriorChamber: freezed == anteriorChamber ? _self.anteriorChamber : anteriorChamber // ignore: cast_nullable_to_non_nullable
as String?,iris: freezed == iris ? _self.iris : iris // ignore: cast_nullable_to_non_nullable
as String?,pupil: freezed == pupil ? _self.pupil : pupil // ignore: cast_nullable_to_non_nullable
as String?,lens: freezed == lens ? _self.lens : lens // ignore: cast_nullable_to_non_nullable
as String?,vitreous: freezed == vitreous ? _self.vitreous : vitreous // ignore: cast_nullable_to_non_nullable
as String?,fundus: freezed == fundus ? _self.fundus : fundus // ignore: cast_nullable_to_non_nullable
as String?,abScanNote: freezed == abScanNote ? _self.abScanNote : abScanNote // ignore: cast_nullable_to_non_nullable
as String?,diagnosis: freezed == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String?,icd10: freezed == icd10 ? _self.icd10 : icd10 // ignore: cast_nullable_to_non_nullable
as String?,recommendations: freezed == recommendations ? _self.recommendations : recommendations // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EyeExam].
extension EyeExamPatterns on EyeExam {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EyeExam value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EyeExam() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EyeExam value)  $default,){
final _that = this;
switch (_that) {
case _EyeExam():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EyeExam value)?  $default,){
final _that = this;
switch (_that) {
case _EyeExam() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String visitId,  String patientId,  String? doctorId,  String? examDate,  String? complaints,  String? anamnesis,  String? odVa,  String? osVa,  String? odSph,  String? osSph,  String? odCyl,  String? osCyl,  int? odAxis,  int? osAxis,  String? odVaCc,  String? osVaCc,  String? odVaOwn,  String? osVaOwn,  String? visualField,  String? iopOd,  String? iopOs,  String? orbit,  String? eyeball,  String? eyelids,  String? conjunctiva,  String? lacrimal,  String? cornea,  String? anteriorChamber,  String? iris,  String? pupil,  String? lens,  String? vitreous,  String? fundus,  String? abScanNote,  String? diagnosis,  String? icd10,  String? recommendations,  String? createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EyeExam() when $default != null:
return $default(_that.id,_that.visitId,_that.patientId,_that.doctorId,_that.examDate,_that.complaints,_that.anamnesis,_that.odVa,_that.osVa,_that.odSph,_that.osSph,_that.odCyl,_that.osCyl,_that.odAxis,_that.osAxis,_that.odVaCc,_that.osVaCc,_that.odVaOwn,_that.osVaOwn,_that.visualField,_that.iopOd,_that.iopOs,_that.orbit,_that.eyeball,_that.eyelids,_that.conjunctiva,_that.lacrimal,_that.cornea,_that.anteriorChamber,_that.iris,_that.pupil,_that.lens,_that.vitreous,_that.fundus,_that.abScanNote,_that.diagnosis,_that.icd10,_that.recommendations,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String visitId,  String patientId,  String? doctorId,  String? examDate,  String? complaints,  String? anamnesis,  String? odVa,  String? osVa,  String? odSph,  String? osSph,  String? odCyl,  String? osCyl,  int? odAxis,  int? osAxis,  String? odVaCc,  String? osVaCc,  String? odVaOwn,  String? osVaOwn,  String? visualField,  String? iopOd,  String? iopOs,  String? orbit,  String? eyeball,  String? eyelids,  String? conjunctiva,  String? lacrimal,  String? cornea,  String? anteriorChamber,  String? iris,  String? pupil,  String? lens,  String? vitreous,  String? fundus,  String? abScanNote,  String? diagnosis,  String? icd10,  String? recommendations,  String? createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _EyeExam():
return $default(_that.id,_that.visitId,_that.patientId,_that.doctorId,_that.examDate,_that.complaints,_that.anamnesis,_that.odVa,_that.osVa,_that.odSph,_that.osSph,_that.odCyl,_that.osCyl,_that.odAxis,_that.osAxis,_that.odVaCc,_that.osVaCc,_that.odVaOwn,_that.osVaOwn,_that.visualField,_that.iopOd,_that.iopOs,_that.orbit,_that.eyeball,_that.eyelids,_that.conjunctiva,_that.lacrimal,_that.cornea,_that.anteriorChamber,_that.iris,_that.pupil,_that.lens,_that.vitreous,_that.fundus,_that.abScanNote,_that.diagnosis,_that.icd10,_that.recommendations,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String visitId,  String patientId,  String? doctorId,  String? examDate,  String? complaints,  String? anamnesis,  String? odVa,  String? osVa,  String? odSph,  String? osSph,  String? odCyl,  String? osCyl,  int? odAxis,  int? osAxis,  String? odVaCc,  String? osVaCc,  String? odVaOwn,  String? osVaOwn,  String? visualField,  String? iopOd,  String? iopOs,  String? orbit,  String? eyeball,  String? eyelids,  String? conjunctiva,  String? lacrimal,  String? cornea,  String? anteriorChamber,  String? iris,  String? pupil,  String? lens,  String? vitreous,  String? fundus,  String? abScanNote,  String? diagnosis,  String? icd10,  String? recommendations,  String? createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _EyeExam() when $default != null:
return $default(_that.id,_that.visitId,_that.patientId,_that.doctorId,_that.examDate,_that.complaints,_that.anamnesis,_that.odVa,_that.osVa,_that.odSph,_that.osSph,_that.odCyl,_that.osCyl,_that.odAxis,_that.osAxis,_that.odVaCc,_that.osVaCc,_that.odVaOwn,_that.osVaOwn,_that.visualField,_that.iopOd,_that.iopOs,_that.orbit,_that.eyeball,_that.eyelids,_that.conjunctiva,_that.lacrimal,_that.cornea,_that.anteriorChamber,_that.iris,_that.pupil,_that.lens,_that.vitreous,_that.fundus,_that.abScanNote,_that.diagnosis,_that.icd10,_that.recommendations,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EyeExam extends EyeExam {
  const _EyeExam({required this.id, required this.visitId, required this.patientId, this.doctorId, this.examDate, this.complaints, this.anamnesis, this.odVa, this.osVa, this.odSph, this.osSph, this.odCyl, this.osCyl, this.odAxis, this.osAxis, this.odVaCc, this.osVaCc, this.odVaOwn, this.osVaOwn, this.visualField, this.iopOd, this.iopOs, this.orbit, this.eyeball, this.eyelids, this.conjunctiva, this.lacrimal, this.cornea, this.anteriorChamber, this.iris, this.pupil, this.lens, this.vitreous, this.fundus, this.abScanNote, this.diagnosis, this.icd10, this.recommendations, this.createdAt, this.updatedAt}): super._();
  factory _EyeExam.fromJson(Map<String, dynamic> json) => _$EyeExamFromJson(json);

@override final  String id;
@override final  String visitId;
@override final  String patientId;
@override final  String? doctorId;
@override final  String? examDate;
// Subjective
@override final  String? complaints;
@override final  String? anamnesis;
// Refraction per eye
@override final  String? odVa;
@override final  String? osVa;
@override final  String? odSph;
@override final  String? osSph;
@override final  String? odCyl;
@override final  String? osCyl;
@override final  int? odAxis;
@override final  int? osAxis;
@override final  String? odVaCc;
@override final  String? osVaCc;
// VA with the patient's own glasses/lenses (TZ «своими» — optional)
@override final  String? odVaOwn;
@override final  String? osVaOwn;
// Visual field — поле зрения (TZ Modul 4)
@override final  String? visualField;
// Tonometry, mmHg
@override final  String? iopOd;
@override final  String? iopOs;
// Structures, in form order
@override final  String? orbit;
@override final  String? eyeball;
@override final  String? eyelids;
@override final  String? conjunctiva;
@override final  String? lacrimal;
@override final  String? cornea;
@override final  String? anteriorChamber;
@override final  String? iris;
@override final  String? pupil;
@override final  String? lens;
@override final  String? vitreous;
@override final  String? fundus;
@override final  String? abScanNote;
// Conclusion
@override final  String? diagnosis;
@override final  String? icd10;
@override final  String? recommendations;
@override final  String? createdAt;
@override final  String? updatedAt;

/// Create a copy of EyeExam
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EyeExamCopyWith<_EyeExam> get copyWith => __$EyeExamCopyWithImpl<_EyeExam>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EyeExamToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EyeExam&&(identical(other.id, id) || other.id == id)&&(identical(other.visitId, visitId) || other.visitId == visitId)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.examDate, examDate) || other.examDate == examDate)&&(identical(other.complaints, complaints) || other.complaints == complaints)&&(identical(other.anamnesis, anamnesis) || other.anamnesis == anamnesis)&&(identical(other.odVa, odVa) || other.odVa == odVa)&&(identical(other.osVa, osVa) || other.osVa == osVa)&&(identical(other.odSph, odSph) || other.odSph == odSph)&&(identical(other.osSph, osSph) || other.osSph == osSph)&&(identical(other.odCyl, odCyl) || other.odCyl == odCyl)&&(identical(other.osCyl, osCyl) || other.osCyl == osCyl)&&(identical(other.odAxis, odAxis) || other.odAxis == odAxis)&&(identical(other.osAxis, osAxis) || other.osAxis == osAxis)&&(identical(other.odVaCc, odVaCc) || other.odVaCc == odVaCc)&&(identical(other.osVaCc, osVaCc) || other.osVaCc == osVaCc)&&(identical(other.odVaOwn, odVaOwn) || other.odVaOwn == odVaOwn)&&(identical(other.osVaOwn, osVaOwn) || other.osVaOwn == osVaOwn)&&(identical(other.visualField, visualField) || other.visualField == visualField)&&(identical(other.iopOd, iopOd) || other.iopOd == iopOd)&&(identical(other.iopOs, iopOs) || other.iopOs == iopOs)&&(identical(other.orbit, orbit) || other.orbit == orbit)&&(identical(other.eyeball, eyeball) || other.eyeball == eyeball)&&(identical(other.eyelids, eyelids) || other.eyelids == eyelids)&&(identical(other.conjunctiva, conjunctiva) || other.conjunctiva == conjunctiva)&&(identical(other.lacrimal, lacrimal) || other.lacrimal == lacrimal)&&(identical(other.cornea, cornea) || other.cornea == cornea)&&(identical(other.anteriorChamber, anteriorChamber) || other.anteriorChamber == anteriorChamber)&&(identical(other.iris, iris) || other.iris == iris)&&(identical(other.pupil, pupil) || other.pupil == pupil)&&(identical(other.lens, lens) || other.lens == lens)&&(identical(other.vitreous, vitreous) || other.vitreous == vitreous)&&(identical(other.fundus, fundus) || other.fundus == fundus)&&(identical(other.abScanNote, abScanNote) || other.abScanNote == abScanNote)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.icd10, icd10) || other.icd10 == icd10)&&(identical(other.recommendations, recommendations) || other.recommendations == recommendations)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,visitId,patientId,doctorId,examDate,complaints,anamnesis,odVa,osVa,odSph,osSph,odCyl,osCyl,odAxis,osAxis,odVaCc,osVaCc,odVaOwn,osVaOwn,visualField,iopOd,iopOs,orbit,eyeball,eyelids,conjunctiva,lacrimal,cornea,anteriorChamber,iris,pupil,lens,vitreous,fundus,abScanNote,diagnosis,icd10,recommendations,createdAt,updatedAt]);

@override
String toString() {
  return 'EyeExam(id: $id, visitId: $visitId, patientId: $patientId, doctorId: $doctorId, examDate: $examDate, complaints: $complaints, anamnesis: $anamnesis, odVa: $odVa, osVa: $osVa, odSph: $odSph, osSph: $osSph, odCyl: $odCyl, osCyl: $osCyl, odAxis: $odAxis, osAxis: $osAxis, odVaCc: $odVaCc, osVaCc: $osVaCc, odVaOwn: $odVaOwn, osVaOwn: $osVaOwn, visualField: $visualField, iopOd: $iopOd, iopOs: $iopOs, orbit: $orbit, eyeball: $eyeball, eyelids: $eyelids, conjunctiva: $conjunctiva, lacrimal: $lacrimal, cornea: $cornea, anteriorChamber: $anteriorChamber, iris: $iris, pupil: $pupil, lens: $lens, vitreous: $vitreous, fundus: $fundus, abScanNote: $abScanNote, diagnosis: $diagnosis, icd10: $icd10, recommendations: $recommendations, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$EyeExamCopyWith<$Res> implements $EyeExamCopyWith<$Res> {
  factory _$EyeExamCopyWith(_EyeExam value, $Res Function(_EyeExam) _then) = __$EyeExamCopyWithImpl;
@override @useResult
$Res call({
 String id, String visitId, String patientId, String? doctorId, String? examDate, String? complaints, String? anamnesis, String? odVa, String? osVa, String? odSph, String? osSph, String? odCyl, String? osCyl, int? odAxis, int? osAxis, String? odVaCc, String? osVaCc, String? odVaOwn, String? osVaOwn, String? visualField, String? iopOd, String? iopOs, String? orbit, String? eyeball, String? eyelids, String? conjunctiva, String? lacrimal, String? cornea, String? anteriorChamber, String? iris, String? pupil, String? lens, String? vitreous, String? fundus, String? abScanNote, String? diagnosis, String? icd10, String? recommendations, String? createdAt, String? updatedAt
});




}
/// @nodoc
class __$EyeExamCopyWithImpl<$Res>
    implements _$EyeExamCopyWith<$Res> {
  __$EyeExamCopyWithImpl(this._self, this._then);

  final _EyeExam _self;
  final $Res Function(_EyeExam) _then;

/// Create a copy of EyeExam
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? visitId = null,Object? patientId = null,Object? doctorId = freezed,Object? examDate = freezed,Object? complaints = freezed,Object? anamnesis = freezed,Object? odVa = freezed,Object? osVa = freezed,Object? odSph = freezed,Object? osSph = freezed,Object? odCyl = freezed,Object? osCyl = freezed,Object? odAxis = freezed,Object? osAxis = freezed,Object? odVaCc = freezed,Object? osVaCc = freezed,Object? odVaOwn = freezed,Object? osVaOwn = freezed,Object? visualField = freezed,Object? iopOd = freezed,Object? iopOs = freezed,Object? orbit = freezed,Object? eyeball = freezed,Object? eyelids = freezed,Object? conjunctiva = freezed,Object? lacrimal = freezed,Object? cornea = freezed,Object? anteriorChamber = freezed,Object? iris = freezed,Object? pupil = freezed,Object? lens = freezed,Object? vitreous = freezed,Object? fundus = freezed,Object? abScanNote = freezed,Object? diagnosis = freezed,Object? icd10 = freezed,Object? recommendations = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_EyeExam(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,visitId: null == visitId ? _self.visitId : visitId // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,doctorId: freezed == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String?,examDate: freezed == examDate ? _self.examDate : examDate // ignore: cast_nullable_to_non_nullable
as String?,complaints: freezed == complaints ? _self.complaints : complaints // ignore: cast_nullable_to_non_nullable
as String?,anamnesis: freezed == anamnesis ? _self.anamnesis : anamnesis // ignore: cast_nullable_to_non_nullable
as String?,odVa: freezed == odVa ? _self.odVa : odVa // ignore: cast_nullable_to_non_nullable
as String?,osVa: freezed == osVa ? _self.osVa : osVa // ignore: cast_nullable_to_non_nullable
as String?,odSph: freezed == odSph ? _self.odSph : odSph // ignore: cast_nullable_to_non_nullable
as String?,osSph: freezed == osSph ? _self.osSph : osSph // ignore: cast_nullable_to_non_nullable
as String?,odCyl: freezed == odCyl ? _self.odCyl : odCyl // ignore: cast_nullable_to_non_nullable
as String?,osCyl: freezed == osCyl ? _self.osCyl : osCyl // ignore: cast_nullable_to_non_nullable
as String?,odAxis: freezed == odAxis ? _self.odAxis : odAxis // ignore: cast_nullable_to_non_nullable
as int?,osAxis: freezed == osAxis ? _self.osAxis : osAxis // ignore: cast_nullable_to_non_nullable
as int?,odVaCc: freezed == odVaCc ? _self.odVaCc : odVaCc // ignore: cast_nullable_to_non_nullable
as String?,osVaCc: freezed == osVaCc ? _self.osVaCc : osVaCc // ignore: cast_nullable_to_non_nullable
as String?,odVaOwn: freezed == odVaOwn ? _self.odVaOwn : odVaOwn // ignore: cast_nullable_to_non_nullable
as String?,osVaOwn: freezed == osVaOwn ? _self.osVaOwn : osVaOwn // ignore: cast_nullable_to_non_nullable
as String?,visualField: freezed == visualField ? _self.visualField : visualField // ignore: cast_nullable_to_non_nullable
as String?,iopOd: freezed == iopOd ? _self.iopOd : iopOd // ignore: cast_nullable_to_non_nullable
as String?,iopOs: freezed == iopOs ? _self.iopOs : iopOs // ignore: cast_nullable_to_non_nullable
as String?,orbit: freezed == orbit ? _self.orbit : orbit // ignore: cast_nullable_to_non_nullable
as String?,eyeball: freezed == eyeball ? _self.eyeball : eyeball // ignore: cast_nullable_to_non_nullable
as String?,eyelids: freezed == eyelids ? _self.eyelids : eyelids // ignore: cast_nullable_to_non_nullable
as String?,conjunctiva: freezed == conjunctiva ? _self.conjunctiva : conjunctiva // ignore: cast_nullable_to_non_nullable
as String?,lacrimal: freezed == lacrimal ? _self.lacrimal : lacrimal // ignore: cast_nullable_to_non_nullable
as String?,cornea: freezed == cornea ? _self.cornea : cornea // ignore: cast_nullable_to_non_nullable
as String?,anteriorChamber: freezed == anteriorChamber ? _self.anteriorChamber : anteriorChamber // ignore: cast_nullable_to_non_nullable
as String?,iris: freezed == iris ? _self.iris : iris // ignore: cast_nullable_to_non_nullable
as String?,pupil: freezed == pupil ? _self.pupil : pupil // ignore: cast_nullable_to_non_nullable
as String?,lens: freezed == lens ? _self.lens : lens // ignore: cast_nullable_to_non_nullable
as String?,vitreous: freezed == vitreous ? _self.vitreous : vitreous // ignore: cast_nullable_to_non_nullable
as String?,fundus: freezed == fundus ? _self.fundus : fundus // ignore: cast_nullable_to_non_nullable
as String?,abScanNote: freezed == abScanNote ? _self.abScanNote : abScanNote // ignore: cast_nullable_to_non_nullable
as String?,diagnosis: freezed == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String?,icd10: freezed == icd10 ? _self.icd10 : icd10 // ignore: cast_nullable_to_non_nullable
as String?,recommendations: freezed == recommendations ? _self.recommendations : recommendations // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
