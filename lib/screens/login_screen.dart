import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:device_information/device_information.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _nikSapController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String imeiNo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _getDeviceInformation();
  }

  // API LOGIN
  Future<Map<String, dynamic>> _apiLogin(
      String username, String password, String manufacturer) async {
    final Uri url = Uri.parse('https://tkapp01.tjiwikimia.co.id/APP.Credential/api/UserLogin');
    var request = http.MultipartRequest('POST', url);

    request.fields['UserId'] = username;
    request.fields['Password'] = password;
    request.fields['Apps'] = 'Camera_App';
    request.fields['DeviceId'] = manufacturer;

    if (kDebugMode) {
      print("Request : $request");
      print("Device ID : $manufacturer");
    }

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("Status Code : 200");
        }
        final String responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> responseData = json.decode(responseBody);

        if (responseData.containsKey('success') &&
            responseData['success'] == true) {
          return responseData['data'];
        } else {
          throw Exception('Login failed with response message : ${responseData['message']}');
        }
      } else {
        if (kDebugMode) {
          print("No Response");
        }
        throw Exception('Login failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print("No Response with Exception");
      }
      throw Exception('$e');
    }
  }
  // End API LOGIN

  // GET IMEI
  Future<void> _getDeviceInformation() async {
    try {
      imeiNo = await DeviceInformation.deviceIMEINumber;
    } on PlatformException {
      imeiNo = 'Permission not access';
    }

    setState(() {});
  }
  // END IMEI

  Future<void> _handleLoginButtonPress() async {
    try {
      String username = _nikSapController.text;
      String password = _passwordController.text;

      // Dapatkan Android Device ID (IMEI)
      String manufacturer = imeiNo;
      if (kDebugMode) {
        print(manufacturer);
      }

      showDialog(
        context: context, 
        builder: (context){
          return const Center(child: CircularProgressIndicator()); 
        },
      );

      // Lakukan login ke API
      Map<String, dynamic> userData = await _apiLogin(username, password, manufacturer);

      // Periksa apakah login berhasil berdasarkan respons API
      if (userData.isNotEmpty) {
        // Simpan status login ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('DeviceId', manufacturer);
        await prefs.setString('userId', username);
        await prefs.setString('name', userData['name']);
        await prefs.setString('sap', userData['sap']);
        await prefs.setString('nik', userData['nik']);
        await prefs.setString('level', userData['level']);
        await prefs.setString('costcenter', userData['costcenter']);
        await prefs.setString('role', userData['role']);

        // Hapus semua halaman kecuali halaman login dari tumpukan navigasi
        Navigator.of(context).popUntil((route) => route.isFirst);
        //Navigator.of(context).pop();
        // Navigasi ke halaman berikutnya setelah login berhasil
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pop();
        // Tampilkan Snackbar jika login gagal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please check your credentials.'),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login failed: ${e.toString()}');
      }
      // Tampilkan Snackbar jika terjadi kesalahan saat login
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFFED1D24)),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            // Sesuaikan dengan jarak atas yang diinginkan
            left: 0,
            right: 0,
            // bottom: 10,
            child: Image.asset(
              'assets/images/camera.png',
              width: 100,
              height: 100,
            ),
          ),
          CustomPaint(
            painter: CurvedBackgroundPainter(),
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // NIK SAP
                  TextField(
                    controller: _nikSapController,
                    decoration: InputDecoration(
                      hintText: 'Username CUIS / Global ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 20.0),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 20.0),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        child: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                  ),
                  const SizedBox(height: 20),

                  // Button
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // handle login
                          _handleLoginButtonPress();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFED1D24),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(width: 2, color: Colors.white),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            'Login Camera Automation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFED1D24)
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(0, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.35,
          size.width * 0.5, size.height * 0.25)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.15, size.width, size.height * 0.25)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
