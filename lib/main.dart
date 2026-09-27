import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pop_media/pages/admin_dashboard.dart';
import 'package:pop_media/pages/create_account_page.dart';
import 'package:pop_media/text_speech/tts_controller.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'pages/home_page.dart';
import 'pages/my_reviews_page.dart';
import 'pages/friends_reviews_page.dart';
import 'pages/followers_list.dart';
import 'pages/trending_page.dart';
import 'pages/discover_page.dart';
import 'pages/profile_page.dart';
import 'pages/upload_page.dart';
import 'pages/login_page.dart';
import 'pages/vibes_page.dart';
import 'pages/recommendations_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/camera_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/gestures.dart';
import 'package:pop_media/pages/auth_gate.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/models/theme.dart';
import 'package:provider/provider.dart';
import 'package:pop_media/models/media.dart';

Future<void> _initAuthPersistence() async {
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
}

Future<void> mainCommon({
  bool useFirebase = true,
  bool fireBaseEmulator = false,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  if (fireBaseEmulator) {
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    print('Using Firebase Emulator');
  } else {
    print('Using production Firebase');
  }

  await Supabase.initialize(
    url: 'https://lvtjyhigbynbhomsktjm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2dGp5aGlnYnluYmhvbXNrdGptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3OTg5ODEsImV4cCI6MjA4MDM3NDk4MX0.t58NoBwJBsP3euZcRL5mrTLijh7_NDX8PvPlGMAaVag',
  );

  await _initAuthPersistence();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController(PopArt)),
        ChangeNotifierProvider(create: (_) => TTSController()),

        ProxyProvider<TTSController, TtsService>(
          update: (_, ttsController, previous) {
            final service = previous ?? TtsService(ttsController);
            service.updateSettings(ttsController);
            service.init();
            return service;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

void main() async {
  await mainCommon();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      scrollBehavior: NoSwipeBackScrollBehavior(),
      debugShowCheckedModeBanner: false,
      title: 'PopMedia',
      theme: toThemeData(themeController.currentTheme),
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            context.read<TtsService>().unlockFromUserGesture();
          },
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaleFactor: themeController.textScale),
            child: child!,
          ),
        );
      },
      home: AuthGate(),
      routes: {
        '/adminDash': (context) => const AdminPage(),
        '/homePage': (context) => const HomePage(),
        '/myReviewsPage': (context) => const MyReviewsPage(hideName: false),
        '/followingPage': (context) => const FollowingPage(),
        '/trendingPage': (context) => const TrendingPage(),
        '/discoverPage': (context) => const DiscoverPage(),
        '/vibesPage': (context) => const VibesPage(),
        '/profilePage': (context) =>
            const ProfilePage(userId: 'me', adminAccess: false),
        '/uploadPage': (context) => const UploadPage(),
        '/createAccountPage': (context) => const CreateAccountPage(),
        '/loginPage': (context) => const LoginPage(),
        '/recommendationsPage': (context) => const RecommendationsPage(),
        '/followersListPage': (context) =>
            const FollowersListPage(userId: 'me'),
        '/cameraPage': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          final camera = args['camera'] as CameraDescription;
          final media = args['media'] as Media;
          final callback = args['callback'] as void Function(bool);
          final stillUploading = args['stillUploading'] as bool;
          return TakePictureScreen(
            camera: camera,
            media: media,
            callback: callback,
            stillUploading: stillUploading,
          );
        },
      },
    );
  }
}

class NoSwipeBackScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // removes overscroll effects
  }
}
