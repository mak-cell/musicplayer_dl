// lib/screens/setting_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final _rowController = TextEditingController();
  final _colController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rows = prefs.getInt('led_rows') ?? 14;
    final cols = prefs.getInt('led_cols') ?? 11;
    _rowController.text = rows.toString();
    _colController.text = cols.toString();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final rows = int.tryParse(_rowController.text) ?? 14;
    final cols = int.tryParse(_colController.text) ?? 11;
    await prefs.setInt('led_rows', rows);
    await prefs.setInt('led_cols', cols);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LED Matrix Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _rowController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rows'),
            ),
            TextField(
              controller: _colController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Columns'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
