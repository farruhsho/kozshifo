import 'package:freezed_annotation/freezed_annotation.dart';

part 'eye_exam.freezed.dart';
part 'eye_exam.g.dart';

/// Ophthalmology exam — the «ОКУЛИСТ КУРИГИ» section of MoH Form 025-8
/// (mirrors backend `EyeExamOut`). Clinical decimals (sph/cyl/IOP) arrive as
/// decimal strings — never parsed to double for storage, only for display.
@freezed
abstract class EyeExam with _$EyeExam {
  const EyeExam._();

  const factory EyeExam({
    required String id,
    required String visitId,
    required String patientId,
    String? doctorId,
    String? examDate,

    // Subjective
    String? complaints,
    String? anamnesis,

    // Refraction per eye
    String? odVa,
    String? osVa,
    String? odSph,
    String? osSph,
    String? odCyl,
    String? osCyl,
    int? odAxis,
    int? osAxis,
    String? odVaCc,
    String? osVaCc,
    // VA with the patient's own glasses/lenses (TZ «своими» — optional)
    String? odVaOwn,
    String? osVaOwn,

    // Visual field — поле зрения (TZ Modul 4)
    String? visualField,

    // Tonometry, mmHg
    String? iopOd,
    String? iopOs,

    // Structures, in form order
    String? orbit,
    String? eyeball,
    String? eyelids,
    String? conjunctiva,
    String? lacrimal,
    String? cornea,
    String? anteriorChamber,
    String? iris,
    String? pupil,
    String? lens,
    String? vitreous,
    String? fundus,

    String? abScanNote,

    // Conclusion
    String? diagnosis,
    String? icd10,
    String? recommendations,

    String? createdAt,
    String? updatedAt,
  }) = _EyeExam;

  factory EyeExam.fromJson(Map<String, dynamic> json) => _$EyeExamFromJson(json);

  /// «Visus OD 0.6 ; sph -1.25 cyl -0.50 ax 170° = 1.0» — summary line for lists.
  String visusLine(String eye) {
    final va = eye == 'OD' ? odVa : osVa;
    final sph = eye == 'OD' ? odSph : osSph;
    final cyl = eye == 'OD' ? odCyl : osCyl;
    final axis = eye == 'OD' ? odAxis : osAxis;
    final cc = eye == 'OD' ? odVaCc : osVaCc;
    final corr = [
      if (sph != null) 'sph $sph',
      if (cyl != null) 'cyl $cyl',
      if (axis != null) 'ax $axis°',
    ].join(' ');
    return 'Visus $eye ${va ?? '—'}${corr.isEmpty ? '' : ' ; $corr'}${cc == null ? '' : ' = $cc'}';
  }
}
