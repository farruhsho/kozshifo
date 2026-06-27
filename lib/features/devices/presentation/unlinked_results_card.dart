import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/devices_repository.dart';

/// «Несвязанные результаты приборов» — orphan device results that arrived without a
/// visit (the прибор sent a measurement before the patient was matched). Staff
/// attach one to the CURRENT visit with a tap. Renders nothing when there are none.
class UnlinkedResultsCard extends ConsumerWidget {
  const UnlinkedResultsCard({super.key, required this.visitId});

  final String visitId;

  Future<void> _link(BuildContext context, WidgetRef ref, String resultId) async {
    try {
      await ref.read(devicesRepositoryProvider).linkResult(resultId, visitId);
      ref.invalidate(unlinkedDeviceResultsProvider);
      ref.invalidate(visitDeviceResultsProvider(visitId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Результат привязан к визиту')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(unlinkedDeviceResultsProvider).maybeWhen(
          data: (results) {
            if (results.isEmpty) return const SizedBox.shrink();
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.link_off, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Несвязанные результаты приборов',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Пришли без визита — привяжите нужный к текущему пациенту.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    for (final r in results)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.summary, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${r.resultType} · '
                          '${r.measuredAt.length >= 10 ? r.measuredAt.substring(0, 10) : r.measuredAt}',
                        ),
                        trailing: TextButton(
                          onPressed: () => _link(context, ref, r.id),
                          child: const Text('Привязать'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }
}
