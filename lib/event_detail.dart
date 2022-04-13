import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frend/confirmation_dialog.dart';
import 'package:frend/searchable_selection_list.dart';

import 'db.dart';
import 'model.dart';


class EventDetail extends StatefulWidget {
  final Event event;
  final DateTime? date;
  final int? friendId;

  const EventDetail({Key? key, required this.event, this.date, this.friendId}): super(key: key);

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
    _repeatDropdownValue = _event.frequency;

    for (var friend in _event.friends) {
      _selectedFriends[friend.id] = friend.name;
    }
    if (widget.friendId != null) {
      Friend passedFriend = objectbox.friendBox.get(widget.friendId!)!;
      _selectedFriends[passedFriend.id] = passedFriend.name;
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
    _pop();
  }

  _deleteEvent() {
    showConfirmationDialog(context, _event.isIdea ? "idea" : "event", () {
      if (_event.id != 0) {
        objectbox.eventBox.remove(_event.id);
      }

      if (!_event.isIdea) {
        _event.deleteNotification();
      }

      _pop();
    });
  }

  _pop() {
    if (_event.isIdea) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).popUntil((route) {
        return route.isFirst || route.settings.name == "friend";
      });
    }
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
    List<Widget> friendList = [
      Center(
        child: ElevatedButton(
          onPressed: _editFriends,
          child: const Text('Edit Friends'),
        ),
      ),
    ];

    if (!_event.isIdea) {
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
    }

    // Maybe should abstract this...
    List<Widget> tagList = [
      Center(
        child: ElevatedButton(
          onPressed: _editTags,
          child: const Text('Edit Tags'),
        ),
      ),
    ];

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

    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,

              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(
                  color: Colors.black54,
                ),
              ),

              // The validator receives the text that the user has entered.
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),

            if (!_event.isIdea)
              DateTimePicker(
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
              ),

            if (!_event.isIdea)
              DropdownButtonFormField(
                value: _repeatDropdownValue,

                // TODO: ugly to do this based on index.
                items: RepeatFrequency.values.sublist(1).map<DropdownMenuItem<RepeatFrequency>>((RepeatFrequency value) {
                  return DropdownMenuItem<RepeatFrequency>(
                    value: value,
                    child: Text(value.string),
                  );
                }).toList(),

                decoration: const InputDecoration(
                  labelText: 'Repeat Frequency',
                  labelStyle: TextStyle(
                    color: Colors.black54,
                  ),
                ),

                onChanged: (RepeatFrequency? newValue) {
                  setState(() {
                    _repeatDropdownValue = newValue!;
                  });
                },
              ),

            const Padding(
              padding: EdgeInsets.only(top: 10),
            ),

            if (!_event.isIdea)
              Flexible(child: ListView(
                // shrinkWrap: true,
                children: friendList,
              )),
            if (_event.isIdea)
              Flexible(child: ListView(
                // shrinkWrap: true,
                children: tagList,
              )),
          ],
        ),
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
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                save();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteEvent,
          )
        ],
      ),

      body: Container(
        alignment: Alignment.center,
        child: _buildForm(context)
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
