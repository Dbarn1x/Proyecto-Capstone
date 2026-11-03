import 'package:flutter/material.dart';
import 'comun.dart';

/// DESCUBRIR: tarjetas de mascotas cercanas ordenadas por compatibilidad
class MatchScreen extends StatefulWidget {
  final Map<String, dynamic> miMascota;
  const MatchScreen({super.key, required this.miMascota});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  List<Map<String, dynamic>> _candidatos = [];
  List<Map<String, dynamic>> _especies = [];
  int? _especieFiltro; // null = todas
  double _radioKm = 15;
  bool _cargando = true;

  String get _miMascotaId => widget.miMascota['id'] as String;

  @override
  void initState() {
    super.initState();
    _cargarEspecies();
    _buscar();
  }

  Future<void> _cargarEspecies() async {
    final lista = await supabase.from('especies').select().order('id');
    if (mounted) setState(() => _especies = lista);
  }

  /// Llama a la función buscar_candidatos de la base de datos (usa PostGIS)
  Future<void> _buscar() async {
    setState(() => _cargando = true);
    try {
      final resultado = await supabase.rpc('buscar_candidatos', params: {
        'p_mascota': _miMascotaId,
        'p_radio_km': _radioKm,
        'p_especie': _especieFiltro,
      });
      _candidatos = List<Map<String, dynamic>>.from(resultado as List);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'Error al buscar: $e', error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// tipo = 'like', 'superlike' o 'pass'
  Future<void> _votar(String tipo) async {
    if (_candidatos.isEmpty) return;
    final otra = _candidatos.first;
    setState(() => _candidatos.removeAt(0));

    try {
      await supabase.from('likes').insert({
        'origen_id': _miMascotaId,
        'destino_id': otra['id'],
        'tipo': tipo,
      });

      // Si fue like, el TRIGGER crear_match ya creó el match si era mutuo
      if (tipo != 'pass') {
        final a = _miMascotaId;
        final b = otra['id'] as String;
        final match = await supabase
            .from('matches')
            .select('id')
            .or('and(mascota_a.eq.$a,mascota_b.eq.$b),and(mascota_a.eq.$b,mascota_b.eq.$a)')
            .maybeSingle();
        if (match != null && mounted) _mostrarMatch(otra);
      }
    } catch (e) {
      final texto = e.toString().contains('propias mascotas') ? 'No puedes hacer match entre tus propias mascotas' : 'No se pudo guardar: $e';
      if (mounted) mostrarMensaje(context, texto, error: true);
    }
  }

  void _mostrarMatch(Map<String, dynamic> otra) {
    final misFotos = widget.miMascota['fotos'] as List;
    final susFotos = otra['fotos'] as List;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colores.tarjeta,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colores.rosa)),
        title: Text('¡Es un match! 🎉', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _avatar(misFotos),
            Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.favorite, color: Colores.rosa, size: 32)),
            _avatar(susFotos),
          ]),
          SizedBox(height: 15),
          Text('${widget.miMascota['nombre']} y ${otra['nombre']} se gustaron. ¡Coordinen una salida en Mis matches!',
              textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Seguir buscando', style: TextStyle(color: Colores.rosa))),
        ],
      ),
    );
  }

  Widget _avatar(List fotos) => CircleAvatar(
        radius: 38,
        backgroundColor: Colores.fondo,
        backgroundImage: fotos.isNotEmpty ? NetworkImage(fotos.first as String) : null,
        child: fotos.isEmpty ? Icon(Icons.pets) : null,
      );

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colores.tarjeta,
      builder: (_) => StatefulBuilder(
        builder: (context, actualizar) => Padding(
          padding: EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            etiqueta('Especie'),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                label: Text('Todas'),
                selected: _especieFiltro == null,
                onSelected: (_) => actualizar(() => _especieFiltro = null),
              ),
              ..._especies.map((e) => ChoiceChip(
                    label: Text(e['nombre'] as String),
                    selected: _especieFiltro == e['id'],
                    onSelected: (_) => actualizar(() => _especieFiltro = e['id'] as int),
                  )),
            ]),
            SizedBox(height: 16),
            etiqueta('Distancia máxima: ${_radioKm.round()} km'),
            Slider(
              value: _radioKm, min: 1, max: 50, divisions: 49,
              activeColor: Colores.rosa,
              onChanged: (v) => actualizar(() => _radioKm = v),
            ),
            SizedBox(height: 10),
            BotonPrincipal(
              texto: 'Aplicar filtros',
              onPressed: () {
                Navigator.pop(context);
                _buscar();
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(children: [
          Expanded(
            child: Text('Buscando amigos para ${widget.miMascota['nombre']}',
                style: TextStyle(color: Colores.texto70)),
          ),
          IconButton(icon: Icon(Icons.tune, color: Colores.rosa), tooltip: 'Filtros', onPressed: _abrirFiltros),
          IconButton(icon: Icon(Icons.refresh, color: Colores.rosa), tooltip: 'Actualizar', onPressed: _buscar),
        ]),
      ),
      Expanded(child: _contenido()),
      if (_candidatos.isNotEmpty)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _botonRedondo(Icons.close, Colors.redAccent, () => _votar('pass'), size: 60),
            _botonRedondo(Icons.star, Colors.blueAccent, () => _votar('superlike'), size: 50),
            _botonRedondo(Icons.favorite, Colors.greenAccent, () => _votar('like'), size: 60),
          ]),
        ),
    ]);
  }

  Widget _contenido() {
    if (_cargando) return Center(child: CircularProgressIndicator(color: Colores.rosa));
    if (_candidatos.isEmpty) {
      return Center(
        child: Text('¡No hay más mascotas cerca! 😢\nPrueba ampliando la distancia en los filtros.',
            textAlign: TextAlign.center, style: TextStyle(color: Colores.texto70, fontSize: 16)),
      );
    }
    // Se dibujan 2 tarjetas: la de atrás y la de adelante (la única que se desliza)
    final visibles = _candidatos.take(2).toList().reversed.toList();
    return Stack(
      fit: StackFit.expand, // las tarjetas ocupan todo el espacio disponible
      children: visibles.map((m) {
        final esLaPrimera = identical(m, _candidatos.first);
        final tarjeta = _tarjeta(m, esLaPrimera);
        if (!esLaPrimera) return tarjeta;
        return Dismissible(
          key: ValueKey(m['id']),
          // Deslizar a la derecha = like, a la izquierda = pass
          onDismissed: (dir) => _votar(dir == DismissDirection.startToEnd ? 'like' : 'pass'),
          child: tarjeta,
        );
      }).toList(),
    );
  }

  Widget _tarjeta(Map<String, dynamic> m, bool adelante) {
    final fotos = m['fotos'] as List;
    final compat = m['compatibilidad'] as int;
    final colorCompat = compat >= 75 ? Colors.greenAccent : (compat >= 50 ? Colors.amber : Colors.redAccent);
    final distancia = m['distancia_km'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: adelante ? 20 : 30, vertical: adelante ? 0 : 15),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: adelante ? Colores.rosa : Colores.texto24, width: 2),
        boxShadow: adelante ? [BoxShadow(color: Colores.rosa, blurRadius: 15, spreadRadius: -5)] : [],
        image: fotos.isNotEmpty ? DecorationImage(image: NetworkImage(fotos.first as String), fit: BoxFit.cover) : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.9), Colors.transparent],
            stops: [0.0, 0.5],
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Etiqueta de compatibilidad
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorCompat, width: 2),
              ),
              child: Text('$compat% compatible', style: TextStyle(color: colorCompat, fontWeight: FontWeight.bold)),
            ),
          ),
          Spacer(),
          Text(m['nombre'] as String,
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Row(children: [
            Icon(Icons.pets, color: Colores.rosa, size: 16),
            SizedBox(width: 5),
            Text('${m['especie']}${m['raza'] != null ? ' · ${m['raza']}' : ''} · ${m['sexo']}',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
          ]),
          if (distancia != null) ...[
            SizedBox(height: 5),
            Row(children: [
              Icon(Icons.location_on, color: Colors.blueAccent, size: 16),
              SizedBox(width: 5),
              Text('A $distancia km de ti', style: TextStyle(color: Colors.white70, fontSize: 16)),
            ]),
          ],
          // Dueño verificado: foto, primer nombre y la foto de ambos juntos
          if (m['nombre_dueno'] != null) ...[
            SizedBox(height: 10),
            Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colores.rojo,
                backgroundImage: m['foto_dueno'] != null ? NetworkImage(m['foto_dueno'] as String) : null,
              ),
              SizedBox(width: 8),
              Text('${m['nombre_dueno']}', style: TextStyle(color: Colors.white)),
              SizedBox(width: 6),
              Icon(Icons.verified, color: Colors.lightBlueAccent, size: 16),
              Text(' RUT verificado', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Spacer(),
              if (m['foto_con_dueno'] != null)
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  onPressed: () => _verFotoJuntos(m),
                  icon: Icon(Icons.photo, color: Colores.rosa, size: 18),
                  label: Text('Juntos', style: TextStyle(color: Colores.rosa)),
                ),
            ]),
          ],
          if ((m['descripcion'] ?? '').toString().isNotEmpty) ...[
            SizedBox(height: 8),
            Text(m['descripcion'] as String,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70)),
          ],
        ]),
      ),
    );
  }

  void _verFotoJuntos(Map<String, dynamic> m) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colores.tarjeta,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(m['foto_con_dueno'] as String, fit: BoxFit.cover),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Text('${m['nombre_dueno']} junto a ${m['nombre']} 🐾'),
          ),
        ]),
      ),
    );
  }

  Widget _botonRedondo(IconData icono, Color color, VoidCallback onPressed, {double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colores.tarjeta,
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
      ),
      child: IconButton(icon: Icon(icono, color: color, size: size * 0.5), onPressed: onPressed),
    );
  }
}
