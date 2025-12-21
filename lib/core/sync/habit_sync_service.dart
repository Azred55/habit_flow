import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:habit_flow/features/task_list/models/habit.dart';

class HabitSyncService {
  HabitSyncService({
    required SupabaseClient? client,
    required Box<Habit> habitBox,
  }) : _client = client,
       _habitBox = habitBox,
       _prefsFuture = SharedPreferences.getInstance();

  static const _tableName = 'habits';
  static const _pendingUpsertsKey = 'habit_sync_pending_upserts';
  static const _pendingDeletesKey = 'habit_sync_pending_deletes';

  final SupabaseClient? _client;
  final Box<Habit> _habitBox;
  final Future<SharedPreferences> _prefsFuture;
  bool _isProcessingQueue = false;
  Timer? _retryTimer;

  bool get _hasClient => _client != null;
  bool get _isAuthenticated {
    final client = _client;
    if (client == null) return false;
    return client.auth.currentSession != null;
  }

  Future<void> initialize() async {
    if (!_hasClient || !_isAuthenticated) return;
    await syncFromRemote();
    await _processQueue();
  }

  Future<void> syncFromRemote() async {
    if (!_hasClient || !_isAuthenticated) return;

    try {
      final rows =
          // ignore: unnecessary_cast
          await _client!
                  .from(_tableName)
                  .select('''
            id,
            title,
            last_completion_date,
            streak_count,
            updated_at
          ''')
                  .order('updated_at')
              as List<Map<String, dynamic>>;

      final remoteById = {for (final row in rows) row['id'] as String: row};

      for (final remote in remoteById.values) {
        final habitId = remote['id'] as String;
        final remoteHabit = Habit.fromRemote(remote);
        final localHabit = _findHabit(habitId);
        if (localHabit == null) {
          await _habitBox.add(remoteHabit);
        } else if (remoteHabit.updatedAt.isAfter(localHabit.updatedAt)) {
          localHabit.applyRemote(remoteHabit);
          await localHabit.save();
        }
      }

      for (final habit in _habitBox.values) {
        if (!remoteById.containsKey(habit.id)) {
          await queueUpsert(habit);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Fehler beim Abrufen der Supabase-Daten: $error\n$stackTrace');
      _scheduleQueueRetry();
    }
  }

  Future<void> queueUpsert(Habit habit) async {
    if (habit.id.isEmpty) return;
    await _updateQueuedIds(_pendingUpsertsKey, (set) => set..add(habit.id));
    await _updateQueuedIds(_pendingDeletesKey, (set) => set..remove(habit.id));
    await _pushHabit(habit);
  }

  Future<void> queueDelete(String habitId) async {
    if (habitId.isEmpty) return;
    await _updateQueuedIds(_pendingUpsertsKey, (set) => set..remove(habitId));
    await _updateQueuedIds(_pendingDeletesKey, (set) => set..add(habitId));
    await _deleteRemoteHabit(habitId);
  }

  Future<void> _processQueue() async {
    if (!_hasClient || _isProcessingQueue || !_isAuthenticated) return;
    _isProcessingQueue = true;

    try {
      final pendingUpserts = await _loadQueuedIds(_pendingUpsertsKey);
      for (final habitId in pendingUpserts) {
        final habit = _findHabit(habitId);
        if (habit == null) {
          await _updateQueuedIds(
            _pendingUpsertsKey,
            (set) => set..remove(habitId),
          );
          continue;
        }
        await _pushHabit(habit);
      }

      final pendingDeletes = await _loadQueuedIds(_pendingDeletesKey);
      for (final habitId in pendingDeletes) {
        await _deleteRemoteHabit(habitId);
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _pushHabit(Habit habit) async {
    if (!_hasClient || !_isAuthenticated) return;
    try {
      await _client!.from(_tableName).upsert(habit.toRemoteMap());
      await _updateQueuedIds(
        _pendingUpsertsKey,
        (set) => set..remove(habit.id),
      );
    } catch (error, stackTrace) {
      debugPrint('Supabase-Upsert fehlgeschlagen: $error\n$stackTrace');
      _scheduleQueueRetry();
    }
  }

  Future<void> _deleteRemoteHabit(String habitId) async {
    if (!_hasClient || !_isAuthenticated) return;
    try {
      await _client!.from(_tableName).delete().eq('id', habitId);
      await _updateQueuedIds(_pendingDeletesKey, (set) => set..remove(habitId));
    } catch (error, stackTrace) {
      debugPrint('Supabase-Löschung fehlgeschlagen: $error\n$stackTrace');
      _scheduleQueueRetry();
    }
  }

  Habit? _findHabit(String id) {
    try {
      return _habitBox.values.firstWhere((habit) => habit.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> _loadQueuedIds(String key) async {
    final prefs = await _prefsFuture;
    return (prefs.getStringList(key) ?? const <String>[]).toSet();
  }

  Future<void> _updateQueuedIds(
    String key,
    Set<String> Function(Set<String> ids) update,
  ) async {
    final prefs = await _prefsFuture;
    final updated = update(
      (prefs.getStringList(key) ?? const <String>[]).toSet(),
    );
    await prefs.setStringList(key, updated.toList());
  }

  void _scheduleQueueRetry() {
    _retryTimer ??= Timer(const Duration(seconds: 10), () {
      _retryTimer = null;
      _processQueue();
    });
  }
}

final habitSyncServiceProvider = Provider<HabitSyncService>(
  (ref) =>
      throw UnimplementedError('HabitSyncService muss überschrieben werden'),
);
