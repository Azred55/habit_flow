import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:habit_flow/app.dart';
import 'package:habit_flow/core/config/supabase_options.dart';
import 'package:habit_flow/core/providers/supabase_client_provider.dart';
import 'package:habit_flow/core/sync/habit_sync_service.dart';
import 'package:habit_flow/features/notifications/notification_service.dart';
import 'package:habit_flow/features/notifications/providers/notification_providers.dart';
import 'package:habit_flow/features/task_list/models/habit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(HabitAdapter());
  final habitBox = await Hive.openBox<Habit>(Habit.boxName);

  SupabaseClient? supabaseClient;
  if (SupabaseOptions.isConfigured) {
    await Supabase.initialize(
      url: SupabaseOptions.url,
      anonKey: SupabaseOptions.anonKey,
    );
    supabaseClient = Supabase.instance.client;
  }

  final habitSyncService = HabitSyncService(
    client: supabaseClient,
    habitBox: habitBox,
  );
  await habitSyncService.initialize();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
        supabaseClientProvider.overrideWithValue(supabaseClient),
        habitSyncServiceProvider.overrideWithValue(habitSyncService),
      ],
      child: const App(),
    ),
  );
}
