/// Herramientas para el RUT chileno.

/// Quita puntos y espacios y deja el formato que exige la base de datos: 12345678-K
String normalizarRut(String rut) {
  final limpio = rut.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  if (limpio.length < 2) return limpio;
  return '${limpio.substring(0, limpio.length - 1)}-${limpio[limpio.length - 1]}';
}

/// Valida el dígito verificador con el algoritmo "módulo 11":
/// se multiplican los dígitos de derecha a izquierda por 2,3,4,5,6,7,2,3...
/// se suman, y 11 menos el resto de dividir por 11 es el dígito (11 → 0, 10 → K).
bool rutValido(String rut) {
  final limpio = rut.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  if (limpio.length < 8 || limpio.length > 9) return false;

  final cuerpo = limpio.substring(0, limpio.length - 1);
  final dv = limpio[limpio.length - 1];
  if (!RegExp(r'^\d+$').hasMatch(cuerpo)) return false;

  int suma = 0;
  int multiplicador = 2;
  for (int i = cuerpo.length - 1; i >= 0; i--) {
    suma += int.parse(cuerpo[i]) * multiplicador;
    multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
  }

  final resto = 11 - (suma % 11);
  final esperado = resto == 11 ? '0' : (resto == 10 ? 'K' : '$resto');
  return dv == esperado;
}
