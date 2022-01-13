import 'package:flutter/material.dart';
import 'package:frend/filters.dart';
import 'package:frend/objectbox.g.dart';

import 'model.dart';
import 'db.dart';
import 'event_detail.dart';


// TODO: Merge this with EventList?
class EventIdeaList extends StatefulWidget {
  const EventIdeaList({Key? key}) : super(key: key);

  @override
  _EventIdeaListState createState() => _EventIdeaListState();
}

class _EventIdeaListState extends State<EventIdeaList> {
  late List<Tag> _allTags;
  final Set<String> _selectedTags = {};
  final List<Event> _events = [];

  @override
  void initState() {
    super.initState();

    _allTags = objectbox.tagBox.getAll();

    objectbox.getEventIdeaQueryStream().map((q) {
      _dataUpdated(q.find());
    });

    _dataUpdated(objectbox.eventBox.query(Event_.isIdea.equals(true)).build().find());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _dataUpdated(List<Event> events) {
    _events.clear();

    if (_selectedTags.isEmpty) {
      _events.addAll(events);
      setState(() {});
      return;
    }

    // TODO: try out using ToMany query with Ors - apparently don't work well right now.
    for (var event in events) {
      for (var tag in event.tags) {
        if (_selectedTags.contains(tag.title)) {
          _events.add(event);
          break;
        }
      }
    }

    setState(() {});
  }

  void _tagSelectionCallback(String tag) {
    _selectedTags.add(tag);
    _dataUpdated(objectbox.eventBox.query(Event_.isIdea.equals(true)).build().find());
  }
  void _tagDeselectionCallback(String tag) {
    _selectedTags.remove(tag);
    _dataUpdated(objectbox.eventBox.query(Event_.isIdea.equals(true)).build().find());
  }

  Widget _filterChips() {
    List<String> tagNames = [];
    for (var tag in _allTags) {
      tagNames.add(tag.title);
    }

    return FilterList(
      tags: tagNames,
      selectionCallback: _tagSelectionCallback,
      deselectionCallback: _tagDeselectionCallback,
    );
  }

  void _goToEventDetail(Event event, bool copy) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EventDetail(
            event: copy ? event.getConcreteEvent() : event,
          );
        },
      ),
    );
  }

  GestureDetector Function(BuildContext, int) _itemBuilder(List<Event> events) =>
          (BuildContext context, int index) => GestureDetector(
        onTap: () => _goToEventDetail(events[index], true),
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
                        events[index].title,
                        style: const TextStyle(
                          fontSize: 15.0,
                        ),
                        // Provide a Key for the integration test
                        key: Key('list_item_$index'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () => _goToEventDetail(events[index], false),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(children: <Widget>[
      ElevatedButton(
        child: const Text('Custom Event'),
        onPressed: () => _goToEventDetail(Event(""), false),
      ),
      _filterChips(),
      Expanded(
          child: StreamBuilder<List<Event>>(
              builder: (context, snapshot) => ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: _events.length,
                  itemBuilder: _itemBuilder(_events)))),
    ]),
    floatingActionButton: FloatingActionButton(
      key: const Key('submit'),
      onPressed: () => _goToEventDetail(Event("", isIdea: true), false),
      child: const Icon(Icons.add),
    ),
  );
}
