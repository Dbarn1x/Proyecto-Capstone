import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comun.dart';
import 'home_screen.dart';

/// Se abre cuando el usuario llega desde el enlace de "¿Olvidaste tu contraseña?"
class NuevaClaveScreen extends StatefulWidget {
  const NuevaClaveScreen({super.key});

  @override
  State<NuevaClaveScreen> createState() => _NuevaClaveScreenState();
}

class _NuevaClaveScreenState extends State<NuevaClaveScreen> {
  final _form = GlobalKey<FormState>();
  final _clave = TextEditingController();
  final _confirmar = TextEditingController();
  bool _guardando = false;

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: _clave.text));
      if (!mounted) return;
      mostrarMensaje(context, 'Contraseña actualizada 🔒');
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } on AuthException catch (e) {
      if (mounted) mostrarMensaje(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Nueva contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Crea una contraseña nueva de al menos 12 caracteres.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            etiqueta('Nueva contraseña'),
            TextFormField(
              controller: _clave,
              obscureText: true,
              decoration: decoracionCampo('Mínimo 12 caracteres', icono: Icons.lock_outline),
              validator: validarClave,
            ),
            const SizedBox(height: 16),
            etiqueta('Confirmar contraseña'),
            TextFormField(
              controller: _confirmar,
              obscureText: true,
              decoration: decoracionCampo('Repite la contraseña', icono: Icons.lock_outline),
              validator: (v) => v == _clave.text ? null : 'Las contraseñas no coinciden',
            ),
            const SizedBox(height: 30),
            BotonPrincipal(texto: 'Guardar contraseña', icono: Icons.check, cargando: _guardando, onPressed: _guardar),
          ]),
        ),
      ),
    );
  }
}

/// Regla de contraseña segura de Paws: 12 caracteres o más, con letras y números
String? validarClave(String? v) {
  if (v == null || v.length < 12) return 'Mínimo 12 caracteres';
  if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) return 'Debe tener letras y números';
  return null;
}
