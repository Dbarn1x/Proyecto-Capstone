import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'comun.dart';

/// CLIMA PARA PASEAR (API Open-Meteo: gratis, sin llave)
/// Muestra la temperatura actual y las mejores horas de hoy para sacar a pasear.
/// Regla: hora ideal = entre 10 °C y 24 °C y probabilidad de lluvia menor a 30 %.
class ClimaPaseo extends StatefulWidget {
  final LatLng punto;
  const ClimaPaseo({super.key, required this.punto});

  @override
  State<ClimaPaseo> createState() => _ClimaPaseoState();
}

class _ClimaPaseoState extends State<ClimaPaseo> {
  double? _tempActual;
  String _consejo = 'Consultando el clima...';
  String _mejoresHoras = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  bool _esIdeal(double temp, num lluvia) => temp >= 10 && temp <= 24 && lluvia < 30;

  Future<void> _cargar() async {
    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast'
          '?latitude=${widget.punto.latitude}&longitude=${widget.punto.longitude}'
          '&current=temperature_2m,precipitation'
          '&hourly=temperature_2m,precipitation_probability'
          '&forecast_days=1&timezone=auto');
      final r = await http.get(url);
      final datos = jsonDecode(r.body) as Map<String, dynamic>;

      final temp = (datos['current']['temperature_2m'] as num).toDouble();
      final lloviendo = (datos['current']['precipitation'] as num) > 0;
      final horas = (datos['hourly']['time'] as List).cast<String>();
      final temps = (datos['hourly']['temperature_2m'] as List).map((t) => (t as num).toDouble()).toList();
      final lluvias = (datos['hourly']['precipitation_probability'] as List).map((p) => (p ?? 0) as num).toList();

      // Consejo según la temperatura de ahora
      String consejo;
      if (lloviendo) {
        consejo = '🌧️ Está lloviendo: mejor un paseo corto';
      } else if (temp > 26) {
        consejo = '🔥 Mucho calor: el pavimento puede quemar sus patitas';
      } else if (temp < 8) {
        consejo = '🥶 Hace frío: abrígalo si es pequeño o de pelo corto';
      } else if (temp >= 10 && temp <= 24) {
        consejo = '✅ ¡Buen momento para pasear!';
      } else {
        consejo = '🙂 Clima aceptable para un paseo';
      }

      // Mejores horas desde ahora hasta el final del día (agrupadas en tramos)
      final ahora = DateTime.now().hour;
      final tramos = <String>[];
      int? inicio;
      for (var i = 0; i < horas.length; i++) {
        final hora = int.parse(horas[i].substring(11, 13));
        final ideal = hora >= ahora && hora >= 7 && hora <= 22 && _esIdeal(temps[i], lluvias[i]);
        if (ideal && inicio == null) inicio = hora;
        if (!ideal && inicio != null) {
          tramos.add('$inicio–$hora h');
          inicio = null;
        }
      }
      if (inicio != null) tramos.add('$inicio–23 h');

      if (!mounted) return;
      setState(() {
        _tempActual = temp;
        _consejo = consejo;
        _mejoresHoras = tramos.isEmpty ? 'Hoy no quedan horas ideales' : 'Mejores horas hoy: ${tramos.take(3).join(', ')}';
      });
    } catch (e) {
      if (mounted) setState(() => _consejo = 'No se pudo cargar el clima');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colores.tarjeta.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colores.morado),
      ),
      child: Row(children: [
        Text(_tempActual == null ? '…' : '${_tempActual!.round()}°',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colores.rosa)),
        SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_consejo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            if (_mejoresHoras.isNotEmpty)
              Text(_mejoresHoras, style: TextStyle(color: Colores.texto70, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
