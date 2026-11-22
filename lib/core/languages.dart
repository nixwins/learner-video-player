/// A language the user can translate into. [code] is the Google Translate
/// `tl` value.
class Language {
  const Language(this.code, this.name);

  final String code;
  final String name;
}

/// Single source of truth for selectable native languages.
/// The first entry is the default.
const supportedLanguages = <Language>[
  Language('kk', 'Қазақша'),
  Language('ru', 'Русский'),
  Language('uk', 'Українська'),
  Language('uz', 'Oʻzbekcha'),
  Language('ky', 'Кыргызча'),
  Language('tr', 'Türkçe'),
  Language('az', 'Azərbaycanca'),
  Language('de', 'Deutsch'),
  Language('fr', 'Français'),
  Language('es', 'Español'),
  Language('it', 'Italiano'),
  Language('pt', 'Português'),
  Language('zh-CN', '中文 (简体)'),
  Language('ja', '日本語'),
  Language('ko', '한국어'),
  Language('ar', 'العربية'),
  Language('hi', 'हिन्दी'),
];

/// Returns the language with [code], or the default if it is unknown/null.
Language languageByCode(String? code) => supportedLanguages.firstWhere(
  (language) => language.code == code,
  orElse: () => supportedLanguages.first,
);
