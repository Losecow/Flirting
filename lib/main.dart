import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform, File;
import 'screens/auth/login_page.dart'; // ResponsiveLoginPage가 있는 파일
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/search_provider.dart';
import 'providers/likes_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/speech_style_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;

  // iOS에서 GoogleService-Info.plist 파일 존재 확인
  if (Platform.isIOS) {
    print('🔍 iOS 환경 확인 중...');
    try {
      final file = File('ios/Runner/GoogleService-Info.plist');
      if (await file.exists()) {
        print('✅ GoogleService-Info.plist 파일이 존재합니다: ${file.path}');
      } else {
        print('❌ GoogleService-Info.plist 파일을 찾을 수 없습니다: ${file.path}');
      }
    } catch (e) {
      print('⚠️ GoogleService-Info.plist 확인 중 오류: $e');
    }
  }

  try {
    // Firebase 초기화 (iOS에서는 GoogleService-Info.plist가 자동으로 로드됨)
    print('🔥 Firebase 초기화 시도 중...');
    await Firebase.initializeApp();
    firebaseInitialized = true;
    print('✅ Firebase 초기화 성공!');
    print('✅ Firebase App Name: ${Firebase.app().name}');
    print('✅ Firebase Project ID: ${Firebase.app().options.projectId}');
    print('✅ Firebase Bundle ID: ${Firebase.app().options.iosBundleId}');
  } catch (e, stackTrace) {
    print('❌❌❌ Firebase 초기화 실패 ❌❌❌');
    print('❌ 에러 타입: ${e.runtimeType}');
    print('❌ 에러 메시지: $e');
    print('❌ 전체 스택 트레이스:');
    print(stackTrace);
    // iOS에서 GoogleService-Info.plist가 없거나 잘못된 경우
    if (Platform.isIOS) {
      print('');
      print('⚠️⚠️⚠️ iOS Firebase 초기화 문제 해결 방법 ⚠️⚠️⚠️');
      print('1. Xcode에서 ios/Runner.xcworkspace 열기');
      print('2. 왼쪽 프로젝트 네비게이터에서 Runner 폴더 확인');
      print('3. GoogleService-Info.plist 파일이 보이는지 확인');
      print(
        '4. 파일이 안 보이면: Finder에서 ios/Runner/GoogleService-Info.plist를 Xcode의 Runner 폴더로 드래그',
      );
      print('5. 파일 선택 후 오른쪽 패널 > Target Membership > Runner 체크 확인');
      print('6. Product > Clean Build Folder (Shift+Cmd+K)');
      print('7. 다시 빌드 및 실행');
      print('');
    }
    // 초기화 실패해도 앱은 실행되도록 함
  }

  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;

  const MyApp({super.key, this.firebaseInitialized = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => LikesProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SpeechStyleProvider()),
      ],
      child: MaterialApp(
        title: 'Campus Match',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
          useMaterial3: true,
        ),
        home: ResponsiveLoginPage(firebaseInitialized: firebaseInitialized),
      ),
    );
  }
}
