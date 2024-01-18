import 'package:flutter/material.dart';

import 'package:instahelp/firebase_options.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:volume_controller/volume_controller.dart';

bool loggedIn = false;
bool emailVerified = false;

Map<String, dynamic> userData = defaultData;

// default values for newly created users
final defaultData = {
  "medicalInfo": medicalInfo = true,
  "bloodType": bloodType = "O+",
  "alertNearbyUsers" : alertNearbyUsers = true,
  "proximityDistance" : proximityDistance = 5,
  "textMessageAlert" : textMessageAlert = true,
  "emergencyContact" : emergencyContact = "",
  "soundAlarm" : soundAlarm = true,
  "blinkFlashlight" : blinkFlashlight = true,
  "blinkSpeed" : blinkSpeed = 250,
};

late bool medicalInfo;
late String bloodType;
late bool alertNearbyUsers;
late double proximityDistance;
late bool textMessageAlert;
late String emergencyContact;
late bool soundAlarm;
late bool blinkFlashlight;
late double blinkSpeed;

late User currentUser;
late FirebaseFirestore db;

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// update database
void updateFirestore() {
  db = FirebaseFirestore.instance;

  // get current user's data
  final docRef = db.collection( "user_options" ).doc( currentUser.uid );
  docRef.get().then(
    (DocumentSnapshot doc) {
      if( doc.data() == null ) { // newly created users get new document in firestore with default data
        userData = defaultData;
        db
          .collection( "user_options" )
          .doc( currentUser.uid )
          .set( userData );
      } else {
        userData = doc.data() as Map<String, dynamic>;
      }
    },
  );
}

void setTempVariables() {
  medicalInfo = userData["medicalInfo"];
  bloodType = userData["bloodType"];
  alertNearbyUsers = userData["alertNearbyUsers"];
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
  userData["alertNearbyUsers"] = alertNearbyUsers;
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

  final userDetection = FirebaseAuth.instance.authStateChanges();

  @override
  Widget build( BuildContext context ) {
    return StreamBuilder<User?>(
      stream: userDetection,
      builder: (context, snapshot) {

        // get current user
        userDetection.listen((User? user) {
          if( user == null ) {
            loggedIn = false;
            userData = defaultData;
            emailVerified = false;
          } else {
            loggedIn = true;
            currentUser = user;
            emailVerified = currentUser.emailVerified;
            updateFirestore();
          }
        });
      
        return loggedIn ? ProfileScreen( // profile screen to show when user already logged in
          showUnlinkConfirmationDialog: true,
          showDeleteConfirmationDialog: true,
          // showMFATile: true, // temporarily disabled to prevent firebase premium charges
          actions: [
            AccountDeletedAction( (context, user) async {
              // delete user options from firebase when account deleted
              await db.collection("user_options").doc(currentUser.uid).delete();
            }),
            EmailVerifiedAction(() {
              setState( () => emailVerified = true );
            }),
          ],
          children: [
            ElevatedButton( // edit profile button
              onPressed: () {
                if(emailVerified) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        setTempVariables();
                        return const EditProfilePage();
                      },
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text( "Please verify email to edit profile" ),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: "OK",
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              },
              child: Center( child: Text( emailVerified ? "Edit profile" : "Please verify email to edit profile" ), ),
            ),
          ],
        ) :
        SignInScreen( // sign in screen to show when no one logged in
          providers: [
            EmailAuthProvider(),
            GoogleProvider( clientId: "" ),
          ],
          showPasswordVisibilityToggle: true,
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

  final contactPicker = FlutterContactPicker();
  final volumeController = VolumeController();

  late String snackBarMessage;

  @override
  void initState() {
    super.initState();

    volumeController.listener((volume) {
      setState( () => volumeListenerValue = volume );
    });

    volumeController.getVolume().then( (volume) => setVolumeValue = volume );
  }

  @override
  void dispose() {
    volumeController.removeListener();

    super.dispose();
  }

  @override
  Widget build( BuildContext context ) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text( "Edit profile" ),
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
                      setState( () => medicalInfo = value );
                    },
                  ),
                ],
              ),
            ),
            Center(
              child: DropdownMenu( // selected blood type
                label: Text( medicalInfo ? "Select blood type" : "Disabled" ),
                initialSelection: medicalInfo ? bloodType : "Disabled",
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
                  DropdownMenuEntry(
                    value: "Disabled",
                    label: "Disabled",
                    enabled: false,
                  ),
                ],
              ),
            ),
            Center(
              child: Row( // alert nearby users
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text( "Alert nearby users (coming soon!)" ),
                  Switch(
                    value: alertNearbyUsers,
                    onChanged: (value) {
                      setState(() {
                        alertNearbyUsers = value;
                        if( value == false ) {
                          proximityDistance = 5.0;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            Center( child: Text( alertNearbyUsers ? "Proximity distance: $proximityDistance ${proximityDistance == 1 ? "mile" : "miles"}" : "Location signal disabled" ), ),
            Center(
              child: Slider( // proximity distance in miles
                min: 1.0,
                max: 10.0,
                divisions: 18,
                value: alertNearbyUsers ? proximityDistance : 1.0,
                onChanged: (value) {
                  if( alertNearbyUsers ) {
                    setState( () => proximityDistance = value );
                  }
                },
                thumbColor: alertNearbyUsers ? Colors.red : Colors.black,
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
            const Center( child: Text( "Designated emergency contact:" ), ),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if( textMessageAlert) {
                    Contact? value = await contactPicker.selectContact();
                    setState( () => emergencyContact = value == null ? "" : value.toString() );
                  }
                },
                child: Text( textMessageAlert ? emergencyContact == "" ? "No emergency contact selected" : emergencyContact : "Text message alert disabled" ),
              ),
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
                        volumeController.getVolume().then( (volume) => setVolumeValue = volume );
                      });
                    },
                  ),
                ],
              ),
            ),
            Center(child: Text( soundAlarm ? "Phone volume: ${volumeListenerValue == 0 ? "Muted" : "${(volumeListenerValue * 100).round()}%" }" : "Sound alarm disabled" ), ),
            Center(
              child: Slider( // siren volume
                min: 0,
                max: 1,
                value: soundAlarm ? volumeListenerValue : 0,
                onChanged: (value) {
                  if( soundAlarm ) {
                    setState(() {
                      setVolumeValue = value;
                      volumeController.setVolume(setVolumeValue);
                    });
                  }
                },
                thumbColor: soundAlarm ? Colors.red : Colors.black,
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
                      setState( () => blinkFlashlight = value );
                      if( value == false ) {
                        blinkSpeed = 250;
                      }
                    },
                  ),
                ],
              ),
            ),
            Center(child: Text( blinkFlashlight ? "Blink speed: ${ blinkSpeed == 1000 ? "1 second" : "${blinkSpeed.round()} milliseconds" }" : "Blink flashlight disabled" )),
            Center(
              child: Slider( // proximity distance in miles
                min: 100,
                max: 1000,
                divisions: 18,
                value: blinkFlashlight ? blinkSpeed : 100.0,
                onChanged: (value) {
                  if( blinkFlashlight ) {
                    setState(() => blinkSpeed = value );
                  }
                },
                thumbColor: blinkFlashlight ? Colors.red : Colors.black,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (updatedIndex) {
          snackBarMessage = updatedIndex == 0 ? "Profile changes saved!" : "Profile changes discarded";

          if( updatedIndex == 0 ) {
            String.fromCharCodes( emergencyContact.codeUnits.where( (x) => (x ^0x30) <= 9 ) ); // extracts phone number
            setFinalVariables();
            db
              .collection( "user_options" )
              .doc( currentUser.uid )
              .set( userData );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text( snackBarMessage ),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: "OK",
                onPressed: () {},
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
  }
}