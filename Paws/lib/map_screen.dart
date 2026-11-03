import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'comun.dart';
import 'ubicacion.dart';
import 'veterinarias_osm.dart';

/// MAPA con 3 modos: Juntas (eventos), Veterinarias y Paseos (zonas)
class MapScreen extends StatefulWidget {
  final String miMascotaId;
  const MapScreen({super.key, required this.miMascotaId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum Modo { juntas, veterinarias, paseos }

class _MapScreenState extends State<MapScreen> {
  final _mapa = MapController();
  Modo _modo = Modo.juntas;
  LatLng _yo = santiagoCentro;
  bool _eligiendoPunto = false; // true = el próximo toque en el mapa crea algo

  List<Map<String, dynamic>> _eventos = [];
  List<Map<String, dynamic>> _veterinarias = [];
  List<Map<String, dynamic>> _zonas = [];
  List<VeterinariaOsm> _vetsOsm = [];   // veterinarias reales de OpenStreetMap
  bool _buscandoVets = false;

  @override
  void initState() {
    super.initState();
    _ubicarme();
    _cargarTodo();
  }

  Future<void> _ubicarme() async {
    final punto = await obtenerUbicacion();
    if (punto != null && mounted) {
      setState(() => _yo = punto);
      try {
        _mapa.move(punto, 14);
      } catch (_) {} // si el mapa aún no se dibuja, igual parte centrado en _yo
    }
  }

  /// Las VISTAS de la base de datos ya filtran lo vigente
  Future<void> _cargarTodo() async {
    try {
      final eventos = await supabase.from('vista_eventos').select().order('fecha');
      final vets = await supabase.from('vista_veterinarias').select();
      final zonas = await supabase.from('vista_zonas').select();
      if (!mounted) return;
      setState(() {
        _eventos = eventos;
        _veterinarias = vets;
        _zonas = zonas;
      });
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'Error al cargar el mapa: $e', error: true);
    }
  }

  /// Busca las veterinarias reales en 5 km alrededor de un punto (OpenStreetMap)
  Future<void> _buscarVeterinarias(LatLng centro) async {
    setState(() => _buscandoVets = true);
    try {
      final lista = await buscarVeterinariasOsm(centro);
      if (!mounted) return;
      setState(() => _vetsOsm = lista);
      mostrarMensaje(context, '${lista.length} veterinarias encontradas cerca 🏥');
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudieron cargar las veterinarias: $e', error: true);
    } finally {
      if (mounted) setState(() => _buscandoVets = false);
    }
  }

  Color _colorVet(bool? abierta) =>
      abierta == true ? Colors.greenAccent : (abierta == false ? Colors.grey : Colors.amber);

  LatLng _punto(Map<String, dynamic> fila) =>
      LatLng((fila['latitud'] as num).toDouble(), (fila['longitud'] as num).toDouble());

  // ------------------------------------------------------------------
  // MARCADORES
  // ------------------------------------------------------------------
  List<Marker> _marcadores() {
    final marcadores = <Marker>[
      Marker(
        point: _yo,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueAccent,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ),
    ];

    switch (_modo) {
      case Modo.juntas:
        marcadores.addAll(_eventos.map((e) => _marcador(_punto(e), Icons.groups, Colores.morado, () => _verEvento(e))));
        break;
      case Modo.veterinarias:
        // Veterinarias reales cercanas (OpenStreetMap)
        marcadores.addAll(_vetsOsm.map((v) =>
            _marcador(v.punto, Icons.local_hospital, _colorVet(v.abiertaAhora), () => _verVeterinariaOsm(v))));
        // Veterinarias con convenio Paws (tabla veterinarias de nuestra BD)
        marcadores.addAll(_veterinarias.map((v) {
          final abierta = v['abierta_ahora'] == true;
          return _marcador(_punto(v), Icons.star, abierta ? Colors.greenAccent : Colors.grey, () => _verVeterinaria(v));
        }));
        break;
      case Modo.paseos:
        marcadores.addAll(_zonas.map((z) => _marcador(_punto(z), _iconoZona(z['tipo'] as String),
            _colorZona(z['tipo'] as String), () => _verZona(z))));
        break;
    }
    return marcadores;
  }

  Marker _marcador(LatLng punto, IconData icono, Color color, VoidCallback alTocar) {
    return Marker(
      point: punto,
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: alTocar,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colores.tarjeta,
            border: Border.all(color: color, width: 3),
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)],
          ),
          child: Icon(icono, color: color, size: 26),
        ),
      ),
    );
  }

  Color _colorZona(String tipo) =>
      tipo == 'recomendada' ? Colors.greenAccent : (tipo == 'precaucion' ? Colors.amber : Colors.redAccent);

  IconData _iconoZona(String tipo) =>
      tipo == 'recomendada' ? Icons.park : (tipo == 'precaucion' ? Icons.warning_amber : Icons.do_not_disturb_on);

  String _textoZona(String tipo) =>
      tipo == 'recomendada' ? 'Recomendada para pasear' : (tipo == 'precaucion' ? 'Precaución' : 'Zona a evitar');

  String _fechaHora(String iso) {
    final f = DateTime.parse(iso).toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${f.day}/${f.month}/${f.year} a las ${dos(f.hour)}:${dos(f.minute)}';
  }

  // ------------------------------------------------------------------
  // DETALLES (se abren al tocar un marcador)
  // ------------------------------------------------------------------
  void _hoja(Widget contenido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colores.tarjeta,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => Padding(padding: const EdgeInsets.all(20), child: contenido),
    );
  }

  Future<void> _verEvento(Map<String, dynamic> e) async {
    // ¿Mi mascota ya está inscrita?
    final inscrita = await supabase
        .from('evento_participantes')
        .select()
        .eq('evento_id', e['id'])
        .eq('mascota_id', widget.miMascotaId)
        .maybeSingle();
    bool participo = inscrita != null;
    int inscritos = e['inscritos'] as int;
    final cupo = e['cupo'] as int?;
    if (!mounted) return;

    _hoja(StatefulBuilder(builder: (context, actualizar) {
      Future<void> alternar() async {
        try {
          if (participo) {
            await supabase.from('evento_participantes').delete()
                .eq('evento_id', e['id']).eq('mascota_id', widget.miMascotaId);
            actualizar(() { participo = false; inscritos--; });
          } else {
            // El cupo se controla en la app antes de inscribir
            if (cupo != null && inscritos >= cupo) {
              mostrarMensaje(context, 'Sin cupos disponibles', error: true);
              return;
            }
            await supabase.from('evento_participantes').insert({'evento_id': e['id'], 'mascota_id': widget.miMascotaId});
            actualizar(() { participo = true; inscritos++; });
          }
          _cargarTodo();
        } catch (err) {
          mostrarMensaje(context, 'Error: $err', error: true);
        }
      }

      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.groups, color: Colores.morado, size: 30),
          const SizedBox(width: 10),
          Expanded(child: Text(e['titulo'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 12),
        Text('📅 ${_fechaHora(e['fecha'] as String)}'),
        const SizedBox(height: 6),
        Text('🐾 $inscritos inscritos${cupo != null ? ' de $cupo cupos' : ''}'),
        if ((e['descripcion'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(e['descripcion'] as String, style: const TextStyle(color: Colors.white70)),
        ],
        const SizedBox(height: 20),
        BotonPrincipal(
          texto: participo ? 'Salir de la junta' : 'Me uno con mi mascota',
          icono: participo ? Icons.logout : Icons.pets,
          onPressed: alternar,
        ),
        if (e['creador_id'] == miId) ...[
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              label: const Text('Eliminar mi junta', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                await supabase.from('eventos').delete().eq('id', e['id']);
                if (context.mounted) Navigator.pop(context);
                _cargarTodo();
              },
            ),
          ),
        ],
      ]);
    }));
  }

  Future<void> _verVeterinaria(Map<String, dynamic> v) async {
    final horarios = await supabase
        .from('horarios_veterinaria')
        .select()
        .eq('veterinaria_id', v['id'])
        .order('dia')
        .order('abre');
    if (!mounted) return;

    const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final abierta = v['abierta_ahora'] == true;

    // Agrupa los tramos por día: "Lunes: 09:00–13:00, 15:00–19:00"
    final porDia = <int, List<String>>{};
    for (final h in horarios) {
      final tramo = '${(h['abre'] as String).substring(0, 5)}–${(h['cierra'] as String).substring(0, 5)}';
      porDia.putIfAbsent(h['dia'] as int, () => []).add(tramo);
    }
    final ordenSemana = [1, 2, 3, 4, 5, 6, 0]; // de lunes a domingo

    _hoja(Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.local_hospital, color: abierta ? Colors.greenAccent : Colors.grey, size: 30),
        const SizedBox(width: 10),
        Expanded(child: Text(v['nombre'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (abierta ? Colors.green : Colors.grey).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(abierta ? 'Abierta ahora' : 'Cerrada ahora',
            style: TextStyle(color: abierta ? Colors.greenAccent : Colors.white70, fontWeight: FontWeight.bold)),
      ),
      if (v['direccion'] != null) ...[const SizedBox(height: 10), Text('📍 ${v['direccion']}')],
      if (v['telefono'] != null) ...[const SizedBox(height: 6), Text('📞 ${v['telefono']}')],
      const SizedBox(height: 12),
      etiqueta('Horario'),
      if (v['es_24_horas'] == true)
        const Text('Abierta las 24 horas, todos los días')
      else
        ...ordenSemana.map((d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${dias[d]}: ${porDia[d]?.join(', ') ?? 'Cerrado'}',
                  style: const TextStyle(color: Colors.white70)),
            )),
      if (v['beneficio'] != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Colors.amber), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.local_offer, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(child: Text('Beneficio Paws: ${v['beneficio']}', style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
        ),
      ],
      const SizedBox(height: 20),
      BotonPrincipal(
        texto: 'Cómo llegar',
        icono: Icons.directions,
        onPressed: () => launchUrl(
          Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${v['latitud']},${v['longitud']}'),
          mode: LaunchMode.externalApplication,
        ),
      ),
    ]));
  }

  void _verVeterinariaOsm(VeterinariaOsm v) {
    final abierta = v.abiertaAhora;
    final estado = abierta == true ? 'Abierta ahora' : (abierta == false ? 'Cerrada ahora' : 'Horario no informado');
    final horario = v.horarioSemana();

    _hoja(Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.local_hospital, color: _colorVet(abierta), size: 30),
        const SizedBox(width: 10),
        Expanded(child: Text(v.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: _colorVet(abierta).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
        child: Text(estado, style: TextStyle(color: _colorVet(abierta), fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 10),
      Text('📍 ${v.direccion ?? 'Dirección no informada'}'),
      if (v.telefono != null) ...[
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('tel:${v.telefono!.replaceAll(' ', '')}')),
          child: Text('📞 ${v.telefono}', style: const TextStyle(decoration: TextDecoration.underline)),
        ),
      ],
      const SizedBox(height: 12),
      etiqueta('Horario'),
      if (horario.isEmpty)
        const Text('Esta veterinaria no tiene su horario publicado. Te recomendamos llamar antes de ir.',
            style: TextStyle(color: Colors.white70))
      else
        ...horario.map((linea) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(linea, style: const TextStyle(color: Colors.white70)),
            )),
      const SizedBox(height: 8),
      const Text('Datos: © colaboradores de OpenStreetMap', style: TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 16),
      BotonPrincipal(
        texto: 'Cómo llegar',
        icono: Icons.directions,
        onPressed: () => launchUrl(
          Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${v.punto.latitude},${v.punto.longitude}'),
          mode: LaunchMode.externalApplication,
        ),
      ),
    ]));
  }

  void _verZona(Map<String, dynamic> z) {
    final tipo = z['tipo'] as String;
    final estrellas = z['estrellas'] as int?;
    _hoja(Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(_iconoZona(tipo), color: _colorZona(tipo), size: 30),
        const SizedBox(width: 10),
        Expanded(child: Text(z['titulo'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 8),
      Text(_textoZona(tipo), style: TextStyle(color: _colorZona(tipo), fontWeight: FontWeight.bold)),
      if (estrellas != null) ...[
        const SizedBox(height: 8),
        Row(children: List.generate(5, (i) => Icon(i < estrellas ? Icons.star : Icons.star_border, color: Colors.amber))),
      ],
      if ((z['comentario'] ?? '').toString().isNotEmpty) ...[
        const SizedBox(height: 10),
        Text('"${z['comentario']}"', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
      ],
      const SizedBox(height: 10),
      Text('Reportado el ${_fechaHora(z['created_at'] as String)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
      if (z['autor_id'] == miId) ...[
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            label: const Text('Eliminar mi reporte', style: TextStyle(color: Colors.redAccent)),
            onPressed: () async {
              await supabase.from('zonas').delete().eq('id', z['id']);
              if (mounted) Navigator.pop(context);
              _cargarTodo();
            },
          ),
        ),
      ],
    ]));
  }

  // ------------------------------------------------------------------
  // CREAR: junta o zona (primero se toca el mapa para elegir el lugar)
  // ------------------------------------------------------------------
  void _alTocarMapa(LatLng punto) {
    if (!_eligiendoPunto) return;
    setState(() => _eligiendoPunto = false);
    if (_modo == Modo.juntas) _formularioEvento(punto);
    if (_modo == Modo.paseos) _formularioZona(punto);
  }

  void _formularioEvento(LatLng punto) {
    final titulo = TextEditingController();
    final descripcion = TextEditingController();
    final cupo = TextEditingController();
    DateTime? fecha;

    _hoja(StatefulBuilder(builder: (context, actualizar) {
      Future<void> elegirFecha() async {
        final dia = await showDatePicker(
            context: context, initialDate: DateTime.now(), firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 180)));
        if (dia == null || !context.mounted) return;
        final hora = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 11, minute: 0));
        if (hora == null) return;
        actualizar(() => fecha = DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute));
      }

      Future<void> crear() async {
        if (titulo.text.trim().isEmpty || fecha == null) {
          mostrarMensaje(context, 'Completa el título y la fecha', error: true);
          return;
        }
        // Validación en la app: la fecha debe ser futura
        if (fecha!.isBefore(DateTime.now())) {
          mostrarMensaje(context, 'La fecha debe ser futura', error: true);
          return;
        }
        try {
          final nuevo = await supabase.from('eventos').insert({
            'creador_id': miId,
            'titulo': titulo.text.trim(),
            'descripcion': descripcion.text.trim(),
            'fecha': fecha!.toUtc().toIso8601String(),
            'cupo': int.tryParse(cupo.text),
            'latitud': punto.latitude,
            'longitud': punto.longitude,
          }).select().single();
          // El creador queda inscrito con su mascota
          await supabase.from('evento_participantes').insert({'evento_id': nuevo['id'], 'mascota_id': widget.miMascotaId});
          if (context.mounted) Navigator.pop(context);
          mostrarMensaje(this.context, '¡Junta creada! 🎉');
          _cargarTodo();
        } catch (e) {
          mostrarMensaje(context, 'No se pudo crear: $e', error: true);
        }
      }

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Nueva junta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: titulo, decoration: decoracionCampo('Título, ej: Juntita en el parque', icono: Icons.title)),
            const SizedBox(height: 10),
            TextField(controller: descripcion, maxLines: 2, decoration: decoracionCampo('Descripción (opcional)')),
            const SizedBox(height: 10),
            TextField(
                controller: cupo,
                keyboardType: TextInputType.number,
                decoration: decoracionCampo('Cupo máximo (opcional)', icono: Icons.people)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colores.morado), minimumSize: const Size(double.infinity, 50)),
              onPressed: elegirFecha,
              icon: const Icon(Icons.event, color: Colores.rosa),
              label: Text(fecha == null ? 'Elegir fecha y hora' : _fechaHora(fecha!.toIso8601String()),
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            BotonPrincipal(texto: 'Crear junta', icono: Icons.check, onPressed: crear),
          ]),
        ),
      );
    }));
  }

  void _formularioZona(LatLng punto) {
    final titulo = TextEditingController();
    final comentario = TextEditingController();
    String tipo = 'recomendada';
    int estrellas = 5;

    _hoja(StatefulBuilder(builder: (context, actualizar) {
      Future<void> crear() async {
        if (titulo.text.trim().isEmpty) {
          mostrarMensaje(context, 'Escribe un título para el lugar', error: true);
          return;
        }
        try {
          await supabase.from('zonas').insert({
            'autor_id': miId,
            'tipo': tipo,
            'titulo': titulo.text.trim(),
            'comentario': comentario.text.trim(),
            'estrellas': tipo == 'recomendada' ? estrellas : null,
            'latitud': punto.latitude,
            'longitud': punto.longitude,
          });
          if (context.mounted) Navigator.pop(context);
          mostrarMensaje(this.context, '¡Gracias por avisar a la comunidad! 🐾');
          _cargarTodo();
        } catch (e) {
          mostrarMensaje(context, 'No se pudo guardar: $e', error: true);
        }
      }

      Widget opcion(String valor, String texto) => ChoiceChip(
            label: Text(texto),
            selected: tipo == valor,
            selectedColor: _colorZona(valor).withOpacity(0.4),
            onSelected: (_) => actualizar(() => tipo = valor),
          );

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Marcar zona de paseo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Wrap(spacing: 8, children: [
              opcion('recomendada', '🟢 Recomendada'),
              opcion('precaucion', '🟡 Precaución'),
              opcion('evitar', '🔴 Evitar'),
            ]),
            const SizedBox(height: 12),
            TextField(controller: titulo, decoration: decoracionCampo('Lugar, ej: Parque Forestal', icono: Icons.place)),
            const SizedBox(height: 10),
            TextField(
                controller: comentario,
                maxLines: 2,
                decoration: decoracionCampo(tipo == 'recomendada'
                    ? '¿Por qué es bueno? Ej: tranquilo, con agua'
                    : '¿Qué pasa? Ej: perros sueltos, vidrios')),
            if (tipo == 'recomendada') ...[
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(i < estrellas ? Icons.star : Icons.star_border, color: Colors.amber),
                    onPressed: () => actualizar(() => estrellas = i + 1),
                  ),
                ),
              ),
            ],
            if (tipo != 'recomendada')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Las alertas desaparecen solas a los 30 días.',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            const SizedBox(height: 20),
            BotonPrincipal(texto: 'Publicar', icono: Icons.check, onPressed: crear),
          ]),
        ),
      );
    }));
  }

  // ------------------------------------------------------------------
  // PANTALLA
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final puedeCrear = _modo != Modo.veterinarias;

    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _mapa,
          options: MapOptions(
            initialCenter: _yo,
            initialZoom: 13,
            onTap: (_, punto) => _alTocarMapa(punto),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.paws',
            ),
            MarkerLayer(markers: _marcadores()),
          ],
        ),
        // Selector de modo
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colores.tarjeta.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colores.morado),
            ),
            child: Row(children: [
              _botonModo(Modo.juntas, Icons.groups, 'Juntas'),
              _botonModo(Modo.veterinarias, Icons.local_hospital, 'Veterinarias'),
              _botonModo(Modo.paseos, Icons.park, 'Paseos'),
            ]),
          ),
        ),
        if (_modo == Modo.veterinarias)
          Positioned(
            top: 80,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colores.tarjeta.withOpacity(0.9), borderRadius: BorderRadius.circular(10)),
              child: const Text('🟢 Abierta   ⚪ Cerrada   🟡 Sin horario   ⭐ Convenio Paws',
                  style: TextStyle(fontSize: 11)),
            ),
          ),
        if (_eligiendoPunto)
          Positioned(
            bottom: 90,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colores.rosa, borderRadius: BorderRadius.circular(12)),
              child: const Text('Toca el mapa donde quieres marcar 📍',
                  textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
      ]),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.small(
          heroTag: 'ubicarme',
          backgroundColor: Colores.tarjeta,
          onPressed: _ubicarme,
          child: const Icon(Icons.my_location, color: Colors.blueAccent),
        ),
        const SizedBox(height: 10),
        if (_modo == Modo.veterinarias)
          FloatingActionButton.extended(
            heroTag: 'buscarVets',
            backgroundColor: Colores.rosa,
            onPressed: _buscandoVets ? null : () => _buscarVeterinarias(_mapa.camera.center),
            icon: _buscandoVets
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search),
            label: const Text('Buscar en esta zona'),
          ),
        if (puedeCrear)
          FloatingActionButton.extended(
            heroTag: 'crear',
            backgroundColor: _eligiendoPunto ? Colors.grey : Colores.rosa,
            onPressed: () => setState(() => _eligiendoPunto = !_eligiendoPunto),
            icon: Icon(_eligiendoPunto ? Icons.close : Icons.add),
            label: Text(_eligiendoPunto ? 'Cancelar' : (_modo == Modo.juntas ? 'Crear junta' : 'Marcar zona')),
          ),
      ]),
    );
  }

  Widget _botonModo(Modo modo, IconData icono, String texto) {
    final activo = _modo == modo;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _modo = modo;
            _eligiendoPunto = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: activo ? Colores.rosa : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Icon(icono, size: 20, color: Colors.white),
            Text(texto, style: TextStyle(fontSize: 12, fontWeight: activo ? FontWeight.bold : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }
}
