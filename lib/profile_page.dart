import 'package:flutter/material.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  // static const googleClientID = String.fromEnvironment("google", defaultValue: "none");
  bool loggedIn = false;
  final userDetection = FirebaseAuth.instance.authStateChanges();

  late User currentUser;
  late FirebaseFirestore db;
  late DocumentReference<Map<String, dynamic>> docRef;
  Map<String, dynamic> userData = {};

  late String bloodType;
  late bool locationSignal;
  late double proximityDistance;
  late bool textMessageAlert;
  late String emergencyContact;
  late bool soundAlarm;

  final FlutterContactPicker contactPicker = FlutterContactPicker();

  late String snackBarMessage;

  // update database
  void updateFirestore() {
    db = FirebaseFirestore.instance;

    // get current user's data
    docRef = db.collection( "user_options" ).doc( currentUser.uid );
    docRef.get().then(
      (DocumentSnapshot doc) {
        userData = doc.data() as Map<String, dynamic>;
      }
    );

    if( userData.isEmpty ) {
      userData = { // default values for newly created users
        "bloodType": bloodType = "O+",
        "locationSignal" : locationSignal = true,
        "proximityDistance" : proximityDistance = 1.0,
        "textMessageAlert" : textMessageAlert = true,
        "emergencyContact" : emergencyContact = "",
        "soundAlarm" : soundAlarm = true,
      };
    } 
  }

  void setTempVariables() {
    bloodType = userData["bloodType"];
    locationSignal = userData["locationSignal"];
    proximityDistance = userData["proximityDistance"];
    textMessageAlert = userData["textMessageAlert"];
    emergencyContact = userData["emergencyContact"];
    soundAlarm = userData["soundAlarm"];
  }

  @override
  Widget build( BuildContext context ) {
    return StreamBuilder<User?>(
      stream: userDetection,
      builder: (context, snapshot) {

        loggedIn = snapshot.hasData;

        // get current user
        userDetection.listen((User? user) {
          if( user != null ) {
            currentUser = user;
            updateFirestore();
          }
        });
      
        return loggedIn ?
        ProfileScreen( // profile screen to show when user already logged in
          actions: [
            SignedOutAction( (context) {
              setState(() {
                loggedIn = snapshot.hasData;
              });
            })
          ],
          showDeleteConfirmationDialog: true,
          children: [
            ElevatedButton( // edit profile button
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      setTempVariables();
                      return StatefulBuilder( builder: (context, setState) {
                        return Scaffold(
                          appBar: AppBar(
                            automaticallyImplyLeading: false,
                            title: const Center( child: Text( "Edit profile" ) ),
                            centerTitle: true,
                          ),
                          body: Center(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Center(
                                  child: DropdownMenu( // selected blood type
                                    label: const Text( "Select blood type" ),
                                    initialSelection: bloodType,
                                    onSelected: (value) => bloodType = value as String,
                                    dropdownMenuEntries: const [
                                      DropdownMenuEntry(
                                        value: "O+",
                                        label: "O+",
                                      ),
                                      DropdownMenuEntry(
                                        value: "O-",
                                        label: "O-",
                                      ),
                                      DropdownMenuEntry(
                                        value: "A+",
                                        label: "A+",
                                      ),
                                      DropdownMenuEntry(
                                        value: "A-",
                                        label: "A-",
                                      ),
                                      DropdownMenuEntry(
                                        value: "B+",
                                        label: "B+",
                                      ),
                                      DropdownMenuEntry(
                                        value: "B-",
                                        label: "B-",
                                      ),
                                      DropdownMenuEntry(
                                        value: "AB+",
                                        label: "AB+",
                                      ),
                                      DropdownMenuEntry(
                                        value: "AB-",
                                        label: "AB-",
                                      ),
                                    ],
                                  ),
                                ),
                                Center(
                                  child: Row( // location signal
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text( "Location signal" ),
                                      Switch(
                                        value: locationSignal,
                                        onChanged: (value) {
                                          setState(() {
                                            locationSignal = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Center( child: Text( locationSignal ? "Proximity distance: $proximityDistance ${proximityDistance == 1 ? "mile" : "miles"}" : "Location signal disabled" ) ),
                                Center(
                                  child: Slider( // proximity distance in miles
                                    min: 1.0,
                                    max: 10.0,
                                    value: locationSignal ? proximityDistance : 1.0,
                                    onChanged: (value) {
                                      if( locationSignal ) {
                                        setState(() {
                                          proximityDistance = double.parse((value).toStringAsFixed(1)); // rounds to 2 decimal places
                                        });
                                      }
                                    },
                                  ),
                                ),
                                Center(
                                  child: Row( // text message alert
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text( "Text message alert" ),
                                      Switch(
                                        value: textMessageAlert,
                                        onChanged: (value) {
                                          setState(() {
                                            textMessageAlert = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Center( child: Text( "Designated emergency contact:") ),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if( textMessageAlert) {
                                        Contact? value = await contactPicker.selectContact();
                                        setState(() {
                                          emergencyContact = value == null ? "" : String.fromCharCodes(value.toString().codeUnits.where((x) => (x ^0x30) <= 9));
                                        });
                                      }
                                    },
                                    child: Text( textMessageAlert ? emergencyContact == "" ? "No emergency contact selected" : emergencyContact : "Text message alert disabled" ),
                                  )
                                ),
                                Center(
                                  child: Row( // sound alarm
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text( "Sound alarm" ),
                                      Switch(
                                        value: soundAlarm,
                                        onChanged: (value) {
                                          setState(() {
                                            soundAlarm = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          bottomNavigationBar: NavigationBar(
                            onDestinationSelected: (updatedIndex) {
                              snackBarMessage = updatedIndex == 0 ? "Profile changes saved!" : "Profile changes discarded";

                              if( updatedIndex == 0 ) {
                                userData["bloodType"] = bloodType;
                                userData["locationSignal"] = locationSignal;
                                userData["proximityDistance"] = proximityDistance;
                                userData["textMessageAlert"] = textMessageAlert;
                                userData["emergencyContact"] = emergencyContact;
                                userData["soundAlarm"] = soundAlarm;

                                db
                                  .collection( "user_options" )
                                  .doc( currentUser.uid )
                                  .set( userData );
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(snackBarMessage),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: "OK",
                                    onPressed: () {

                                    },
                                  ),
                                ),
                              );

                              updateFirestore();
                              userData = {};
                              Navigator.pop(context);
                            },
                            destinations: const [
                              NavigationDestination(
                                icon: Icon( Icons.save ),
                                label: "Save",
                              ),
                              NavigationDestination(
                                icon: Icon( Icons.delete ),
                                label: "Discard",
                              ),
                            ],
                          ),
                        );
                      });
                    },
                  )
                );
              },
              child: const Center( child: Text( "Edit profile" ) ),
            ),
          ],
        ) : 
        SignInScreen( // sign in screen to show when no one logged in
          providers: [
            EmailAuthProvider(),
            // TODO: get google sign in to work
            // GoogleProvider( clientId: googleClientID )
          ],
          footerBuilder: (context, action) {
            return const Center( child: Text( "InstaHelp accounts are completely optional" ) );
          },
        );
      }
    );
  }
}