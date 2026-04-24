import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_mma, size: 48, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              const Text('Trainer App', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Sign in as a trainer', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 48),
              // Seeded trainer card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text('A', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  ),
                  title: const Text('Aarav', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Lead Trainer'),
                  trailing: Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Login as Aarav'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final authService = AuthService(ApiService());
      await authService.login(
        userId: 'trainer_aarav',
        role: 'trainer',
        name: 'Aarav',
      );

      final settings = Hive.box('settings');
      await settings.put('isLoggedIn', true);
      await settings.put('userId', 'trainer_aarav');
      await settings.put('userName', 'Aarav');
      await settings.put('userRole', 'trainer');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrainerHomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            action: SnackBarAction(label: 'Copy error', onPressed: () {}),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
