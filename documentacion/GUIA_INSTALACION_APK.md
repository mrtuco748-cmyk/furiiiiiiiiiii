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

## Paso 1 — Permitir "instalar apps desconocidas"

Realme bloquea la instalación desde fuera de su tienda. Hay que habilitarlo:

1. `Ajustes` → `Contraseñas y seguridad` (o buscá "instalar apps desconocidas")
2. `Instalar apps desconocidas`
3. Habilitá el permiso para la app desde donde vas a abrir el APK:
   - Si lo recibís por **WhatsApp** → permitir WhatsApp
   - Si lo bajás con el **Administrador de archivos / Files** → permitir Archivos
4. Si te aparece un cartel "para tu seguridad", tocá **Configurar** → **Permitir**

## Paso 2 — Pasar y abrir el APK

**Método A (recomendado): descargar con el navegador del celular**
- WhatsApp y Drive a veces renombran o cortan el archivo (termina en `.apk.1` y
  Android lo rechaza con "aplicación no instalada"). Bajarlo por el navegador
  del celular **no lo renombra**:
  1. Abrí con **Chrome** el link del APK:
     `https://github.com/mrtuco748-cmyk/furiiiiiiiiiii/releases/latest`
  2. Tocá `app-release.apk` → `Descargar`
  3. Cuando termine, tocá la notificación (o `Descargas` → el archivo)
  4. **Instalar** (permití "apps desconocidas" si lo pide)

**Método B — por WhatsApp/Drive:**
1. Recibí el archivo `app-release.apk` por WhatsApp o Drive
2. Asegurate de que **termine en `.apk`** (no `.apk.txt` ni `.apk.1`)
3. Tocá el archivo → se abre el instalador
4. Tocá **Instalar**
5. Si pregunta por el administrador, tocá `Ajustes → Permitir desde esta fuente`
6. Al final: **Listo / Abrir**

## Si falla con un mensaje de error

| Mensaje | Causa | Solución |
|---------|-------|----------|
| "No se puede instalar" gris | Permiso apps desconocidas no habilitado para esa app | Repetir Paso 1 |
| "Aplicación no instalada" | Queda una versión vieja con otra firma | Repetir Paso 0 (desinstalar) |
| "Falta la aplicación para abrir este archivo" | Descarga corrupta/incompleta | Volver a descargar y verificar que termina en `.apk` |
| "Existe una app con un paquete en conflicto" | Misma causa que "aplicación no instalada" | Repetir Paso 0 |
| Aplicación bloqueada por seguridad ("puede dañar") | Play Protect escanea APKs desconocidos | Play Store → perfil → Play Protect → Ajustes → desactivar "Escanear apps" |

## Verificación final

- La app abre y muestra la pantalla de **login** (elegir Facu/Rocio)
- Si ya tenía cuenta, entra directo al Home

---

**Archivo a instalar:** `build/app/outputs/flutter-apk/app-release.apk`
