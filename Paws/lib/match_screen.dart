import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class PetModel {
  final String id;
  final String name;
  final String breed;
  final int age;
  final LatLng location;
  String distanceText;
  final String imageUrl;
  final String bio;

  PetModel({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.location,
    this.distanceText = 'Calculando GPS...',
    required this.imageUrl,
    required this.bio,
  });
}

class SponsorShop {
  final String id;
  final String name;
  final String category;
  final LatLng location;
  final String discount;

  SponsorShop({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.discount,
  });
}

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final MapController _mapController = MapController();
  LatLng _userPosition = const LatLng(-33.4489, -70.6693);
  bool _isLoadingLocation = false;
  String _gpsStatusText = "Buscando señal GPS...";

  List<PetModel> pets = [
    PetModel(
      id: '1',
      name: 'Rocky',
      breed: 'Golden Retriever',
      age: 2,
      location: const LatLng(-33.4450, -70.6650),
      imageUrl: 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80',
      bio: 'Amante de las pelotas de tenis y los paseos en el parque. ¡Muy juguetón!',
    ),
    PetModel(
      id: '2',
      name: 'Luna',
      breed: 'Husky Siberiano',
      age: 3,
      location: const LatLng(-33.4520, -70.6730),
      imageUrl: 'https://images.unsplash.com/photo-1605568427561-40dd23c2acea?auto=format&fit=crop&w=800&q=80',
      bio: 'Le encanta correr por las mañanas. Buscando compañero de aventuras.',
    ),
    PetModel(
      id: '3',
      name: 'Toby',
      breed: 'Beagle',
      age: 1,
      location: const LatLng(-33.4470, -70.6720),
      imageUrl: 'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?auto=format&fit=crop&w=800&q=80',
      bio: 'Curioso y glotón. ¿Salimos a olfatear nuevos lugares?',
    ),
  ];

  List<SponsorShop> sponsors = [
    SponsorShop(
      id: 's1',
      name: 'PetShop Guau & Miau',
      category: 'Tienda & Alimentos',
      location: const LatLng(-33.4475, -70.6670),
      discount: '15% desc. mostrando MatchPet',
    ),
    SponsorShop(
      id: 's2',
      name: 'Veterinaria San Francisco',
      category: 'Urgencias 24/7',
      location: const LatLng(-33.4505, -70.6710),
      discount: 'Consulta de revisión gratis',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionYCalcularDistancias();
  }

  Future<void> _obtenerUbicacionYCalcularDistancias() async {
    setState(() {
      _isLoadingLocation = true;
      _gpsStatusText = "Obteniendo GPS...";
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoadingLocation = false;
        _gpsStatusText = "GPS Desactivado";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoadingLocation = false;
          _gpsStatusText = "Permiso GPS Denegado";
        });
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    LatLng userLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _userPosition = userLatLng;
      _isLoadingLocation = false;
      _gpsStatusText = "Mapa Activo";

      _mapController.move(userLatLng, 15.0);

      for (var pet in pets) {
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          pet.location.latitude,
          pet.location.longitude,
        );

        if (distanceInMeters >= 1000) {
          pet.distanceText = '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
        } else {
          pet.distanceText = '${distanceInMeters.round()} m';
        }
      }
    });
  }

  void _mostrarDetalleMascota(PetModel pet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF180528),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFFFF2A55), width: 2)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(pet.imageUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pet.name}, ${pet.age} años',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          pet.breed,
                          style: const TextStyle(color: Color(0xFFFF2A55), fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF00E676), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'A ${pet.distanceText} de ti',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(pet.bio, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2A55),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('¡Solicitud enviada a ${pet.name}! 🐾')),
                    );
                  },
                  icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                  label: const Text('Conectar / Match', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDetalleSponsor(SponsorShop shop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF180528),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFFFFCC00), width: 2)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFFFFCC00), size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              shop.name,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Color(0xFFFFCC00), size: 18),
                          ],
                        ),
                        Text(shop.category, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCC00)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_rounded, color: Color(0xFFFFCC00)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Beneficio exclusivo: ${shop.discount}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.directions_walk_rounded, color: Colors.black),
                  label: const Text('Cómo Llegar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080010),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: _isLoadingLocation
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF2A55)))
              : const Icon(Icons.my_location_rounded, color: Color(0xFFFF2A55)),
          onPressed: _obtenerUbicacionYCalcularDistancias,
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, color: Color(0xFFFF2A55)),
            SizedBox(width: 8),
            Text('Mapa Interactivo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userPosition,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userPosition,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF2A55).withOpacity(0.3),
                        border: Border.all(color: const Color(0xFFFF2A55), width: 3),
                      ),
                      child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                  ...pets.map(
                    (pet) => Marker(
                      point: pet.location,
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _mostrarDetalleMascota(pet),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFF2A55), width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Color(0x80FF2A55), blurRadius: 10),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(pet.imageUrl),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ...sponsors.map(
                    (shop) => Marker(
                      point: shop.location,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _mostrarDetalleSponsor(shop),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF180528),
                            border: Border.all(color: const Color(0xFFFFCC00), width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x80FFCC00), blurRadius: 8),
                            ],
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Color(0xFFFFCC00), size: 26),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF180528).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF2A55).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _gpsStatusText == "Mapa Activo" ? Icons.gps_fixed : Icons.gps_not_fixed,
                    size: 16,
                    color: _gpsStatusText == "Mapa Activo" ? const Color(0xFF00E676) : const Color(0xFFFF2A55),
                  ),
                  const SizedBox(width: 8),
                  Text(_gpsStatusText, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}