import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';

import 'objectbox.g.dart';

// run:
// flutter pub run build_runner build

@Entity()
class Friend {
  int id = 0;
  String? name;

  DateTime? birthday;

  String? notes;
  final interests = ToMany<Tag>();
}

@Entity()
class Event {
  int id = 0;
  String? title;
  String? description;

  DateTime? date;
  // If set, event repeats after this many days. TODO: this probably needs to be fancier
  int? repeatDays;
  
  final tags = ToMany<Tag>();
}

@Entity()
class Tag {
  int id = 0;
  String? title;
}

@Entity()
class Note {
  int id;

  String text;
  String? comment;

  /// Note: Stored in milliseconds without time zone info.
  DateTime date;

  Note(this.text, {this.id = 0, this.comment, DateTime? date})
      : date = date ?? DateTime.now();

  String get dateFormat => DateFormat('dd.MM.yyyy hh:mm:ss').format(date);
}
