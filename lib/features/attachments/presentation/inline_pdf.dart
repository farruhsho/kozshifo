import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'inline_pdf_io.dart' if (dart.library.js_interop) 'inline_pdf_web.dart' as impl;

/// In-app PDF view. On web the bytes are embedded in a browser <iframe> (native
/// PDF render + zoom + print, no heavy dependency); elsewhere it shows a
/// fallback that opens the document externally via [onOpenExternal].
Widget inlinePdfView(Uint8List bytes, {required VoidCallback onOpenExternal}) =>
    impl.inlinePdfView(bytes, onOpenExternal: onOpenExternal);
