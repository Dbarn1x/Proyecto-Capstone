import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'comun.dart';

/// Si no hay GPS o el usuario no da permiso, se usa Santiago centro
const santiagoCentro = LatLng(-33.4489, -70.6693);

/// Pide permiso y obtiene la posición actual del celular (null si no se puede)
Future<LatLng?> obtenerUbicacion() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}

/// Guarda la ubicación en mi perfil. La base de datos arma sola el punto
/// PostGIS (columna "ubicacion") a partir de latitud y longitud.
Future<void> guardarMiUbicacion() async {
  final punto = await obtenerUbicacion();
  if (punto == null || supabase.auth.currentUser == null) return;
  await supabase
      .from('perfiles')
      .update({'latitud': punto.latitude, 'longitud': punto.longitude})
      .eq('id', miId);
}
