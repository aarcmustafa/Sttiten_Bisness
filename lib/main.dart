import 'package:flutter/material.dart';
import 'screens/lock_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StittenStoresApp());
}

class StittenStoresApp extends StatelessWidget {
  const StittenStoresApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stitten Stores v2.0',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const LockScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
