import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// A lightweight patient option for picker widgets (id + display name + MRN).
typedef PatientOption = ({String id, String name, String mrn});

/// Searches patients by free text (name / MRN / phone) for picker widgets.
/// Reusable across features (e.g. lab referrals); formerly lived in the
/// now-removed scheduling repository.
final patientSearchProvider = FutureProvider.autoDispose
    .family<List<PatientOption>, String>((ref, q) async {
  final dio = ref.watch(dioProvider);
  try {
    final resp = await dio.get('/patients',
        queryParameters: {'q': ?q.isEmpty ? null : q, 'limit': 20});
    final items = (resp.data as Map<String, dynamic>)['items'] as List<dynamic>;
    return [
      for (final e in items)
        (
          id: (e as Map<String, dynamic>)['id'] as String,
          name: [e['last_name'], e['first_name'], e['middle_name']]
              .where((x) => x != null && (x as String).isNotEmpty)
              .join(' '),
          mrn: (e['mrn'] as String?) ?? '',
        ),
    ];
  } on DioException catch (e) {
    throw ApiException.from(e);
  }
});
