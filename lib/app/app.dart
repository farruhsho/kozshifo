import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class KozShifoApp extends ConsumerWidget {
  const KozShifoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: "KO'Z SHIFO",
      debugShowCheckedModeBanner: false,
      theme: KozTheme.light(),
      darkTheme: KozTheme.dark(),
      routerConfig: router,
    );
  }
}
