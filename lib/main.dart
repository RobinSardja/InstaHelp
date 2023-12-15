import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

import 'package:flutter_sms/flutter_sms.dart';
import 'package:geolocator/geolocator.dart';
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
      porcupineManager = await PorcupineManager.fromKeywordPaths(
        accessKey,
        [
          "assets/get-away-from-me_en_${platform}_v3_0_0.ppn",
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
    sendInstaHelpAlert();
    setState(() {
      message = "Help is on the way!";
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

  // sends text message alert
  static const emergencyContact = String.fromEnvironment('contact', defaultValue: 'none');

  void sendInstaHelpAlert() async {
    try {
        Position location = await getLocation();
        await sendSMS(
          message: "InstaHelp alert! Someone needs your help at ${location.latitude}, ${location.longitude}!",
          recipients: [emergencyContact],
          sendDirect: true,
        );
    } on Error {
      // handle sending text message error
    }
  }

  // get current location of user
  Future<Position> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if( !serviceEnabled ) {
      return Future.error( "Location services are disabled." );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if( permission == LocationPermission.denied ) {
      permission = await Geolocator.requestPermission();

      if( permission == LocationPermission.denied ) {
        return Future.error( "Location permissions are denied." );
      }
    }

    if( permission == LocationPermission.deniedForever ) {
      return Future.error( "Location permissions are permanently denied, we cannot request permissions." );
    }

    return await Geolocator.getCurrentPosition();
  }

  // determines if all required permissions have been granted
  LocationPermission mapPermStatus = LocationPermission.denied;
  PermissionStatus micPermStatus = PermissionStatus.denied;
  PermissionStatus smsPermStatus = PermissionStatus.denied;

  // updates all permission variables with current device permissions
  void checkPermissions() async {
    final newMapPermStatus = await Geolocator.checkPermission();
    setState( () => mapPermStatus = newMapPermStatus );
    final newMicPermStatus = await Permission.microphone.status;
    setState( () => micPermStatus = newMicPermStatus );
    final newSmsPermStatus = await Permission.sms.status;
    setState( () => smsPermStatus = newSmsPermStatus );
  }
  
  // requests for all permissions required
  void requestPermissions() async {
    await Geolocator.requestPermission().then( (value) async {
      await Permission.microphone.request().then( (value) async {
        await Permission.sms.request();
      });
    });
    checkPermissions();
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

  @override
  void initState() {    
    super.initState();

    createPorcupineManager();
    checkPermissions();
  }

  @override
  void dispose() {
    porcupineManager.delete();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light().copyWith( // app theme
        appBarTheme: const AppBarTheme(
          color: Colors.red,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
          )
        ),
        elevatedButtonTheme: const ElevatedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll( Colors.white ),
            backgroundColor: MaterialStatePropertyAll( Colors.red ),
          )
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.red,
          selectedIconTheme: IconThemeData(
            color: Colors.white,
          ),
          unselectedIconTheme: IconThemeData(
            color: Colors.black,
          ),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.black,
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
            micPermStatus.isGranted && smsPermStatus.isGranted ?
            home() : permissionRequestPage(), // cannot replace condition with function, have to use really long and statement
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
            child: const Text("Request required permissions"),
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