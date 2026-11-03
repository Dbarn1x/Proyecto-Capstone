import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comun.dart';

/// Una foto puede ser una que ya está en Storage (url) o una nueva elegida de la galería (bytes)
class Foto {
  final String? url;
  final Uint8List? bytes;
  const Foto.url(this.url) : bytes = null;
  const Foto.nueva(this.bytes) : url = null;

  ImageProvider get imagen => bytes != null ? MemoryImage(bytes!) : NetworkImage(url!) as ImageProvider;
}

/// Abre la galería y devuelve la foto elegida (null si se cancela)
Future<Uint8List?> elegirFoto() async {
  final archivo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 75);
  if (archivo == null) return null;
  return await archivo.readAsBytes();
}

/// Sube una foto a Storage, dentro de la carpeta del usuario (fotos/<su id>/...)
Future<String> subirFoto(Uint8List bytes, String nombre) async {
  final ruta = '$miId/${nombre}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await supabase.storage.from('fotos').uploadBinary(ruta, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
  return supabase.storage.from('fotos').getPublicUrl(ruta);
}

/// Devuelve las URLs de una lista de fotos, subiendo solo las nuevas
Future<List<String>> guardarFotos(List<Foto> fotos, String prefijo) async {
  final urls = <String>[];
  for (int i = 0; i < fotos.length; i++) {
    urls.add(fotos[i].url ?? await subirFoto(fotos[i].bytes!, '${prefijo}_$i'));
  }
  return urls;
}

/// Fila de 3 casilleros de foto: tocar uno vacío agrega, tocar uno con foto la quita
class SelectorFotos extends StatelessWidget {
  final List<Foto> fotos;
  final VoidCallback alCambiar;
  const SelectorFotos({super.key, required this.fotos, required this.alCambiar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final tieneFoto = i < fotos.length;
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              if (tieneFoto) {
                fotos.removeAt(i);
                alCambiar();
              } else if (fotos.length < 3) {
                final f = await elegirFoto();
                if (f != null) {
                  fotos.add(Foto.nueva(f));
                  alCambiar();
                }
              }
            },
            child: Container(
              height: 110,
              margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
              decoration: BoxDecoration(
                color: Colores.tarjeta,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colores.morado),
                image: tieneFoto ? DecorationImage(image: fotos[i].imagen, fit: BoxFit.cover) : null,
              ),
              child: tieneFoto
                  ? const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: CircleAvatar(
                            radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                      ))
                  : const Icon(Icons.add_a_photo, color: Colores.rosa),
            ),
          ),
        );
      }),
    );
  }
}

/// Un solo casillero grande (ej: la foto del dueño junto a su mascota)
class SelectorFotoUnica extends StatelessWidget {
  final Foto? foto;
  final String texto;
  final ValueChanged<Foto> alElegir;
  const SelectorFotoUnica({super.key, required this.foto, required this.texto, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final f = await elegirFoto();
        if (f != null) alElegir(Foto.nueva(f));
      },
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colores.tarjeta,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colores.morado),
          image: foto != null ? DecorationImage(image: foto!.imagen, fit: BoxFit.cover) : null,
        ),
        child: foto != null
            ? null
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_a_photo, color: Colores.rosa, size: 30),
                const SizedBox(height: 8),
                Text(texto),
              ]),
      ),
    );
  }
}
