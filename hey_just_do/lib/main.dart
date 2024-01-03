import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'heyjustdo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String feedbackText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Button Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 50, // 고정 높이
              color: Colors.black,
            ),
            Text(
              feedbackText,
              style: TextStyle(fontSize: 20),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // 랜덤하게 'good', 'bad', 'soso' 중 하나의 텍스트를 선택
                  final List<String> feedbackOptions = ['good', 'bad', 'soso'];
                  feedbackText = feedbackOptions[DateTime.now().microsecondsSinceEpoch % 3];
                });
              },
              child: Text('Button'),
            ),
          ],
        ),
      ),
    );
  }
}
