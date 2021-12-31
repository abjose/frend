import 'package:flutter/material.dart';

import 'model.dart';
import 'db.dart';

class FriendDetail extends StatefulWidget {
  final int? friendId;
  final ObjectBox db;

  const FriendDetail({required this.friendId, required this.db});

  @override
  _FriendDetailState createState() => _FriendDetailState(friendId, db);
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
  final ObjectBox _db;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  _FriendDetailState(this._friendId, this._db);

  save() {
    // Should already be validated...
    // if (_nameController.text.isEmpty) return;

    var friend = Friend(_nameController.text, date: DateTime.tryParse(_dateController.text));
    if (_friendId != null) {
      friend.id = _friendId!;
    }
    _friendId = _db.friendBox.put(friend);
  }

  _deleteFriend() {
    if (_friendId != null) {
      _db.friendBox.remove(_friendId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    Friend? friend;
    DateTime birthdate = DateTime.now();
    if (_friendId != null) {
      friend = _db.friendBox.get(_friendId!);
      if (friend != null) {
        _nameController.text = friend.name!;
        _dateController.text = friend.dateFormat;
        birthdate = friend.birthdate!;
      } else {
        _nameController.text = "Name";
        _dateController.text = "Choose a date";
      }
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
    super.dispose();
  }
}
