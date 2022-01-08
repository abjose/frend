import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:frend/objectbox.g.dart';
import 'package:frend/searchable_selection_list.dart';

import 'db.dart';
import 'event_detail.dart';
import 'model.dart';

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
  final List<TextEditingController> _noteControllers = [];

  @override
  void initState() {
    super.initState();

    setState(() {}); // need this?

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
          _noteControllers.add(TextEditingController(text: note));
        }
      } else {
        _nameController.text = "Name";
        _dateController.text = "Choose a date";
      }
    }

    if (_noteControllers.isEmpty) {
      _noteControllers.add(TextEditingController());
    }
  }

  save() {
    var friend = Friend(_nameController.text, date: DateTime.tryParse(_dateController.text));
    if (_friendId != null) {
      friend = objectbox.friendBox.get(_friendId!)!;
      friend.id = _friendId!;
      friend.interests.clear();
    }

    List<Tag> dbTags = [];
    for (var tag in _selectedTags.entries) {
      Tag? maybeTag = objectbox.tagBox.get(tag.key);
      if (maybeTag != null) {
        dbTags.add(maybeTag);
      }
    }
    friend.interests.addAll(dbTags);

    List<String> newNotes = [];
    for (var controller in _noteControllers) {
      newNotes.add(controller.text);
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

  void _goToEventDetail(int? id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Event'),
            ),
            body: EventDetail(
              eventId: id,
            ),
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

  @override
  Widget build(BuildContext context) {
    List<Widget> tagList = [];
    for (var tagTitle in _selectedTags.values) {
      tagList.add(
          Card(
            color: Colors.amberAccent,
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
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

    List<ExpandablePanel> noteWidgets = [];
    for (var controller in _noteControllers) {
      noteWidgets.add(
        ExpandablePanel(
            header: Text(controller.text, softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis,),
            // collapsed: Text(controller.text, softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis,),
            collapsed: SizedBox.shrink(),
            expanded: TextFormField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Edit Note'),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
        ),
      );
    }

    List<Card> eventList = [];
    for (var event in _events) {
      eventList.add(
          Card(
            color: Colors.amberAccent,
            // elevation: 4,
            // margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              // leading: Text(
              //   _foundUsers[index]["id"].toString(),
              //   style: const TextStyle(fontSize: 24),
              // ),
              title: Text(event.title!),
              // trailing:
              onTap: () => _goToEventDetail(event.id),
            ),
          )
      );
    }

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
              _dateController.text = date.toString().substring(0, 10);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a birthdate';
              }
              return null;
            },
          ),
          Flexible(child: ListView(
            padding: const EdgeInsets.all(8),
            children: tagList,
          )),
          eventList.isNotEmpty ?
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: eventList,
              )
            )
          : const SizedBox.shrink(),
          Flexible(child: ListView(
            // shrinkWrap: true,  // apparently this is expensive
            padding: const EdgeInsets.all(8),
            children: noteWidgets,
          )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _noteControllers.add(TextEditingController(text: "New Note"));
                });
              },
              child: const Text('Add New Note'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: ElevatedButton(
              onPressed: () {
                // Validate returns true if the form is valid, or false otherwise.
                if (_formKey.currentState!.validate()) {
                  // If the form is valid, display a snackbar. In the real world,
                  // you'd often call a server or save the information in a database.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saving')),
                  );
                  save();

                  // In case notes have been updated and need to redraw titles.
                  // TODO: use a callback instead or something.
                  setState(() {});
                }
              },
              child: const Text('Save'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: ElevatedButton(
              onPressed: _deleteFriend,
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _noteControllers.forEach((element) {
      element.dispose();
    });
    super.dispose();
  }
}
