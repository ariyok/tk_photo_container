import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../image_fullscreen.dart';
import 'FG_image_preview_screen.dart';

class DraftListPage extends StatefulWidget {
  const DraftListPage({super.key});

  @override
  _DraftListPageState createState() => _DraftListPageState();
}

class _DraftListPageState extends State<DraftListPage> {
  final dbHelper = DatabaseHelper();
  List<DraftData> drafts = [];


  @override
  void initState() {
    super.initState();
    _loadDraftsFromDatabase();
    _getUserInfo();
  }

  Future<void> _loadDraftsFromDatabase() async {
    final draftList = await dbHelper.getDrafts();
    setState(() {
      drafts = draftList;
    });
  }

  String userID = '';
  Future<void> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userId') ?? 'Unknown User';
    });
  }

  Image imageFromBase64(String base64String) {
    final bytes = base64Decode(base64String);
    return Image.memory(Uint8List.fromList(bytes));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Draft Image',
          style: TextStyle(
            color: Colors.white, // Set the text color to white
            fontWeight: FontWeight.bold, // Set the text to bold
          ),
        ),
        centerTitle: true,
      ),
      body: drafts.isEmpty
          ? const Center(
        child: Text('No drafts found'),
      )
          : ListView.builder(
        itemCount: drafts.length,
        itemBuilder: (context, index) {
          final draft = drafts[index];

          return Dismissible(
            key: Key(draft.id.toString()), // Unique key for each item
            background: Container(
              color: Colors.red, // Background color when swiping
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              // Remove the item from the database
              dbHelper.deleteDraft(draft.id!);

              setState(() {
                // Remove the item from the drafts list
                drafts.removeAt(index);
              });

              // Show a SnackBar to provide feedback to the user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Item deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // Handle undo action if needed
                      // For example, add the deleted item back to the list
                      setState(() {
                        drafts.insert(index, draft);
                      });
                    },
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 2.5, bottom: 2.5),
              child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          // Navigate to fullscreen view on tap
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageViewBase64(
                                imagePath: draft.imagePath,
                              ),
                            ),
                          );
                        },
                        child: imageFromBase64(draft.imagePath),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            /*'${draft.dirname}',*/
                            draft.dirname.substring(0, 2) == 'NC' ? 'Non-Container' : draft.dirname.substring(0, 2) == 'CC' ? 'Container' : '',
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          const Divider()
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /*Text(draft.imagePath),*/
                          /*Text(userID),*/
                          Text(
                            draft.dirname.substring(2),
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          Text(draft.container.substring(2)),
                          Text(draft.activity)
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {

                          // Buat request HTTP untuk mengirim gambar ke API
                          /*var uri = Uri.parse('http://172.16.185.94/CameraAPI/Api/Capture');*/
                          Uri uri;
                          if (kDebugMode){
                            uri = Uri.parse('https://tkapp01.tjiwikimia.co.id/APP.Camera/API/Capture');
                          }else{
                            uri = Uri.parse('https://tkapp01.tjiwikimia.co.id/APP.Camera/API/Capture');
                          }
                          /*var uri = Uri.parse('http://apipd.app.co.id/APIPD/Camera/API/Capture');*/
                          var request = http.MultipartRequest('POST', uri);

                          // Tambahkan base64Image sebagai bagian dari request fields
                          request.fields['foto'] = draft.imagePath;
                          request.fields['userid'] = userID;
                          request.fields['dirname'] = draft.dirname;
                          request.fields['container'] = draft.container;
                          request.fields['activity'] = draft.activity;

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
                              print(responseText);
                              _showResponseDialog(context, responseText);

                              setState(() {
                                // Remove the item from the database
                                dbHelper.deleteDraft(draft.id!);

                                // Remove the item from the drafts list
                                drafts.removeAt(index);
                              });

                            } else {
                              print(response.reasonPhrase);
                              _showErrorDialog(
                                  context, 'There was a problem with the connection or service.!');
                            }
                          } catch (e) {
                            print('Error sending image to API: $e');
                            _showErrorDialog(context,
                                'Error sending image to API, There was a problem with the connection or service.!');
                          } finally {
                            setState(() {
                              // Set status mengirim data kembali ke false
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text('Send', style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  )
              ),
            ),
          );
        },
      ),
    );
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
                /*Navigator.of(context).pop();*/
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
