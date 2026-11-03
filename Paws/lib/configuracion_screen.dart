import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'comun.dart';
import 'editar_perfil_screen.dart';
import 'pet_profile_setup_screen.dart';
import 'nueva_clave_screen.dart';
import 'welcome_screen.dart';

/// La mascota con la que se busca en Descubrir se guarda en el celular
/// (si el usuario tiene más de una mascota).
Future<String?> leerMascotaActiva() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('mascota_activa_$miId');
}

Future<void> guardarMascotaActiva(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('mascota_activa_$miId', id);
}

/// CONFIGURACIÓN: perfil, mascotas y cuenta
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  Map<String, dynamic>? _perfil;
  List<Map<String, dynamic>> _mascotas = [];
  String? _activa;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final perfil = await supabase.from('perfiles').select().eq('id', miId).single();
    final mascotas = await supabase.from('mascotas').select().eq('dueno_id', miId).order('created_at');
    final activa = await leerMascotaActiva();
    if (!mounted) return;
    setState(() {
      _perfil = perfil;
      _mascotas = mascotas;
      _activa = mascotas.any((m) => m['id'] == activa) ? activa : (mascotas.isEmpty ? null : mascotas.first['id'] as String);
    });
  }

  /// Abre otra pantalla y, si hubo cambios, recarga esta
  Future<void> _abrir(Widget pantalla) async {
    final cambio = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => pantalla));
    if (cambio == true) _cargar();
  }

  Future<void> _elegirActiva(String id) async {
    await guardarMascotaActiva(id);
    setState(() => _activa = id);
  }

  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
        child: Text(texto.toUpperCase(),
            style: const TextStyle(color: Colores.rosa, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      );

  Widget _grupo(List<Widget> filas) => Container(
        decoration: BoxDecoration(
          color: Colores.tarjeta,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colores.morado),
        ),
        child: Column(children: filas),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(backgroundColor: Colores.fondo, title: const Text('Configuración')),
        body: _perfil == null
            ? const Center(child: CircularProgressIndicator(color: Colores.rosa))
            : ListView(padding: const EdgeInsets.all(16), children: [
                // ---------- PERFIL ----------
                _grupo([
                  ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colores.rojo,
                      backgroundImage: (_perfil!['fotos'] as List).isNotEmpty
                          ? NetworkImage((_perfil!['fotos'] as List).first as String)
                          : null,
                    ),
                    title: Text(_perfil!['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Row(children: [
                      Icon(Icons.verified, color: Colors.lightBlueAccent, size: 16),
                      SizedBox(width: 4),
                      Text('RUT verificado', style: TextStyle(color: Colors.white54)),
                    ]),
                    trailing: const Icon(Icons.edit, color: Colores.rosa),
                    onTap: () => _abrir(const EditarPerfilScreen()),
                  ),
                ]),

                // ---------- MASCOTAS ----------
                _titulo('Mis mascotas'),
                if (_mascotas.length > 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Toca una mascota para buscar amigos con ella en Descubrir.',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                _grupo([
                  ..._mascotas.map((m) {
                    final fotos = m['fotos'] as List;
                    final esActiva = m['id'] == _activa;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colores.fondo,
                        backgroundImage: fotos.isNotEmpty ? NetworkImage(fotos.first as String) : null,
                      ),
                      title: Text(m['nombre'] as String),
                      subtitle: esActiva
                          ? const Text('Buscando amigos en Descubrir', style: TextStyle(color: Colores.rosa, fontSize: 12))
                          : null,
                      onTap: () => _elegirActiva(m['id'] as String),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (esActiva) const Icon(Icons.check_circle, color: Colores.rosa),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          tooltip: 'Editar',
                          onPressed: () => _abrir(PetProfileSetupScreen(mascota: m, desdeConfiguracion: true)),
                        ),
                      ]),
                    );
                  }),
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Colores.rojo, child: Icon(Icons.add, color: Colors.white)),
                    title: const Text('Agregar otra mascota'),
                    onTap: () => _abrir(const PetProfileSetupScreen(desdeConfiguracion: true)),
                  ),
                ]),

                // ---------- CUENTA ----------
                _titulo('Cuenta'),
                _grupo([
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: Colores.rosa),
                    title: const Text('Cambiar contraseña'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrir(const NuevaClaveScreen(desdeConfiguracion: true)),
                  ),
                  const Divider(height: 1, color: Colores.morado),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
                    onTap: _cerrarSesion,
                  ),
                ]),
                const SizedBox(height: 30),
                Center(
                  child: Text('Paws · versión 1.0 · ${supabase.auth.currentUser?.email ?? ''}',
                      style: const TextStyle(color: Colors.white24, fontSize: 12)),
                ),
              ]),
    );
  }
}
