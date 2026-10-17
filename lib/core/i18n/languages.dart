/// Daftar bahasa yang bisa dipilih. Kode = kode BCP-47 yang dipakai Google ML Kit.
/// Nama ditulis dalam bahasanya sendiri supaya mudah dikenali pemakainya.
class LanguageOption {
  const LanguageOption(this.code, this.nativeName, this.englishName);

  final String code;
  final String nativeName;
  final String englishName;
}

/// Bahasa asli aplikasi. Semua teks di kode ditulis dalam bahasa ini.
const String sourceLanguageCode = 'id';

/// Bahasa yang selalu tampil paling atas di daftar.
const List<String> pinnedLanguageCodes = <String>['id', 'en', 'ms', 'zh'];

const List<LanguageOption> allLanguages = <LanguageOption>[
  LanguageOption('id', 'Bahasa Indonesia', 'Indonesian'),
  LanguageOption('en', 'English', 'English'),
  LanguageOption('ms', 'Bahasa Melayu', 'Malay'),
  LanguageOption('zh', '中文', 'Chinese'),
  LanguageOption('af', 'Afrikaans', 'Afrikaans'),
  LanguageOption('sq', 'Shqip', 'Albanian'),
  LanguageOption('ar', 'العربية', 'Arabic'),
  LanguageOption('be', 'Беларуская', 'Belarusian'),
  LanguageOption('bn', 'বাংলা', 'Bengali'),
  LanguageOption('bg', 'Български', 'Bulgarian'),
  LanguageOption('ca', 'Català', 'Catalan'),
  LanguageOption('hr', 'Hrvatski', 'Croatian'),
  LanguageOption('cs', 'Čeština', 'Czech'),
  LanguageOption('da', 'Dansk', 'Danish'),
  LanguageOption('nl', 'Nederlands', 'Dutch'),
  LanguageOption('eo', 'Esperanto', 'Esperanto'),
  LanguageOption('et', 'Eesti', 'Estonian'),
  LanguageOption('fi', 'Suomi', 'Finnish'),
  LanguageOption('fr', 'Français', 'French'),
  LanguageOption('gl', 'Galego', 'Galician'),
  LanguageOption('ka', 'ქართული', 'Georgian'),
  LanguageOption('de', 'Deutsch', 'German'),
  LanguageOption('el', 'Ελληνικά', 'Greek'),
  LanguageOption('gu', 'ગુજરાતી', 'Gujarati'),
  LanguageOption('ht', 'Kreyòl ayisyen', 'Haitian Creole'),
  LanguageOption('he', 'עברית', 'Hebrew'),
  LanguageOption('hi', 'हिन्दी', 'Hindi'),
  LanguageOption('hu', 'Magyar', 'Hungarian'),
  LanguageOption('is', 'Íslenska', 'Icelandic'),
  LanguageOption('ga', 'Gaeilge', 'Irish'),
  LanguageOption('it', 'Italiano', 'Italian'),
  LanguageOption('ja', '日本語', 'Japanese'),
  LanguageOption('kn', 'ಕನ್ನಡ', 'Kannada'),
  LanguageOption('ko', '한국어', 'Korean'),
  LanguageOption('lv', 'Latviešu', 'Latvian'),
  LanguageOption('lt', 'Lietuvių', 'Lithuanian'),
  LanguageOption('mk', 'Македонски', 'Macedonian'),
  LanguageOption('mt', 'Malti', 'Maltese'),
  LanguageOption('mr', 'मराठी', 'Marathi'),
  LanguageOption('no', 'Norsk', 'Norwegian'),
  LanguageOption('fa', 'فارسی', 'Persian'),
  LanguageOption('pl', 'Polski', 'Polish'),
  LanguageOption('pt', 'Português', 'Portuguese'),
  LanguageOption('ro', 'Română', 'Romanian'),
  LanguageOption('ru', 'Русский', 'Russian'),
  LanguageOption('sk', 'Slovenčina', 'Slovak'),
  LanguageOption('sl', 'Slovenščina', 'Slovenian'),
  LanguageOption('es', 'Español', 'Spanish'),
  LanguageOption('sw', 'Kiswahili', 'Swahili'),
  LanguageOption('sv', 'Svenska', 'Swedish'),
  LanguageOption('tl', 'Tagalog', 'Tagalog'),
  LanguageOption('ta', 'தமிழ்', 'Tamil'),
  LanguageOption('te', 'తెలుగు', 'Telugu'),
  LanguageOption('th', 'ไทย', 'Thai'),
  LanguageOption('tr', 'Türkçe', 'Turkish'),
  LanguageOption('uk', 'Українська', 'Ukrainian'),
  LanguageOption('ur', 'اردو', 'Urdu'),
  LanguageOption('vi', 'Tiếng Việt', 'Vietnamese'),
  LanguageOption('cy', 'Cymraeg', 'Welsh'),
];

LanguageOption languageByCode(String code) {
  for (final LanguageOption l in allLanguages) {
    if (l.code == code) return l;
  }
  return allLanguages.first;
}