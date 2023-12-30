import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geolocator/geolocator.dart';

// location handling
late Position position;

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

  position = await Geolocator.getCurrentPosition();
}

void getPosition() async {
  position = await Geolocator.getCurrentPosition();
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

  @override
  Widget build( BuildContext context ) {
    return Scaffold(
      body: target == null ? const Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      ) : GoogleMap(
        onMapCreated: onMapCreated,
        initialCameraPosition: CameraPosition(
          target: target as LatLng,
          zoom: 10,
        ),
      ),
    );
  }
}