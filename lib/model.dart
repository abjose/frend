import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';

import 'db.dart';
import 'notification_service.dart';
import 'objectbox.g.dart';

// run:
// flutter pub run build_runner build

@Entity()
class Friend {
  int id = 0;
  String name;

  @Property(type: PropertyType.date)
  DateTime birthdate;

  // If set, remind user to schedule an event with this Friend if there are no upcoming events
  // within the next `reminderToSchedule` days.
  int? reminderToSchedule;

  final interests = ToMany<Tag>();
  List<String> notes = [];

  // TODO
  Friend(this.name, {this.id = 0, DateTime? date})
      : birthdate = date ?? DateTime.now();

  String get dateFormat => DateFormat.yMMMMd('en_US').format(birthdate);

  // Returns true if this friend doesn't have an upcoming event within reminderToSchedule weeks.
  bool overdue() {
    if (reminderToSchedule == null) {
      // print("reminderToSchedule is null");
      return false;
    }

    // List of events involving this friend, sorted by date.
    // QueryBuilder<Event> builder = objectbox.eventBox.query(Event_.date.greaterOrEqual(DateTime.now()));
    QueryBuilder<Event> builder = objectbox.eventBox.query();
    builder.linkMany(Event_.friends, Friend_.id.equals(id));
    builder.order(Event_.date);
    List<Event> events = builder.build().find();

    if (events.isEmpty) {
      return true;
    }

    var now = DateTime.now();  // TODO: bad idea?
    // events.removeWhere((event) => event.date.isBefore(now));

    // Check if first event is soon enough.
    try {
      Event soonestEvent = events.firstWhere((event) => event.date.isAfter(now));
      if (soonestEvent.date.difference(now).inDays <= reminderToSchedule!) {
        return false;
      }
    } catch (e) {
      // print("Found no future events");
    }

    // If not, check if maybe there's a repeating event happening soon.
    for (var event in events) {
      if (event.repeatDays == null || event.repeatDays! == 0) {
        continue;
      }

      int? soonestRepeat = event.soonestRepeat(now);
      if (soonestRepeat != null && soonestRepeat <= reminderToSchedule!) {
        return false;
      }
    }

    return true;
  }
}

@Entity()
class Event {
  int id = 0;
  String title;
  String? description;

  // If true, will only be shown in Event Ideas list.
  bool isIdea = false;

  @Property(type: PropertyType.date)
  DateTime date;
  // If set, event repeats after this many days. TODO: this probably needs to be fancier
  int? repeatDays;

  final friends = ToMany<Friend>();
  var tags = ToMany<Tag>();

  // TODO
  Event(this.title, {this.id = 0, DateTime? date, bool? isIdea})
      : date = date ?? DateTime.now(), isIdea = isIdea ?? false;

  String get dateFormat => DateFormat.yMd().format(date);
  String get timeFormat => DateFormat.Hm().format(date);

  // Get non-idea version of this event.
  Event getConcreteEvent(DateTime? date) {
    assert(isIdea);
    var event = Event(title, date: date);
    for (var tag in tags) {
      event.tags.add(tag);
    }
    return event;
  }

  bool repeatsOnDay(DateTime date) {
    if (repeatDays ==  null || repeatDays! == 0) {
      return false;
    }
    return soonestRepeat(date) == 0;
  }

  // Returns days until soonest repeat on or after passed date.
  int? soonestRepeat(DateTime target) {
    DateTime targetDay = DateUtils.dateOnly(target);
    if (repeatDays != null && repeatDays! > 0) {
      DateTime day = DateUtils.dateOnly(date);
      if (targetDay.isBefore(day)) {
        return (day.difference(targetDay).inHours / 24).round();
      }

      int dayDiff = (targetDay.difference(day).inHours / 24).round();
      return dayDiff % repeatDays!;
    }

    return null;
  }

  void updateNotification() {
    assert(!isIdea);

    // Cancel existing notification just in case.
    deleteNotification().then((value) {
      // Then re-schedule.
      String friendString = "With ";
      for (var friend in friends) {
        friendString += "${friend.name}, ";
      }

      NotificationService().scheduleNotification(
          id, title, friends.isEmpty ? null : friendString, id.toString(), date);
    });
  }

  Future<void> deleteNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}

@Entity()
class Tag {
  int id = 0;

  @Unique(onConflict: ConflictStrategy.replace)
  String title;

  Tag(this.title);
}

// probably don't need this, could just have a list of notes on Friend
@Entity()
class Note {
  int id;

  String text;
  String? comment;

  /// Note: Stored in milliseconds without time zone info.
  @Property(type: PropertyType.date)
  DateTime date;

  Note(this.text, {this.id = 0, this.comment, DateTime? date})
      : date = date ?? DateTime.now();

  String get dateFormat => DateFormat('dd.MM.yyyy hh:mm:ss').format(date);
}
