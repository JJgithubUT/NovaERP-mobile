# Flujo de trabajo del sprint (NovaERP móvil)

## Ramas

```
main                      ← solo entregas del sprint (PR desde develop)
 └─ develop               ← integración; aquí ya está la base conectada al backend
     ├─ feature/HU16-mfa
     ├─ feature/HU17-logout
     ├─ feature/HU18-recuperar-password
     └─ feature/HU19-sesiones
```

1. `git switch develop && git pull`
2. `git switch -c feature/HUxx-nombre`
3. Commits pequeños que mencionen el issue (`HU16: pantalla de OTP (#28)`).
4. Pull request **hacia `develop`**, nunca a `main`. Pedir revisión a un compañero.
5. Antes de abrir el PR: `git pull origin develop` en tu rama y `flutter analyze` + `flutter test --exclude-tags backend`.

## Reparto y archivos propios

Cada HU tiene sus archivos y *ranuras* ya creadas en `develop`. Edita solo lo tuyo.

| HU | Issue | Archivos propios |
|---|---|---|
| HU16 MFA/TOTP | #28 | `screens/login/otp_screen.dart`, `screens/login/enroll_mfa_screen.dart`, bloque HU16 en `services/auth_service.dart` y `providers/auth_provider.dart` |
| HU17 Logout | #27 | bloque HU17 en `services/auth_service.dart` y `providers/auth_provider.dart`, `_BotonCerrarSesion` en `screens/profile/profile_screen.dart` |
| HU18 Recuperar contraseña | #29 | `screens/recovery/*`, bloque HU18 en `services/auth_service.dart` |
| HU19 Sesiones activas | #26 | `screens/sessions/*`, `services/sesiones_service.dart`, `models/sesion.dart` |
| EP03 | #25 | Épica: se cierra cuando se completan las cuatro HU |

## Reglas para no tener conflictos de merge

- **No edites `app_routes.dart`, `core/config/api_constants.dart`, `pubspec.yaml`, `auth_gate.dart` ni `main.dart`**: las rutas, endpoints y dependencias del sprint ya están. Si necesitas algo nuevo ahí, avisa en el grupo y se hace en un PR aparte, rápido, a `develop`.
- No reordenes, renombres ni reformatees métodos o archivos ajenos (nada de "format on save" masivo).
- Los bloques de `auth_service.dart` y `auth_provider.dart` están separados por banners `HUxx`; reemplaza solo el cuerpo del tuyo.
- Archivos nuevos van en la carpeta de tu HU.
- Si necesitas un widget compartido, créalo nuevo en `core/widgets/` en lugar de modificar uno existente.
- Los cambios en `linux/`, `windows/` y `macos/` tras `flutter pub get` son normales; **no los incluyas en tu PR** (`git checkout -- linux windows macos` antes de hacer commit).

## Orden recomendado

HU17, HU18 y HU19 necesitan una sesión iniciada para probarse, y el login completo depende de HU16 (el token lo emite el paso OTP). Por eso **HU16 se integra primero** en un PR corto; mientras tanto el resto puede avanzar su UI y servicio contra el backend (HU18 es pública y no necesita sesión).

## Ejecutar la app

```bash
flutter pub get
flutter run --dart-define-from-file=config/dev.json
```

`config/dev.json` apunta a `127.0.0.1:8000`. Para emulador Android usa `10.0.2.2`, y para un teléfono físico la IP de tu PC. Para no ensuciar el repo crea `config/dev.local.json` (ignorado por git) con tu IP y úsalo en lugar de `dev.json`.
