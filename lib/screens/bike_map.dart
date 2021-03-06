import 'package:bikekollective/screens/accident_waiver.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/bike_view.dart';
import '../models/bike.dart';
import '../models/app_user.dart';
import '../widgets/navdrawer.dart';
import '../services/get_location.dart';
import '../screens/sign_in.dart';

class BikeMap extends StatefulWidget {
  static const routeName = '/';
  @override
  _BikeMapState createState() => _BikeMapState();
}

class _BikeMapState extends State<BikeMap> {
  LocationData currentLocation;
  var latitude = 0.0;
  var longitude = 0.0;

  final Map<String, Marker> _markers = {};
  Future<void> _onMapCreated(GoogleMapController controller) async {
    // get the current location from location services
    currentLocation = await getLocation();

    // load the bikes from firestore
    QuerySnapshot bikeSnapshot =
        await FirebaseFirestore.instance.collection('bikes').get();
    var allBikes = bikeSnapshot.docs;
    setState(() {
      // create the markers (for the bikes)
      _markers.clear();
      for (final bike in allBikes) {
        final bikeObj = Bike.fromMap(bike.data(), bike.reference.id);
        final bikeMarker = Marker(
            markerId: MarkerId(bikeObj.bikeDescription),
            position:
                LatLng(bikeObj.location.latitude, bikeObj.location.longitude),
            infoWindow: InfoWindow(
                title: bikeObj.bikeDescription,
                snippet: bikeObj.bikeDescription,
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(BikeView.routeName, arguments: bikeObj);
                }),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                (bikeObj.isCheckedOut) ? BitmapDescriptor.hueRed : 207));
        _markers[bikeObj.bikeDescription] = bikeMarker;
      }

      if (currentLocation != null) {
        latitude = currentLocation.latitude;
        longitude = currentLocation.longitude;
      }
      // move the camera to the current location when it loads
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(latitude, longitude), zoom: 15),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User>();
    final appUsersSnapshots = context.watch<QuerySnapshot>();
    final currUser = context.watch<AppUser>();

    if (firebaseUser != null &&
        appUsersSnapshots != null &&
        appUsersSnapshots.docs != null &&
        appUsersSnapshots.docs.length > 0) {
      currUser.setAuthId = firebaseUser.uid;
      currUser.loadInfo(appUsersSnapshots.docs);
    }

    if (firebaseUser != null) {
      if (currUser.hasSignedWaiver) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Bike Map'),
            backgroundColor: Colors.green[700],
          ),
          drawer: navDrawer(context),
          body: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(0.0, 0.0),
              zoom: 2,
            ),
            markers: _markers.values.toSet(),
          ),
        );
      } else {
        return AccidentWaiver();
      }
    } else {
      return SignIn();
    }
  }
}
