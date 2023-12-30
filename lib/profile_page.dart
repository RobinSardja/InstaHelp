import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:volume_controller/volume_controller.dart';

Map<String, dynamic> userData = {};

late User currentUser;
late FirebaseFirestore db;
late DocumentReference<Map<String, dynamic>> docRef;

late bool medicalInfo;
late String bloodType;
late bool locationSignal;
late double proximityDistance;
late bool textMessageAlert;
late String emergencyContact;
late bool soundAlarm;
late bool blinkFlashlight;
late num blinkSpeed;

// update database
void updateFirestore() {
  db = FirebaseFirestore.instance;

  // get current user's data
  docRef = db.collection( "user_options" ).doc( currentUser.uid );
  docRef.get().then(
    (DocumentSnapshot doc) {
      userData = doc.data() == null ? { // default values for newly created users
        "medicalInfo": medicalInfo = true,
        "bloodType": bloodType = "O+",
        "locationSignal" : locationSignal = true,
        "proximityDistance" : proximityDistance = 5.0,
        "textMessageAlert" : textMessageAlert = true,
        "emergencyContact" : emergencyContact = "",
        "soundAlarm" : soundAlarm = true,
        "blinkFlashlight" : blinkFlashlight = true,
        "blinkSpeed" : blinkSpeed = 250,
      } : doc.data() as Map<String, dynamic>;
    },
  );
}

void setTempVariables() {
  medicalInfo = userData["medicalInfo"];
  bloodType = userData["bloodType"];
  locationSignal = userData["locationSignal"];
  proximityDistance = userData["proximityDistance"];
  textMessageAlert = userData["textMessageAlert"];
  emergencyContact = userData["emergencyContact"];
  soundAlarm = userData["soundAlarm"];
  blinkFlashlight = userData["blinkFlashlight"];
  blinkSpeed = userData["blinkSpeed"];
}

void setFinalVariables() {
  userData["medicalInfo"] = medicalInfo;
  userData["bloodType"] = bloodType;
  userData["locationSignal"] = locationSignal;
  userData["proximityDistance"] = proximityDistance;
  userData["textMessageAlert"] = textMessageAlert;
  userData["emergencyContact"] = emergencyContact;
  userData["soundAlarm"] = soundAlarm;
  userData["blinkFlashlight"] = blinkFlashlight;
  userData["blinkSpeed"] = blinkSpeed;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final googleClientID = ""; // google provider doesn't actually need client ID? package might need updating

  bool loggedIn = false;
  final userDetection = FirebaseAuth.instance.authStateChanges();
  
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
            }),
          ],
          showDeleteConfirmationDialog: true,
          children: [
            ElevatedButton( // edit profile button
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      setTempVariables();
                      return const EditProfilePage();
                    },
                  ),
                );
              },
              child: const Center( child: Text( "Edit profile" ) ),
            ),
          ],
        ) : 
        SignInScreen( // sign in screen to show when no one logged in
          providers: [
            EmailAuthProvider(),
            GoogleProvider( clientId: googleClientID ),
          ],
          footerBuilder: (context, action) {
            return const Center( child: Text( "InstaHelp accounts are completely optional" ) );
          },
        );
      },
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {

  double volumeListenerValue = 0;
  double getVolume = 0;
  double setVolumeValue = 0;

  final FlutterContactPicker contactPicker = FlutterContactPicker();
  String snackBarMessage = "Profile changes saved";

  @override
  void initState() {
    super.initState();

    VolumeController().listener((volume) {
      setState(() => volumeListenerValue = volume);
    });

    VolumeController().getVolume().then((volume) => setVolumeValue = volume);
  }

  @override
  void dispose() {
    VolumeController().removeListener();

    super.dispose();
  }

  @override
  Widget build( BuildContext context ) {
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
              child: Row( // choose to send medical information
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text( "Send medical information" ),
                  Switch(
                    value: medicalInfo,
                    onChanged: (value) {
                      setState(() {
                        medicalInfo = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Center(
              child: DropdownMenu( // selected blood type
                label: Text( medicalInfo ? "Select blood type" : "Disabled" ),
                enabled: medicalInfo,
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
                        if( value == false ) {
                          proximityDistance = 5.0;
                        }
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
                divisions: 18,
                value: locationSignal ? proximityDistance : 1.0,
                onChanged: (value) {
                  if( locationSignal ) {
                    setState(() {
                      proximityDistance = value;
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
                        if( value == false ) {
                          emergencyContact = "";
                        }
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
                        VolumeController().getVolume().then((volume) => setVolumeValue = volume);
                      });
                    },
                  ),
                ],
              ),
            ),
            Center( child: Text( soundAlarm ? "Sound volume: ${volumeListenerValue == 0 ? "Muted" : "${(volumeListenerValue * 100).ceil()}%" }" : "Sound alarm disabled" ) ),
            Center(
              child: Slider( // proximity distance in miles
                min: 0,
                max: 1,
                value: soundAlarm ? volumeListenerValue : 0,
                onChanged: (value) {
                  if( soundAlarm ) {
                    setState(() {
                      setVolumeValue = value;
                      VolumeController().setVolume(setVolumeValue);
                    });
                  }
                },
              ),
            ),
            Center(
              child: Row( // text message alert
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text( "Blink flashlight" ),
                  Switch(
                    value: blinkFlashlight,
                    onChanged: (value) {
                      setState(() {
                        blinkFlashlight = value;
                      });
                      if( value == false ) {
                        blinkSpeed = 250;
                      }
                    },
                  ),
                ],
              ),
            ),
            Center( child: Text( blinkFlashlight ? "Blink speed: ${ blinkSpeed == 1000 ? "1 second" : "${blinkSpeed.truncate()} milliseconds" }" : "Blink flashlight disabled" ) ),
            Center(
              child: Slider( // proximity distance in miles
                min: 100,
                max: 1000,
                divisions: 18,
                value: blinkFlashlight ? blinkSpeed.toDouble() : 100.0,
                onChanged: (value) {
                  if( blinkFlashlight ) {
                    setState(() {
                      blinkSpeed = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (updatedIndex) {
          snackBarMessage = updatedIndex == 0 ? "Profile changes saved!" : "Profile changes discarded";

          if( updatedIndex == 0 ) {
            setFinalVariables();
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
  }
}