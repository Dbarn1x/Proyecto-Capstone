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

  await cargarTema(); // modo claro / oscuro / automático guardado en el celular

  runApp(const PawsApp());
}

/// Permite cambiar de pantalla desde fuera de un widget (ej: al volver del correo)
final navegador = GlobalKey<NavigatorState>();

/// Temas de la app con la paleta de Paws
final temaOscuro = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF08060A),
  colorScheme: const ColorScheme.dark(primary: Color(0xFFE0314B), secondary: Colores.morado, surface: Color(0xFF1A0A12)),
  chipTheme: const ChipThemeData(selectedColor: Colores.rojo, side: BorderSide(color: Colores.morado)),
  sliderTheme: const SliderThemeData(activeTrackColor: Color(0xFFE0314B), thumbColor: Color(0xFFE0314B)),
);

final temaClaro = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFAF5F7),
  colorScheme: const ColorScheme.light(primary: Color(0xFF9E1230), secondary: Colores.morado, surface: Colors.white),
  chipTheme: const ChipThemeData(selectedColor: Color(0xFFF3D3DC), side: BorderSide(color: Color(0xFFD9B8C4))),
  sliderTheme: const SliderThemeData(activeTrackColor: Color(0xFF9E1230), thumbColor: Color(0xFF9E1230)),
);

class PawsApp extends StatefulWidget {
  const PawsApp({super.key});

  @override
  State<PawsApp> createState() => _PawsAppState();
}

class _PawsAppState extends State<PawsApp> with WidgetsBindingObserver {
  late final StreamSubscription<AuthState> _escuchaSesion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calcularModo();
    temaApp.addListener(_aplicarTema);

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
    WidgetsBinding.instance.removeObserver(this);
    temaApp.removeListener(_aplicarTema);
    _escuchaSesion.cancel();
    super.dispose();
  }

  /// En modo automático, si el celular cambia entre claro y oscuro, la app lo sigue
  @override
  void didChangePlatformBrightness() => _aplicarTema();

  void _calcularModo() {
    final modo = temaApp.value;
    final celularClaro = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light;
    Colores.claro = modo == ThemeMode.light || (modo == ThemeMode.system && celularClaro);
  }

  /// Cambia el modo y vuelve a dibujar TODAS las pantallas abiertas
  /// (sin perder en qué pantalla estaba el usuario).
  void _aplicarTema() {
    _calcularModo();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _redibujar(context as Element);
    });
  }

  void _redibujar(Element elemento) {
    elemento.markNeedsBuild();
    elemento.visitChildren(_redibujar);
  }

  @override
  Widget build(BuildContext context) {
    // Si ya había una sesión iniciada, entra directo a la app
    final haySesion = supabase.auth.currentSession != null;

    return MaterialApp(
      title: 'Paws',
      navigatorKey: navegador,
      debugShowCheckedModeBanner: false,
      theme: temaClaro,
      darkTheme: temaOscuro,
      themeMode: Colores.claro ? ThemeMode.light : ThemeMode.dark,
      home: haySesion ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
