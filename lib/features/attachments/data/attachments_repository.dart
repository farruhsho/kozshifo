import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/attachment.dart';

final attachmentsRepositoryProvider = Provider<AttachmentsRepository>(
    (ref) => AttachmentsRepository(ref.watch(dioProvider)));

class AttachmentsRepository {
  AttachmentsRepository(this._dio);

  final Dio _dio;

  Future<List<Attachment>> list(String patientId,
      {String? kind, String? operationId}) async {
    try {
      final resp = await _dio.get(
        '/patients/$patientId/attachments',
        queryParameters: {
          'kind': ?kind,
          'operation_id': ?operationId,
        },
      );
      return (resp.data as List<dynamic>)
          .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Uploads a document (PDF/image) onto the patient's record. [kind] is one of
  /// uzi | hiv | lab | other; an optional visit/operation links the document for
  /// context (the HIV analysis stapled to a scheduled operation, etc.).
  Future<Attachment> upload({
    required String patientId,
    required String kind,
    required List<int> bytes,
    required String filename,
    String? visitId,
    String? operationId,
    String? note,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'kind': kind,
        'visit_id': ?visitId,
        'operation_id': ?operationId,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
      final resp =
          await _dio.post('/patients/$patientId/attachments', data: form);
      return Attachment.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> delete(String attachmentId) async {
    try {
      await _dio.delete('/attachments/$attachmentId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Raw bytes of a stored attachment (for preview/download).
  Future<Uint8List> fileBytes(String attachmentId) async {
    try {
      final resp = await _dio.get(
        '/attachments/$attachmentId/file',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data as List<int>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// All documents on a patient's record (newest first).
final patientAttachmentsProvider = FutureProvider.autoDispose
    .family<List<Attachment>, String>((ref, patientId) =>
        ref.watch(attachmentsRepositoryProvider).list(patientId));
