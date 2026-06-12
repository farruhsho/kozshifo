import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped by the network layer when the session is definitively over
/// (refresh token rejected by the server). The auth controller listens and
/// flips to unauthenticated so GoRouter redirects to login — the network
/// layer cannot watch the auth controller directly without a provider cycle.
final sessionExpiredTickProvider = StateProvider<int>((_) => 0);
