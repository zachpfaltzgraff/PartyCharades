import 'package:flutter/material.dart';
import 'package:party_charades/services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int roundLength = SettingsService.defaultRoundLength;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    roundLength = await SettingsService.getRoundLength();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> save(int value) async {
    setState(() {
      roundLength = value;
    });

    await SettingsService.setRoundLength(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Round Length"),
            subtitle: Text("$roundLength seconds"),
          ),
          Slider(
            value: roundLength.toDouble(),
            min: 30,
            max: 180,
            divisions: 30,
            label: "$roundLength sec",
            onChanged: (value) {
              save(value.round());
            },
          ),
        ],
      ),
    );
  }
}
