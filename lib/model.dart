import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';  // don't get rid of this...

import 'db.dart';
import 'notification_service.dart';
import 'objectbox.g.dart';

// run:
// flutter pub run build_runner build
// also... might have to comment out objectbox.g.dart import above?


@Entity()
class Friend {
  int id = 0;
  String name;

  @Property(type: PropertyType.date)
  DateTime birthdate;

  // Objectbox doesn't seem to like nullable DateTimes, so approximate it with this.
  bool birthdateSet;

  // If set, remind user to schedule an event with this Friend if there are no upcoming events
  // within the next `overdueWeeks` weeks.
  int? overdueWeeks;

  // Used for making "targeted" suggestions for this friendship, and for grouping friends together.
  FriendshipLevel friendshipLevel;

  final interests = ToMany<Tag>();
  List<String> notes = [];

  // TODO
  Friend(this.name, {this.id = 0, DateTime? date})
      : birthdate = date ?? DateTime.now(),
        birthdateSet = date != null,
        friendshipLevel = FriendshipLevel.friend;

  String get dateFormat => birthdateSet ? DateFormat.yMMMMd('en_US').format(birthdate) : "Unknown";

  // Returns true if this friend doesn't have an upcoming event within reminderToSchedule weeks.
  bool overdue() {
    if (overdueWeeks == null) {
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

    int overdueDays = overdueWeeks! * 7;

    var now = DateTime.now();  // TODO: bad idea?
    // events.removeWhere((event) => event.date.isBefore(now));

    // Check if first event is soon enough.
    try {
      Event soonestEvent = events.firstWhere((event) => event.date.isAfter(now));
      if (soonestEvent.date.difference(now).inDays <= overdueDays) {
        return false;
      }
    } catch (e) {
      // print("Found no future events");
    }

    // If not, check if maybe there's a repeating event happening soon.
    for (var event in events) {
      DateTime? soonest = event.soonestRepeat(now);
      if (soonest == null) {
        continue;
      }

      if (soonest.isBefore(now.add(Duration(days: overdueDays))))  {
        return false;
      }
    }

    return true;
  }

  int? get dbFriendshipLevel {
    _ensureStableEnumValues();
    return friendshipLevel.index;
  }

  set dbFriendshipLevel(int? value) {
    _ensureStableEnumValues();
    if (value == null) {
      friendshipLevel = FriendshipLevel.friend;
    } else {
      friendshipLevel = FriendshipLevel.values[value];
    }
  }

  void _ensureStableEnumValues() {
    assert(FriendshipLevel.unknown.index == 0);
    assert(FriendshipLevel.acquaintance.index == 1);
    assert(FriendshipLevel.outOfTouch.index == 2);
    assert(FriendshipLevel.friend.index == 3);
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

  // How often to repeat this event, if at all.
  // NOTE: previously this was an int representing days between repeats, but due to limitations of
  // the notification system, it was changed to an enum with just a few options. If ever switch to
  // another notification system, might be worth reconsidering all the extra complexity of this change.
  RepeatFrequency frequency;

  final friends = ToMany<Friend>();
  var tags = ToMany<Tag>();

  Event(this.title, {this.id = 0, DateTime? date, bool? isIdea})
      : date = date ?? DateTime.now(), isIdea = isIdea ?? false,
        frequency = RepeatFrequency.never;

  String get dateFormat => DateFormat.yMd().format(date);
  String get timeFormat => DateFormat.Hm().format(date);

  String getFriendString() {
    String friendString = "With ";
    for (var friend in friends) {
      friendString += "${friend.name}, ";
    }
    friendString = friendString.substring(0, friendString.length - 2);

    return friendString;
  }

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
    DateTime? soonest = soonestRepeat(date);
    if (soonest == null) {
      return false;
    }

    DateTime day = DateUtils.dateOnly(date);
    return soonest == day;
  }

  // Returns date of soonest repeat on or after passed date.
  DateTime? soonestRepeat(DateTime target) {
    if (frequency == RepeatFrequency.never || frequency == RepeatFrequency.unknown) {
      return null;
    }

    DateTime targetDay = DateUtils.dateOnly(target);
    DateTime day = DateUtils.dateOnly(date);
    if (targetDay.isBefore(day)) {
      return day;
    }
    if (frequency == RepeatFrequency.daily) {
      return targetDay;
    }

    // Take a stab at closest day - if not right, just increment the guess.
    DateTime maybeClosestDay = DateTime(
      targetDay.year,
      frequency == RepeatFrequency.yearly ? day.month : targetDay.month,
      frequency == RepeatFrequency.weekly ? (targetDay.day / 7).floor() * 7 + day.day % 7 : day.day,
    );

    if (maybeClosestDay == targetDay || maybeClosestDay.isAfter(targetDay)) {
      return maybeClosestDay;
    }

    // Otherwise, increment relevant field.
    return DateTime(
      frequency == RepeatFrequency.yearly ? maybeClosestDay.year + 1 : maybeClosestDay.year,
      frequency == RepeatFrequency.monthly ? maybeClosestDay.month + 1 : maybeClosestDay.month,
      frequency == RepeatFrequency.weekly ? maybeClosestDay.day + 7 : maybeClosestDay.day,
    );
  }

  void updateNotification() {
    assert(!isIdea);

    // Cancel existing notification just in case.
    deleteNotification().then((value) {
      if (date.isBefore(DateTime.now()) || frequency == RepeatFrequency.unknown) {
        return;
      }

      // Then re-schedule.
      NotificationService().scheduleNotification(
          id, title, friends.isEmpty ? null : getFriendString(), id.toString(), date, frequency);
    });
  }

  Future<void> deleteNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  int? get dbFrequency {
    _ensureStableEnumValues();
    return frequency.index;
  }

  set dbFrequency(int? value) {
    _ensureStableEnumValues();
    if (value == null) {
      frequency = RepeatFrequency.never;
    } else {
      frequency = RepeatFrequency.values[value];
    }
  }

  void _ensureStableEnumValues() {
    assert(RepeatFrequency.unknown.index == 0);
    assert(RepeatFrequency.never.index == 1);
    assert(RepeatFrequency.daily.index == 2);
    assert(RepeatFrequency.weekly.index == 3);
    assert(RepeatFrequency.monthly.index == 4);
    assert(RepeatFrequency.yearly.index == 5);
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


enum RepeatFrequency {
  unknown,
  never,
  daily,
  weekly,
  monthly,
  yearly,
}


extension RepeatFrequencyExtension on RepeatFrequency {
  String get string {
    switch (this) {
      case RepeatFrequency.never:
        return 'Never';
      case RepeatFrequency.daily:
        return 'Daily';
      case RepeatFrequency.weekly:
        return 'Weekly';
      case RepeatFrequency.monthly:
        return 'Monthly';
      case RepeatFrequency.yearly:
        return 'Yearly';
      default:
        return 'Unknown';
    }
  }
}


extension RepeatFrequencyDateTimeComponentsExtension on RepeatFrequency {
  DateTimeComponents? get dateTimeComponents {
    switch (this) {
      case RepeatFrequency.unknown:  // fall through
      case RepeatFrequency.never:
        return null;
      case RepeatFrequency.daily:
        return DateTimeComponents.time;
      case RepeatFrequency.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatFrequency.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case RepeatFrequency.yearly:
        return DateTimeComponents.dateAndTime;
    }
  }
}


enum FriendshipLevel {
  unknown,
  acquaintance,
  outOfTouch,
  friend,
}


extension FriendshipLevelExtension on FriendshipLevel {
  String get string {
    switch (this) {
      case FriendshipLevel.acquaintance:
        return 'Acquaintance';
      case FriendshipLevel.outOfTouch:
        return 'Out-of-touch Friend';
      case FriendshipLevel.friend:
        return 'Friend';

      default:
        return 'Unknown';
    }
  }
}