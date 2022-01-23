import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:frend/objectbox.g.dart';
import 'package:frend/searchable_selection_list.dart';
import 'package:intl/intl.dart';

import 'db.dart';
import 'event_detail.dart';
import 'model.dart';


class NoteItem {
  NoteItem({
    required this.controller,
    this.isExpanded = false,
  });

  TextEditingController controller;
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
  DateTime birthdate = DateTime.now();
  List<Event> _events = [];

  Map<int, String> _selectedTags = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final List<NoteItem> _notes = [];

  @override
  void initState() {
    super.initState();

    _friendId = widget.friendId;

    Friend? friend;
    // birthdate = DateTime.now();
    if (_friendId != null) {
      friend = objectbox.friendBox.get(_friendId!);
      if (friend != null) {
        _nameController.text = friend.name;
        _dateController.text = friend.dateFormat;
        birthdate = friend.birthdate;

        QueryBuilder<Event> builder = objectbox.eventBox.query();
        builder.linkMany(Event_.friends, Friend_.id.equals(_friendId!));
        _events = builder.build().find();
        for (var tag in friend.interests) {
          _selectedTags[tag.id] = tag.title;
        }
        for (var note in friend.notes) {
          _notes.add(NoteItem(controller: TextEditingController(text: note)));
        }
      } else {
        _nameController.text = "Name";
        _dateController.text = "Choose a date";
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
    friend.birthdate = DateFormat.yMMMMd('en_US').parse(_dateController.text);

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
    if (_friendId != null) {
      objectbox.friendBox.remove(_friendId!);
      Navigator.pop(context);
    }
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
            selected: _selectedTags.keys.toSet(),
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

  List<Widget> _buildTagList() {
    List<Widget> tagList = [];
    tagList.add(
      Container(
        padding: const EdgeInsets.only(top: 15),
        child: Align(
          alignment: AlignmentDirectional.center,
          child: Text(
            'Interests',
            style: Theme.of(context).textTheme.caption,
            textScaleFactor: 1.5,
          ),
        ),
      )
    );
    for (var tagTitle in _selectedTags.values) {
      tagList.add(
          Card(
            color: Colors.amberAccent,
            elevation: 4,
            // margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              title: Text(tagTitle),
            ),
          )
      );
    }
    tagList.add(
      ElevatedButton(
        onPressed: _editTags,
        child: const Text('Edit Interests'),
      ),
    );

    return tagList;
  }

  List<Widget> _buildEventList() {
    List<Widget> eventList = [];
    eventList.add(
        Container(
          padding: const EdgeInsets.only(top: 15),
          child: Align(
            alignment: AlignmentDirectional.center,
            child: Text(
              'Events',
              style: Theme.of(context).textTheme.caption,
              textScaleFactor: 1.5,
            ),
          ),
        )
    );

    for (var event in _events) {
      eventList.add(
          Card(
            color: Colors.amberAccent,
            child: ListTile(
              title: Text(event.title),
              onTap: () => _goToEventDetail(event),
            ),
          )
      );
    }

    return eventList;
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

    noteList.add(ElevatedButton(
      child: const Text('Add New Note'),
      onPressed: () {
        setState(() {
          _notes.add(NoteItem(controller: TextEditingController(text: "New Note")));
        });
      },
    ));

    return noteList;
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
            decoration: InputDecoration(hintText: 'Pick Birthdate'),
            onTap: () async {
              var date = await showDatePicker(
                  context: context,
                  // maybe get most recent birthdate? if click away then lose date
                  initialDate: birthdate, // DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100));
              // TODO: use dateFormat from Friend instead.
              if (date != null) {
                _dateController.text = DateFormat.yMMMMd('en_US').format(date);
              }

            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a birthdate';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Friend"),
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
          if (_selectedTags.isNotEmpty) ..._buildTagList(),
          if (_events.isNotEmpty) ..._buildEventList(),
          if (_notes.isNotEmpty) ..._buildNotesPanel(),
        ],
      )
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _notes.forEach((element) {
      element.controller.dispose();
    });
    super.dispose();
  }
}
