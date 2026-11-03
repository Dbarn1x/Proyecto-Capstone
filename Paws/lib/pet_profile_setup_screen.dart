import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comun.dart';
import 'ubicacion.dart';
import 'home_screen.dart';

class PetProfileSetupScreen extends StatefulWidget {
  const PetProfileSetupScreen({super.key});

  @override
  State<PetProfileSetupScreen> createState() => _PetProfileSetupScreenState();
}

class _PetProfileSetupScreenState extends State<PetProfileSetupScreen> {
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();

  // Catálogos que vienen de la base de datos
  List<Map<String, dynamic>> _especies = [];
  List<Map<String, dynamic>> _razas = [];

  int? _especieId;
  int? _razaId;
  String _sexo = 'hembra';
  double _tamano = 3;   // 1 mini … 5 gigante
  double _energia = 3;  // 1 tranquilo … 5 hiperactivo
  DateTime? _nacimiento;
  final List<Uint8List> _fotos = [];      // hasta 3 fotos de la mascota
  final List<Uint8List> _fotosDueno = []; // hasta 3 fotos del dueño
  Uint8List? _fotoJuntos;                 // 1 foto del dueño con su mascota
  bool _guardando = false;

  static const _nombresTamano = ['Mini', 'Pequeño', 'Mediano', 'Grande', 'Gigante'];
  static const _nombresEnergia = ['Muy tranquilo', 'Tranquilo', 'Normal', 'Activo', 'Hiperactivo'];

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    final especies = await supabase.from('especies').select().order('id');
    final razas = await supabase.from('razas').select().order('nombre');
    setState(() {
      _especies = especies;
      _razas = razas;
    });
  }

  Future<Uint8List?> _elegirFoto() async {
    final archivo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 75);
    if (archivo == null) return null;
    return await archivo.readAsBytes();
  }

  Future<String> _subirFoto(Uint8List bytes, String nombre) async {
    // Cada usuario sube solo a su carpeta: fotos/<su id>/... (regla de Storage)
    final ruta = '$miId/${nombre}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('fotos').uploadBinary(ruta, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    return supabase.storage.from('fotos').getPublicUrl(ruta);
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
    if (_fotosDueno.isEmpty || _fotoJuntos == null) {
      mostrarMensaje(context, 'Por seguridad, sube una foto tuya y una foto junto a tu mascota', error: true);
      return;
    }
    setState(() => _guardando = true);

    try {
      // 1. Subir las fotos a Supabase Storage
      final urls = <String>[];
      for (int i = 0; i < _fotos.length; i++) {
        urls.add(await _subirFoto(_fotos[i], 'mascota_$i'));
      }
      final urlsDueno = <String>[];
      for (int i = 0; i < _fotosDueno.length; i++) {
        urlsDueno.add(await _subirFoto(_fotosDueno[i], 'dueno_$i'));
      }
      final urlJuntos = await _subirFoto(_fotoJuntos!, 'juntos');

      // Las fotos del dueño van en su perfil (verificación de identidad)
      await supabase.from('perfiles').update({'fotos': urlsDueno}).eq('id', miId);

      // 2. Guardar la mascota en la tabla mascotas
      await supabase.from('mascotas').insert({
        'dueno_id': miId,
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
      });

      // 3. Guardar mi ubicación para calcular distancias (PostGIS)
      await guardarMiUbicacion();

      if (!mounted) return;
      mostrarMensaje(context, '¡Perfil de ${_nombre.text.trim()} guardado! 🐾');
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// 3 casilleros de foto: tocar uno vacío agrega, tocar uno con foto la quita
  Widget _filaFotos(List<Uint8List> lista) {
    return Row(
      children: List.generate(3, (i) {
        final tieneFoto = i < lista.length;
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              if (tieneFoto) {
                setState(() => lista.removeAt(i));
              } else if (lista.length < 3) {
                final f = await _elegirFoto();
                if (f != null) setState(() => lista.add(f));
              }
            },
            child: Container(
              height: 110,
              margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
              decoration: BoxDecoration(
                color: Colores.tarjeta,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colores.morado),
                image: tieneFoto ? DecorationImage(image: MemoryImage(lista[i]), fit: BoxFit.cover) : null,
              ),
              child: tieneFoto
                  ? const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: CircleAvatar(
                            radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                      ))
                  : const Icon(Icons.add_a_photo, color: Colores.rosa),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final razasDeEspecie = _razas.where((r) => r['especie_id'] == _especieId).toList();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Perfil de tu peludo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cuéntanos sobre tu mascota para encontrarle los mejores amigos.',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),

            // ---------- FOTOS ----------
            etiqueta('Fotos de tu mascota (hasta 3)'),
            _filaFotos(_fotos),
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
            etiqueta('Tus fotos (hasta 3)'),
            _filaFotos(_fotosDueno),
            const SizedBox(height: 16),
            etiqueta('Foto de ustedes juntos'),
            GestureDetector(
              onTap: () async {
                final f = await _elegirFoto();
                if (f != null) setState(() => _fotoJuntos = f);
              },
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colores.tarjeta,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colores.morado),
                  image: _fotoJuntos != null ? DecorationImage(image: MemoryImage(_fotoJuntos!), fit: BoxFit.cover) : null,
                ),
                child: _fotoJuntos != null
                    ? null
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_a_photo, color: Colores.rosa, size: 30),
                        SizedBox(height: 8),
                        Text('Tú + tu mascota 🐶👤'),
                      ]),
              ),
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
              texto: 'Guardar perfil y buscar amigos',
              icono: Icons.favorite,
              cargando: _guardando,
              onPressed: _guardar,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
