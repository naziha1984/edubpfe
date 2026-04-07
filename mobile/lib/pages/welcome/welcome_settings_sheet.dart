import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../ui/theme/edubridge_colors.dart';
import '../../ui/theme/edubridge_theme.dart';
import '../../ui/theme/edubridge_typography.dart';
import 'welcome_copy.dart';

/// Panneau réglages : langue + thème (Material 3, sobre).
Future<void> showWelcomeSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return const _WelcomeSettingsSheetBody();
    },
  );
}

class _WelcomeSettingsSheetBody extends StatelessWidget {
  const _WelcomeSettingsSheetBody();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final lang = settings.languageCode;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: EduBridgeTheme.spacingMD,
        right: EduBridgeTheme.spacingMD,
        bottom: bottom + EduBridgeTheme.spacingMD,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: EduBridgeTheme.elevation4,
        shadowColor: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: EduBridgeColors.textTertiary.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                WelcomeCopy.settingsTitle(lang),
                style: EduBridgeTypography.titleLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                WelcomeCopy.languageLabel(lang),
                style: EduBridgeTypography.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'fr',
                    label: Text('FR'),
                  ),
                  ButtonSegment<String>(
                    value: 'ar',
                    label: Text('عربي'),
                  ),
                  ButtonSegment<String>(
                    value: 'en',
                    label: Text('EN'),
                  ),
                ],
                selected: {lang},
                onSelectionChanged: (s) {
                  final v = s.first;
                  context.read<AppSettingsProvider>().setLocale(Locale(v));
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                WelcomeCopy.appearanceLabel(lang),
                style: EduBridgeTypography.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text(WelcomeCopy.themeSystem(lang)),
                    icon: const Icon(Icons.brightness_auto, size: 18),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text(WelcomeCopy.themeLight(lang)),
                    icon: const Icon(Icons.light_mode_outlined, size: 18),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text(WelcomeCopy.themeDark(lang)),
                    icon: const Icon(Icons.dark_mode_outlined, size: 18),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) {
                  context.read<AppSettingsProvider>().setThemeMode(s.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
