import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:pop_media/models/theme.dart';
import 'package:pop_media/pages/edit_account_page.dart';
import 'package:pop_media/text_speech/tts_controller.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/forgot_password_popup.dart';
import 'package:pop_media/pages/login_page.dart';
import 'package:pop_media/pages/upload_page.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/models/user.dart';
import 'package:pop_media/widgets/report_popup.dart';
import 'package:pop_media/widgets/theme_select.dart';
import 'package:provider/provider.dart';

class MainScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final int? currentIndex;

  const MainScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.currentIndex,
  });
 
  State<MainScaffold> createState() => _MainScaffold();
}

class _MainScaffold extends State<MainScaffold> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
  if (UserSession.currentUser != null) {
    setState(() {
      _user = UserSession.currentUser;
    });
    return;
  }

  final user = await DataService.getUser(UserSession.uid!);

  if (mounted) {
    setState(() {
      _user = user;
      if (_user != null) {
        UserSession.setUser(_user!);
      }
    });
  }
}
  
  bool get _isDesktop {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  void _navigate(BuildContext context, String targetRoute) {
  final String? currentRoute = ModalRoute.of(context)?.settings.name;

  if (currentRoute == targetRoute) return;

  if (targetRoute == '/uploadPage') {
    Navigator.pushNamed(context, targetRoute);
  } else {
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      targetRoute,
      (route) => false,);
  }
}

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final themeController = context.watch<ThemeController>();
    final theme = themeController.currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.mainBackgroundColor,
      appBar: _isDesktop ? AppBar(
        backgroundColor: theme.topBarColor,
        foregroundColor: theme.primaryColor,
        title: Row(
            children: [
              Image.asset(
                theme.logo,
                height: 60,
                fit: BoxFit.contain,
              ),
              screenWidth >= 700 ?
              TextButton(
                onPressed: () => {
                  context.read<TtsService>().speak("Opening Home Page"),
                  _navigate(context, '/homePage')
                },
                child: Text('Home', style: TextStyle(color: Colors.white, fontSize: 24)),
              ):
              IconButton(
                onPressed: () => {
                  context.read<TtsService>().speak("Opening Home Page"),
                  _navigate(context, '/homePage')
                },
                icon: Icon(Icons.home),
              ),
              screenWidth >= 700 ?
              TextButton(
                onPressed: () => {
                  context.read<TtsService>().speak("Opening Discover Page"),
                  _navigate(context, '/discoverPage'),
                },
                child: Text('Discover', style: TextStyle(color: Colors.white, fontSize: 24)),
              ):
               IconButton(
                onPressed: () => {
                  context.read<TtsService>().speak("Opening Discover Page"),
                  _navigate(context, '/discoverPage'),
                },
                icon: Icon(Icons.search),
              ),
              screenWidth >= 700 ?
              TextButton(
                key: const Key('upload_button'),
                onPressed: () => {
                  context.read<TtsService>().speak("Opening Upload Page"),
                  _navigate(context, '/uploadPage'),
                },
                child: Text('Upload', style: TextStyle(color: Colors.white, fontSize: 24)),
              ):
               IconButton(
                onPressed: () => {
                  context.read<TtsService>().speak("Opening Upload Page"),
                  _navigate(context, '/uploadPage'),
                },
                icon: Icon(Icons.add, color: theme.plusItemColor, size: 32),
              ),
              screenWidth >= 700 ?
              TextButton(
                onPressed: () => {
                  context.read<TtsService>().speak("Opening Vibes Page"),
                  _navigate(context, '/vibesPage'),
                },
                child: Text('Vibe', style: TextStyle(color: Colors.white, fontSize: 24)),
              ):
               IconButton(
                onPressed: () => {
                  context.read<TtsService>().speak("Opening Vibes Page"),
                  _navigate(context, '/vibesPage'),
                },
                icon: Icon(Icons.waves),
              ),
              screenWidth >= 700 ?
               TextButton(
                onPressed: () => {
                  context.read<TtsService>().speak("Opening Profile Page"),
                  _navigate(context, '/profilePage'),
                },
                child: Text('Profile', style: TextStyle(color: Colors.white, fontSize: 24)),
              ):
               IconButton(
                onPressed: () => {
                  context.read<TtsService>().speak("Opening Profile Page"),
                  _navigate(context, '/profilePage'),
                },
                icon: ClipRSuperellipse(
                  borderRadius: BorderRadius.circular(17),
                  child: user == null
                    ? const CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.grey,
                      )
                    : ClipRSuperellipse(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.network(
                          user.imageUrl,
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        ),
                      )
                  ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.settings),
                key: const Key('settings_button_web'),
                color: theme.primaryColor, 
                onPressed: () {
                 _showSettingsMenu(context, themeController);
                },
              )
            ],
          ),
          elevation: 0,
        ): null,
      body: _isDesktop
      ? _dismissKeyboardWrapper(widget.body)
      : NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 60,
            backgroundColor: theme.topBarColor,
            foregroundColor: theme.primaryColor,
            floating: false,
            pinned: false,
            actions: [
              IconButton(
                icon: Icon(Icons.settings),
                key: const Key('settings_button_mobile'),
                color: theme.primaryColor,
                onPressed: () {
                 _showSettingsMenu(context, themeController);
                },
              )
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: EdgeInsets.only(bottom: 2),
              title: SizedBox(
                height: 50,
                child: Image.asset(
                  theme.logo,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ],
        body: _dismissKeyboardWrapper(widget.body),
      ),
      bottomNavigationBar: _isDesktop
          ? null
          : BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: widget.currentIndex ?? 0,
            backgroundColor: theme.appBarColor,
            selectedItemColor: theme.appItemSelected,
            unselectedItemColor: theme.appItemUnselected,
            onTap: (index) {
              final routeMap = {
                0: '/homePage',
                1: '/discoverPage',
                2: '/uploadPage',
                3: '/vibesPage',
                4: '/profilePage',
              };

              String targetRoute = routeMap[index]!;
              if (ModalRoute.of(context)?.settings.name == targetRoute) return;

              if (index == 2) {
                context.read<TtsService>().speak("Opening Upload Page");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UploadPage()),
                );
              } else {
                context.read<TtsService>().speak("Opening ${targetRoute}");
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                  targetRoute,
                  (route) => false,
                );
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                key: const Key('upload_button'),
                icon: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.appItemSelected,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.add, color: theme.plusItemColor, size: 32),
                ),
                label: 'Upload', 
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.waves),
                label: 'Vibe',
              ),
              BottomNavigationBarItem(
                icon: ClipRSuperellipse(
                  borderRadius: BorderRadius.circular(35),
                  child: user == null
                    ? const CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.grey,
                      )
                    : ClipRSuperellipse(
                        borderRadius: BorderRadius.circular(35),
                        child: Image.network(
                          user.imageUrl,
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        ),
                      )
                  ),
                label: 'Profile',
              ),
            ],
          )
        );
      }
}

Widget _dismissKeyboardWrapper(Widget child) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () {
      FocusManager.instance.primaryFocus?.unfocus();
    },
    child: child,
  );
}

void _showDeleteSuccess(BuildContext context){
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: Container(
          width: 350,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 3),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(4, 6),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Delete Account Successful!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              )
            ]
          )
          )
        );
    });
}

void _showDeleteMenu(BuildContext context, Theme theme){
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: Container(
          width: 350,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.primaryColor, width: 2,),
            color: theme.mainBackgroundColor,
            image: theme.mainBackgroundImage != null
                ? DecorationImage(
                    image: AssetImage(theme.mainBackgroundImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Are you sure you want to delete your account?", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                Text("This cannot be undone.", style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold)),
                Row(
                  children:[
                    TextButton(
                      onPressed: () async {
                        final success = await DataService.deleteAccount(UserSession.uid!);
                        context.read<TtsService>().speak("Opened Report PopUp");

                         Navigator.pop(context);

                        if (success) {
                          context.read<TtsService>().speak("Account Successfully Deleted");
                          Navigator.pushReplacementNamed(context, '/loginPage');
                          _showDeleteSuccess(context);
                        } else {
                          Navigator.pop(context);
                          context.read<TtsService>().speak("Error Deleting Account");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to delete account. Please try again later.'),
                            ),
                          );
                        }
                      },
                      child: ComicTitle(title: 'Delete Account', color: Colors.red),
                    ),
                    TextButton(
                      onPressed: () => {
                        context.read<TtsService>().speak("Closed Delete Account PopUp"),
                        Navigator.pop(context)
                      },
                      child: ComicTitle(title: 'Close'),
                    ),
                  ]
                )
              ]
            )
          )
        );
      }
    );
}


void _showSettingsMenu(BuildContext context, ThemeController themeController) {
  final theme = themeController.currentTheme;

  void _showResetPassword() async{
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ForgotPasswordPopup()
    );
  }

  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) {
      final themeController = context.watch<ThemeController>();

      return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: themeController.textScale.clamp(1.0, 1.2),
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.primaryColor, width: 2,),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        "Settings",
                        style: TextStyle(
                          fontFamily: theme.fontFamily,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: Icon(Icons.close, color: theme.primaryColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
              children: [
                Text(
                  "Text to Speech: ",
                  style: TextStyle(
                    fontFamily: theme.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Consumer<TTSController>(
                  builder: (context, settings, _) {
                    return Switch(
                      value: settings.ttsEnabled,
                      activeColor: theme.accentColor,
                      onChanged: (value) {
                        settings.setTtsEnabled(value);

                        if (value) {
                          context.read<TtsService>()
                            .speak("Text to speech enabled");
                        }
                      },
                    );
                  },
                ),
              ],
              ),
             const SizedBox(height: 16),
              Row(
                children:[
                  Text("Text Sizing: ", style: TextStyle(fontFamily: theme.fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                    Expanded(
                    child: Slider(
                      value: themeController.textScale,
                      min: themeController.minTextScale,
                      max: themeController.maxTextScale ,
                      divisions: 5,
                      label: "${(themeController.textScale * 100).round()}%",
                      activeColor: theme.accentColor,
                      thumbColor: theme.accentColor,
                      onChanged: (value) {
                        context.read<TtsService>().speak("Changing Text Size");
                        themeController.setTextScale(value);
                      },
                    ),
                  ),
                ]
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Text("Theme Select: ", style: TextStyle(fontFamily: theme.fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  ThemeSelector(),
                ]
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  context.read<TtsService>().speak("Opened Report PopUp");
                  showDialog(
                    context: context,
                    builder: (context) => ReportPopUp(type: "General"),
                  );
                },
                child: ComicTitle(title: 'Report An Issue'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditAccountAccountPage(uid: UserSession.uid),
                    ),
                  );
                },
                child: ComicTitle(title: 'Edit Profile'),
              ),
              const SizedBox(height: 10),
              TextButton(
                    onPressed: () {
                      context.read<TtsService>().speak("Opened Password Reset PopUp");
                      _showResetPassword();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    child: ComicTitle(title: "Reset Password"),
              ),
              const SizedBox(height: 10),
              TextButton(
                key: const Key('logout_button'),
                onPressed: () async {
                  context.read<TtsService>().speak("Logging Out User");

                  UserSession.clear();
                  Navigator.pop(context);

                  await FirebaseAuth.instance.signOut();
                  UserSession.clear();

                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                child: ComicTitle(title: "Logout"),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  context.read<TtsService>().speak("Opened Delete Account Menu");
                  _showDeleteMenu(context, theme);
                },
                child: ComicTitle(title: "Delete Account", color: Colors.red),
              ),
            ],
          ),
        ),
      ));
    },
  );
}