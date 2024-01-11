import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

Map<String, String> flowers_dict = {
  'astilbe': 'astilbe',
  'bellflower': 'clopoțel',
  'black_eyed_susan': 'susan cu ochi negri',
  'calendula': 'galbenele',
  'california_poppy': 'mac',
  'carnation': 'garoafă',
  'common_daisy': 'margareta',
  'coreopsis': 'coreopsis / ochiul fetei',
  'daffodil': 'narcisă',
  'dandelion': 'păpădie',
  'iris': 'iris',
  'magnolia': 'magnolie',
  'rose': 'trandafir',
  'sunflower': 'floarea soarelui',
  'tulip': 'lalea',
  'water_lily': 'nufăr',
};

Map<String, String> details_dict = {
  'astilbe':
      'Plante perene, cu flori mici, în formă de pană, de obicei de culoare roz sau alb.',
  'bellflower':
      'O floare cu forme variate, unele crescând în tufe, iar altele fiind mai solitare.',
  'black_eyed_susan': 'O floare cu petale galbene și un disc central închis.',
  'calendula':
      'O plantă medicinală și ornamentală, cu multe efecte benefice pentru organism.',
  'california_poppy':
      'O floare portocalie sau galbenă originară din California.',
  'carnation':
      'O floare populară, cultivată în numeroase culori, cu un miros plăcut.',
  'common_daisy':
      'O floare mică, cu petale albe și centru galben, întâlnită în multe regiuni.',
  'coreopsis':
      'O floare cu aspect asemănător cu al unei margarete, dar cu petale colorate în diferite nuanțe.',
  'daffodil':
      'O floare primăvăratică, cu petale galbene și un trompetă centrală.',
  'dandelion':
      'O floare cu florile galbene, cunoscute pentru pufuleții albi care sunt purtați de vânt.',
  'iris':
      'O floare cu petale colorate și forme variate, care crește din bulbi.',
  'magnolia':
      'Un arbore sau arbust ornamental, cunoscut pentru florile mari și parfumate.',
  'rose':
      'Una dintre cele mai populare flori, cu petale de diverse culori și un miros distinctiv.',
  'sunflower':
      'O floare cu inflorescențe mari, cu petale galbene dispuse într-o spirală caracteristică.',
  'tulip':
      'O floare iubită pentru diversitatea de culori și forme, cultivată din bulbi.',
  'water_lily':
      'O floare acvatică cu frunze mari, plasată pe suprafața apei, cu flori albe sau roz.',
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(cameras),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen(this.cameras, {super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  late Future<void> initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    initializeControllerFuture = controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String textDisplay = "Apasa butonul de captura!";
  String textDetails = " ";

  Future<void> _takePictureAndSend() async {
    try {
      setState(() {
        textDisplay = "Taking photo...";
      });

      await initializeControllerFuture;

      final XFile picture = await controller.takePicture();

      final File imageFile = File(picture.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(Uint8List.fromList(imageBytes));

      setState(() {
        textDisplay = "Sending photo...";
      });

      final response = await http.post(
        Uri.parse("http://resedintavieru.go.ro:63333/upload_image"),
        body: jsonEncode({"image": base64Image}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          textDisplay = flowers_dict[response.body] == null
              ? "Nesigur"
              : "Floarea detectata: ${flowers_dict[response.body]}";
          textDetails = details_dict[response.body] ?? " ";
        });
      } else {
        setState(() {
          textDisplay = "Error: ${response.statusCode} ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        textDisplay = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flower detection'),
      ),
      body: FutureBuilder<void>(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                CameraPreview(controller),
                Text(
                  textDisplay,
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  textDetails,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                )
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePictureAndSend,
        child: const Icon(Icons.camera),
      ),
    );
  }
}
