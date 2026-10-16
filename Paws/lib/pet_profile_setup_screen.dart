import 'package:flutter/material.dart';

class PetProfileSetupScreen extends StatefulWidget {
  const PetProfileSetupScreen({super.key});

  @override
  State<PetProfileSetupScreen> createState() => _PetProfileSetupScreenState();
}

class _PetProfileSetupScreenState extends State<PetProfileSetupScreen> {
  final List<bool> _petPhotos = [false, false, false];
  final List<bool> _ownerPhotos = [false, false, false];
  bool _togetherPhoto = false;

  final TextEditingController _descriptionController = TextEditingController();

  final String _mockPetImage = 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=400&q=80';
  final String _mockOwnerImage = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';
  final String _mockTogetherImage = 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=600&q=80';

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado RGB (Negro -> Púrpura -> Rojo Neón)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF05000A),
                  Color(0xFF380045),
                  Color(0xFF7A002A),
                  Color(0xFFD50032),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botón Volver
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF180528).withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF2A55), width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A55).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Perfil de tu Peludo 📸',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sube las fotos y cuéntanos sobre su personalidad para encontrar los mejores matches.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECCIÓN 1: FOTOS DE LA MASCOTA
                    _buildDarkSectionHeader(
                      title: '1. Fotos de tu Mascota (3 fotos)',
                      icon: Icons.pets_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(3, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index < 2 ? 10.0 : 0),
                            child: _buildDarkPhotoBox(
                              isSet: _petPhotos[index],
                              imageUrl: _mockPetImage,
                              label: 'Foto ${index + 1}',
                              onTap: () {
                                setState(() {
                                  _petPhotos[index] = !_petPhotos[index];
                                });
                              },
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // SECCIÓN 2: FOTOS TUYAS
                    _buildDarkSectionHeader(
                      title: '2. Fotos tuyas (3 fotos)',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(3, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index < 2 ? 10.0 : 0),
                            child: _buildDarkPhotoBox(
                              isSet: _ownerPhotos[index],
                              imageUrl: _mockOwnerImage,
                              label: 'Foto ${index + 1}',
                              onTap: () {
                                setState(() {
                                  _ownerPhotos[index] = !_ownerPhotos[index];
                                });
                              },
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // SECCIÓN 3: FOTO JUNTOS
                    _buildDarkSectionHeader(
                      title: '3. Foto de ambos juntos (1 foto)',
                      icon: Icons.favorite_rounded,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      width: double.infinity,
                      child: _buildDarkPhotoBox(
                        isSet: _togetherPhoto,
                        imageUrl: _mockTogetherImage,
                        label: 'Tú + Tu Mascota 🐶👤',
                        onTap: () {
                          setState(() {
                            _togetherPhoto = !_togetherPhoto;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SECCIÓN 4: DESCRIPCIÓN
                    const Text(
                      'Descripción y Personalidad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF140822).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF8E24AA), width: 1.8),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cuéntanos sobre tu mascota... ¿Es tímida, activa, juguetona? ¿Le asustan los ruidos o le encanta correr con otros perritos?',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13.5, height: 1.4),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // BOTÓN GUARDAR Y FINALIZAR
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFD50032),
                            Color(0xFF8E24AA),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD50032).withOpacity(0.5),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Perfil completado con éxito! 🎉🐾'),
                              backgroundColor: Color(0xFFD50032),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Guardar y Finalizar 🚀',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFF2A55)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDarkPhotoBox({
    required bool isSet,
    required String imageUrl,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 105,
        decoration: BoxDecoration(
          color: const Color(0xFF140822).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSet ? const Color(0xFFFF2A55) : const Color(0xFF8E24AA).withOpacity(0.8),
            width: isSet ? 2.2 : 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isSet ? const Color(0xFFFF2A55).withOpacity(0.4) : Colors.black.withOpacity(0.5),
              blurRadius: isSet ? 10 : 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: isSet
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(imageUrl, fit: BoxFit.cover),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF2A55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    )
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2A55).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: Color(0xFFFF2A55),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}