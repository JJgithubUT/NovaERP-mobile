# NovaERP Móvil — Guía de despliegue

Complemento de la guía de despliegue del backend. Cubre lo que hay que cambiar
en la app cuando el backend deja de ser `localhost` y pasa a vivir en un
servidor, más las trampas que solo aparecen en un build de release.

Documentos hermanos: la guía de despliegue del backend · `config/prod.json.ejemplo` ·
`android/key.properties.ejemplo`

---

## 0. Estado

| Área | Estado |
|---|---|
| Configuración por entorno | ✅ `--dart-define-from-file`, sin recompilar código |
| HTTPS obligatorio en release | ✅ El tráfico en claro solo se permite en debug |
| Identificador de paquete | ✅ `com.novaerp.movil` (ya no es `com.example.*`) |
| Ofuscación R8 | ✅ Con reglas para `flutter_secure_storage` y Tink |
| Firma de release | ⚠️ Falta generar el almacén de claves (§2) |
| Token de sesión | ✅ Keychain / EncryptedSharedPreferences |
| Verificación contra backend real | ✅ `test/backend_e2e_test.dart` |

---

## 1. Configuración por entorno

Los tres valores que cambian entre entornos se inyectan en tiempo de
compilación. No hay ningún `localhost` escrito en el código de producción.

| Variable | Qué es |
|---|---|
| `API_BASE_URL` | Origen del backend. **Debe coincidir exactamente** con un host de `ALLOWED_HOSTS`, o Django responde 400 sin mirar la petición |
| `TENANT_SLUG` | Slug de la empresa en `core.tenant`. La app se compila por cliente |

Copie la plantilla y rellénela:

```bash
cp config/prod.json.ejemplo config/prod.json
```

`config/prod.json` está en `.gitignore`. `config/dev.json` sí se versiona, para
que cualquiera pueda arrancar en local sin adivinar valores.

```bash
flutter run   --dart-define-from-file=config/dev.json
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

### HTTPS no es opcional en release

`android/app/src/debug/res/xml/network_security_config.xml` permite tráfico en
claro, y **solo existe en el build de depuración**. Un build de release contra
`http://` falla con un error de red genérico.

Esto es deliberado: por ese canal viajan contraseñas, códigos TOTP y JWT de
sesión. Si el backend queda en HTTP plano, la app no debe adaptarse — hay que
poner el certificado.

---

## 2. Firma de release

Sin esto, el APK se firma con la clave de depuración: sirve para probar
`--release` en local, pero **no se puede publicar ni actualizar después** con la
clave real.

```bash
keytool -genkey -v -keystore ~/novaerp-release.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias novaerp
```

Copie `android/key.properties.ejemplo` a `android/key.properties` y rellénelo.
Ambos, el `.jks` y el `key.properties`, están en `.gitignore`.

> **Guarde el `.jks` y su contraseña en la bóveda de la empresa.** Si se pierden,
> Google Play no admite más actualizaciones: hay que publicar una app nueva con
> otro identificador de paquete y pedir a todos los usuarios que reinstalen.

El `build.gradle.kts` detecta el archivo: si existe firma de release, la usa; si
no, cae a la de depuración para que `flutter run` siga funcionando en una
máquina recién clonada.

---

## 3. Lo que el backend debe cumplir para la app

Además de lo que ya cubre la guía del backend:

| Requisito | Por qué |
|---|---|
| `ALLOWED_HOSTS` incluye el host de `API_BASE_URL` | Django rechaza con 400 y una página HTML antes de mirar la ruta |
| HTTPS con certificado de una CA | Un certificado autofirmado necesita empaquetarse en la app y configurar el cliente HTTP |
| `X-Forwarded-Proto` en el proxy | Sin él, `SECURE_SSL_REDIRECT=True` entra en bucle de redirección y la API entera queda inaccesible |
| `USE_X_FORWARDED_FOR=True` | Las IP que muestra la pestaña de Bitácora salen de ahí; sin esto todas figuran como la del proxy |

**`CORS_ALLOWED_ORIGINS` no aplica a la app.** CORS es una restricción del
navegador; un cliente nativo no envía `Origin` y no se ve afectado. Esa variable
solo importa para el frontend web.

---

## 4. La trampa que puede dejar el sistema inservible

> ⚠️ **Rotar `SECRET_KEY` en producción bloquea a todos los usuarios de forma
> permanente.** No solo cierra sesiones.

`core/utils/secretos.py` deriva la clave de cifrado Fernet de `SECRET_KEY`, y
con ella cifra el `mfa_secret` de cada usuario. Al rotar la clave, esos secretos
dejan de poder descifrarse.

El diseño preveía degradar con elegancia — el docstring de `descifrar()` dice
que un secreto ilegible debe tratarse como «sin secreto» y forzar
re-enrolamiento — **pero eso nunca se cableó**. `auth_service.autenticar()`
comprueba solo si el secreto es `NULL`:

```python
if usuario.mfa_secret is None or not usuario.mfa_enrolado:
```

Con un secreto presente pero ilegible, el login se va por la rama OTP, ningún
código puede validar jamás, y **cada intento suma al contador de bloqueo**. Si
el único `TENANT_ADMIN` activo cae en ese estado, nadie puede resetearle el MFA
a nadie y el tenant queda muerto.

Reproducido en desarrollo: la cuenta `admin@acme.com` estaba exactamente así.

**Mientras no se corrija:**

- No rote `SECRET_KEY` en producción sin un plan de reseteo masivo de MFA.
- No copie datos entre entornos: los `mfa_secret` de desarrollo no se descifran
  con la clave de producción.
- Antes de rotarla, ejecute `UPDATE core.usuario SET mfa_secret=NULL,
  mfa_enrolado=FALSE` en la misma ventana de mantenimiento. Todos re-enrolan en
  su siguiente acceso, que es molesto pero recuperable.

La corrección de fondo es que `autenticar()` decida la rama según si el secreto
es *utilizable*, no según si es `NULL`.

---

## 5. La prueba de humo del backend está mal

La sección de verificación de la guía del backend propone:

```bash
curl -X POST https://api.suempresa.com/api/auth/login/ \
  -d '{"email":"...","password":"..."}'
# "Token válido → GET /api/core/me/"
```

Eso **no funciona** contra este backend, por tres motivos:

1. Los campos son `tenant_slug`, `correo` y `password`. No existe `email`, y
   falta `tenant_slug`, que es obligatorio.
2. `/api/auth/login/` **no devuelve un token**. Devuelve un reto de segundo
   factor: `{reto, mfa, mensaje}`. El login es de dos fases (RF-16).
3. El token de sesión lo emite `/api/auth/otp/` al canjear el reto por un código
   TOTP.

Un despliegue que pase esa prueba estaría dando por bueno un 400. La secuencia
correcta:

```bash
# Fase 1 — devuelve {"reto": "...", "mfa": "otp"|"enroll"}
curl -sS -X POST https://api.suempresa.com/api/auth/login/ \
  -H 'Content-Type: application/json' \
  -d '{"tenant_slug":"suempresa","correo":"admin@suempresa.com","password":"..."}'

# Fase 2 — canjea el reto por el token
curl -sS -X POST https://api.suempresa.com/api/auth/otp/ \
  -H 'Content-Type: application/json' \
  -d '{"reto":"<el reto de la fase 1>","codigo":"123456"}'

# Contexto
curl -sS https://api.suempresa.com/api/core/me/ -H 'Authorization: Bearer <token>'
```

En el primer acceso de un usuario, la fase 1 responde `mfa: "enroll"` e incluye
`secret` y `otpauth_uri` **una sola vez**.

---

## 6. Verificación antes de publicar

```bash
flutter analyze                    # sin errores ni advertencias
flutter test                       # 27 pruebas
```

Y contra el backend ya desplegado, apuntando las pruebas de integración al
entorno real:

```bash
flutter test test/backend_e2e_test.dart \
  --dart-define=API_BASE_URL=https://api.suempresa.com \
  --dart-define=TENANT_SLUG=suempresa \
  --dart-define=TEST_CORREO=... \
  --dart-define=TEST_PASSWORD=... \
  --dart-define=TEST_MFA_SECRET=...
```

> Esa suite **escribe datos reales**: crea un almacén de pruebas, registra
> movimientos de inventario y da de alta un usuario. Contra producción, úsela
> solo con las pruebas de consulta, o contra un entorno de preproducción.

Después, con el APK de release instalado:

- [ ] Login completo, incluido el enrolamiento MFA con QR
- [ ] Cerrar sesión y comprobar que el token deja de servir
- [ ] Las secciones visibles coinciden con los permisos del rol
- [ ] Un usuario sin permisos de inventario no ve esa pestaña
- [ ] Registrar un movimiento y ver el stock actualizado
- [ ] El enlace de activación se comparte con la URL correcta

---

## 7. Distribución

```bash
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

El `.aab` pesa ~52 MB, pero **eso no es lo que descarga el usuario**: Play genera
un APK por dispositivo (~18 MB) a partir del bundle. Para distribución directa
fuera de Play, use APK por arquitectura:

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=config/prod.json
```

### Un build por empresa

`TENANT_SLUG` se fija en compilación, así que **cada cliente necesita su propio
build**. Si eso deja de escalar, la alternativa es una pantalla previa de
configuración que pida la empresa una sola vez y la guarde — el `AuthService` ya
lee el slug de un único sitio, así que el cambio queda acotado a `ApiConstants`
y a esa pantalla.

---

## 8. Pendientes conocidos

| # | Hueco | Impacto |
|---|---|---|
| 1 | Sin icono propio (usa el de Flutter) | Cosmético; se resuelve con `flutter_launcher_icons` |
| 2 | Sin build para iOS | El proyecto existe pero nunca se compiló ni se firmó |
| 3 | Las alertas de stock devuelven UUID en crudo | La app pagina el catálogo para resolver nombres; se cae solo si el backend resuelve los nombres en `serialize_alerta` |
| 4 | La bitácora devuelve `usuario_id` en crudo | Igual que el anterior; se resuelve contra el reporte de actividad |
| 5 | Roles sin permisos | `Idiota` y `Puton` tienen 0 permisos: quien solo tenga uno de esos entra y no ve nada |
| 6 | Crear y editar roles no está en el móvil | Son 73 códigos de permiso; es trabajo de escritorio |
