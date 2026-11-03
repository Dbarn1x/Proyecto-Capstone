import 'package:flutter/material.dart';
import 'comun.dart';
import 'chat_screen.dart';

/// MIS MATCHES: mascotas con las que hubo like mutuo
class MatchesScreen extends StatefulWidget {
  final String miMascotaId;
  const MatchesScreen({super.key, required this.miMascotaId});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final id = widget.miMascotaId;
      // Se traen los datos de ambas mascotas del match usando sus llaves foráneas
      final lista = await supabase
          .from('matches')
          .select('id, created_at, '
              'a:mascotas!matches_mascota_a_fkey(id, nombre, fotos), '
              'b:mascotas!matches_mascota_b_fkey(id, nombre, fotos)')
          .or('mascota_a.eq.$id,mascota_b.eq.$id')
          .order('created_at', ascending: false);
      _matches = lista;
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'Error al cargar matches: $e', error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// De las dos mascotas del match, devuelve la que NO es mía
  Map<String, dynamic> _laOtra(Map<String, dynamic> match) {
    final a = match['a'] as Map<String, dynamic>;
    return a['id'] == widget.miMascotaId ? match['b'] as Map<String, dynamic> : a;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return Center(child: CircularProgressIndicator(color: Colores.rosa));

    return RefreshIndicator(
      color: Colores.rosa,
      onRefresh: _cargar,
      child: _matches.isEmpty
          ? ListView(children: [
              SizedBox(height: 150),
              Text('Todavía no tienes matches 💔\nDa like en Descubrir y desliza hacia abajo para actualizar.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colores.texto70, fontSize: 16)),
            ])
          : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: _matches.length,
              separatorBuilder: (_, __) => SizedBox(height: 10),
              itemBuilder: (_, i) {
                final match = _matches[i];
                final otra = _laOtra(match);
                final fotos = otra['fotos'] as List;
                final fecha = DateTime.parse(match['created_at'] as String).toLocal();
                return Container(
                  decoration: BoxDecoration(
                    color: Colores.tarjeta,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colores.morado),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colores.fondo,
                      backgroundImage: fotos.isNotEmpty ? NetworkImage(fotos.first as String) : null,
                      child: fotos.isEmpty ? Icon(Icons.pets) : null,
                    ),
                    title: Text(otra['nombre'] as String, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Match del ${fecha.day}/${fecha.month}/${fecha.year}',
                        style: TextStyle(color: Colores.texto54)),
                    trailing: Icon(Icons.chat_bubble, color: Colores.rosa),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(matchId: match['id'] as String, nombreOtra: otra['nombre'] as String),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
