# Bot WhatsApp de F.U.R.I

## Propósito
Bot que notifica por WhatsApp sobre actividad en la app F.U.R.I cada 30 minutos.
Envia mensajes a ambos integrantes de la pareja (Facu y Rocio) con las novedades detectadas.

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

## Categorias notificadas (12)

| # | Tabla | Icono | Regla | Tracking key |
|---|-------|-------|-------|-------------|
| 1 | schedules | 📅 | Proximas 2h | `schedule-{id}-{date}-{startTime}` |
| 2 | anniversaries | 🎉 | Hoy (8-10 AM) + mañana | `anniversary-{id}-{date}` |
| 3 | moods | 😊 | Ultima 1h | `mood-{id}` |
| 4 | letters | 💌 | Ultima 1h | `letter-{id}` |
| 5 | challenges | 🚩 | Ultima 1h (creado/iniciado/completado) | `challenge-{id}` |
| 6 | goals | 🏅 | Ultima 1h (creada/completada) | `goal-{id}` |
| 7 | tasks | ✅ | Ultima 1h | `task-{id}` |
| 8 | transactions | 💰/💸 | Ultima 1h (income/expense) | `transaction-{id}` |
| 9 | favorites | ⭐ | Ultima 1h | `favorite-{id}` |
| 10 | notes | 📝 | Ultima 1h | `note-{id}` |
| 11 | gallery | 🖼️ | Ultima 1h | `gallery-{id}` |
| 12 | timeline_events | 🕐 | Ultima 1h | `timeline-{id}` |

**No notifica**: messages (ya tienen push via FCM)

## Flujo de ejecucion

```
1. main()
2. loadSessionFromSupabase()
   └── SELECT session_data FROM bot_sessions WHERE id=1
   └── Valida que la sesion coincida con MI_NUMERO
   └── Escribe archivos en auth/
3. useMultiFileAuthState(auth/)
4. makeWASocket({ auth, printQRInTerminal: false })
5. Espera connection.update → 'open'
   └── Si no hay sesion guardada, muestra QR en terminal
6. saveSessionToSupabase() (guarda por si acaba de escanear QR)
7. verificarYNotificar(sock)
   └── Itera las 12 categorias
   └── yaNotificado(tabla, key) para cada registro
   └── Acumula mensajes[]
   └── Si hay mensajes, los une con header y envia
8. enviarMensaje(sock, num, texto) para FACU_NUMERO y ROCIO_NUMERO
9. sock.end()
10. process.exit(0)
```

## Setup inicial (primera vez)

```bash
cd bot-furi
npm install
node bot.js
# Escanea el QR con WhatsApp > Dispositivos vinculados
# La sesion se guarda automaticamente en Supabase
```

## GitHub Actions

```yaml
on:
  schedule:
    - cron: '*/30 * * * *'  # cada 30 min
  workflow_dispatch:         # manual
```

Secrets requeridos:
- `SUPABASE_URL` - URL del proyecto Supabase
- `SUPABASE_KEY` - service_role key (para escribir en bot_notificaciones)
- `MI_NUMERO` - numero de WhatsApp del bot (cuenta desde la que se envia, ej: 5493786499129)
- `FACU_NUMERO` - numero de Facu para recibir notificaciones
- `ROCIO_NUMERO` - numero de Rocio para recibir notificaciones

## Troubleshooting

| Problema | Causa | Solucion |
|---------|-------|---------|
| "Sesion cerrada. Vuelve a ejecutar localmente" | Sesion WhatsApp expiro | `node bot.js` local, re-escanear QR |
| Timeout 60s en CI | No pudo restaurar sesion de Supabase | Verificar tabla bot_sessions, re-escanear |
| "Falta SUPABASE_URL o SUPABASE_KEY" | No cargo .env o secrets | Verificar dotenv local, GitHub Secrets en CI |
| Mensajes duplicados | Error en tracking key | Verificar formato de registro_id en bot_notificaciones |
| "ERR_REQUIRE_ESM" | Baileys v6+ es ESM-only | Asegurar `"type": "module"` en package.json |

## Limitaciones

- No es tiempo real (polling cada 30 min)
- WhatsApp puede desconectar sesion en CI (se requiere re-escanear localmente)
- Depende de GitHub Actions uptime y Supabase disponibilidad
