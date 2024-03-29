import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

import 'package:flutter_sms/flutter_sms.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:torch_light/torch_light.dart';
import 'package:volume_controller/volume_controller.dart';

import 'map_page.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ensures app stays in portrait mode
  SystemChrome.setPreferredOrientations( [DeviceOrientation.portraitUp] );

  // ensures firebase features work
  await firebaseClass.initializeFirebase();

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

  // Implementation of Porcupine Wake Word by Picovoice
  late PorcupineManager _porcupineManager;
  final _platform = Platform.isAndroid ? "android" : "ios";
  static const _accessKey = String.fromEnvironment("picovoice", defaultValue: "none");

  Future<void> _createPorcupineManager() async {
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        [
          "assets/get-away-from-me_en_${_platform}_v3_0_0.ppn",
          "assets/i-cant-get-up_en_${_platform}_v3_0_0.ppn",
          "assets/leave-me-alone_en_${_platform}_v3_0_0.ppn",
          "assets/somebody-help_en_${_platform}_v3_0_0.ppn",
        ],
        _wakeWordCallback,
      );

      await _porcupineManager.start();
    } on PorcupineException {
      // handle any errors
    }
  }

  // features to run when call for help detected
  void _wakeWordCallback(keywordIndex) {
    setState( () => _message = "Help is on the way!" );
    if( userData.getTextMessageAlert() ) _sendTextMessageAlert();
    if( userData.getSoundAlarm() ) _playSoundAlarm();
    if( userData.getBlinkFlashlight() ) _startBlinkingFlashlight();
  }

  Future<void> _sendTextMessageAlert() async {

    List<String> recipients = [];

    for( int i = 0; i < userData.getEmergencyContacts().values.toList().length; i++ ) {
      recipients.add( userData.getEmergencyContacts().values.toList()[i].toString() );
    }

    await getPosition();
    try {
        await sendSMS(
          message: "InstaHelp alert! "

            // send username. If empty, just say "someone"
            "${firebaseClass.currentUser.displayName == null ||
            firebaseClass.currentUser.displayName!.replaceAll(" ", "").isEmpty ?
            "Someone" : firebaseClass.currentUser.displayName} "

            "needs your help at "

            // send current location of the user
            "www.google.com/maps/search/${currentPosition.latitude},${currentPosition.longitude}"
            "/@${currentPosition.latitude},${currentPosition.longitude}! "

            // if enabled by the user, send the user's medical information
            "${userData.getMedicalInfo() ? "Blood Type: ${userData.getBloodType()}" : "" }",
          recipients: recipients,
          sendDirect: true,
        );
    } on Error {
      // handle sending text message error
    }
  }

  final _volumeController = VolumeController();
  late double _previousVolume;
  final _player = AudioPlayer()..setAsset("assets/siren.wav")..setLoopMode(LoopMode.one);
  Future<void> _playSoundAlarm() async {
    _volumeController.getVolume().then( (volume) => _previousVolume = volume );
    _volumeController.maxVolume();
    await _player.seek( const Duration( seconds: 0 ), ); // reset to beginning of sound effect
    await _player.play();
  }

  Future<void> _startBlinkingFlashlight() async {
    final isTorchAvailable = await TorchLight.isTorchAvailable();
    if( isTorchAvailable ) {
      while( !_muted ) {
        await TorchLight.enableTorch();
        await Future.delayed( Duration( milliseconds: userData.getBlinkSpeed().round(), ), );
        await TorchLight.disableTorch();
        await Future.delayed( Duration( milliseconds: userData.getBlinkSpeed().round(), ), );
      } 
    }
  }

  // determines if all required permissions have been granted
  PermissionStatus _mapPermStatus = PermissionStatus.denied;
  PermissionStatus _micPermStatus = PermissionStatus.denied;
  PermissionStatus _smsPermStatus = PermissionStatus.denied;

  // updates all permission variables with current device permissions
  Future<void> _checkAllPermissions() async {
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
  Future<void> _requestAllPermissions() async {
    await Permission.location.request().then( (value) async {
      await Permission.microphone.request().then( (value) async {
        await Permission.sms.request().then( (value) async {
          await _checkAllPermissions();
          await _createPorcupineManager();
          await initializePosition();
        });
      });
    });
  }

  // controls switching between pages
  int _selectedIndex = 0;
  final _pageController = PageController(
    initialPage: 0,
  );

  @override
  void initState() {    
    super.initState();

    _requestAllPermissions();
  }

  @override
  void dispose() async {
    await _player.dispose();
    await TorchLight.disableTorch();
    await _porcupineManager.delete();
    _volumeController.removeListener();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      theme: ThemeData( // app theme
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
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.red,
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
          behavior: SnackBarBehavior.floating,
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
          controller: _pageController,
          onPageChanged: (changedIndex) => setState( () => _selectedIndex = changedIndex ),
          children: [ // pages shown in app
            const ProfilePage(),
            _mapPermStatus.isGranted && _micPermStatus.isGranted && _smsPermStatus.isGranted ?
            _homePage() : _permissionRequestPage(),
            const MapPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (changedIndex) {
            setState( () => _selectedIndex = changedIndex );
            _pageController.jumpToPage(changedIndex);
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

  Widget _homePage() {
    return Scaffold(
      body: Center( child: Text( _message, style: const TextStyle( fontSize: 36 ), ), ),
      floatingActionButton: FloatingActionButton(
        child: Icon( _muted ? Icons.mic_off : Icons.mic ),
        onPressed: () async {
          setState(() {
            _muted = !_muted;
            _message = _muted ? "Glad you're safe!" : "We're ready to help!";
          });
          if( _muted ) {
            await _porcupineManager.stop();
            _player.stop();
            _volumeController.setVolume( _previousVolume );
            await TorchLight.disableTorch();
          } else {
            await _porcupineManager.start();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _permissionRequestPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text( "Please grant all required permissions" ),
          ElevatedButton(
            onPressed: () async => await _requestAllPermissions(),
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