import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  Future<String> _loadAsset(BuildContext context) async {
    return await DefaultAssetBundle.of(context).loadString('assets/help.md');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: _loadAsset(context),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Markdown(data: snapshot.data ?? "no data?");
          }

          if (snapshot.hasError) {
            print("Error loading help.md:, ${snapshot.error}");
          }

          return const Text("Still loading...");
        });
  }
}
