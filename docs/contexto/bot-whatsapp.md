# Bot WhatsApp de F.U.R.I

## Propósito
Bot que notifica por WhatsApp sobre actividad en la app F.U.R.I cada 30 minutos.
Usa un numero de WhatsApp propio para enviar notificaciones a Facu y Rocio.

## Stack

| Componente | Tecnologia |
|-----------|-----------|
| Runtime | Node.js v20 |
| WhatsApp | @whiskeysockets/baileys v6 |
| Base de datos | Supabase (PostgreSQL) |
| Automatizacion | GitHub Actions (cron */30) |
| Sesion WhatsApp | Persistida en Supabase `bot_sessions` |

## Estructura

```
bot-furi/
├── bot.js                   # Punto de entrada: conexion, verificacion, envio
├── package.json             # Dependencias + type: module (ESM)
├── supabase_migration.sql   # Tablas bot_sessions + bot_notificaciones
├── .env                     # SUPABASE_URL, SUPABASE_KEY, MI_NUMERO, FACU_NUMERO, ROCIO_NUMERO
└── .gitignore               # node_modules, auth/, .env
```

## Tablas en Supabase (creadas por migracion)

### bot_sessions
```sql
CREATE TABLE bot_sessions (
  id INTEGER PRIMARY KEY DEFAULT 1,
  session_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```
Almacena la sesion de WhatsApp como JSONB (un objeto con archivos .json de Baileys como claves).
Se carga al iniciar y se guarda en cada `creds.update`.

### bot_notificaciones
```sql
CREATE TABLE bot_notificaciones (
  id BIGSERIAL PRIMARY KEY,
  tabla TEXT NOT NULL,         -- schedules, anniversaries, moods, etc.
  registro_id TEXT NOT NULL,  -- ID unico del registro notificado
  tipo TEXT NOT NULL,         -- proximo, nueva, hoy, manana, etc.
  phone TEXT NOT NULL,        -- numero al que se envio
  mensaje TEXT,               -- contenido de la notificacion
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```
Evita notificaciones duplicadas. Antes de enviar se chequea si `(tabla, registro_id)` ya existe.

## Categorias notificadas (22 + 4b)

| # | Tabla | Icono | Regla | Tracking key |
|---|-------|-------|-------|-------------|
| 1 | schedules | 📅 | Proximas 2h | `schedule-{id}-{date}-{startTime}` |
| 2 | anniversaries | 🎉 | Hoy (8-10 AM) + mañana | `anniversary-{id}-{date}` |
| 3 | moods | 😊 | Ultima 1h | `mood-{id}` |
| 4 | letters | 💌 | Ultima 1h · no spoilea cartas selladas (apertura futura) | `letter-{id}` |
| 4b | letters (apertura) | 💌 | Entrega ceremonial cuando `scheduled_open` cae en la última 1h ("tu carta acaba de abrirse") | `letteropen-{id}-{fecha}` |
| 5 | challenges | 🚩 | Ultima 1h (creado/iniciado/completado) → a la pareja del creador | `challenge-{id}` |
| 6 | goals | 🏅 | Ultima 1h (creada/completada) → a la pareja del creador | `goal-{id}` |
| 7 | tasks | ✅ | Ultima 1h | `task-{id}` |
| 8 | transactions | 💰/💸 | Ultima 1h (income/expense) | `transaction-{id}` |
| 9 | favorites | ⭐ | Ultima 1h | `favorite-{id}` |
| 10 | notes | 📝 | Ultima 1h | `note-{id}` |
| 11 | gallery | 🖼️ | Ultima 1h | `gallery-{id}` |
| 12 | timeline_events | 🕐 | Ultima 1h | `timeline-{id}` |
| 13 | custom_questions | ❓ | Ultima 1h (nueva/respondida) | `question-{id}` |
| 14 | class_schedules | 📚 | Clases de hoy en proximas 2h (titulo + horario) | `class-{id}-{date}-{startTime}` |
| 15 | deck_cards | 🃏 | Tarjeta nueva en ultima 1h → a la pareja del creador (categoria + preview) | `deck-{id}` |
| 16 | deck match | 🃏 | reactions con >=2 valores todos 'encanta' y updated_at en ultima 1h → a AMBOS ("FURI!!") | `deckmatch-{id}` |
| 17 | workout_logs | 💪 | Nuevo ejercicio en ultima 1h (nombre + series x reps + peso) | `exercise-{id}` |
| 18 | workout_completions | 🏋️ | Sesion de entrenamiento completada en ultima 1h | `wcompletion-{id}` |
| 19 | workout_challenges | 🏆 | Reto de ejercicio creado/aprobado/completado en ultima 1h | `wchallenge-{id}-{tipo}` |
| 20 | racha de entrenamiento | 🔥 | Racha individual >=3 dias y no entreno hoy ni ayer → aviso una vez por dia a la pareja | `streak-{uuid}-{date}` |
| 21 | couple_achievements | 🏅 | Logro de pareja desbloqueado en ultima 1h → a AMBOS (emoji/titulo) | `logro-{code}` |
| 22 | question_answers | 🎯 | Trivia: cuando AMBOS respondieron hoy → aviso "quién conoce más" (a ambos) | `trivia-{date}` |

**No notifica**: messages (ya tienen push via FCM)

## Regla de destinatario

Cada registro se enruta **solo a la persona que NO lo generó**: si el creador es Facu
va a `ROCIO_NUMERO`, y si es Rocio va a `FACU_NUMERO`. Si no se puede identificar el
creador, se envía a ambos (default). Aplica a schedules (user_id), class_schedules
(user_id), moods (user_id), letters (from_user), challenges (couple_id), goals
(couple_id), tasks (created_by), transactions/gallery/notes/timeline (user_id),
custom_questions (from_id), deck_cards (created_by). **Aniversarios van a ambos** (son fechas de pareja).

El tracking en `bot_notificaciones` filtra por `phone` además de `(tabla, registro_id)`,
así cada destinatario tiene su propio registro anti-duplicado.

## Flujo de ejecucion

```
1. main()
2. loadSessionFromSupabase()
   └── SELECT session_data FROM bot_sessions WHERE id=1
   └── Valida que la sesion coincida con MI_NUMERO leyendo creds.json (me.id)
   └── Escribe archivos en auth/
3. useMultiFileAuthState(auth/)
4. makeWASocket({ auth, printQRInTerminal: false })
5. Espera connection.update → 'open'
   └── Si no hay sesion guardada, muestra QR en terminal
6. saveSessionToSupabase() (guarda por si acaba de escanear QR)
7. verificarYNotificar(sock)
   └── cargarUsuarios() (mapea profiles.id → facu/rocio)
   └── **Ventana dinámica (desde 2026-08-28)**: lee `last_run_at` de `bot_sessions.session_data`; consulta eventos `desde = max(last_run_previo, ahora-24h)` en vez de fija 1h (el cron de CI puede correr con 6-12h de retraso, una ventana fija de 1h pierde eventos). Persiste `last_run_at` al final (saveSessionToSupabase extra).
   └── **LIDs persistidos en `bot_sessions.session_data.lids`** (se cargan desde Supabase, no de `lids.json` en CI efímero).
   └── Itera las 22 categorias + 4b (apertura de cartas)
   └── Para cada registro: yaNotificado(tabla, key, phone) + destinosPara(usuarios, creatorId)
   └── Acumula mensajesPorNum{} (map phone → textos)
   └── Por la regla "cada quien ve lo que agrega la otra": cada registro se enruta
       solo al destinatario que NO lo genero (si no se identifica el creador, a ambos)
 8. Por cada numero con mensajes, une textos con header y envia
9. sock.end()
10. process.exit(0)
```

## Setup inicial (primera vez)

### Instalacion de Node.js

Node.js se instalo via descarga manual (portable ZIP) en:

```
D:\nodejs\node-v20.18.0-win-x64\
├── node.exe       # Runtime Node.js v20.18.0
├── npm.cmd        # Gestor de paquetes npm v10.8.2
├── npx.cmd        # Ejecutor de paquetes
├── corepack.cmd
├── node_modules/  # Modulos globales
└── install_tools.bat
```

No se uso instalador MSI ni `C:\Program Files\nodejs\`. La version portable evita permisos de administrador y mantiene Node.js aislado en `D:`.

### PATH requerido

Node.js **NO** esta en el PATH del sistema. Para cada sesion de terminal, hay que agregarlo manualmente:

**PowerShell:**
```powershell
$env:Path = "D:\nodejs\node-v20.18.0-win-x64;" + $env:Path
```

**CMD:**
```cmd
set PATH=D:\nodejs\node-v20.18.0-win-x64;%PATH%
```

> Para agregarlo permanentemente: `Win + R` > `sysdm.cpl` > Opciones avanzadas > Variables de entorno > PATH > agregar `D:\nodejs\node-v20.18.0-win-x64`

### Variables de entorno del bot (.env)

Archivo `bot-furi\.env` (NO se commitea, esta en .gitignore):

```env
SUPABASE_URL=https://nruyjpvoplkilcxqnees.supabase.co
SUPABASE_KEY=sb_secret_xxx_poner_key_real
MI_NUMERO=5493786499129
FACU_NUMERO=5493786614189
ROCIO_NUMERO=5493786513637
```

| Variable | Descripcion | Donde obtenerla |
|---------|------------|----------------|
| `SUPABASE_URL` | URL del proyecto Supabase | Supabase Dashboard > Settings > API > Project URL |
| `SUPABASE_KEY` | Key de Supabase para lectura/escritura. Desde 2026-08-08 se usa una service role key nueva, porque la anterior fue invalidada por Supabase ("Unregistered API key"). La publishable key de la app (en `lib/supabase_config.dart`) tambien funciona para el bot (policies `FOR ALL USING (true)`) | Supabase Dashboard > Settings > API |
| `MI_NUMERO` | Numero WhatsApp DEL BOT (cuenta que envia) | El numero que vinculaste al QR. Ej: 5493786499129 |
| `FACU_NUMERO` | Numero de Facu que recibe notificaciones | 5493786614189 |
| `ROCIO_NUMERO` | Numero de Rocio que recibe notificaciones | 5493786513637 |

> `MI_NUMERO` es la cuenta de WhatsApp que escaneo el QR (una cuenta aparte para el bot, no el numero personal de Facu ni Rocio). El bot envia desde ese numero a `FACU_NUMERO` y `ROCIO_NUMERO`.

### Ejecutar localmente

**Para iniciar sesion nueva (escanear QR):**
```powershell
# 1. Agregar Node.js al PATH
$env:Path = "D:\nodejs\node-v20.18.0-win-x64;" + $env:Path

# 2. Ir al directorio del bot
cd D:\projetcs\proyectos\F.U.R.I\bot-furi

# 3. Instalar dependencias (solo primera vez)
npm install

# 4. (Opcional) Borrar sesion vieja para re-escanear QR
Remove-Item -Recurse -Force auth -ErrorAction SilentlyContinue

# 5. Ejecutar
node bot.js
```

Se mostrara un QR en la terminal. Escanear con **WhatsApp > Dispositivos vinculados > Vincular un dispositivo**.
La sesion se guarda automaticamente en Supabase (`bot_sessions`) y en `bot-furi/auth/`.

**Para ejecutar con sesion ya guardada:**
```powershell
$env:Path = "D:\nodejs\node-v20.18.0-win-x64;" + $env:Path
cd D:\projetcs\proyectos\F.U.R.I\bot-furi
node bot.js
```

No mostrara QR y verificara eventos inmediatamente.

### Dependencias npm

```json
{
  "dependencies": {
    "@whiskeysockets/baileys": "^6.7.0",   // Conexion WhatsApp Web
    "@supabase/supabase-js": "^2.45.0",     // Cliente Supabase
    "qrcode-terminal": "^0.12.0",           // QR en terminal
    "pino": "^9.0.0",                       // Logger (requerido por Baileys)
    "ws": "^8.18.0",                        // WebSocket para Supabase Realtime
    "dotenv": "^16.4.0"                     // Carga .env automaticamente
  }
}
```

`node_modules/` se excluye del repo (`.gitignore`). Se regenera con `npm install`.

## GitHub Actions

```yaml
on:
  schedule:
    - cron: '*/30 * * * *'  # respaldo cada 30 min
  workflow_dispatch:         # manual
  repository_dispatch:       # webhook en tiempo real desde Supabase (pg_net)
    types: [bot-trigger]
concurrency:
  group: bot-furi
  cancel-in-progress: false
```

### Webhook en tiempo real (desde 2026-08-29)

Supabase dispara el bot **segundos** después de cada INSERT vía `pg_net` → GitHub API.

- **Migración**: `supabase/migration_bot_webhook.sql` crea `furi_trigger_bot()` y triggers `trg_furi_bot_dispatch` en 20 tablas.
- **PAT**: guardado en `vault.decrypted_secrets` con `name = 'github_bot_pat'` (`vault.create_secret('ghp_...', 'github_bot_pat')`).
- **Función**: `POST https://api.github.com/repos/mrtuco748-cmyk/furiiiiiiiiiii/actions/workflows/bot-whatsapp.yml/dispatches` con `ref: main`.
- **Cron 30min** queda como respaldo por si el webhook falla.
- **Verificación**: `SELECT * FROM net._http_response ORDER BY created DESC LIMIT 5;` (status 204 = ok).

Secrets requeridos:
- `SUPABASE_URL` - URL del proyecto Supabase
- `SUPABASE_KEY` - service_role key (para escribir en bot_notificaciones)
- `MI_NUMERO` - numero WhatsApp del bot (cuenta emisora, ej: 5493786499129)
- `FACU_NUMERO` - numero de Facu que recibe notificaciones
- `ROCIO_NUMERO` - numero de Rocio que recibe notificaciones

## Troubleshooting

| Problema | Causa | Solucion |
|---------|-------|---------|
| "Sesion cerrada. Vuelve a ejecutar localmente" | Sesion WhatsApp expiro | `node bot.js` local, re-escanear QR |
| Timeout 60s en CI | No pudo restaurar sesion de Supabase (validacion de numero fallida o sesion expirada) | Verificar tabla bot_sessions, re-escanear |
| "Sesion guardada no coincide..." en CI aunque el numero es correcto | Bug viejo: validacion usaba `Array.first` (undefined en JS) sobre los nombres de archivo | Ya corregido: se valida por contenido de `creds.json` (`me.id`) con `[0]` |
| "Falta SUPABASE_URL o SUPABASE_KEY" | No cargo .env o secrets | Verificar dotenv local, GitHub Secrets en CI |
| Mensajes duplicados | Error en tracking key | Verificar formato de registro_id en bot_notificaciones |
| "ERR_REQUIRE_ESM" | Baileys v6+ es ESM-only | Asegurar `"type": "module"` en package.json |

## Limitaciones

- ~~No es tiempo real (polling cada 30 min)~~ → Desde 2026-08-29 es **tiempo real** vía webhook (polling queda de respaldo)
- WhatsApp puede desconectar sesion en CI (se requiere re-escanear localmente)
- Depende de GitHub Actions uptime y Supabase disponibilidad

## Confirmacion de entrega (desde 2026-08-07)

`enviarMensaje` NO confia en que `sendMessage` resuelve (solo escribe al socket).
Espera el ACK del servidor (`messages.update` con status >= SERVER_ACK, timeout
20s). NO reintenta el envio del mismo mensaje: una vez que la sesion esta sana
(con claves LID), reenviar duplica la entrega porque WhatsApp ya recibio el
texto aunque el ACK tarde mas de 8s en una sesion restaurada de Supabase.
Devuelve `false` solo si `sendMessage` lanza.

El registro "notificado" en `bot_notificaciones` solo se persiste DESPUES de una
entrega confirmada (`flushMarksPendientes(num)`). Si el envio falla, el registro
queda sin marcar y se reintenta en la proxima corrida — nunca se pierde silenciosamente.

### ~~Si los mensajes se quedan "en cola" sin entregarse~~ ✅ RESUELTO 2026-08-11

Sintoma: `sendMessage` resuelve pero el destinatario no recibe nada y no llega ACK.
Causa raiz: desde ~2026-08-10 WhatsApp migro el enrutamiento de contactos a IDs de
dispositivo vinculado (LID). Enviar al JID con numero normal (`549...@s.whatsapp.net`)
resuelve sin error pero el servidor NO entrega (perdida silenciosa, sin receipt).
Sintoma observable: el log de Baileys mostraba "sending message to 3 devices"
(cuando antes decia 4) el mismo dia de la migracion, y los ACKs dejaron de llegar.

Fix implementado (2026-08-11): resolver los LIDs con `sock.onWhatsApp(numero)`
(devuelve `lid: "83189842346022@lid"`, con el sufijo incluido) y enviar al JID LID
(`83189842346022@lid`) en vez del numero normal.

- `bot-furi/lids.json`: cache de LIDs (numero → `xxx@lid`), gitignored.
- `main()`: si falta algun LID, los resuelve en una **conexion descartable**
  (`resolverLidsSolo()`) ANTES de la conexion principal. Motivo: `onWhatsApp()`
  puede romper el stream con `stream:error xml-not-well-formed` (bug de Baileys,
  reproducible 2 de 3 veces); al ejecutarlo en una conexion aparte, la conexion
  principal queda sana para enviar.
- `enviarMensaje()` usa SOLO el cache de LIDs (nunca llama onWhatsApp en la
  conexion principal). Si no hay LID cacheado, cae al JID normal.
- `esperarAck()` agrego un `sock.ev.flush()` periodico cada 2s: el event buffer
  de Baileys retiene `messages.update` durante `AwaitingInitialSync`; el flush
  libera los ACKs acumulados para que la confirmacion llegue a tiempo.
- Verificado end-to-end: mood de prueba → mensaje enviado al JID LID de Facu →
  `status=4` (leido) en `83189842346022@lid` → registro marcado en
  `bot_notificaciones` → limpieza del dato de prueba.

Fix descartado: re-vincular WhatsApp (borrar `auth/` + re-escanear QR) NO sirve
para este problema: la sesion tenia las claves LID de los contactos y aun asi no
entregaba; el bloqueo era del JID destino, no de las claves de cifrado.

Los logs de fondo mostraban errores `failed to decrypt message` (inofensivos,
mensajes de estado) — no eran la causa.
