import 'package:flutter/material.dart';
import 'package:my_app/screens/workout_select_screen.dart';
import 'package:my_app/service/pin_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_app/screens/pin_lock_screen.dart';
import 'package:my_app/service/offline_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/generated/l10n.dart';

import 'screens/workout_screen.dart';
import 'screens/yoga_screen.dart';
import 'screens/exercise_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await OfflineService().initialize();

  final prefs = await SharedPreferences.getInstance();

  // 👇 Вот это добавляем для отладки:
  print('🟡 SharedPreferences: все ключи и значения:');
  for (var key in prefs.getKeys()) {
    print('🔑 $key: ${prefs.get(key)}');
  }

  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final isLoggedIn = prefs.containsKey('uid');

  runApp(MyFitnessApp(
    initialThemeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
    isLoggedIn: isLoggedIn,
  ));
}


class MyFitnessApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final bool isLoggedIn;

  const MyFitnessApp({
    Key? key,
    required this.initialThemeMode,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  State<MyFitnessApp> createState() => _MyFitnessAppState();
}

class _MyFitnessAppState extends State<MyFitnessApp> {
  late ThemeMode _themeMode;
  late bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _isLoggedIn = widget.isLoggedIn;
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _setLoggedIn(bool loggedIn) {
    setState(() {
      _isLoggedIn = loggedIn;
    });
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyApp(
      setThemeMode: _setThemeMode,
      setLoggedIn: _setLoggedIn,
      child: MaterialApp(
        title: 'Fitness Assignment',
        themeMode: _themeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.deepPurple,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.deepPurple,
        ),
        debugShowCheckedModeBanner: false,
        home: _isLoggedIn ? FutureBuilder<bool>(
          future: PinAuthService().isPinSetup(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data == true) {
              return PinLockScreen(onSuccess: () => _navigateToHome(context));
            }
            return HomeScreen();
          },
        ) : LoginScreen(),
      ),
    );
  }
}

class MyApp extends InheritedWidget {
  final void Function(ThemeMode) setThemeMode;
  final void Function(bool) setLoggedIn;

  const MyApp({
    Key? key,
    required this.setThemeMode,
    required this.setLoggedIn,
    required Widget child,
  }) : super(key: key, child: child);

  static MyApp? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MyApp>();

  @override
  bool updateShouldNotify(covariant MyApp oldWidget) => true;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  String? name;
  String? email;
  bool isOffline = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final screens = [
    DashboardScreen(),
    WorkoutSelectScreen(),
    NutritionScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
    initConnectivityListener();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name');
      email = prefs.getString('email');
    });
  }

  Future<void> saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', nameController.text);
    await prefs.setString('email', emailController.text);
    setState(() {
      name = nameController.text;
      email = emailController.text;
    });
  }

  void initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        isOffline = result == ConnectivityResult.none;
      });
    });

    Connectivity().checkConnectivity().then((result) {
      setState(() {
        isOffline = result == ConnectivityResult.none;
      });
    });
  }

  Widget buildUserForm() {
    return Scaffold(
      appBar: AppBar(title: const Text("Добро пожаловать")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveUserData,
              child: const Text("Сохранить"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (name == null || email == null) {
      return buildUserForm();
    }

    return Stack(
      children: [
        Scaffold(
          body: screens[index],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (value) => setState(() => index = value),
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Main"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center), label: "Exercises"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.fastfood), label: "Nutrition"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        ),
        if (isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Нет подключения к интернету',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

      ],
    );
  }
}
