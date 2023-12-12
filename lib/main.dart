import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';

import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ensure app stays in portrait mode
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) =>
    runApp(
      const InstaHelp()
    )
  );
}

class InstaHelp extends StatefulWidget {
  const InstaHelp({super.key});

  @override
  State<InstaHelp> createState() => _InstaHelpState();
}

class _InstaHelpState extends State<InstaHelp> {

  String message = "Listening";
  bool muted = false;

  // initialize porcupine wake word manager
  late PorcupineManager porcupineManager;
  static const accessKey = String.fromEnvironment('picovoice', defaultValue: 'none');
  final platform = Platform.isAndroid ? "android" : "ios";
  void createPorcupineManager() async {
    try {
      porcupineManager = await PorcupineManager.fromBuiltInKeywords(
        accessKey,
        [
          BuiltInKeyword.HEY_GOOGLE,
        ],
        wakeWordCallback,
      );

      startAudioCapture();
    } on PorcupineException {
      // handle any errors
    }
  }

  // controls actions when wake word detected
  void wakeWordCallback(keywordIndex) {
    setState(() {
      message = "Hello!";
    });
  }

  // start listening for porcupine wake word
  void startAudioCapture() async {
    try {
      await porcupineManager.start();
    } on PorcupineException {
      // handle any errors
    }
  }

  // pause listening for porcupine wake word
  void pauseAudioCapture() async {
    try {
      await porcupineManager.stop();
    } on PorcupineException {
      // handle any errors
    }
  }

  // controls switching between pages
  int currentIndex = 1;
  void changeIndex(selectedIndex) {
    setState(() {
      currentIndex = selectedIndex;
    });
  }

  // controls swiping between pages
  final pageController = PageController(
    initialPage: 1,
  );

  // determines if all required permissions have been granted
  PermissionStatus micPermStatus = PermissionStatus.denied;

  // updates permission variables with current device permissions
  void updatePermissions() async {
    final newMicPermStatus = await Permission.microphone.status;
    setState(() => micPermStatus = newMicPermStatus );
  }
  
  // requests for all permissions required
  void requestPermissions() async {
    await openAppSettings();
    updatePermissions();
  }

  @override
  void initState() {    
    super.initState();

    createPorcupineManager();
    updatePermissions();
  }

  @override
  void dispose() {
    porcupineManager.delete();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        appBarTheme: const AppBarTheme(
          color: Colors.red,
        ),
        elevatedButtonTheme: const ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll( Colors.red ),
          )
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.red,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.red,
          selectedIconTheme: IconThemeData(
            color: Colors.white,
          ),
          selectedItemColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Center( child: Text("InstaHelp") ),
        ),
        body: PageView(
          controller: pageController,
          onPageChanged: (selectedIndex) => {
            changeIndex(selectedIndex),
          },
          children: [
            profile(),
            micPermStatus.isGranted ? home() : permissionRequestPage(),
            settings(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: muted ? const Icon( Icons.mic_off ) : const Icon( Icons.mic ),
          onPressed: () {
            setState(() {
              muted = !muted;
              message = muted ? "Muted" : "Listening";
            });
            muted ? pauseAudioCapture() : startAudioCapture();
          }
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon( Icons.person ),
              label: "Profile",
            ),
            BottomNavigationBarItem(
              icon: Icon( Icons.home ),
              label: "InstaHelp",
            ),
            BottomNavigationBarItem(
              icon: Icon( Icons.settings ),
              label: "Settings",
            ),
          ],
          currentIndex: currentIndex,
          onTap: (selectedIndex) => {
            changeIndex(selectedIndex),
            pageController.jumpToPage(selectedIndex),
          },
        ),
      ),
    );
  }

  // home page
  Widget profile() {
    return const Center( child: Text("Profile") );
  }

  // InstaHelp page
  Widget home() {
    return Center( child: Text(message) );
  }

  // to display when any permissions are not granted
  Widget permissionRequestPage() {
    return Center(
      child: Column( 
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Please grant all required permissions"),
          ElevatedButton(
            onPressed: () { requestPermissions(); },
            child: const Text("Open app settings"),
          )
        ],
      ),
    );
  }

  // settings page
  Widget settings() {
    return const Center( child: Text("Settings") );
  }

}