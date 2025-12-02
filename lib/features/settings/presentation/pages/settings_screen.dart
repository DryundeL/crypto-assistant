import 'dart:ui';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.settings),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFFe3f2fd),
                    const Color(0xFFbbdefb),
                    const Color(0xFF90caf9),
                  ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingsTile(
                context,
                title: l10n.theme,
                icon: Icons.brightness_6,
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  dropdownColor: isDark ? const Color(0xFF16213e) : Colors.white,
                  underline: const SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.black54),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
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
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                context,
                title: l10n.language,
                icon: Icons.language,
                trailing: DropdownButton<Locale>(
                  value: settings.locale,
                  dropdownColor: isDark ? const Color(0xFF16213e) : Colors.white,
                  underline: const SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.black54),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
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
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                context,
                title: l10n.currency,
                icon: Icons.attach_money,
                trailing: DropdownButton<String>(
                  value: settings.currency,
                  dropdownColor: isDark ? const Color(0xFF16213e) : Colors.white,
                  underline: const SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.black54),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  onChanged: (String? newCurrency) {
                    if (newCurrency != null) {
                      settings.updateCurrency(newCurrency);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'usd', child: Text('USD')),
                    DropdownMenuItem(value: 'eur', child: Text('EUR')),
                    DropdownMenuItem(value: 'gbp', child: Text('GBP')),
                    DropdownMenuItem(value: 'jpy', child: Text('JPY')),
                    DropdownMenuItem(value: 'rub', child: Text('RUB')),
                  ],
                ),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget trailing,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.4),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? Colors.white70 : Colors.deepPurple),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: trailing,
            ),
          ),
        ),
      ),
    );
  }
}
