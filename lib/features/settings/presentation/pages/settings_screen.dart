import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto_assistant/l10n/app_localizations.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsViewModel>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.theme),
            leading: const Icon(Icons.brightness_6),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  settings.updateThemeMode(newMode);
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.system),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.light),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.dark),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.language),
            leading: const Icon(Icons.language),
            trailing: DropdownButton<Locale>(
              value: settings.locale,
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  settings.updateLocale(newLocale);
                }
              },
              items: [
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Text(l10n.english),
                ),
                DropdownMenuItem(
                  value: const Locale('ru'),
                  child: Text(l10n.russian),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
