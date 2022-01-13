import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';


class ActorFilterEntry {
  const ActorFilterEntry(this.name, this.initials);
  final String name;
  final String initials;
}

class FilterList extends StatefulWidget {
  final List<String> tags;
  final ValueSetter<String> selectionCallback;
  final ValueSetter<String> deselectionCallback;
  
  const FilterList({
    Key? key,
    required this.tags,
    required this.selectionCallback,
    required this.deselectionCallback}) : super(key: key);

  @override
  State createState() => _FilterListState();
}

class _FilterListState extends State<FilterList> {
  final List<String> _selected = <String>[];

  Iterable<Widget> get actorWidgets sync* {
    for (final String tag in widget.tags) {
      yield Padding(
        padding: const EdgeInsets.all(2.0),
        child: FilterChip(
          label: Text(tag, textScaleFactor: .8),
          selected: _selected.contains(tag),
          onSelected: (bool value) {
            setState(() {
              if (value) {
                _selected.add(tag);
                widget.selectionCallback(tag);
              } else {
                _selected.removeWhere((String s) {
                  return s == tag;
                });
                widget.deselectionCallback(tag);
              }
            });
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ExpansionTile(
          title: const Text('Filter by Tag'),
          children: <Widget>[
            Wrap(
              children: actorWidgets.toList(),
            ),
          ],
        ),
      ],
    );
  }
}