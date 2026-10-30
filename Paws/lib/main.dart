import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de la base de datos Supabase (Paws App)
  await Supabase.initialize(
    url: 'https://tdmgngxdmjekpgvdpoep.supabase.co',
    anonKey: 'sb_publishable_bq8fCmdiD9iRbOXK3vwrAQ_7G8Rcait',
  );

  runApp(const MatchPetApp());
}

class MatchPetApp extends StatelessWidget {
  const MatchPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatchPet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F001A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD50050),
          secondary: Color(0xFF8A2BE2),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
