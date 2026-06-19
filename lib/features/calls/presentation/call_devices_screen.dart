import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/calls_repository.dart';
import '../domain/call_device.dart';

/// Управление телефонами ресепшена: регистрация (выдаёт ключ для агента),
/// статус онлайн/офлайн, ротация ключа и активация/деактивация.
class CallDevicesScreen extends ConsumerWidget {
  const CallDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(callDevicesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/calls'),
        ),
        title: const Text('Телефоны ресепшена'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(callDevicesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDevice(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Добавить телефон'),
      ),
      body: AsyncValueWidget<List<CallDevice>>(
        value: devices,
        onRetry: () => ref.invalidate(callDevicesProvider),
        builder: (list) {
          if (list.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _DeviceTile(device: list[i]),
          );
        },
      ),
    );
  }

  Future<void> _addDevice(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<CreatedDevice>(
      context: context,
      builder: (_) => const _AddDeviceDialog(),
    );
    if (created == null) return;
    ref.invalidate(callDevicesProvider);
    if (context.mounted) {
      await _showKeyDialog(context, created, isNew: true);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smartphone, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Нет зарегистрированных телефонов',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Зарегистрируйте телефон ресепшена и введите выданный ключ\n'
              'в приложение-агент на самом телефоне.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  const _DeviceTile({required this.device});

  final CallDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    final online = device.online;
    return ListTile(
      leading: Tooltip(
        message: online ? 'На связи' : 'Офлайн',
        child: Icon(Icons.circle, size: 14, color: online ? Colors.green : Colors.grey),
      ),
      title: Row(
        children: [
          Text(device.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: device.isActive ? null : muted,
              )),
          if (!device.isActive) ...[
            const SizedBox(width: 8),
            const _Pill(text: 'выключен', color: Colors.grey),
          ],
        ],
      ),
      subtitle: Text(_subtitle()),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => _onAction(context, ref, v),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'rotate', child: Text('Сменить ключ')),
          PopupMenuItem(
            value: 'toggle',
            child: Text(device.isActive ? 'Выключить' : 'Включить'),
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[];
    if (device.phoneNumber != null && device.phoneNumber!.isNotEmpty) {
      parts.add(device.phoneNumber!);
    }
    parts.add(device.online
        ? 'на связи'
        : 'был(а) ${_lastSeenLabel(device.lastSeenAt)}');
    if (device.appVersion != null) parts.add('v${device.appVersion}');
    return parts.join('  ·  ');
  }

  Future<void> _onAction(BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(callsRepositoryProvider);
    try {
      if (action == 'rotate') {
        final ok = await _confirm(context, 'Сменить ключ?',
            'Старый ключ сразу перестанет работать. На телефоне нужно будет ввести новый ключ.');
        if (ok != true) return;
        final created = await repo.rotateKey(device.id);
        ref.invalidate(callDevicesProvider);
        if (context.mounted) await _showKeyDialog(context, created, isNew: false);
      } else if (action == 'toggle') {
        await repo.updateDevice(device.id, isActive: !device.isActive);
        ref.invalidate(callDevicesProvider);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

/// Диалог регистрации телефона: название, SIM-номер, филиал.
class _AddDeviceDialog extends ConsumerStatefulWidget {
  const _AddDeviceDialog();

  @override
  ConsumerState<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends ConsumerState<_AddDeviceDialog> {
  final _label = TextEditingController();
  final _phone = TextEditingController();
  String? _branchId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Укажите название телефона');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await ref.read(callsRepositoryProvider).createDevice(
            label: label,
            phoneNumber: _phone.text.trim(),
            branchId: _branchId,
          );
      if (mounted) Navigator.of(context).pop(created);
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchOptionsProvider);
    return AlertDialog(
      title: const Text('Новый телефон ресепшена'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _label,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Название *',
                hintText: 'Ресепшн 1 (Главный)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Номер SIM (необязательно)',
                hintText: '+998 90 000 00 00',
              ),
            ),
            const SizedBox(height: 12),
            branches.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Не удалось загрузить филиалы'),
              data: (list) => DropdownButtonFormField<String?>(
                initialValue: _branchId,
                decoration: const InputDecoration(labelText: 'Филиал'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— не указан —')),
                  ...list.map((b) =>
                      DropdownMenuItem(value: b.id, child: Text(b.name))),
                ],
                onChanged: (v) => setState(() => _branchId = v),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Создать'),
        ),
      ],
    );
  }
}

/// Показывает выданный ключ ОДИН раз + памятку для настройки агента.
Future<void> _showKeyDialog(BuildContext context, CreatedDevice created,
    {required bool isNew}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(isNew ? 'Телефон зарегистрирован' : 'Новый ключ выдан'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сохраните ключ сейчас — он показывается только один раз. '
            'Введите его и адрес сервера в приложение-агент на телефоне.',
          ),
          const SizedBox(height: 16),
          _CopyField(label: 'Адрес сервера', value: ApiConstants.apiBase),
          const SizedBox(height: 12),
          _CopyField(label: 'Ключ устройства', value: created.apiKey),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Готово'),
        ),
      ],
    ),
  );
}

class _CopyField extends StatelessWidget {
  const _CopyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              IconButton(
                tooltip: 'Копировать',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Скопировано'),
                          duration: Duration(seconds: 1)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<bool?> _confirm(BuildContext context, String title, String body) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Подтвердить')),
      ],
    ),
  );
}

/// «5 мин назад» / «никогда» из ISO-UTC.
String _lastSeenLabel(String? iso) {
  if (iso == null) return 'не выходил на связь';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final dt = (parsed.isUtc
          ? parsed
          : DateTime.utc(parsed.year, parsed.month, parsed.day, parsed.hour,
              parsed.minute, parsed.second))
      .toLocal();
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'только что';
  if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
  if (diff.inHours < 24) return '${diff.inHours} ч назад';
  return '${diff.inDays} дн назад';
}
