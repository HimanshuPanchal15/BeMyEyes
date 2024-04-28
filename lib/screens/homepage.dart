import 'dart:io';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../constants/constants.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  int i = 0;
  @override
  void initState() {
    super.initState();
    // Bind listener

    PerfectVolumeControl.stream.listen((value) {
      print(i);
      i++;
      if (i % 3 == 0) {
        _pickImage();
      }
    });
  }

  final apiService = ApiService();
  File? _selectedImage;
  String diseaseName = '';
  String old = '';
  String diseasePrecautions = '';
  bool detecting = false;
  bool precautionLoading = false;

  Future<void> _pickImage() async {
    final camera = (await availableCameras()).first;
    final controller = CameraController(camera, ResolutionPreset.low);
    await controller.initialize();
    await controller.setFlashMode(FlashMode.off);
    final pickedFile = await controller.takePicture();
    setState(() {
      _selectedImage = File(pickedFile.path);
      detectDisease();
    });
    }

  detectDisease() async {
    setState(() {
      detecting = true;
    });
    try {
      diseaseName =
      await apiService.sendImageToGPT4Vision(image: _selectedImage!);
    } catch (error) {
      _showErrorSnackBar(error);
    } finally {
      setState(() {
        detecting = false;
      });
    }
  }

  showPrecautions() async {
    setState(() {
      precautionLoading = true;
    });
    try {
      if (diseasePrecautions == '') {
        diseasePrecautions =
        await apiService.sendMessageGPT(diseaseName: diseaseName);
      }
      _showSuccessDialog(diseaseName, diseasePrecautions);
    } catch (error) {
      _showErrorSnackBar(error);
    } finally {
      setState(() {
        precautionLoading = false;
      });
    }
  }

  void _showErrorSnackBar(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error.toString()),
      backgroundColor: Colors.red,
    ));
  }

  void _showSuccessDialog(String title, String content) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      title: title,
      desc: content,
      btnOkText: 'Got it',
      btnOkColor: themeColor,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.black, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            const Stack(
              children: [],
            ),
            _selectedImage == null
                ? SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Image.asset('assets/images/pick.jpeg'),
            )
                : Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              decoration:
              BoxDecoration(borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.fromLTRB(20.0,
                  MediaQuery.of(context).size.height * 0.1, 20.0, 20.0),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            if (_selectedImage != null)
              detecting
                  ? SpinKitWave(
                color: themeColor,
                size: 30,
              )
                  : Column(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.2,
                    padding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DefaultTextStyle(
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 30),
                          child: AnimatedTextKit(
                              isRepeatingAnimation: false,
                              repeatForever: false,
                              displayFullTextOnTap: true,
                              totalRepeatCount: 1,
                              animatedTexts: [
                                TyperAnimatedText(
                                  diseaseName.trim(),
                                ),
                              ]),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}