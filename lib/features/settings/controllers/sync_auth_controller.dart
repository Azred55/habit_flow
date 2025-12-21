import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:habit_flow/core/providers/supabase_client_provider.dart';
import 'package:habit_flow/core/sync/habit_sync_service.dart';

class SyncAuthController extends ChangeNotifier {
  SyncAuthController(this._client, this._habitSyncService) {
    _init();
  }

  final SupabaseClient? _client;
  final HabitSyncService _habitSyncService;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = false;
  String? _lastError;

  bool get isAvailable => _client != null;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  bool get isLoggedIn {
    final client = _client;
    if (client == null) {
      return false;
    }
    final user = client.auth.currentUser;
    final session = client.auth.currentSession;
    if (session == null || user == null) {
      return false;
    }
    return (user.email ?? '').isNotEmpty;
  }

  String? get userEmail {
    final client = _client;
    if (client == null) return null;
    return client.auth.currentUser?.email;
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return 'Supabase ist nicht konfiguriert.';
    }
    _setLoading(true);
    _setError(null);
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      await _habitSyncService.initialize();
      notifyListeners();
      return null;
    } on AuthException catch (error) {
      _setError(error.message);
      return error.message;
    } catch (error) {
      final message = 'Anmeldung fehlgeschlagen: $error';
      _setError(message);
      return message;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signOut() async {
    final client = _client;
    if (client == null) {
      return 'Supabase ist nicht konfiguriert.';
    }
    _setLoading(true);
    _setError(null);
    try {
      await client.auth.signOut();
      notifyListeners();
      return null;
    } on AuthException catch (error) {
      _setError(error.message);
      return error.message;
    } catch (error) {
      final message = 'Abmelden fehlgeschlagen: $error';
      _setError(message);
      return message;
    } finally {
      _setLoading(false);
    }
  }

  void _init() {
    final client = _client;
    if (client == null) return;
    _authSubscription = client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.tokenRefreshed) {
        unawaited(_habitSyncService.initialize());
      }
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _lastError = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final syncAuthControllerProvider = ChangeNotifierProvider<SyncAuthController>((
  ref,
) {
  final controller = SyncAuthController(
    ref.watch(supabaseClientProvider),
    ref.watch(habitSyncServiceProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
