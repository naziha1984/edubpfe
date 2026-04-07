/// Textes de la page d'accueil selon languageCode (fr | en | ar).
class WelcomeCopy {
  const WelcomeCopy._();

  static String welcomeToLine(String code) {
    switch (code) {
      case 'en':
        return 'Welcome to';
      case 'ar':
        return '\u0623\u0647\u0644\u0627\u064b \u0628\u0643 \u0641\u064a';
      default:
        return 'Bienvenue sur';
    }
  }

  static String tagline(String code) {
    switch (code) {
      case 'en':
        return 'Learn with clarity and calm rigor.';
      case 'ar':
        return '\u062a\u0639\u0644\u0651\u0645 \u0628\u0648\u0636\u0648\u062d \u0648\u0628\u062c\u062f\u064a\u0629 \u0647\u0627\u062f\u0626\u0629.';
      default:
        return 'Apprendre avec clart\u00e9 et exigence douce.';
    }
  }

  static String startCta(String code) {
    switch (code) {
      case 'en':
        return 'Get started';
      case 'ar':
        return '\u0627\u0628\u062f\u0623';
      default:
        return 'Commencer';
    }
  }

  static String loginCta(String code) {
    switch (code) {
      case 'en':
        return 'Sign in';
      case 'ar':
        return '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644';
      default:
        return 'Se connecter';
    }
  }

  static String settingsTitle(String code) {
    switch (code) {
      case 'en':
        return 'Settings';
      case 'ar':
        return '\u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a';
      default:
        return 'R\u00e9glages';
    }
  }

  static String languageLabel(String code) {
    switch (code) {
      case 'en':
        return 'Language';
      case 'ar':
        return '\u0627\u0644\u0644\u063a\u0629';
      default:
        return 'Langue';
    }
  }

  static String appearanceLabel(String code) {
    switch (code) {
      case 'en':
        return 'Appearance';
      case 'ar':
        return '\u0627\u0644\u0645\u0638\u0647\u0631';
      default:
        return 'Apparence';
    }
  }

  static String themeSystem(String code) {
    switch (code) {
      case 'en':
        return 'System';
      case 'ar':
        return '\u0627\u0644\u0646\u0638\u0627\u0645';
      default:
        return 'Syst\u00e8me';
    }
  }

  static String themeLight(String code) {
    switch (code) {
      case 'en':
        return 'Light';
      case 'ar':
        return '\u0641\u0627\u062a\u062d';
      default:
        return 'Clair';
    }
  }

  static String themeDark(String code) {
    switch (code) {
      case 'en':
        return 'Dark';
      case 'ar':
        return '\u062f\u0627\u0643\u0646';
      default:
        return 'Sombre';
    }
  }
}
