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
  "emergencyContacts" : emergencyContacts = [],
  "soundAlarm" : soundAlarm = true,
  "blinkFlashlight" : blinkFlashlight = true,
  "blinkSpeed" : blinkSpeed = 250,
};

late bool medicalInfo;
late String bloodType;
late bool alertNearbyUsers;
late double proximityDistance;
late bool textMessageAlert;
late List<dynamic> emergencyContacts;
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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final _userDetection = FirebaseAuth.instance.authStateChanges();

  void _setTempVariables() {
    medicalInfo = userData["medicalInfo"];
    bloodType = userData["bloodType"];
    alertNearbyUsers = userData["alertNearbyUsers"];
    proximityDistance = userData["proximityDistance"];
    textMessageAlert = userData["textMessageAlert"];
    emergencyContacts = userData["emergencyContacts"];
    soundAlarm = userData["soundAlarm"];
    blinkFlashlight = userData["blinkFlashlight"];
    blinkSpeed = userData["blinkSpeed"];
  }

  @override
  Widget build( BuildContext context ) {
    return StreamBuilder<User?>(
      stream: _userDetection,
      builder: (context, snapshot) {

        // get current user
        _userDetection.listen((User? user) {
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
                        _setTempVariables();
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

  double _volumeListenerValue = 0;
  double _setVolumeValue = 0;

  final _contactPicker = FlutterContactPicker();
  final _volumeController = VolumeController();

  final _maxEmergencyContacts = 5;

  void _setFinalVariables() {
    userData["medicalInfo"] = medicalInfo;
    userData["bloodType"] = bloodType;
    userData["alertNearbyUsers"] = alertNearbyUsers;
    userData["proximityDistance"] = proximityDistance;
    userData["textMessageAlert"] = textMessageAlert;
    userData["emergencyContacts"] = emergencyContacts;
    userData["soundAlarm"] = soundAlarm;
    userData["blinkFlashlight"] = blinkFlashlight;
    userData["blinkSpeed"] = blinkSpeed;
  }

  @override
  void initState() {
    super.initState();

    _volumeController.listener((volume) {
      setState( () => _volumeListenerValue = volume );
    });

    _volumeController.getVolume().then( (volume) => _setVolumeValue = volume );
  }

  @override
  void dispose() {
    _volumeController.removeListener();

    super.dispose();
  }

  @override
  Widget build( BuildContext context ) {

    return PopScope(
      onPopInvoked: (didPop) => updateFirestore(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text( "Edit profile" ),
        ),
        body: Center(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile( // choose to send medical information
                title: const Text( "Send medical information" ),
                trailing: Switch(
                  value: medicalInfo,
                  onChanged: (value) {
                    setState( () => medicalInfo = value );
                  },
                ),
              ),
              Center(
                child: DropdownMenu( // selected blood type
                  enabled: medicalInfo,
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
              ListTile( // alert nearby users
                title: const Text( "Alert nearby users (in future!)" ),
                trailing: Switch(
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
              ),
              Center(
                child: Text(
                  alertNearbyUsers ? "Proximity distance: $proximityDistance ${proximityDistance == 1 ? "mile" : "miles"}" : "Location signal disabled"
                ),
              ),
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
              ListTile( // send text message to designated emergency contacts
                title: const Text( "Text message alert" ),
                trailing: Switch(
                  value: textMessageAlert,
                  onChanged: (value) {
                    setState(() {
                      textMessageAlert = value;
                      if( value == false ) {
                        emergencyContacts = [];
                      }
                    });
                  },
                ),
              ),
              Center( // button to add emergency contacts
                child: ElevatedButton(
                  onPressed: () async {
                    if( textMessageAlert && emergencyContacts.length < _maxEmergencyContacts ) {
                      Contact? value = await _contactPicker.selectContact();                                                            
                      if( value != null && !emergencyContacts.contains(value.toString()) ) {
                        setState( () => emergencyContacts.add( value.toString() ) );
                      }
                    }
                  },
                  child: Text(
                    textMessageAlert ? emergencyContacts.length == _maxEmergencyContacts ? "Maximum $_maxEmergencyContacts emergency contacts" : "Add new emergency contact" : "Text message alert disabled"
                  ),
                ),
              ),
              ListView.builder( // TODO: not discarding on back button
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: emergencyContacts.length,
                itemBuilder: (_, int index) {
                  return ListTile(
                    title: Text( emergencyContacts[index] ),
                    trailing: IconButton(
                      icon: const Icon( Icons.delete ),
                      onPressed: () {
                        setState( () => emergencyContacts.remove( emergencyContacts[index] ) );
                      },
                    ),
                  );
                },
              ),
              ListTile( // play loud siren
                title: const Text( "Sound alarm" ),
                trailing: Switch(
                  value: soundAlarm,
                  onChanged: (value) {
                    setState(() {
                      soundAlarm = value;
                      _volumeController.getVolume().then( (volume) => _setVolumeValue = volume );
                    });
                  },
                ),
              ),
              Center(
                child: Text(
                  soundAlarm ? "Phone volume: ${_volumeListenerValue == 0 ? "Muted" : "${(_volumeListenerValue * 100).round()}%" }" : "Sound alarm disabled"
                ),
              ),
              Center(
                child: Slider( // siren volume
                  min: 0,
                  max: 1,
                  value: soundAlarm ? _volumeListenerValue : 0,
                  onChanged: (value) {
                    if( soundAlarm ) {
                      setState(() {
                        _setVolumeValue = value;
                        _volumeController.setVolume(_setVolumeValue);
                      });
                    }
                  },
                  thumbColor: soundAlarm ? Colors.red : Colors.black,
                ),
              ),
              ListTile( // turn flashlight on and off like a blinker
                title: const Text( "Blink flashlight" ),
                trailing: Switch(
                  value: blinkFlashlight,
                  onChanged: (value) {
                    setState( () => blinkFlashlight = value );
                    if( value == false ) {
                      blinkSpeed = 250;
                    }
                  },
                ),
              ),
              Center(
                child: Text(
                  blinkFlashlight ? "Blink speed: ${ blinkSpeed == 1000 ? "1 second" : "${blinkSpeed.round()} milliseconds" }" : "Blink flashlight disabled"
                ),
              ),
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
      
            if( updatedIndex == 0 ) {
              _setFinalVariables();
              db
                .collection( "user_options" )
                .doc( currentUser.uid )
                .set( userData );
            }
      
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text( updatedIndex == 0 ? "Profile changes saved!" : "Profile changes discarded" ),
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
      ),
    );
  }
}