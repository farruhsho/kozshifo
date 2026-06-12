import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/flow_labels.dart';
import '../../../core/utils/formatters.dart';
import '../data/search_repository.dart';
import '../domain/search_results.dart';

/// Opens the global Smart Search palette (Ctrl+K / Ctrl+F): one input that
/// finds patients, visits and receipts at once. Esc closes (dialog default),
/// ArrowUp/ArrowDown move the highlight across all sections, Enter opens it.
Future<void> showSearchOverlay(BuildContext context, WidgetRef ref) {
  final repository = ref.read(searchRepositoryProvider);
  return showDialog<void>(
    context: context,
    builder: (_) => _SearchOverlay(repository: repository),
  );
}

/// One row of the flattened result list (headers excluded — the highlight and
/// Enter only ever land on openable rows).
class _Entry {
  const _Entry({
    required this.section,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.patientId,
  });

  final String section;
  final IconData icon;
  final String title;
  final String subtitle;

  /// Everything in Smart Search resolves to a patient card; a receipt without
  /// a linked patient stays visible but is not openable.
  final String? patientId;
}

class _SearchOverlay extends StatefulWidget {
  const _SearchOverlay({required this.repository});

  final SearchRepository repository;

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  static const _minChars = 2;
  static const _debounce = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  Timer? _debounceTimer;

  SearchResults? _results;
  bool _loading = false;
  String? _error;
  int _highlight = 0;

  /// Monotonic request counter — a slow earlier response can never overwrite
  /// the results of a newer query.
  int _requestSeq = 0;

  /// One key per flattened entry, regenerated with each result set, so the
  /// keyboard highlight can be scrolled into view.
  List<GlobalKey> _keys = const [];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    _debounceTimer?.cancel();
    final q = raw.trim();
    if (q.length < _minChars) {
      setState(() {
        _results = null;
        _loading = false;
        _error = null;
        _highlight = 0;
        _keys = const [];
      });
      return;
    }
    _debounceTimer = Timer(_debounce, () => _search(q));
  }

  Future<void> _search(String q) async {
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.repository.search(q);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _results = results;
        _loading = false;
        _highlight = 0;
        _keys = List.generate(_entriesOf(results).length, (_) => GlobalKey());
      });
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _results = null;
        _loading = false;
        _error = '$e';
        _keys = const [];
      });
    }
  }

  List<_Entry> _entriesOf(SearchResults r) => [
    for (final p in r.patients)
      _Entry(
        section: 'Пациенты',
        icon: Icons.person_outline,
        title: p.fullName,
        subtitle: [
          p.mrn,
          if (p.phone != null && p.phone!.isNotEmpty) p.phone!,
        ].join(' · '),
        patientId: p.id,
      ),
    for (final v in r.visits)
      _Entry(
        section: 'Визиты',
        icon: Icons.event_note_outlined,
        title: v.visitNo,
        subtitle: '${v.patientName} · ${flowStatusLabel(v.flowStatus)}',
        patientId: v.patientId,
      ),
    for (final c in r.receipts)
      _Entry(
        section: 'Чеки',
        icon: Icons.receipt_long_outlined,
        title: c.receiptNo,
        subtitle: formatMoney(c.amount),
        patientId: c.patientId,
      ),
  ];

  void _open(_Entry entry) {
    final patientId = entry.patientId;
    if (patientId == null) return;
    // Grab the router before popping: the dialog context dies with the pop.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go('/patients/$patientId/card');
  }

  void _moveHighlight(int delta, List<_Entry> entries) {
    if (entries.isEmpty) return;
    setState(() {
      _highlight = (_highlight + delta).clamp(0, entries.length - 1);
    });
    // Keep the highlighted row visible inside the scrolling result list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _highlight >= _keys.length) return;
      final ctx = _keys[_highlight].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 80),
        );
      }
    });
  }

  void _openHighlighted(List<_Entry> entries) {
    if (entries.isEmpty || _highlight >= entries.length) return;
    _open(entries[_highlight]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _results;
    final entries = results == null ? const <_Entry>[] : _entriesOf(results);

    // The TextField keeps focus the whole time; arrows/Enter bubble up from
    // it to this CallbackShortcuts before DefaultTextEditingShortcuts (the
    // app root) can turn them into caret movements.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Only claim the keys while there is something to navigate — with no
        // results, arrows/Enter keep their normal text-field behaviour.
        if (entries.isNotEmpty) ...{
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _moveHighlight(1, entries),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _moveHighlight(-1, entries),
          const SingleActivator(LogicalKeyboardKey.enter): () =>
              _openHighlighted(entries),
          const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
              _openHighlighted(entries),
        },
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    hintText: 'Поиск: пациент, телефон, карта, визит, чек…',
                    helperText:
                        '↑↓ — выбор, Enter — открыть, Esc — закрыть (от $_minChars символов)',
                  ),
                ),
              ),
              Flexible(child: _resultsArea(theme, entries)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultsArea(ThemeData theme, List<_Entry> entries) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }
    if (_results == null) {
      // Nothing searched yet (or query below the minimum) — stay compact.
      return const SizedBox(height: 8);
    }
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Ничего не найдено',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final rows = <Widget>[];
    String? section;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (e.section != section) {
        section = e.section;
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              section,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      }
      rows.add(
        ListTile(
          key: i < _keys.length ? _keys[i] : null,
          dense: true,
          selected: i == _highlight,
          leading: Icon(e.icon),
          title: Text(e.title, overflow: TextOverflow.ellipsis),
          subtitle: Text(e.subtitle, overflow: TextOverflow.ellipsis),
          enabled: e.patientId != null,
          onTap: e.patientId == null ? null : () => _open(e),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 8),
      children: rows,
    );
  }
}
