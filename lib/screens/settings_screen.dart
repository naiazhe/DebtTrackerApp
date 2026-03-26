import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>().currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(title: const Text('Name'), subtitle: Text(user?.name ?? 'Unknown')),
          ListTile(title: const Text('Email'), subtitle: Text(user?.email ?? 'Unknown')),
          const SizedBox(height: 16),
          const Text('App Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const ListTile(title: Text('Version'), subtitle: Text('1.0.0')),
          const ListTile(title: Text('Environment'), subtitle: Text('Offline SQLite')), 
        ],
      ),
    );
  }
}
