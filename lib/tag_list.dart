import 'package:flutter/material.dart';
import 'dart:async';

import 'model.dart';
import 'db.dart';


class TagList extends StatefulWidget {
  const TagList({Key? key}) : super(key: key);

  @override
  _TagListState createState() => _TagListState();
}

class _TagListState extends State<TagList> {
  final _tagInputController = TextEditingController();
  final _listController = StreamController<List<Tag>>(sync: true);

  @override
  void initState() {
    super.initState();

    setState(() {});

    _listController.addStream(objectbox.getTagQueryStream().map((q) => q.find()));
  }

  void _addTag() {
    if (_tagInputController.text.isEmpty) return;
    objectbox.tagBox.put(Tag(_tagInputController.text));
    _tagInputController.text = '';
  }

  @override
  void dispose() {
    _tagInputController.dispose();
    _listController.close();
    super.dispose();
  }

  GestureDetector Function(BuildContext, int) _itemBuilder(List<Tag> tags) =>
          (BuildContext context, int index) => GestureDetector(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                    border:
                    Border(bottom: BorderSide(color: Colors.black12))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 18.0, horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        tags[index].title,
                        style: const TextStyle(
                          fontSize: 15.0,
                        ),
                        // Provide a Key for the integration test
                        key: Key('list_item_$index'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => objectbox.tagBox.remove(tags[index].id),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: TextField(
                      decoration: const InputDecoration(
                          hintText: 'Enter a new tag'),
                      controller: _tagInputController,
                      onSubmitted: (value) => _addTag(),
                      // Provide a Key for the integration test
                      key: const Key('input'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      Expanded(
          child: StreamBuilder<List<Tag>>(
              stream: _listController.stream,
              builder: (context, snapshot) => ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: snapshot.hasData ? snapshot.data!.length : 0,
                  itemBuilder: _itemBuilder(snapshot.data ?? []))))
    ]),
  );
}
