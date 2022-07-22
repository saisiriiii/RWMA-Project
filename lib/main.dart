import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
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
  late List<LatLng>
      locationList; //เพิ่มตอนทำ Marker ล่าสุด ++ *เอาไว้เพิ่ม Marker
  int countIdMarker = 1; // เลขหมุด ตัวนับ ID Marker จะทำให้ ID ไม่ซ้ำกัน
  late LocationData currentLocation; //หาตำแหน่งปัจจุบันของตัวเอง

  List latlog =
      []; //เก็บ Latlog เอาไว้ไปแสดงเป็นเส้น Polyline (จำนวนข้างในเป็นทศนิยม)
  int drawVetor = 1; //นับ Maker เพื่อไปลากเส้น

  //เพิ่มตอนทำ Marker ล่าสุด ++
  void getLocation() async {
    var result = await polymaker.getLocation(
      context,
      trackingMode: TrackingMode.PLANAR,
      enableDragMarker: true,
      autoEditMode: true, //กำหนดให้ใส่หมุดเพิ่มได้เลย แสดงออกมาเลยในหน้า Map2
    );

    if (result != null) {
      setState(() {
        locationList = result;
      });
      // markers
      //     .clear(); // ทำการลบ Marker ทั้งหมดเมื่อมีการกดปุ่มบวกเลือกที่ Marker

      //เอาค่า LatLng ตามลำดับออกมา เริ่มตั้งแต่ 1
      locationList.forEach((locatonMarkerList) {
        //forloop พิกัดไปเรื่อยๆ
        if (countIdMarker == 1) {
          _addMarker(
              LatLng(currentLocation.latitude!.toDouble(),
                  currentLocation.longitude!.toDouble()),
              "0", //สีแดง *ต้นทาง คือ 0
              BitmapDescriptor.defaultMarker);
        }
        _addMarker(
            locatonMarkerList, // จุด Marker ปลายทาง
            "$countIdMarker", // ID ของ Marker
            BitmapDescriptor.defaultMarker);

        print(locatonMarkerList.latitude);
        if (drawVetor == 1) {
          //จุดปัจจุบันของเรา
          latlog.insert(drawVetor - 1, currentLocation.latitude!.toDouble());
          latlog.insert(drawVetor, currentLocation.longitude!.toDouble());
          drawVetor += 1; //เลือกเพิ่ม 1 จุด
          // _getPolyline();
        }
        // print(latlog);

        if (drawVetor >= 2) {
          //ปลายทางแต่ละจุด
          print("drawVetor ${latlog.length}");
          latlog.insert(latlog.length, locatonMarkerList.latitude);
          latlog.insert(latlog.length, locatonMarkerList.longitude);
          setState(() {});
          print(latlog);
          _getPolyline(
              //ส่งพิกัดไปให้ google maps ลากเส้นให้
              lat_mylocation: latlog[latlog.length - 4],
              lng_mylocation: latlog[latlog.length - 3],
              lat_target: latlog[latlog.length - 2],
              lng_target: latlog[latlog.length - 1]);
        }

        countIdMarker += 1;
        drawVetor += 1;
      });
      print("locationList $locationList");
    }
  }

  // เป็นตัวที่ทำให้ map เลื่อนไปยังตำแหน่งปัจจุบัน
  Future _goToMe() async {
    final GoogleMapController controller = await _controller.future;
    currentLocation = await getCurrentLocation();
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(currentLocation.latitude!.toDouble(),
          currentLocation.longitude!.toDouble()),
      zoom: 16,
    )));
  }

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
    Marker marker = Marker(
      markerId: markerId,
      icon: descriptor,
      position: position,
      infoWindow: InfoWindow(title: "$id"),
    );
    markers[markerId] = marker;
  }

  _getPolyline(
      {required double lat_mylocation,
      required double lng_mylocation,
      required double lat_target,
      required double lng_target}) async {
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

  // คือฟังก์ชันที่เอาไว้เรียกตำแหน่งตัวเอง และค่า LatLng ออกมา
  getCurrentLocation() async {
    Location location = Location();
    try {
      return await location.getLocation();
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    locationList = []; //เพิ่มตอนทำ Maker ล่าสุด ++
    _goToMe(); // ตัวที่เมื่อเรียกใช้แล้วจะไป *ตำแหน่งปัจจุบันของผู้ใช้

    // //หมุดต้นทาง
    // _addMarker(
    //     LatLng(19.2049654, 99.8749145),
    //     "ต้นทาง", //สีแดง
    //     BitmapDescriptor.defaultMarker);
    // //หมุดปลายทาง
    // _addMarker(
    //     LatLng(19.0284482, 99.9009381),
    //     "ปลายทาง", //สีเขียว
    //     BitmapDescriptor.defaultMarkerWithHue(90));
    // _getPolyline(); //เรียกใช้แล้ว ดึงข้อมูลเส้นทางใน google maps
  }

  @override
  Widget build(BuildContext context) {
    //หน้าจอทั้งหน้า แสดงผลทั้งหมดต้องผ่าน Widget build
    return Scaffold(
        appBar: AppBar(title: Text('62020730')),
        //ปุ่มไปหน้า Map2
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            getLocation();
          },
          child: Icon(Icons.add),
        ),
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
