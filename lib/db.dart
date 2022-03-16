import 'model.dart';
import 'objectbox.g.dart'; // created by `flutter pub run build_runner build`


/// Provides access to the ObjectBox Store throughout the app. GLOBAL!
// TODO: Is this the best place for this?
late ObjectBox objectbox;

/// Provides access to the ObjectBox Store throughout the app.
///
/// Create this in the apps main function.
class ObjectBox {
  /// The Store of this app.
  late final Store store;

  late final Box<Note> noteBox;  // remove
  late final Box<Friend> friendBox;
  late final Box<Event> eventBox;
  late final Box<Tag> tagBox;

  /// A stream of all notes ordered by date.
  // late final Stream<Query<Note>> queryStream;

  ObjectBox._create(this.store) {
    noteBox = Box<Note>(store);
    friendBox = Box<Friend>(store);
    eventBox = Box<Event>(store);
    tagBox = Box<Tag>(store);

    // final qBuilder = noteBox.query()
    //   ..order(Note_.date, flags: Order.descending);
    // queryStream = qBuilder.watch(triggerImmediately: true);

    // Add some demo data if the box is empty.
    // if (noteBox.isEmpty()) {
    //   _putDemoData();
    // }
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    final store = await openStore();
    return ObjectBox._create(store);
  }

  Stream<Query<Note>> getNoteQueryStream() {
    // This doesn't seem right - previously was passing queryStream as init'd
    // in _create, but was getting: Bad State: Stream has already been listened to.
    // But is returning a new stream every time OK?
    // TODO: maybe ask on IRC if this seems right.
    final qBuilder = noteBox.query()
      ..order(Note_.date, flags: Order.descending);
    return qBuilder.watch(triggerImmediately: true);
  }

  Stream<Query<Friend>> getFriendQueryStream() {
    // This doesn't seem right - previously was passing queryStream as init'd
    // in _create, but was getting: Bad State: Stream has already been listened to.
    // But is returning a new stream every time OK?
    // TODO: maybe ask on IRC if this seems right.
    final qBuilder = friendBox.query()
      ..order(Friend_.name);
    return qBuilder.watch(triggerImmediately: true);
  }

  Stream<Query<Event>> getEventQueryStream() {
    final qBuilder = eventBox.query(Event_.isIdea.equals(false))
      ..order(Event_.date);
    return qBuilder.watch(triggerImmediately: true);
  }
  Stream<Query<Event>> getEventIdeaQueryStream() {
    final qBuilder = eventBox.query(Event_.isIdea.equals(true))
      ..order(Event_.title);
    return qBuilder.watch(triggerImmediately: true);
  }
  // TODO: ugly to depend on enum index for all of these.
  List<Event> getRealEvents() {
    final qBuilder = eventBox.query(Event_.dbFrequency.equals(RepeatFrequency.never.index) & Event_.isIdea.equals(false))
      ..order(Event_.date);
    return qBuilder.build().find();
  }
  List<Event> getRepeatingEvents() {
    final qBuilder = eventBox.query(Event_.dbFrequency.greaterThan(RepeatFrequency.never.index) & Event_.isIdea.equals(false))
      ..order(Event_.date);
    return qBuilder.build().find();
  }
  List<Event> getRealEventsForFriend(Friend friend) {
    final qBuilder = eventBox.query(Event_.dbFrequency.equals(RepeatFrequency.never.index) & Event_.isIdea.equals(false))
      ..order(Event_.date);
    qBuilder.linkMany(Event_.friends, Friend_.id.equals(friend.id));
    return qBuilder.build().find();
  }
  List<Event> getRepeatingEventsForFriend(Friend friend) {
    final qBuilder = eventBox.query(Event_.dbFrequency.greaterThan(RepeatFrequency.never.index) & Event_.isIdea.equals(false))
      ..order(Event_.date);
    qBuilder.linkMany(Event_.friends, Friend_.id.equals(friend.id));
    return qBuilder.build().find();
  }

  Stream<Query<Tag>> getTagQueryStream() {
    final qBuilder = tagBox.query()
      ..order(Tag_.title);
    return qBuilder.watch(triggerImmediately: true);
  }
}
