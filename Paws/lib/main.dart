import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comun.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';
import 'nueva_clave_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Conexión con la base de datos Supabase del proyecto Paws.
  // La "publishable key" es pública: lo que protege los datos son las reglas RLS.
  await Supabase.initialize(
    url: 'https://umouwevatysnvdnhhaxt.supabase.co',
    anonKey: 'sb_publishable_lN9RvQSGD1hIYCtYZKMJUQ_RM83Ljg5',
  );

  runApp(const PawsApp());
}

/// Permite cambiar de pantalla desde fuera de un widget (ej: al volver del correo)
final navegador = GlobalKey<NavigatorState>();

class PawsApp extends StatefulWidget {
  const PawsApp({super.key});

  @override
  State<PawsApp> createState() => _PawsAppState();
}

class _PawsAppState extends State<PawsApp> {
  late final StreamSubscription<AuthState> _escuchaSesion;

  @override
  void initState() {
    super.initState();
    // Si el usuario abrió el enlace de "¿Olvidaste tu contraseña?",
    // Supabase avisa con el evento passwordRecovery → pedimos la nueva clave.
    _escuchaSesion = supabase.auth.onAuthStateChange.listen((estado) {
      if (estado.event == AuthChangeEvent.passwordRecovery) {
        navegador.currentState?.push(MaterialPageRoute(builder: (_) => const NuevaClaveScreen()));
      }
    });
  }

  @override
  void dispose() {
    _escuchaSesion.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si ya había una sesión iniciada, entra directo a la app
    final haySesion = supabase.auth.currentSession != null;

    return MaterialApp(
      title: 'Paws',
      navigatorKey: navegador,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colores.fondo,
        colorScheme: const ColorScheme.dark(primary: Colores.rosa, secondary: Colores.morado, surface: Colores.tarjeta),
        chipTheme: const ChipThemeData(selectedColor: Colores.rojo, side: BorderSide(color: Colores.morado)),
        sliderTheme: const SliderThemeData(activeTrackColor: Colores.rosa, thumbColor: Colores.rosa),
      ),
      home: haySesion ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
