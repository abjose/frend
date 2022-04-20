import 'package:flutter/material.dart';

void showConfirmationDialog(BuildContext context, String text, VoidCallback cb) {
  showDialog(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Please Confirm'),
          content: Text(text),
          actions: [

            // Yes button
            TextButton(
                onPressed: () {
                  // Close the dialog
                  Navigator.of(context).pop();

                  cb();
                },
                child: const Text('Yes')),

            // No button
            TextButton(
                onPressed: () {
                  // Close the dialog
                  Navigator.of(context).pop();
                },
                child: const Text('No'))
          ],
        );
      });
}