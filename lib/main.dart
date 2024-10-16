import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/FG/FG_deliverylist.dart';
import 'screens/capture_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  //SharedPreferences prefs = await SharedPreferences.getInstance();
  //String userId = prefs.getString('userId') ?? '';

  //await FlutterDownloader.initialize(
  //    debug: true,
  //    // optional: set to false to disable printing logs to console (default: true)
  //    ignoreSsl: true
  //    // option: set to false to disable working with http links (default: false)
  //    );

  List<CameraDescription> cameras = await availableCameras();

  final initialRoute = await _getInitialRoute();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Check and request the phone permission
  PermissionStatus status = await Permission.phone.status;
  PermissionStatus storage = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.phone.request();
  }
  if (!storage.isGranted){
    storage = await Permission.storage.request();
  }

/*   // Tempatkan FlutterDownloader.registerCallback di sini
  FlutterDownloader.registerCallback((id, status, progress) {
    if (status == DownloadTaskStatus.complete) {
      // File APK akan otomatis dibuka setelah unduhan selesai
    }
  }); */

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeApps(),
        '/delivery': (context) => const DeliveryList(type: '', deliv_type: ''),
        '/capture': (context) => CaptureScreen(
            camera: cameras.first,
            deliv_id: '',
            containersNo: '',
            type: ''
        ),
      },
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFED1D24),
        ),
      ),
      themeMode: ThemeMode.light,
    ),
  );
}

// Fungsi untuk mendapatkan rute awal berdasarkan status login
Future<String> _getInitialRoute() async {
  // Lakukan pemeriksaan status login di SharedPreferences atau mekanisme penyimpanan data lainnya
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  if (isLoggedIn) {
    return '/home';
    //return '/capture';
  } else {
    return '/login';
  }
}
