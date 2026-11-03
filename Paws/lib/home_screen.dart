import 'package:flutter/material.dart';
import 'comun.dart';
import 'ubicacion.dart';
import 'pet_profile_setup_screen.dart';
import 'configuracion_screen.dart';
import 'match_screen.dart';
import 'matches_screen.dart';
import 'map_screen.dart';
import 'marketplace_screen.dart';

/// Pantalla principal con 4 pestañas abajo
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pestana = 0;
  Map<String, dynamic>? _miMascota; // la mascota con la que busco amigos

  static const _titulos = ['Descubrir', 'Mis matches', 'Mapa', 'Marketplace'];

  @override
  void initState() {
    super.initState();
    _cargarMiMascota();
    guardarMiUbicacion(); // actualiza mi ubicación cada vez que abro la app
  }

  Future<void> _cargarMiMascota() async {
    final lista = await supabase.from('mascotas').select().eq('dueno_id', miId).order('created_at');

    if (!mounted) return;
    if (lista.isEmpty) {
      // Todavía no tiene mascota (o borró todas): la creamos primero
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetProfileSetupScreen()));
      return;
    }
    // Si tiene varias, se usa la que eligió en Configuración (o la primera)
    final activa = await leerMascotaActiva();
    setState(() {
      _miMascota = lista.firstWhere((m) => m['id'] == activa, orElse: () => lista.first);
    });
  }

  Future<void> _abrirConfiguracion() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionScreen()));
    _cargarMiMascota(); // al volver: pudo cambiar la mascota activa, su foto o su nombre
  }

  @override
  Widget build(BuildContext context) {
    if (_miMascota == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colores.rosa)));
    }
    final idMascota = _miMascota!['id'] as String;
    final fotos = _miMascota!['fotos'] as List;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colores.fondo,
        centerTitle: true,
        title: Text(_titulos[_pestana], style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: _abrirConfiguracion,
            child: CircleAvatar(
              backgroundColor: Colores.tarjeta,
              backgroundImage: fotos.isNotEmpty ? NetworkImage(fotos.first as String) : null,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colores.rosa),
            tooltip: 'Configuración',
            onPressed: _abrirConfiguracion,
          ),
        ],
      ),
      // IndexedStack mantiene cada pestaña viva al cambiar de una a otra.
      // La "key" con el id de la mascota hace que se recarguen si cambia la mascota activa.
      body: IndexedStack(
        index: _pestana,
        children: [
          MatchScreen(key: ValueKey('descubrir_$idMascota'), miMascota: _miMascota!),
          MatchesScreen(key: ValueKey('matches_$idMascota'), miMascotaId: idMascota),
          MapScreen(key: ValueKey('mapa_$idMascota'), miMascotaId: idMascota),
          const MarketplaceScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _pestana,
        onTap: (i) => setState(() => _pestana = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colores.tarjeta,
        selectedItemColor: Colores.rosa,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Descubrir'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
        ],
      ),
    );
  }
}
