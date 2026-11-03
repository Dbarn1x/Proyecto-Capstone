import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comun.dart';
import 'marketplace_screen.dart';

/// PUBLICAR un producto en el marketplace
class PublicarProductoScreen extends StatefulWidget {
  const PublicarProductoScreen({super.key});

  @override
  State<PublicarProductoScreen> createState() => _PublicarProductoScreenState();
}

class _PublicarProductoScreenState extends State<PublicarProductoScreen> {
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _precio = TextEditingController();
  final _precioOriginal = TextEditingController();
  final _whatsapp = TextEditingController();

  String _categoria = 'Camas';
  String _estado = 'usado';
  DateTime? _vencimiento;
  Uint8List? _foto;
  Uint8List? _fotoVencimiento;
  bool _guardando = false;

  bool get _esMedicamento => categoriasMedicamento.contains(_categoria);

  Future<Uint8List?> _elegirFoto() async {
    final archivo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 75);
    if (archivo == null) return null;
    return await archivo.readAsBytes();
  }

  Future<String> _subir(Uint8List bytes, String nombre) async {
    final ruta = '$miId/${nombre}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('fotos').uploadBinary(ruta, bytes, fileOptions: FileOptions(contentType: 'image/jpeg'));
    return supabase.storage.from('fotos').getPublicUrl(ruta);
  }

  Future<void> _publicar() async {
    final precio = int.tryParse(_precio.text.replaceAll('.', ''));
    final original = int.tryParse(_precioOriginal.text.replaceAll('.', ''));

    // Validaciones en la app (la base de datos vuelve a revisar las de medicamentos)
    if (_titulo.text.trim().isEmpty || precio == null || precio <= 0) {
      mostrarMensaje(context, 'Completa el título y un precio válido', error: true);
      return;
    }
    if (original != null && original <= precio) {
      mostrarMensaje(context, 'El precio original debe ser mayor al precio de venta', error: true);
      return;
    }
    if (_foto == null) {
      mostrarMensaje(context, 'Agrega una foto del producto', error: true);
      return;
    }
    if (_esMedicamento) {
      final minimo = DateTime.now().add(Duration(days: 30));
      if (_vencimiento == null || _vencimiento!.isBefore(minimo)) {
        mostrarMensaje(context, 'El medicamento debe vencer en 30 días o más', error: true);
        return;
      }
      if (_fotoVencimiento == null) {
        mostrarMensaje(context, 'Agrega una foto donde se vea la fecha de vencimiento', error: true);
        return;
      }
    }

    setState(() => _guardando = true);
    try {
      final urlFoto = await _subir(_foto!, 'producto');
      final urlVence = _fotoVencimiento == null ? null : await _subir(_fotoVencimiento!, 'vencimiento');

      await supabase.from('productos').insert({
        'vendedor_id': miId,
        'categoria': _categoria,
        'titulo': _titulo.text.trim(),
        'descripcion': _descripcion.text.trim(),
        'estado': _esMedicamento ? 'sellado' : _estado,
        'precio': precio,
        'precio_original': original,
        'fecha_vencimiento': _vencimiento?.toIso8601String().substring(0, 10),
        'foto_url': urlFoto,
        'foto_vencimiento_url': urlVence,
        'whatsapp': _whatsapp.text.trim(),
      });

      if (!mounted) return;
      mostrarMensaje(context, '¡Producto publicado! 🛍️');
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      // La regla medicamento_sellado_y_vigente de la base de datos lo rechazó
      final texto = e.message.contains('medicamento_sellado_y_vigente')
          ? 'Los medicamentos deben estar sellados, con foto del vencimiento y vencer en 30 días o más'
          : e.message;
      if (mounted) mostrarMensaje(context, texto, error: true);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo publicar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _cajaFoto(Uint8List? foto, String texto, VoidCallback alTocar) {
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colores.tarjeta,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colores.morado),
          image: foto != null ? DecorationImage(image: MemoryImage(foto), fit: BoxFit.cover) : null,
        ),
        child: foto != null
            ? null
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo, color: Colores.rosa, size: 30),
                SizedBox(height: 8),
                Text(texto, style: TextStyle(color: Colores.texto70)),
              ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colores.fondo, title: Text('Vender un producto')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          etiqueta('Foto del producto'),
          _cajaFoto(_foto, 'Toca para agregar foto', () async {
            final f = await _elegirFoto();
            if (f != null) setState(() => _foto = f);
          }),
          SizedBox(height: 16),

          etiqueta('Categoría'),
          DropdownButtonFormField<String>(
            value: _categoria,
            dropdownColor: Colores.tarjeta,
            decoration: decoracionCampo(''),
            items: categoriasProducto.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() {
              _categoria = v!;
              if (_esMedicamento) _estado = 'sellado';
            }),
          ),

          // Reglas especiales para medicamentos
          if (_esMedicamento) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '💊 Reglas para medicamentos:\n'
                '• Solo productos de venta libre (sin receta).\n'
                '• Envase original sellado y completo.\n'
                '• Deben vencer en 30 días o más.\n'
                '• Foto donde se vea la fecha de vencimiento.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
          SizedBox(height: 16),

          etiqueta('Título'),
          TextField(controller: _titulo, decoration: decoracionCampo('Ej: Cama ortopédica talla M')),
          SizedBox(height: 16),

          etiqueta('Estado'),
          Wrap(spacing: 8, children: [
            for (final e in ['sellado', 'como_nuevo', 'usado'])
              ChoiceChip(
                label: Text(textoEstado(e)),
                selected: _estado == e,
                // Si es medicamento, solo se permite "Sellado"
                onSelected: _esMedicamento && e != 'sellado' ? null : (_) => setState(() => _estado = e),
              ),
          ]),
          SizedBox(height: 16),

          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                etiqueta('Precio'),
                TextField(controller: _precio, keyboardType: TextInputType.number, decoration: decoracionCampo('12000')),
              ]),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                etiqueta('Precio original'),
                TextField(
                    controller: _precioOriginal,
                    keyboardType: TextInputType.number,
                    decoration: decoracionCampo('Opcional')),
              ]),
            ),
          ]),
          SizedBox(height: 16),

          if (_esMedicamento || _categoria == 'Alimento') ...[
            etiqueta('Fecha de vencimiento${_esMedicamento ? '' : ' (opcional)'}'),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colores.morado), minimumSize: Size(double.infinity, 50)),
              onPressed: () async {
                final f = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(Duration(days: 60)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                );
                if (f != null) setState(() => _vencimiento = f);
              },
              icon: Icon(Icons.event, color: Colores.rosa),
              label: Text(
                _vencimiento == null
                    ? 'Elegir fecha'
                    : '${_vencimiento!.day}/${_vencimiento!.month}/${_vencimiento!.year}',
                style: TextStyle(color: Colores.texto),
              ),
            ),
            SizedBox(height: 16),
          ],

          if (_esMedicamento) ...[
            etiqueta('Foto de la fecha de vencimiento'),
            _cajaFoto(_fotoVencimiento, 'Foto donde se lea el vencimiento', () async {
              final f = await _elegirFoto();
              if (f != null) setState(() => _fotoVencimiento = f);
            }),
            SizedBox(height: 16),
          ],

          etiqueta('Descripción'),
          TextField(controller: _descripcion, maxLines: 3, decoration: decoracionCampo('Detalles, talla, para qué mascota...')),
          SizedBox(height: 16),

          etiqueta('WhatsApp de contacto'),
          TextField(
            controller: _whatsapp,
            keyboardType: TextInputType.phone,
            decoration: decoracionCampo('Ej: 912345678', icono: Icons.phone),
          ),
          SizedBox(height: 30),

          BotonPrincipal(texto: 'Publicar', icono: Icons.storefront, cargando: _guardando, onPressed: _publicar),
          SizedBox(height: 40),
        ]),
      ),
    );
  }
}
