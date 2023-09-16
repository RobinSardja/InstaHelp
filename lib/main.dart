import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MaterialApp(home: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  final FlutterContactPicker _contactPicker = new FlutterContactPicker();
  Contact? _contact;
  final FlutterContactPicker _contactPicker2 = new FlutterContactPicker();
  Contact? _contact2;
  final FlutterContactPicker _contactPicker3 = new FlutterContactPicker();
  Contact? _contact3;
  // choose keyword based on current operating system
  final String platform = Platform.isAndroid ? "android" : "ios";

  // TO DO: set these variables in the settings route
  final String _phoneNumber = "4076150853";
  final String _username = "Nathan";

  // speech detection variables
  late PorcupineManager _porcupineManager;
  final String _accessKey =
      "lxZcL/ZMV0al2l0SayCeX/crV9B7g4GjuJzSqMCtCLrTnXQXk+f7hQ==";

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
  int currentIndex = 1;
  late PageController pageController;

  String _menuMessage = "We've got you covered!";

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
        _googleMapsLink =
            "www.google.com/maps/search/$_latitude,$_longitude/@$_latitude,$_longitude";
        setState(() {
          String? encodeQueryParameters(Map<String, String> params) {
            return params.entries
                .map((MapEntry<String, String> e) =>
                    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
                .join('&');
          }

          final Uri textNumber = Uri(
            scheme: 'sms',
            path: _phoneNumber,
            query: encodeQueryParameters(<String, String>{
              'body':
                  'InstaHelp Alert! $_username needs you help at $_googleMapsLink',
            }),
          );

          launchUrl(textNumber);
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
          toolbarHeight: 80,
          title: const Text('INSTAHELP'),
          backgroundColor: Colors.red,
        ),
        body: SizedBox.expand(
          child: PageView(
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            children: [
              //CONTACTS
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 120, 0, 0),
                      child: Text(
                        'CONTACTS',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 30,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                      child: new Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          new MaterialButton(
                            color: Colors.red,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 13, 5, 13),
                              child: new Text(
                                "SELECT CONTACT 1",
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
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: new Text(
                              _contact == null
                                  ? 'No contact selected.'
                                  : _contact.toString(),
                            ),
                          ),
                          new MaterialButton(
                            color: Colors.red,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 13, 5, 13),
                              child: new Text(
                                "SELECT CONTACT 2",
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
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: new Text(
                              _contact2 == null
                                  ? 'No contact selected.'
                                  : _contact2.toString(),
                            ),
                          ),
                          new MaterialButton(
                            color: Colors.red,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 13, 5, 13),
                              child: new Text(
                                "SELECT CONTACT 3",
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
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: new Text(
                              _contact3 == null
                                  ? 'No contact selected.'
                                  : _contact3.toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              //CONTACTS
              //MAIN SCREEN
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                  child: Column(children: [
                    Stack(
                      //alignment:new Alignment(x, y)
                      children: <Widget>[
                        Positioned(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(0, 100, 0, 0),
                            //alignment:Alignment.center,
                            height: 230,
                            width: 230,
                            child: Material(
                              borderRadius: BorderRadius.circular(
                                  switchValue ? 180 * breathsize : 180),
                              color: switchValue
                                  ? const Color(0xffffb5bd)
                                  : const Color(0xff9f9f9f),
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
                            //alignment:Alignment.center,
                            height: 200,
                            width: 200,
                            child: Material(
                              borderRadius: BorderRadius.circular(
                                  switchValue ? 180 * breathsize : 180),
                              color: switchValue
                                  ? const Color(0xffff8091)
                                  : const Color(0xff565656),
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
                            margin: const EdgeInsets.fromLTRB(33, 132, 0, 0),
                            //alignment:Alignment.center,
                            height: 160,
                            width: 160,
                            child: Material(
                              borderRadius: BorderRadius.circular(
                                  switchValue ? 160 * breathsize : 160),
                              color: switchValue ? Colors.red : Colors.black,
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
                    ), //BREATHING ICON
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: switchValue
                          ? Text(
                              _menuMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 20,
                              ),
                            )
                          : Text(
                              _menuMessage,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                              ),
                            ),
                    ), //TEXT
                    CupertinoSwitch(
                      // This bool value toggles the switch.
                      value: switchValue,
                      activeColor: Colors.red,
                      onChanged: (bool value) {
                        setState(() {
                          switchValue = value;

                          // display encouraging message whether on or off
                          if (value) {
                            _menuMessage = "We've got you covered!";
                          } else {
                            _menuMessage = "Glad you're safe!";
                          }
                        });
                      },
                    ),
                  ]),
                ),
              ),
              //MAIN SCREEN
              //SETTINGS
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(95, 0, 0, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 100, 0),
                        child: Text(
                          "Enter Your Name",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 100, 20),
                        child: SizedBox(
                          width: 200,
                          child: TextField(
                            decoration: InputDecoration(
                                hintText: "Enter Name",
                                border: OutlineInputBorder()),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                            child: Text(
                              "Alarm Sound",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          CupertinoSwitch(
                            value: switchOneValue,
                            activeColor: Colors.red,
                            onChanged: (value) {
                              setState(() {
                                switchOneValue = value;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                            child: Text(
                              "Send Text",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(34, 0, 0, 0),
                            child: CupertinoSwitch(
                              value: switchTwoValue,
                              activeColor: Colors.red,
                              onChanged: (value) {
                                setState(() {
                                  switchTwoValue = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                            child: Text(
                              "Location",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(46, 0, 0, 0),
                            child: CupertinoSwitch(
                              value: switchThreeValue,
                              activeColor: Colors.red,
                              onChanged: (value) {
                                setState(() {
                                  switchThreeValue = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          color: Colors.red,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
            child: GNav(
              //TAB CHANGE
              onTabChange: (index) {
                pageController.jumpToPage(index);
              },
              //TAB CHANGE
              backgroundColor: Colors.red,
              color: Colors.white,
              activeColor: Colors.white,
              tabBackgroundColor: Colors.redAccent,
              padding: const EdgeInsets.all(30),
              gap: 4,
              tabs: const [
                GButton(icon: Icons.list, text: 'Contacts'),
                GButton(icon: Icons.shield, text: 'Instahelp'),
                GButton(icon: Icons.settings, text: 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
