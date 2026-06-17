// lib/screens/tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.person_outline, size: 80, color: AppTheme.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('Sign in to view your profile', style: TextStyle(color: AppTheme.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign In'),
            ),
          ]),
        ),
      );
    }

    final customer = auth.customer!;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Avatar
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.gold,
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(customer.email, style: const TextStyle(color: AppTheme.grey)),
          if (customer.phone != null && customer.phone!.isNotEmpty)
            Text(customer.phone!, style: const TextStyle(color: AppTheme.grey)),
          const SizedBox(height: 8),
          if (customer.referralCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.card_giftcard, color: AppTheme.gold, size: 16),
                const SizedBox(width: 8),
                Text('Referral Code: ${customer.referralCode}',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w600)),
              ]),
            ),
          const SizedBox(height: 24),

          // Menu Items
          _menuItem(context, Icons.luggage_outlined, 'My Bookings', () {}),
          _menuItem(context, Icons.notifications_outlined, 'Notifications', () {}),
          _menuItem(context, Icons.help_outline, 'Help & Support', () {}),
          _menuItem(context, Icons.info_outline, 'About EBO Stay', () {}),
          const Divider(height: 32),
          _menuItem(
            context, Icons.logout, 'Sign Out', () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            color: Colors.red,
          ),
        ]),
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.primary),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: color == null ? const Icon(Icons.chevron_right, color: AppTheme.grey) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
