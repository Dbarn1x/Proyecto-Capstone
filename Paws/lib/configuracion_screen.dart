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

  /// Privacidad: mostrar u ocultar TODAS mis mascotas en Descubrir
  bool get _visibles => _mascotas.every((m) => m['visible'] != false);

  Future<void> _cambiarVisibilidad(bool visible) async {
    try {
      await supabase.from('mascotas').update({'visible': visible}).eq('dueno_id', miId);
      if (!mounted) return;
      mostrarMensaje(context, visible ? 'Tus mascotas vuelven a aparecer en Descubrir' : 'Tus mascotas ya no aparecen en Descubrir');
      _cargar();
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo cambiar: $e', error: true);
    }
  }

  /// Privacidad: borrar la cuenta y TODOS sus datos (pide escribir BORRAR para confirmar)
  Future<void> _borrarCuenta() async {
    final confirmacion = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colores.tarjeta,
        title: const Text('Borrar mi cuenta'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Se borrarán tu perfil, tus mascotas, matches, mensajes, juntas, productos y zonas. '
              'No se puede deshacer.'),
          const SizedBox(height: 15),
          const Text('Escribe BORRAR para confirmar:'),
          const SizedBox(height: 8),
          TextField(controller: confirmacion, decoration: decoracionCampo('BORRAR')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, confirmacion.text.trim().toUpperCase() == 'BORRAR'),
            child: const Text('Borrar cuenta', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      // Función de la base de datos que borra SOLO la cuenta de quien la llama
      await supabase.rpc('borrar_mi_cuenta');
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo borrar la cuenta: $e', error: true);
    }
  }

  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => WelcomeScreen()), (_) => false);
  }

  Widget _titulo(String texto) => Padding(
        padding: EdgeInsets.fromLTRB(4, 24, 4, 8),
        child: Text(texto.toUpperCase(),
            style: TextStyle(color: Colores.rosa, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
        appBar: AppBar(backgroundColor: Colores.fondo, title: Text('Configuración')),
        body: _perfil == null
            ? Center(child: CircularProgressIndicator(color: Colores.rosa))
            : ListView(padding: EdgeInsets.all(16), children: [
                // ---------- PERFIL ----------
                _grupo([
                  ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colores.rojo,
                      backgroundImage: (_perfil!['fotos'] as List).isNotEmpty
                          ? NetworkImage((_perfil!['fotos'] as List).first as String)
                          : null,
                    ),
                    title: Text(_perfil!['nombre'] as String, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(children: [
                      Icon(Icons.verified, color: Colors.lightBlueAccent, size: 16),
                      SizedBox(width: 4),
                      Text('RUT verificado', style: TextStyle(color: Colores.texto54)),
                    ]),
                    trailing: Icon(Icons.edit, color: Colores.rosa),
                    onTap: () => _abrir(EditarPerfilScreen()),
                  ),
                ]),

                // ---------- MASCOTAS ----------
                _titulo('Mis mascotas'),
                if (_mascotas.length > 1)
                  Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Toca una mascota para buscar amigos con ella en Descubrir.',
                        style: TextStyle(color: Colores.texto54, fontSize: 12)),
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
                          ? Text('Buscando amigos en Descubrir', style: TextStyle(color: Colores.rosa, fontSize: 12))
                          : null,
                      onTap: () => _elegirActiva(m['id'] as String),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (esActiva) Icon(Icons.check_circle, color: Colores.rosa),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colores.texto70),
                          tooltip: 'Editar',
                          onPressed: () => _abrir(PetProfileSetupScreen(mascota: m, desdeConfiguracion: true)),
                        ),
                      ]),
                    );
                  }),
                  // Máximo 5 mascotas por dueño (la base de datos también lo controla)
                  ListTile(
                    enabled: _mascotas.length < 5,
                    leading: CircleAvatar(
                      backgroundColor: _mascotas.length < 5 ? Colores.rojo : Colores.texto24,
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                    title: Text(_mascotas.length < 5 ? 'Agregar otra mascota' : 'Máximo 5 mascotas'),
                    subtitle: Text('${_mascotas.length} de 5', style: TextStyle(color: Colores.texto54, fontSize: 12)),
                    onTap: () => _abrir(PetProfileSetupScreen(desdeConfiguracion: true)),
                  ),
                ]),

                // ---------- APARIENCIA ----------
                _titulo('Apariencia'),
                _grupo([
                  for (final opcion in [
                    (ThemeMode.system, 'Automático', 'Igual que tu celular', Icons.brightness_auto),
                    (ThemeMode.light, 'Claro', 'Fondo claro', Icons.light_mode),
                    (ThemeMode.dark, 'Oscuro', 'Fondo oscuro', Icons.dark_mode),
                  ])
                    RadioListTile<ThemeMode>(
                      value: opcion.$1,
                      groupValue: temaApp.value,
                      activeColor: Colores.rosa,
                      title: Row(children: [
                        Icon(opcion.$4, size: 20, color: Colores.rosa),
                        const SizedBox(width: 10),
                        Text(opcion.$2),
                      ]),
                      subtitle: Text(opcion.$3, style: TextStyle(color: Colores.texto54, fontSize: 12)),
                      onChanged: (modo) async {
                        if (modo == null) return;
                        await guardarTema(modo);
                        if (mounted) setState(() {});
                      },
                    ),
                ]),

                // ---------- PRIVACIDAD ----------
                _titulo('Privacidad'),
                _grupo([
                  SwitchListTile(
                    value: _visibles,
                    activeColor: Colores.rosa,
                    secondary: Icon(Icons.visibility, color: Colores.rosa),
                    title: const Text('Mostrar mis mascotas en Descubrir'),
                    subtitle: Text('Si lo apagas, nadie nuevo podrá encontrarlas. Tus matches y chats se mantienen.',
                        style: TextStyle(color: Colores.texto54, fontSize: 12)),
                    onChanged: _cambiarVisibilidad,
                  ),
                  Divider(height: 1, color: Colores.morado),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    title: const Text('Borrar mi cuenta', style: TextStyle(color: Colors.redAccent)),
                    subtitle: Text('Elimina todos tus datos de Paws', style: TextStyle(color: Colores.texto54, fontSize: 12)),
                    onTap: _borrarCuenta,
                  ),
                ]),

                // ---------- CUENTA ----------
                _titulo('Cuenta'),
                _grupo([
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: Colores.rosa),
                    title: Text('Cambiar contraseña'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => _abrir(NuevaClaveScreen(desdeConfiguracion: true)),
                  ),
                  Divider(height: 1, color: Colores.morado),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.redAccent),
                    title: Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
                    onTap: _cerrarSesion,
                  ),
                ]),
                SizedBox(height: 30),
                Center(
                  child: Text('Paws · versión 1.0 · ${supabase.auth.currentUser?.email ?? ''}',
                      style: TextStyle(color: Colores.texto24, fontSize: 12)),
                ),
              ]),
    );
  }
}
