import 'package:flutter/material.dart';

import 'package:instahelp/firebase_options.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:volume_controller/volume_controller.dart';

// Variables and functions related to Firebase
class FirebaseClass {

  late FirebaseFirestore db;
  late User currentUser;

  bool loggedIn = false;
  bool emailVerified = false;

  // initialize Firebase when first running app
  Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // immediately initialize connection to Firestore after Firebase connection made
    db = FirebaseFirestore.instance;
  }

  void loadFromFirestore() {

    // ensures Firestore operations only occur if a user is logged in
    if( !loggedIn ) return;

    // get current user's data
    db.collection( "user_options" ).doc( currentUser.uid ).get().then(
      (doc) {
        if( doc.data() == null ) {
          // newly created users get new document in Firestore with default data
          userData.resetData("all");
          db
            .collection( "user_options" )
            .doc( currentUser.uid )
            .set( userData.dataMap );
        } else {
          // existing users get their data stored in UserData as a map
          userData.dataMap = doc.data() as Map<String, dynamic>;
          userData.setTempVariables();
        }
      },
    );
  }

  // saves user data in Firestore when users presses save button in edit profile page
  void saveToFirestore() {
    userData.setDataMap();
    firebaseClass.db
      .collection( "user_options" )
      .doc( firebaseClass.currentUser.uid )
      .set( userData.dataMap );
  }
}

// User options from Firestore
class UserData {

  // user data in map structure for reading and writing to Firestore
  Map<String, dynamic> dataMap = {
    "medicalInfo" : true,
    "bloodType" : "O+",
    "alertNearbyUsers" : true,
    "proximityDistance" : 5.0,
    "textMessageAlert" : true,
    "emergencyContacts" : [],
    "soundAlarm" : true,
    "blinkFlashlight" : true,
    "blinkSpeed" : 250.0,
  };

  // whether to send user's medical info when distress detected
  bool _medicalInfo = true;
  void setMedicalInfo( bool value ) => _medicalInfo = value;
  bool getMedicalInfo() => _medicalInfo;

  // blood type as part of user's medical info
  String _bloodType = "O+";
  void setBloodType( String value ) => _bloodType = value;
  String getBloodType() => _bloodType;

  // whether to alert InstaHelp users close by to user
  bool _alertNearbyUsers = true;
  void setAlertNearbyUsers( bool value ) => _alertNearbyUsers = value;
  bool getAlertNearbyUsers() => _alertNearbyUsers;

  // distance radius from user to alert nearby users in
  double _proximityDistance = 5.0;
  void setProximityDistance( double value ) => _proximityDistance = value;
  double getProximityDistance() => _proximityDistance;

  // whether to send a text message to designated emergency contacts
  bool _textMessageAlert = true;
  void setTextMessageAlert( bool value ) => _textMessageAlert = value;
  bool getTextMessageAlert() => _textMessageAlert;

  // emergency contacts to send text messages to when distress detected
  List<dynamic> _emergencyContacts = [];
  void setEmergencyContacts( List<dynamic> value ) => _emergencyContacts = value;
  List<dynamic> getEmergencyContacts() => _emergencyContacts;

  // whether to play a loud siren from user's phone when distress detected
  bool _soundAlarm = true;
  void setSoundAlarm( bool value ) => _soundAlarm = value;
  bool getSoundAlarm() => _soundAlarm;

  // whether to blink the user's phone flashlight when distress detected
  bool _blinkFlashlight = true;
  void setBlinkFlashlight( bool value ) => _blinkFlashlight = value;
  bool getBlinkFlashlight() => _blinkFlashlight;

  // how fast to blink the flashlight
  double _blinkSpeed = 250.0;
  void setBlinkSpeed( double value ) => _blinkSpeed = value;
  double getBlinkSpeed() => _blinkSpeed;

  void setTempVariables() {
    _medicalInfo = dataMap["medicalInfo"];
    _bloodType = dataMap["bloodType"];
    _alertNearbyUsers = dataMap["alertNearbyUsers"];
    _proximityDistance = dataMap["proximityDistance"];
    _textMessageAlert = dataMap["textMessageAlert"];
    _emergencyContacts = dataMap["emergencyContacts"];
    _soundAlarm = dataMap["soundAlarm"];
    _blinkFlashlight = dataMap["blinkFlashlight"];
    _blinkSpeed = dataMap["blinkSpeed"];
  }

  void setDataMap() {
    dataMap["medicalInfo"] = _medicalInfo;
    dataMap["bloodType"] = _bloodType;
    dataMap["alertNearbyUsers"] = _alertNearbyUsers;
    dataMap["proximityDistance"] = _proximityDistance;
    dataMap["textMessageAlert"] = _textMessageAlert;
    dataMap["emergencyContacts"] = _emergencyContacts;
    dataMap["soundAlarm"] = _soundAlarm;
    dataMap["blinkFlashlight"] = _blinkFlashlight;
    dataMap["blinkSpeed"] = _blinkSpeed;
  }

  // default values for newly created users
  void resetData(String field) {
    switch( field ) {
      case "medicalInfo":
        _medicalInfo = true;
      case "bloodType":
        _bloodType = "O+";
      case "alertNearbyUsers":
        _alertNearbyUsers = true;
      case "proximityDistance":
        _proximityDistance = 5.0;
      case "textMessageAlert":
        _textMessageAlert = true;
      case "emergencyContacts":
        _emergencyContacts = [];
      case "soundAlarm":
        _soundAlarm = true;
      case "blinkFlashlight":
        _blinkFlashlight = true;
      case "blinkSpeed":
        _blinkSpeed = 250.0;
      case "all":
        _medicalInfo = true;
        _bloodType = "O+";
        _alertNearbyUsers = true;
        _proximityDistance = 5.0;
        _textMessageAlert = true;
        _emergencyContacts = [];
        _soundAlarm = true;
        _blinkFlashlight = true;
        _blinkSpeed = 250.0;
    }
  }

}

FirebaseClass firebaseClass = FirebaseClass();
UserData userData = UserData();

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final _userDetection = FirebaseAuth.instance.authStateChanges();

  @override
  Widget build( BuildContext context ) {
    return StreamBuilder<User?>(
      stream: _userDetection,
      builder: (context, snapshot) {

        // get current user
        _userDetection.listen((User? user) {
          if( user == null ) {
            firebaseClass.loggedIn = false;
            firebaseClass.emailVerified = false;
          } else {
            firebaseClass.loggedIn = true;
            firebaseClass.currentUser = user;
            firebaseClass.emailVerified = firebaseClass.currentUser.emailVerified;
          }
          firebaseClass.loadFromFirestore();
        });
      
        return firebaseClass.loggedIn ? ProfileScreen( // profile screen to show when user already logged in
          showUnlinkConfirmationDialog: true,
          showDeleteConfirmationDialog: true,
          // showMFATile: true, // temporarily disabled to prevent firebase premium charges
          actions: [
            SignedOutAction((context) {
              // reset user data to default upon sign out
              userData.resetData("all");
              userData.setDataMap();
            }),
            AccountDeletedAction( (context, user) async {
              // delete user options from firebase when account deleted
              await firebaseClass.db.collection("user_options").doc(user.uid).delete();
            }),
          ],
          children: [
            ElevatedButton( // edit profile button doubles as email verification button
              onPressed: () async {

                if( firebaseClass.emailVerified ) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        userData.setTempVariables();
                        return const EditProfilePage();
                      },
                    ),
                  );
                } else {
                  await firebaseClass.currentUser.reload();
                  firebaseClass.currentUser = FirebaseAuth.instance.currentUser as User;
                  setState( () => firebaseClass.emailVerified = firebaseClass.currentUser.emailVerified );

                  if(!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        firebaseClass.emailVerified ?
                        "Email successfully verified!" :
                        "Email still not yet verified"
                      ),
                      action: SnackBarAction(
                        label: "OK",
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              },
              child: Center(
                child: Text(
                  firebaseClass.emailVerified ?
                  "Edit profile" :
                  "Check email verification status"
                ),
              ),
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
      onPopInvoked: (didPop) => firebaseClass.loadFromFirestore(),
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
                  value: userData.getMedicalInfo(),
                  onChanged: (value) {
                    setState( () => userData.setMedicalInfo(value) );
                  },
                ),
              ),
              Center(
                child: DropdownMenu( // selected blood type
                  enabled: userData.getMedicalInfo(),
                  label: Text( userData.getMedicalInfo() ? "Select blood type" : "Disabled" ),
                  initialSelection: userData.getMedicalInfo() ? userData.getBloodType() : "Disabled",
                  onSelected: (value) => userData.setBloodType(value as String),
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
                  value: userData.getAlertNearbyUsers(),
                  onChanged: (value) {
                    setState(() {
                      userData.setAlertNearbyUsers(value);
                      if( value == false ) {
                        userData.resetData("proximityDistance");
                      }
                    });
                  },
                ),
              ),
              Center(
                child: Text(
                  userData.getAlertNearbyUsers() ?
                  "Proximity distance: "
                  "${userData.getProximityDistance()} "
                  "${userData.getProximityDistance() == 1 ? "mile" : "miles"}" :
                  "Location signal disabled"
                ),
              ),
              Center(
                child: Slider( // proximity distance in miles
                  min: 1.0,
                  max: 10.0,
                  divisions: 18,
                  value: userData.getAlertNearbyUsers() ? userData.getProximityDistance() : 1.0,
                  onChanged: (value) {
                    if( userData.getAlertNearbyUsers() ) {
                      setState( () => userData.setProximityDistance(value) );
                    }
                  },
                  thumbColor: userData.getAlertNearbyUsers() ? Colors.red : Colors.black,
                ),
              ),
              ListTile( // send text message to designated emergency contacts
                title: const Text( "Text message alert" ),
                trailing: Switch(
                  value: userData.getTextMessageAlert(),
                  onChanged: (value) {
                    setState(() {
                      userData.setTextMessageAlert(value);
                      if( value == false ) {
                        userData.resetData("emergencyContacts");
                      }
                    });
                  },
                ),
              ),
              Center( // button to add emergency contacts
                child: ElevatedButton(
                  onPressed: () async {
                    if( userData.getTextMessageAlert() && userData.getEmergencyContacts().length < _maxEmergencyContacts ) {
                      Contact? value = await _contactPicker.selectContact();                                                            
                      if( value != null && !userData.getEmergencyContacts().contains(value.toString()) ) {
                        setState( () => userData.getEmergencyContacts().add( value.toString() ) );
                      }
                    }
                  },
                  child: Text(
                    userData.getTextMessageAlert() ?
                    userData.getEmergencyContacts().length == _maxEmergencyContacts ?
                    "Maximum $_maxEmergencyContacts emergency contacts" :
                    "Add new emergency contact" :
                    "Text message alert disabled"
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: userData.getEmergencyContacts().length,
                itemBuilder: (_, int index) {
                  return ListTile(
                    title: Text( userData.getEmergencyContacts()[index] ),
                    trailing: IconButton(
                      icon: const Icon( Icons.delete ),
                      onPressed: () {
                        setState( () => userData.getEmergencyContacts().remove( userData.getEmergencyContacts()[index] ) );
                      },
                    ),
                  );
                },
              ),
              ListTile( // play loud siren
                title: const Text( "Sound alarm" ),
                trailing: Switch(
                  value: userData.getSoundAlarm(),
                  onChanged: (value) {
                    setState(() {
                      userData.setSoundAlarm(value);
                      _volumeController.getVolume().then( (volume) => _setVolumeValue = volume );
                    });
                  },
                ),
              ),
              Center(
                child: Text(
                  userData.getSoundAlarm() ?
                  "Phone volume: ${_volumeListenerValue == 0 ?
                  "Muted" :
                  "${(_volumeListenerValue * 100).round()}%" }" :
                  "Sound alarm disabled"
                ),
              ),
              Center(
                child: Slider( // siren volume
                  min: 0,
                  max: 1,
                  value: userData.getSoundAlarm() ? _volumeListenerValue : 0,
                  onChanged: (value) {
                    if( userData.getSoundAlarm() ) {
                      setState(() {
                        _setVolumeValue = value;
                        _volumeController.setVolume(_setVolumeValue);
                      });
                    }
                  },
                  thumbColor: userData.getSoundAlarm() ? Colors.red : Colors.black,
                ),
              ),
              ListTile( // turn flashlight on and off like a blinker
                title: const Text( "Blink flashlight" ),
                trailing: Switch(
                  value: userData.getBlinkFlashlight(),
                  onChanged: (value) {
                    setState( () => userData.setBlinkFlashlight(value) );
                    if( value == false ) {
                      userData.resetData("blinkSpeed");
                    }
                  },
                ),
              ),
              Center(
                child: Text(
                  userData.getBlinkFlashlight() ?
                  "Blink speed: ${ userData.getBlinkSpeed() == 1000 ?
                  "1 second" :
                  "${userData.getBlinkSpeed().round()} milliseconds" }" :
                  "Blink flashlight disabled"
                ),
              ),
              Center(
                child: Slider( // proximity distance in miles
                  min: 100,
                  max: 1000,
                  divisions: 18,
                  value: userData.getBlinkFlashlight() ? userData.getBlinkSpeed() : 100.0,
                  onChanged: (value) {
                    if( userData.getBlinkFlashlight() ) {
                      setState( () => userData.setBlinkSpeed(value) );
                    }
                  },
                  thumbColor: userData.getBlinkFlashlight() ? Colors.red : Colors.black,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (updatedIndex) {
      
            if( updatedIndex == 0 ) {
              firebaseClass.saveToFirestore();
            }
      
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text( updatedIndex == 0 ? "Profile changes saved!" : "Profile changes discarded" ),
                action: SnackBarAction(
                  label: "OK",
                  onPressed: () {},
                ),
              ),
            );
      
            firebaseClass.loadFromFirestore();

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