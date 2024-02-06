import 'dart:async';
import 'dart:math' as math;
import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_share.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hey_just_do/firebase_options.dart';
import 'package:flutter/services.dart';

final FeedTemplate defaultFeed = FeedTemplate(
  content: Content(
    title: '친구가 첫 번째 그냥해!를 시작했어요🌞',
    imageUrl: Uri.parse(
        'https://mud-kage.kakao.com/dn/Q2iNx/btqgeRgV54P/VLdBs9cvyn8BJXB3o7N8UK/kakaolink40_original.png'),
    description: '어떤 해인지 확인해볼까요?',
    link: Link(
        webUrl: Uri.parse('https://developers.kakao.com'),
        mobileWebUrl: Uri.parse('https://developers.kakao.com')),
  ),
  buttons: [
    Button(
      title: '확인하기',
      link: Link(
        webUrl: Uri.parse('https: //developers.kakao.com'),
        mobileWebUrl: Uri.parse('https: //developers.kakao.com'),
      ),
    ),
  ],
);

TimeOfDay getCurrentTime() {
  final DateTime now = DateTime.now();
  return TimeOfDay(hour: now.hour, minute: now.minute);
}

class DynamicTheme {

  static ThemeData getTheme() {
    final currentTime = getCurrentTime();
    // 오전 6시부터 저녁 5시 59분까지는 라이트 모드
    if (currentTime.hour >= 6 && currentTime.hour < 18) {
      return lightTheme;
    } else {
      // 나머지 시간은 다크 모드
      return darkTheme;
    }
  }

  static ThemeData toggleTheme(){
    if(getTheme() == darkTheme){return lightTheme;}
    else {return darkTheme;}
  }

  static final lightTheme = ThemeData(
      fontFamily: 'PreRg',
      colorScheme: const ColorScheme.light(
        background: Colors.white,
        primary: Color(0xFFFF9737),
        secondary: Colors.black,
        tertiary: Colors.black54,
        onPrimary: Colors.white,
        onBackground:Colors.black,
        onSecondary: Colors.white,
      ));

  static final darkTheme = ThemeData(
      colorScheme: const ColorScheme.dark(
        background: Color(0xFF44576E),
        primary: Color(0xFFC1C1C1),
        secondary: Colors.white,
        tertiary: Colors.white60,
        onBackground: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Color(0xFF44576E),
      ));
}

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
  KakaoSdk.init(
      javaScriptAppKey: 'a45ef9643128ef4def000227b1e86c8a'
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: FToastBuilder(),
      title: 'heyjustdo',
      theme: DynamicTheme.getTheme(),
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
  FToast fToast = FToast();
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

  String shareText = '친구가 첫 번째 그냥해!를 시작했어요🌞\n어떤 해인지 확인해볼까요?\n';
  final String appLink = 'hey-just-do.vercel.app';

  @override
  void initState() {
    super.initState();
    _loadUserEntryCount();
    readData();
    fToast.init(context);
  }

  _showToast(String message) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sunny, color: Theme.of(context).colorScheme.onPrimary),
          SizedBox(
            width: 12.0,
          ),
          Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 2),
    );
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
            if(userEntryCount > 1) {
              shareText = '친구가 $userEntryCount번째 그냥해!를 시작했어요🌞\n 어떤 해인지 확인해볼까요?\n';
            }
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


  void shareOnTwitter() async {
    Uri tweetUrl = Uri.parse('https://twitter.com/intent/tweet?text=$shareText&url=$appLink');

    if (!await launchUrl(tweetUrl)) {
      throw Exception('Could not launch twitter');
    }
  }

  void shareOnKakao() async {
    // 카카오톡 실행 가능 여부 확인
    bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();

    if (isKakaoTalkSharingAvailable) {
      try {
        Uri uri =
        await ShareClient.instance.shareDefault(template: defaultFeed);
        await ShareClient.instance.launchKakaoTalk(uri);
        print('카카오톡 공유 완료');
      } catch (error) {
        print('카카오톡 공유 실패 $error');
      }
    } else {
      try {
        Uri shareUrl = await WebSharerClient.instance
            .makeDefaultUrl(template: defaultFeed);
        await launchBrowserTab(shareUrl, popupOpen: true);
      } catch (error) {
        print('카카오톡 공유 실패 $error');
      }
    }
  }

  Future<void> shareClipBoard() async {
    await Clipboard.setData(ClipboardData(text: '$shareText$appLink'));
    _showToast("클립보드에 복사되었어요.");
  }

  @override
  Widget build(BuildContext context) {

    final now = DateTime.now();
    final remainingTime = DateTime(now.year, now.month, now.day + 1) // 다음날 00:00
        .difference(now);

    final hours = remainingTime.inHours;
    final minutes = (remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    final timeText = '$hours:$minutes:$seconds';

    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });

    return Scaffold(
      body: Container(
          height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
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
                child: Icon(Icons.help_outline, color:Theme.of(context).colorScheme.tertiary)
              )
            ),
            Stack(
              //해 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary,shape: BoxShape.circle,),
                    child: Visibility(
                      visible: Theme.of(context).brightness == Brightness.dark,
                      child: SvgPicture.asset('images/moon.svg'),
                    ),
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
                    SvgPicture.asset( Theme.of(context).brightness == Brightness.dark ? 'images/logo_dark.svg' : 'images/logo.svg'))  //,width: 60, height: 60
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
                          _1pText2 = '$todayMission';
                          _1pText3 = '소소하지만 한 번 해봐';
                          _1pText4 = '';
                          _topSentence = true;
                          _text4 = false;
                          _mission = true;
                          hae = !hae;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onPrimary, // 한번 눌러서 보라색으로 변한 글자/색상 변경
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
              ],),

            Column( //상단 문장 2개 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                children: [
                  Stack(
                      children: <Widget> [
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
                                  Text(_1pText1, textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: "PreRg", fontSize: 25, color: Theme.of(context).colorScheme.onBackground,),),
                                  const SizedBox(height:7),
                                  Text(_1pText2, textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: "Gangwon", fontSize: 60, height: 1.1, color: Theme.of(context).colorScheme.onBackground,) ,)
                                ]
                            ),
                          ),
                        ),
                      ),
                        //팡파레~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                      Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                        child: Visibility(
                            visible: _mission2,
                            child: Container(
                                alignment: Alignment.topCenter,
                                child: Lottie.asset('lottie/Pang.json')
                            )
                        ),
                      ),
                      ]),
                                                                                      // ],
                  Stack(
                      children: <Widget> [                                                         //),
                   //,width: 60, height: 60

                      // 해 위에 있는 흰박스+검은선~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
                      Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        margin: EdgeInsets.all(0), /*color: Colors.red,*/
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom:0),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.background,
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
                                              Text(_1pText3, textAlign: TextAlign.center,
                                                style: TextStyle(fontFamily: "PreRg", fontSize: 15, color: Theme.of(context).colorScheme.onBackground,),),
                                              SizedBox(height:7)
                                            ]
                                        ),
                                      ),
                                      Visibility(
                                          visible: _text4,
                                          child:
                                          Text(_1pText4, textAlign: TextAlign.center,
                                            style: TextStyle(fontFamily: "PreRg", fontSize: 27, color: Theme.of(context).colorScheme.onBackground,),)
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
                                                    shareOnKakao();
                                                    setState(() {
                                                      _1pText1 = '카톡 작동중';
                                                    });
                                                  },
                                                  child: Image.asset('images/kakao.png',width: 60, height: 60),
                                                ),
                                                SizedBox(width:15),
                                                InkWell(
                                                  onTap: (){
                                                    shareOnTwitter();
                                                    setState(() {
                                                      _1pText1 = '트위터 작동중';
                                                    });
                                                  },
                                                  child: Image.asset('images/X.png',width: 60, height: 60),
                                                ),
                                                SizedBox(width:15),
                                                InkWell(
                                                  onTap: (){
                                                    shareClipBoard();
                                                    setState(() {
                                                      _1pText1 = 'URL 작동중';
                                                    });
                                                  },
                                                  child: Image.asset('images/URL.png',width: 60, height: 60),
                                                ),

                                              ]),
                                              SizedBox(height:20),

                                              Text("다음 '그냥해'까지 $timeText 남음", textAlign: TextAlign.center,
                                                style: TextStyle(fontFamily: "PreBd", fontSize: 15, color: Theme.of(context).colorScheme.onBackground,),),
                                              SizedBox(height:5),
                                              Text('현재 $entryCount명 참여중', textAlign: TextAlign.center,
                                                style: TextStyle(fontFamily: "PreRg", fontSize: 15, color: Theme.of(context).colorScheme.onBackground,),),

                                            ]

                                        ),
                                      ),
                                      // 미션 시작 버튼 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
                                      Visibility(
                                        visible: _mission,
                                        child: (
                                            ElevatedButton(
                                              onPressed: () {
                                                participate();
                                                setState(() {

                                                  _mission2 = true;
                                                  _mission = false;
                                                  _text42 = false;
                                                  BelowPadding = 0.05;//하단영역 Padding 조절
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                                foregroundColor: Theme.of(context).colorScheme.onSecondary,
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
                      ),                        ]),
                    ],
                  ),
                ]
            )
        )
      ); //Body
  }}
//팝업~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
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
          padding: const EdgeInsets.all(35),
          alignment: Alignment.center,
          child: SingleChildScrollView( child: Column(
            children: [
                SvgPicture.asset('images/face.svg', width: 60),
                const SizedBox(height: 5),
                Container(
                    padding: const EdgeInsets.only(top:20),
                    alignment: Alignment.center,
                    child: Column(
                        children: [
                          Text("새해만 되면 여기저기서 올라오는 갓생 인증글들 사이에서 불안함을 느꼈던 적이 있나요? 특히 올해의 ‘띠’라면 왠지 모르게 더 잘 살아야할 것만 같은 부담감이 장난 아니죠.",
                              style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Theme.of(context).colorScheme.onBackground,)),
                          const SizedBox(height: 18),
                          Text("그냥해!는 용띠와 쥐띠가 뭉쳐 갓생러들 사이 '갓생이 아니어도 괜찮은' 이들을 위해 생겨났어요. 부담없이 소소한 미션들을 수행하며 작은 용기들을 얻어가셨으면 좋겠습니다.",
                              style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Theme.of(context).colorScheme.onBackground,)),
                          const SizedBox(height: 18),
                          Text("미션들을 왜 해야하냐구요? 그냥 한 번 해보세요! 분명히 달라지실 거예요. 우리도 그랬으니까요 :)",
                              style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Theme.of(context).colorScheme.onBackground,))
                        ]
                    ),
                ),
                const SizedBox(height: 25),
                Container(
                  //width: 380,
                    padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text.rich(
                    TextSpan(
                      children: const <TextSpan> [
                        TextSpan(
                            text: '· ', style: TextStyle(fontFamily: "PreBd")),
                        TextSpan(
                            text: '매일 자정에 '),
                        TextSpan(
                            text: '새로운 미션', style: TextStyle(fontFamily: "PreBd")),
                        TextSpan(
                            text: '이 공개돼요.'),
                      ],
                    style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Theme.of(context).colorScheme.onBackground)), ),
                      const SizedBox(height: 15),
                      Text.rich(
                        TextSpan(
                          children: const <TextSpan> [
                            TextSpan(
                                text: '· 미션 수행 여부는 체크 NO!', style: TextStyle(fontFamily: "PreBd")
                            ),
                            TextSpan(
                                text: ' 혼자 또는 친구와 부담없이 미션을 수행해봐요.')
                          ],
                            style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Theme.of(context).colorScheme.onBackground)
                        ), ),
                      const SizedBox(height: 15),
                      Text.rich(
                        TextSpan(
                          children: const <TextSpan> [
                            TextSpan(
                                text: '· 여러 번 ', style: TextStyle(fontFamily: "PreBd")
                            ),
                            TextSpan(
                                text: '미션에 참여하면 좋은 일이 생길지도?' )
                          ],
                            style: TextStyle(fontFamily: "PreRd", fontSize: 16, color: Theme.of(context).colorScheme.onBackground)), ),
                    ]
                  )
                ),
                const SizedBox(height: 20),
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
