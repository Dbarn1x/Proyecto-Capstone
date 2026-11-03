import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Veterinaria obtenida de OpenStreetMap (datos abiertos y gratuitos)
class VeterinariaOsm {
  final String id;
  final String nombre;
  final LatLng punto;
  final String? direccion;
  final String? telefono;
  final String? horarioOriginal;          // texto tal cual viene de OSM
  final Map<int, List<String>> tramos;    // 1 = lunes … 7 = domingo → ["09:00-13:00", ...]
  final bool es24Horas;
  final bool horarioEntendido;            // false si el formato era muy raro

  VeterinariaOsm({
    required this.id,
    required this.nombre,
    required this.punto,
    this.direccion,
    this.telefono,
    this.horarioOriginal,
    required this.tramos,
    required this.es24Horas,
    required this.horarioEntendido,
  });

  bool get tieneHorario => es24Horas || (horarioEntendido && tramos.isNotEmpty);

  /// true = abierta, false = cerrada, null = no se sabe (sin horario)
  bool? get abiertaAhora {
    if (es24Horas) return true;
    if (!tieneHorario) return null;
    final ahora = DateTime.now();
    final minutos = ahora.hour * 60 + ahora.minute;
    for (final tramo in tramos[ahora.weekday] ?? <String>[]) {
      final partes = tramo.split('-');
      final abre = _aMinutos(partes[0]);
      var cierra = _aMinutos(partes[1]);
      if (cierra <= abre) cierra = 24 * 60; // ej: 20:00-02:00 → se cuenta hasta medianoche
      if (minutos >= abre && minutos < cierra) return true;
    }
    return false;
  }

  /// Horario de la semana en español, de lunes a domingo
  List<String> horarioSemana() {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    if (es24Horas) return ['Abierta las 24 horas, todos los días'];
    if (!horarioEntendido) return horarioOriginal == null ? [] : ['Horario: $horarioOriginal'];
    return List.generate(7, (i) {
      final t = tramos[i + 1];
      return '${dias[i]}: ${t == null || t.isEmpty ? 'Cerrado' : t.map((x) => x.replaceAll('-', '–')).join(', ')}';
    });
  }
}

int _aMinutos(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

/// Resultados ya buscados (por zona de ~1 km) para no volver a consultar
final Map<String, List<VeterinariaOsm>> _cache = {};

/// Consulta UN servidor; devuelve null si falla, se demora o está saturado
Future<Map<String, dynamic>?> _consultar(String servidor, String consulta) async {
  try {
    final r = await http.post(Uri.parse(servidor), body: {'data': consulta}).timeout(Duration(seconds: 15));
    if (r.statusCode != 200) return null;
    final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    // Saturado: a veces responde 200 pero con un aviso ("remark") y sin resultados
    if (json['remark'] != null && (json['elements'] as List).isEmpty) return null;
    return json;
  } catch (_) {
    return null;
  }
}

/// Busca veterinarias en un radio alrededor de un punto usando la API Overpass de OpenStreetMap
Future<List<VeterinariaOsm>> buscarVeterinariasOsm(LatLng centro, {int radioMetros = 3000}) async {
  final claveCache = '${centro.latitude.toStringAsFixed(2)},${centro.longitude.toStringAsFixed(2)}';
  if (_cache.containsKey(claveCache)) return _cache[claveCache]!;

  // Se busca de varias formas, porque en OpenStreetMap no todas están bien etiquetadas:
  //  1. lugares marcados como veterinaria (amenity / healthcare = veterinary)
  //  2. lugares con "veterin" o "vet" en el nombre (ej: una "Clínica Veterinaria"
  //     que alguien marcó como clínica de personas)
  final zona = '(around:$radioMetros,${centro.latitude},${centro.longitude})';
  final consulta = '''
[out:json][timeout:15];
(
  nwr["amenity"="veterinary"]$zona;
  nwr["healthcare"="veterinary"]$zona;
  nw["name"~"veterin|^vet[ .]|[ ]vet\$|petvet|vetcenter",i]$zona;
);
out center tags 200;
''';
  // Se consulta a 3 servidores públicos de OpenStreetMap AL MISMO TIEMPO
  // y se usa el primero que responda bien (si uno está saturado, no importa).
  const servidores = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];
  final primero = Completer<Map<String, dynamic>?>();
  var pendientes = servidores.length;
  for (final servidor in servidores) {
    _consultar(servidor, consulta).then((r) {
      pendientes--;
      if (primero.isCompleted) return;
      if (r != null) {
        primero.complete(r);
      } else if (pendientes == 0) {
        primero.complete(null); // ninguno respondió bien
      }
    });
  }
  final datos = await primero.future;
  if (datos == null) {
    throw Exception('Los servidores de OpenStreetMap están ocupados. Intenta de nuevo en un momento.');
  }

  final resultado = <VeterinariaOsm>[];

  final vistos = <String>{}; // evita repetidos (un lugar puede calzar con 2 reglas)
  for (final e in (datos['elements'] as List)) {
    if (!vistos.add('${e['type']}/${e['id']}')) continue;
    final tags = Map<String, dynamic>.from(e['tags'] ?? {});
    // Los "node" traen lat/lon; los "way" (edificios) traen un "center"
    final lat = (e['lat'] ?? e['center']?['lat']) as num?;
    final lon = (e['lon'] ?? e['center']?['lon']) as num?;
    if (lat == null || lon == null) continue;

    final calle = tags['addr:street'];
    final numero = tags['addr:housenumber'];
    final comuna = tags['addr:city'] ?? tags['addr:suburb'];
    String? direccion;
    if (calle != null) {
      direccion = [('$calle ${numero ?? ''}').trim(), if (comuna != null) comuna].join(', ');
    }

    final horario = tags['opening_hours'] as String?;
    final interpretado = interpretarHorario(horario);

    resultado.add(VeterinariaOsm(
      id: '${e['type']}/${e['id']}',
      nombre: (tags['name'] ?? 'Veterinaria') as String,
      punto: LatLng(lat.toDouble(), lon.toDouble()),
      direccion: direccion,
      telefono: (tags['phone'] ?? tags['contact:phone']) as String?,
      horarioOriginal: horario,
      tramos: interpretado.tramos,
      es24Horas: interpretado.es24Horas,
      horarioEntendido: interpretado.entendido,
    ));
  }
  _cache[claveCache] = resultado;
  return resultado;
}

/// Resultado de traducir el horario de OSM
class HorarioInterpretado {
  final Map<int, List<String>> tramos;
  final bool es24Horas;
  final bool entendido;
  HorarioInterpretado(this.tramos, this.es24Horas, this.entendido);
}

/// Traduce el formato "opening_hours" de OpenStreetMap. Entiende los casos comunes:
///   "24/7" · "Mo-Fr 09:00-19:00" · "Mo-Fr 09:00-13:00,15:00-19:00; Sa 10:00-14:00; Su off"
///   "Mo,We,Fr 10:00-18:00" · "09:00-20:00" (todos los días)
HorarioInterpretado interpretarHorario(String? texto) {
  if (texto == null || texto.trim().isEmpty) return HorarioInterpretado({}, false, false);
  final limpio = texto.trim();
  if (limpio == '24/7') return HorarioInterpretado({}, true, true);

  const codigos = {'Mo': 1, 'Tu': 2, 'We': 3, 'Th': 4, 'Fr': 5, 'Sa': 6, 'Su': 7};
  final tramos = <int, List<String>>{};
  final formatoHora = RegExp(r'^\d{1,2}:\d{2}-\d{1,2}:\d{2}$');

  for (var regla in limpio.split(';')) {
    regla = regla.trim();
    if (regla.isEmpty || regla.startsWith('PH')) continue; // feriados: se ignoran

    // Separar la parte de días ("Mo-Fr") de la parte de horas ("09:00-19:00")
    final m = RegExp(r'^((?:Mo|Tu|We|Th|Fr|Sa|Su)[A-Za-z,\- ]*?)?\s*(\d.*|off|closed)?$').firstMatch(regla);
    if (m == null) return HorarioInterpretado({}, false, false);
    final parteDias = m.group(1)?.replaceAll(' ', '');
    final parteHoras = m.group(2)?.trim();
    if (parteHoras == null) return HorarioInterpretado({}, false, false);

    // Días a los que aplica la regla
    final dias = <int>[];
    if (parteDias == null || parteDias.isEmpty) {
      dias.addAll([1, 2, 3, 4, 5, 6, 7]);
    } else {
      for (final pedazo in parteDias.split(',')) {
        if (pedazo == 'PH' || pedazo.isEmpty) continue;
        final rango = pedazo.split('-');
        final desde = codigos[rango.first];
        final hasta = codigos[rango.last];
        if (desde == null || hasta == null) return HorarioInterpretado({}, false, false);
        var d = desde;
        while (true) {
          dias.add(d);
          if (d == hasta) break;
          d = d == 7 ? 1 : d + 1; // permite rangos como Sa-Mo
        }
      }
    }

    // Horas
    final lista = <String>[];
    if (parteHoras != 'off' && parteHoras != 'closed') {
      for (final h in parteHoras.split(',')) {
        final t = h.trim();
        if (!formatoHora.hasMatch(t)) return HorarioInterpretado({}, false, false);
        final p = t.split('-');
        lista.add('${p[0].padLeft(5, '0')}-${p[1].padLeft(5, '0')}');
      }
    }
    // Las reglas posteriores reemplazan a las anteriores (así funciona OSM)
    for (final d in dias) {
      tramos[d] = List.of(lista);
    }
  }
  return HorarioInterpretado(tramos, false, tramos.isNotEmpty);
}
