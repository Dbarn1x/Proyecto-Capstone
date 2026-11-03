import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'comun.dart';
import 'publicar_producto_screen.dart';

/// Categorías (deben coincidir con el CHECK de la tabla productos)
const categoriasProducto = [
  'Medicamentos', 'Antiparasitarios', 'Alimento', 'Camas', 'Comederos',
  'Juguetes', 'Ropa', 'Correas', 'Transportadoras', 'Otro',
];

/// Categorías con reglas especiales (sellado + vencimiento + foto)
const categoriasMedicamento = ['Medicamentos', 'Antiparasitarios'];

/// 18000 → "$18.000"
String formatoPesos(num valor) {
  final texto = valor.round().toString();
  final conPuntos = texto.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '\$$conPuntos';
}

String textoEstado(String estado) =>
    estado == 'sellado' ? 'Sellado' : (estado == 'como_nuevo' ? 'Como nuevo' : 'Usado');

/// MARKETPLACE: reventa de medicamentos sobrantes y accesorios
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Map<String, dynamic>> _productos = [];
  String? _categoria; // null = todas
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// La vista vista_productos ya oculta los vendidos y vencidos
  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      var consulta = supabase.from('vista_productos').select();
      if (_categoria != null) consulta = consulta.eq('categoria', _categoria!);
      _productos = await consulta.order('created_at', ascending: false);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'Error al cargar productos: $e', error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _publicar() async {
    final publicado = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const PublicarProductoScreen()));
    if (publicado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        // Filtro por categoría
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [null, ...categoriasProducto].map((c) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c ?? 'Todo'),
                  selected: _categoria == c,
                  onSelected: (_) {
                    setState(() => _categoria = c);
                    _cargar();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: Colores.rosa))
              : RefreshIndicator(
                  color: Colores.rosa,
                  onRefresh: _cargar,
                  child: _productos.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 150),
                          Text('No hay productos en esta categoría todavía 🛍️',
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                        ])
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.68),
                          itemCount: _productos.length,
                          itemBuilder: (_, i) => _tarjeta(_productos[i]),
                        ),
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'vender',
        backgroundColor: Colores.rosa,
        onPressed: _publicar,
        icon: const Icon(Icons.add),
        label: const Text('Vender'),
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> p) {
    final ahorro = p['ahorro_pct'];
    return GestureDetector(
      onTap: () => _verDetalle(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colores.tarjeta,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colores.morado),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              p['foto_url'] != null
                  ? Image.network(p['foto_url'] as String, fit: BoxFit.cover)
                  : const Icon(Icons.inventory_2, size: 50, color: Colors.white24),
              if (ahorro != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                    child: Text('-$ahorro%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['titulo'] as String, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(formatoPesos(p['precio'] as num),
                  style: const TextStyle(color: Colores.rosa, fontWeight: FontWeight.bold, fontSize: 16)),
              if (p['precio_original'] != null)
                Text(formatoPesos(p['precio_original'] as num),
                    style: const TextStyle(color: Colors.white38, decoration: TextDecoration.lineThrough, fontSize: 12)),
              Text('${p['categoria']} · ${textoEstado(p['estado'] as String)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _verDetalle(Map<String, dynamic> p) {
    final esMio = p['vendedor_id'] == miId;
    final vence = p['fecha_vencimiento'] as String?;

    Future<void> contactar() async {
      var numero = (p['whatsapp'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (numero.length == 9) numero = '56$numero'; // celular chileno sin código de país
      final texto = Uri.encodeComponent('Hola! Vi tu "${p['titulo']}" en Paws 🐾 ¿Sigue disponible?');
      await launchUrl(Uri.parse('https://wa.me/$numero?text=$texto'), mode: LaunchMode.externalApplication);
    }

    Future<void> marcarVendido() async {
      await supabase.from('productos').update({'vendido': true}).eq('id', p['id']);
      if (mounted) Navigator.pop(context);
      _cargar();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colores.tarjeta,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (p['foto_url'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(p['foto_url'] as String, height: 220, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 15),
          Text(p['titulo'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            Text(formatoPesos(p['precio'] as num),
                style: const TextStyle(color: Colores.rosa, fontSize: 24, fontWeight: FontWeight.bold)),
            if (p['precio_original'] != null) ...[
              const SizedBox(width: 10),
              Text(formatoPesos(p['precio_original'] as num),
                  style: const TextStyle(color: Colors.white38, decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 8),
              Text('Ahorras ${p['ahorro_pct']}%', style: const TextStyle(color: Colors.greenAccent)),
            ],
          ]),
          const SizedBox(height: 10),
          Text('${p['categoria']} · ${textoEstado(p['estado'] as String)}', style: const TextStyle(color: Colors.white70)),
          if (vence != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.verified, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Vence el ${vence.substring(8, 10)}/${vence.substring(5, 7)}/${vence.substring(0, 4)}'
                      '${categoriasMedicamento.contains(p['categoria']) ? ' · Envase sellado verificado con foto' : ''}'),
                ),
              ]),
            ),
          ],
          if (p['foto_vencimiento_url'] != null) ...[
            const SizedBox(height: 10),
            etiqueta('Foto del vencimiento'),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(p['foto_vencimiento_url'] as String, height: 120, fit: BoxFit.cover),
            ),
          ],
          if ((p['descripcion'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p['descripcion'] as String, style: const TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 20),
          if (esMio) ...[
            BotonPrincipal(texto: 'Marcar como vendido', icono: Icons.check_circle, onPressed: marcarVendido),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                label: const Text('Eliminar publicación', style: TextStyle(color: Colors.redAccent)),
                onPressed: () async {
                  await supabase.from('productos').delete().eq('id', p['id']);
                  if (mounted) Navigator.pop(context);
                  _cargar();
                },
              ),
            ),
          ] else if ((p['whatsapp'] ?? '').toString().isNotEmpty)
            BotonPrincipal(texto: 'Contactar por WhatsApp', icono: Icons.chat, onPressed: contactar)
          else
            const Text('El vendedor no dejó contacto.', style: TextStyle(color: Colors.white54)),
        ]),
      ),
    );
  }
}
