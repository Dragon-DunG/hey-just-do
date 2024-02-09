import 'dart:async';
import 'dart:math';
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
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hey_just_do/firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


int calculateDaysSince(DateTime startDate) {
  DateTime today = DateTime.now();
  Duration difference = today.difference(startDate);
  return difference.inDays;
}

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
        primary: Color(0xFFD0D0D0),
        secondary: Colors.white,
        tertiary: Colors.white60,
        onBackground: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Color(0xFF44576E),
      ));
}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
      javaScriptAppKey: "a45ef9643128ef4def000227b1e86c8a",
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: FToastBuilder(),
      title: '그냥해!',
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
  DateTime startDate = DateTime(2024, 2, 8);
  late DateTime _lastParticipationDate;
  late bool _hasParticipatedToday;
  late int _todayMissionNumber;
  int userEntryCount = 0;

  FToast fToast = FToast();
  String feedbackText = '';
  String? currentId;
  String? todayMission = '오늘의 미션은?';
  int? entryCount = 0;

  var _1pText1 = '소소하든 중대하든';
  var _1pText2 = '그냥해!';
  var _1pText3 = '오늘의 해는 어떤해?';
  var _1pText4 = '해를 클릭해서 확인해!';
  bool hae = false; //logo와 함께 간다

  bool _mission = false;
  bool _topSentence = false;
  bool _text4 = false;
  bool _mission2 = false;
  bool _text42 = true;
  bool _isButtonClicked = false;

  var BelowPadding = 0.12;

  String shareTextA = '친구가 첫 번째 그냥해!를 시작했어요🌞';
  String shareTextB = '나의 그냥해!는 어떤 해일까요?';
  final String appLink = 'hey-just-do.xyz';

  @override
  void initState() {
    super.initState();
    _initializeLastParticipationDate();
    _updateLastParticipationDate();
    _loadUserEntryCount();
    _setInitialData(calculateDaysSince(startDate));
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
          Icon(Icons.sunny, color: Theme.of(context).colorScheme.onSecondary),
          SizedBox(
            width: 12.0,
          ),
          Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),),
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

    final storedParticipationStatus = cookieString
        ?.split(';')
        .firstWhere((cookie) => cookie.trim().startsWith('hasParticipatedToday='),
        orElse: () => '');

    if (storedEntryCount != null && storedEntryCount.isNotEmpty) {
      setState(() {
        userEntryCount = int.parse(storedEntryCount);
      });
    }
    if (storedParticipationStatus!.isNotEmpty) {
      final hasParticipatedToday = storedParticipationStatus.split('=').last;
      setState(() {
        _hasParticipatedToday = hasParticipatedToday.toLowerCase() == 'true';
      });
    }
  }

  void _initializeLastParticipationDate() {
    final cookieValue = html.window.document.cookie
        ?.split('; ')
        .firstWhere((element) => element.startsWith('lastParticipationDate='),
        orElse: () => '')
        .split('=')
        .last;
    final lastParticipationDateString =
    cookieValue!.isNotEmpty ? cookieValue : '2000-01-01';
    setState(() {
      _lastParticipationDate = DateTime.parse(lastParticipationDateString);
      _hasParticipatedToday =
          DateTime.now().difference(_lastParticipationDate).inDays == 0;
    });
  }

  void _updateLastParticipationDate() {
    final now = DateTime.now();
    if (now.difference(_lastParticipationDate).inDays >= 1) {
      // Reset entry count and last participation date if a new day has started
      setState(() {
        _lastParticipationDate = DateTime(now.year, now.month, now.day);
        _hasParticipatedToday = false;
      });
      html.window.document.cookie =
      'lastParticipationDate=${_lastParticipationDate.toIso8601String()};expires=${DateTime(now.year, now.month, now.day + 1).toUtc()}';
      html.window.document.cookie =
      'hasParticipatedToday=false;expires=${DateTime(now.year, now.month, now.day + 1).toUtc()}';
    }
  }

  void getData(int number) {
    final missionsCollectionReference = FirebaseFirestore.instance.collection("missionList");

    missionsCollectionReference
        .where('number', isEqualTo: number)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          todayMission = querySnapshot.docs.first.data()?['mission'];
          currentId = querySnapshot.docs.first.id;
          missionsCollectionReference.doc("TodayEntryCount").get()
              .then((entryCountSnapshot) {
            if(entryCountSnapshot.exists) {
              entryCount =
              entryCountSnapshot.data()?[DateFormat('yyyy-MM-dd').format(
                  DateTime.now())];
              if (entryCount == null) {
                print('EntryCount Document does not exist');
              }
            }
          }).catchError((error) {
            print('Failed to get entryCount: $error');
          });
          if(_hasParticipatedToday){
            _1pText1 = '~ 오늘의 그냥해 미션 ~';
            _1pText2 = '$todayMission';
            hae = true;
            _mission = false;
            _topSentence = true;
            _text4 = false;
            _mission2 = true;
            _text42 = false;
            _isButtonClicked = false;
            BelowPadding = 0.05;
          }
        });
      } else {
        print('No data available');
      }
    });
  }

  void _setInitialData(int number) {
    final missionsCollectionReference = FirebaseFirestore.instance.collection("missionList");
    final now = DateTime.now();
    late int randomNumber;
    late int missionNumber;

    final storedRandomNumber = html.window.document.cookie
        ?.split(';')
        .firstWhere(
          (cookie) => cookie.trim().startsWith('TodayMissionNumber='),
      orElse: () => '',
    )
        .split('=')
        .last;

    print(storedRandomNumber);
    if(!_hasParticipatedToday){ _text4 = true; }

    if (storedRandomNumber != null && storedRandomNumber.isNotEmpty) {
      missionNumber = int.parse(storedRandomNumber);
      getData(missionNumber);
    } else {
      missionsCollectionReference.get().then((querySnapshot) {
        int totalDocuments = querySnapshot.docs.length;
        List<int> storedNumbers = [];

        final cookieString = html.window.document.cookie;
        if (cookieString != null ) {
          final storedCookie = cookieString.split(';').firstWhere(
                  (cookie) => cookie.trim().startsWith('randomNumbers='),
              orElse: () => ''
          );
          if (storedCookie.isNotEmpty) {
            storedNumbers = storedCookie.split('=')[1].split(',')
                .map((e) => int.parse(e))
                .toList();
          }
        }
        // Generate a random number within the range of totalDocuments
        List<int> availableNumbers = List.generate(totalDocuments - 1, (index) => index + 1)
            .where((num) => !storedNumbers.contains(num))
            .toList();
        Random random = Random();
        randomNumber = availableNumbers[random.nextInt(availableNumbers.length)];
        storedNumbers.add(randomNumber);
        html.window.document.cookie = 'randomNumbers=${storedNumbers.join(',')};expires=${DateTime(now.year, now.month, now.day + 100).toUtc()}';
        html.window.document.cookie = 'TodayMissionNumber=$randomNumber;expires=${DateTime(now.year, now.month, now.day + 1).toUtc()}';
        missionNumber = randomNumber;
        getData(missionNumber);
      }).catchError((error) {
        print('Failed to get total document count: $error');
      });
    }
    }


  void participate() {
    final missionsCollectionReference = FirebaseFirestore.instance.collection("missionList");
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    missionsCollectionReference.doc("TodayEntryCount").get().then((documentSnapshot) {
      if (documentSnapshot.exists) {
        entryCount = documentSnapshot.data()?[todayDate] ?? 0;
        missionsCollectionReference.doc("TodayEntryCount").update({
          '$todayDate': FieldValue.increment(1),
        }).then((value) {
          setState(() {
            userEntryCount++;
            _hasParticipatedToday = true;
            entryCount = (entryCount ?? 0) + 1;
          });
          final expirationDate = DateTime.now().add(Duration(days: 100));
          html.window.document.cookie = 'userEntryCount=$userEntryCount;expires=$expirationDate';
          html.window.document.cookie = 'hasParticipatedToday=true;expires=$expirationDate';

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

  String setShareText() {
    String returnText;
    if(userEntryCount > 1) {
      returnText = '친구가 $userEntryCount번째 그냥해!를 시작했어요🌞';
    } else {returnText = '친구가 첫 번째 그냥해!를 시작했어요🌞';}
    return returnText;
  }

  // double screenHeight = MediaQuery.of(context).size.height;  // 화면 높이
  void shareOnTwitter() async {
    String shareText = '${setShareText()}\n[ 친구의 미션 : $todayMission ]\n\n$shareTextB\n';
    Uri tweetUrl = Uri.parse('https://twitter.com/intent/tweet?text=$shareText&url=$appLink');

    if (!await launchUrl(tweetUrl)) {
      throw Exception('Could not launch twitter');
    }
  }

  Future<void> shareClipBoard() async {
    String shareText = '${setShareText()}\n[ 친구의 미션 : $todayMission ]\n\n$shareTextB\n';
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

    final FeedTemplate defaultFeed = FeedTemplate(
      content: Content(
        title: setShareText(),
        imageUrl: Uri.parse(
            'https://firebasestorage.googleapis.com/v0/b/hey-just-do.appspot.com/o/kakaoShareImage2.png?alt=media&token=b40597a1-bd32-4782-ac58-c2fe8f2c39c8'),
        description: '[ 친구의 미션 : $todayMission ]',
        link: Link(
            webUrl: Uri.parse('https://developers.kakao.com'),
            mobileWebUrl: Uri.parse('https://developers.kakao.com')),
      ),
      buttons: [
        Button(
          title: '나의 그냥해!는 어떤 해일까요?',
          link: Link(
            webUrl: Uri.parse('https://developers.kakao.com'),
            mobileWebUrl: Uri.parse('https://developers.kakao.com'),
          ),
        ),
      ],
    );

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
                          _text42 = !_hasParticipatedToday;
                          _mission = !_hasParticipatedToday;
                          _mission2 = _hasParticipatedToday;
                          if(_hasParticipatedToday) {BelowPadding = 0.05;}
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
                        alignment: Alignment.center,
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
                                    style: TextStyle(fontFamily: "Gangwon",
                                      fontSize: _1pText2.length < 10 ? 60 : _1pText2.length < 12 ? 54 : 48,
                                      height: 1.1, color: Theme.of(context).colorScheme.onBackground,) ,)
                                ]
                            ),
                          ),
                        ),
                      ),
                        //팡파레~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                      Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                        child: Visibility(
                            visible: _mission2 && _isButtonClicked,
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
                                              Text('$userEntryCount번째 ' + (_hasParticipatedToday && !_isButtonClicked ? '해를 봤어요!' : '해보기 시작!'), textAlign: TextAlign.center,
                                                style: TextStyle(fontFamily: "PreRg", fontSize: 25, color: Theme.of(context).colorScheme.onBackground,),),
                                              SizedBox(height:20),
                                              Row( mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                                                InkWell(
                                                  onTap: (){
                                                    shareOnKakao();
                                                  },
                                                  child: Image.asset('images/kakao.png',width: 60, height: 60),
                                                ),
                                                SizedBox(width:15),
                                                InkWell(
                                                  onTap: (){
                                                    shareOnTwitter();
                                                  },
                                                  child: Image.asset('images/X.png',width: 60, height: 60),
                                                ),
                                                SizedBox(width:15),
                                                InkWell(
                                                  onTap: (){
                                                    shareClipBoard();
                                                  },
                                                  child: Image.asset('images/URL.png',width: 60, height: 60),
                                                ),

                                              ]),
                                              SizedBox(height:20),

                                              Text("다음 '그냥해'까지 $timeText 남음", textAlign: TextAlign.center,
                                                style: TextStyle(fontFamily: "PreBd", fontSize: 15, color: Theme.of(context).colorScheme.onBackground,),),
                                              SizedBox(height:5),
                                              Text('오늘 $entryCount명이 함께 해를 봤어요', textAlign: TextAlign.center,
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
                                                  _isButtonClicked = true;
                                                  BelowPadding = 0.05;//하단영역 Padding 조절
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                                textStyle: const TextStyle(
                                                  fontFamily: "PreBd",
                                                  fontSize: 28.0,
                                                  color: Colors.black,
                                                  // fontWeight: FontWeight.w900,
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
    barrierDismissible: true, //다이로그 밖 선택시 팝업 안 닫히게
    builder: (context) {
      return Dialog(
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        // 그림자 높이 elevation: 50,
        insetPadding: const  EdgeInsets.fromLTRB(20,40,20,40),

        child: Container(
          width: 450,
          padding: const EdgeInsets.all(30),
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
