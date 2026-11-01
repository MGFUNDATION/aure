# Aure 🌙

**Tu música. Tu mundo. Tu momento.**

Reproductor de música **offline** para Android (y iOS) con entornos personalizables,
sonidos ambientales, letras, estadísticas, bienestar y un asistente con IA que
reconoce canciones cuando las tarareas.

## Qué incluye

| Pantalla | Qué hace |
|---|---|
| **Inicio** | Saludo, entorno activo, modos *Enfoque / Relajación / Sueño / Energía*, accesos a Estadísticas y Bienestar, escuchado recientemente |
| **Explorar** | Buscar en tu música, entornos destacados, categorías, artistas, lo más escuchado. Botón 🎤 para tararear |
| **Aure IA** (botón central) | Tararea o canta → reconoce la canción. Pega un enlace → te dice qué canción es y dónde escucharla. Busca y descarga **música con licencia libre** eligiendo calidad. Recomienda entornos según tu ánimo |
| **Reproductor** | Paisaje del entorno, controles, aleatorio/repetir, letras sincronizadas, mezclador de sonidos ambientales, temporizador para dormir |
| **Personalizar** | 8 entornos + tu propia imagen de fondo, iluminación, tema claro/oscuro/auto, 8 colores principales, tamaño de letra, sonidos |
| **Biblioteca** | Playlists, favoritos, canciones, álbumes, artistas y descargas |
| **Perfil** | Foto, portada, nombre y frase editables; Mi universo; accesos a todo |
| **Estadísticas** | Tiempo de escucha por semana/mes, comparación, sesiones de enfoque, hora favorita, top entornos/artistas/canciones/géneros |
| **Bienestar** | ¿Cómo te sientes hoy?, rutinas (mañana productiva, pomodoro, pausa, sueño), respiración 4‑7‑8 guiada |
| **Ajustes** | Apariencia, calidad de descarga, funciones en línea on/off, privacidad |

Todo lo personal (estadísticas, ánimo, historial, playlists) se guarda **solo en el teléfono**.

## Descargas y anuncios

- Aure **solo descarga música cuya licencia lo permite**: Jamendo (Creative Commons)
  e Internet Archive (Creative Commons / dominio público). Calidad baja, media o alta.
- Cada descarga gratis muestra **un anuncio corto con recompensa**. No hay ningún otro anuncio en la app.
- Los enlaces de Spotify, YouTube, Apple Music, etc. se **reconocen** (vía song.link) y se abren
  en el servicio oficial; no se descargan, porque esa música tiene derechos de autor.

## Cómo compilar

Requiere [Flutter](https://flutter.dev) 3.35 o superior.

```bash
flutter pub get
flutter run
```

### Claves opcionales

Sin claves la app funciona offline y con Internet Archive. Para activar todo:

| Servicio | Para qué | Dónde conseguirla |
|---|---|---|
| ACRCloud | Reconocer por tarareo | https://console.acrcloud.com (proyecto con *Humming*) |
| Jamendo | Catálogo de música libre | https://devportal.jamendo.com |
| AdMob | Anuncio por descarga | https://admob.google.com |

```bash
flutter run \
  --dart-define=ACR_HOST=identify-xx.acrcloud.com \
  --dart-define=ACR_KEY=... --dart-define=ACR_SECRET=... \
  --dart-define=JAMENDO_CLIENT_ID=... \
  --dart-define=ADMOB_REWARDED_ID=ca-app-pub-.../...
```

Antes de publicar, cambia también el ID de aplicación de AdMob en
`android/app/src/main/AndroidManifest.xml` y `ios/Runner/Info.plist` (ahora son IDs de prueba).

### APK automático

Cada cambio en `main` compila un APK con GitHub Actions (pestaña **Actions → Compilar APK → Artifacts**).
Las claves se configuran como *secrets* del repositorio con los mismos nombres.

## Estructura

```
lib/
  main.dart                 arranque, proveedores de estado, audio en segundo plano
  theme/                    paleta y tema (Poppins, claro/oscuro, color principal)
  models/                   canciones, playlists, entornos y sonidos ambientales
  state/                    ajustes, biblioteca, reproductor, estadísticas
  services/                 letras, reconocimiento, música libre, descargas, anuncios
  screens/                  todas las pantallas
  widgets/                  paisajes dibujados, mini reproductor, componentes
assets/sounds/              sonidos ambientales (generados con tool/gen_sounds.py, sin derechos)
```

## Próximos pasos

- Ecualizador y crossfade
- Letras incrustadas en los archivos (ID3)
- Sonidos ambientales grabados (CC0) para reemplazar los sintéticos
- Ilustraciones de los entornos como en el diseño
- Copia de seguridad / sincronización opcional
