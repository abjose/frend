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

  final TextEditingController _controller = TextEditingController();

  _FriendDetailState(this._friendId, this._db);

  _submit() {
    // print(_controller.text);

    if (_controller.text.isEmpty) return;

    var note = Note(_controller.text);
    if (_friendId != null) {
      note.id = _friendId!;
    }
    _friendId = _db.noteBox.put(note);
    // _controller.text = '';

    // print(_friendId);
  }

  @override
  Widget build(BuildContext context) {
    Note? note;
    if (_friendId != null) {
      note = _db.noteBox.get(_friendId!);
      if (note != null) {
        _controller.text = note.text;
      }
    }
    // print(note?.text);


    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            // decoration: const InputDecoration(hintText: "", text),
            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
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
                  _submit();
                }
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}