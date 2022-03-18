import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frend/db.dart';
import 'package:frend/model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';

import 'event_detail.dart';
import 'event_idea_list.dart';


int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

DateTime getFirstOfMonth(DateTime date) {
  return DateTime(date.year, date.month, 1);
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
  final _events = LinkedHashMap<DateTime, List<Event>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  late final ValueNotifier<List<Event>> _selectedEvents;
  DateTime _selectedDay = DateTime.now();

  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();

    _selectedEvents = ValueNotifier([]);

    // Listen for event changes and setState so will properly display changes to even times.
    objectbox.getEventQueryStream().listen((event) {
      // TODO: better way to do this?
      setState(() {
        if (mounted) {
          _refreshEventCache(_selectedDay);
        }
      });
    });
  }

  // Caches events for the passed month.
  void _refreshEventCache(DateTime date) {
    DateTime firstOfMonth = getFirstOfMonth(date);
    _events.clear();

    // Collect one-offs for this month.
    for (var event in objectbox.getOneOffEvents()) {
      if (!_events.containsKey(event.date)) {
        _events[event.date] = [];
      }
      _events[event.date]?.add(event);
    }

    // Collect repeats for this month.
    DateTime nextMonth = DateTime(firstOfMonth.year, firstOfMonth.month + 1, firstOfMonth.day);
    for (var event in objectbox.getRepeatingEvents()) {
      DateTime currRepeatDate = event.soonestRepeat(firstOfMonth)!;
      while (currRepeatDate.isBefore(nextMonth)) {
        if (!_events.containsKey(currRepeatDate)) {
          _events[currRepeatDate] = [];
        }
        _events[currRepeatDate]?.add(event);

        currRepeatDate = event.soonestRepeat(currRepeatDate.add(Duration(days: 1)))!;
      }
    }

    // Sort everything by time (repeating events might be out of order).
    DateTime currDay = DateTime(firstOfMonth.year, firstOfMonth.month, firstOfMonth.day);
    while (currDay.isBefore(nextMonth)) {
      if (_events.containsKey(currDay)) {
        _events[currDay]?.sort((a, b) => a.date.compareTo(b.date));
      }
      currDay = currDay.add(Duration(days: 1));
    }

    _selectedEvents.value = _getEventsForDay(_selectedDay);
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // Note that this is getting called for EVERY DAY every time setState is called, so should be
  // very lightweight.
  List<Event> _getEventsForDay(DateTime date) {
    return _events[date] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  void _goToEventIdeaList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
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
            calendarStyle: const CalendarStyle(
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
            onPageChanged: (date) {
              setState(() {
                _selectedDay = DateTime(date.year, date.month,
                    min(_selectedDay.day, DateUtils.getDaysInMonth(date.year, date.month)));
                _refreshEventCache(_selectedDay);
              });
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
                        subtitle: value[index].friends.isEmpty ? null : Text(value[index].getFriendString()),
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
