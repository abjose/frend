import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frend/objectbox.g.dart';

import 'model.dart';
import 'db.dart';
import 'event_detail.dart';


class EventSuggestions extends StatefulWidget {
  final DateTime? date;
  final int numSuggestions = 5;

  const EventSuggestions({Key? key, this.date}) : super(key: key);

  @override
  _EventSuggestionsState createState() => _EventSuggestionsState();
}

class _EventSuggestionsState extends State<EventSuggestions> {
  late List<Friend> _friends;
  late List<Event> _eventIdeas;
  final List<Event> _suggestions = [];


  @override
  void initState() {
    super.initState();

    _eventIdeas = objectbox.eventBox.query(Event_.isIdea.equals(true)).build().find();
    _friends = objectbox.friendBox.getAll();

    _refreshSuggestions();
  }

  void _refreshSuggestions() {
    _suggestions.clear();

    for (int i = 0; i < widget.numSuggestions; ++i) {
      Event newEvent = _eventIdeas[Random().nextInt(_eventIdeas.length)].getConcreteEvent(widget.date);
      newEvent.friends.add(_friends[Random().nextInt(_friends.length)]);
      _suggestions.add(newEvent);
    }

    setState(() {});
  }

  List<ListTile> _getSuggestionTiles() {
    List<ListTile> tiles = [];

    for (var event in _suggestions) {
      tiles.add(ListTile(
        title: Text(event.title),
        subtitle: event.friends.isEmpty ? null : Text(
            event.getFriendString()),
        trailing: Wrap(
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _goToEventDetail(event),
            ),
          ],
        ),
      ));
    }

    return tiles;
  }

  void _goToEventDetail(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EventDetail(
            event: event,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Create an Event'),
    ),
    body: ListView(
      children: _getSuggestionTiles(),
    ),

    floatingActionButton: FloatingActionButton(
      key: const Key('refresh'),
      onPressed: _refreshSuggestions,
      child: const Icon(Icons.refresh),
    ),
  );
}
