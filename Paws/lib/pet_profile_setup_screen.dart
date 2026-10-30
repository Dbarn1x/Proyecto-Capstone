import 'package:flutter/material.dart';
import 'match_screen.dart';

class PetProfileSetupScreen extends StatelessWidget {
  const PetProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F001A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.pinkAccent)),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Perfil de tu Peludo ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                Icon(Icons.camera_alt, color: Colors.white),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Sube las fotos y cuéntanos sobre su personalidad para encontrar los mejores matches.', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 25),
            
            _buildSectionTitle('1. Fotos de tu Mascota (3 fotos)', Icons.pets),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPhotoBox('Foto 1'),
                _buildPhotoBox('Foto 2'),
                _buildPhotoBox('Foto 3'),
              ],
            ),
            const SizedBox(height: 25),

            _buildSectionTitle('2. Fotos tuyas (3 fotos)', Icons.person),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPhotoBox('Foto 1'),
                _buildPhotoBox('Foto 2'),
                _buildPhotoBox('Foto 3'),
              ],
            ),
            const SizedBox(height: 25),

            _buildSectionTitle('3. Foto de ambos juntos (1 foto)', Icons.favorite),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1A0025),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF8A2BE2)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.pinkAccent, size: 30),
                  SizedBox(height: 8),
                  Text('Tú + Tu Mascota 🐶👤', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Text('Descripción y Personalidad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cuéntanos sobre tu mascota... ¿Es tímida, activa, juguetona?',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF150020),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8A2BE2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Nuevo botón inferior para avanzar al Match
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFD50032), Color(0xFF8A2BE2)]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 55),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchScreen()));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Guardar Perfil y Buscar Pareja', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Icon(Icons.favorite, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildPhotoBox(String label) {
    return Container(
      width: 100,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF1A0025),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8A2BE2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo, color: Colors.pinkAccent),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}