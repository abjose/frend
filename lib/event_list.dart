import 'package:flutter/material.dart';
import 'dart:async';

import 'model.dart';
import 'db.dart';
import 'event_detail.dart';


class EventList extends StatefulWidget {
  const EventList({Key? key}) : super(key: key);

  @override
  _EventListState createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  final _eventInputController = TextEditingController();
  final _listController = StreamController<List<Event>>(sync: true);

  @override
  void initState() {
    super.initState();

    setState(() {});

    // _listController.addStream(objectbox.queryStream.map((q) => q.find()));
    // _listController.addStream(objectbox.getNoteQueryStream().map((q) => q.find()));
    _listController.addStream(objectbox.getEventQueryStream().map((q) => q.find()));
  }

  @override
  void dispose() {
    _eventInputController.dispose();
    _listController.close();
    super.dispose();
  }

  GestureDetector Function(BuildContext, int) _itemBuilder(List<Event> events) =>
          (BuildContext context, int index) => GestureDetector(
        onTap: () => _goToEventDetail(events[index].id),
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
                        events[index].title!,
                        style: const TextStyle(
                          fontSize: 15.0,
                        ),
                        // Provide a Key for the integration test
                        key: Key('list_item_$index'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          'Added on ${events[index].dateFormat}',
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

  void _goToEventDetail(int? id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Event'),
            ),
            body: EventDetail(
              eventId: id,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(children: <Widget>[
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
      onPressed: () => _goToEventDetail(null),
      child: const Icon(Icons.add),
    ),
  );
}
