import 'package:flutter/widgets.dart';

class S {
  final Locale locale;

  S(this.locale);

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('kk'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Hello',
      'language': 'Language',
      'name': 'Name',
      'save': 'Save',
      'home': 'Home',
      'workouts': 'Workouts',
      'nutrition': 'Nutrition',
      'profile': 'Profile',
    },
    'ru': {
      'title': 'Привет',
      'language': 'Язык',
      'name': 'Имя',
      'save': 'Сохранить',
      'home': 'Главная',
      'workouts': 'Тренировки',
      'nutrition': 'Питание',
      'profile': 'Профиль',
    },
    'kk': {
      'title': 'Сәлем',
      'language': 'Тіл',
      'name': 'Аты',
      'save': 'Сақтау',
      'home': 'Басты бет',
      'workouts': 'Жаттығулар',
      'nutrition': 'Тамақтану',
      'profile': 'Профиль',
    },
  };

  String get title => _localizedValues[locale.languageCode]!['title']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get name => _localizedValues[locale.languageCode]!['name']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get workouts => _localizedValues[locale.languageCode]!['workouts']!;
  String get nutrition => _localizedValues[locale.languageCode]!['nutrition']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru', 'kk'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) {
    return Future.value(S(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<S> old) => false;
}
