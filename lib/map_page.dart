import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geolocator/geolocator.dart';

import 'profile_page.dart';

// location handling
late Position currentPosition;

Future<void> initializePosition() async {
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

  await getPosition();
}

Future<void> getPosition() async {
  currentPosition = await Geolocator.getCurrentPosition();
}

// currenty hardcoded, nearby users will be a feature in the near future
Set<Marker> nearbyUsers = {
  // Marker(
  //   markerId: const MarkerId( "Nearby user 1 (online and safe)" ),
  //   icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueGreen ),
  //   position: LatLng( currentPosition.latitude + 0.01, currentPosition.longitude + 0.01 ),
  // ),
  // Marker(
  //   markerId: const MarkerId( "Nearby user 2 (in danger)" ),
  //   icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueRed ),
  //   position: LatLng( currentPosition.latitude - 0.01, currentPosition.longitude + 0.01 ),
  // ),
  // Marker(
  //   markerId: const MarkerId( "Nearby user 3 (coming to help you)" ),
  //   icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueBlue ),
  //   position: LatLng( currentPosition.latitude + 0.01, currentPosition.longitude - 0.01 ),
  // ),
  // Marker(
  //   markerId: const MarkerId( "Nearby user 4 (offline)" ),
  //   icon: BitmapDescriptor.defaultMarkerWithHue( BitmapDescriptor.hueViolet ),
  //   position: LatLng( currentPosition.latitude - 0.01, currentPosition.longitude - 0.01 ),
  // ),
};

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {

  late GoogleMapController mapController;
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
  bool includeMap = true;

  final positionStream = Geolocator.getPositionStream();

  void resetMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) {
        setState(() => includeMap = true);
      }
    });
    if(mounted) {
      setState(() => includeMap = false);
    }
  }

  @override
  initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resetMap();
    }
  }

  @override
  Widget build( BuildContext context ) {
    return StreamBuilder<Position>(
      stream: positionStream,
      builder: (context, snapshot) {

        double radiusInMiles = userData["proximityDistance"] ??= defaultData["proximityDistance"];
        bool enableSignal = userData["alertNearbyUsers"] ??= defaultData["alertNearbyUsers"];

        positionStream.listen( (event) => currentPosition = event );
      
        return Scaffold(
          body: snapshot.hasData && includeMap ? GoogleMap(
            onMapCreated: onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng( currentPosition.latitude, currentPosition.longitude ),
              zoom: 12,
            ),
            myLocationEnabled: true,
            markers: nearbyUsers,
            circles: enableSignal ? {
              Circle( // map radius of nearby area for users to come help
                circleId: const CircleId( "Nearby area" ),
                fillColor: Colors.red.withOpacity(0.5),
                center: LatLng( currentPosition.latitude, currentPosition.longitude ),
                radius: radiusInMiles * 1609.34, // converts miles to meters
                strokeWidth: 1,
              ),
            } : {},
          ) :
          const Center( // loading screen
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>( Colors.red ),
                ),
                Text( "Loading nearby users" ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async => await getPosition(),
            child: const Icon( Icons.refresh ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}