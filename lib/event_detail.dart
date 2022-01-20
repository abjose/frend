import 'package:flutter/material.dart';
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

  // DateTime _date = DateTime.now();
  late Event _event;

  // Maybe an awkward way to do this.
  Map<int, String> _selectedFriends = {};
  Map<int, String> _selectedTags = {};
  Map<int, Set<String>> _interestMap = {};

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _event = widget.event;
    // _titleController.text = _event.title ?? "Event Title";
    _titleController.text = _event.title;
    _dateController.text = _event.id != 0 ? _event.dateFormat : "Pick a date";
    if (widget.date != null) {
      _dateController.text = widget.date.toString();
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
    // date saved by DatePicker

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

    objectbox.eventBox.put(_event);

    if (_event.isIdea) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  _deleteEvent() {
    if (_event.id != 0) {
      objectbox.eventBox.remove(_event.id);
    }

    if (_event.isIdea) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
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
              selected: _selectedFriends.keys.toSet(),
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
            TextFormField(
              readOnly: true,
              controller: _dateController,
              decoration: InputDecoration(hintText: 'Pick Date'),
              onTap: () async {
                var date = await showDatePicker(
                    context: context,
                    // initialDate: _event.date, // DateTime.now(),
                    initialDate: DateTime.parse(_dateController.text),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100));
                // _dateController.text = date.toString().substring(0, 10);
                _dateController.text = date.toString();
                _event.date = date!;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a birthdate';
                }
                return null;
              },
            ),
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
        title: Text('Edit Event${_event.isIdea ? " Idea" : ""}'),
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
    _dateController.dispose();
    super.dispose();
  }
}
