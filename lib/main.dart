import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ShieldGuardianApp());
}

class ShieldGuardianApp extends StatelessWidget {
  const ShieldGuardianApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Shield Guardian',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: Brightness.light,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
