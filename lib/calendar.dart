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
final kFirstDay = DateTime(kToday.year, kToday.month - 6, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 18, kToday.day);


class EventCalendar extends StatefulWidget {
  const EventCalendar({Key? key}) : super(key: key);

  @override
  _EventCalendarState createState() => _EventCalendarState();
}

class _EventCalendarState extends State<EventCalendar> {
  final _allEvents = LinkedHashMap<DateTime, List<Event>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );
  final List<Event> _repeatingEvents = [];
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Listen for event changes and setState so will properly display changes to even times.
    objectbox.getEventQueryStream().listen((event) {
      // TODO: better way to do this?
      setState(() {
        if (mounted) {
          _refreshEventCache();
        }
      });
    });

    _selectedEvents = ValueNotifier([]);
    _refreshEventCache();
  }

  void _refreshEventCache() {
    _repeatingEvents.clear();
    _repeatingEvents.addAll(objectbox.getRepeatingEvents());

    _allEvents.clear();
    for (var event in objectbox.getRealEvents()) {
      if (!_allEvents.containsKey(event.date)) {
        _allEvents[event.date] = [];
      }
      _allEvents[event.date]?.add(event);
    }

    _selectedEvents.value = _getEventsForDay(_selectedDay);
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime date) {
    DateTime day = DateUtils.dateOnly(date);
    List<Event> events = List.from(_allEvents[day] ?? []);

    bool addedRepeatingEvent = false;
    for (var repeatingEvent in _repeatingEvents) {
      if (repeatingEvent.repeatsOnDay(date)) {
        events.add(repeatingEvent);
        addedRepeatingEvent = true;
      }
    }

    if (addedRepeatingEvent) {
      events.sort((a, b) => a.date.compareTo(b.date));
    }

    return events;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
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
            focusedDay: _selectedDay,
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
