import 'package:flutter/material.dart';

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
  DateTime birthdate = DateTime.now();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    setState(() {});  // need this?

    _eventId = widget.eventId;

    Event? event;
    // birthdate = DateTime.now();
    if (_eventId != null) {
      event = objectbox.eventBox.get(_eventId!);
      if (event != null) {
        _titleController.text = event.title!;
        _dateController.text = event.dateFormat;
        birthdate = event.date!;
      } else {
        _titleController.text = "Title";
        _dateController.text = "Choose a date";
      }
    }
  }

  save() {
    // Should already be validated...
    // if (_titleController.text.isEmpty) return;

    var event = Event(_titleController.text, date: DateTime.tryParse(_dateController.text));
    if (_eventId != null) {
      event.id = _eventId!;
    }
    _eventId = objectbox.eventBox.put(event);
  }

  _deleteEvent() {
    if (_eventId != null) {
      objectbox.eventBox.remove(_eventId!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
