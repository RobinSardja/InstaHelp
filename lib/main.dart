import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // ensures app stays in portrait mode
  SystemChrome.setPreferredOrientations( [DeviceOrientation.portraitUp] );

  // ensures firebase features work
  await initializeFirebase();

  runApp( const InstaHelp() );
}

class InstaHelp extends StatefulWidget {
  const InstaHelp({super.key});

  @override
  State<InstaHelp> createState() => _InstaHelpState();
}

class _InstaHelpState extends State<InstaHelp> {

  String _message = "We're ready to help!";
  bool _muted = false;

  // initialize porcupine wake word manager
  late PorcupineManager _porcupineManager;
  static const _accessKey = String.fromEnvironment("picovoice", defaultValue: "none");
  final _platform = Platform.isAndroid ? "android" : "ios";

  Future<void> createPorcupineManager() async {
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        [
          "assets/get-away-from-me_en_${_platform}_v3_0_0.ppn",
          "assets/leave-me-alone_en_${_platform}_v3_0_0.ppn",
          "assets/somebody-help_en_${_platform}_v3_0_0.ppn",
        ],
        wakeWordCallback,
      );

      await _porcupineManager.start();
    } on PorcupineException {
      // handle any errors
    }
  }

  // features to run when call for help detected
  void wakeWordCallback(keywordIndex) {
    setState( () => _message = "Help is on the way!" );
    if( userData["textMessageAlert"] ) sendTextMessageAlert();
    if( userData["soundAlarm"] ) playSoundAlarm();
    if( userData["blinkFlashlight"] ) startBlinkingFlashlight();
  }

  Future<void> sendTextMessageAlert() async {

    List<String> recipients = [];

    for( int i = 0; i < userData["emergencyContacts"].length; i++ ) { // extracts phone number
      recipients.add( String.fromCharCodes( userData["emergencyContacts"][i].toString().codeUnits.where( (x) => (x ^0x30) <= 9 ) ) );
    }

    await getPosition();
    try {
        await sendSMS(
          message: "InstaHelp alert! ${currentUser.displayName == null ||
            currentUser.displayName!.replaceAll(" ", "").isEmpty ?
            "Someone" : currentUser.displayName} needs your help at "
            "www.google.com/maps/search/${currentPosition.latitude},${currentPosition.longitude}"
            "/@${currentPosition.latitude},${currentPosition.longitude}! "
            "${userData["medicalInfo"] ? "Blood Type: ${userData["bloodType"]}" : "" }",
          recipients: recipients,
          sendDirect: true,
        );
    } on Error {
      // handle sending text message error
    }
  }

  final _player = AudioPlayer()..setAsset("assets/siren.wav")..setLoopMode(LoopMode.one);
  Future<void> playSoundAlarm() async {
    await _player.seek( const Duration( seconds: 0 ), ); // reset to beginning of sound effect
    await _player.play();
  }

  Future<void> startBlinkingFlashlight() async {
    final isTorchAvailable = await TorchLight.isTorchAvailable();
    if( isTorchAvailable ) {
      while( !_muted ) {
        await TorchLight.enableTorch();
        await Future.delayed( Duration( milliseconds: userData["blinkSpeed"].round(), ), );
        await TorchLight.disableTorch();
        await Future.delayed( Duration( milliseconds: userData["blinkSpeed"].round(), ), );
      } 
    }
  }

  // determines if all required permissions have been granted
  PermissionStatus _mapPermStatus = PermissionStatus.denied;
  PermissionStatus _micPermStatus = PermissionStatus.denied;
  PermissionStatus _smsPermStatus = PermissionStatus.denied;

  // updates all permission variables with current device permissions
  Future<void> checkAllPermissions() async {
    final newMapPermStatus = await Permission.location.status;
    final newMicPermStatus = await Permission.microphone.status;
    final newSmsPermStatus = await Permission.sms.status;
    setState(() {
      _mapPermStatus = newMapPermStatus;
      _micPermStatus = newMicPermStatus;
      _smsPermStatus = newSmsPermStatus;
    });
  }
  
  // requests for all permissions required
  Future<void> requestAllPermissions() async {
    await Permission.location.request().then( (value) async {
      await Permission.microphone.request().then( (value) async {
        await Permission.sms.request().then( (value) async {
          await checkAllPermissions();
          await createPorcupineManager();
          await initializePosition();
        });
      });
    });
  }

  // controls switching between pages
  int _selectedIndex = 0;
  final pageController = PageController(
    initialPage: 0,
  );

  @override
  void initState() {    
    super.initState();

    requestAllPermissions();
  }

  @override
  void dispose() async {
    await _player.dispose();
    await TorchLight.disableTorch();
    await _porcupineManager.delete();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      theme: ThemeData.light().copyWith( // app theme
        colorScheme: const ColorScheme.light(
          primary: Colors.red,
          secondary: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        outlinedButtonTheme: const OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll( Colors.black ),
          ),
        ),
        elevatedButtonTheme: const ElevatedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll( Colors.white ),
            backgroundColor: MaterialStatePropertyAll( Colors.red ),
          ),
        ),
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll( Colors.red ),
          )
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          floatingLabelStyle: TextStyle( color: Colors.black ),
          focusedBorder: UnderlineInputBorder( borderSide: BorderSide( color: Colors.black ), ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.red,
          indicatorColor: Colors.white,
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
            ( Set<MaterialState> states ) {
              return TextStyle(
                color: states.contains( MaterialState.selected ) ? Colors.white : Colors.black,
              );
            },
          ),
          iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
            ( Set<MaterialState> states ) {
              return IconThemeData(
                color: states.contains( MaterialState.selected ) ? Colors.red : Colors.black,
              );
            },
          ),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: MaterialStatePropertyAll( Colors.white ),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.black,
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
              return states.contains( MaterialState.selected ) ? Colors.red : null;
            },
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("InstaHelp"),
        ),
        body: PageView(
          controller: pageController,
          onPageChanged: (changedIndex) => setState( () => _selectedIndex = changedIndex ),
          children: [ // pages shown in app
            const ProfilePage(),
            _mapPermStatus.isGranted && _micPermStatus.isGranted && _smsPermStatus.isGranted ?
            homePage() : permissionRequestPage(), // cannot replace condition with function, have to use really long and statement
            const MapPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (changedIndex) {
            setState( () => _selectedIndex = changedIndex );
            pageController.jumpToPage(changedIndex);
          },
          selectedIndex: _selectedIndex,
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
      body: Center( child: Text( _message, style: const TextStyle( fontSize: 36 ), ), ),
      floatingActionButton: FloatingActionButton(
        child: _muted ? const Icon( Icons.mic_off ) : const Icon( Icons.mic ),
        onPressed: () async {
          setState(() {
            _muted = !_muted;
            _message = _muted ? "Glad you're safe!" : "We're ready to help!";
          });
          if( _muted ) {
            await _porcupineManager.stop();
            _player.stop();
            await TorchLight.disableTorch();
          } else {
            await _porcupineManager.start();
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
          const Text( "Please grant all required permissions" ),
          ElevatedButton(
            onPressed: () async => await requestAllPermissions(),
            child: const Text( "Request permissions and check status" ),
          ),
          const Text( "Alternatively, grant permissions from app settings" ),
          ElevatedButton(
            onPressed: () async => await openAppSettings(),
            child: const Text( "Grant permissions from app settings" ),
          ),
        ],
      ),
    );
  }
}