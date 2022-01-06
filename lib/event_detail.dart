import 'package:flutter/material.dart';
import 'package:frend/searchable_selection_list.dart';

import 'db.dart';
import 'model.dart';


class EventDetail extends StatefulWidget {
  final int? eventId;

  const EventDetail({Key? key, required this.eventId}): super(key: key);

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

  int? _eventId;
  DateTime _date = DateTime.now();

  // Maybe an awkward way to do this.
  Map<int, String> _selectedFriends = {};

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    setState(() {});  // need this?

    _eventId = widget.eventId;

    if (_eventId != null) {
      Event? event = objectbox.eventBox.get(_eventId!);
      if (event != null) {
        _titleController.text = event.title!;
        _dateController.text = event.dateFormat;
        _date = event.date!;

        for (var friend in event.friends) {
          _selectedFriends[friend.id] = friend.name;
        }
      } else {
        _titleController.text = "Title";
        _dateController.text = "Choose a date";
      }
    }
  }

  save() {
    var event = Event(_titleController.text, date: DateTime.tryParse(_dateController.text));
    if (_eventId != null) {
      event.id = _eventId!;
    }

    // TODO: Better way to save friends?
    List<Friend> dbFriends = [];
    for (var friend in _selectedFriends.entries) {
      Friend? maybeFriend = objectbox.friendBox.get(friend.key);
      if (maybeFriend != null) {
        dbFriends.add(maybeFriend);
      }
    }
    event.friends.addAll(dbFriends);

    _eventId = objectbox.eventBox.put(event);
  }

  _deleteEvent() {
    if (_eventId != null) {
      objectbox.eventBox.remove(_eventId!);
      Navigator.pop(context);
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
              onDone: (newSelected) {

                // ehhh
                WidgetsBinding.instance
                    ?.addPostFrameCallback((_) => setState(() {
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

  @override
  Widget build(BuildContext context) {
    List<Card> friendList = [];
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
              onTap: _editFriends,
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
          TextFormField(
            readOnly: true,
            controller: _dateController,
            decoration: InputDecoration(hintText: 'Pick Date'),
            onTap: () async {
              var date = await showDatePicker(
                  context: context,
                  // maybe get most recent birthdate? if click away then lose date
                  initialDate: _date, // DateTime.now(),
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
            children: friendList,
          )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Validate returns true if the form is valid, or false otherwise.
                if (_formKey.currentState!.validate()) {
                  // If the form is valid, display a snackbar. In the real world,
                  // you'd often call a server or save the information in a database.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Processing Data')),
                  );
                  save();
                }
              },
              child: const Text('Save'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: _deleteEvent,
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
