import 'package:flutter/material.dart';
import 'package:habit_flow/core/router/app_router.dart';
import 'package:habit_flow/features/settings/controllers/settings_controller.dart';
import 'package:habit_flow/features/settings/widgets/settings_scope.dart';

const Color _accentGreen = Color(0xFF22C55E);

class App extends StatelessWidget {
  const App({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: settingsController,
      child: AnimatedBuilder(
        animation: settingsController,
        builder: (context, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: settingsController.themeMode,
            title: 'Habit Flow',
            routerConfig: appRouter,
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _accentGreen,
      brightness: brightness,
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: 'SFPro',
      colorScheme: colorScheme,
    );

    final selectedFillResolver = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.selected)
          ? _accentGreen
          : base.checkboxTheme.fillColor?.resolve(states),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: base.textTheme.apply(fontFamily: 'SFPro'),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: _accentGreen,
        foregroundColor: Colors.white,
      ),
      switchTheme: base.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? _accentGreen
              : base.switchTheme.thumbColor?.resolve(states),
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? _accentGreen.withValues(alpha: 0.4)
              : base.switchTheme.trackColor?.resolve(states),
        ),
      ),
      checkboxTheme: base.checkboxTheme.copyWith(
        fillColor: selectedFillResolver,
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
    );
  }
}
