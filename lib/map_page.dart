import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geolocator/geolocator.dart';

import 'profile_page.dart';

// location handling
late Position currentPosition;

void initializePosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if( !serviceEnabled ) {
    return Future.error( "Location services are disabled." );
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if( permission == LocationPermission.denied ) {
    permission = await Geolocator.requestPermission();

    if( permission == LocationPermission.denied ) {
      return Future.error( "Location permissions are denied." );
    }
  }

  if( permission == LocationPermission.deniedForever ) {
    return Future.error( "Location permissions are permanently denied, we cannot request permissions." );
  }

  LocationAccuracyStatus accuracyStatus = await Geolocator.getLocationAccuracy();
  if( accuracyStatus == LocationAccuracyStatus.reduced ) {
    return Future.error( "Location permissions are reduced, we need precise accuracy." );
  }

  getPosition();
}

void getPosition() async {
  currentPosition = await Geolocator.getCurrentPosition();
}

// add nearby users to markers set later
Set<Marker> nearbyUsers = {
  Marker(
    markerId: const MarkerId( "Nearby user 1 (online and safe)" ),
    icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueGreen ),
    position: LatLng( currentPosition.latitude + 0.01, currentPosition.longitude + 0.01 ),
  ),
  Marker(
    markerId: const MarkerId( "Nearby user 2 (in danger)" ),
    icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueRed ),
    position: LatLng( currentPosition.latitude - 0.01, currentPosition.longitude + 0.01 ),
  ),
  Marker(
    markerId: const MarkerId( "Nearby user 3 (coming to help you)" ),
    icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueBlue ),
    position: LatLng( currentPosition.latitude + 0.01, currentPosition.longitude - 0.01 ),
  ),
  Marker(
    markerId: const MarkerId( "Nearby user 4 (offline)" ),
    icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueViolet ),
    position: LatLng( currentPosition.latitude - 0.01, currentPosition.longitude - 0.01 ),
  ),
};

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  late GoogleMapController mapController;
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  bool located = false;
  final positionStream = Geolocator.getPositionStream();

  @override
  Widget build( BuildContext context ) {
    return StreamBuilder<Position>(
      stream: positionStream,
      builder: (context, snapshot) {

        located = snapshot.hasData;
        double? radius = userData["proximityDistance"];
        bool? signal = userData["locationSignal"];
        
        return Scaffold(
          body: located && radius != null && signal != null ? GoogleMap(
            onMapCreated: onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng( currentPosition.latitude, currentPosition.longitude ),
              zoom: 15,
            ),
            myLocationEnabled: true,
            markers: nearbyUsers,
            circles: signal ? {
              Circle( // map radius of nearby area for users to come help
                circleId: const CircleId( "Nearby area" ),
                fillColor: const Color.fromRGBO(255, 0, 0, 0.5),
                center: LatLng( currentPosition.latitude, currentPosition.longitude ),
                radius: radius * 1609.34, // converts meters to miles
                strokeWidth: 1,
              ),
            } : {}
          ) :
          const Center( // loading screen
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                Text( "Loading nearby users" ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              getPosition();
            },
            child: const Icon( Icons.refresh ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}