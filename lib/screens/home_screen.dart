import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'FG/FG_draft.dart';
import 'FG/FG_type.dart';
import 'capture_screen.dart';
import 'settings_screen.dart';

class HomeApps extends StatefulWidget {
  const HomeApps({super.key});

  @override
  State<HomeApps> createState() => _HomeAppsState();
}

class _HomeAppsState extends State<HomeApps> {
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

      // Call _initializeItems here to ensure role is not null
      _initializeItems();
    });
  }

  Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? 'Unknown User';
  }

  List<GridItem> items = [];

  // Function to launch the URL
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _initializeItems() {
    setState(() {

      if (kDebugMode) {
        print("role : $role");
      }

      if (role.contains('Information Technology') || role == 'IT') {
        items.addAll([
          GridItem(
            title: 'Delivery',
            imageUrl: 'assets/images/truck.png',
            type: 'C',
          ),
          GridItem(
            title: 'Non-Delivery',
            imageUrl: 'assets/images/pickup.png',
            type: 'NC',
          ),
          GridItem(
              title: 'Draft',
              imageUrl: 'assets/images/draft.png',
              type: 'Draft'
          ),
        ]);
      } else if (role.substring(0, 8) == 'Finished'){
        items.addAll([
          GridItem(
            title: 'Delivery',
            imageUrl: 'assets/images/truck.png',
            type: 'C',
          ),
          GridItem(
            title: 'Non-Delivery',
            imageUrl: 'assets/images/pickup.png',
            type: 'NC',
          ),
          GridItem(
              title: 'Draft',
              imageUrl: 'assets/images/draft.png',
              type: 'Draft'
          )
        ]);
      }
      else {
        items.add(
          GridItem(title: '', imageUrl: '', type: '')
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(4),
          child: Card(
            color: Colors.red,
            child: Image.asset('assets/images/minilogo.png'),
          )
        ),
        title: const Text(
          'Camera Automation',
          style: TextStyle(
          color: Colors.white, // Set the text color to white
          fontWeight: FontWeight.bold, // Set the text to bold
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body:  SizedBox(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Pilih Menu ",
                      style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Card(
                        color: Colors.lightBlue,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child:  Text(
                            role,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.white,
                            ),
                          ),
                        )
                    ),
                  ],
                ),
                const Divider(),
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 2.0,
                    mainAxisSpacing: 2.0,
                  ),
                  itemCount: items.length,
                  // Center the grid horizontally
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    return Card(
                        elevation: 3.0,
                        child: InkWell(
                          onTap: () async {
                            if (items[index].type == 'C'){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => FGType(type: items[index].type,)));
                            }
                            else if (items[index].type == 'NC'){
                              List<CameraDescription> cameras = await availableCameras();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CaptureScreen(
                                    camera: cameras.first, // Assuming 'cameras' is a List of available cameras
                                    deliv_id: '',
                                    containersNo: '',
                                    type: items[index].type,
                                  ),
                                ),
                              );
                            }
                            else if (items[index].type == 'Draft'){
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
                                            color: Colors.red.shade800,
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
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }
                              else{

                              }
                            }
                            else{

                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  items[index].imageUrl,
                                  height: 56.0,
                                  fit: BoxFit.contain,
                                ),
                                Text(
                                  items[index].title,
                                  style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                    );
                  },
                ),
              ],
            ),
          )
        ),
      ),
    );
  }
}

class GridItem {
  final String title;
  final String imageUrl;
  final String type;

  GridItem({required this.title, required this.imageUrl, required this.type});
}