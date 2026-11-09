import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'comun.dart';
import 'marketplace_screen.dart' show formatoPesos;

/// PAGO CON WEBPAY PLUS (Transbank) en el marketplace.
///
/// Usa el AMBIENTE DE INTEGRACIÓN (pruebas) con las credenciales públicas
/// que Transbank entrega para probar. No se cobra dinero real.
/// En producción, la llave secreta iría en un servidor (Supabase Edge
/// Function) y nunca dentro de la app.
///
/// Flujo:
///  1. Se crea la venta en la BD (el trigger pone el precio y calcula la comisión de 5 %).
///  2. Se crea la transacción en Transbank → devuelve token + url.
///  3. Se abre Webpay para pagar.
///  4. Al volver, "Confirmar pago" hace el commit en Transbank.
///     Si fue aprobado, la venta queda "pagada" y el producto se marca vendido.
class Transbank {
  static const _api =
      'https://webpay3gint.transbank.cl/rswebpaytransaction/api/webpay/v1.2/transactions';
  static const _cabeceras = {
    'Tbk-Api-Key-Id': '597055555532', // código de comercio de prueba
    'Tbk-Api-Key-Secret': '579B532A7440BB0C9079DED94D31EA1615BACEB56610332264630D42D0A36B1C',
    'Content-Type': 'application/json',
  };
  // Página a la que Webpay vuelve al terminar (en pruebas basta con cualquiera)
  static const _urlRetorno = 'https://example.com/paws/pago-terminado';

  /// Crea la transacción y devuelve {token, url}
  static Future<Map<String, dynamic>> crear(String ordenCompra, int monto) async {
    final r = await http.post(Uri.parse(_api),
        headers: _cabeceras,
        body: jsonEncode({
          'buy_order': ordenCompra,
          'session_id': miId,
          'amount': monto,
          'return_url': _urlRetorno,
        }));
    if (r.statusCode != 200) throw 'Transbank respondió ${r.statusCode}: ${r.body}';
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Confirma (commit) la transacción. Devuelve true si el pago fue aprobado.
  static Future<bool> confirmar(String token) async {
    final r = await http.put(Uri.parse('$_api/$token'), headers: _cabeceras);
    if (r.statusCode != 200) return false;
    final datos = jsonDecode(r.body) as Map<String, dynamic>;
    return datos['status'] == 'AUTHORIZED' && datos['response_code'] == 0;
  }
}

/// Botón "Comprar con Webpay" para el detalle de un producto
class BotonPagarWebpay extends StatefulWidget {
  final Map<String, dynamic> producto;
  final VoidCallback alTerminar;
  const BotonPagarWebpay({super.key, required this.producto, required this.alTerminar});

  @override
  State<BotonPagarWebpay> createState() => _BotonPagarWebpayState();
}

class _BotonPagarWebpayState extends State<BotonPagarWebpay> {
  bool _cargando = false;

  Future<void> _pagar() async {
    setState(() => _cargando = true);
    try {
      // 1. Venta en la BD: el trigger toma el precio real y calcula la comisión
      final orden = 'PAWS${DateTime.now().millisecondsSinceEpoch}';
      final venta = await supabase
          .from('ventas')
          .insert({'producto_id': widget.producto['id'], 'comprador_id': miId, 'orden_compra': orden})
          .select()
          .single();

      // 2. Transacción en Transbank
      final tx = await Transbank.crear(orden, venta['monto'] as int);
      final token = tx['token'] as String;
      await supabase.from('ventas').update({'token': token}).eq('id', venta['id']);

      // 3. Abrir Webpay
      await launchUrl(Uri.parse('${tx['url']}?token_ws=$token'), mode: LaunchMode.inAppBrowserView);
      if (!mounted) return;

      // 4. Al volver, confirmar el pago
      final listo = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: Colores.tarjeta,
          title: const Text('Pago con Webpay'),
          content: Text('Total: ${formatoPesos(venta['monto'] as num)}\n'
              'Comisión Paws (5 %): ${formatoPesos(venta['comision'] as num)}\n'
              'Recibe el vendedor: ${formatoPesos(venta['monto_vendedor'] as num)}\n\n'
              'Cuando termines de pagar en Webpay, toca "Confirmar pago".'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar pago')),
          ],
        ),
      );
      if (listo != true) {
        await supabase.from('ventas').update({'estado': 'rechazada'}).eq('id', venta['id']);
        return;
      }

      final aprobado = await Transbank.confirmar(token);
      await supabase.from('ventas').update({'estado': aprobado ? 'pagada' : 'rechazada'}).eq('id', venta['id']);
      if (!mounted) return;
      mostrarMensaje(context, aprobado ? '¡Pago aprobado! El producto es tuyo 🐾' : 'El pago fue rechazado o no se completó',
          error: !aprobado);
      if (aprobado) widget.alTerminar();
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo iniciar el pago: $e', error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return Center(child: CircularProgressIndicator(color: Colores.rosa));
    return BotonPrincipal(texto: 'Comprar con Webpay', icono: Icons.credit_card, onPressed: _pagar);
  }
}
