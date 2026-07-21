import 'package:flutter/material.dart';
import 'package:party_charades/pages/settings/instruction_row.dart';
import 'package:party_charades/services/audio_service.dart';
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
  bool tiltControl = SettingsService.defaultTiltControl;
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

    final tilt = await SettingsService.getTiltControl();

    if (!mounted) return;

    setState(() {
      roundLength = length;
      audioEnabled = audio;
      hapticEnabled = haptic;
      tiltControl = tilt;
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
    AudioService().playHapticCorrect();

    setState(() {
      audioEnabled = value;
    });

    await SettingsService.setAudio(value);
  }

  Future<void> updateHaptic(bool value) async {
    AudioService().playHapticCorrect();

    setState(() {
      hapticEnabled = value;
    });

    await SettingsService.setHaptic(value);
  }

  Future<void> updateTilt(bool value) async {
    AudioService().playHapticCorrect();

    setState(() {
      tiltControl = value;
    });

    await SettingsService.setTiltControl(value);
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
                          AudioService().playHapticCorrect();
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
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.screen_rotation_rounded),
                      title: const Text("Tilt Controls"),
                      subtitle: const Text(
                        "Play with tilt controls or swipe controls",
                      ),
                      value: tiltControl,
                      onChanged: updateTilt,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.help_outline),
                          SizedBox(width: 12),
                          Text(
                            "How to Play",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      InstructionRow(
                        icon: Icons.face_6_rounded,
                        title: "Hold it up",
                        description:
                            "Place your phone on your forehead so everyone else can see the word.",
                      ),

                      const SizedBox(height: 16),

                      InstructionRow(
                        icon: Icons.record_voice_over_rounded,
                        title: "Listen to clues",
                        description:
                            "Friends describe or act out the word without saying it while you guess.",
                      ),

                      const SizedBox(height: 16),

                      InstructionRow(
                        icon: Icons.keyboard_arrow_down_rounded,
                        iconColor: Colors.green,
                        title: "Tilt Down / Swipe Right",
                        description: "You guessed correctly!",
                      ),

                      const SizedBox(height: 16),

                      InstructionRow(
                        icon: Icons.keyboard_arrow_up_rounded,
                        iconColor: Colors.red,
                        title: "Tilt Up / Swipe Left",
                        description: "Skip to the next word.",
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: Text(
                          "Guess as many words as you can before time runs out!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
