import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SpeakToTextPage(),
    );
  }
}

class SpeakToTextPage extends StatefulWidget {
  const SpeakToTextPage({super.key});

  @override
  State<SpeakToTextPage> createState() => _SpeakToTextPageState();
}

class _SpeakToTextPageState extends State<SpeakToTextPage> {
  FlutterSoundRecorder? _recorder; // object to manage recording
  bool isRecording = false; // Flag to check if recording is ongoing;
  String? _filePath; //path where the recorded file is saved
  String _transcription="";
  bool _isLoading=false;

  @override
  void initState() {
    super.initState();
    // initializs recorded when the app Start
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    final status =
        await Permission.microphone.request(); // Request microphone access
    if (status != PermissionStatus.granted) {
      throw Exception(
        ' Microphone permission not granted',
      ); // throw error if permission denied
    }
    await _recorder!.openRecorder(); // open the recorder
  }

  //Start Recording audio
  Future<void> _startRecording() async {
    final tempDir = await getTemporaryDirectory(); // Get temporary directory
    _filePath =
        '${tempDir.path}/recording.m4a'; //Set file path for saving recording

    await _recorder!.startRecorder(toFile: _filePath, codec: Codec.aacMP4);

    setState(() {
      isRecording = true;
      _transcription="";
    });
  }

  // Stop recording audio

  Future<void> _stopRecording() async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Small delay to ensure file save correctly
    await _recorder!.stopRecorder();
    setState(() {
      isRecording = false; //update recording status to false
    });
    if (_filePath != null) {
      // if exists, send it for transcription
      await _sendToWhisper(_filePath!);
    }
  }

  //
  Future<void> _sendToWhisper(String path) async {
    setState(() {
      _isLoading=true;
    });
    String _apiKey =
        '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';
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
          )
          ..headers['Authorization'] = 'Bearer $_apiKey'
          ..files.add(
            await http.MultipartFile.fromPath('file', path),
          ) // Add recorded File
          ..fields['model'] = 'whisper-1'; //Using whisper model
          try{
    final response = await request.send(); // Sent HTTP request
    final responseBody =
        await response.stream.bytesToString(); // Get response body as String
    final decoded = json.decode(responseBody);
    setState(() {
      _transcription =decoded['text']??"Transcription Error";
      _isLoading=false;

    });
          }catch (e){
            setState(() {
              _transcription="Failed to transcribe. try again.";
              _isLoading=false;
            });
          }
   
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text("Voice Assistant"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 40,
              child:
                  isRecording
                      ? LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.green,
                        size: 80,
                      )
                      : SizedBox(height: 40),
            ),
            SizedBox(height: 30),
            Text(
              'Transcription:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 20),
            if(_isLoading)
            LoadingAnimationWidget.threeRotatingDots(color: Colors.blue,size: 60)
            else
             Container(
              padding:  EdgeInsets.all(16),
              margin:  EdgeInsets.symmetric(
                horizontal: 10
              ),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)
              ,
              color: Colors.grey[200]),
              child: Text(_transcription,textAlign: TextAlign.center,style: TextStyle(fontSize: 16),)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          isRecording ? _stopRecording() : _startRecording();
        },
        tooltip: 'Mic',
        child: Icon(isRecording ? Icons.mic : Icons.mic_off),
      ),
    );
  }
}
