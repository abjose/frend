import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';

import 'objectbox.g.dart';

// run:
// flutter pub run build_runner build

@Entity()
class Friend {
  int id = 0;
  String name;

  @Property(type: PropertyType.date)
  DateTime birthdate;

  final interests = ToMany<Tag>();
  List<String> notes = [];

  // TODO
  Friend(this.name, {this.id = 0, DateTime? date})
      : birthdate = date ?? DateTime.now();

  String get dateFormat => DateFormat.yMMMMd('en_US').format(birthdate);
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
  // final tags = ToMany<Tag>();
  var tags = ToMany<Tag>();

  // TODO
  Event(this.title, {this.id = 0, DateTime? date, bool? isIdea})
      : date = date ?? DateTime.now(), isIdea = isIdea ?? false;

  String get dateFormat => DateFormat.yMd().format(date);
  String get timeFormat => DateFormat.Hm().format(date);

  // Get non-idea version of this event.
  Event getConcreteEvent() {
    assert(isIdea);
    var event = Event(title);
    for (var tag in tags) {
      event.tags.add(tag);
    }
    return event;
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
