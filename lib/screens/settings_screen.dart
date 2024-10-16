import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'FG/FG_draft.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  String userName = '';
  String userNik = '';
  String userSAP = '';
  String costCenter = '';
  String level = '';
  String role = '';


  Future<void> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? 'Unknown User';
      userNik = prefs.getString('nik') ?? 'Unknown NIK';
      userSAP = prefs.getString('sap') ?? 'Unknown SAP';
      level = prefs.getString('level') ?? 'Unknown Level';
      costCenter = prefs.getString('costcenter') ?? 'Unknown Cost_Center';
      role = prefs.getString('role') ?? 'Unknown Role';
    });
  }

  Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? 'Unknown User';
  }

  Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  String deviceInfo = 'Device information';

  Future<String> getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return '''
        - Model: ${androidInfo.model}
        - Version: ${androidInfo.version.release}
        - Manufacturer: ${androidInfo.manufacturer}
        ''';
    } else {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return '''
        iOS Device Info:
        - Model: ${iosInfo.utsname.machine}
        - System Version: ${iosInfo.systemVersion}
        ''';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
          color: Colors.white, // Set the text color to white
          fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FutureBuilder<String>(
            future: getUserId(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                // String userId = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 90.0, // Set the desired width
                            height: 90.0, // Set the desired height
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFED1D24), // Choose your desired border color
                                width: 3.0, // Set the border width as needed
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30.0,
                              backgroundColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(5.0), // Set your desired padding
                                child: Image.asset('assets/images/worker.png'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Card(
                                  color: Colors.redAccent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child:  Text(
                                      'User $userNik',
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                              ),
                              Card(
                                color: Colors.lightGreen,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child:  Text(
                                   'Hi, $userName',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              )
                            ],
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Draft'),
            subtitle: const Text('View Images that failed to send'),
            onTap: () {
              if (role.contains('Finished Goods')){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DraftListPage()
                  ),
                );
              }
              else if (role.contains('Information Technology') || role == 'IT'){
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      title: Text(
                        'Pilih Draft',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      content: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DraftListPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red.shade400, // Text color
                            ),
                            child: const Text('Finished Goods'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              else{

              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: const Text('Device'),
            subtitle: const Text('View Device Information'),
            onTap: () {
              // Show the device information dialog
              getDeviceInfo().then((info) {
                setState(() {
                  deviceInfo = info;
                });

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Device Information'),
                      content: Text(deviceInfo),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.mobile_friendly),
            title: const Text('App Version'),
            subtitle: FutureBuilder<String>(
              future: getAppVersion(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Text('V.${snapshot.data}');
                }
              },
            ),
            onTap: () {
              // Handle tap if needed
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            subtitle: const Text('Log out from your account'),
            onTap: () async {
              // Menampilkan dialog konfirmasi
              bool confirmLogout = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text(
                        'Are you sure you want to log out of your account?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Batal'),
                        onPressed: () {
                          Navigator.of(context).pop(false); // Batalkan logout
                        },
                      ),
                      TextButton(
                        child: const Text('Keluar'),
                        onPressed: () {
                          Navigator.of(context).pop(true); // Konfirmasi logout
                        },
                      ),
                    ],
                  );
                },
              );

              // Jika pengguna mengonfirmasi logout, maka hapus data dari SharedPreferences
              if (confirmLogout == true) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('userId');
                await prefs.remove('isLoggedIn');
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                  // Hapus semua halaman sebelumnya
                );
              }
            },
          ),
          const Spacer(), // Menggunakan Spacer untuk mengisi ruang di atas logo
          const Divider(height: 1, color: Colors.grey),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: Image.asset('assets/images/tjiwi.png', width: 100),
                  ),
                ],
              ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
