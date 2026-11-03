import 'package:flutter/material.dart';
import 'comun.dart';
import 'fotos.dart';

/// EDITAR MI PERFIL: nombre, teléfono y fotos del dueño. El RUT no se puede cambiar.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final List<Foto> _fotos = [];
  String _rut = '';
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final p = await supabase.from('perfiles').select().eq('id', miId).single();
    if (!mounted) return;
    setState(() {
      _nombre.text = p['nombre'] ?? '';
      _telefono.text = p['telefono'] ?? '';
      _rut = p['rut'] ?? '';
      _fotos.addAll((p['fotos'] as List).map((u) => Foto.url(u as String)));
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().length < 3) {
      mostrarMensaje(context, 'Escribe tu nombre', error: true);
      return;
    }
    if (_fotos.isEmpty) {
      mostrarMensaje(context, 'Por seguridad, deja al menos 1 foto tuya', error: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      final urls = await guardarFotos(_fotos, 'dueno');
      await supabase.from('perfiles').update({
        'nombre': _nombre.text.trim(),
        'telefono': _telefono.text.trim(),
        'fotos': urls,
      }).eq('id', miId);
      if (!mounted) return;
      mostrarMensaje(context, 'Perfil actualizado ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Mi perfil')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colores.rosa))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                etiqueta('Tus fotos (hasta 3)'),
                SelectorFotos(fotos: _fotos, alCambiar: () => setState(() {})),
                const SizedBox(height: 20),
                etiqueta('Nombre completo'),
                TextField(controller: _nombre, decoration: decoracionCampo('Ej: Camila Soto', icono: Icons.person_outline)),
                const SizedBox(height: 16),
                etiqueta('Teléfono (opcional)'),
                TextField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: decoracionCampo('Ej: +56 9 1234 5678', icono: Icons.phone),
                ),
                const SizedBox(height: 16),
                etiqueta('RUT'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colores.campo,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colores.morado),
                  ),
                  child: Row(children: [
                    const Icon(Icons.verified, color: Colors.lightBlueAccent),
                    const SizedBox(width: 10),
                    Text(_rut),
                    const Spacer(),
                    const Text('No se puede cambiar', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 30),
                BotonPrincipal(texto: 'Guardar cambios', icono: Icons.check, cargando: _guardando, onPressed: _guardar),
              ]),
            ),
    );
  }
}
