import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:instahelp/firebase_options.dart';

import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

import 'package:flutter_sms/flutter_sms.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'map_page.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  String message = "We've got your back!";
  bool muted = false;

  // initialize porcupine wake word manager
  late PorcupineManager porcupineManager;
  static const accessKey = String.fromEnvironment("picovoice", defaultValue: "none");
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
    sendTextMessageAlert();
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
  static const emergencyContact = String.fromEnvironment("contact", defaultValue: "none");

  void sendTextMessageAlert() async {
    try {
        Position location = await getLocation();
        await sendSMS(
          message: "InstaHelp alert! Someone needs your help at www.google.com/maps/search/${location.latitude},${location.longitude}/@${location.latitude},${location.longitude}!",
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

    // TODO: handle when only approximate location is permitted

    return await Geolocator.getCurrentPosition();
  }

  // determines if all required permissions have been granted
  PermissionStatus mapPermStatus = PermissionStatus.denied;
  PermissionStatus micPermStatus = PermissionStatus.denied;
  PermissionStatus smsPermStatus = PermissionStatus.denied;

  // updates all permission variables with current device permissions
  void checkAllPermissions() async {
    final newMapPermStatus = await Permission.location.status;
    setState( () => mapPermStatus = newMapPermStatus );
    final newMicPermStatus = await Permission.microphone.status;
    setState( () => micPermStatus = newMicPermStatus );
    final newSmsPermStatus = await Permission.sms.status;
    setState( () => smsPermStatus = newSmsPermStatus );
  }
  
  // requests for all permissions required
  void requestAllPermissions() async {
    await Permission.location.request().then( (value) async {
      await Permission.microphone.request().then( (value) async {
        await Permission.sms.request();
      });
    });
    checkAllPermissions();
  }

  // controls switching between pages
  int selectedIndex = 1;

  void changeIndex(updatedIndex) {
    setState(() {
      selectedIndex = updatedIndex;
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
    requestAllPermissions();
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
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.red,
          indicatorColor: Colors.white,
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
            ( Set<MaterialState> states ) {
              if( states.contains( MaterialState.selected ) ) {
                return const TextStyle(
                  color: Colors.white,
                );
              }
              return const TextStyle(
                color: Colors.black,
              );
            }
          ),
          iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
            ( Set<MaterialState> states ) {
              if( states.contains( MaterialState.selected ) ) {
                return const IconThemeData(
                  color: Colors.red,
                );
              }
              return const IconThemeData(
                color: Colors.black,
              );
            }
          ),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: MaterialStatePropertyAll( Colors.white ),
          )
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.black,
          thumbColor: Colors.red,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.white,
          actionTextColor: Colors.red,
          contentTextStyle: TextStyle(
            color: Colors.black,
          ),
        ),
        switchTheme: SwitchThemeData(
          trackColor: MaterialStateProperty.resolveWith<Color?>(
            ( Set<MaterialState> states ) {
              if( states.contains( MaterialState.selected ) ) {
                return Colors.red;
              }
              return null;
            }
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("InstaHelp"),
          centerTitle: true,
        ),
        body: PageView(
          controller: pageController,
          onPageChanged: (selectedIndex) => {
            changeIndex(selectedIndex),
          },
          children: [ // pages shown in app
            const ProfilePage(),
            mapPermStatus.isGranted && micPermStatus.isGranted && smsPermStatus.isGranted ?
            homePage() : permissionRequestPage(), // cannot replace condition with function, have to use really long and statement
            const MapPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (updatedIndex) {
            changeIndex(updatedIndex);
            pageController.jumpToPage(updatedIndex);
          },
          selectedIndex: selectedIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon( Icons.person ),
              label: "Profile",
            ),
            NavigationDestination(
              icon: Icon( Icons.home ),
              label: "InstaHelp",
            ),
            NavigationDestination(
              icon: Icon( Icons.map ),
              label: "Map",
            ),
          ],          
        )
      ),
    );
  }

  Widget homePage() {
    return Scaffold(
      body: Center( child: Text( message ) ),
      floatingActionButton: FloatingActionButton(
        child: muted ? const Icon( Icons.mic_off ) : const Icon( Icons.mic ),
        onPressed: () {
          setState(() {
            muted = !muted;
            message = muted ? "Glad you're safe!" : "We've got your back!";
          });
          muted ? pauseAudioCapture() : startAudioCapture();
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget permissionRequestPage() {
    return Center(
      child: Column( 
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Please grant all required permissions"),
          ElevatedButton(
            onPressed: () { requestAllPermissions(); },
            child: const Text("Request required permissions"),
          )
        ],
      ),
    );
  }
}