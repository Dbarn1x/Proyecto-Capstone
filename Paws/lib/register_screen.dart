import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comun.dart';
import 'rut.dart';
import 'pet_profile_setup_screen.dart';
import 'login_screen.dart';
import 'nueva_clave_screen.dart' show validarClave;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _rut = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmar = TextEditingController();
  bool _cargando = false;
  bool _verClave = false;

  Future<void> _registrar() async {
    // 1. Validaciones en la app (formato, dígito verificador del RUT, etc.)
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      // 2. Crear la cuenta en Supabase Auth. El nombre y el RUT viajan como
      //    "metadata" y el TRIGGER crear_perfil los guarda en la tabla perfiles.
      final respuesta = await supabase.auth.signUp(
        email: _correo.text.trim(),
        password: _clave.text,
        data: {'nombre': _nombre.text.trim(), 'rut': normalizarRut(_rut.text)},
      );
      if (!mounted) return;

      if (respuesta.session != null) {
        // Sesión iniciada: pasamos a crear el perfil de la mascota
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (_) => const PetProfileSetupScreen()), (_) => false);
      } else {
        // Supabase tiene activada la confirmación por correo
        mostrarMensaje(context, 'Te enviamos un correo para confirmar tu cuenta. Luego inicia sesión.');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } on AuthException catch (e) {
      String texto = e.message;
      // Si el trigger falla (RUT repetido) Supabase responde "Database error saving new user"
      if (texto.contains('Database error')) texto = 'Este RUT ya está registrado';
      if (texto.contains('already registered')) texto = 'Este correo ya está registrado';
      if (texto.contains('Password should')) texto = 'La contraseña no cumple los requisitos de seguridad';
      if (mounted) mostrarMensaje(context, texto, error: true);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo conectar. Revisa tu internet.', error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Text('Crear Cuenta ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                Icon(Icons.pets, color: Colors.blueAccent),
              ]),
              const SizedBox(height: 10),
              const Text('¡Estás a un paso de encontrarle mejores amigos a tu peludo!',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colores.tarjeta,
                  border: Border.all(color: Colores.rosa),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.security, color: Colores.rosa),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Registro seguro: solicitamos tu RUT para verificar tu identidad y prevenir el robo de mascotas. Solo tú puedes verlo.',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ]),
              ),
              const SizedBox(height: 25),
              etiqueta('Tu nombre completo'),
              TextFormField(
                controller: _nombre,
                decoration: decoracionCampo('Ej: Camila Soto', icono: Icons.person_outline),
                validator: (v) => (v == null || v.trim().length < 3) ? 'Escribe tu nombre' : null,
              ),
              const SizedBox(height: 16),
              etiqueta('RUT'),
              TextFormField(
                controller: _rut,
                decoration: decoracionCampo('Ej: 12.345.678-5', icono: Icons.badge_outlined),
                validator: (v) => rutValido(v ?? '') ? null : 'RUT inválido',
              ),
              const SizedBox(height: 16),
              etiqueta('Correo electrónico'),
              TextFormField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                decoration: decoracionCampo('ejemplo@correo.com', icono: Icons.email_outlined),
                validator: (v) => (v != null && v.contains('@') && v.contains('.')) ? null : 'Correo inválido',
              ),
              const SizedBox(height: 16),
              etiqueta('Contraseña'),
              TextFormField(
                controller: _clave,
                obscureText: !_verClave,
                decoration: decoracionCampo('Mínimo 12 caracteres, con letras y números',
                    icono: Icons.lock_outline,
                    sufijo: IconButton(
                      icon: Icon(_verClave ? Icons.visibility : Icons.visibility_off, color: Colors.white30),
                      onPressed: () => setState(() => _verClave = !_verClave),
                    )),
                validator: validarClave,
              ),
              const SizedBox(height: 16),
              etiqueta('Confirmar contraseña'),
              TextFormField(
                controller: _confirmar,
                obscureText: !_verClave,
                decoration: decoracionCampo('Repite la contraseña', icono: Icons.lock_outline),
                validator: (v) => v == _clave.text ? null : 'Las contraseñas no coinciden',
              ),
              const SizedBox(height: 30),
              BotonPrincipal(
                  texto: 'Registrarme con Seguridad', icono: Icons.arrow_forward, cargando: _cargando, onPressed: _registrar),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
