import 'dart:async';
import 'dart:math' as math;
import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hey_just_do/firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'heyjustdo',
      theme: ThemeData(
        fontFamily: 'PreRg'
      ),
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
  String? currentId;
  String? todayMission;
  int? entryCount;
  int userEntryCount = 0;

  var _1pText1 = '소소하든 중대하든';
  var _1pText2 = '그냥해!';
  var _1pText3 = '오늘의 해는 어떤해?';
  var _1pText4 = '해를 클릭해서 확인해!';
  bool _mission = false;
  bool _text4 = true;
  bool _mission2 = false;
  bool _text42 = true;
  var BelowPadding = 0.12;
  var now = new DateTime.now();
  //String formatDate = DateFormat('yy/MM/dd - HH:mm:ss').format(now);

  @override
  void initState() {
    super.initState();
    _loadUserEntryCount();
    readData();
  }

  void _loadUserEntryCount() {
    final cookieString = html.window.document.cookie;
    final storedEntryCount = cookieString?.split(';')
        .firstWhere((cookie) => cookie.trim().startsWith('userEntryCount='),
        orElse: () => '')
        .split('=')
        .last;

    if (storedEntryCount != null && storedEntryCount.isNotEmpty) {
      setState(() {
        userEntryCount = int.parse(storedEntryCount);
      });
    }
  }


  void readData() {
    final missionsCollectionReference = FirebaseFirestore.instance.collection("missions");

    missionsCollectionReference
        .orderBy(FieldPath.documentId)
        .limit(1)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          todayMission = querySnapshot.docs.first.data()?['mission'];
          entryCount = querySnapshot.docs.first.data()?['entryCount'];
          currentId = querySnapshot.docs.first.id;
        });
      } else {
        print('No data available');
      }
    });
  }

  void getNextData() {
    if (currentId != null) {
      final missionsCollectionReference = FirebaseFirestore.instance.collection("missions");

      missionsCollectionReference
          .where(FieldPath.documentId, isGreaterThan: currentId!)
          .orderBy(FieldPath.documentId)
          .limit(1)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            todayMission = querySnapshot.docs.first.data()?['mission'];
            entryCount = querySnapshot.docs.first.data()?['entryCount'];
            currentId = querySnapshot.docs.first.id;
          });
        } else {
          print('No more data available');
        }
      });
    }
  }

  void participate() {
    final missionsCollectionReference = FirebaseFirestore.instance.collection("missions");

    missionsCollectionReference.doc(currentId).get().then((documentSnapshot) {
      if (documentSnapshot.exists) {
        entryCount = documentSnapshot.data()?['entryCount'] ?? 0;
        missionsCollectionReference.doc(currentId).update({
          'entryCount': FieldValue.increment(1),
        }).then((value) {
          setState(() {
            userEntryCount++;
            entryCount = (entryCount ?? 0) + 1;
          });
          final expirationDate = DateTime.now().add(Duration(days: 100));
          html.window.document.cookie = 'userEntryCount=$userEntryCount;expires=$expirationDate';

        }).catchError((error) {
          print("Failed to update entryCount: $error");
        });
      } else {
        print("Document does not exist");
      }
    }).catchError((error) {
      print("Failed to get current entryCount: $error");
    });
  }

  // double screenHeight = MediaQuery.of(context).size.height;  // 화면 높이

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        body: Container(
            height: MediaQuery.of(context).size.height,
            child: Stack(
                children: [
                  Container(
                    //해 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~```
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.45,
                        left: MediaQuery.of(context).size.width * 0.2,
                        right: MediaQuery.of(context).size.width * 0.2
                    ),
                    width : MediaQuery.of(context).size.width / 1.5, height : MediaQuery.of(context).size.width / 1.5, decoration: BoxDecoration(color: Colors.orange,shape: BoxShape.circle,),),
                  //click 버튼 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  Container(
                      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.4 - 200.0),
                      alignment: Alignment.center,
                      child: Visibility(
                        visible: _text4,
                        child: TextButton(
                            onPressed: () {
                              setState(() {
                                _1pText1 = '~ 오늘의 그냥해 미션 ~';
                                _1pText2 = '$todayMission';
                                _1pText3 = '소소하지만 한번 해봐';
                                _1pText4 = '';
                                _text4 = false;
                                _mission = true;
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black, // 한번 눌러서 보라색으로 변한 글자/색상 변경
                              textStyle: const TextStyle(
                                fontFamily: "Gangwon",
                                fontSize: 30.0,
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                              ),
                              alignment: Alignment.center,),
                            child: Text('click')),
                      )
                  ),
                  //상단 문장 2개 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
                  Column(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Container(
                          // color: Colors.blue,
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.2,
                              left: 10,
                              right: 10
                          ),
                          child: Column(
                            children: [
                              Text(_1pText1, textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreBd", fontSize: 20, color: Colors.black,),),
                              SizedBox(height:7),
                              Text(_1pText2, textAlign: TextAlign.center, style: TextStyle(fontFamily: "Gangwon", fontSize: 60, height: 1.1, color: Colors.black,) ,),],
                          ),),),

                      // 해 위에 있는 흰박스+검은선~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
                      Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        margin: EdgeInsets.all(0), /*color: Colors.red,*/
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom:0),
                              decoration: const BoxDecoration(color: Colors.white,
                                  border: Border(top: BorderSide(color: Colors.black, width:1),)),),

                            // 하단 영역 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            Container(
                                child: Container(
                                  // color: Colors.red,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * BelowPadding),
                                  child: Column(
                                    // 하단 문장 2개 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                    children: [
                                      Visibility(
                                        visible: _text42,
                                        child: Column(
                                            children: [
                                              Text(_1pText3, textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreRg", fontSize: 15, color: Colors.grey,),),
                                              SizedBox(height:7)
                                            ]
                                        ),
                                      ),
                                      Visibility(
                                          visible: _text4,
                                          child:
                                          Text(_1pText4, textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreRg", fontSize: 27, color: Colors.black,),)
                                      ), // 3번째 페이지 하단 글자 및 임시 버튼 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
                                      Visibility(
                                        visible: _mission2,
                                        child: Column(
                                            children: [
                                              Text('$userEntryCount번째 해보기 성공!', textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreRg", fontSize: 25, color: Colors.black,),),
                                              SizedBox(height:20),
                                              Row( mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                                                ElevatedButton(
                                                    onPressed: (){
                                                      setState(() {
                                                        _1pText1 = '카톡 작동예정';
                                                      });
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.grey,
                                                      foregroundColor: Colors.white,
                                                      shape: CircleBorder(),
                                                      padding: const EdgeInsets.symmetric(vertical:40, horizontal: 40),
                                                      alignment: Alignment.center,),
                                                    child: const Text('카톡')),
                                                ElevatedButton(
                                                    onPressed: (){
                                                      setState(() {
                                                        _1pText1 = '트위터 작동예정!';
                                                      });
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.grey,
                                                      foregroundColor: Colors.white,
                                                      shape: CircleBorder(),
                                                      padding: const EdgeInsets.symmetric(vertical:40, horizontal: 40),
                                                      alignment: Alignment.center,),
                                                    child: const Text('트위터')),
                                                ElevatedButton(
                                                    onPressed: (){
                                                      setState(() {
                                                        _1pText1 = 'URL 작동중';
                                                      });
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.grey,
                                                      foregroundColor: Colors.white,
                                                      shape: CircleBorder(),
                                                      padding: const EdgeInsets.symmetric(vertical:40, horizontal: 40),
                                                      alignment: Alignment.center,),
                                                    child: const Text('URL'))
                                              ]),
                                              SizedBox(height:20),
                                              Row( mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                                                Text('현재 ', textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreRg", fontSize: 15, color: Colors.black,),),
                                                Text('$entryCount', textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreRg", fontSize: 15, color: Colors.black,),),
                                                Text(' 명 참여중', textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreRg", fontSize: 15, color: Colors.black,),)
                                              ]),
                                              SizedBox(height:5),
                                              Row( mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                                                Text("다음 '그냥해'까지 ", textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreBd", fontSize: 15, color: Colors.black,),),
                                                Text('$now', textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreBd", fontSize: 15, color: Colors.black,),),
                                                Text(' 남음', textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreBd", fontSize: 15, color: Colors.black,),)
                                              ])
                                            ]

                                        ),
                                      ),
                                      // 미션 시작 버튼 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
                                      Visibility(
                                        visible: _mission,
                                        child: (
                                            ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    participate();
                                                    _1pText1 = '~ 그냥해 시작을 축하해! ~';
                                                    _1pText3 = '친구에게 그냥해 공유하기';
                                                    _mission2 = true;
                                                    _mission = false;
                                                    _text42 = false;
                                                    BelowPadding = 0.05; //하단영역 Padding 조절
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.black,
                                                  foregroundColor: Colors.white,
                                                  textStyle: const TextStyle(
                                                    fontFamily: "Gangwon",
                                                    fontSize: 30.0,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                  padding: EdgeInsets.symmetric(vertical: 25, horizontal: 60),
                                                  alignment: Alignment.center,),
                                                child: Text('미션 시작'))
                                        ),
                                      )
                                    ],

                                  ),
                                )
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]
            )
        )
    );
  }}