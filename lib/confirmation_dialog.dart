import 'package:flutter/material.dart';

void showConfirmationDialog(BuildContext context, String text, VoidCallback cb) {
  showDialog(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Please Confirm'),
          content: Text('Do you want to delete this $text?'),
          actions: [
            // The "Yes" button
            TextButton(
                onPressed: () {
                  // Remove the box
                  // setState(() {
                  //   _isShown = false;
                  // });

                  // Close the dialog
                  Navigator.of(context).pop();

                  cb();


                },
                child: const Text('Yes')),
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