import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_flow/features/settings/controllers/settings_controller.dart';
import 'package:habit_flow/features/settings/controllers/sync_auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(settingsControllerProvider);
    final syncController = ref.watch(syncAuthControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: controller.isInitialized
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cloud-Sync',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          !syncController.isAvailable
                              ? 'Supabase ist nicht konfiguriert. '
                                    'Setze SUPABASE_URL und SUPABASE_ANON_KEY, '
                                    'um dich mit dem Server zu verbinden.'
                              : syncController.isLoggedIn
                              ? 'Angemeldet als ${syncController.userEmail}. '
                                    'Deine Habits werden automatisch synchronisiert.'
                              : 'Melde dich an, um deine Gewohnheiten '
                                    'mit Supabase zu synchronisieren.',
                        ),
                        if (syncController.lastError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            syncController.lastError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed:
                              (!syncController.isAvailable ||
                                  syncController.isLoading)
                              ? null
                              : syncController.isLoggedIn
                              ? () => _handleSignOut(context, syncController)
                              : () => _handleSignIn(context, syncController),
                          child: syncController.isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  syncController.isLoggedIn
                                      ? 'Abmelden'
                                      : 'Anmelden',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                  subtitle: const Text(
                    'Push-Benachrichtigungen für Habits aktivieren',
                  ),
                  value: controller.notificationsEnabled,
                  onChanged: controller.updateNotificationsEnabled,
                ),
                const SizedBox(height: 24),
                ListTile(
                  title: const Text('Erinnerungszeit'),
                  subtitle: Text(controller.reminderTime.format(context)),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final selected = await _pickReminderTime(
                      context,
                      controller.reminderTime,
                    );
                    if (selected != null) {
                      controller.updateReminderTime(selected);
                    }
                  },
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
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

    return showTimePicker(context: context, initialTime: initialTime);
  }

  Future<void> _handleSignIn(
    BuildContext context,
    SyncAuthController controller,
  ) async {
    final credentials = await _showLoginDialog(context);
    if (credentials == null) return;
    final error = await controller.signIn(
      email: credentials.email,
      password: credentials.password,
    );
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Erfolgreich bei Supabase angemeldet.'),
        backgroundColor: error == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handleSignOut(
    BuildContext context,
    SyncAuthController controller,
  ) async {
    final error = await controller.signOut();
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Vom Supabase-Sync abgemeldet.'),
        backgroundColor: error == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<_LoginCredentials?> _showLoginDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bei Supabase anmelden'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte gib deine E-Mail ein.';
                    }
                    if (!value.contains('@')) {
                      return 'Ungültige E-Mail-Adresse.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Passwort',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte gib dein Passwort ein.';
                    }
                    if (value.length < 6) {
                      return 'Mindestens 6 Zeichen.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Anmelden'),
            ),
          ],
        );
      },
    );

    final credentials = shouldSubmit == true
        ? _LoginCredentials(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          )
        : null;

    emailController.dispose();
    passwordController.dispose();

    return credentials;
  }
}

class _LoginCredentials {
  const _LoginCredentials({required this.email, required this.password});

  final String email;
  final String password;
}
