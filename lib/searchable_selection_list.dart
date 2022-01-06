import 'package:flutter/material.dart';
import 'dart:async';

import 'model.dart';
import 'db.dart';


// https://www.kindacode.com/article/how-to-create-a-filter-search-listview-in-flutter/
class SearchableSelectionList extends StatefulWidget {
  final Map<int, String> elements;  // {id: value}
  final Set<int>? selected; // Ids of already selected rows, if any.
  final bool showX; // Will show red X if true; otherwise green checkmark.

  // Called when widget is disposed of with Set of selected element ids.
  final ValueSetter<Set<int>> onDone;

  const SearchableSelectionList(
      {Key? key, required this.elements,
        this.selected, this.showX = false, required this.onDone})
      : super(key: key);

  @override
  _SearchableSelectionListState createState() => _SearchableSelectionListState();
}

class _SearchableSelectionListState extends State<SearchableSelectionList> {
  Map<int, String> _allElements = {};
  Map<int, String> _foundElements = {};
  Set<int> _selected = {};

  @override
  initState() {
    _allElements = widget.elements;
    _foundElements = _allElements;

    if (widget.selected != null) {
      _selected = widget.selected!;
    }

    super.initState();
  }

  // This function is called whenever the text field changes
  void _runFilter(String enteredKeyword) {
    Map<int, String> results = {};
    if (enteredKeyword.isEmpty) {
      results = _allElements;
    } else {
      results = Map.from(_allElements)
        ..removeWhere((k, v) => !v.toLowerCase().contains(enteredKeyword.toLowerCase()));
    }

    // Refresh the UI
    setState(() {
      _foundElements = results;
    });
  }

  void _onTap(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  void dispose() {
    widget.onDone(_selected);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapValues = _foundElements.entries.toList();  // ehhhh
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            TextField(
              onChanged: (value) => _runFilter(value),
              decoration: const InputDecoration(
                  labelText: 'Search', suffixIcon: Icon(Icons.search)),
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: _foundElements.isNotEmpty
                  ? ListView.builder(
                itemCount: _foundElements.length,
                itemBuilder: (context, index) => Card(
                  // key: ValueKey(_foundUsers[index]["id"]),
                  color: Colors.amberAccent,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    // leading: Text(
                    //   _foundUsers[index]["id"].toString(),
                    //   style: const TextStyle(fontSize: 24),
                    // ),
                    title: Text(mapValues[index].value),
                    trailing: _selected.contains(mapValues[index].key) ?
                      (widget.showX ? Icon(Icons.close, color: Colors.red) : Icon(Icons.check, color: Colors.green)) :
                      null,
                    // trailing:
                    onTap: () => { _onTap(mapValues[index].key) },
                  ),
                ),
              )
                  : const Text(
                'No results found',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
