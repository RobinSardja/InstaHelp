import 'package:flutter/material.dart';

import 'dart:io';

import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {

  // choose keyword based on current operating system
  final String platform = Platform.isAndroid ? "android" : "ios";

  final String _accessKey = "hAHKQ8DcL6G15ApEwPYuh+IQIzfclLkl++sDQtuWHFZvqHUSlfH92w==";
  late PorcupineManager _porcupineManager;

  String _menuMessage = "We've got you covered!";


  // initialize wake word manager
  void createPorcupineManager() async {
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        [
          "assets/someone-help-me_en_${platform}_v2_2_0.ppn",
        ],
        _wakeWordCallback,
      );

      startAudioCapture();

    } on PorcupineActivationException {
      // handle wake word initialization error
    }
  }

  // code to run when wake word detected
  void _wakeWordCallback( int keywordIndex ) {
    if( keywordIndex == 0 ) {
      setState(() {
        _menuMessage = "Help is on the way!";
      });
    }
  }

  // start listening for wake word
  void startAudioCapture() async {
    try {
      await _porcupineManager.start();
    } on PorcupineException {
      // handle audio exception
    }
  }

  // initialize wake word manager upon starting app
  @override void initState() {
    super.initState();

    createPorcupineManager();
  }

  // delete wake word manager upon exiting app
  @override void dispose() {
    super.dispose();

    _porcupineManager.delete();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(_menuMessage),
        ),
      ),
    );
  }
}
