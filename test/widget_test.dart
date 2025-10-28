// This is a basic Flutter widget file converted to a runnable app.
//
// The flutter_test package is only available in test environments; to avoid
// depending on it in this file we provide a normal app entrypoint instead.

import 'package:flutter/material.dart';

// Provide a minimal MyApp when lib/main.dart is missing.
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test App')),
        body: Center(child: Text('$_counter')),
        floatingActionButton: FloatingActionButton(
          onPressed: _increment,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}
