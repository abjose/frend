import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: "Settings",
      children: [
        TextInputSettingsTile(
          title: 'Show notifications X minutes before event',
          settingKey: 'reminder-before-event-minutes',
          initialValue: '15',
          validator: (String? username) {
            if (username != null && username.length > 3) {
              return null;
            }
            return "User Name can't be smaller than 4 letters";
          },
          borderColor: Colors.blueAccent,
          errorColor: Colors.deepOrangeAccent,
        ),
        CheckboxSettingsTile(
          settingKey: 'show-help',
          title: 'Show Help page on next startup?',
          defaultValue: true,
        ),
      ],
    );
  }
}
