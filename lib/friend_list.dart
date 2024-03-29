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
  Map<FriendshipLevel, StreamBuilder<List<Friend>>> _streamBuilders = {};

  @override
  void dispose() {
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
                    border: Border(bottom: BorderSide(color: Colors.black54))),
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
  
  Stream<List<Friend>>? _getStream(FriendshipLevel level) {
    // TODO: is the `map`-ing here the source of the multiple listeners issue?
    switch (level) {
      case FriendshipLevel.friend:
        return objectbox.getFriendQueryStream().map((q) => q.find());
      case FriendshipLevel.acquaintance:
        return objectbox.getAcquaintanceQueryStream().map((q) => q.find());
      case FriendshipLevel.outOfTouch:
        return objectbox.getOutOfTouchFriendQueryStream().map((q) => q.find());
      default:
        assert(false);  // TODO
    }

    return null;
  }

  Widget _getFriendStreamWidget(FriendshipLevel level) {
    if (!_streamBuilders.containsKey(level)) {
      _streamBuilders[level] = StreamBuilder<List<Friend>>(
          stream: _getStream(level),
          builder: (context, snapshot) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: snapshot.hasData ? snapshot.data!.length : 0,
              itemBuilder: _itemBuilder(snapshot.data ?? [])));
    }


    return _streamBuilders[level]!;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(children: <Widget>[
      // TODO: hide conditionally?
      _getSectionHeader("Friends"),
      _getFriendStreamWidget(FriendshipLevel.friend),

      _getSectionHeader("Acquaintances"),
      _getFriendStreamWidget(FriendshipLevel.acquaintance),

      _getSectionHeader("Out-of-touch Friends"),
      _getFriendStreamWidget(FriendshipLevel.outOfTouch),
    ]),
    floatingActionButton: FloatingActionButton(
      key: const Key('submit'),
      onPressed: () => _goToFriendDetail(null),
      child: const Icon(Icons.add),
    ),
  );
}
