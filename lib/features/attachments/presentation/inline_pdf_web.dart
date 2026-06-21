import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

int _seq = 0;

/// Web: embed the PDF bytes in a browser <iframe> via a blob URL. The browser
/// renders the PDF natively with its own zoom / print / download — no pub
/// dependency (mirrors the blob+iframe interop already used by printBytes).
Widget inlinePdfView(Uint8List bytes, {required VoidCallback onOpenExternal}) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final viewType = 'kozshifo-pdf-${_seq++}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    return web.HTMLIFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
  });
  return HtmlElementView(viewType: viewType);
}
