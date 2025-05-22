import 'package:flutter/material.dart';
import 'package:my_app/service/pin_auth_service.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const PinLockScreen({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final _authService = PinAuthService();
  String? _error;

  Future<void> _verifyPin() async {
    final pin = _pinController.text;
    final success = await _authService.verifyPin(pin);

    if (success) {
      widget.onSuccess();
    } else {
      setState(() {
        _error = _authService.isPinLocked
            ? 'Слишком много попыток. Блокировка.'
            : 'Неверный PIN. Осталось попыток: ${_authService.remainingAttempts}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Введите PIN", style: TextStyle(fontSize: 24)),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'PIN-код'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _verifyPin,
              child: const Text("Подтвердить"),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}
