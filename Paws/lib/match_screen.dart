import 'package:flutter/material.dart';
import 'map_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final List<Map<String, String>> _pets = [
    {
      'name': 'Max',
      'breed': 'Golden Retriever',
      'age': '2 años',
      'distance': 'A 2 km de ti',
      'image': 'https://images.unsplash.com/photo-1552053831-71594a27632d?q=80&w=800&auto=format&fit=crop'
    },
    {
      'name': 'Luna',
      'breed': 'Husky Siberiano',
      'age': '1 año',
      'distance': 'A 5 km de ti',
      'image': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'
    },
    {
      'name': 'Rocky',
      'breed': 'Bulldog Francés',
      'age': '3 años',
      'distance': 'A 1 km de ti',
      'image': 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?q=80&w=800&auto=format&fit=crop'
    }
  ];

  void _swipeCard() {
    setState(() {
      if (_pets.isNotEmpty) {
        _pets.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F001A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Descubrir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person, color: Colors.pinkAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _pets.isEmpty
          ? const Center(
              child: Text('¡No hay más perritos cerca! 😢\nVuelve más tarde.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18)))
          : Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: _pets.reversed.map((pet) {
                      int index = _pets.indexOf(pet);
                      bool isFront = index == 0;

                      return Dismissible(
                        key: Key(pet['name']!),
                        onDismissed: (direction) => _swipeCard(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.only(
                            top: isFront ? 0 : 20.0,
                            bottom: isFront ? 0 : 20.0,
                            left: isFront ? 20 : 30.0,
                            right: isFront ? 20 : 30.0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isFront ? Colors.pinkAccent : Colors.white24, width: 2),
                            boxShadow: isFront
                                ? [const BoxShadow(color: Colors.pinkAccent, blurRadius: 15, spreadRadius: -5)]
                                : [],
                            image: DecorationImage(
                              image: NetworkImage(pet['image']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                                stops: const [0.0, 0.4],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(pet['name']!, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 10),
                                      Text(pet['age']!, style: const TextStyle(color: Colors.white70, fontSize: 22)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.pets, color: Colors.pinkAccent, size: 16),
                                      const SizedBox(width: 5),
                                      Text(pet['breed']!, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.blueAccent, size: 16),
                                      const SizedBox(width: 5),
                                      Text(pet['distance']!, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRoundButton(Icons.close, Colors.redAccent, _swipeCard, size: 60),
                      _buildRoundButton(Icons.star, Colors.blueAccent, _swipeCard, size: 50),
                      _buildRoundButton(Icons.favorite, Colors.greenAccent, _swipeCard, size: 60),
                    ],
                  ),
                ),
                // BOTÓN PARA EXPLORAR GPS EN TIEMPO REAL
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A0025),
                      side: const BorderSide(color: Colors.blueAccent, width: 2),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      shadowColor: Colors.blueAccent.withOpacity(0.5),
                      elevation: 10,
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
                    },
                    icon: const Icon(Icons.location_on, color: Colors.blueAccent, size: 24),
                    label: const Text('Explorar GPS en tiempo real', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildRoundButton(IconData icon, Color color, VoidCallback onPressed, {double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A0025),
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.5),
        onPressed: onPressed,
      ),
    );
  }
}