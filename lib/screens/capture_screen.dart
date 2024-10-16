import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_information/device_information.dart';
import 'package:flutter/services.dart';

import 'FG/FG_draft.dart';
import 'FG/FG_image_preview_screen.dart';
import 'settings_screen.dart';

class CaptureScreen extends StatefulWidget {
  final CameraDescription camera;
  final deliv_id;
  final containersNo;
  final type;

  const CaptureScreen(
      {super.key,
      required this.camera,
      required this.deliv_id,
      required this.containersNo,
      required this.type});

  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late CameraController _controller;
  double _baseScale = 1.0;
  double _currentZoom = 1.0;
  final double _minAvailableZoom = 1.0;
  final double _maxAvailableZoom = 5.0;
  bool _flashOn = false;
  bool _loading = false;
  String _selectedResolution = 'high';
  late Directory externalDir;
  TextEditingController dirnameController = TextEditingController();
  TextEditingController containerController = TextEditingController();
  TextEditingController activityController = TextEditingController();
  bool _exposureAutoMode = true;
  String imeiNo = 'Loading...';

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
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeCamera();
    //_checkForUpdates(context);
    _autoLogout(context);
    _getDeviceInformation();
    _getUserInfo();

    /*  // Tambahkan pemanggilan FlutterDownloader.registerCallback di sini
    FlutterDownloader.registerCallback((id, status, progress) {
      if (status == DownloadTaskStatus.complete) {
        // File APK telah diunduh dan siap untuk dibuka
        OpenFile.open('${externalDir.path}/camera_app_v0.0.6.apk');
        // Ganti dengan nama file APK Anda yang benar
      }
    }); */
  }

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

  @override
  void dispose() {
    _controller.dispose();
    dirnameController.dispose();
    containerController.dispose();
    activityController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedResolution = prefs.getString('cameraResolution') ?? 'high';
    // low 320x240
    // medium 720x480
    // high 1280x720
    // veryHigh 1920x1080
    // ultraHigh 3840x2160
    ResolutionPreset preset;

    switch (_selectedResolution) {
      case 'low':
        preset = ResolutionPreset.low;
        break;
      case 'medium':
        preset = ResolutionPreset.medium;
        break;
      case 'high':
        preset = ResolutionPreset.high;
        break;
      case 'veryHigh':
        preset = ResolutionPreset.veryHigh;
        break;
      case 'ultraHigh':
        preset = ResolutionPreset.ultraHigh;
        break;
      default:
        preset = ResolutionPreset.high;
        break;
    }

    _controller = CameraController(widget.camera, preset);

    await _controller.initialize();

    // Adjust exposure
    _controller.setExposureMode(ExposureMode.auto);

    final size = _controller.value.previewSize;
    if (size != null) {
      final centerPoint = Offset(size.width / 2, size.height / 2);
      final normalizedCenterPoint =
          Offset(centerPoint.dx / size.width, centerPoint.dy / size.height);
      await _controller.setExposurePoint(normalizedCenterPoint);
    }

    // Adjust exposure compensation to make the preview lighter
    await _controller.setExposureOffset(
        1.0); // Increase this value to make the preview lighter

    if (!mounted) {
      return;
    }

    try {
      // Try to set autofocus mode (auto)
      await _controller.setFocusMode(FocusMode.auto);
    } catch (e) {
      // Handle error if autofocus mode is not supported
      if (kDebugMode) {
        print('Autofocus not supported by camera: $e');
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewSize = _controller.value.previewSize!;
    final previewRatio = previewSize.height / previewSize.width;

    double screenWidth, screenHeight;

    if (deviceRatio > previewRatio) {
      screenWidth = size.width;
      screenHeight = size.width / previewSize.width * previewSize.height;
    } else {
      screenHeight = size.height;
      screenWidth = size.height / previewSize.height * previewSize.width;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.settings,
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
        actions: <Widget>[
          // resolustion
          IconButton(
            icon: const Icon(
              Icons.hd,
              color: Colors.white,
            ),
            onPressed: () {
              _showSettingsDialog(context);
            },
          ),
          // resolution
          // Tombol untuk mengaktifkan/menonaktifkan flash
          IconButton(
            onPressed: () {
              // Toggle flash
              setState(() {
                if (_flashOn) {
                  _controller.setFlashMode(FlashMode.off);
                } else {
                  _controller.setFlashMode(FlashMode.torch);
                }
                _flashOn = !_flashOn;
              });
            },
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.yellow : Colors.white,
              // Ganti warna ikon jika flash aktif
            ),
          ),

          // Tombol untuk mengaktifkan/menonaktifkan autofocus
          IconButton(
            onPressed: () {
              setState(() {
                _exposureAutoMode = !_exposureAutoMode;
                // Toggle variabel exposure
                _controller.setExposureMode(
                  _exposureAutoMode ? ExposureMode.auto : ExposureMode.locked,
                );
              });
            },
            icon: Icon(
              _exposureAutoMode ? Icons.crop_free : Icons.filter_center_focus,
              color: _exposureAutoMode ? Colors.white : Colors.yellow,
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onTapDown: (details) => _onViewFinderTap(details, context),
            onScaleStart: (details) {
              _baseScale = _currentZoom;
            },
            onScaleUpdate: (details) {
              double scale = _baseScale * details.scale;
              scale = scale.clamp(
                _minAvailableZoom,
                _maxAvailableZoom,
              );
              setState(() {
                _currentZoom = scale;
                _controller.setZoomLevel(_currentZoom);
              });
            },
            child: Center(
              child: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: CameraPreview(_controller),
              ),
            ),
          ),
          const SizedBox(
            width: double.infinity,
            height: double.infinity,
          ),
          if (_loading)
            const Stack(
              children: <Widget>[
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    'mengambil gambar, mohon tunggu...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ],
            ),
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zoom: ${_currentZoom.toStringAsFixed(2)}x',
                  style: const TextStyle(color: Colors.white),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_minAvailableZoom, _currentZoom),
                    min: _minAvailableZoom,
                    max: _maxAvailableZoom,
                    activeColor: Colors.white,
                    inactiveColor: Colors.grey,
                    onChanged: (values) {
                      setState(() {
                        _currentZoom = values.end;
                        _controller.setZoomLevel(_currentZoom);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 3,
                  onPressed: () {
                    _captureImage(true);
                  },
                  tooltip: 'Gallery',
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.browse_gallery_sharp,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                FloatingActionButton(
                    heroTag: 1,
                    onPressed: () {
                      if (role.contains('Finished Goods')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DraftListPage()),
                        );
                      } else if (role.contains('Information Technology') ||
                          role == 'IT') {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Colors.black,
                              title: const Text(
                                'Pilih Draft',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              content: Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(
                                          context); // Close the dialog
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const DraftListPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Finished Goods',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      } else {}
                    },
                    backgroundColor: Colors.white,
                    child: const Text(
                      'Draft',
                      style: TextStyle(color: Colors.black),
                    )),
                const SizedBox(
                  width: 10,
                ),
                FloatingActionButton(
                  heroTag: 2,
                  onPressed: () {
                    _captureImage(false);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('Resolution'),
                trailing: DropdownButton<String>(
                  value: _selectedResolution,
                  onChanged: (String? newValue) async {
                    if (newValue != null) {
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString('cameraResolution', newValue);
                      setState(() {
                        _selectedResolution = newValue;
                      });
                      _initializeCamera();
                    }
                  },
                  // low 320x240
                  // medium 720x480
                  // hight 1280x720
                  // veryHight 1920x1080
                  // ultrahight 3840x2160
                  items: <String>[
                    'low',
                    'medium',
                    'high',
                    'veryHigh',
                    'ultraHigh',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _captureImage(bool isFromGallery) async {
    bool previousFlashStatus = _flashOn;
    final XFile? image;

    if (!isFromGallery) {
      setState(() {
        _loading = true;
      });

      if (_flashOn) {
        await _controller.setFlashMode(FlashMode.torch);
      } else {
        await _controller.setFlashMode(FlashMode.off);
      }
      await _controller.setFocusMode(FocusMode.auto);
      image = await _controller.takePicture();
    } else {
      final picker = ImagePicker();
      image = await picker.pickImage(source: ImageSource.gallery);
    }

    try {
      await _addWatermark(image!.path);

      if (widget.type == 'C') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              imagePath: image!.path,
              delivID: widget.deliv_id,
              containersNo: widget.containersNo,
              type: widget.type,
            ),
          ),
        );
      } else if (widget.type == 'NC') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              imagePath: image!.path,
              delivID: widget.deliv_id,
              containersNo: widget.containersNo,
              type: widget.type,
            ),
          ),
        );
      } else {}

      // Restore the flash status after capturing the image
      setState(() {
        _loading = false;
        _flashOn = previousFlashStatus;
        if (_flashOn) {
          _controller.setFlashMode(FlashMode.torch);
        } else {
          _controller.setFlashMode(FlashMode.off);
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (kDebugMode) {
        print(e);
      }
      if (kDebugMode) {
        print('Error capturing image: $e');
      }
    }
  }

  void _onViewFinderTap(TapDownDetails details, BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset point = box.globalToLocal(details.globalPosition);
    final Offset focusPoint = Offset(
      point.dx / box.size.width,
      point.dy / box.size.height,
    );

    _controller.setFocusPoint(focusPoint);
  }

  Future<void> _addWatermark(String imagePath) async {
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;

    // You can customize the watermark text and position
    String watermarkText =
        DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now()).toString();
    int x = 20;
    int y = image.height - 50;

    // Set the watermark color using dart:ui
    Color watermarkColor = Colors.amber;

    // Get the individual RGB components
    int red = watermarkColor.red;
    int green = watermarkColor.green;
    int blue = watermarkColor.blue;

    img.Color imgWatermarkColor = img.ColorRgb8(red, green, blue);

    // Draw the watermark on the image
    img.drawString(image, watermarkText,
        font: _getWatermarkFont(), x: x, y: y, color: imgWatermarkColor);

    // Save the image with the watermark
    imageFile.writeAsBytesSync(img.encodeJpg(image, quality: 100));
  }

  img.BitmapFont _getWatermarkFont() {
    switch (_selectedResolution) {
      case 'low':
        return img.arial14;
      case 'medium':
        return img.arial14;
      case 'high':
        return img.arial48;
      case 'veryHigh':
        return img.arial48;
      case 'ultraHigh':
        return img.arial48;
      default:
        return img.arial14;
    }
  }

  Future<File> _compressImage(File imageFile) async {
    final compressedImage = await _compressImageFile(imageFile);

    if (compressedImage != null) {
      return compressedImage;
    } else {
      return imageFile;
    }
  }

  Future<File?> _compressImageFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image != null) {
      const maxWidth = 480;
      const maxHeight = 720;

      if (image.width > maxWidth || image.height > maxHeight) {
        final compressedImage = img.copyResize(
          image,
          width: maxWidth,
          height: maxHeight,
        );

        final compressedFile = File(imageFile.path)
          ..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 100));

        return compressedFile;
      } else {
        return imageFile;
      }
    } else {
      return null;
    }
  }

// ============================= Cek Device Out Logout =========================

  Future<void> _autoLogout(BuildContext context) async {
    // Get User ID dari Sherpreference
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? DeviceId = prefs.getString('DeviceId');
    // Dapatkan Android Device ID (IMEI)
    // String manufacturer = imeiNo;

    final Uri uri;
    if (kDebugMode) {
      uri = Uri.parse(
          'https://tkapp01.tjiwikimia.co.id/APP.Credential/API/Userlogin');
    } else {
      uri = Uri.parse(
          'https://tkapp01.tjiwikimia.co.id/APP.Credential/API/Userlogin');
    }

    var request = http.MultipartRequest('GET', uri);
    request.fields['userId'] = '$userId';
    if (kDebugMode) {
      print('Unknown response: $userId');
    }
    request.fields['apps'] = 'Camera_App';
    if (kDebugMode) {
      print('Unknown response: Camera_App');
    }
    request.fields['DeviceId'] = '$DeviceId';
    if (kDebugMode) {
      print('Unknown response: $DeviceId');
    }

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final String responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);
        final message = responseData['message'];

        if (message == 'Device ID Blocked') {
          // Tampilkan dialog dan lakukan logout otomatis
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Logout'),
                content: const Text(
                    'Sorry, your user ID has been blocked and your session has ended.'),
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

          Future.delayed(const Duration(seconds: 5), () {
            _handleLogout();
          });
        } else {
          if (kDebugMode) {
            print('Unknown response: $message');
          }
        }
      } else {
        if (kDebugMode) {
          print('Failed to fetch data: ${response.reasonPhrase}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error during HTTP request: $error');
      }
    }
  }

  Future<void> _handleLogout() async {
    // Hapus data dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');

    // Navigasi ke halaman login (ganti dengan halaman login Anda)
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      // Ganti dengan rute halaman login Anda
      (route) => false,
    );
  }
// ============================= End Cek Device Out Logout ====================

// ============================= Update Offline ===============================
/*   Future<void> _checkForUpdates(BuildContext context) async {
    final Uri uri;
    if (kDebugMode){
      uri = Uri.parse('https://tkapp01.tjiwikimia.co.id/APP.Credential/API/MobileVersion');
    }else{
      uri = Uri.parse('https://tkapp01.tjiwikimia.co.id/APP.Credential/API/MobileVersion');
    }

    var request = http.MultipartRequest('GET', uri);
    request.fields['apps'] = 'Camera_App';

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final String responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);

        final latestVersionData = responseData['data']['versionCode'];
        final latestVersion = latestVersionData.substring(1);
        // Menghapus karakter 'V' di awal

        final currentVersion = await getAppVersion();

        if (latestVersion.compareTo(currentVersion) > 0) {
          showUpdateDialog(context, () {
            _downloadAndInstallAPK(responseData['data']['downloadUrl']);
          });
        }
      } else {
        print('Failed to fetch data: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error during HTTP request: $error');
    }
  } */

  /*  Future<void> _downloadAndInstallAPK(String apkUrl) async {
    final externalDir = await getExternalStorageDirectory();
    final taskId = await FlutterDownloader.enqueue(
      url: apkUrl,
      savedDir: externalDir!.path,
      showNotification: true,
      openFileFromNotification: true,
      saveInPublicStorage: true,
    );

   /*  FlutterDownloader.registerCallback((id, status, progress) {
      if (id == taskId) {
        if (status == DownloadTaskStatus.complete) {
          print('Download completed');
          showUpdateDialog(context, () {
            print('Opening and installing the APK');
            OpenFile.open('${externalDir.path}/camera_app_v0.0.6.apk');
          });
        } else if (status == DownloadTaskStatus.failed) {
          print('Download failed');
          // Handle download failure here
        }
      }
    }); */
  }
 */
  Future<String> getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<void> showUpdateDialog(
      BuildContext context, Function downloadAndInstallAPK) async {
    print('Before showing update dialog');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        print('Inside dialog builder');
        return AlertDialog(
          title: const Text('Update Available'),
          content: const Text(
              'A new version of the app is available. Do you want to download?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Download'),
              onPressed: () {
                print('Download button pressed');
                downloadAndInstallAPK();
                Navigator.of(context).pop();
                print('After popping dialog');
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                if (kDebugMode) {
                  print('Cancel button pressed');
                  print('After popping dialog');
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (kDebugMode) {
      print('After showing download dialog');
    }
  }
}
