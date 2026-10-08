# Guía de instalación del APK en el Realme C11

> Para instalarlo la novia desde Buenos Aires (sin ADB). Sigue estos pasos en el celular.

## Paso 0 — Desinstalar versión vieja (SOLO si la app **no se instala**)

La v1.0.2+ está firmada con la **firma debug de Flutter** (la misma que aceptaban
los APK de antes del 6/8): si el celular tiene una versión vieja con esa firma,
se instala encima **sin desinstalar**. Pero si quedó instalada la **v1.0.1**
(firmada con CN=Furi el 6/8), Android **no permite reemplazarla** y tira
"aplicación no instalada". En ese caso desinstalá primero:

1. `Ajustes` → `Aplicaciones` → busca **furi_app** (o "F.U.R.I.")
2. Toca → `Desinstalar`

> Solo desinstalá si la instalación falla. Si nunca la instaló, salta este paso.

## Paso 1 — Elegir el APK correcto para tu celular

Hay **3 APKs separados** por arquitectura (~20 MB cada uno). Descargá el que
coincida con tu celular:

| Arquitectura | Dispositivos típicos | Archivo |
|---|---|---|
| **arm64-v8a** | La mayoría (64-bit moderno) | `app-arm64-v8a-release.apk` |
| **armeabi-v7a** | Celulares viejos (32-bit) | `app-armeabi-v7a-release.apk` |
| **x86_64** | Emuladores, tablets | `app-x86_64-release.apk` |

> **Si no sabés cuál**, descargá **arm64-v8a** (el más común).
> Para saberlo: `Ajustes` → `Acerca del teléfono` → `Arquitectura del procesador`

## Paso 2 — Permitir "instalar apps desconocidas"

Realme bloquea la instalación desde fuera de su tienda. Hay que habilitarlo:

1. `Ajustes` → `Contraseñas y seguridad` (o buscá "instalar apps desconocidas")
2. `Instalar apps desconocidas`
3. Habilitá el permiso para la app desde donde vas a abrir el APK:
   - Si lo bajás con el **navegador Chrome** → permitir Chrome
   - Si lo recibís por **WhatsApp** → permitir WhatsApp
4. Si te aparece un cartel "para tu seguridad", tocá **Configurar** → **Permitir**

## Paso 3 — Descargar e instalar

**Método A (recomendado): descargar con Chrome desde GitHub**
1. Abrí este link en Chrome del celular:
   `https://github.com/mrtuco748-cmyk/furiiiiiiiiiii/releases/latest`
2. Tocá el APK de tu arquitectura (ej: `app-arm64-v8a-release.apk`)
3. Tocá **Descargar**
4. Cuando termine, tocá la notificación → **Instalar**

**Método B — por WhatsApp/Drive:**
1. Recibí el archivo por WhatsApp o Drive
2. Asegurate de que **termine en `.apk`** (no `.apk.txt` ni `.apk.1`)
3. Tocá el archivo → **Instalar**
4. Si pregunta por el administrador, tocá `Ajustes → Permitir desde esta fuente`

## Si falla con un mensaje de error

| Mensaje | Causa | Solución |
|---------|-------|----------|
| "No se puede instalar" gris | Permiso apps desconocidas no habilitado para esa app | Repetir Paso 2 |
| "Aplicación no instalada" | Queda una versión vieja con otra firma | Repetir Paso 0 (desinstalar) |
| "Falta la aplicación para abrir este archivo" | Descarga corrupta/incompleta | Volver a descargar con Chrome |
| "Existe una app con un paquete en conflicto" | Misma causa que "aplicación no instalada" | Repetir Paso 0 |
| Aplicación bloqueada por seguridad ("puede dañar") | Play Protect escanea APKs desconocidos | Play Store → perfil → Play Protect → Ajustes → desactivar "Escanear apps" |

## Verificación final

- La app abre y muestra la pantalla de **login** (elegir Facu/Rocio)
- Si ya tenía cuenta, entra directo al Home

---

**APKs en:** `build/app/outputs/flutter-apk/app-{arquitectura}-release.apk`
