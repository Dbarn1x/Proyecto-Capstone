import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso a Supabase desde cualquier pantalla
final supabase = Supabase.instance.client;

/// Id del usuario con sesión iniciada
String get miId => supabase.auth.currentUser!.id;

/// Paleta oficial de Paws: negro → rojo vino → morado.
/// Los colores de fondo, tarjetas y textos cambian según el modo (claro u oscuro);
/// el rojo vino y el morado son iguales en ambos.
class Colores {
  /// true = modo claro. Lo decide PawsApp según lo elegido en Configuración.
  static bool claro = false;

  static const rojo = Color(0xFF7A0A16);   // rojo vino
  static const morado = Color(0xFF450D51); // morado

  static Color get fondo => claro ? const Color(0xFFFAF5F7) : const Color(0xFF08060A);
  static Color get tarjeta => claro ? Colors.white : const Color(0xFF1A0A12);
  static Color get campo => claro ? const Color(0xFFF4EBEF) : const Color(0xFF12080D);

  /// Rojo para íconos y textos destacados (más oscuro en modo claro para que se lea)
  static Color get rosa => claro ? const Color(0xFF9E1230) : const Color(0xFFE0314B);

  /// Textos: casi negro en modo claro, blanco en modo oscuro
  static Color get texto => claro ? const Color(0xFF1A0A12) : Colors.white;
  static Color get texto70 => texto.withOpacity(0.70);
  static Color get texto54 => texto.withOpacity(0.54);
  static Color get texto38 => texto.withOpacity(0.38);
  static Color get texto30 => texto.withOpacity(0.30);
  static Color get texto24 => texto.withOpacity(0.24);

  /// Degradado de fondo (como la imagen de la paleta)
  static LinearGradient get degradado => claro
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFAF5F7), Color(0xFFF3E4EA), Color(0xFFEBCFD8), Color(0xFFDCCBE6)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF08060A), Color(0xFF2C070D), rojo, morado],
          stops: [0.0, 0.35, 0.6, 1.0],
        );
}

// ---------------------------------------------------------------------
// TEMA: automático (según el celular), claro u oscuro. Se guarda en el celular.
// ---------------------------------------------------------------------
final temaApp = ValueNotifier<ThemeMode>(ThemeMode.dark);

Future<void> cargarTema() async {
  final prefs = await SharedPreferences.getInstance();
  final guardado = prefs.getString('tema') ?? 'oscuro';
  temaApp.value = guardado == 'claro' ? ThemeMode.light : (guardado == 'auto' ? ThemeMode.system : ThemeMode.dark);
}

Future<void> guardarTema(ThemeMode modo) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('tema', modo == ThemeMode.light ? 'claro' : (modo == ThemeMode.system ? 'auto' : 'oscuro'));
  temaApp.value = modo;
}

/// Mensaje corto en la parte de abajo de la pantalla
void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(texto),
    backgroundColor: error ? Colors.redAccent : Colors.green,
  ));
}

/// Estilo de los campos de texto
InputDecoration decoracionCampo(String hint, {IconData? icono, Widget? sufijo}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colores.texto30),
    prefixIcon: icono == null ? null : Icon(icono, color: Colores.rosa),
    suffixIcon: sufijo,
    filled: true,
    fillColor: Colores.campo,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colores.morado),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colores.rosa, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
  );
}

/// Etiqueta en negrita sobre un campo
Widget etiqueta(String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(texto, style: TextStyle(color: Colores.texto, fontWeight: FontWeight.bold, fontSize: 14)),
    );

/// Botón con degradado rojo vino → morado (el estilo de la app). Su texto siempre es blanco.
class BotonPrincipal extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final VoidCallback? onPressed;
  final bool cargando;

  const BotonPrincipal({super.key, required this.texto, this.icono, this.onPressed, this.cargando = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colores.rojo, Colores.morado]),
        border: Border.all(color: Colores.rosa.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 55),
        ),
        onPressed: cargando ? null : onPressed,
        child: cargando
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(texto, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  if (icono != null) ...[const SizedBox(width: 10), Icon(icono, color: Colors.white, size: 20)],
                ],
              ),
      ),
    );
  }
}
