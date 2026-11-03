import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso a Supabase desde cualquier pantalla
final supabase = Supabase.instance.client;

/// Id del usuario con sesión iniciada
String get miId => supabase.auth.currentUser!.id;

/// Paleta oficial de Paws: degradado negro → rojo vino → morado
class Colores {
  static const fondo = Color(0xFF08060A);   // negro
  static const tarjeta = Color(0xFF1A0A12); // negro rojizo para tarjetas
  static const campo = Color(0xFF12080D);   // fondo de los campos de texto
  static const rojo = Color(0xFF7A0A16);    // rojo vino
  static const morado = Color(0xFF450D51);  // morado
  static const rosa = Color(0xFFE0314B);    // rojo claro para íconos y textos destacados

  /// Degradado de fondo (como la imagen de la paleta)
  static const degradado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [fondo, Color(0xFF2C070D), rojo, morado],
    stops: [0.0, 0.35, 0.6, 1.0],
  );
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
    hintStyle: const TextStyle(color: Colors.white30),
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
      borderSide: const BorderSide(color: Colores.rosa, width: 2),
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
      child: Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    );

/// Botón con degradado rojo → morado (el estilo de la app)
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
