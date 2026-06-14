import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/file_saver.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/cameras_repository.dart';
import '../domain/camera.dart';

/// IP-камеры: подключить камеру по IP (логин/пароль) и смотреть живой поток.
/// Браузер не умеет RTSP, поэтому живой просмотр = опрос кадра-снимка (~1/сек),
/// который бэкенд проксирует с камеры. Кнопка «Снимок» сохраняет текущий кадр.
class CamerasScreen extends ConsumerWidget {
  const CamerasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameras = ref.watch(camerasListProvider);
    final canManage =
        ref.watch(authControllerProvider).user?.can('cameras.manage') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Камеры'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => ref.invalidate(camerasListProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showAddCameraDialog(context, ref),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Добавить камеру'),
            )
          : null,
      body: AsyncValueWidget<List<Camera>>(
        value: cameras,
        onRetry: () => ref.invalidate(camerasListProvider),
        builder: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_outlined, size: 48),
                  const SizedBox(height: 12),
                  const Text('Камеры не добавлены'),
                  if (canManage) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Нажмите «Добавить камеру» и введите IP, логин и пароль.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            );
          }
          // Адаптивная сетка: широкий экран — по 2 камеры в ряд.
          final wide = MediaQuery.sizeOf(context).width >= 900;
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: wide ? 2 : 1,
            childAspectRatio: 16 / 12,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              for (final c in items) _CameraCard(camera: c, canManage: canManage),
            ],
          );
        },
      ),
    );
  }
}

/// Одна камера: живой просмотр опросом снимка + управление.
class _CameraCard extends ConsumerStatefulWidget {
  const _CameraCard({required this.camera, required this.canManage});

  final Camera camera;
  final bool canManage;

  @override
  ConsumerState<_CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends ConsumerState<_CameraCard> {
  static const _interval = Duration(seconds: 1);

  Timer? _timer;
  Uint8List? _frame;
  String? _error;
  bool _loading = false; // re-entrancy guard: skip a tick if the last is in flight
  bool _busy = false; // a manage action (test/delete) is running
  bool _capturing = false; // a «Снимок» save is in flight

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(_interval, (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_loading || !mounted) return;
    _loading = true;
    try {
      final bytes = await ref.read(camerasRepositoryProvider).snapshot(widget.camera.id);
      if (!mounted) return;
      setState(() {
        _frame = bytes;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : '$e');
    } finally {
      _loading = false;
    }
  }

  Future<void> _capture() async {
    final frame = _frame;
    if (frame == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final name = 'snapshot-${widget.camera.name}-'
          '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = await saveBytes(frame, name, 'image/jpeg');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(path == null ? 'Снимок сохранён' : 'Снимок: $path')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _test() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(camerasRepositoryProvider).test(widget.camera.id);
      if (!mounted) return;
      final msg = r.online
          ? 'Камера на связи${r.model != null ? ' · ${r.model}' : ''}'
          : 'Камера недоступна: ${r.error ?? 'нет ответа'}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      ref.invalidate(camerasListProvider);
    } catch (e) {
      if (mounted) _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить камеру?'),
        content: Text('«${widget.camera.name}» будет удалена из списка.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(camerasRepositoryProvider).delete(widget.camera.id);
      ref.invalidate(camerasListProvider);
    } catch (e) {
      if (mounted) _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snackError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e is ApiException ? e.message : '$e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.camera;
    final scheme = Theme.of(context).colorScheme;
    // «Живой», пока есть свежий кадр и нет ошибки последнего опроса.
    final live = _frame != null && _error == null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.videocam_outlined),
            title: Text(c.name, overflow: TextOverflow.ellipsis),
            subtitle: Text('${c.address} · канал ${c.channelNo}'
                '${c.branchName != null ? ' · ${c.branchName}' : ''}'),
            trailing: _LiveDot(live: live),
          ),
          // Видео-область 16:9 на тёмном фоне.
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: _frame != null
                  ? Image.memory(
                      _frame!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true, // без мигания между кадрами
                      errorBuilder: (_, _, _) =>
                          const _Placeholder(text: 'Кадр не отображается'),
                    )
                  : _Placeholder(
                      text: _error == null
                          ? 'Подключение…'
                          : 'Нет сигнала',
                      detail: _error,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: [
                if (widget.canManage)
                  TextButton.icon(
                    onPressed: _busy ? null : _test,
                    icon: const Icon(Icons.wifi_tethering, size: 18),
                    label: const Text('Проверить'),
                  ),
                TextButton.icon(
                  onPressed: (_frame == null || _capturing) ? null : _capture,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Снимок'),
                ),
                if (widget.canManage)
                  TextButton.icon(
                    onPressed: _busy ? null : _delete,
                    icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                    label: Text('Удалить', style: TextStyle(color: scheme.error)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.live});
  final bool live;

  @override
  Widget build(BuildContext context) {
    final color = live ? Colors.red : Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 4),
        Text(live ? 'LIVE' : 'офлайн',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text, this.detail});
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 36),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(color: Colors.white70)),
        if (detail != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(detail!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────────── add-camera dialog ─────────────────────────────

Future<void> _showAddCameraDialog(BuildContext context, WidgetRef ref) async {
  final added = await showDialog<bool>(
    context: context,
    builder: (_) => const _AddCameraDialog(),
  );
  if (added == true) ref.invalidate(camerasListProvider);
}

/// Форма подключения камеры по IP. Пароль — write-only на сервере. Мирорит
/// форм-паттерн write_off_dialog: инлайн-ошибка, _canSave, спиннер на кнопке.
class _AddCameraDialog extends ConsumerStatefulWidget {
  const _AddCameraDialog();

  @override
  ConsumerState<_AddCameraDialog> createState() => _AddCameraDialogState();
}

class _AddCameraDialogState extends ConsumerState<_AddCameraDialog> {
  final _name = TextEditingController();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '80');
  final _username = TextEditingController(text: 'admin');
  final _password = TextEditingController();
  final _channel = TextEditingController(text: '1');
  final _snapshotPath = TextEditingController();

  String _vendor = 'hikvision';
  bool _useHttps = false;
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    _channel.dispose();
    _snapshotPath.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      _name.text.trim().isNotEmpty &&
      _host.text.trim().isNotEmpty &&
      _username.text.trim().isNotEmpty &&
      _password.text.isNotEmpty &&
      (int.tryParse(_port.text.trim()) ?? 0) > 0;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final branchId = ref.read(authControllerProvider).user?.branchId;
      final snapshotPath = _snapshotPath.text.trim();
      await ref.read(camerasRepositoryProvider).create(
            name: _name.text.trim(),
            host: _host.text.trim(),
            port: int.parse(_port.text.trim()),
            username: _username.text.trim(),
            password: _password.text,
            useHttps: _useHttps,
            vendor: _vendor,
            channelNo: int.tryParse(_channel.text.trim()) ?? 1,
            snapshotPath: snapshotPath.isEmpty ? null : snapshotPath,
            branchId: branchId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Подключить камеру'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Название', hintText: 'Камера регистратуры'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _host,
                      decoration: const InputDecoration(
                          labelText: 'IP-адрес', hintText: '192.168.1.64'),
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
                decoration: const InputDecoration(labelText: 'Логин'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _vendor,
                      decoration: const InputDecoration(labelText: 'Тип'),
                      items: const [
                        DropdownMenuItem(value: 'hikvision', child: Text('Hikvision (ISAPI)')),
                        DropdownMenuItem(value: 'generic', child: Text('Другая (свой путь)')),
                      ],
                      onChanged: (v) => setState(() => _vendor = v ?? 'hikvision'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _channel,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Канал'),
                    ),
                  ),
                ],
              ),
              if (_vendor == 'generic') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _snapshotPath,
                  decoration: const InputDecoration(
                    labelText: 'Путь снимка',
                    hintText: '/cgi-bin/snapshot.cgi',
                  ),
                ),
              ],
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _useHttps,
                onChanged: (v) => setState(() => _useHttps = v),
                title: const Text('HTTPS'),
                dense: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
                ),
              ],
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
              : const Text('Подключить'),
        ),
      ],
    );
  }
}
