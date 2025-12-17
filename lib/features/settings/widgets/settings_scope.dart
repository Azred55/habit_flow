import 'package:flutter/widgets.dart';
import 'package:habit_flow/features/settings/controllers/settings_controller.dart';

class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController watch(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope not found in context');
    return scope!.notifier!;
  }

  static SettingsController read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope not found in context');
    return scope!.notifier!;
  }

  @override
  bool updateShouldNotify(SettingsScope oldWidget) => true;
}
