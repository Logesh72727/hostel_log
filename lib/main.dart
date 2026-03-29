import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hostel_log/firebase_options.dart';
import 'package:hostel_log/screens/login_screen.dart';
import 'package:hostel_log/screens/dashboard_screen.dart';
import 'package:hostel_log/services/auth_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Hostel Log',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (auth.user != null) {
              return DashboardScreen();
            } else {
              return LoginScreen();
            }
          },
        ),
        routes: {
          '/login': (_) => LoginScreen(),
          '/dashboard': (_) => DashboardScreen(),
        },
      ),
    );
  }
}
