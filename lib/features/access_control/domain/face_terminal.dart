import 'package:freezed_annotation/freezed_annotation.dart';

part 'face_terminal.freezed.dart';
part 'face_terminal.g.dart';

/// A connected Hikvision face terminal (mirrors backend `TerminalOut`).
/// The admin password is write-only on the backend and never present here.
@freezed
abstract class FaceTerminal with _$FaceTerminal {
  const factory FaceTerminal({
    required String id,
    required String name,
    required String host,
    required int port,
    required String username,
    required int doorNo,
    @Default(false) bool useHttps,
    String? branchId,
    String? branchName,
    @Default('active') String status,
    @Default(false) bool online,
    DateTime? lastSeen,
    Map<String, dynamic>? deviceInfo,
    required DateTime createdAt,
  }) = _FaceTerminal;

  factory FaceTerminal.fromJson(Map<String, dynamic> json) =>
      _$FaceTerminalFromJson(json);
}

/// Result of probing a terminal (mirrors backend `TerminalTestResult`).
@freezed
abstract class TerminalTestResult with _$TerminalTestResult {
  const factory TerminalTestResult({
    required bool online,
    String? model,
    String? firmware,
    String? serial,
    String? deviceName,
    String? error,
  }) = _TerminalTestResult;

  factory TerminalTestResult.fromJson(Map<String, dynamic> json) =>
      _$TerminalTestResultFromJson(json);
}
