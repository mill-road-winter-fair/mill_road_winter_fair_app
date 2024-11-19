import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define available distance units
enum DistanceUnits { metric, imperial }

// Set default distance units
DistanceUnits preferredDistanceUnits = DistanceUnits.metric;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from shared preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Retrieve the saved enum index and convert it back to DistanceUnits
      int savedUnitIndex = prefs.getInt('preferredDistanceUnits') ?? 0; // Default to 0 (metric)
      preferredDistanceUnits = DistanceUnits.values[savedUnitIndex];
    });
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredDistanceUnits', preferredDistanceUnits.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView.separated(
        separatorBuilder: (BuildContext context, int index) => Divider(color: Colors.grey[350]),
        itemCount: 1,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Distance Units', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                RadioListTile(
                  title: const Text('Metric'),
                  subtitle: Text('Metres & Kilometres', style: TextStyle(fontSize: 14, color: Colors.grey[700]),),
                  visualDensity: VisualDensity.compact,
                  value: DistanceUnits.metric,
                  groupValue: preferredDistanceUnits,
                  onChanged: (DistanceUnits? value) {
                    setState(() {
                      preferredDistanceUnits = value!;
                    });
                    _saveSettings();
                  },
                ),
                RadioListTile(
                  title: const Text('Imperial'),
                  subtitle: Text('Feet & Miles', style: TextStyle(fontSize: 14, color: Colors.grey[700]),),
                  visualDensity: VisualDensity.compact,
                  value: DistanceUnits.imperial,
                  groupValue: preferredDistanceUnits,
                  onChanged: (DistanceUnits? value) {
                    setState(() {
                      preferredDistanceUnits = value!;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
