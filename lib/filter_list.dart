import 'package:flutter/material.dart';


class FilterList extends StatefulWidget {
  final Set<String> tags;
  final Set<String>? initialSelection;
  final ValueSetter<String>? selectionCallback;
  final ValueSetter<String>? deselectionCallback;
  
  const FilterList({
    Key? key,
    required this.tags,
    this.selectionCallback,
    this.deselectionCallback,
    this.initialSelection}) : super(key: key);

  @override
  State createState() => _FilterListState();
}

class _FilterListState extends State<FilterList> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection ?? <String>{};
  }

  Iterable<Widget> get chipWidgets sync* {
    for (final String tag in widget.tags) {
      yield Padding(
        padding: const EdgeInsets.all(2.0),
        child: FilterChip(
          label: Text(tag, textScaleFactor: .8),
          selected: _selected.contains(tag),
          onSelected: (bool value) {
            if (widget.selectionCallback == null || widget.deselectionCallback == null) {
              return;
            }

            setState(() {
              if (value) {
                _selected.add(tag);
                widget.selectionCallback!(tag);
              } else {
                _selected.removeWhere((String s) {
                  return s == tag;
                });
                widget.deselectionCallback!(tag);
              }
            });
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectionCallback == null || widget.deselectionCallback == null) {
      return Wrap(
        children: chipWidgets.toList(),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ExpansionTile(
          title: const Text('Filter by Tag'),
          children: <Widget>[
            Wrap(
              children: chipWidgets.toList(),
            ),
          ],
        ),
      ],
    );
  }
}