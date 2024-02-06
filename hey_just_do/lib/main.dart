import 'dart:async';
import 'dart:math' as math;
import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hey_just_do/firebase_options.dart';
import 'package:flutter/services.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  //
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
  bool hae = false; //logo와 함께 간다
  bool _visible = true;

  bool _mission = false;
  bool _topSentence = false;
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
        //팡파레~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        child: Stack(
          children: [
            Visibility(
                visible: _mission2,
                child: Container(
                    alignment: Alignment.topCenter,
                    child: Lottie.asset('lottie/Pang.json')
                )
            ),
            //Q 팝업~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
            Container(
              alignment: Alignment.topRight,
              margin: EdgeInsets.all(25),
              child: InkWell(
                onTap: (){
                  setState(() {
                    myDialog(context);
                  });
                },
                child: Image.asset('images/Q.png')
              )
            ),
            //해 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~```
            Stack(
              children: <Widget>[
                AnimatedPositioned(
                  duration: const Duration(seconds: 1),
                  curve: Curves.fastOutSlowIn,
                  bottom: hae ? MediaQuery.of(context).size.height * 0.25 : MediaQuery.of(context).size.height * 0.015,
                  //left: MediaQuery.of(context).size.width * 0.2,
                  //right: MediaQuery.of(context).size.width * 0.2,
                  left: 50,
                  right: 50,
                  child: Container(
                      alignment: Alignment.center,
                      //width : MediaQuery.of(context).size.width / 1.2, height : MediaQuery.of(context).size.width / 1.2,
                      width : 370, height : 370,
                      decoration: BoxDecoration(color: Colors.orange,shape: BoxShape.circle,),
                  ),),
                //로고~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.fastOutSlowIn,
                  bottom: hae ? MediaQuery.of(context).size.height - 70 : MediaQuery.of(context).size.height - 250,
                  height: hae ? 50 : 90,
                  left: MediaQuery.of(context).size.width * 0.2,
                  right: MediaQuery.of(context).size.width * 0.2,
                  child: (
                    Image.asset('images/logo.png'))  //,width: 60, height: 60
                  )],
            ),
            //click 버튼 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            Container(
              margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.12),
              alignment: Alignment.center,
              child: Visibility(
                visible: _text4,
                child: TextButton(
                    onPressed: () {
                      setState(() {
                        _1pText1 = '~ 오늘의 그냥해 미션 ~';
                        _1pText2 = '붕어빵 먹고 하늘도 보고';
                        _1pText3 = '소소하지만 한 번 해봐';
                        _1pText4 = '';
                        _topSentence = true;
                        _text4 = false;
                        _mission = true;
                        hae = !hae;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, // 한번 눌러서 보라색으로 변한 글자/색상 변경
                      textStyle: const TextStyle(
                        fontFamily: "PreBd",
                        fontSize: 30.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                      alignment: Alignment.center,),
                      child: Text('click')),
              ),
            ),

            Column( //상단 문장 2개 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                children: [
                  Container(
                    //color: Colors.blue,
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Container(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.22,
                          left: 30,
                          right: 30
                      ),
                            child: AnimatedOpacity(
                                opacity: _topSentence ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 600),
                                child: Column(
                                  children: [
                                    Text(_1pText1, textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreRg", fontSize: 25, color: Colors.black,),),
                                    SizedBox(height:7),
                                    Text(_1pText2, textAlign: TextAlign.center, style: TextStyle(fontFamily: "Gangwon", fontSize: 60, height: 1.1, color: Colors.black,) ,)
                                  ]
                                ),
                            ),
                        ),
                    ),


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
                                                InkWell(
                                                  onTap: (){
                                                    setState(() {
                                                      _1pText1 = '카톡 작동중';
                                                    });
                                                  },
                                                  child: Image.asset('images/kakao.png',width: 60, height: 60),
                                                ),
                                                SizedBox(width:15),
                                                InkWell(
                                                  onTap: (){
                                                    setState(() {
                                                      _1pText1 = '트위터 작동중';
                                                    });
                                                  },
                                                  child: Image.asset('images/X.png',width: 60, height: 60),
                                                ),
                                                SizedBox(width:15),
                                                InkWell(
                                                  onTap: (){
                                                    setState(() {
                                                      _1pText1 = 'URL 작동중';
                                                    });
                                                  },
                                                  child: Image.asset('images/URL.png',width: 60, height: 60),
                                                ),

                                              ]),
                                              SizedBox(height:20),

                                              Text("다음 '그냥해'까지 "+'$now'+' 남음', textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreBd", fontSize: 15, color: Colors.black,),),
                                              SizedBox(height:5),
                                              Text('현재 '+'$entryCount'+' 명 참여중', textAlign: TextAlign.center, style: TextStyle(fontFamily: "PreRg", fontSize: 15, color: Colors.black,),),

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

                                                  _mission2 = true;
                                                  _mission = false;
                                                  _text42 = false;
                                                  BelowPadding = 0.05;//하단영역 Padding 조절
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                                textStyle: const TextStyle(
                                                  fontFamily: "PreRg",
                                                  fontSize: 28.0,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                                padding: EdgeInsets.symmetric(vertical: 23, horizontal: 80),
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

      ); //Body

  }}

void myDialog(context) { 
  showDialog(
    context: context,
    barrierDismissible: false, //다이로그 밖 선택시 팝업 안 닫히게
    builder: (context) {
      return Dialog(

        surfaceTintColor: Colors.white,

        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        // 그림자 높이 elevation: 50,

        insetPadding: const  EdgeInsets.fromLTRB(40,40,40,40),

        child: Container(
          width: 450,
          padding: EdgeInsets.all(35),
          //color: Colors.red,
          alignment: Alignment.center,
          child: SingleChildScrollView( child: Column(
            children: [
                Image.asset('images/face.png', width: 60),
                SizedBox(height: 5),
                Container(
                    padding: EdgeInsets.only(top:20),
                    alignment: Alignment.center,
                    child: const Column(
                        children: [
                          Text("새해만 되면 여기저기서 올라오는 갓생 인증글들 사이에서 불안함을 느꼈던 적이 있나요? 특히 올해의 ‘띠’라면 왠지 모르게 더 잘 살아야할 것만 같은 부담감이 장난 아니죠.", style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Colors.black,)),
                          SizedBox(height: 18),
                          Text("그냥해!는 용띠와 쥐띠가 뭉쳐 갓생러들 사이 '갓생이 아니어도 괜찮은' 이들을 위해 생겨났어요. 부담없이 소소한 미션들을 수행하며 작은 용기들을 얻어가셨으면 좋겠습니다.", style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Colors.black,)),
                          SizedBox(height: 18),
                          Text("미션들을 왜 해야하냐구요? 그냥 한 번 해보세요! 분명히 달라지실 거예요. 우리도 그랬으니까요 :)", style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Colors.black,))
                        ]
                    ),
                ),
                SizedBox(height: 25),
                Container(
                  //width: 380,
                    padding: EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Color(0xffFF9737).withOpacity(0.3), borderRadius: BorderRadius.circular(15)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text.rich(
                    TextSpan(
                      children: <TextSpan> [
                        TextSpan(
                            text: '· ', style: TextStyle(fontFamily: "PreBd", fontSize: 16, color: Colors.black, )
                        ),
                        TextSpan(
                            text: '매일 자정에 ', style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Colors.black)
                        ),
                        TextSpan(
                            text: '새로운 미션', style: TextStyle(fontFamily: "PreBd", fontSize: 16, color: Colors.black)
                        ),
                        TextSpan(
                            text: '이 공개돼요.', style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Colors.black)
                        ),
                      ], ), ),
                      SizedBox(height: 15),
                      Text.rich(
                        TextSpan(
                          children: <TextSpan> [
                            TextSpan(
                                text: '· 미션 수행 여부는 체크 NO!', style: TextStyle(fontFamily: "PreBd", fontSize: 16, color: Colors.black)
                            ),
                            TextSpan(
                                text: ' 혼자 또는 친구와 부담없이 미션을 수행해봐요.', style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Colors.black)
                            )
                          ], ), ),
                      SizedBox(height: 15),
                      Text.rich(
                        TextSpan(
                          children: <TextSpan> [
                            TextSpan(
                                text: '· 여러 번 ', style: TextStyle(fontFamily: "PreBd", fontSize: 16, color: Colors.black)
                            ),
                            TextSpan(
                                text: '미션에 참여하면 좋은 일이 생겨요.', style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Colors.black)
                            )
                          ], ), ),

                    ]
                  )
                ),
                SizedBox(height: 20),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
              )

          ],
        )       ),
        )
      );
    },
  );
}
