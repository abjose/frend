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
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    final store = await openStore();
    return ObjectBox._create(store);
  }

  void maybePopulate() {
    // eventBox.removeAll();
    // tagBox.removeAll();

    if (tagBox.isEmpty()) {
      // Friendship levels
      tagBox.put(Tag("acquaintance"));
      tagBox.put(Tag("out-of-touch"));
      // tagBox.put(Tag("partner"));

      // Interests
      tagBox.put(Tag("art"));
      tagBox.put(Tag("comedy"));
      tagBox.put(Tag("comics"));
      tagBox.put(Tag("cooking and baking"));
      tagBox.put(Tag("dancing"));
      tagBox.put(Tag("fitness"));
      tagBox.put(Tag("games"));
      tagBox.put(Tag("movies"));
      tagBox.put(Tag("music"));
      tagBox.put(Tag("nature"));
      tagBox.put(Tag("nightlife"));
      tagBox.put(Tag("reading"));
      tagBox.put(Tag("singing"));
      tagBox.put(Tag("theater"));
      tagBox.put(Tag("travel"));
      tagBox.put(Tag("tv shows"));
      tagBox.put(Tag("volunteering"));
      tagBox.put(Tag("writing"));
    }

    if (eventBox.isEmpty()) {
      eventBox.put(Event("ask how they're doing", isIdea: true,
          initialTags: ["acquaintance", "out-of-touch"]));
      eventBox.put(Event("ask advice on book / music / film", isIdea: true,
          initialTags: ["acquaintance", "movies", "music", "reading"]));
      eventBox.put(Event("ask what some of their favorite things to do / places to go are", isIdea: true,
          initialTags: ["acquaintance"]));
      eventBox.put(Event("share something you think is interesting or funny", isIdea: true,
          initialTags: ["acquaintance"]));
      eventBox.put(Event("reminisce about a shared experience", isIdea: true,
          initialTags: ["acquaintance", "out-of-touch"]));
      eventBox.put(Event("ask if they share {one of your interests}", isIdea: true,
          initialTags: ["acquaintance"]));
      eventBox.put(Event("go to a bar", isIdea: true,
          initialTags: ["acquaintance", "nightlife"]));
      eventBox.put(Event("invite to existing plans", isIdea: true,
          initialTags: ["acquaintance"]));
      eventBox.put(Event("go get coffee", isIdea: true,
          initialTags: ["acquaintance", "out-of-touch"]));
      eventBox.put(Event("ask how one of their projects is going", isIdea: true,
          initialTags: ["acquaintance"]));
      eventBox.put(Event("share something personal (like a quirk, a dream for the future, a secret wish...)", isIdea: true,
          initialTags: []));
      eventBox.put(Event("ask how one of their close relations is doing", isIdea: true,
          initialTags: []));
      eventBox.put(Event("go to a comedy show", isIdea: true,
          initialTags: ["comedy", "nightlife"]));
      eventBox.put(Event("ask about one of their substantial life events", isIdea: true,
          initialTags: []));
      eventBox.put(Event("play a game online, remotely", isIdea: true,
          initialTags: ["games"]));
      eventBox.put(Event("watch videos on the internet", isIdea: true,
          initialTags: []));
      eventBox.put(Event("take an exercise class", isIdea: true,
          initialTags: ["dancing", "fitness"]));
      eventBox.put(Event("go to a restaurant", isIdea: true,
          initialTags: []));
      eventBox.put(Event("share a fear, flaw, or insecurity", isIdea: true,
          initialTags: []));
      eventBox.put(Event("go to an open mic night", isIdea: true,
          initialTags: ["nightlife"]));
      eventBox.put(Event("go to a concert", isIdea: true,
          initialTags: ["dancing", "music", "nightlife"]));
      eventBox.put(Event("go to a festival", isIdea: true,
          initialTags: ["dancing", "music"]));
      eventBox.put(Event("host a potluck", isIdea: true,
          initialTags: ["cooking and baking"]));
      eventBox.put(Event("watch a movie", isIdea: true,
          initialTags: ["movies"]));
      eventBox.put(Event("go to a museum", isIdea: true,
          initialTags: ["art"]));
      eventBox.put(Event("go to a bookstore", isIdea: true,
          initialTags: ["reading"]));
      eventBox.put(Event("invite them over for a meal", isIdea: true,
          initialTags: []));
      eventBox.put(Event("go hiking", isIdea: true,
          initialTags: ["nature"]));
      eventBox.put(Event("explore a part of your neighborhood / town / city", isIdea: true,
          initialTags: ["nightlife"]));
      eventBox.put(Event("play a game in real life", isIdea: true,
          initialTags: ["games"]));
      eventBox.put(Event("volunteer", isIdea: true,
          initialTags: ["volunteering"]));
      eventBox.put(Event("start reading a book", isIdea: true,
          initialTags: ["reading"]));
      eventBox.put(Event("take a class", isIdea: true,
          initialTags: []));
      eventBox.put(Event("go to a convention", isIdea: true,
          initialTags: ["comics", "games"]));
      eventBox.put(Event("cook or bake something", isIdea: true,
          initialTags: ["cooking and baking"]));
      eventBox.put(Event("learn a new skill", isIdea: true,
          initialTags: ["art", "comedy", "dancing", "music", "volunteering", "writing"]));
      eventBox.put(Event("start a project", isIdea: true,
          initialTags: ["art", "comedy", "music", "volunteering", "writing"]));
      eventBox.put(Event("get them a gift", isIdea: true,
          initialTags: []));
      eventBox.put(Event("go on a road trip", isIdea: true,
          initialTags: ["nature", "travel"]));
      eventBox.put(Event("go on a camping trip", isIdea: true,
          initialTags: ["nature"]));
    }
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

  Stream<Query<Friend>> getAllFriendQueryStream() {
    // This doesn't seem right - previously was passing queryStream as init'd
    // in _create, but was getting: Bad State: Stream has already been listened to.
    // But is returning a new stream every time OK?
    // TODO: maybe ask on IRC if this seems right.
    final qBuilder = friendBox.query()
      ..order(Friend_.name);
    return qBuilder.watch(triggerImmediately: true);
  }

  // Query streams for specific friend levels. See warnings above.
  // TODO: figure out why need to make these broadcast streams - i.e. where multiple listeners are coming from.
  Stream<Query<Friend>> getFriendQueryStream() {
    final qBuilder = friendBox.query(Friend_.dbFriendshipLevel.equals(FriendshipLevel.friend.index))
      ..order(Friend_.name);
    return qBuilder.watch(triggerImmediately: true).asBroadcastStream();
  }
  Stream<Query<Friend>> getAcquaintanceQueryStream() {
    final qBuilder = friendBox.query(Friend_.dbFriendshipLevel.equals(FriendshipLevel.acquaintance.index))
      ..order(Friend_.name);
    return qBuilder.watch(triggerImmediately: true).asBroadcastStream();
  }
  Stream<Query<Friend>> getOutOfTouchFriendQueryStream() {
    final qBuilder = friendBox.query(Friend_.dbFriendshipLevel.equals(FriendshipLevel.outOfTouch.index))
      ..order(Friend_.name);
    return qBuilder.watch(triggerImmediately: true).asBroadcastStream();
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
  List<Event> getOneOffEvents() {
    final qBuilder = eventBox.query(Event_.dbFrequency.equals(RepeatFrequency.never.index) & Event_.isIdea.equals(false))
      ..order(Event_.date);
    return qBuilder.build().find();
  }
  List<Event> getRepeatingEvents() {
    final qBuilder = eventBox.query(Event_.dbFrequency.greaterThan(RepeatFrequency.never.index) & Event_.isIdea.equals(false))
      ..order(Event_.date);
    return qBuilder.build().find();
  }
  List<Event> getOneOffEventsForFriend(Friend friend) {
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
