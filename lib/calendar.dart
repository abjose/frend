import 'package:flutter/material.dart';
import 'package:frend/db.dart';
import 'package:frend/model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';

import 'event_detail.dart';
import 'event_idea_list.dart';


/// Example events.
///
/// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
// final kEvents = LinkedHashMap<DateTime, List<ExampleEvent>>(
//   equals: isSameDay,
//   hashCode: getHashCode,
// )..addAll(_kEventSource);

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);


class EventCalendar extends StatefulWidget {
  const EventCalendar({Key? key}) : super(key: key);

  @override
  _EventCalendarState createState() => _EventCalendarState();
}

class _EventCalendarState extends State<EventCalendar> {
  final _nonRepeatingEvents = LinkedHashMap<DateTime, List<Event>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );
  final _repeatingEvents = LinkedHashMap<DateTime, List<Event>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

    _nonRepeatingEvents.clear();
    _repeatingEvents.clear();

    for (var event in objectbox.getNonRepeatingEvents()) {
      if (!_nonRepeatingEvents.containsKey(event.date)) {
        _nonRepeatingEvents[event.date] = [];
      }
      _nonRepeatingEvents[event.date]?.add(event);
    }

    for (var event in objectbox.getRepeatingEvents()) {
      if (!_repeatingEvents.containsKey(event.date)) {
        _repeatingEvents[event.date] = [];
      }
      _repeatingEvents[event.date]?.add(event);
    }

    objectbox.getEventQueryStream().listen((event) {
      // Listen for even changes and setState so will properly display changes to even times.
      // TODO: better way to do this?
      setState(() {});
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    List<Event> events = _nonRepeatingEvents[day] ?? [];

    // TODO: handle repeating events
    // also be careful about times being out of order...
    // maybe instead should have all events in one thing, then another with just repeating
    // and for all the repeating ones, only add the repeats.
    if (_repeatingEvents.containsKey(day)) {
      events.addAll(_repeatingEvents[day]!);
    }

    return events;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _goToEventIdeaList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Event Ideas'),
            ),
            body: EventIdeaList(date: _selectedDay),
          );
        },
      ),
    );
  }

  void _goToEventDetail(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EventDetail(event: event);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeSelectionMode: RangeSelectionMode.toggledOff,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              // Use `CalendarStyle` to customize the UI
              outsideDaysVisible: false,
            ),
            onDaySelected: _onDaySelected,
            availableCalendarFormats: {CalendarFormat.month : '2 Weeks', CalendarFormat.twoWeeks : 'Month'},
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        onTap: () => _goToEventDetail(value[index]),
                        title: Text('${value[index].title}'),
                        trailing: Text("${value[index].timeFormat}"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('submit'),
        onPressed: _goToEventIdeaList,
        child: const Icon(Icons.add),
      ),
    );
  }
}
