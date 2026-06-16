// Queue screen auto-refresh hardening: the periodic (5s) refresh must NOT stack
// requests while a previous fetch is still in flight, and the timer must be
// cancelled cleanly on dispose (no pending Timer / hang). Providers overridden,
// no real Dio traffic; the fake repo gates its list() future with a Completer so
// the "fetch in flight" window is deterministic.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/queue/data/queue_repository.dart';
import 'package:kozshifo/features/queue/domain/queue_ticket.dart';
import 'package:kozshifo/features/queue/presentation/queue_screen.dart';

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    AuthStatus.authenticated,
    AuthUser(
      id: 'u1',
      email: 'diagnost@kozshifo.uz',
      fullName: 'Диагност',
      branchId: 'br-1',
      permissions: ['queue.read', 'queue.manage'],
    ),
  );
}

/// Repo whose list() stays pending until the test completes it — so the
/// "fetch in flight" window is deterministic. Counts how many times it ran.
class _FakeQueueRepository extends QueueRepository {
  _FakeQueueRepository() : super(Dio());

  int listCalls = 0;
  Completer<List<QueueTicket>>? pending;

  @override
  Future<List<QueueTicket>> list({
    required String branchId,
    String? track,
    bool activeOnly = true,
  }) {
    listCalls++;
    return (pending = Completer<List<QueueTicket>>()).future;
  }

  void resolve() {
    pending?.complete(const <QueueTicket>[]);
    pending = null;
  }

  @override
  Future<List<Specialist>> specialists(String branchId) async =>
      const <Specialist>[];
}

void main() {
  testWidgets(
    '5s auto-refresh skips ticks while a fetch is in flight and disposes '
    'without a pending timer',
    (tester) async {
      final repo = _FakeQueueRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_FakeAuthController.new),
            queueRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: QueueScreen()),
        ),
      );

      // Initial build kicks off exactly one list() — still in flight.
      await tester.pump();
      expect(repo.listCalls, 1);

      // A 5s tick fires while #1 is still loading → guard skips it, no 2nd GET.
      await tester.pump(const Duration(seconds: 6));
      expect(repo.listCalls, 1);

      // Resolve #1; the next tick is now allowed to refresh the list.
      repo.resolve();
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(repo.listCalls, 2);

      // Resolve #2 and tear the screen down — State.dispose() must cancel the
      // periodic timer, leaving no pending Timer (the classic hang/leak).
      repo.resolve();
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
