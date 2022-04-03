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
  Map<FriendshipLevel, StreamController<List<Friend>>> _listControllers = {};

  @override
  void initState() {
    super.initState();

    _listControllers[FriendshipLevel.friend] = StreamController<List<Friend>>(sync: true);
    _listControllers[FriendshipLevel.friend]?.addStream(objectbox.getFriendQueryStream().map((q) => q.find()));

    _listControllers[FriendshipLevel.acquaintance] = StreamController<List<Friend>>(sync: true);
    _listControllers[FriendshipLevel.acquaintance]?.addStream(objectbox.getAcquaintanceQueryStream().map((q) => q.find()));

    _listControllers[FriendshipLevel.outOfTouch] = StreamController<List<Friend>>(sync: true);
    _listControllers[FriendshipLevel.outOfTouch]?.addStream(objectbox.getOutOfTouchFriendQueryStream().map((q) => q.find()));

    setState(() {});
  }

  @override
  void dispose() {
    for (var c in _listControllers.values) {
      c.close();
    }

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
                      const Spacer(),
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
        settings: const RouteSettings(name: "friend"),
        builder: (context) {
          return FriendDetail(friendId: id);
        },
      ),
    );
  }

  Container _getSectionHeader(String title) {
    return Container(
      child: Text(
        title, style: TextStyle(fontSize: 20),
      ),
      padding: EdgeInsets.all(10),
      alignment: Alignment.centerLeft,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(children: <Widget>[
      _getSectionHeader("Friends"),
      StreamBuilder<List<Friend>>(
          stream: _listControllers[FriendshipLevel.friend]?.stream,
          builder: (context, snapshot) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: snapshot.hasData ? snapshot.data!.length : 0,
              itemBuilder: _itemBuilder(snapshot.data ?? []))),
      // TODO: hide conditionally
      _getSectionHeader("Out-of-touch Friends"),
      StreamBuilder<List<Friend>>(
          stream: _listControllers[FriendshipLevel.outOfTouch]?.stream,
          builder: (context, snapshot) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: snapshot.hasData ? snapshot.data!.length : 0,
              itemBuilder: _itemBuilder(snapshot.data ?? []))),
      _getSectionHeader("Acquaintances"),
      StreamBuilder<List<Friend>>(
          stream: _listControllers[FriendshipLevel.acquaintance]?.stream,
          builder: (context, snapshot) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: snapshot.hasData ? snapshot.data!.length : 0,
              itemBuilder: _itemBuilder(snapshot.data ?? []))),
    ]),
    floatingActionButton: FloatingActionButton(
      key: const Key('submit'),
      onPressed: () => _goToFriendDetail(null),
      child: const Icon(Icons.add),
    ),
  );
}
