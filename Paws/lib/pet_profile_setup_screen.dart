import 'package:flutter/material.dart';
import 'comun.dart';
import 'fotos.dart';
import 'ubicacion.dart';
import 'home_screen.dart';

/// Formulario de mascota. Sirve para 3 casos:
///  · primera mascota al registrarse   (mascota = null, desdeConfiguracion = false)
///  · agregar otra mascota             (mascota = null, desdeConfiguracion = true)
///  · editar una mascota existente     (mascota = sus datos)
class PetProfileSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? mascota;
  final bool desdeConfiguracion;
  const PetProfileSetupScreen({super.key, this.mascota, this.desdeConfiguracion = false});

  @override
  State<PetProfileSetupScreen> createState() => _PetProfileSetupScreenState();
}

class _PetProfileSetupScreenState extends State<PetProfileSetupScreen> {
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();

  List<Map<String, dynamic>> _especies = [];
  List<Map<String, dynamic>> _razas = [];

  int? _especieId;
  int? _razaId;
  String _sexo = 'hembra';
  double _tamano = 3;   // 1 mini … 5 gigante
  double _energia = 3;  // 1 tranquilo … 5 hiperactivo
  DateTime? _nacimiento;

  final List<Foto> _fotos = [];       // hasta 3 fotos de la mascota
  final List<Foto> _fotosDueno = [];  // hasta 3 fotos del dueño (solo si aún no tiene)
  Foto? _fotoJuntos;                  // dueño + mascota
  bool _pedirFotosDueno = false;
  bool _cargando = true;
  bool _guardando = false;

  bool get _editando => widget.mascota != null;

  static const _nombresTamano = ['Mini', 'Pequeño', 'Mediano', 'Grande', 'Gigante'];
  static const _nombresEnergia = ['Muy tranquilo', 'Tranquilo', 'Normal', 'Activo', 'Hiperactivo'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final especies = await supabase.from('especies').select().order('id');
    final razas = await supabase.from('razas').select().order('nombre');
    final perfil = await supabase.from('perfiles').select('fotos').eq('id', miId).single();

    // Si estamos editando, se rellenan los campos con los datos actuales
    final m = widget.mascota;
    if (m != null) {
      _nombre.text = m['nombre'] ?? '';
      _descripcion.text = m['descripcion'] ?? '';
      _especieId = m['especie_id'] as int?;
      _razaId = m['raza_id'] as int?;
      _sexo = m['sexo'] as String;
      _tamano = (m['tamano'] as int).toDouble();
      _energia = (m['energia'] as int).toDouble();
      if (m['fecha_nacimiento'] != null) _nacimiento = DateTime.parse(m['fecha_nacimiento'] as String);
      _fotos.addAll((m['fotos'] as List).map((u) => Foto.url(u as String)));
      if (m['foto_con_dueno'] != null) _fotoJuntos = Foto.url(m['foto_con_dueno'] as String);
    }

    if (!mounted) return;
    setState(() {
      _especies = especies;
      _razas = razas;
      _pedirFotosDueno = (perfil['fotos'] as List).isEmpty;
      _cargando = false;
    });
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _nacimiento ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha de nacimiento (aproximada)',
    );
    if (fecha != null) setState(() => _nacimiento = fecha);
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty || _especieId == null) {
      mostrarMensaje(context, 'Completa el nombre y la especie', error: true);
      return;
    }
    if (_fotos.isEmpty) {
      mostrarMensaje(context, 'Sube al menos 1 foto de tu mascota', error: true);
      return;
    }
    if ((_pedirFotosDueno && _fotosDueno.isEmpty) || _fotoJuntos == null) {
      mostrarMensaje(context, 'Por seguridad, sube una foto tuya y una foto junto a tu mascota', error: true);
      return;
    }
    setState(() => _guardando = true);

    try {
      // 1. Fotos: se suben solo las nuevas, las que ya estaban se mantienen
      final urls = await guardarFotos(_fotos, 'mascota');
      final urlJuntos = _fotoJuntos!.url ?? await subirFoto(_fotoJuntos!.bytes!, 'juntos');
      if (_pedirFotosDueno) {
        final urlsDueno = await guardarFotos(_fotosDueno, 'dueno');
        await supabase.from('perfiles').update({'fotos': urlsDueno}).eq('id', miId);
      }

      // 2. Datos de la mascota
      final datos = {
        'nombre': _nombre.text.trim(),
        'especie_id': _especieId,
        'raza_id': _razaId,
        'sexo': _sexo,
        'tamano': _tamano.round(),
        'energia': _energia.round(),
        'fecha_nacimiento': _nacimiento?.toIso8601String().substring(0, 10),
        'descripcion': _descripcion.text.trim(),
        'fotos': urls,
        'foto_con_dueno': urlJuntos,
      };
      if (_editando) {
        await supabase.from('mascotas').update(datos).eq('id', widget.mascota!['id']);
      } else {
        await supabase.from('mascotas').insert({...datos, 'dueno_id': miId});
      }

      if (!widget.desdeConfiguracion) await guardarMiUbicacion();

      if (!mounted) return;
      mostrarMensaje(context, _editando ? 'Cambios guardados ✅' : '¡Perfil de ${_nombre.text.trim()} guardado! 🐾');
      if (widget.desdeConfiguracion || _editando) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      }
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colores.tarjeta,
        title: Text('¿Eliminar a ${widget.mascota!['nombre']}?'),
        content: const Text('Se borrarán también sus likes, matches e inscripciones a juntas. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await supabase.from('mascotas').delete().eq('id', widget.mascota!['id']);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _editando
        ? 'Editar a ${widget.mascota!['nombre']}'
        : (widget.desdeConfiguracion ? 'Nueva mascota' : 'Perfil de tu peludo');

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, title: Text(titulo)),
        body: const Center(child: CircularProgressIndicator(color: Colores.rosa)),
      );
    }
    final razasDeEspecie = _razas.where((r) => r['especie_id'] == _especieId).toList();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text(titulo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_editando)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text('Cuéntanos sobre tu mascota para encontrarle los mejores amigos.',
                    style: TextStyle(color: Colors.white70)),
              ),

            // ---------- FOTOS ----------
            etiqueta('Fotos de tu mascota (hasta 3)'),
            SelectorFotos(fotos: _fotos, alCambiar: () => setState(() {})),
            const SizedBox(height: 20),

            // Seguridad: RUT + fotos del dueño + foto juntos ayudan a prevenir robos
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colores.tarjeta,
                border: Border.all(color: Colores.rosa),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.verified_user, color: Colores.rosa),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Por la seguridad de todos, pedimos fotos tuyas y una foto tuya con tu mascota. '
                    'Así los demás saben con quién se van a juntar y se previene el robo de mascotas.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            if (_pedirFotosDueno) ...[
              etiqueta('Tus fotos (hasta 3)'),
              SelectorFotos(fotos: _fotosDueno, alCambiar: () => setState(() {})),
              const SizedBox(height: 16),
            ],
            etiqueta('Foto de ustedes juntos'),
            SelectorFotoUnica(
              foto: _fotoJuntos,
              texto: 'Tú + tu mascota 🐶👤',
              alElegir: (f) => setState(() => _fotoJuntos = f),
            ),
            const SizedBox(height: 20),

            // ---------- DATOS ----------
            etiqueta('Nombre'),
            TextField(controller: _nombre, decoration: decoracionCampo('Ej: Akali', icono: Icons.pets)),
            const SizedBox(height: 16),

            etiqueta('Especie'),
            DropdownButtonFormField<int>(
              value: _especieId,
              dropdownColor: Colores.tarjeta,
              decoration: decoracionCampo('Elige una especie'),
              items: _especies
                  .map((e) => DropdownMenuItem<int>(value: e['id'] as int, child: Text(e['nombre'] as String)))
                  .toList(),
              onChanged: (v) => setState(() {
                _especieId = v;
                _razaId = null; // la raza depende de la especie
              }),
            ),
            const SizedBox(height: 16),

            etiqueta('Raza (opcional)'),
            DropdownButtonFormField<int>(
              key: ValueKey(_especieId), // se reinicia al cambiar de especie
              value: _razaId,
              dropdownColor: Colores.tarjeta,
              decoration: decoracionCampo(_especieId == null ? 'Primero elige la especie' : 'Elige una raza'),
              items: razasDeEspecie
                  .map((r) => DropdownMenuItem<int>(value: r['id'] as int, child: Text(r['nombre'] as String)))
                  .toList(),
              onChanged: (v) => setState(() => _razaId = v),
            ),
            const SizedBox(height: 16),

            etiqueta('Sexo'),
            Row(children: [
              ChoiceChip(
                label: const Text('Hembra'),
                selected: _sexo == 'hembra',
                onSelected: (_) => setState(() => _sexo = 'hembra'),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('Macho'),
                selected: _sexo == 'macho',
                onSelected: (_) => setState(() => _sexo = 'macho'),
              ),
            ]),
            const SizedBox(height: 16),

            etiqueta('Tamaño: ${_nombresTamano[_tamano.round() - 1]}'),
            Slider(
              value: _tamano, min: 1, max: 5, divisions: 4,
              activeColor: Colores.rosa,
              onChanged: (v) => setState(() => _tamano = v),
            ),

            etiqueta('Nivel de energía: ${_nombresEnergia[_energia.round() - 1]}'),
            Slider(
              value: _energia, min: 1, max: 5, divisions: 4,
              activeColor: Colores.rosa,
              onChanged: (v) => setState(() => _energia = v),
            ),

            etiqueta('Fecha de nacimiento (opcional)'),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colores.morado),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _elegirFecha,
              icon: const Icon(Icons.cake, color: Colores.rosa),
              label: Text(
                _nacimiento == null
                    ? 'Elegir fecha'
                    : '${_nacimiento!.day}/${_nacimiento!.month}/${_nacimiento!.year}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            etiqueta('Descripción y personalidad'),
            TextField(
              controller: _descripcion,
              maxLines: 3,
              decoration: decoracionCampo('¿Es tímida, juguetona, le encanta correr?'),
            ),
            const SizedBox(height: 30),

            BotonPrincipal(
              texto: _editando ? 'Guardar cambios' : 'Guardar perfil y buscar amigos',
              icono: _editando ? Icons.check : Icons.favorite,
              cargando: _guardando,
              onPressed: _guardar,
            ),
            if (_editando) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: _eliminar,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  label: Text('Eliminar a ${widget.mascota!['nombre']}', style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
