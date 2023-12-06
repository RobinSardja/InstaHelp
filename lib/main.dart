import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:geolocator/geolocator.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
void main() {
  runApp( MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const InstaHelp(),
    theme: ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light().copyWith(
        primary: Colors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.red,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.red,
        selectedItemColor: Colors.white,
        showSelectedLabels: false,
        unselectedItemColor: Colors.black,
        showUnselectedLabels: false,
      )
    ),
  ));
}

class InstaHelp extends StatefulWidget {
  const InstaHelp({super.key});

  @override
  State<InstaHelp> createState() => _InstaHelpState();
}

class _InstaHelpState extends State<InstaHelp> with TickerProviderStateMixin {

  // contact list variables
  final FlutterContactPicker _contactPicker = FlutterContactPicker();
  Contact? _contact;
  String? _number;
  final FlutterContactPicker _contactPicker2 = FlutterContactPicker();
  Contact? _contact2;
  String? _number2;
  final FlutterContactPicker _contactPicker3 = FlutterContactPicker();
  Contact? _contact3;
  String? _number3;

  // choose keyword based on current operating system
  final String platform = Platform.isAndroid ? "android" : "ios";

  // TO DO: set these variables in the settings route
  final List<String> _contactList = [];
  String _username = "A loved one";

  // speech detection variables
  late PorcupineManager _porcupineManager;
  final String _accessKey = "hAHKQ8DcL6G15ApEwPYuh+IQIzfclLkl++sDQtuWHFZvqHUSlfH92w==";
  int blobbystate = 0;

  // gps variables
  late String _latitude;
  late String _longitude;
  String _googleMapsLink = "Google Maps";

  // styling variables
  late AnimationController breathController;
  var breath = 0.0;
  bool switchValue = true;
  bool switchOneValue = true;
  bool switchTwoValue = true;
  bool switchThreeValue = true;
  int _currentIndex = 0;
  late PageController pageController;

  List<Color> outpallette = [const Color(0xffffb5bd), const Color(0xff9f9f9f),const Color.fromARGB(255, 180, 255, 163)];
  List<Color> midpallette = [const Color(0xffff8091), const Color(0xff565656),const Color.fromARGB(255, 128, 255, 100)];
  List<Color> inpallette = [Colors.red, Colors.black,const Color.fromARGB(255, 0, 219, 37)];
  List<Color> butpallette = [Colors.red, Colors.black, Colors.black];

  String _menuMessage = "We're here to help!";

  // initialize wake word manager
  void createPorcupineManager() async {
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        [
          "assets/someone-help-me_en_${platform}_v2_2_0.ppn",
          "assets/somebody-help_en_${platform}_v2_2_0.ppn",
        ],
        _wakeWordCallback,
      );

      startAudioCapture();
    } on PorcupineActivationException {
      // handle wake word initialization error
    }
  }

  // code to run when wake word detected
  void _wakeWordCallback(int keywordIndex) {
    if (keywordIndex == 0 || keywordIndex == 1) {
      _getCurrentLocation().then((value) {

        _latitude = "${value.latitude}";
        _longitude = "${value.longitude}";
        _googleMapsLink = "www.google.com/maps/search/$_latitude,$_longitude/@$_latitude,$_longitude";

        setState(() {
          _menuMessage = "Help is on the way!";
          blobbystate = 2;
          _sendSMS(
            "InstaHelp Alert! $_username needs your help at $_googleMapsLink",
            _contactList,
          );
        });
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

  void pauseAudioCapture() async {
    try {
      await _porcupineManager.stop();
    } on PorcupineException {
      // handle audio exception
    }
  }

  // get the user's current coordinates
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          "Location permissions are permanently denied. We cannot track your location.");
    }

    return await Geolocator.getCurrentPosition();
  }

  void _sendSMS( String message, List<String> recipients ) async {
    await sendSMS( message: message, recipients: recipients, sendDirect: true );
  }

  // initialize wake word manager and breath animation controller upon starting app
  @override
  void initState() {
    super.initState();

    createPorcupineManager();

    breathController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        breathController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        breathController.forward();
      }
    });
    breathController.addListener(() {
      setState(() {
        breath = breathController.value;
      });
    });
    breathController.forward();
    pageController = PageController();
  }

  // delete wake word manager upon exiting app
  @override
  void dispose() {
    super.dispose();

    _porcupineManager.delete();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    final breathsize = breath;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('InstaHelp'),
          backgroundColor: Colors.red,
        ),
        body: SizedBox.expand(
          child: PageView(
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              // contacts
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 120, 0, 0),
                      child: Text(
                        'Contacts',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 30,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          MaterialButton(
                            color: Colors.red,
                            child: const Padding(
                              padding: EdgeInsets.fromLTRB(5, 13, 5, 13),
                              child: Text(
                                "Select Contact 1",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              Contact? contact =
                                  await _contactPicker.selectContact();
                              setState(() {
                                _contact = contact;
                                if( !_contactList.contains( _contact.toString() ) ) {
                                  _number = String.fromCharCodes( 
                                    _contact.toString().codeUnits.where((x) => (x ^0x30) <= 9)
                                  );
                                  _contactList.add( _number.toString() );
                                }
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: Text(
                              _contact == null
                                  ? "No contact selected."
                                  : _contact.toString(),
                            ),
                          ),
                          MaterialButton(
                            color: Colors.red,
                            child: const Padding(
                              padding: EdgeInsets.fromLTRB(5, 13, 5, 13),
                              child: Text(
                                "Select Contact 2",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              Contact? contact =
                                  await _contactPicker2.selectContact();
                              setState(() {
                                _contact2 = contact;
                                if( !_contactList.contains( _contact2.toString() ) ) {
                                  _number2 = String.fromCharCodes( 
                                    _contact2.toString().codeUnits.where((x) => (x ^0x30) <= 9)
                                  );
                                  _contactList.add( _number2.toString() );
                                }
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: Text(
                              _contact2 == null
                                  ? "No contact selected."
                                  : _contact2.toString(),
                            ),
                          ),
                          MaterialButton(
                            color: Colors.red,
                            child: const Padding(
                              padding: EdgeInsets.fromLTRB(5, 13, 5, 13),
                              child: Text(
                                "Select Contact 3",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              Contact? contact =
                                  await _contactPicker3.selectContact();
                              setState(() {
                                _contact3 = contact;
                                if( !_contactList.contains( _contact3.toString() ) ) {
                                  _number3 = String.fromCharCodes( 
                                    _contact3.toString().codeUnits.where((x) => (x ^0x30) <= 9)
                                  );
                                  _contactList.add( _number3.toString() );
                                }
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: Text(  
                              _contact3 == null
                                  ? "No contact selected."
                                  : _contact3.toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // contacts
              // main screen
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                  child: Column(children: [
                    Stack(
                      children: <Widget>[
                        Positioned(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(0, 100, 0, 0),
                            height: 230,
                            width: 230,
                            child: Material(
                              borderRadius: BorderRadius.circular(
                                  switchValue ? 180 * breathsize : 180),
                              color: outpallette[blobbystate],
                              child: const Icon(
                                Icons.earbuds,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(13, 112, 0, 0),
                            height: 200,
                            width: 200,
                            child: Material(
                              borderRadius: BorderRadius.circular(
                                  switchValue ? 180 * breathsize : 180),
                              color: midpallette[blobbystate],
                            ),
                          ),
                        ),
                        Positioned(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(33, 132, 0, 0),
                            height: 160,
                            width: 160,
                            child: Material(
                              borderRadius: BorderRadius.circular(
                                switchValue ? 160 * breathsize : 160
                              ),
                              color: inpallette[blobbystate],
                              child: switchValue
                                ? const Icon(
                                  Icons.mic,
                                  size: 50,
                                  color: Colors.white,
                                )
                                : const Icon(
                                  Icons.mic_none,
                                  size: 50,
                                  color: Colors.white,
                                ),
                            ),
                          ),
                        ),
                      ],
                    ), //Breathing Icon
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: switchValue
                          ? Text(
                              _menuMessage,
                              style: TextStyle(
                                color: butpallette[blobbystate],
                                fontSize: 30,
                              ),
                            )
                          : Text(
                              _menuMessage,
                              style: TextStyle(
                                color: butpallette[blobbystate],
                                fontSize: 30,
                              ),
                            ),
                    ), // text
                    CupertinoSwitch(
                      // this bool value toggles the switch.
                      value: switchValue,
                      activeColor: Colors.red,
                      onChanged: (bool value) {
                        setState(() {
                          switchValue = value;
                          // display encouraging message whether on or off
                          if (value) {
                            blobbystate = 0;
                            _menuMessage = "We're here to help!";
                            startAudioCapture();
                          } else {
                            blobbystate = 1;
                            _menuMessage = "Glad you're safe!";
                            pauseAudioCapture();
                          }
                        });
                      },
                    ),
                  ]),
                ),
              ),
              // main screen
              // settings
              Container(
                color: Colors.white,
                child: Center(
                  child:
                    SizedBox(
                      width: 300.0,
                      child: TextField(
                        onChanged: (name) {
                          setState(() {
                            _username = name;
                          });
                        },
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: "What's your name?",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    )
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.sms),
              label: "Contacts",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield),
              label: "InstaHelp",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            )
          ],
          
          currentIndex: _currentIndex,
          onTap: (index) {
            pageController.jumpToPage(index);
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
