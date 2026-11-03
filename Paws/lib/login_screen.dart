import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comun.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;
  bool _verClave = false;

  Future<void> _ingresar() async {
    if (_correo.text.trim().isEmpty || _clave.text.isEmpty) {
      mostrarMensaje(context, 'Ingresa tu correo y contraseña', error: true);
      return;
    }
    setState(() => _cargando = true);
    try {
      // Supabase Auth valida el correo y la contraseña
      await supabase.auth.signInWithPassword(email: _correo.text.trim(), password: _clave.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => HomeScreen()), (_) => false);
    } on AuthException catch (e) {
      String texto = e.message;
      if (texto.contains('Invalid login')) texto = 'Correo o contraseña incorrectos';
      if (texto.contains('Email not confirmed')) texto = 'Debes confirmar tu correo antes de entrar';
      if (mounted) mostrarMensaje(context, texto, error: true);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo conectar. Revisa tu internet.', error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// "¿Olvidaste tu contraseña?": Supabase envía un correo con un enlace
  /// para crear una contraseña nueva (ver nueva_clave_screen.dart).
  Future<void> _recuperarClave() async {
    final correo = TextEditingController(text: _correo.text.trim());
    final enviar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colores.tarjeta,
        title: Text('Recuperar contraseña'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Te enviaremos un enlace a tu correo para crear una contraseña nueva.',
              style: TextStyle(color: Colores.texto70)),
          SizedBox(height: 15),
          TextField(
            controller: correo,
            keyboardType: TextInputType.emailAddress,
            decoration: decoracionCampo('ejemplo@correo.com', icono: Icons.email_outlined),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Enviar enlace', style: TextStyle(color: Colores.rosa)),
          ),
        ],
      ),
    );
    if (enviar != true || !mounted) return;
    if (!correo.text.contains('@')) {
      mostrarMensaje(context, 'Escribe un correo válido', error: true);
      return;
    }
    try {
      await supabase.auth.resetPasswordForEmail(
        correo.text.trim(),
        // En el navegador, el enlace vuelve a esta misma página
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );
      if (mounted) mostrarMensaje(context, 'Listo, revisa tu correo (también la carpeta spam) 📩');
    } on AuthException catch (e) {
      if (mounted) mostrarMensaje(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola de nuevo 🐾',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colores.texto)),
            SizedBox(height: 10),
            Text('Ingresa para ver a tus amigos peludos.', style: TextStyle(color: Colores.texto70)),
            SizedBox(height: 30),
            etiqueta('Correo electrónico'),
            TextField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              decoration: decoracionCampo('ejemplo@correo.com', icono: Icons.email_outlined),
            ),
            SizedBox(height: 20),
            etiqueta('Contraseña'),
            TextField(
              controller: _clave,
              obscureText: !_verClave,
              decoration: decoracionCampo('••••••••',
                  icono: Icons.lock_outline,
                  sufijo: IconButton(
                    icon: Icon(_verClave ? Icons.visibility : Icons.visibility_off, color: Colores.texto30),
                    onPressed: () => setState(() => _verClave = !_verClave),
                  )),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _recuperarClave,
                child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colores.rosa)),
              ),
            ),
            SizedBox(height: 20),
            BotonPrincipal(texto: 'Ingresar', icono: Icons.arrow_forward, cargando: _cargando, onPressed: _ingresar),
            SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                child: Text('¿No tienes cuenta? Regístrate', style: TextStyle(color: Colores.rosa)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
