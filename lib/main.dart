import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_tourism/screens/bot_screen.dart';
import 'dev/bot_dev/cert_bot.dart';
import 'screens/map_screen.dart';

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(MaterialApp(
    thegitme: ThemeData(
      primaryColor: Colors.amberAccent,
    ),
    initialRoute: '/',
    routes: {
      '/': (context) => MapScreen(),
      '/bot':(context) => ChatPage(),
    },

  ));
}



