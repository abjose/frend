import 'package:flutter/material.dart';
import 'package:frend/event_list.dart';
// import 'package:frend/random_words.dart';
import 'package:frend/friend_list.dart';
import 'dart:async';
import 'db.dart';

// ignore_for_file: public_member_api_docs


Future<void> main() async {
  // This is required so ObjectBox can get the application directory
  // to store the database in.
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();

  runApp(const FrendApp());
}

class FrendApp extends StatelessWidget {
  const FrendApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: "Events"),
                Tab(text: "Friends"),
                // Tab(icon: Icon(Icons.directions_car)),
                // Tab(icon: Icon(Icons.directions_transit)),
                // Tab(icon: Icon(Icons.directions_bike)),
              ],
            ),
            title: const Text('Tabs Demo'),
          ),
          body: const TabBarView(
            children: [
              EventList(),
              FriendList(),
            ],
          ),
        ),
      ),
    );
  }
}

