import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

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
  late Map<String, dynamic> userData;

  late String bloodType;
  late bool locationSignal;
  late double proximityDistance;
  late bool textMessageAlert; 
  late bool soundAlarm;

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
  }

  void setTempVariables() {
    bloodType = userData["bloodType"];
    locationSignal = userData["locationSignal"];
    proximityDistance = userData["proximityDistance"];
    textMessageAlert = userData["textMessageAlert"];
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
            ElevatedButton(
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
                                Center( child: Text( "Proximity distance: $proximityDistance ${proximityDistance == 1 ? "mile" : "miles"}" ) ),
                                Center(
                                  child: Slider( // proximity distance in miles
                                    min: 1.0,
                                    max: 10.0,
                                    value: proximityDistance,
                                    onChanged: (value) {
                                      setState(() {
                                        proximityDistance = double.parse((value).toStringAsFixed(1)); // rounds to 2 decimal places
                                      });
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
                                    onPressed: () {

                                    },
                                    child: const Text( "Select emergency contact" ),
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
            )
          ]
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