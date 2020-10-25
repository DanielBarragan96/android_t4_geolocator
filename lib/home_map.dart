import 'dart:async';

import 'package:address_search_field/address_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeMap extends StatefulWidget {
  HomeMap({Key key}) : super(key: key);

  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  final Completer<GoogleMapController> _googleMapController =
      Completer<GoogleMapController>();
  Set<Marker> _mapMarkers = Set();
  GoogleMapController _mapController;
  Position _currentPosition;
  Position _defaultPosition = Position(
    longitude: 20.608148,
    latitude: -103.417576,
  );
  bool _currentPositionCamera = true;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getCurrentPosition(),
      builder: (context, result) {
        final Size size = MediaQuery.of(context).size;
        if (result.error == null) {
          if (_currentPosition == null) _currentPosition = _defaultPosition;
          return Scaffold(
            body: SafeArea(
              child: Stack(
                children: <Widget>[
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    markers: _mapMarkers,
                    onLongPress: _setMarker,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentPosition.latitude,
                        _currentPosition.longitude,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20.0,
                    left: size.width * 0.1,
                    right: size.width * 0.1,
                    child: Container(
                      width: size.width * 0.8,
                      color: Colors.white,
                      child: AddressSearchField(
                        country: "Mexico",
                        hintText: "Address",
                        noResultsText: "No results.",
                        onDone: (BuildContext dialogContext,
                            AddressPoint point) async {
                          if (point.found) {
                            _setMarker(LatLng(point.latitude, point.longitude));
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 5,
                    child: IconButton(
                        icon: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 40,
                        ),
                        onPressed: () {
                          _currentPositionCamera = true;
                          _getCurrentPosition();
                        }),
                  ),
                ],
              ),
            ),
          );
        } else {
          Scaffold(
            body: Center(child: Text("Error!")),
          );
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _onMapCreated(controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _setMarker(LatLng coord) async {
    // get address
    String _markerAddress = await _getGeolocationAddress(
      Position(latitude: coord.latitude, longitude: coord.longitude),
    );

    // add marker
    setState(() {
      _mapMarkers.add(
        Marker(
          markerId: MarkerId(coord.toString()),
          position: coord,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: coord.toString(),
            snippet: _markerAddress,
          ),
        ),
      );
    });

    _currentPositionCamera = false;
    // move camera
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: coord,
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<void> _getCurrentPosition() async {
    // get current position
    _currentPosition = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // get address
    String _currentAddress = await _getGeolocationAddress(_currentPosition);

    // add marker
    _mapMarkers.add(
      Marker(
        markerId: MarkerId(_currentPosition.toString()),
        position: LatLng(
          _currentPosition.latitude,
          _currentPosition.longitude,
        ),
        infoWindow: InfoWindow(
          title: _currentPosition.toString(),
          snippet: _currentAddress,
        ),
      ),
    );

    // move camera
    if (_currentPositionCamera) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition.latitude,
              _currentPosition.longitude,
            ),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Future<String> _getGeolocationAddress(Position position) async {
    var places = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places != null && places.isNotEmpty) {
      final Placemark place = places.first;
      return "${place.thoroughfare}, ${place.locality}";
    }
    return "No address availabe";
  }
}
