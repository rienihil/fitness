import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../service/auth_service.dart';
import '../service/pin_auth_service.dart';
import 'login_screen.dart';
import 'pin_setup_screen.dart';
import 'edit_account_screen.dart';
import 'delete_account_screen.dart';// Добавляем импорт экрана редактирования аккаунта

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = 'User';
  String email = 'user@example.com';
  bool isDarkMode = false;
  bool isGuest = false;
  bool _isPinSetup = false;
  bool _isLoading = true;

  final _authService = AuthService();
  final _pinAuthService = PinAuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkPinStatus();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? name;
      email = prefs.getString('email') ?? email;
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      isGuest = prefs.getBool('isGuestMode') ?? false;
    });
  }

  Future<void> _checkPinStatus() async {
    final isPinSetup = await _pinAuthService.isPinSetup();
    setState(() {
      _isPinSetup = isPinSetup;
      _isLoading = false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    MyApp.of(context)?.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    setState(() => isDarkMode = value);
  }

  Future<void> _resetPin() async {
    setState(() => _isLoading = true);
    await _pinAuthService.resetPin();
    setState(() {
      _isPinSetup = false;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN successfully reset')),
    );
  }

  void _navigateToPinSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PinSetupScreen()),
    ).then((_) => _checkPinStatus());
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    MyApp.of(context)?.setLoggedIn(false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  void _showDialog(String title, Widget content, {List<Widget>? actions}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: content,
        actions: actions ??
            [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
      ),
    );
  }

  void _showGuestRestriction() {
    _showDialog(
      'Feature Restricted',
      const Text('This feature is not available in guest mode. Sign in to access all features.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _signOut();
          },
          child: const Text('Sign In'),
        ),
      ],
    );
  }

  // Изменяем метод для открытия экрана редактирования аккаунта
  void _showAccountDetails() {
    if (isGuest) return _showGuestRestriction();

    // Вместо диалога открываем экран редактирования
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountScreen(
          currentName: name,
          currentEmail: email,
        ),
      ),
    ).then((updatedName) {
      // Если получили обновленное имя, обновляем состояние
      if (updatedName != null && updatedName is String) {
        setState(() {
          name = updatedName;
        });
      }
      // Перезагружаем данные пользователя для обновления интерфейса
      _loadUserData();
    });
  }

  void _showLanguageDialog() {
    _showDialog(
      'Select Language',
      Column(
        mainAxisSize: MainAxisSize.min,
        children: ['English', 'Russian', 'Kazakh']
            .map((lang) => ListTile(title: Text(lang), onTap: () => Navigator.pop(context)))
            .toList(),
      ),
    );
  }

  void _showDeleteConfirmation() {
    if (isGuest) return _showGuestRestriction();

    // Вместо диалога перенаправляем на экран удаления аккаунта
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeleteAccountScreen(),
      ),
    );
  }

  void _showNotificationsSettings() {
    if (isGuest) return _showGuestRestriction();
    _showDialog(
      'Notification Settings',
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Workout Reminders'),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text('Nutrition Alerts'),
            value: false,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap, {bool disabled = false}) {
    return ListTile(
      leading: Icon(icon, color: disabled ? Colors.grey : null),
      title: Text(title, style: TextStyle(color: disabled ? Colors.grey : null)),
      trailing: Icon(disabled ? Icons.lock : Icons.arrow_forward_ios, size: 16, color: disabled ? Colors.grey : null),
      onTap: disabled ? _showGuestRestriction : onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).cardColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(),
          if (isGuest) _buildGuestBanner(),
          _buildTile(Icons.person, 'Account', _showAccountDetails, disabled: isGuest),
          _buildTile(Icons.language, 'Language', _showLanguageDialog),
          _buildTile(Icons.notifications, 'Notifications', _showNotificationsSettings, disabled: isGuest),
          _buildTile(Icons.delete, 'Delete Account', _showDeleteConfirmation, disabled: isGuest),
          _buildTile(Icons.logout, 'Sign Out', _signOut),
          const SizedBox(height: 20),
          _buildThemeToggle(),
          const SizedBox(height: 32),
          _buildPinSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 28, child: Text(isGuest ? 'G' : name.isNotEmpty ? name[0].toUpperCase() : 'A')),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.grey)),
            if (isGuest)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Text('GUEST MODE', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildGuestBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber),
              SizedBox(width: 8),
              Text('Limited Access Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('You are using the app in guest mode. Some features are restricted.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _signOut,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Sign In Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(isDarkMode ? Icons.nightlight_round : Icons.wb_sunny),
          const SizedBox(width: 12),
          const Text("Dark theme", style: TextStyle(fontSize: 16)),
        ]),
        Switch(value: isDarkMode, onChanged: _toggleTheme),
      ],
    );
  }

  Widget _buildPinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Offline Access', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(
              _isPinSetup ? Icons.lock : Icons.lock_open,
              color: _isPinSetup ? Colors.green : Colors.orange,
            ),
            title: Text(_isPinSetup ? 'PIN is set up' : 'Set up PIN for offline access'),
            subtitle: Text(
              _isPinSetup
                  ? 'You can access the app offline with your PIN'
                  : 'Create a PIN to use the app when you\'re offline',
            ),
            trailing: _isPinSetup
                ? TextButton(onPressed: _resetPin, child: const Text('Reset'))
                : TextButton(onPressed: _navigateToPinSetup, child: const Text('Setup')),
          ),
        ),
      ],
    );
  }
}