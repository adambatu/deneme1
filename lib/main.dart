import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return const MaterialApp(
      home: ImageQuiz(),
    );
  }
}

class ImageQuiz extends StatefulWidget {
  const ImageQuiz({Key? key}) : super(key: key);

  @override
  _ImageQuizState createState() => _ImageQuizState();
}

class _ImageQuizState extends State<ImageQuiz> with SingleTickerProviderStateMixin {
  List<String> images = ['images/at.jpg', 'images/avrat.jpg', 'images/silah.jpg'];
  List<String> names = ['at', 'avrat', 'silah'];
  int currentIndex = 0;
  Color screenColor = Colors.transparent;
  late AnimationController _animationController;

  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speechToText = stt.SpeechToText();

  bool isNotListening = true;
  bool _userEnded = false;
  bool _cancelOnError = false;

  void _onNotifyError(dynamic error) {
    if (isNotListening && _userEnded) {
      return;
    }
    print('Speech Recognition Error: $error');
    setState(() {
      screenColor = Colors.blue;
      currentIndex = 0; // Reset to first image if there is an error
    });
    _animationController.forward().then((value) => _animationController.reverse());
    askQuestion();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Image.asset(
            images[currentIndex],
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.center,
          ),
          FadeTransition(
            opacity: _animationController,
            child: Container(color: screenColor),
          ),
          Visibility(
            visible: currentIndex == 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: currentIndex == 0 ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: ElevatedButton(
                  child: const Text('Start Game'),
                  onPressed: currentIndex == 0 ? askQuestion : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void startListening() async {
    bool available = await speechToText.initialize(
      onStatus: (status) {
        if (status == 'done') {
          processVoiceInput();
        }
      },
      onError: (error) => print('Error: $error'),
    );

    if (available) {
      speechToText.listen(localeId: 'tr_TR', listenFor: Duration(seconds: 5));
      await Future.delayed(Duration(seconds: 10)); // Timer'ı beklemek için await kullandım
      stopListening();
      setState(() {
        screenColor = Colors.red;
      });
      _animationController.forward().then((value) => _animationController.reverse());
      processVoiceInput(); // Cevabı kontrol et
    }
  }

  void stopListening() async {
    if (speechToText.isListening) {
      await speechToText.stop();
    }
  }

  void processVoiceInput() {
    if (speechToText.lastRecognizedWords.toLowerCase() == names[currentIndex].toLowerCase()) {
      setState(() {
        currentIndex++;
        screenColor = Colors.green;
      });
      _animationController.forward().then((value) => _animationController.reverse());
      if (currentIndex < images.length) {
        askQuestion();
      } else {
        showResults(); // Oyun bitti, sonuçları göster
      }
    } else {
      setState(() {
        screenColor = Colors.red;
        currentIndex = 0; // Reset to first image if the answer was incorrect
      });
      _animationController.forward().then((value) => _animationController.reverse());
      askQuestion();
    }
  }

  void showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Oyun Bitti'),
          content: Text('Tebrikler! Oyunu tamamladınız.'),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  void askQuestion() async {
    setState(() {
      currentIndex = 0; // Reset to first image when asking a new question
      screenColor = Colors.transparent;
    });
    await flutterTts.setLanguage('tr-TR');
    await flutterTts.speak('Karşındaki resmin ismi nedir?');
    startListening();
  }
}