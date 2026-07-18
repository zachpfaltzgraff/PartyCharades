import 'package:flutter/material.dart';
import 'package:party_charades/services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int roundLength = SettingsService.defaultRoundLength;
  bool audioEnabled = SettingsService.defaultAudio;
  bool hapticEnabled = SettingsService.defaultHaptic;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final length = await SettingsService.getRoundLength();

    final audio = await SettingsService.getAudio();

    final haptic = await SettingsService.getHaptic();

    if (!mounted) return;

    setState(() {
      roundLength = length;
      audioEnabled = audio;
      hapticEnabled = haptic;
      loading = false;
    });
  }

  Future<void> updateRoundLength(int value) async {
    setState(() {
      roundLength = value;
    });

    await SettingsService.setRoundLength(value);
  }

  Future<void> updateAudio(bool value) async {
    setState(() {
      audioEnabled = value;
    });

    await SettingsService.setAudio(value);
  }

  Future<void> updateHaptic(bool value) async {
    setState(() {
      hapticEnabled = value;
    });

    await SettingsService.setHaptic(value);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.secondary, colors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.timer),
                          SizedBox(width: 12),
                          Text(
                            "Round Length",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$roundLength seconds",
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: roundLength.toDouble(),
                        min: 30,
                        max: 180,
                        divisions: 15,
                        label: "$roundLength sec",
                        onChanged: (value) {
                          updateRoundLength(value.round());
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.volume_up),
                      title: const Text("Sound Effects"),
                      subtitle: const Text(
                        "Play sounds for correct and passed words",
                      ),
                      value: audioEnabled,
                      onChanged: updateAudio,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.vibration),
                      title: const Text("Vibration"),
                      subtitle: const Text(
                        "Enable haptic feedback during gameplay",
                      ),
                      value: hapticEnabled,
                      onChanged: updateHaptic,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
