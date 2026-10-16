# Reglas de ofuscacion para el build de release.
#
# Flutter aporta las suyas automaticamente; aqui solo van las de los plugins
# nativos que usan reflexion y que R8 no puede rastrear.

# flutter_secure_storage: accede al almacen de claves de Android por reflexion.
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Tink, la biblioteca de cifrado que usa flutter_secure_storage por debajo.
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# El motor de Flutter y los canales de plataforma.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
