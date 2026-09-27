import 'package:flutter/material.dart';
import 'screens/lock_screen.dart';

void main() {
  runApp(const StittenStoresApp());
}

class StittenStoresApp extends StatelessWidget {
  const StittenStoresApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stitten Stores',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LockScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
