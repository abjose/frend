import 'package:flutter/material.dart';
import 'package:frend/random_words.dart';
import 'package:frend/friend_detail.dart';

import 'dart:async';

import 'model.dart';
import 'db.dart';

// ignore_for_file: public_member_api_docs

/// Provides access to the ObjectBox Store throughout the app.
late ObjectBox objectbox;

Future<void> main() async {
  // This is required so ObjectBox can get the application directory
  // to store the database in.
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();

  runApp(const TabBarDemo());
  // runApp(MyApp());
}

class TabBarDemo extends StatelessWidget {
  const TabBarDemo({Key? key}) : super(key: key);

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
              RandomWords(),
              MyApp(),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OB Example',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: const MyHomePage(title: 'OB Example'),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _friendInputController = TextEditingController();
  final _listController = StreamController<List<Friend>>(sync: true);
  // final _listController = StreamController<List<Note>>();
  // final _listController = StreamController<List<Note>>.broadcast();

  void _addFriend() {
    if (_friendInputController.text.isEmpty) return;
    objectbox.friendBox.put(Friend(_friendInputController.text));
    _friendInputController.text = '';
  }

  @override
  void initState() {
    super.initState();

    setState(() {});

    // _listController.addStream(objectbox.queryStream.map((q) => q.find()));
    // _listController.addStream(objectbox.getNoteQueryStream().map((q) => q.find()));
    _listController.addStream(objectbox.getFriendQueryStream().map((q) => q.find()));
  }

  @override
  void dispose() {
    _friendInputController.dispose();
    _listController.close();
    super.dispose();
  }

  GestureDetector Function(BuildContext, int) _itemBuilder(List<Friend> friends) =>
          (BuildContext context, int index) => GestureDetector(
        onTap: () => _goToFriendDetail(friends[index].id),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                    border:
                    Border(bottom: BorderSide(color: Colors.black12))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 18.0, horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        friends[index].name!,
                        style: const TextStyle(
                          fontSize: 15.0,
                        ),
                        // Provide a Key for the integration test
                        key: Key('list_item_$index'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          'Added on ${friends[index].dateFormat}',
                          style: const TextStyle(
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  void _goToFriendDetail(int? id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: FriendDetail(
              friendId: id,
              db: objectbox,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
    ),
    body: Column(children: <Widget>[
      Expanded(
          child: StreamBuilder<List<Friend>>(
              stream: _listController.stream,
              builder: (context, snapshot) => ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: snapshot.hasData ? snapshot.data!.length : 0,
                  itemBuilder: _itemBuilder(snapshot.data ?? []))))
    ]),
    floatingActionButton: FloatingActionButton(
      key: const Key('submit'),
      onPressed: () => _goToFriendDetail(null),
      child: const Icon(Icons.add),
    ),
  );
}
