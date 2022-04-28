import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

// https://pub.dev/packages/flutter_settings_screens/versions/0.3.2-null-safety
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
          title: 'Minutes before event to show notification',
          settingKey: 'reminder-before-event-minutes',
          initialValue: '15',
          keyboardType: TextInputType.number,
          validator: (String? value) {
            if (value != null && int.tryParse(value) != null) {
              return null;
            }
            return "Please input an integer.";
          },
        ),
        CheckboxSettingsTile(
          title: 'Show notifications on birthdays?',
          settingKey: 'show-birthday-notifications',
          defaultValue: true,
        ),
        CheckboxSettingsTile(
          title: 'Show Help page on next startup?',
          settingKey: 'show-help',
          defaultValue: true,
        ),
      ],
    );
  }
}
