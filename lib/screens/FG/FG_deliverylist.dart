import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:search_page/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;

import '../capture_screen.dart';
import '../capture_screen2.dart';
import '../settings_screen.dart';

class Delivery implements Comparable<Delivery> {
  final String deliv_id, ContainerNo, IDMill;

  const Delivery(this.deliv_id, this.ContainerNo, this.IDMill);

  @override
  int compareTo(Delivery other) => deliv_id.compareTo(other.deliv_id);
}

class DeliveryList extends StatefulWidget {
  final type;
  final deliv_type;

  const DeliveryList({
    super.key,
    required this.type,
    required this.deliv_type
  });

  @override
  State<DeliveryList> createState() => _DeliveryListState();
}

class _DeliveryListState extends State<DeliveryList> {

  String userNik = '';

  Future<void> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userNik = prefs.getString('nik') ?? 'Unknown NIK';
    });
  }

  final TextEditingController dirnameController = TextEditingController();
  final TextEditingController containerController = TextEditingController();

  bool _validateDirname = false;
  bool _validateContainer = false;

  List<Delivery> deliverylist = [];

  //String threeDaysAgoString = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 3)));
  String dDates = DateFormat('yyyy-MM-dd').format(DateTime.now());
  
  Future<List<Delivery>> fetchDataFromSoapService() async {
    final String soapEnvelope = '''<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <GetData xmlns="http://tempuri.org/">
          <Mill>TKM</Mill>
          <date>$dDates</date>
          <ReportType>${widget.deliv_type}</ReportType>
          <Token>XXXXXX</Token>
          <Appl>Camera_App</Appl>
        </GetData>
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
            'Content-Length': soapEnvelope.length.toString(),
            'SOAPAction': 'http://tempuri.org/GetData',
          },
          body: soapEnvelope,
        );
      }
      else{
        response = await http.post(
          Uri.parse('https://tkapp01.tjiwikimia.co.id/APP.Other/Delivery.asmx'),
          headers: {
            'Content-Type': 'text/xml; charset=utf-8',
            'Content-Length': soapEnvelope.length.toString(),
            'SOAPAction': 'http://tempuri.org/GetData',
          },
          body: soapEnvelope,
        );
      }

      if (response.statusCode == 200) {
        final xmlResponse = response.body;
        final deliveryList = parseDataFromXml(xmlResponse);
        return deliveryList;
      } else {
        throw Exception('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  List<Delivery> parseDataFromXml(String xmlResponse) {
    final document = xml.XmlDocument.parse(xmlResponse);
    final dataNodes = document.findAllElements('DataModel');
    final deliveryList = dataNodes.map((node) {
      final IDMill = node.findElements('IDMill').first.text;
      //final TglDaftar = node.findElements('TglDaftar').first.text;
      final delivId = node.findElements('deliv_id').first.text;
      final ContainerNo = node.findElements('ContainerNo').first.text;
      //final contName = node.findElements('cont_name').first.text;

      return Delivery(delivId, ContainerNo, IDMill);
    }).toList();

    return deliveryList;
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    fetchDataAndPopulateDeliveryList();
  }

  Future<void> fetchDataAndPopulateDeliveryList() async {
    try {
      final deliveryData = await fetchDataFromSoapService();

      setState(() {
        deliverylist = deliveryData;
      });
    } catch (e) {
      // Handle error
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  _showManualInputPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 15.0),
                  const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/container-delivery.png'),
                    radius: 25, // Adjust the size as needed
                  ),
                  const SizedBox(height: 5.0),
                  const Text('Please input stuffing manual'),
                  const SizedBox(height: 10.0),
                  TextField(
                    controller: dirnameController,
                    decoration: InputDecoration(
                      hintText: 'Delivery Number',
                      border: const OutlineInputBorder(),
                      labelText: 'Delivery Number',
                      errorText: _validateDirname ? 'Delivery Number is required.' : null,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: containerController,
                    decoration: InputDecoration(
                      hintText: 'Container Number',
                      border: const OutlineInputBorder(),
                      labelText: 'Container Number',
                      errorText: _validateContainer ? 'Container Number is required.' : null,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Tambahkan logika untuk tombol "Cancel" di sini
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white),),
                      ),
                      const SizedBox(width: 16.0), // Add space between buttons
                      ElevatedButton(
                        onPressed: () async {
                          // Your validation logic here
                          if (dirnameController.text.isEmpty) {
                            setState(() {
                              _validateDirname = true;
                            });
                          } else {
                            setState(() {
                              _validateDirname = false;
                            });
                          }
                          if (containerController.text.isEmpty) {
                            setState(() {
                              _validateContainer = true;
                            });
                          } else {
                            setState(() {
                              _validateContainer = false;
                            });
                          }
                          if (!_validateDirname && !_validateContainer) {
                            // Continue with the logic you want
                            List<CameraDescription> cameras = await availableCameras();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CaptureScreen(
                                  camera: cameras.first,
                                  deliv_id: dirnameController.text,
                                  containersNo: containerController.text,
                                  type: widget.type,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFED1D24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text('Submit', style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _showBarcodeScanResult(){
    showDialog(
        context: context,
        builder: (context){
          return Dialog(
              child: Column(
                children: [
                  const SizedBox(height: 15,),
                  Text('Scan Result : $_scanBarcode'),
                  const SizedBox(height: 15,),
                  Expanded(
                      child: ListView.builder(
                          itemCount: deliverylist.length,
                          itemBuilder: (context, index) {
                            final delivery = deliverylist[index];

                            if (delivery.ContainerNo.contains(_scanBarcode)){
                              return Padding(
                                padding: const EdgeInsets.only(left: 15, right: 15, top: 2, bottom: 2),
                                child: Card(
                                  elevation: 2,
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundImage: AssetImage('assets/images/container-delivery.png'),
                                      radius: 20, // Adjust the size as needed
                                    ),
                                    title: Text(
                                        'Delivery : ${delivery.deliv_id}',
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold)
                                    ),
                                    subtitle: Text('Container : ${delivery.ContainerNo}'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25), // Adjust the radius as needed
                                        color: delivery.IDMill == 'PDK1'
                                            ? Colors.indigoAccent
                                            : delivery.IDMill == 'PDK2'
                                            ? Colors.teal
                                            : delivery.IDMill == 'PDK3'
                                            ? Colors.cyan
                                            : delivery.IDMill == 'TKM'
                                            ? Colors.blueAccent
                                            : Colors.black, // Default color if not 'PDK1', 'PDK2', or 'PDK3'
                                      ),
                                      child: Text(
                                        delivery.IDMill,
                                        style: const TextStyle(
                                            color: Colors.white, // Text color
                                            fontSize: 12
                                        ),
                                      ),
                                    ),
                                    onTap: () async {
                                      List<CameraDescription> cameras = await availableCameras();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => 
                                            CaptureScreen(
                                              camera: cameras.first, // Assuming 'cameras' is a List of available cameras
                                              deliv_id: delivery.deliv_id,
                                              containersNo: delivery.ContainerNo,
                                              type: widget.type,
                                            ), 
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            } else {
                              // If the condition is not met, return an empty container
                              return const SizedBox.shrink();
                            }
                          }
                      )
                  )
                ],
              )
          );
        }
    );
  }

  String _scanBarcode = 'No Barcode';

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delivery Menu',
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
      body: ListView.builder(
        itemCount: deliverylist.length,
        itemBuilder: (context, index) {
          final delivery = deliverylist[index];
          final String heroTag = deliverylist[index].deliv_id+deliverylist[index].ContainerNo;
          return Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 2, bottom: 2),
            child: Card(
              elevation: 2,
              child: ListTile(
                leading: Hero(
                  tag: heroTag, 
                  child: const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/container-delivery.png'),
                    radius: 20, // Adjust the size as needed
                  ),
                ),
                title: Text(
                    delivery.deliv_id,
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold)
                ),
                subtitle: Text(delivery.ContainerNo),
                onTap: () async {
                  List<CameraDescription> cameras = await availableCameras();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CaptureScreen(
                        camera: cameras.first,
                        deliv_id: delivery.deliv_id,
                        containersNo: delivery.ContainerNo,
                        type: widget.type,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Tooltip(
            message: 'Add your tooltip message here',
            child: FloatingActionButton(
              heroTag: 1,
              backgroundColor: const Color(0xFFED1D24),
              tooltip: 'Search delivery',
              onPressed: () => showSearch(
                context: context,
                delegate: SearchPage(
                  onQueryUpdate: print,
                  items: deliverylist,
                  searchLabel: 'Search delivery or container number',
                  barTheme: ThemeData(
                    // Customize the search bar's appearance here
                    appBarTheme: const AppBarTheme(
                      backgroundColor: Color(0xFFED1D24),
                    ),
                    textTheme: const TextTheme(
                      // Customize the text style of the search input field
                      titleLarge: TextStyle(
                        color: Colors.white, // Change the text color
                        fontSize: 16.0, // Change the text size
                      ),
                    ),
                  ),
                  suggestion: const Center(
                    child: Text('search delivery number or container number'),
                  ),
                  failure: Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Center(
                          child: Text('No delivery or container found, please input manual'),
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: dirnameController,
                          decoration: InputDecoration(
                            hintText: 'Delivery Number',
                            border: const OutlineInputBorder(),
                            labelText: 'Devlivery Number',
                            errorText:
                            _validateDirname ? 'Delivery Number is required.' : null,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: containerController,
                          decoration: InputDecoration(
                            hintText: 'Container Number',
                            border: const OutlineInputBorder(),
                            labelText: 'Container Number',
                            errorText:
                            _validateContainer ? 'Container Number is required.' : null,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () async {
                            if (dirnameController.text.isEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Validation Error'),
                                    content:
                                    const Text('Delivery Number is required.'),
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
                                    const Text('Container Number is required.'),
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
                            else{
                              List<CameraDescription> cameras = await availableCameras();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CaptureScreen(
                                    camera: cameras.first, // Assuming 'cameras' is a List of available cameras
                                    deliv_id: dirnameController.text,
                                    containersNo: containerController.text,
                                    type: widget.type,
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFED1D24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: const Text('Submit', style: TextStyle(color: Colors.white),),
                        ),
                      ],
                    ),
                  ),
                  filter: (delivery) => [
                    delivery.deliv_id,
                    delivery.ContainerNo,
                    delivery.IDMill,
                  ],
                  sort: (a, b) => a.compareTo(b),
                  builder: (deliverylist) => Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 2, bottom: 2 ),
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundImage: AssetImage('assets/images/container-delivery.png'),
                          radius: 20, // Adjust the size as needed
                        ),
                        title: Text(
                            deliverylist.deliv_id,
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)
                        ),
                        subtitle: Text('Container : ${deliverylist.ContainerNo}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20), // Adjust the radius as needed
                            color: deliverylist.IDMill == 'PDK1'
                                ? Colors.indigoAccent
                                : deliverylist.IDMill == 'PDK2'
                                ? Colors.teal
                                : deliverylist.IDMill == 'PDK3'
                                ? Colors.cyan
                                : Colors.black, // Default color if not 'PDK1', 'PDK2', or 'PDK3'
                          ),
                          child: Text(
                            deliverylist.IDMill == 'PDK1'
                                ? 'PDK1'
                                : deliverylist.IDMill == 'PDK2'
                                ? 'PDK2'
                                : deliverylist.IDMill == 'PDK3'
                                ? 'PDK3'
                                : 'Other',
                            style: const TextStyle(
                                color: Colors.white, // Text color
                                fontSize: 12
                            ),
                          ),
                        ),
                        onTap: () async {
                          List<CameraDescription> cameras = await availableCameras();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CaptureScreen(
                                camera: cameras.first, // Assuming 'cameras' is a List of available cameras
                                deliv_id: deliverylist.deliv_id,
                                containersNo: deliverylist.ContainerNo,
                                type: widget.type,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              child: const Icon(Icons.search, color: Colors.white,),
            ),
          ),
          const SizedBox(width: 10.0,),
          Tooltip(
            message: 'Scan Barcode',
            child: FloatingActionButton(
              heroTag: 2,
              backgroundColor: const Color(0xFFED1D24),
              onPressed: () {
                if(deliverylist.isNotEmpty)
                {
                  scanBarcodeNormal();
                  _showBarcodeScanResult();
                }
                else{
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Scan Barcode No Delivery'),
                        content: const Text('Mohon tunggu, masih memuat data delivery'),
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
              },
              child: const Icon(Icons.document_scanner_outlined, color: Colors.white,),
            ),
          ),
          const SizedBox(width: 10.0), // Add space between buttons
          Tooltip(
            message: 'Input manual',
            child: FloatingActionButton(
              heroTag: 3,
              backgroundColor: const Color(0xFFED1D24),
              onPressed: () {
                _showManualInputPopup();
              },
              child: const Icon(Icons.edit, color: Colors.white,),
            ),
          ),
        ],
      )
    );
  }
}

class DeliveryService {
  final String IDMill;
  final String TglDaftar;
  final String deliv_id;
  final String ReffNum1;
  final String ContainerNo;
  final String cont_name;

  DeliveryService(this.IDMill, this.TglDaftar, this.deliv_id, this.ReffNum1, this.ContainerNo, this.cont_name);
}