import 'package:flutter/material.dart';
import 'pet_profile_setup_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
                Text('Crear Cuenta ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                Icon(Icons.pets, color: Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 10),
            const Text('¡Estás a un paso de encontrarle mejores amigos a tu peludo!', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 20),
            // Alerta de seguridad y RUT restaurada
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0025),
                border: Border.all(color: Colors.pinkAccent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.pinkAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Registro seguro: Solicitamos tu RUT para verificar tu identidad y prevenir el robo de mascotas.', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _buildTextField('Tu Nombre Completo', 'Ej: Camila Soto', Icons.person_outline),
            // Campo de RUT agregado
            _buildTextField('RUT del Dueño', 'Ej: 12.345.678-K', Icons.badge_outlined),
            _buildTextField('Nombre de tu Mascota', 'Ej: Toby / Luna', Icons.pets),
            _buildTextField('Correo Electrónico', 'ejemplo@correo.com', Icons.email_outlined),
            _buildTextField('Contraseña', '••••••••', Icons.lock_outline, isPassword: true),
            const SizedBox(height: 30),
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PetProfileSetupScreen()));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Registrarme con Seguridad', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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

  Widget _buildTextField(String label, String hint, IconData icon, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            obscureText: isPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: Icon(icon, color: Colors.pinkAccent),
              suffixIcon: isPassword ? const Icon(Icons.visibility_off, color: Colors.white30) : null,
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
        ],
      ),
    );
  }
}