import 'package:flutter/material.dart';
import 'dart:async';

import 'filters.dart';
import 'model.dart';
import 'db.dart';


// https://www.kindacode.com/article/how-to-create-a-filter-search-listview-in-flutter/
class SearchableSelectionList extends StatefulWidget {
  final Map<int, String> elements;  // {id: value}
  final Set<int>? selected; // Ids of already selected rows, if any.
  final bool showX; // Will show red X if true; otherwise green checkmark.
  final Map<int, Set<String>>? tags;  // If present, will show a list of tags to filter by.

  // Called when widget is disposed of with Set of selected element ids.
  final ValueSetter<Set<int>> onDone;

  const SearchableSelectionList(
      {Key? key, required this.elements,
        this.selected, this.showX = false, this.tags,
        required this.onDone})
      : super(key: key);

  @override
  _SearchableSelectionListState createState() => _SearchableSelectionListState();
}

class _SearchableSelectionListState extends State<SearchableSelectionList> {
  Map<int, String> _allElements = {};
  Map<int, String> _foundElements = {};
  Set<int> _selectedElements = {};

  String _enteredKeyword = "";

  Set<String> _allTags = {};
  Set<String> _selectedTags = {};
  Map<String, Set<int>> _tagToId = {};

  @override
  initState() {
    _allElements = widget.elements;
    _foundElements = _allElements;

    if (widget.selected != null) {
      _selectedElements = widget.selected!;
    }

    if (widget.tags != null) {
      widget.tags!.forEach((id, tagSet) {
        _allTags.addAll(tagSet);

        for (var tag in tagSet) {
          if (!_tagToId.containsKey(tag)) _tagToId[tag] = {};
          _tagToId[tag]!.add(id);
        }
      });
    }

    super.initState();
  }

  // This function is called whenever the text field changes
  void _runFilter() {
    Map<int, String> results = {};
    if (_enteredKeyword.isEmpty) {
      results = _allElements;
    } else {
      results = Map.from(_allElements)
        ..removeWhere((k, v) => !v.toLowerCase().contains(_enteredKeyword.toLowerCase()));
    }

    // Apply tag filters.
    if (_selectedTags.isNotEmpty) {
      Set<int> allowableIds = {};
      for (var e in _selectedTags) {
        allowableIds.addAll(_tagToId[e]!);
      }
      results = Map.from(results)
        ..removeWhere((k, v) => !allowableIds.contains(k));
    }

    // Refresh the UI
    setState(() {
      _foundElements = results;
    });
  }

  void _onTap(int id) {
    setState(() {
      if (_selectedElements.contains(id)) {
        _selectedElements.remove(id);
      } else {
        _selectedElements.add(id);
      }
    });
  }

  void _tagSelectionCallback(String tag) {
    _selectedTags.add(tag);
    _runFilter();
  }
  void _tagDeselectionCallback(String tag) {
    _selectedTags.remove(tag);
    _runFilter();
  }

  Widget _filterChips() {
    List<String> tagNames = [];
    for (var tag in _allTags) {
      tagNames.add(tag);
    }

    return FilterList(
      tags: tagNames,
      selectionCallback: _tagSelectionCallback,
      deselectionCallback: _tagDeselectionCallback,
    );
  }

  @override
  void dispose() {
    widget.onDone(_selectedElements);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapValues = _foundElements.entries.toList();  // ehhhh
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Selection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            TextField(
              onChanged: (value) {
                _enteredKeyword = value;
                _runFilter();
              },
              decoration: const InputDecoration(
                  labelText: 'Search', suffixIcon: Icon(Icons.search)),
            ),
            const SizedBox(
              height: 20,
            ),
            if (_allTags.isNotEmpty) _filterChips(),
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
                    trailing: _selectedElements.contains(mapValues[index].key) ?
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
