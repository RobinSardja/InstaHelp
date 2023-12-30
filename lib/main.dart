import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:instahelp/firebase_options.dart';

import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

import 'package:flutter_sms/flutter_sms.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:torch_light/torch_light.dart';

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

  String message = "We're ready to help!";
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
    setState(() {
      message = "Help is on the way!";
    });
    if( userData["textMessageAlert"] ) {
      sendTextMessageAlert();
    }
    if( userData["soundAlarm"] ) {
      playSoundAlarm();
    }
    if( userData["blinkFlashlight"] ) {
      startBlinkingFlashlight();
    }
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

  void sendTextMessageAlert() async {
    getPosition();
    try {
        await sendSMS(
          message: "InstaHelp alert! Someone needs your help at www.google.com/maps/search/${position.latitude},${position.longitude}/@${position.latitude},${position.longitude}!",
          recipients: [ userData["emergencyContact"], ],
          sendDirect: true,
        );
    } on Error {
      // handle sending text message error
    }
  }

  final player = AudioPlayer()..setAsset("assets/sound-alarm.mp3")..setLoopMode(LoopMode.one);
  void playSoundAlarm() async {
    await player.seek( const Duration(seconds: 0) ); // reset to beginning of sound effect
    await player.play();
  }

  void startBlinkingFlashlight() async {
    final isTorchAvailable = await TorchLight.isTorchAvailable();
    if( isTorchAvailable ) {
      while( !muted ) {
        await TorchLight.enableTorch();
        await Future.delayed( Duration( milliseconds: userData["blinkSpeed"].toInt() ) );
        await TorchLight.disableTorch();
        await Future.delayed( Duration( milliseconds: userData["blinkSpeed"].toInt() ) );
      } 
    }
  }

  void turnOffFlashlight() async {
    await TorchLight.disableTorch();
  }

  // determines if all required permissions have been granted
  PermissionStatus batteryPermStatus = PermissionStatus.denied;
  PermissionStatus mapPermStatus = PermissionStatus.denied;
  PermissionStatus micPermStatus = PermissionStatus.denied;
  PermissionStatus smsPermStatus = PermissionStatus.denied;

  // updates all permission variables with current device permissions
  void checkAllPermissions() async {
    final newMapPermStatus = await Permission.location.status;
    final newMicPermStatus = await Permission.microphone.status;
    final newSmsPermStatus = await Permission.sms.status;
    final newbatteryPermStatus = await Permission.ignoreBatteryOptimizations.status;
    setState(() {
      batteryPermStatus = newbatteryPermStatus;
      mapPermStatus = newMapPermStatus;
      micPermStatus = newMicPermStatus;
      smsPermStatus = newSmsPermStatus;
    });
  }
  
  // requests for all permissions required
  void requestAllPermissions() async {
    await Permission.ignoreBatteryOptimizations.request().then( (value) async {
      await Permission.location.request().then( (value) async {
        await Permission.microphone.request().then( (value) async {
          await Permission.sms.request().then( (value) async {
            checkAllPermissions();
          });
        });
      });
    });
  }

  // controls switching between pages
  int selectedIndex = 0;

  void changeIndex(updatedIndex) {
    setState(() {
      selectedIndex = updatedIndex;
    });
  }

  // controls swiping between pages
  final pageController = PageController(
    initialPage: 0,
  );

  @override
  void initState() {    
    super.initState();

    createPorcupineManager();
    requestAllPermissions();
    initializePosition();
  }

  @override
  void dispose() {
    porcupineManager.delete();
    player.dispose();
    turnOffFlashlight();

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
          ),
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
            },
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
            },
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
            },
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
        ),
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
            message = muted ? "Glad you're safe!" : "We're ready to help!";
          });
          if( muted ) {
            pauseAudioCapture();
            player.pause();
            turnOffFlashlight();
          } else {
            startAudioCapture();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget permissionRequestPage() {
    return Center(
      child: Column( 
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Please grant all requested permissions"),
          ElevatedButton(
            onPressed: () => requestAllPermissions(),
            child: const Text("Request permissions and check status"),
          ),
          const Text("Alternatively, grant permissions from app settings"),
          ElevatedButton(
            onPressed: () async => await openAppSettings(),
            child: const Text("Grant permissions from app settings"),
          ),
        ],
      ),
    );
  }
}