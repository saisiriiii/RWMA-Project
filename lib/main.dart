import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:polymaker/core/models/trackingmode.dart';
import 'package:polymaker/polymaker.dart' as polymaker;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MapStam(),
    );
  }
}

class MapStam extends StatefulWidget {
  const MapStam({Key? key}) : super(key: key);

  @override
  State<MapStam> createState() => _MapStamState();
}

class _MapStamState extends State<MapStam> {
  Completer<GoogleMapController> _controller = Completer();
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];
  List<LatLng>? locationList; //เพิ่มตอนทำ Maker ล่าสุด ++
  void getLocation() async {
    //เพิ่มตอนทำ Maker ล่าสุด ++
    var result = await polymaker.getLocation(
      context,
      trackingMode: TrackingMode.PLANAR,
      enableDragMarker: true,
    );
    if (result != null) {
      setState(() {
        locationList = result;
      });
    }
  }

  double lat_mylocation = 19.2049654; //ประกาศตัวแปร ตำแหน่งของเรา
  double lng_mylocation = 99.8749145; //ประกาศตัวแปร ตำแหน่งของเรา
  double lat_target = 19.0284482; //ประกาศตัวแปร ตำแหน่งลูกค้า
  double lng_target = 99.9009381; //ประกาศตัวแปร ตำแหน่งลูกค้า

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(19.2049654, 99.8749145), //เป้าหมายเริ่มต้นและคงที่
    zoom: 14.4746,
  );
  Map<PolylineId, Polyline> polylines = {};
  String googleAPiKey =
      "AIzaSyBMVusdsQp7CGB80KRMXqEW-pLWSLm_HLI"; //google maps api key
  Map<MarkerId, Marker> markers = {}; //หมุด

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.red, points: polylineCoordinates);
    polylines[id] = polyline;
    setState(() {});
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
        Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey,
        PointLatLng(lat_mylocation, lng_mylocation),
        PointLatLng(lat_target, lng_target),
        travelMode: TravelMode.driving,
        wayPoints: [PolylineWayPoint(location: "")]);
    print("เชื่อมกับ Goofle Maps ได้แล้ว จริงๆนะ");
    print(result.errorMessage);
    if (result.points.isNotEmpty) {
      print("เชื่อมกับ Goofle Maps ได้แล้ว");
      print(result.points); //ตรวจสอบพิกัด ออกไหม
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
      print(polylineCoordinates);
    }
    _addPolyLine();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    locationList = []; //เพิ่มตอนทำ Maker ล่าสุด ++

    //หมุดต้นทาง
    _addMarker(
        LatLng(19.2049654, 99.8749145),
        "ต้นทาง", //สีแดง
        BitmapDescriptor.defaultMarker);
    //หมุดปลายทาง
    _addMarker(
        LatLng(19.0284482, 99.9009381),
        "ปลายทาง", //สีเขียว
        BitmapDescriptor.defaultMarkerWithHue(90));
    _getPolyline(); //เรียกใช้แล้ว ดึงข้อมูลเส้นทางใน google maps
  }

  @override
  Widget build(BuildContext context) {
    //หน้าจอทั้งหน้า แสดงผลทั้งหมดต้องผ่าน Widget build
    return Scaffold(
        appBar: AppBar(title: Text('62020730')),
        body: Container(
          child: GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: Set<Marker>.of(markers.values),
            polylines: {
              Polyline(
                  polylineId: const PolylineId('overview_polyline'),
                  color: Colors.red,
                  width: 5,
                  points: polylineCoordinates //พิกัดเส้นทาง
                  ),
            },
          ),
        ));
  }
}
