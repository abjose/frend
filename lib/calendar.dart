import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frend/db.dart';
import 'package:frend/model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';

import 'event_detail.dart';
import 'event_idea_list.dart';
import 'friend_detail.dart';


class CalendarItem {
  CalendarItem({this.event, this.friend}) {
    if (event != null) {
      date = event!.date;
    } else if (friend != null) {
      date = friend!.birthdate;
    }
  }

  Event? event;
  Friend? friend;

  DateTime date = DateTime.now();
}

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
  final _calendarItems = LinkedHashMap<DateTime, List<CalendarItem>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  late final ValueNotifier<List<CalendarItem>> _selectedItems;
  DateTime _selectedDay = DateTime.now();

  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();

    _selectedItems = ValueNotifier([]);

    // Listen for event changes and setState so will properly display changes to even times.
    objectbox.getEventQueryStream().listen((event) {
      // TODO: better way to do this?
      if (mounted) {
        setState(() {
          _refreshEventCache(_selectedDay);
        });
      }
    });
  }

  // Caches events for the passed month.
  void _refreshEventCache(DateTime date) {
    DateTime firstOfMonth = getFirstOfMonth(date);
    _calendarItems.clear();

    // Collect one-offs for this month.
    for (var event in objectbox.getOneOffEvents()) {
      if (!DateUtils.isSameMonth(event.date, firstOfMonth)) {
        continue;
      }

      if (!_calendarItems.containsKey(event.date)) {
        _calendarItems[event.date] = [];
      }
      _calendarItems[event.date]?.add(CalendarItem(event: event));
    }

    // Collect repeats for this month.
    DateTime nextMonth = DateTime(firstOfMonth.year, firstOfMonth.month + 1, firstOfMonth.day);
    for (var event in objectbox.getRepeatingEvents()) {
      DateTime currRepeatDate = event.soonestRepeat(firstOfMonth)!;
      while (currRepeatDate.isBefore(nextMonth)) {
        if (!_calendarItems.containsKey(currRepeatDate)) {
          _calendarItems[currRepeatDate] = [];
        }
        _calendarItems[currRepeatDate]?.add(CalendarItem(event: event));

        currRepeatDate = event.soonestRepeat(currRepeatDate.add(Duration(days: 1)))!;
      }
    }

    // Collect birthdays.
    for (var friend in objectbox.friendBox.getAll()) {
      if (!friend.birthdateSet) {
        continue;
      }

      if (!DateUtils.isSameMonth(friend.birthdate, firstOfMonth)) {
        continue;
      }

      if (!_calendarItems.containsKey(friend.birthdate)) {
        _calendarItems[friend.birthdate] = [];
      }
      _calendarItems[friend.birthdate]?.add(CalendarItem(friend: friend));
    }

    // Sort everything by time (repeating events might be out of order).
    DateTime currDay = DateTime(firstOfMonth.year, firstOfMonth.month, firstOfMonth.day);
    while (currDay.isBefore(nextMonth)) {
      if (_calendarItems.containsKey(currDay)) {
        _calendarItems[currDay]?.sort((a, b) => a.date.compareTo(b.date));
      }
      currDay = currDay.add(Duration(days: 1));
    }

    _selectedItems.value = _getItemsForDay(_selectedDay);
  }

  @override
  void dispose() {
    _selectedItems.dispose();
    super.dispose();
  }

  // Note that this is getting called for EVERY DAY every time setState is called, so should be
  // very lightweight.
  List<CalendarItem> _getItemsForDay(DateTime date) {
    return _calendarItems[date] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _selectedItems.value = _getItemsForDay(selectedDay);
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

  ListTile _getListTile(CalendarItem item) {
    assert(item.event != null || item.friend != null);

    if (item.event != null) {
      return ListTile(
        onTap: () => _goToEventDetail(item.event!),
        title: Text(item.event!.title),
        subtitle: item.event!.friends.isEmpty ? null : Text(
            item.event!.getFriendString()),
        trailing: Text(item.event!.timeFormat),
      );
    }

    if (item.friend != null) {
      return ListTile(
        onTap: () => _goToFriendDetail(item.friend!.id),
        title: Text("${item.friend!.name}'s Birthday"),
        trailing: Text(item.friend!.timeFormat),
      );
    }
    
    return const ListTile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TableCalendar<CalendarItem>(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeSelectionMode: RangeSelectionMode.toggledOff,
            eventLoader: _getItemsForDay,
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
            child: ValueListenableBuilder<List<CalendarItem>>(
              valueListenable: _selectedItems,
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
                      child: _getListTile(value[index]),
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
