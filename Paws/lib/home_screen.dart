import 'package:flutter/material.dart';
import 'comun.dart';
import 'ubicacion.dart';
import 'welcome_screen.dart';
import 'pet_profile_setup_screen.dart';
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
  Map<String, dynamic>? _miMascota;

  static const _titulos = ['Descubrir', 'Mis matches', 'Mapa', 'Marketplace'];

  @override
  void initState() {
    super.initState();
    _cargarMiMascota();
    guardarMiUbicacion(); // actualiza mi ubicación cada vez que abro la app
  }

  Future<void> _cargarMiMascota() async {
    final lista = await supabase
        .from('mascotas')
        .select()
        .eq('dueno_id', miId)
        .order('created_at')
        .limit(1);

    if (!mounted) return;
    if (lista.isEmpty) {
      // Todavía no tiene mascota: la creamos primero
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetProfileSetupScreen()));
    } else {
      setState(() => _miMascota = lista.first);
    }
  }

  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_miMascota == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colores.rosa)));
    }
    final idMascota = _miMascota!['id'] as String;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colores.fondo,
        centerTitle: true,
        title: Text(_titulos[_pestana], style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colores.tarjeta,
            backgroundImage: (_miMascota!['fotos'] as List).isNotEmpty
                ? NetworkImage((_miMascota!['fotos'] as List).first as String)
                : null,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colores.rosa), tooltip: 'Cerrar sesión', onPressed: _cerrarSesion),
        ],
      ),
      // IndexedStack mantiene cada pestaña viva al cambiar de una a otra
      body: IndexedStack(
        index: _pestana,
        children: [
          MatchScreen(miMascota: _miMascota!),
          MatchesScreen(miMascotaId: idMascota),
          MapScreen(miMascotaId: idMascota),
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
