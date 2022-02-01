import 'package:flutter/material.dart';
import 'package:frend/friend_list.dart';
import 'package:frend/calendar.dart';
import 'package:frend/tag_list.dart';
import 'dart:async';
import 'db.dart';
import 'notification_service.dart';


Future<void> main() async {
  // This is required so ObjectBox can get the application directory
  // to store the database in.
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();

  await NotificationService().init();

  // runApp(const FrendApp());
  runApp(FrendApp());
}

class FrendApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: FrendHome()
    );
  }
}

class FrendHome extends StatelessWidget {
  // const FrendHome({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Frend'),
            bottom: const TabBar(
              tabs: [
                Tab(text: "Events"),
                Tab(text: "Friends"),
              ],
            ),
            actions: [
              DropdownButton<String>(
                icon: const Icon(Icons.settings, color: Colors.white),
                // elevation: 16,
                style: const TextStyle(color: Colors.black),
                underline: Container(height: 0),
                onChanged: (String? newValue) {},// onChanged: null,
                items: [
                  DropdownMenuItem<String>(
                    value: "Tags",
                    child: Text("Tags"),
                    onTap: () => _goToTagList(context),
                  ),
                  DropdownMenuItem<String>(
                    value: "Settings",
                    child: Text("Settings"),
                    onTap: () => print("settings!"),
                  ),
                ],
              ),
            ],
          ),
          body: TabBarView(
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

