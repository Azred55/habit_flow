import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:habit_flow/app.dart';
import 'package:habit_flow/features/settings/controllers/settings_controller.dart';
import 'package:habit_flow/features/settings/data/settings_service.dart';
import 'package:habit_flow/features/task_list/models/habit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(HabitAdapter());
  await Hive.openBox<Habit>(Habit.boxName);

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  runApp(App(settingsController: settingsController));
}
