import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:frend/confirmation_dialog.dart';
import 'package:frend/searchable_selection_list.dart';

import 'db.dart';
import 'model.dart';


class EventDetail extends StatefulWidget {
  final Event event;
  final DateTime? date;

  const EventDetail({Key? key, required this.event, this.date}): super(key: key);

  @override
  _EventDetailState createState() => _EventDetailState();
}

// Create a corresponding State class.
// This class holds data related to the form.
class _EventDetailState extends State<EventDetail> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  late Event _event;

  // Maybe an awkward way to do this.
  Map<int, String> _selectedFriends = {};
  Map<int, String> _selectedTags = {};
  Map<int, Set<String>> _interestMap = {};

  final TextEditingController _titleController = TextEditingController();
  RepeatFrequency _repeatDropdownValue = RepeatFrequency.never;

  @override
  void initState() {
    super.initState();

    _event = widget.event;
    if (widget.date != null) {
      _event.date = widget.date!;
    }

    _titleController.text = _event.title;

    if (_event.frequency != null) {
      _repeatDropdownValue = _event.frequency;
    }

    for (var friend in _event.friends) {
      _selectedFriends[friend.id] = friend.name;
    }
    for (var tag in _event.tags) {
      _selectedTags[tag.id] = tag.title;
    }
    for (var friend in objectbox.friendBox.getAll()) {
      _interestMap[friend.id] = {};
      for (var interest in friend.interests) {
        _interestMap[friend.id]!.add(interest.title);
      }
    }

    setState(() {});  // need this?
  }

  save() {
    _event.title = _titleController.text;

    // Do horrible things to DateTime.
    // Seems like date is UTC by default, but calendar and DateTimePicker don't handle UTC?
    // TODO: come up with better solution for timezone.
    var dateString = _event.date.toString();
    if (dateString.endsWith("Z")) {
      dateString = dateString.substring(0, dateString.length-1);
    }
    var maybeDate = DateTime.tryParse(dateString);
    if (maybeDate != null) {
      _event.date = maybeDate;
    }

    _event.dbFrequency = _repeatDropdownValue.index;

    // TODO: Better way to save friends?
    List<Friend> dbFriends = [];
    for (var friend in _selectedFriends.entries) {
      Friend? maybeFriend = objectbox.friendBox.get(friend.key);
      if (maybeFriend != null) {
        dbFriends.add(maybeFriend);
      }
    }
    _event.friends.clear();
    _event.friends.addAll(dbFriends);

    List<Tag> dbTags = [];
    for (var tag in _selectedTags.entries) {
      Tag? maybeTag = objectbox.tagBox.get(tag.key);
      if (maybeTag != null) {
        dbTags.add(maybeTag);
      }
    }
    _event.tags.clear();
    _event.tags.addAll(dbTags);

    if (!_event.isIdea) {
      _event.updateNotification();
    }

    objectbox.eventBox.put(_event);

    if (_event.isIdea) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  _deleteEvent() {
    showConfirmationDialog(context, "event", () {
      if (_event.id != 0) {
        objectbox.eventBox.remove(_event.id);
      }

      if (_event.isIdea) {
        Navigator.pop(context);
      } else {
        _event.deleteNotification();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  _editFriends() {
    Map<int, String> allFriends = {};
    for (var friend in objectbox.friendBox.getAll()) {
      allFriends[friend.id] = friend.name;
    }

    // wait want to be able to edit friends list even if not saved yet
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return SearchableSelectionList(
              elements: allFriends,
              selectedItems: _selectedFriends.keys.toSet(),
              tags: _interestMap,
              onDone: (newSelected) {

                // ehhh
                WidgetsBinding.instance?.addPostFrameCallback((_) => setState(() {
                  _selectedFriends.clear();
                  for (var id in newSelected) {
                    _selectedFriends[id] = allFriends[id]!;
                  }
                }));
              },
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

  Widget _buildForm(BuildContext context) {
    List<Widget> friendList = [];
    for (var friendName in _selectedFriends.values) {
      friendList.add(
          Card(
            color: Colors.amberAccent,
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              // leading: Text(
              //   _foundUsers[index]["id"].toString(),
              //   style: const TextStyle(fontSize: 24),
              // ),
              title: Text(friendName),
              // trailing:
              // onTap: _editFriends,
            ),
          )
      );
    }
    friendList.add(
      ElevatedButton(
        onPressed: _editFriends,
        child: const Text('Edit Friends'),
      ),
    );

    // Maybe should abstract this...
    List<Widget> tagList = [];
    for (var tagTitle in _selectedTags.values) {
      tagList.add(
          Card(
            color: Colors.amberAccent,
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              title: Text(tagTitle),
              // onTap: _editTags,
            ),
          )
      );
    }
    tagList.add(
      ElevatedButton(
        onPressed: _editTags,
        child: const Text('Edit Tags'),
      ),
    );

    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: "Input Title"),
            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          if (!_event.isIdea)
            Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 10),
              child: DateTimePicker(
                type: DateTimePickerType.dateTimeSeparate,
                dateMask: 'd MMM, yyyy',
                initialValue: _event.date.toString(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                icon: const Icon(Icons.event),
                dateLabelText: 'Date',
                timeLabelText: "Time",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a date/time';
                  }
                  return null;
                },
                onChanged: (dateString) {
                  var maybeDate = DateTime.tryParse(dateString);
                  if (maybeDate != null) {
                    _event.date = maybeDate;
                  }
                },
              )
            ),
          if (!_event.isIdea)
            Row(children: [
              const Text("Repeat Frequency: "),
              DropdownButton<RepeatFrequency>(
                value: _repeatDropdownValue,
                elevation: 16,
                // style: const TextStyle(color: Colors.deepPurple),
                onChanged: (RepeatFrequency? newValue) {
                  setState(() {
                    _repeatDropdownValue = newValue!;
                  });
                },
                // TODO: ugly to do this based on index.
                items: RepeatFrequency.values.sublist(1).map<DropdownMenuItem<RepeatFrequency>>((RepeatFrequency value) {
                  return DropdownMenuItem<RepeatFrequency>(
                    value: value,
                    child: Text(value.string),
                  );
                }).toList(),
              ),
          ]),
          if (!_event.isIdea)
            Flexible(child: ListView(
              padding: const EdgeInsets.all(8),
              children: friendList,
            )),
          Flexible(child: ListView(
            padding: const EdgeInsets.all(8),
            children: tagList,
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_event.id == 0 ? "Add" : "Edit"} Event${_event.isIdea ? " Idea" : ""}'),
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
            onPressed: _deleteEvent,
          )
        ],
      ),
      body: _buildForm(context),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
