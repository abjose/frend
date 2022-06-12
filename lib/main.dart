import 'package:flutter/material.dart';
import 'package:frend/confirmation_dialog.dart';
import 'package:frend/friend_list.dart';
import 'package:frend/calendar.dart';
import 'package:frend/settings_page.dart';
import 'package:frend/tag_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'dart:async';
import 'db.dart';
import 'help_page.dart';
import 'notification_service.dart';

Future<void> main() async {
  // This is required so ObjectBox can get the application directory
  // to store the database in.
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();
  objectbox.maybeFix();
  objectbox.maybePopulate();

  await NotificationService().init();

  await Settings.init();

  // Without this MaterialApp, get errors when navigating from dropdown menu.
  // TODO: Figure out how to consolidate to a single MaterialApp.
  runApp(MaterialApp(
    theme: ThemeData(
      brightness: Brightness.light,
    ),
    darkTheme: ThemeData(
      brightness: Brightness.dark,
    ),
    themeMode: ThemeMode.system,

    debugShowCheckedModeBanner: false,
    home: FrendApp()),
  );
}

class FrendApp extends StatelessWidget {
  const FrendApp({Key? key}) : super(key: key);

  void _goToTagList(context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tags'),
            ),
            body: TagList(),
          );
        },
      ),
    );
  }

  void _goToHelpPage(context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Help'),
            ),
            body: HelpPage(),
          );
        },
      ),
    );
  }

  void _goToSettingsPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          print("in settings page cb");
          return SettingsPage();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: this getInstance is no longer necessary but keeps the widget from crashing, should fix.
    SharedPreferences.getInstance().then((prefs) async {
      var showHelp = Settings.getValue<bool>("show-help", true);
      if (showHelp) {
        showConfirmationDialog(context, "Welcome!", "Would you like to view the help page?",
                () => _goToHelpPage(context));
        await Settings.setValue<bool>("show-help", false);
      }
    });

    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,

      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        animationDuration: Duration.zero,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AppBar(
              toolbarHeight: 25,
              title: const Text('Frend'),
              bottom: const TabBar(
                tabs: [
                  SizedBox(
                    height: 35,
                    child: Tab(text: "Events"),
                  ),
                  SizedBox(
                    height: 35,
                    child: Tab(text: "Friends"),
                  )
                ],
              ),
              actions: [
                DropdownButton<String>(
                  icon: const Icon(Icons.settings),
                  underline: Container(height: 0),
                  onChanged: (String? newValue) {},
                  items: [
                    DropdownMenuItem<String>(
                      value: "Tags",
                      child: const Text("Tags"),
                      onTap: () => _goToTagList(context),
                    ),
                    DropdownMenuItem<String>(
                      value: "Settings",
                      child: const Text("Settings"),
                      onTap: () => _goToSettingsPage(context),
                    ),
                    DropdownMenuItem<String>(
                      value: "Help",
                      child: const Text("Help"),
                      onTap: () => _goToHelpPage(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              EventCalendar(),
              FriendList(),
            ],
          ),
        ),
      ),
    );
  }
}
