import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Non-web fallback: no embedded browser PDF engine, so offer to open the file
/// in the OS default viewer (which renders + prints it). Web gets a true inline
/// iframe instead (see inline_pdf_web.dart).
Widget inlinePdfView(Uint8List bytes, {required VoidCallback onOpenExternal}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.picture_as_pdf_outlined, size: 56, color: AppColors.muted),
        const SizedBox(height: 12),
        const Text('PDF-документ', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onOpenExternal,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Открыть PDF'),
        ),
      ],
    ),
  );
}
