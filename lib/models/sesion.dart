/// HU19 - Sesion activa del usuario (GET /api/core/sesiones/).
///
/// Forma de cada elemento de `results`:
///   id, jti, dispositivo (User-Agent crudo), ip_origen, iniciada_en,
///   ultima_actividad, expira_en (ISO 8601) y `actual` (true = esta sesion).
/// El tipo de dispositivo se deriva del User-Agent en la app.
class Sesion {
  // TODO(HU19): campos y fromJson.
  const Sesion();
}
