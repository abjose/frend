import 'package:flutter/material.dart';
import 'dart:async';

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
  final _listController = StreamController<List<Event>>(sync: true);

  @override
  void initState() {
    super.initState();

    setState(() {});

    _listController.addStream(objectbox.getEventIdeaQueryStream().map((q) => q.find()));
  }

  @override
  void dispose() {
    _listController.close();
    super.dispose();
  }

  void _goToEventDetail(Event event, bool copy) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Edit Event${ copy ? "" : " Idea"}'),
            ),
            body: EventDetail(
              event: copy ? event.getConcreteEvent() : event,
            ),
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
      Expanded(
          child: StreamBuilder<List<Event>>(
              stream: _listController.stream,
              builder: (context, snapshot) => ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: snapshot.hasData ? snapshot.data!.length : 0,
                  itemBuilder: _itemBuilder(snapshot.data ?? []))))
    ]),
    floatingActionButton: FloatingActionButton(
      key: const Key('submit'),
      onPressed: () => _goToEventDetail(Event("", isIdea: true), false),
      child: const Icon(Icons.add),
    ),
  );
}
