import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:habit_flow/features/settings/widgets/settings_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScope.watch(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Theme wählen',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    isExpanded: true,
                    value: controller.themeMode,
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Hell'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dunkel'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateThemeMode(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Benachrichtigungen'),
                subtitle:
                    const Text('Push-Benachrichtigungen für Habits aktivieren'),
                value: controller.notificationsEnabled,
                onChanged: controller.updateNotificationsEnabled,
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Erinnerungszeit'),
                subtitle: Text(
                  controller.reminderTime.format(context),
                ),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final selected =
                      await _pickReminderTime(context, controller.reminderTime);
                  if (selected != null) {
                    controller.updateReminderTime(selected);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<TimeOfDay?> _pickReminderTime(
    BuildContext context,
    TimeOfDay initialTime,
  ) async {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS) {
      var selectedTime = initialTime;

      return showCupertinoModalPopup<TimeOfDay>(
        context: context,
        builder: (context) {
          return Container(
            height: 300,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(
                      2020,
                      1,
                      1,
                      initialTime.hour,
                      initialTime.minute,
                    ),
                    use24hFormat: true,
                    onDateTimeChanged: (dateTime) {
                      selectedTime = TimeOfDay(
                        hour: dateTime.hour,
                        minute: dateTime.minute,
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: CupertinoButton(
                    child: const Text('Fertig'),
                    onPressed: () => Navigator.of(context).pop(selectedTime),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return showTimePicker(
      context: context,
      initialTime: initialTime,
    );
  }
}
