import 'package:flutter/material.dart';
import 'dart:async';

import 'model.dart';
import 'db.dart';
import 'friend_detail.dart';


class FriendList extends StatefulWidget {
  const FriendList({Key? key}) : super(key: key);

  @override
  _FriendListState createState() => _FriendListState();
}

class _FriendListState extends State<FriendList> {
  final _listController = StreamController<List<Friend>>(sync: true);

  @override
  void initState() {
    super.initState();

    _listController.addStream(objectbox.getFriendQueryStream().map((q) => q.find()));

    setState(() {});
  }

  @override
  void dispose() {
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
                      vertical: 14.0, horizontal: 10.0),
                  child: Row(
                    children: <Widget>[
                      Text(
                        friends[index].name,
                        style: const TextStyle(
                          fontSize: 15.0,
                        ),
                        // Provide a Key for the integration test
                        key: Key('list_item_$index'),
                      ),
                      Spacer(),
                      if (friends[index].overdue())
                        const Icon(
                          Icons.announcement,
                          color: Colors.red,
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
          return FriendDetail(friendId: id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
