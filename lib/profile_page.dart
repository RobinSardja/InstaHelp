import 'package:flutter/material.dart';

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

  @override
  Widget build( BuildContext context ) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        loggedIn = snapshot.hasData;
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
                Navigator.push(
                  context,
                  MaterialPageRoute<ProfilePage>(
                    builder: (context) => editProfilePage(),
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

  late String snackBarMessage;

  Widget editProfilePage() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center( child: Text( "Edit profile" ) ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text( "edit profile page" )
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon( Icons.save ),
            label: "Save",
          ),
          BottomNavigationBarItem(
            icon: Icon( Icons.delete ),
            label: "Delete",
          )
        ],
        onTap: (selectedIndex) {
          snackBarMessage = selectedIndex == 0 ? "Profile changes saved!" : "Profile changes deleted";
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
          Navigator.pop(context);
        },
      ),
    );
  }
}