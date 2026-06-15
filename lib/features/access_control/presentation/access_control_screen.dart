import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/access_control_repository.dart';
import '../domain/access_event.dart';
import '../domain/enrollment.dart';
import '../domain/face_terminal.dart';

/// Face ID / контроль доступа: подключение терминалов по LAN, привязка лиц
/// сотрудников и журнал распознаваний. Управление — под access_control.manage.
class AccessControlScreen extends StatelessWidget {
  const AccessControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Face ID · Контроль доступа'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Терминалы'),
            Tab(text: 'Сотрудники'),
            Tab(text: 'События'),
          ]),
        ),
        body: const TabBarView(children: [
          _TerminalsTab(),
          _StaffTab(),
          _EventsTab(),
        ]),
      ),
    );
  }
}

void _showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
  ));
}

String _fmtTime(DateTime dt) {
  final l = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}';
}

// ═══ Терминалы ════════════════════════════════════════════════════════════════

class _TerminalsTab extends ConsumerWidget {
  const _TerminalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminals = ref.watch(terminalsProvider);
    final user = ref.watch(authControllerProvider).user;
    final canManage = user?.can('access_control.manage') ?? false;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openCreate(context, ref),
              icon: const Icon(Icons.add_link),
              label: const Text('Подключить терминал'),
            )
          : null,
      body: AsyncValueWidget<List<FaceTerminal>>(
        value: terminals,
        onRetry: () => ref.invalidate(terminalsProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Терминалов пока нет.\nНажмите «Подключить терминал» и введите '
                  'IP, логин и пароль устройства в локальной сети.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = items[i];
              final online = t.online;
              final model = t.deviceInfo?['model'] as String?;
              return ListTile(
                leading: Icon(
                  online ? Icons.videocam : Icons.videocam_off_outlined,
                  color: online ? Colors.green : scheme.outline,
                ),
                title: Text(t.name),
                subtitle: Text([
                  '${t.host}:${t.port}',
                  ?model,
                  if (t.lastSeen != null) 'проверен ${_fmtTime(t.lastSeen!)}',
                ].join(' · ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(online ? 'онлайн' : 'оффлайн'),
                      labelStyle: TextStyle(
                          color: online ? Colors.green.shade800 : scheme.outline),
                      backgroundColor:
                          online ? Colors.green.withValues(alpha: 0.12) : null,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                    if (canManage) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Проверить соединение',
                        icon: const Icon(Icons.wifi_tethering),
                        onPressed: () => _test(context, ref, t),
                      ),
                      _TerminalMenu(terminal: t),
                    ],
                  ],
                ),
                onTap: canManage ? () => _openEdit(context, ref, t) : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _test(BuildContext context, WidgetRef ref, FaceTerminal t) async {
    _showSnack(context, 'Проверка ${t.name}…');
    try {
      final res = await ref.read(accessControlRepositoryProvider).testTerminal(t.id);
      ref.invalidate(terminalsProvider);
      if (!context.mounted) return;
      if (res.online) {
        _showSnack(context,
            'Онлайн: ${res.model ?? '—'} · прошивка ${res.firmware ?? '—'}');
      } else {
        _showSnack(context, 'Недоступен: ${res.error ?? 'нет ответа'}', error: true);
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, '$e', error: true);
    }
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _TerminalDialog(),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(terminalsProvider);
      _showSnack(context, 'Терминал подключён');
    }
  }

  Future<void> _openEdit(
      BuildContext context, WidgetRef ref, FaceTerminal t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _TerminalDialog(terminal: t),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(terminalsProvider);
      _showSnack(context, 'Терминал обновлён');
    }
  }
}

class _TerminalMenu extends ConsumerWidget {
  const _TerminalMenu({required this.terminal});

  final FaceTerminal terminal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'configure-push') {
          await _configurePush(context, ref);
        } else if (value == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Удалить «${terminal.name}»?'),
              content: const Text(
                  'Терминал будет отключён от системы. Сотрудники и их привязки '
                  'не удаляются.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Удалить')),
              ],
            ),
          );
          if (confirmed != true) return;
          try {
            await ref
                .read(accessControlRepositoryProvider)
                .deleteTerminal(terminal.id);
            ref.invalidate(terminalsProvider);
            if (context.mounted) _showSnack(context, 'Терминал удалён');
          } catch (e) {
            if (context.mounted) _showSnack(context, '$e', error: true);
          }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: 'configure-push',
            child: Text('Настроить автоотправку событий')),
        PopupMenuItem(value: 'delete', child: Text('Удалить')),
      ],
    );
  }

  /// Один клик: просим терминал слать события на наш webhook (без захода в
  /// веб-меню камеры). Сервер берёт LAN-IP сам; на вебе подсказываем адрес,
  /// с которого открыт интерфейс.
  Future<void> _configurePush(BuildContext context, WidgetRef ref) async {
    _showSnack(context, 'Настраиваю отправку событий на «${terminal.name}»…');
    try {
      final res = await ref.read(accessControlRepositoryProvider).configurePush(
            terminal.id,
            serverHost: kIsWeb ? Uri.base.host : null,
            serverPort: kIsWeb ? Uri.base.port : null,
          );
      if (!context.mounted) return;
      _showSnack(
        context,
        res.configured
            ? 'Готово — камера будет отправлять события на сервер'
            : 'Не удалось настроить камеру: ${res.error ?? 'нет ответа'}',
        error: !res.configured,
      );
    } catch (e) {
      if (context.mounted) _showSnack(context, '$e', error: true);
    }
  }
}

/// Подключение / редактирование терминала. При создании пароль обязателен; при
/// редактировании пустой пароль = не менять.
class _TerminalDialog extends ConsumerStatefulWidget {
  const _TerminalDialog({this.terminal});

  final FaceTerminal? terminal;

  @override
  ConsumerState<_TerminalDialog> createState() => _TerminalDialogState();
}

class _TerminalDialogState extends ConsumerState<_TerminalDialog> {
  late final _name = TextEditingController(text: widget.terminal?.name ?? '');
  late final _host = TextEditingController(text: widget.terminal?.host ?? '');
  late final _port =
      TextEditingController(text: (widget.terminal?.port ?? 80).toString());
  late final _username =
      TextEditingController(text: widget.terminal?.username ?? 'admin');
  final _password = TextEditingController();
  late final _doorNo =
      TextEditingController(text: (widget.terminal?.doorNo ?? 1).toString());
  bool _saving = false;

  bool get _isEdit => widget.terminal != null;

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    _doorNo.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      _name.text.trim().isNotEmpty &&
      _host.text.trim().isNotEmpty &&
      _username.text.trim().isNotEmpty &&
      int.tryParse(_port.text.trim()) != null &&
      (_isEdit || _password.text.isNotEmpty);

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(accessControlRepositoryProvider);
    final pwd = _password.text.isEmpty ? null : _password.text;
    try {
      if (_isEdit) {
        await repo.updateTerminal(
          widget.terminal!.id,
          name: _name.text.trim(),
          host: _host.text.trim(),
          port: int.parse(_port.text.trim()),
          username: _username.text.trim(),
          password: pwd,
          doorNo: int.tryParse(_doorNo.text.trim()),
        );
      } else {
        await repo.createTerminal(
          name: _name.text.trim(),
          host: _host.text.trim(),
          port: int.parse(_port.text.trim()),
          username: _username.text.trim(),
          password: _password.text,
          doorNo: int.tryParse(_doorNo.text.trim()) ?? 1,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack(context, '$e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Терминал ${widget.terminal!.name}' : 'Новый терминал'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Название', hintText: 'Главный вход'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _host,
                      decoration: const InputDecoration(
                          labelText: 'IP в сети', hintText: '192.168.1.50'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _port,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Порт'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Логин устройства'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Пароль устройства',
                  helperText: _isEdit ? 'Пусто — не менять' : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _doorNo,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Номер двери/реле', hintText: '1'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: _saving
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? 'Сохранить' : 'Подключить'),
        ),
      ],
    );
  }
}

// ═══ Сотрудники ═══════════════════════════════════════════════════════════════

class _StaffTab extends ConsumerStatefulWidget {
  const _StaffTab();

  @override
  ConsumerState<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends ConsumerState<_StaffTab> {
  String? _terminalId;
  String? _busyUserId; // a per-row in-flight guard

  @override
  Widget build(BuildContext context) {
    final terminals = ref.watch(terminalsProvider);
    final enrollment = ref.watch(enrollmentProvider);
    final user = ref.watch(authControllerProvider).user;
    final canManage = user?.can('access_control.manage') ?? false;

    return AsyncValueWidget<List<FaceTerminal>>(
      value: terminals,
      onRetry: () => ref.invalidate(terminalsProvider),
      builder: (terms) {
        if (terms.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Сначала подключите терминал на вкладке «Терминалы», затем '
                'привязывайте к нему сотрудников.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        _terminalId ??= terms.first.id;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: DropdownButtonFormField<String>(
                initialValue: _terminalId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Терминал для привязки', border: OutlineInputBorder()),
                items: [
                  for (final t in terms)
                    DropdownMenuItem(
                        value: t.id,
                        child: Text('${t.name} (${t.host})',
                            overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _terminalId = v),
              ),
            ),
            Expanded(
              child: AsyncValueWidget<List<EnrollmentRow>>(
                value: enrollment,
                onRetry: () => ref.invalidate(enrollmentProvider),
                builder: (rows) {
                  if (rows.isEmpty) {
                    return const Center(child: Text('Сотрудников пока нет.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) =>
                        _staffTile(context, rows[i], canManage),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _staffTile(BuildContext context, EnrollmentRow row, bool canManage) {
    final scheme = Theme.of(context).colorScheme;
    final enrolled = row.enrolled;
    final busy = _busyUserId == row.userId;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            enrolled ? Colors.green.withValues(alpha: 0.15) : scheme.surfaceContainerHighest,
        child: Icon(enrolled ? Icons.face_retouching_natural : Icons.face_outlined,
            color: enrolled ? Colors.green.shade700 : scheme.outline),
      ),
      title: Text(row.fullName),
      subtitle: Text(enrolled
          ? '${row.email} · ID на устройстве: ${row.faceidEmployeeNo}'
          : '${row.email} · не привязан'),
      trailing: !canManage
          ? null
          : busy
              ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : PopupMenuButton<String>(
                  onSelected: (v) => _action(v, row),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'enroll', child: Text('Привязать к терминалу')),
                    const PopupMenuItem(value: 'face', child: Text('Загрузить фото лица')),
                    if (enrolled)
                      const PopupMenuItem(value: 'remove', child: Text('Снять привязку')),
                  ],
                ),
    );
  }

  Future<void> _action(String action, EnrollmentRow row) async {
    final terminalId = _terminalId;
    if (terminalId == null) return;
    final repo = ref.read(accessControlRepositoryProvider);
    setState(() => _busyUserId = row.userId);
    try {
      switch (action) {
        case 'enroll':
          final res = await repo.enroll(terminalId, row.userId);
          _reportEnroll(res, 'Привязан (ID ${res.faceidEmployeeNo})');
        case 'remove':
          final res = await repo.removeEnrollment(terminalId, row.userId);
          if (mounted) {
            _showSnack(context,
                res.error == null
                    ? 'Привязка снята'
                    : 'Привязка снята локально, но устройство недоступно: ${res.error}',
                error: res.error != null);
          }
        case 'face':
          final picked = await FilePicker.platform.pickFiles(
              type: FileType.image, withData: true);
          final file = picked?.files.firstOrNull;
          final bytes = file?.bytes;
          if (file == null || bytes == null) break; // отмена
          final res = await repo.uploadFace(
              terminalId: terminalId,
              userId: row.userId,
              bytes: bytes,
              filename: file.name);
          _reportEnroll(res,
              res.faceUploaded ? 'Фото отправлено на терминал' : 'Фото сохранено');
      }
      ref.invalidate(enrollmentProvider);
    } catch (e) {
      if (mounted) _showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  void _reportEnroll(EnrollResult res, String okMsg) {
    if (!mounted) return;
    if (res.error != null) {
      _showSnack(context,
          'Сохранено, но терминал недоступен: ${res.error}', error: true);
    } else {
      _showSnack(context, okMsg);
    }
  }
}

// ═══ События ══════════════════════════════════════════════════════════════════

class _EventsTab extends ConsumerWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(accessEventsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => ref.invalidate(accessEventsProvider),
        tooltip: 'Обновить',
        child: const Icon(Icons.refresh),
      ),
      body: AsyncValueWidget<List<AccessEvent>>(
        value: events,
        onRetry: () => ref.invalidate(accessEventsProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Событий распознавания пока нет.\nОни появятся, когда сотрудник '
                  'пройдёт через терминал.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = items[i];
              final isIn = e.direction == 'in';
              return ListTile(
                leading: Icon(
                  isIn ? Icons.login : Icons.logout,
                  color: isIn ? Colors.green : scheme.tertiary,
                ),
                title: Text(e.userFullName ?? 'Сотрудник'),
                subtitle: Text(isIn ? 'Вход' : 'Выход'),
                trailing: Text(_fmtTime(e.occurredAt)),
              );
            },
          );
        },
      ),
    );
  }
}
