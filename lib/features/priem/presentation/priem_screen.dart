import 'package:flutter/material.dart';

import '../../queue/presentation/queue_screen.dart';

/// Объединённый кабинет врача «Приём» — две вкладки:
///   • «Моя очередь» — живая очередь к врачу (V), только СВОИ пациенты
///     (записанные на этого врача) + общий нераспределённый пул. Вызов
///     следующего → осмотр → «Готово» (поток к кассиру).
///   • «Лечение» — процедурные Л-талоны: вызвать / принять / завершить курс.
/// Каждая вкладка — встроенный [QueueScreen] (без собственного AppBar). Диагност
/// и процедурная сестра по-прежнему пользуются отдельными экранами.
class PriemScreen extends StatelessWidget {
  const PriemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Приём'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Моя очередь', icon: Icon(Icons.assignment_ind_outlined)),
              Tab(text: 'Лечение', icon: Icon(Icons.medication_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            QueueScreen(
              personal: true,
              track: 'doctor',
              embedded: true,
              ownOnly: true,
            ),
            QueueScreen(
              personal: true,
              track: 'treatment',
              embedded: true,
            ),
          ],
        ),
      ),
    );
  }
}
