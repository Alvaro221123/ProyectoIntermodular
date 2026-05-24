import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vecinoapp/ThemeColors/colors_theme.dart';
import 'firebase_options.dart';
import 'screens/register/registro_general.dart';
import 'screens/home/citizen_home_screen.dart';
import 'screens/home/association_home_screen.dart';

Future<void> main() async {
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
      debugShowCheckedModeBanner: false,
      title: 'VecinoApp',

      // Pantalla inicial
      initialRoute: '/',

      // Rutas de la app
      routes: {
        '/': (context) => Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                centerTitle: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                title: const Text('VecinoApp'),
              ),
              backgroundColor: AppColors.background,
              body: const RegistroGeneral(),
            ),

        '/citizen-home': (context) => const CitizenHomeScreen(),
        '/association-home': (context) => const AssociationHomeScreen(),
      },
    );
  }
}