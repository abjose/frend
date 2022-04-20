import 'package:flutter/material.dart';
import 'package:frend/event_idea_list.dart';
import 'package:frend/searchable_selection_list.dart';
import 'package:intl/intl.dart';

import 'confirmation_dialog.dart';
import 'db.dart';
import 'event_detail.dart';
import 'filter_list.dart';
import 'model.dart';

class EPListItem {
  EPListItem({
    required this.headerValue,
    this.isExpanded = false,
  });

  String headerValue;
  bool isExpanded;
}

class FriendDetail extends StatefulWidget {
  final int? friendId;

  const FriendDetail({Key? key, required this.friendId}) : super(key: key);

  @override
  _FriendDetailState createState() => _FriendDetailState();
}

// Create a corresponding State class.
// This class holds data related to the form.
class _FriendDetailState extends State<FriendDetail> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  int? _friendId;

  Map<int, String> _selectedTags = {};

  FriendshipLevel _friendshipLevelDropdownValue = FriendshipLevel.friend;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _reminderController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  static const int INTEREST_IDX = 0;
  static const int PAST_EVENT_IDX = 1;
  static const int UPCOMING_EVENT_IDX = 2;
  final List<EPListItem> _epItems = [
    EPListItem(headerValue: "Interests"),
    EPListItem(headerValue: "Past Events"),
    EPListItem(headerValue: "Upcoming Events"),
  ];

  // TODO: get these tags in a smarter way.
  final Map<FriendshipLevel, Set<String>> _extraTagsForFriendshipLevel = {
    FriendshipLevel.acquaintance: {"acquaintance"},
    FriendshipLevel.outOfTouch: {"out-of-touch"},
  };

  @override
  void initState() {
    super.initState();

    _friendId = widget.friendId;

    Friend? friend;
    if (_friendId != null) {
      friend = objectbox.friendBox.get(_friendId!);
      if (friend != null) {
        _nameController.text = friend.name;
        if (friend.birthdateSet) {
          _dateController.text = friend.dateFormat;
        }
        if (friend.overdueWeeks != null) {
          _reminderController.text = friend.overdueWeeks.toString();
        }
        if (friend.note.isNotEmpty) {
          _noteController.text = friend.note;
        }

        _friendshipLevelDropdownValue = friend.friendshipLevel;

        for (var tag in friend.interests) {
          _selectedTags[tag.id] = tag.title;
        }
      }
    }

    setState(() {}); // need this?
  }

  save([pop = true]) {
    var friend = Friend("");
    if (_friendId != null) {
      friend = objectbox.friendBox.get(_friendId!)!;
      friend.id = _friendId!;
      friend.interests.clear();
    }

    friend.name = _nameController.text;

    if (_dateController.text.isNotEmpty) {
      friend.birthdate = DateFormat.yMMMMd('en_US').parse(_dateController.text);
      friend.birthdateSet = true;
    }

    friend.overdueWeeks = int.tryParse(_reminderController.text);
    if (friend.overdueWeeks == 0) {
      friend.overdueWeeks = null;
    }

    friend.dbFriendshipLevel = _friendshipLevelDropdownValue.index;
    friend.note = _noteController.text;

    List<Tag> dbTags = [];
    for (var tag in _selectedTags.entries) {
      Tag? maybeTag = objectbox.tagBox.get(tag.key);
      if (maybeTag != null) {
        dbTags.add(maybeTag);
      }
    }
    friend.interests.addAll(dbTags);

    _friendId = objectbox.friendBox.put(friend);

    if (pop) {
      Navigator.pop(context);
    }
  }

  _deleteFriend() {
    showConfirmationDialog(context, null, "Are you sure you want to delete this friend?", () {
      if (_friendId != null) {
        objectbox.friendBox.remove(_friendId!);
        Navigator.pop(context);
      }
    });
  }

  void _goToEventDetail(Event event) {
    // Collapse lists so they won't be out of date if/when we come back.
    // TODO: do this better.
    for (var item in _epItems) {
      item.isExpanded = false;
    }
    setState(() {});

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EventDetail(event: event);
        },
      ),
    );
  }

  // Note that this adds _selectedTags by default.
  void _goToEventIdeaList(Set<String> extraTags) {
    // Save changes to friend before we switch pages.
    save(false);

    Set<String> allTags = _selectedTags.values.toSet();
    allTags.addAll(extraTags);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EventIdeaList(
            friendId: _friendId,
            tags: allTags,
          );
        },
      ),
    );
  }

  _editTags() {
    Map<int, String> allTags = {};
    for (var tag in objectbox.tagBox.getAll()) {
      allTags[tag.id] = tag.title;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return SearchableSelectionList(
            title: "Edit Interests",
            elements: allTags,
            selectedItems: _selectedTags.keys.toSet(),
            onDone: (newSelected) {
              WidgetsBinding.instance?.addPostFrameCallback((_) => setState(() {
                    _selectedTags.clear();
                    for (var id in newSelected) {
                      _selectedTags[id] = allTags[id]!;
                    }
                  }));
            },
          );
        },
      ),
    );
  }

  Widget _buildAddTagButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 100),
      child: ElevatedButton(
        onPressed: _editTags,
        child: const Text('Edit Interests'),
      ),
    );
  }

  ExpansionPanel _getEventExpansionPanel(EPListItem item, List<Event> events) {
    return ExpansionPanel(
      headerBuilder: (BuildContext context, bool isExpanded) {
        return ListTile(
          title: Text(item.headerValue),
        );
      },
      body: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: events.map<Container>((event) {
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
                onTap: () => _goToEventDetail(event),
                title: Text(event.title),
                subtitle: event.friends.isEmpty ? null : Text(event.getFriendString()),
                trailing: Text("${event.timeFormat}"),
              ),
            );
          }).toList()),
      isExpanded: item.isExpanded,
    );
  }

  ExpansionPanel _getInterestExpansionPanel(EPListItem item, List<String> tags) {
    return ExpansionPanel(
      headerBuilder: (BuildContext context, bool isExpanded) {
        return ListTile(
          title: Text(item.headerValue),
        );
      },
      body: Column(
        children: [
          FilterList(tags: _selectedTags.values.toSet()),
          _buildAddTagButton(),
        ],
      ),
      isExpanded: item.isExpanded,
    );
  }

  Widget _buildEP() {
    var friend = _friendId != null ? objectbox.friendBox.get(_friendId!) : null;

    var pastEventItem = _epItems[PAST_EVENT_IDX];
    var upcomingEventItem = _epItems[UPCOMING_EVENT_IDX];
    var interestItem = _epItems[INTEREST_IDX];

    List<Event> pastEvents = [];
    if (pastEventItem.isExpanded && friend != null) {
      pastEvents = objectbox
          .getOneOffEventsForFriend(friend)
          .where((event) => event.date.isBefore(DateTime.now()))
          .toList();
    }

    List<Event> upcomingEvents = [];
    if (upcomingEventItem.isExpanded && friend != null) {
      upcomingEvents = objectbox
          .getOneOffEventsForFriend(friend)
          .where((event) => event.date.isAfter(DateTime.now()))
          .toList();
      upcomingEvents.addAll(objectbox.getRepeatingEventsForFriend(friend));
    }

    List<String> interests = [];
    if (interestItem.isExpanded) {
      interests = _selectedTags.values.toList();
    }

    // getting called again every time you try to expand!
    // print("called");

    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _epItems[index].isExpanded = !isExpanded;
        });
      },

      // If change this order, make sure to update _epItems and _IDX vars.
      // TODO: clean this up so can rearrange without causing issues.
      children: [
        _getInterestExpansionPanel(interestItem, interests),
        if (friend != null) _getEventExpansionPanel(pastEventItem, pastEvents),
        if (friend != null) _getEventExpansionPanel(upcomingEventItem, upcomingEvents),
      ],
    );
  }

  Widget _buildNotesPanel() {
    return ListTile(
        minVerticalPadding: 20,
        title: Text("Notes"),
        subtitle: TextFormField(
          controller: _noteController,
          decoration: const InputDecoration(hintText: 'Edit Note'),
          maxLines: null,
          keyboardType: TextInputType.multiline,
        ));
  }

  Widget _buildScheduleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: const Text("Schedule Event"),
          onPressed: () {
            _goToEventIdeaList({});
          },
        ),
        if (_friendshipLevelDropdownValue == FriendshipLevel.acquaintance ||
            _friendshipLevelDropdownValue == FriendshipLevel.outOfTouch)
          const Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
        if (_friendshipLevelDropdownValue == FriendshipLevel.acquaintance)
          ElevatedButton(
            child: const Text("Deepen Friendship"),
            onPressed: () {
              _goToEventIdeaList(_extraTagsForFriendshipLevel[FriendshipLevel.acquaintance]!);
            },
          ),
        if (_friendshipLevelDropdownValue == FriendshipLevel.outOfTouch)
          ElevatedButton(
            child: const Text("Get Back In Touch"),
            onPressed: () {
              _goToEventIdeaList(_extraTagsForFriendshipLevel[FriendshipLevel.outOfTouch]!);
            },
          ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(
                  color: Colors.black54,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            TextFormField(
              readOnly: true,
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Birthdate',
                labelStyle: TextStyle(
                  color: Colors.black54,
                ),
              ),
              onTap: () async {
                DateTime oldDate = DateTime.now();
                if (_dateController.text.isNotEmpty) {
                  oldDate = DateFormat.yMMMMd('en_US').parse(_dateController.text);
                }

                var newDate = await showDatePicker(
                    context: context,
                    initialDate: oldDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100));
                // TODO: use dateFormat from Friend instead.
                if (newDate != null) {
                  _dateController.text = DateFormat.yMMMMd('en_US').format(newDate);
                }
              },
            ),
            TextFormField(
              controller: _reminderController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                icon: (_friendId != null && objectbox.friendBox.get(_friendId!)!.overdue())
                    ? const Icon(
                        Icons.announcement,
                        color: Colors.red,
                      )
                    : null,
                labelText: 'Overdue threshold (weeks)',
                labelStyle: const TextStyle(
                  color: Colors.black54,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null;
                }

                var maybeInt = int.tryParse(value);
                if (maybeInt == null || maybeInt < 0) {
                  return 'Enter positive number';
                }
                return null;
              },
            ),
            DropdownButtonFormField(
              value: _friendshipLevelDropdownValue,

              // TODO: ugly to do this based on index.
              items: FriendshipLevel.values
                  .sublist(1)
                  .map<DropdownMenuItem<FriendshipLevel>>((FriendshipLevel value) {
                return DropdownMenuItem<FriendshipLevel>(
                  value: value,
                  child: Text(value.string),
                );
              }).toList(),

              decoration: const InputDecoration(
                labelText: 'Friendship Level',
                labelStyle: TextStyle(
                  color: Colors.black54,
                ),
              ),

              onChanged: (FriendshipLevel? newValue) {
                setState(() {
                  _friendshipLevelDropdownValue = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('${_friendId == null ? "Add" : "Edit"} Friend'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.save, color: Colors.white),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  save();
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteFriend,
            )
          ],
        ),
        // body: _buildForm(context),
        body: ListView(
          children: [
            _buildForm(context),
            if (_friendId != null) _buildScheduleButton(),
            _buildEP(),
            _buildNotesPanel(),
          ],
        ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _reminderController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
