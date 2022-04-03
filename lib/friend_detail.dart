import 'package:flutter/material.dart';
import 'package:frend/event_idea_list.dart';
import 'package:frend/searchable_selection_list.dart';
import 'package:intl/intl.dart';

import 'confirmation_dialog.dart';
import 'db.dart';
import 'event_detail.dart';
import 'filter_list.dart';
import 'model.dart';


class NoteItem {
  NoteItem({
    required this.controller,
    this.isExpanded = false,
  });

  TextEditingController controller;
  bool isExpanded;
}


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
  final List<NoteItem> _notes = [];

  static const int PAST_EVENT_IDX = 0;
  static const int UPCOMING_EVENT_IDX = 1;
  static const int INTEREST_IDX = 2;
  final List<EPListItem> _epItems = [
    EPListItem(headerValue: "Past Events"),
    EPListItem(headerValue: "Upcoming Events"),
    EPListItem(headerValue: "Interests"),
  ];

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

        _friendshipLevelDropdownValue = friend.friendshipLevel;

        for (var tag in friend.interests) {
          _selectedTags[tag.id] = tag.title;
        }
        for (var note in friend.notes) {
          _notes.add(NoteItem(controller: TextEditingController(text: note)));
        }
      }
    }

    if (_notes.isEmpty) {
      _notes.add(NoteItem(controller: TextEditingController(text: "")));
    }

    setState(() {}); // need this?
  }

  save() {
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
    friend.dbFriendshipLevel = _friendshipLevelDropdownValue.index;

    List<Tag> dbTags = [];
    for (var tag in _selectedTags.entries) {
      Tag? maybeTag = objectbox.tagBox.get(tag.key);
      if (maybeTag != null) {
        dbTags.add(maybeTag);
      }
    }
    friend.interests.addAll(dbTags);

    List<String> newNotes = [];
    for (var note in _notes) {
      newNotes.add(note.controller.text);
    }
    friend.notes = newNotes;

    _friendId = objectbox.friendBox.put(friend);
    Navigator.pop(context);
  }

  _deleteFriend() {
    showConfirmationDialog(context, "friend", () {
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

  void _goToEventIdeaList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EventIdeaList(
            friendId: _friendId,
            tags: _selectedTags.values.toSet(),
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
      body: FilterList(tags: _selectedTags.values.toSet()),
      isExpanded: item.isExpanded,
    );
  }
  
  Widget _buildEP() {
    assert(_friendId != null);

    var friend = objectbox.friendBox.get(_friendId!);

    var pastEventItem = _epItems[PAST_EVENT_IDX];
    var upcomingEventItem = _epItems[UPCOMING_EVENT_IDX];
    var interestItem = _epItems[INTEREST_IDX];

    List<Event> pastEvents = [];
    if (pastEventItem.isExpanded) {
      pastEvents = objectbox.getOneOffEventsForFriend(friend!).where((event) =>
          event.date.isBefore(DateTime.now())).toList();
    }

    List<Event> upcomingEvents = [];
    if (upcomingEventItem.isExpanded) {
      upcomingEvents = objectbox.getOneOffEventsForFriend(friend!).where((event) =>
          event.date.isAfter(DateTime.now())).toList();
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
      children: [
        _getEventExpansionPanel(pastEventItem, pastEvents),
        _getEventExpansionPanel(upcomingEventItem, upcomingEvents),
        _getInterestExpansionPanel(interestItem, interests),
      ],
    );
  }

  List<Widget> _buildNotesPanel() {
    List<Widget> noteList = [];

    noteList.add(
        Container(
          padding: const EdgeInsets.only(top: 15),
          child: Align(
            alignment: AlignmentDirectional.center,
            child: Text(
              'Notes',
              style: Theme.of(context).textTheme.caption,
              textScaleFactor: 1.5,
            ),
          ),
        )
    );

    noteList.add(ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _notes[index].isExpanded = !isExpanded;
        });
      },
      children: _notes.map<ExpansionPanel>((NoteItem item) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: isExpanded
                  ? TextFormField(
                    controller: item.controller,
                    decoration: const InputDecoration(hintText: 'Edit Note'),
                    maxLines: null,
                    keyboardType: TextInputType.multiline)
                  : Text(item.controller.text, softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis,),
            );
          },
          body: ListTile(
              title: ElevatedButton(
                  child: const Text("Delete"),
                  onPressed: () {
                    setState(() {
                      _notes.removeWhere((NoteItem currentItem) => item == currentItem);
                    });
                  })),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    ));

    noteList.add(
      Container(
        padding: const EdgeInsets.only(left: 100, right: 100),
        child: ElevatedButton(
          child: const Text('Add New Note'),
          onPressed: () {
            setState(() {
              _notes.add(NoteItem(controller: TextEditingController(text: "New Note")));
            });
          },
        )));

    return noteList;
  }

  Widget _buildScheduleButton() {
    return Container(
        padding: const EdgeInsets.only(left: 100, right: 100),
        child: ElevatedButton(
          child: const Text("Schedule Event"),
          onPressed: () {
            _goToEventIdeaList();
          },
        ));
  }

  Widget _buildForm(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: "Input Name"),
            // The validator receives the text that the user has entered.
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
            decoration: InputDecoration(hintText: 'Set Birthdate'),
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
          Row(children: [
            if (_friendId != null && objectbox.friendBox.get(_friendId!)!.overdue())
              const Icon(
                Icons.announcement,
                color: Colors.red,
              ),
            const Text("Overdue threshold (weeks) or 'none': "),
            Container(
              width: 125,
              child: TextFormField(
                controller: _reminderController,
                validator: (value) {
                  if (value == null || value.toLowerCase() == "none") {
                    return null;
                  }

                  var maybeInt = int.tryParse(value);
                  if (maybeInt == null || maybeInt < 0) {
                    return 'Enter positive number';
                  }
                  return null;
                },
              )
          )]),
          Row(children: [
            const Text("Friendship Level: "),
            DropdownButton<FriendshipLevel>(
              value: _friendshipLevelDropdownValue,
              elevation: 16,
              onChanged: (FriendshipLevel? newValue) {
                setState(() {
                  _friendshipLevelDropdownValue = newValue!;
                });
              },
              // TODO: ugly to do this based on index.
              items: FriendshipLevel.values.sublist(1).map<DropdownMenuItem<FriendshipLevel>>((FriendshipLevel value) {
                return DropdownMenuItem<FriendshipLevel>(
                  value: value,
                  child: Text(value.string),
                );
              }).toList(),
            ),
          ]),
        ],
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
          _buildScheduleButton(),
          _buildEP(),
          _buildAddTagButton(),
          if (_notes.isNotEmpty) ..._buildNotesPanel(),
        ],
      )
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _reminderController.dispose();
    _notes.forEach((element) {
      element.controller.dispose();
    });
    super.dispose();
  }
}
