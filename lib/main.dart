import 'package:flutter/material.dart';
import 'package:frend/friend_list.dart';
import 'package:frend/calendar.dart';
import 'package:frend/tag_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import 'db.dart';
import 'help_page.dart';
import 'notification_service.dart';

Future<void> main() async {
  // This is required so ObjectBox can get the application directory
  // to store the database in.
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();
  objectbox.maybePopulate();

  await NotificationService().init();

  runApp(FrendApp());
}

class FrendApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: FrendHome());
  }
}

class FrendHome extends StatelessWidget {
  const FrendHome({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    SharedPreferences.getInstance().then((prefs) {
      var shown = prefs.getBool("introShown");
      if (shown == null || !shown) {
        _goToHelpPage(context);
      }
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
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
                  icon: const Icon(Icons.settings, color: Colors.white),
                  // elevation: 16,
                  style: const TextStyle(color: Colors.black),
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
                      onTap: () => print("settings!"),
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
