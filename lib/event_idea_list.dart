import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:frend/event_suggestions.dart';
import 'package:frend/filter_list.dart';
import 'package:frend/objectbox.g.dart';

import 'model.dart';
import 'db.dart';
import 'event_detail.dart';


// TODO: Merge this with EventList?
class EventIdeaList extends StatefulWidget {
  final DateTime? date;
  final int? friendId;
  final Set<String>? tags;

  const EventIdeaList({Key? key, this.date, this.friendId, this.tags}) : super(key: key);

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

    if (widget.tags != null) {
      for (var tag in widget.tags!) {
        _selectedTags.add(tag);
      }
    }

    objectbox.getEventIdeaQueryStream().listen((q) {
      if (mounted) {
        _dataUpdated(q.find());
      }
    });
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
    Set<String> tagNames = {};
    for (var tag in _allTags) {
      tagNames.add(tag.title);
    }

    return FilterList(
      tags: tagNames,
      initialSelection: _selectedTags,
      selectionCallback: _tagSelectionCallback,
      deselectionCallback: _tagDeselectionCallback,
    );
  }

  void _goToEventDetail(Event event, bool copy) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EventDetail(
            event: copy ? event.getConcreteEvent(widget.date) : event,
            date: copy ? widget.date : null,
            friendId: widget.friendId,
          );
        },
      ),
    );
  }

  void _goToSuggestEvents() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EventSuggestions(date: widget.date);
        },
      ),
    );
  }

  GestureDetector Function(BuildContext, int) _itemBuilder(List<Event> events) =>
          (BuildContext context, int index) => GestureDetector(
        child: Card(
          child: ListTile(
            title: Text(events[index].title),
            trailing: Wrap(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _goToEventDetail(events[index], true),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _goToEventDetail(events[index], false),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Create an Event'),
    ),
    body: Column(children: <Widget>[
      _filterChips(),
      Expanded(
          child: StreamBuilder<List<Event>>(
              builder: (context, snapshot) => ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: _events.length,
                  itemBuilder: _itemBuilder(_events)))),
    ]),

    floatingActionButton: SpeedDial(
      icon: Icons.add,
      spaceBetweenChildren: 5,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.lightbulb),
          label: 'Add Event Idea',
          onTap: () => _goToEventDetail(Event("", isIdea: true), false),
        ),
        SpeedDialChild(
          child: const Icon(Icons.event),
          label: 'Create One-off Event',
          onTap: () => _goToEventDetail(Event("", date: widget.date), false),
        ),
        SpeedDialChild(
          child: const Icon(Icons.groups),
          label: 'Suggest Events',
          onTap: () => _goToSuggestEvents(),
        ),
      ],
    ),
  );
}
