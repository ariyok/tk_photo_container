import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:xml/xml.dart' as xml;

import '../image_fullscreen.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;
  final String delivID;
  final String containersNo;
  final String type;

  const ImagePreviewScreen({super.key, 
    required this.imagePath,
    required this.delivID,
    required this.containersNo,
    required this.type
  });

  @override
  _ImagePreviewScreenState createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final TextEditingController dirnameController = TextEditingController();
  final TextEditingController containerController = TextEditingController();
  final TextEditingController activityController = TextEditingController();

  bool _validateDirname = false;
  bool _validateContainer = false;
  final bool _validateActivity = false;
  bool _sendingData = false; // Status mengirim data
  bool _isEditing = false;

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

  @override
  void initState() {
    super.initState();
    _loadDescriptionFromSharedPreferences();
    // Muat nilai dari SharedPreferences saat layar dibuat
    activityOptions = []; // Initialize the list here
    fetchDataFromActivityService();
    _getUserInfo();
  }


  Future<void> _loadDescriptionFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDescription = widget.delivID == '' ? prefs.getString('Delivery Number') : widget.delivID;
    String? savedDescription2 = widget.containersNo == '' ? prefs.getString('Container Number') : widget.containersNo;
    String savedDescription3 = prefs.getString('Activity') ?? '';
    setState(() {
      dirnameController.text = savedDescription!;
      containerController.text = savedDescription2!;
      activityController.text = savedDescription3;
    });
  }

  @override
  void dispose() {
    dirnameController.dispose();
    containerController.dispose();
    activityController.dispose();
    super.dispose();
  }

  String selectedActivity = '';

  late List<String> activityOptions;

  Future<void> fetchDataFromActivityService() async {
    String soapActivityEnvelope = '''<?xml version="1.0" encoding="utf-8"?>
      <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <GetDataActivity xmlns="http://tempuri.org/">
            <Token>XXXXXX</Token>
            <Appl>Camera_App</Appl>
          </GetDataActivity>
        </soap:Body>
      </soap:Envelope>
    ''';
    try {
      final http.Response response;
      if (kDebugMode){
        response = await http.post(
          Uri.parse('https://tkapp01.tjiwikimia.co.id/APP.Other/Delivery.asmx'),
          headers: {
            'Content-Type': 'text/xml; charset=utf-8',
            'Content-Length': soapActivityEnvelope.length.toString(),
            'SOAPAction': 'http://tempuri.org/GetDataActivity',
          },
          body: soapActivityEnvelope,
        );
      }else{
        response = await http.post(
          Uri.parse('https://tkapp01.tjiwikimia.co.id/APP.Other/Delivery.asmx'),
          headers: {
            'Content-Type': 'text/xml; charset=utf-8',
            'Content-Length': soapActivityEnvelope.length.toString(),
            'SOAPAction': 'http://tempuri.org/GetDataActivity',
          },
          body: soapActivityEnvelope,
        );
      }

      if (response.statusCode == 200) {
        final xmlResponse = response.body;
        final activityList = parseActivityDataFromXml(xmlResponse);

        // Print the fetched activity options
        if (kDebugMode) {
          print('Fetched Activity Options: $activityList');
        }

        // Update activityOptions using setState
        setState(() {
          activityOptions = activityList;
        });
      } else {
        throw Exception('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching activity data: $e');
      }
    }
  }

  List<String> parseActivityDataFromXml(String xmlResponse) {
    final document = xml.XmlDocument.parse(xmlResponse);
    final dataNodes = document.findAllElements('DataActivity');
    final activityList = dataNodes.map((node) {
      final activity = node.findElements('Activity').first.text;
      return activity;
    }).toList();

    return activityList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Preview Image',
          style: TextStyle(
            color: Colors.white, // Set the text color to white
            fontWeight: FontWeight.bold, // Set the text to bold
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 15.0),
            /*Image.file(File(widget.imagePath)),*/
            Center(
              child: GestureDetector(
                onTap: () {
                  // Navigate to fullscreen view on tap
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageView(
                        imagePath: widget.imagePath,
                      ),
                    ),
                  );
                },
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30, top: 5, bottom: 5),
              child: ElevatedButton(
                  onPressed: () {
                    // Navigate to fullscreen view on tap
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageView(
                          imagePath: widget.imagePath,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.fit_screen, color: Colors.white,),
                      Text(" Lihat gambar penuh", style: TextStyle(color: Colors.white),)
                    ],
                  )
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.only(top: 16.0,bottom: 16.0,left: 20.0,right: 20.0),
              child: Column(
                children: [
                  TextField(
                    controller: dirnameController,
                    onChanged: (text) {
                      // Call the function to save the description to SharedPreferences when the text changes
                      _saveDescriptionToSharedPreferences(text);
                      // Check if dirnameController is empty and update the enabled property accordingly
                      setState(() {
                        _validateDirname = text.isEmpty;
                      });
                    },
                    enabled: _isEditing || widget.delivID == '' ? true : false, // Enable editing only when dirnameController is empty
                    /*enabled: false,  // Set enabled to false to disable editing*/
                    decoration: InputDecoration(
                      hintText: widget.type == 'C' ? 'Delivery Number' :
                                widget.type == 'NC' ? 'Nama Barang / Asset Name' :
                                'Dirname 1',
                      border: const OutlineInputBorder(),
                      labelText: widget.type == 'C' ? 'Delivery Number' :
                                 widget.type == 'NC' ? 'Nama Barang / Asset Name' :
                                 'Dirname 1',
                      hintStyle: const TextStyle(color: Colors.grey),  // Change the hint text color
                      labelStyle: const TextStyle(color: Colors.black), // Change the label text color
                      errorText:
                      _validateDirname ?
                      widget.type == 'C' ? 'Delivery Number is required.' :
                      widget.type == 'NC' ? 'Nama Barang / Asset Name is required.' :
                      'Dirname 1 is required.' : null,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  TextField(
                    controller: containerController,
                    onChanged: (text) {
                      // Panggil fungsi untuk menyimpan deskripsi ke SharedPreferences saat teks berubah
                      _saveDescriptionToSharedPreferences2(text);
                      // Check if dirnameController is empty and update the enabled property accordingly
                      setState(() {
                        _validateContainer = text.isEmpty;
                      });
                    },
                    enabled: _isEditing || widget.containersNo == '' ? true : false,
                    decoration: InputDecoration(
                      hintText: widget.type == 'C' ? 'Container Number' : widget.type == 'NC' ? 'Nomor Barang / Kode Asset / Serial Number' : 'Dirname 2',
                      border: const OutlineInputBorder(),
                      labelText: widget.type == 'C' ? 'Container Number' : widget.type == 'NC' ? 'Nomor Barang / Kode Asset / Serial Number' : 'Dirname 2',
                      hintStyle: const TextStyle(color: Colors.grey),  // Change the hint text color
                      labelStyle: const TextStyle(color: Colors.black), // Change the label text color
                      errorText:
                      _validateContainer ? widget.type == 'C' ? 'Container Number is required.' : widget.type == 'NC' ? 'Nomor Barang / Kode Asset / Serial Number is required.' : 'Dirname 2 is required.' : null,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  SingleChildScrollView(
                     child:  AutoCompleteTextField<String>(
                       key: GlobalKey(),
                       clearOnSubmit: false,
                       suggestions: activityOptions,
                       controller: activityController,
                       onFocusChanged: (text) {
                         // Panggil fungsi untuk menyimpan deskripsi ke SharedPreferences saat teks berubah
                         _saveDescriptionToSharedPreferences3(activityController.text);
                       },
                       decoration: InputDecoration(
                         hintText: 'Select Activity',
                         border: const OutlineInputBorder(),
                         labelText: 'Activity',
                         hintStyle: const TextStyle(color: Colors.grey),
                         labelStyle: const TextStyle(color: Colors.black),
                         errorText:
                         _validateActivity ?
                         'Activity is required.' : null,
                       ),
                       itemFilter: (String suggestion, String query) {
                         return suggestion.toLowerCase().contains(query.toLowerCase());
                       },
                       itemSorter: (String a, String b) {
                         return a.compareTo(b);
                       },
                       itemSubmitted: (String value) {
                         setState(() {
                           selectedActivity = value;
                           // Call the function to save the selected activity to SharedPreferences if needed
                         });
                       },
                       itemBuilder: (BuildContext context, String suggestion) {
                         return ListTile(
                           title: Text(suggestion),
                         );
                       },
                     ),
                   ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        if (widget.type == 'C')
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true; // Assuming _isEditing is defined in your state
                                  });
                                },
                              ),
                              const Text('Edit Field'),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    // Spasi antara TextField dan tombol
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // button cancel
                        ElevatedButton.icon(
                          onPressed: () {
                            // Tambahkan logika untuk tombol "Cancel" di sini
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.white, // Set the text color to white
                          ),
                          label: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white, // Set the text color to white
                              fontWeight: FontWeight.bold, // Set the text to bold
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            minimumSize: const Size(150.0, 48.0),
                          ),
                        ),
                        // button cancel
                        // button send
                        ElevatedButton.icon(
                          onPressed: _sendingData
                              ? null
                              : () {
                                  if (dirnameController.text.isEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Validation Error'),
                                          content:
                                              Text(widget.type == 'C' ? 'Delivery Number is required.' : widget.type == 'NC' ? 'Nama Barang / Asset Name is required.' : 'Dirname 1 is required.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                  else if (containerController.text.isEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Validation Error'),
                                          content:
                                          Text(widget.type == 'C' ? 'Container Number is required.' : widget.type == 'NC' ? 'Nomor Barang / Kode Asset / Serial Number is required.' : 'Dirname 2 is required.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                  else if (activityController.text.isEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Validation Error'),
                                          content:
                                          const Text('Activity is required.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                  else {
                                    setState(() {
                                      _sendingData = true;
                                      // Set status mengirim data
                                    });
                                    // Panggil fungsi untuk mengirim foto ke server di sini
                                    _sendPhotoToAPI(
                                        context, (widget.type == 'C' ? 'CC' : widget.type == 'NC' ? 'NC' : '') + dirnameController.text, (widget.type == 'C' ? 'CC' : widget.type == 'NC' ? 'NC' : '') + containerController.text, activityController.text);
                                  }
                                },
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white, // Set the text color to white
                          ),
                          label: const Text(
                            'Send',
                            style: TextStyle(
                              color: Colors.white, // Set the text color to white
                              fontWeight: FontWeight.bold, // Set the text to bold
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            minimumSize: const Size(150.0, 48.0),
                          ),
                        ),
                        // end button send
                      ],
                    ),
                    const SizedBox(height: 200.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        border: const OutlineInputBorder(),
        hintStyle: const TextStyle(color: Colors.grey),  // Change the hint text color
        labelStyle: const TextStyle(color: Colors.black), // Change the label text color
      ),
    );
  }

  // Function untuk menyimpan deskripsi ke SharedPreferences saat teks berubah
  void _saveDescriptionToSharedPreferences(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('Delivery Number', text);
  }
  void _saveDescriptionToSharedPreferences2(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('Container Number', text);
  }
  void _saveDescriptionToSharedPreferences3(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('Activity', text);
  }

  //=========================== Function Send To API =======================

  void _sendPhotoToAPI(BuildContext context, String dirname, String container, String activity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? '';

    // Baca file gambar sebagai bytes
    List<int> imageBytes = await File(widget.imagePath).readAsBytes();

    // Konversi bytes ke base64
    String base64Image = base64Encode(imageBytes);

    // Buat request HTTP untuk mengirim gambar ke API
    Uri uri = Uri.parse('https://tkapp01.tjiwikimia.co.id/app.camera/api/capture');

    var request = http.MultipartRequest('POST', uri);

    // Tambahkan base64Image sebagai bagian dari request fields
    request.fields['foto'] = base64Image;
    request.fields['userid'] = userId;
    request.fields['dirname'] = dirname;
    request.fields['container'] = container;
    request.fields['activity'] = activity;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing the dialog
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Loading..."),
            ],
          ),
        );
      },
    );

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseText = await response.stream.bytesToString();
        if (kDebugMode) {
          print(responseText);
        }

        // Parse the JSON response
        Map<String, dynamic> jsonResponse = jsonDecode(responseText);

        // Access "success" and "code" values
        bool success = jsonResponse['success'];
        int code = jsonResponse['code'];
        String message = jsonResponse['message'];

        if (kDebugMode) {
          print('Success: $success');
          print('Code: $code');
          print('Message: $message');
        }

        if (code == 200){
          _showResponseDialog(context, responseText);
        }

        if (code == 400){
          _showErrorDialog(context, message);

          // Read the image file as bytes
          List<int> imageBytes = await File(widget.imagePath).readAsBytes();

          // Convert the image bytes to a Base64 string
          String base64Image = base64Encode(imageBytes);

          // Save data as a draft
          final draftData = DraftData(
            dirname: dirname,
            container: container,
            activity: activity,
            imagePath: base64Image,
          );

          final dbHelper = DatabaseHelper();
          await dbHelper.saveDraft(draftData);
        }

      } else {
        if (kDebugMode) {
          print(response.reasonPhrase);
        }
        _showErrorDialog(
            context, 'There was a problem with the connection or service.!');

        // Read the image file as bytes
        List<int> imageBytes = await File(widget.imagePath).readAsBytes();

        // Convert the image bytes to a Base64 string
        String base64Image = base64Encode(imageBytes);

        // Save data as a draft
        final draftData = DraftData(
          dirname: dirname,
          container: container,
          activity: activity,
          imagePath: base64Image,
        );

        final dbHelper = DatabaseHelper();
        await dbHelper.saveDraft(draftData);

      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending image to API: $e');
      }
      _showErrorDialog(context,
          'Error sending image to API, There was a problem with the connection or service.!');

      // Read the image file as bytes
      List<int> imageBytes = await File(widget.imagePath).readAsBytes();

      // Convert the image bytes to a Base64 string
      String base64Image = base64Encode(imageBytes);

      // Save data as a draft
      final draftData = DraftData(
        dirname: dirname,
        container: container,
        activity: activity,
        imagePath: base64Image,
      );

      final dbHelper = DatabaseHelper();
      await dbHelper.saveDraft(draftData);

    } finally {
      setState(() {
        _sendingData = false;
        // Set status mengirim data kembali ke false
      });
    }
  }

  void _showResponseDialog(BuildContext context, String responseText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('The photo was successfully sent to the server.!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Failed'),
          content: Text(errorMessage),
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
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  static Database? _db;

  DatabaseHelper.internal();

  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDatabase();
    return _db;
  }

  Future<Database> initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'drafts.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int newVersion) async {
    await db.execute('''
      CREATE TABLE Drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dirname TEXT,
        container TEXT,
        activity TEXT,
        imagePath TEXT
      )
    ''');
  }

  Future<int> saveDraft(DraftData draft) async {
    var client = await db;
    return await client!.insert('Drafts', draft.toMap());
  }

  Future<List<DraftData>> getDrafts() async {
    var client = await db;
    if (client == null) return []; // Check if client is null

    List<Map<String, dynamic>> maps = await client.query('Drafts', columns: ['id', 'dirname', 'container', 'activity', 'imagePath']);
    List<DraftData> drafts = [];
    if (maps.isNotEmpty) {
      for (Map<String, dynamic> map in maps) {
        drafts.add(DraftData.fromMap(map));
      }
    }
    return drafts;
  }

  Future<void> deleteDraft(int id) async {
    var client = await db;
    await client!.delete('Drafts', where: 'id = ?', whereArgs: [id]);
  }
}

class DraftData {
  final int? id; // Add an ID for database reference
  final String dirname;
  final String container;
  final String activity;
  final String imagePath;

  DraftData({this.id, required this.dirname, required this.container, required this.activity, required this.imagePath});

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Include ID in the map
      'dirname': dirname,
      'container': container,
      'activity': activity,
      'imagePath': imagePath,
    };
  }

  factory DraftData.fromMap(Map<String, dynamic> map) {
    return DraftData(
      id: map['id'],
      dirname: map['dirname'],
      container: map['container'],
      activity: map['activity'],
      imagePath: map['imagePath'],
    );
  }
}

Widget circularButton(IconData icon, VoidCallback onPressed) {
  return Padding(
    padding: const EdgeInsets.only(top: 10.0),
    child: ClipOval(
      child: Material(
        color: Colors.grey, // Button color
        child: InkWell(
          splashColor: Colors.red,
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              color: Colors.black, // Icon color
            ),
          ),
        ),
      ),
    ),
  );
}