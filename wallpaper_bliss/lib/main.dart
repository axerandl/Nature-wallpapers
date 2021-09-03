import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallpaper_bliss/data/utils.dart';
import 'package:wallpaper_bliss/model/firebase/firebase_model.dart';
import 'package:wallpaper_bliss/screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AndroidInfo androidInfo = AndroidInfo();
  await androidInfo.init();

  SigninUtilAnonymous signinUtil = SigninUtilAnonymous();
  await signinUtil.signIn();

  // SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => FirebaseWPModelFactory().createWPModel()),
        Provider(
          create: (_) => AdShowAid(),
        ),
        Provider(
          create: (_) => AdMobUtil(),
        ),
        Provider.value(value: androidInfo),
        // Provider.value(value: signinUtil),
        // Provider.value(value: prefs),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nature Wallpapers',
        theme: ThemeData(
          brightness: Brightness.dark,
          accentColor: Colors.green[300],
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          accentColor: Colors.green[300],
        ),
        home: Home());
  }
}
