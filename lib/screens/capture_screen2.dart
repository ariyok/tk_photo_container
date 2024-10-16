import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_field/image_field.dart';
import 'package:image_picker/image_picker.dart';

class CaptureScreen2 extends StatefulWidget {
  final deliv_id;
  final containersNo;

  const CaptureScreen2(
      {super.key, required this.deliv_id, required this.containersNo});

  @override
  State<CaptureScreen2> createState() => _CaptureScreen2State();
}

typedef Progress = Function(double percent);

class _CaptureScreen2State extends State<CaptureScreen2> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _DelivIDController = TextEditingController();
  final TextEditingController _ContIDController = TextEditingController();

  dynamic remoteFiles;

  Future<dynamic> uploadToServer(XFile? file,
      {Progress? uploadProgress}) async {
    final stream = file!.openRead();
    int length = await file.length();
    final client = HttpClient();

    final request = await client.postUrl(Uri.parse('URI'));
    request.headers.add('Content-Type', 'application/octet-stream');
    request.headers.add('Accept', '*/*');
    request.headers.add('Content-Disposition', 'file; filename="${file.name}"');
    request.headers.add('Authorization', 'Bearer ACCESS_TOKEN');
    request.contentLength = length;

    int byteCount = 0;
    double percent = 0;
    Stream<List<int>> stream2 = stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          byteCount += data.length;
          if (uploadProgress != null) {
            percent = (byteCount / length) * 100;
            uploadProgress(percent);
          }
          sink.add(data);
        },
        handleError: (error, stack, sink) {},
        handleDone: (sink) {
          sink.close();
        },
      ),
    );
    await request.addStream(stream2);
  }

  @override
  void initState() {
    super.initState();
    _DelivIDController.text = widget.deliv_id;
    _ContIDController.text = widget.containersNo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Images',
          style: TextStyle(
            color: Colors.white, // Set the text color to white
            fontWeight: FontWeight.bold, // Set the text to bold
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 15,
              ),
              TextField(
                controller: _DelivIDController,
                readOnly: true, // Makes the TextField read-only
                decoration: const InputDecoration(
                  labelText: 'Delivery ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              TextField(
                controller: _ContIDController,
                readOnly: true, // Makes the TextField read-only
                decoration: const InputDecoration(
                  labelText: 'Container ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              /*  ImageField(),
              SizedBox(
                height: 15,
              ), */
              ImageField(
                texts: const {
                  'fieldFormText': 'Upload Photos',
                  'titleText': 'Upload Photos',
                  'addCaptionText': 'Add a activity',
                },
                /* files: remoteFiles != null
                    ? remoteFiles!.map((image) {
                        return ImageAndCaptionModel(
                            file: image, caption: image.alt.toString());
                      }).toList()
                    : [],
                remoteImage: false,
                onUpload:
                    (pickedFile, controllerLinearProgressIndicator) async {
                  dynamic fileUploaded = await uploadToServer(
                    pickedFile,
                    uploadProgress: (percent) {
                      var uploadProgressPercentage = percent / 100;
                      controllerLinearProgressIndicator!
                          .updateProgress(uploadProgressPercentage);
                    },
                  );
                  return fileUploaded;
                },
                onSave: (List<ImageAndCaptionModel>? imageAndCaptionList) {
                  remoteFiles = imageAndCaptionList;
                }, */
              ),
            ],
          ),
        ),
      ),
    );
  }
}
