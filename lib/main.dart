import 'package:flutter/material.dart';
import 'package:frend/event_list.dart';
// import 'package:frend/random_words.dart';
import 'package:frend/friend_list.dart';
import 'package:frend/searchable_selection_list.dart';
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
            title: const Text('Frend'),
            bottom: const TabBar(
              tabs: [
                Tab(text: "Events"),
                Tab(text: "Friends"),
                // Tab(icon: Icon(Icons.directions_car)),
                // Tab(icon: Icon(Icons.directions_transit)),
                // Tab(icon: Icon(Icons.directions_bike)),
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
                    onTap: () => print("tags!"),
                  ),
                  DropdownMenuItem<String>(
                    value: "Drafts",
                    child: Text("Drafts"),
                    onTap: () => print("drafts!"),
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
          body: const TabBarView(
            children: [
              EventList(),
              // SearchableSelectionList(elements: {13: "Andy", 15: "Aragon", 2: "Bob", 6: "Franco", 98: "Scally"}), // onSelectionChange: testfn),
              FriendList(),
            ],
          ),
        ),
      ),
    );
  }
}

