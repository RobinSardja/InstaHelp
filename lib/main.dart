import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  // choose keyword based on current operating system
  final String platform = Platform.isAndroid ? "android" : "ios";
  // TO DO: set these variables in the settings route
  final String _phoneNumber = "5551234567";
  final String _username = "Robin";
  final String _accessKey = "hAHKQ8DcL6G15ApEwPYuh+IQIzfclLkl++sDQtuWHFZvqHUSlfH92w==";
  late PorcupineManager _porcupineManager;
  late AnimationController breathController;
  var breath = 0.0;
  bool switchValue = true;
  int currentIndex = 0;
  late PageController pageController;

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
            'body': 'InstaHelp Alert! $_username needs you help!',
          }),
        );

        launchUrl(textNumber);
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
    breathController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 2000));
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
  @override void dispose() {
    super.dispose();

    _porcupineManager.delete();
  }

  @override
  Widget build(BuildContext context) {
    final breathsize = breath;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Text(widget.title),
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
                color: Colors.blue,
              ),
              //CONTACTS
              //MAIN SCREEN
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                  child: Column(
                      children: [
                        Stack(
                          //alignment:new Alignment(x, y)
                          children: <Widget>[
                            Positioned(
                              child: Container (
                                margin: const EdgeInsets.fromLTRB(0, 100, 0, 0),
                                //alignment:Alignment.center,
                                height: 230,
                                width: 230,
                                child: Material(
                                  borderRadius: BorderRadius.circular(switchValue ? 180 * breathsize : 180),
                                  color: switchValue ? Color(0xffffb5bd) : Color(
                                      0xff9f9f9f),
                                  child: Icon(
                                    Icons.earbuds,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              child: Container (
                                margin: const EdgeInsets.fromLTRB(13, 112, 0, 0),
                                //alignment:Alignment.center,
                                height: 200,
                                width: 200,
                                child: Material(
                                  borderRadius: BorderRadius.circular(switchValue ? 180 * breathsize : 180),
                                  color: switchValue ? Color(0xffff8091) : Color(
                                      0xff565656),
                                  child: Icon(
                                    Icons.earbuds,
                                    size: 50,
                                    color:Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              child: Container (
                                margin: const EdgeInsets.fromLTRB(33, 132, 0, 0),
                                //alignment:Alignment.center,
                                height: 160,
                                width: 160,
                                child: Material(
                                  borderRadius: BorderRadius.circular(switchValue ? 160 * breathsize : 160),
                                  color: switchValue ? Colors.red : Colors.black,
                                  child: switchValue ? Icon(
                                    Icons.mic,
                                    size: 50,
                                    color:Colors.white,
                                  ) : Icon(
                                    Icons.mic_none,
                                    size: 50,
                                    color:Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ), //BREATHING ICON
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child:
                          switchValue ? Text(
                            _menuMessage,
                            style: TextStyle(color: Colors.red,
                              fontSize: 20,
                            ),
                          ) : Text(
                            _menuMessage,
                            style: TextStyle(color: Colors.black,
                              fontSize: 20,
                            ),
                          ),
                        ), //TEXT
                        CupertinoSwitch(
                          // This bool value toggles the switch.
                          value: switchValue,
                          activeColor: Colors.red,
                          onChanged: (bool? value) {
                            setState(() {
                              switchValue = value ?? false;
                            });
                          },
                        ),
                      ]
                  ),
                ),
              ),
              //MAIN SCREEN
              //SETTINGS
              Container(
                color: Colors.green,
              ),
              //SETTINGS
            ]

        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.red,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15,
              vertical: 30),
          child: GNav(
            //TAB CHANGE
            onTabChange: (index) {
              print(index);
              pageController.jumpToPage(index);
            },
            //TAB CHANGE
            backgroundColor: Colors.red,
            color: Colors.white,
            activeColor: Colors.white,
            tabBackgroundColor: Colors.redAccent,
            padding: EdgeInsets.all(30),
            gap: 4,
            tabs: [
              GButton(
                  icon: Icons.list,
                  text: 'Contacts'
              ),
              GButton(
                  icon: Icons.shield,
                  text: 'Instahelp'
              ),
              GButton(
                  icon: Icons.settings,
                  text: 'Settings'
              ),
            ],
          ),
        ),
      ),
    );
  }
