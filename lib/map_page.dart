import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geolocator/geolocator.dart';

// location handling
late Position currentPosition;

// add nearby users to markers set later
Set<Marker> nearbyUsers = {
  Marker(
    markerId: const MarkerId( "Nearby user" ),
    icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueRed ),
    position: LatLng( currentPosition.latitude + 0.1, currentPosition.longitude + 0.1 ),
  ),
  Marker(
    markerId: const MarkerId( "Nearby user" ),
    icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueRed ),
    position: LatLng( currentPosition.latitude - 0.1, currentPosition.longitude + 0.1 ),
  ),
  Marker(
    markerId: const MarkerId( "Nearby user" ),
    icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueRed ),
    position: LatLng( currentPosition.latitude + 0.1, currentPosition.longitude - 0.1 ),
  ),
  Marker(
    markerId: const MarkerId( "Nearby user" ),
    icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueRed ),
    position: LatLng( currentPosition.latitude - 0.1, currentPosition.longitude - 0.1 ),
  ),
};

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

LatLng? target;

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

        positionStream.listen((Position? position) {
          if( position != null ) {
            currentPosition = position;
          }
        });

        return Scaffold(
          body: located ? GoogleMap(
            onMapCreated: onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng( currentPosition.latitude, currentPosition.longitude ),
              zoom: 10,
            ),
            myLocationEnabled: true,
            markers: nearbyUsers,
          ) : const Center(
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
        );
      }
    );
  }
}