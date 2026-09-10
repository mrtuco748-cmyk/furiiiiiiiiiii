import 'dotenv/config';
import { makeWASocket, useMultiFileAuthState, DisconnectReason } from '@whiskeysockets/baileys';
import { createClient } from '@supabase/supabase-js';
import qrcode from 'qrcode-terminal';
import pino from 'pino';
import WebSocket from 'ws';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ─── CONFIG ───────────────────────────────────────────────────
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_KEY;
const MI_NUMERO = process.env.MI_NUMERO || process.env.TU_NUMERO;
const FACU_NUMERO = process.env.FACU_NUMERO;
const ROCIO_NUMERO = process.env.ROCIO_NUMERO;
const AUTH_DIR = path.join(__dirname, 'auth');
const SESSION_TABLE = 'bot_sessions';
const NOTIF_TABLE = 'bot_notificaciones';

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('Falta SUPABASE_URL o SUPABASE_KEY en variables de entorno');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY, {
  realtime: { transport: WebSocket },
});

// ─── RESOLUCION DE LIDS ────────────────────────────────────────
// Desde ~2026-08-10 WhatsApp migro el enrutamiento de contactos a IDs de
// dispositivo vinculado (@lid): enviar al JID con numero (@s.whatsapp.net)
// resuelve sin error pero el servidor NO entrega (perdida silenciosa).
// Resolvemos el LID con sock.onWhatsApp() y lo cacheamos en lids.json para
// no depender de esa llamada (que puede romper el stream) en cada corrida.
const LID_CACHE_FILE = path.join(__dirname, 'lids.json');
const lidCache = {};
// Ventana de deteccion dinamica: GitHub Actions cron (*/30) corre con horas de
// retraso, asi que una ventana fija de 1h perdía eventos en silencio. Guardamos
// last_run_at en bot_sessions y desde la proxima corrida consultamos TODO lo
// ocurrido desde la corrida anterior (capped a 24h). El dedupe de
// bot_notificaciones hace que re-consultar sea seguro.
let lastRunPrevio = null;
// Marca de tiempo del inicio de la corrida actual; se persiste en
// bot_sessions para que la siguiente corrida consulte desde aca.
let lastRunActual = null;

function cargarLidsCache() {
  try {
    const data = JSON.parse(fs.readFileSync(LID_CACHE_FILE, 'utf-8'));
    for (const [phone, lid] of Object.entries(data)) lidCache[phone] = lid;
    const entries = Object.entries(lidCache);
    if (entries.length > 0) {
      console.log('LIDs cacheados: ' + entries.map(([p, l]) => `${p} -> ${l}`).join(', '));
    }
  } catch { /* todavia no existe el cache */ }
}

function guardarLidCache(phone, lid) {
  lidCache[phone] = lid;
  try { fs.writeFileSync(LID_CACHE_FILE, JSON.stringify(lidCache, null, 2)); } catch { /* noop */ }
}

// Devuelve el JID LID de un numero (usa cache si existe). Si no se puede
// resolver, devuelve el JID normal como fallback (con LID roto no entrega,
// pero es el mismo comportamiento que antes del fix).
// NOTA: en Baileys 6.7.x el campo `lid` de onWhatsApp ya incluye el sufijo
// "@lid" (ej: "83189842346022@lid"). Se normaliza por si alguna version
// devuelve solo el numero.
async function lidJid(sock, phone) {
  if (!phone) return null;
  const cached = lidCache[phone];
  if (cached) return cached;
  try {
    const res = await sock.onWhatsApp(phone);
    const lid = res?.[0]?.lid;
    if (lid) {
      const jid = lid.includes('@lid') ? lid : `${lid}@lid`;
      guardarLidCache(phone, jid);
      console.log(`LID resuelto: ${phone} -> ${jid}`);
      return jid;
    }
    console.log(`No se encontro LID para ${phone}`);
  } catch (e) {
    console.error(`Error resolviendo LID de ${phone}:`, e.message);
  }
  return `${phone}@s.whatsapp.net`;
}

// Conexion DESCARTABLE para resolver LIDs. onWhatsApp() puede romper el
// stream con "xml-not-well-formed" (bug de Baileys), asi que se ejecuta en
// una conexion aparte que se descarta; la conexion principal solo usa el
// cache y nunca llama onWhatsApp (su stream queda sano para enviar).
function resolverLidsSolo() {
  return new Promise(async (resolve) => {
    let resuelto = false;
    const finish = (motivo) => {
      if (resuelto) return;
      resuelto = true;
      console.log(`Fin conexion descartable (${motivo})`);
      try { sock.end(); } catch { /* noop */ }
      resolve();
    };

    const { state } = await useMultiFileAuthState(AUTH_DIR);
    const sock = makeWASocket({
      auth: state,
      printQRInTerminal: false,
      logger: pino({ level: 'warn' }),
    });

    sock.ev.on('connection.update', async (update) => {
      if (update.connection === 'open') {
        console.log('Conexion descartable abierta, resolviendo LIDs...');
        try {
          for (const num of [FACU_NUMERO, ROCIO_NUMERO]) {
            if (num && !lidCache[num]) await lidJid(sock, num);
          }
        } catch (e) {
          console.error('Error resolviendo LIDs:', e.message);
        }
        finish('lids ok');
      }
      if (update.connection === 'close') finish('close');
    });

    // timeout duro: nunca colgar
    setTimeout(() => finish('timeout'), 45000);
  });
}

// ─── SESION EN SUPABASE ───────────────────────────────────────
async function loadSessionFromSupabase() {
  const { data, error } = await supabase
    .from(SESSION_TABLE)
    .select('session_data')
    .eq('id', 1)
    .single();

  if (error || !data || !data.session_data || Object.keys(data.session_data).length === 0) {
    console.log('No hay sesion guardada en Supabase. Se solicitara QR.');
    return false;
  }

  const session = data.session_data;

  // Valida que la sesion corresponda a MI_NUMERO verificando el contenido de
  // creds.json (campo me.id: "<pais><numer o>@s.whatsapp.net"), NO los nombres
  // de archivo (creds.json, session-*.json, etc. no incluyen el numero).
  const creds = session['creds.json'];
  const credsFull = String(creds?.me?.id ?? '');
  const credsNumber = credsFull.replace('@s.whatsapp.net', '').split(':')[0];
  const numeroCoincide = (credsNumber === (MI_NUMERO || '')) || (!MI_NUMERO);
  if (!numeroCoincide) {
    console.log(`Sesion guardada no coincide con el numero ${MI_NUMERO}. Se ignorara y se solicitara QR.`);
    return false;
  }

  if (!fs.existsSync(AUTH_DIR)) fs.mkdirSync(AUTH_DIR, { recursive: true });

  for (const [filename, content] of Object.entries(session)) {
    // 'lids' y 'last_run_at' son metadatos de la corrida, no archivos de sesion
    if (!filename.endsWith('.json')) continue;
    fs.writeFileSync(path.join(AUTH_DIR, filename), JSON.stringify(content));
  }

  // Recuperar LIDs cacheados (evita la conexion descartable en cada corrida de CI)
  if (session['lids'] && typeof session['lids'] === 'object') {
    for (const [phone, lid] of Object.entries(session['lids'])) {
      if (!lidCache[phone]) lidCache[phone] = lid;
    }
  }

  // Recuperar la fecha de la ultima corrida para la ventana de deteccion
  if (session['last_run_at']) {
    const t = Date.parse(session['last_run_at']);
    if (!Number.isNaN(t)) lastRunPrevio = t;
  }

  console.log('Sesion cargada desde Supabase');
  return true;
}

async function saveSessionToSupabase() {
  if (!fs.existsSync(AUTH_DIR)) return;

  const files = fs.readdirSync(AUTH_DIR).filter(f => f.endsWith('.json'));
  const session = {};
  for (const file of files) {
    try {
      const content = JSON.parse(fs.readFileSync(path.join(AUTH_DIR, file), 'utf-8'));
      session[file] = content;
    } catch (e) {
      console.error(`Error leyendo ${file}:`, e.message);
    }
  }

  if (Object.keys(session).length === 0) return;

  // Persistir metadatos de la corrida junto con la sesion (misma fila id=1)
  const entriesLids = Object.entries(lidCache);
  if (entriesLids.length > 0) session['lids'] = lidCache;
  if (lastRunActual) session['last_run_at'] = lastRunActual;

  const { error } = await supabase
    .from(SESSION_TABLE)
    .upsert({ id: 1, session_data: session, updated_at: new Date().toISOString() });

  if (error) {
    console.error('Error guardando sesion en Supabase:', error.message);
  } else {
    console.log('Sesion guardada en Supabase');
  }
}

// ─── CONEXION WHATSAPP ────────────────────────────────────────
// reintentos maximos por corrida (evita loop infinito que cuelga el job de CI)
const MAX_REINTENTOS = 3;
// timeout global duro: pase lo que pase, la corrida termina (CI no debe colgar)
const TIMEOUT_GLOBAL_MS = 180000;

function conectarYNotificar() {
  let intentos = 0;
  return conectarIntento();

  function conectarIntento() {
    const tiempoReintento = 'intento-' + (intentos + 1);
    return new Promise(async (resolve) => {
      const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR);

      const sock = makeWASocket({
        auth: state,
        printQRInTerminal: false,
        logger: pino({ level: 'warn' }),
      });

      let resuelto = false;

    sock.ev.on('connection.update', async (update) => {
      const { connection, lastDisconnect, qr } = update;

      if (qr) {
        console.log('Escanea este QR con WhatsApp:');
        qrcode.generate(qr, { small: true });
      }

      if (connection === 'open') {
        console.log('Conectado a WhatsApp');
        if (!resuelto) {
          resuelto = true;
          try {
            await saveSessionToSupabase();
            await verificarYNotificar(sock);
            // Guardar de nuevo: verificar setea lastRunActual, y la marca debe
            // persistirse para que la proxima corrida consulte desde aca.
            await saveSessionToSupabase();
          } catch (e) {
            console.error('Error en verificacion:', e.message);
          }
          sock.end();
          resolve();
        }
      }

      if (connection === 'close') {
        const statusCode = lastDisconnect?.error?.output?.statusCode;
        if (statusCode === DisconnectReason.loggedOut) {
          console.log('Sesion cerrada. Vuelve a ejecutar localmente para re-escanear QR.');
          if (!resuelto) { resuelto = true; resolve(); }
        } else if (!resuelto) {
          intentos++;
          if (intentos >= MAX_REINTENTOS) {
            console.log(`No se pudo conectar en ${intentos} intentos. Abortando.`);
            resuelto = true;
            resolve();
          } else {
            console.log(`Conexion cerrada, reintentando (${intentos}/${MAX_REINTENTOS})...`);
            setTimeout(async () => {
              if (resuelto) { resolve(); return; }
              try {
                await conectarIntento();
                resolve();
              } catch (e) {
                console.error('Error en reintento:', e.message);
                resolve();
              }
            }, 3000);
          }
        }
      }
    });

    sock.ev.on('creds.update', async () => {
      await saveCreds();
      await saveSessionToSupabase();
    });

    setTimeout(() => {
      if (!resuelto) {
        console.log(`Timeout: no se pudo conectar en ${TIMEOUT_GLOBAL_MS / 1000}s (intento ${intentos + 1}).`);
        resuelto = true;
        resolve();
      }
    }, 60000);
  });
  }
}

// ─── UTIL: ENVIAR MENSAJE (espera confirmacion + reintento) ──
// Baileys: sendMessage resuelve apenas escribe al socket, NO cuando WhatsApp
// entrega. Esperamos el ACK del servidor (status >= SERVER_ACK). Si NO hay ACK,
// devolvemos false: el registro NO se marca como notificado y se reintenta en
// la proxima corrida (evita perdida silenciosa).
//
// IMPORTANTE: el listener de messages.update debe registrarse ANTES de llamar
// sendMessage. Si se registra despues del await, los eventos del buffer de
// Baileys ya se emitieron y el ACK se pierde (confirmado por diag 2026-08-11).
async function enviarMensaje(sock, phone, mensaje) {
  // SOLO cache: nunca llamar onWhatsApp aca (rompe el stream de la conexion
  // principal). Si no hay LID, se manda al JID normal como antes.
  const jid = phone.includes('@s.whatsapp.net')
    ? phone
    : (lidCache[phone] || `${phone}@s.whatsapp.net`);
  const ack = esperarAck(sock, 20000);
  try {
    const res = await sock.sendMessage(jid, { text: mensaje });
    const id = res?.key?.id;
    const confirmado = await ack(id);
    if (confirmado) {
      console.log(`Mensaje enviado y confirmado a ${phone}`);
    } else {
      console.log(`SIN CONFIRMACION para ${phone}: el mensaje no se marca como notificado y se reintentara.`);
    }
    return confirmado;
  } catch (e) {
    console.error(`Error enviando a ${phone}:`, e.message);
    return false;
  }
}

// Crea un "esperador de ACK" que registra el listener de inmediato y devuelve
// una funcion que, dado el id del mensaje, resuelve true si WhatsApp confirma
// la entrega (status >= SERVER_ACK) dentro del timeout.
// NOTA: en Baileys 6.7.x el status llega en update.status (anidado), no en
// status directo. Se soportan ambos formatos por compatibilidad.
function esperarAck(sock, timeoutMs) {
  const esperas = [];
  let cleaned = false;
  // El event buffer de Baileys retiene messages.update durante
  // AwaitingInitialSync; flush periodico libera los ACKs acumulados.
  const flushInt = setInterval(() => {
    try { sock.ev.flush?.(); } catch { /* noop */ }
  }, 2000);

  // Quita el listener y el timer una vez que no quedan esperas pendientes
  // (evita acumular listeners messages.update por cada envio).
  const limpiar = () => {
    if (cleaned) return;
    cleaned = true;
    clearInterval(flushInt);
    try { sock.ev.off('messages.update', handler); } catch { /* noop */ }
  };

  const handler = (updates) => {
    for (const u of updates) {
      const status = u.update?.status ?? u.status;
      if (![1, 2, 3, 4].includes(status)) continue;
      for (let i = esperas.length - 1; i >= 0; i--) {
        const e = esperas[i];
        if (e.id && e.id === u.key?.id && !e.done) {
          e.done = true;
          clearTimeout(e.timer);
          esperas.splice(i, 1);
          e.resolve(true);
        }
      }
    }
    if (esperas.length === 0) limpiar();
  };
  sock.ev.on('messages.update', handler);

  return (id) => new Promise((resolve) => {
    const e = { id, resolve, done: false, timer: null };
    if (!id) { limpiar(); resolve(false); return; }
    e.timer = setTimeout(() => {
      if (!e.done) {
        e.done = true;
        const idx = esperas.indexOf(e);
        if (idx >= 0) esperas.splice(idx, 1);
        resolve(false);
        if (esperas.length === 0) limpiar();
      }
    }, timeoutMs);
    esperas.push(e);
  });
}

// ─── UTIL: YA FUE NOTIFICADO? ─────────────────────────────────
async function yaNotificado(tabla, registroId, phone) {
  let query = supabase
    .from(NOTIF_TABLE)
    .select('id')
    .eq('tabla', tabla)
    .eq('registro_id', String(registroId));

  if (phone) query = query.eq('phone', phone);
  query = query.limit(1);

  const { data, error } = await query;
  if (error) {
    console.error(`Error en yaNotificado (${tabla}/${registroId}):`, error.message);
    return false;
  }
  return data && data.length > 0;
}

// ─── UTIL: MARCAR COMO NOTIFICADO (pendiente hasta confirmar envio) ──
// No escribe en la BD inmediatamente: acumula en memoria y solo se persiste
// cuando el mensaje se confirmo como enviado (ver flushMarksPendientes).
const marksPendientes = [];
function marcarNotificado(tabla, registroId, tipo, phone, mensaje) {
  marksPendientes.push({ tabla, registro_id: String(registroId), tipo, phone, mensaje });
}

// Persiste en la BD las notificaciones pendientes SOLO del numero indicado,
// despues de confirmar que el mensaje fue enviado. Si el envio fallo, no se
// marca, por lo que en la proxima corrida el bot lo re-enviara (no se pierde).
async function flushMarksPendientes(phone) {
  const pendientes = marksPendientes.filter(m => m.phone === phone);
  if (pendientes.length === 0) return;
  for (const m of pendientes) {
    const { error } = await supabase.from(NOTIF_TABLE).insert(m);
    if (error) console.error(`Error marcando notificado (${m.tabla}/${m.registro_id}):`, error.message);
  }
  // Eliminamos los que ya flusheamos (marcamos como escritos)
  const escritos = new Set(pendientes.map(m => m.tabla + '|' + m.registro_id + '|' + m.phone));
  for (let i = marksPendientes.length - 1; i >= 0; i--) {
    const m = marksPendientes[i];
    if (escritos.has(m.tabla + '|' + m.registro_id + '|' + m.phone)) marksPendientes.splice(i, 1);
  }
}

// ─── USUARIOS (mapeo user_id de la app → identidad) ──────────
// Devuelve { facu: <uuid>, rocio: <uuid> } leyendo la tabla profiles.
async function cargarUsuarios() {
  const { data, error } = await supabase.from('profiles').select('id, name');
  if (error) console.error('Error en cargarUsuarios (profiles):', error.message);
  const map = { facu: null, rocio: null };
  for (const p of data || []) {
    const key = String(p.name || '').toLowerCase();
    if (key === 'facu') map.facu = p.id;
    if (key === 'rocio') map.rocio = p.id;
  }
  return map;
}

// Determina a qué destinatarios va un registro según quién lo creó.
// Regla: cada quien recibe solo lo que agrega la OTRA persona.
// Si el creador no se puede identificar, va a ambos (default).
function destinosPara(usuarios, creatorId) {
  // creatorId puede ser el UUID de profiles (otras tablas) o la identidad
  // (AppState.identity) que la app guarda en schedules/class_schedules.user_id.
  const id = String(creatorId || '').toLowerCase();
  if (usuarios.facu && (id === String(usuarios.facu).toLowerCase() || id === 'facu')) return [ROCIO_NUMERO].filter(Boolean);
  if (usuarios.rocio && (id === String(usuarios.rocio).toLowerCase() || id === 'rocio')) return [FACU_NUMERO].filter(Boolean);
  return [FACU_NUMERO, ROCIO_NUMERO].filter(Boolean);
}

// ─── FORMATO DE HORA ──────────────────────────────────────────
function formatHora(hora) {
  if (!hora) return '';
  return hora.slice(0, 5);
}

// ─── ZONA HORARIA DE LA APP ────────────────────────────────────
// La app Flutter vive en Argentina (America/Argentina/Buenos_Aires, UTC-3 sin DST).
// GitHub Actions corre en UTC; por eso todas las fechas/horas LOCALES se calculan
// con la zona del dispositivo (la app guarda fechas y horarios locales).
const APP_TZ = process.env.APP_TZ || 'America/Argentina/Buenos_Aires';

let _tzOffsetMs;
function tzOffsetMs() {
  if (_tzOffsetMs === undefined) {
    const now = new Date();
    const fmt = new Intl.DateTimeFormat('en-US', { timeZone: APP_TZ, hour12: false, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit' });
    const p = {};
    for (const e of fmt.formatToParts(now)) p[e.type] = e.value;
    _tzOffsetMs = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour, +p.minute, +p.second) - now.getTime();
  }
  return _tzOffsetMs;
}

// Fecha local (YYYY-MM-DD) en la zona de la app.
function fechaLocal(dateObj = new Date()) {
  return new Intl.DateTimeFormat('en-CA', { timeZone: APP_TZ }).format(dateObj);
}

// Hora local actual (HH) en la zona de la app.
function horaLocal() {
  return new Intl.DateTimeFormat('en-US', { timeZone: APP_TZ, hour12: false, hour: '2-digit', minute: '2-digit' }).format(new Date()).slice(0, 2);
}

// Convierte una hora "de pared" (dateStr 'YYYY-MM-DD' + timeStr 'HH:MM') escrita en
// zona local de la app a un instante absoluto Date, para compararlo contra `ahora`.
function localInstant(dateStr, timeStr) {
  const asUtc = new Date(`${dateStr}T${timeStr || '00:00'}:00Z`);
  return new Date(asUtc.getTime() - tzOffsetMs());
}

// Dias consecutivos hacia atras desde la primera fecha (listado desc,
// strings YYYY-MM-DD). Usado para detectar racha rota de entrenamiento.
function diasConsecutivos(fechas) {
  if (!fechas.length) return 0;
  let streak = 1;
  let cursor = new Date(fechas[0] + 'T00:00:00Z');
  for (let i = 1; i < fechas.length; i++) {
    const prev = new Date(cursor.getTime() - 24 * 60 * 60 * 1000);
    if (fechas[i] === prev.toISOString().slice(0, 10)) {
      streak++;
      cursor = prev;
    } else {
      break;
    }
  }
  return streak;
}

// Emoji + titulo para el aviso de un logro de pareja desbloqueado.
// Mapea TODOS los códigos de lib/models/couple_achievement.dart.
function descripcionLogro(code) {
  const map = {
    first_mood: '🌅 *Primer día* (ambos con estado de ánimo)',
    workout_both: '💪 *Equipo activo* (ambos entrenaron)',
    furi_first: '🃏 *Primer FURI!!* (primer match del mazo)',
    streak_3: '🔥 *Racha en marcha* (3 días de racha de pareja)',
    streak_7: '🔥 *Una semana completa* (7 días)',
    best_streak_14: '🌟 *Medio mes* (mejor racha 14+)',
    messages_100: '💬 *Conversadores* (100 mensajes)',
    messages_1000: '💬 *No se callan nada* (1000 mensajes)',
    messages_500: '💬 *Charla larga* (500 mensajes)',
    messages_2000: '💬 *Devotos* (2000 mensajes)',
    messages_5000: '💬 *Inseparables* (5000 mensajes)',
    mood_streak_7: '😊 *Ánimo en pareja* (7 días de ánimo ambos)',
    mood_streak_14: '😊 *Quince días* (14 días de ánimo ambos)',
    mood_streak_30: '😊 *Mes completo* (30 días de ánimo ambos)',
    workouts_50: '🏋️ *En racha* (50 sesiones entre ambos)',
    workout_100: '🏋️ *Cien veces* (100 sesiones entre ambos)',
    workout_200: '🏋️ *Doscientas* (200 sesiones entre ambos)',
    location_shared: '📍 *Cerca tuyo* (ambos compartieron ubicación)',
    reward_fulfilled: '🎁 *Deseo cumplido* (primera recompensa de la cajita)',
    first_reward: '🎁 *Deseo #1* (primera recompensa cumplida)',
    rewards_3: '🎁 *Cajita llena* (3 recompensas cumplidas)',
    trivia_day: '🎯 *Se conocen* (ambos respondieron la trivia del día)',
    trivia_7: '🎯 *Semana de sabios* (7 días respondiendo ambos)',
    trivia_30: '🎯 *Maestros* (30 días respondiendo ambos)',
    trivia_100: '🎯 *Genios* (100 respuestas de trivia entre ambos)',
    first_letter: '💌 *Primera carta* (enviaron su primera carta)',
    letters_10: '💌 *Decálogo* (10 cartas entre ambos)',
    letters_50: '💌 *Epistolario* (50 cartas entre ambos)',
    first_challenge: '🚩 *Reto nacido* (primer reto juntos)',
    challenges_3: '🚩 *Triunfadores* (3 retos completados entre ambos)',
    first_goal: '🏅 *Primera meta* (primera meta completada juntos)',
    goals_5: '🏅 *Cinco estrellas* (5 metas completadas entre ambos)',
    furi_3: '🃏 *Tres FURI* (3 matches del mazo)',
    furi_10: '🃏 *Diez FURI* (10 matches del mazo)',
    points_100: '⭐ *Cien puntos* (100 puntos de pareja)',
    points_500: '⭐ *Quinientos* (500 puntos de pareja)',
    points_1000: '⭐ *Mil puntos* (1000 puntos de pareja)',
    first_photo: '🖼️ *Primera foto* (primera foto en la galería)',
    photos_10: '🖼️ *Álbum pequeño* (10 fotos en la galería)',
    first_favorite: '⭐ *Favorito* (primer favorito guardado)',
    favorites_10: '⭐ *Coleccionistas* (10 favoritos entre ambos)',
    distance_1km: '📍 *Cerca* (se separaron al menos 1 km)',
    distance_100km: '📍 *Lejos pero juntos* (se separaron al menos 100 km)',
    first_activity_both: '🏃 *En movimiento* (ambos con mood y entrenados el mismo día)',
  };
  if (map[code]) return map[code];
  // Fallback legible para códigos futuros: snake_case -> Capitalizado
  const readable = String(code || '')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
  return readable ? `🏅 *${readable}*` : '🏅 *Logro desbloqueado*';
}

// ─── VERIFICAR EVENTOS ────────────────────────────────────────
async function verificarYNotificar(sock) {
  console.log('Verificando eventos...');
  // mensajesPorNum: { '54...': ["texto1", "texto2"], ... }
  const mensajesPorNum = {};
  const encolar = (phone, texto) => {
    (mensajesPorNum[phone] = mensajesPorNum[phone] || []).push(texto);
  };

  const usuarios = await cargarUsuarios();

  const ahora = new Date();
  // Ventana dinamica: desde la ultima corrida (capped a 24h por si el bot
  // estuvo caido mas de un dia); fallback a 1h si no hay marca previa.
  lastRunActual = ahora.toISOString();
  const haceUnaHora = new Date(ahora.getTime() - 60 * 60 * 1000).toISOString();
  const desde = lastRunPrevio
    ? new Date(Math.max(lastRunPrevio, ahora.getTime() - 24 * 60 * 60 * 1000)).toISOString()
    : haceUnaHora;
  if (lastRunPrevio) {
    console.log(`Ventana de deteccion: desde ${desde}`);
  }
  const enDosHoras = new Date(ahora.getTime() + 2 * 60 * 60 * 1000);

  const hoy = fechaLocal(ahora);
  const manana = fechaLocal(new Date(ahora.getTime() + 24 * 60 * 60 * 1000));

  // ── 1. SCHEDULES (clases/eventos) ──
  const { data: schedules } = await supabase
    .from('schedules')
    .select('*')
    .eq('date', hoy)
    .order('startTime');

  if (schedules) {
    for (const s of schedules) {
      const inicio = localInstant(s.date, s.startTime);
      if (inicio <= enDosHoras && inicio > ahora) {
        const key = `schedule-${s.id}-${s.date}-${s.startTime}`;
        const destinos = destinosPara(usuarios, s.user_id);
        for (const phone of destinos) {
          if (!(await yaNotificado('schedules', key, phone))) {
            const minutos = Math.round((inicio - ahora) / 60000);
            encolar(phone,
              `📅 *${s.title}*\n` +
              `⏰ ${formatHora(s.startTime)} - ${formatHora(s.endTime)}\n` +
              `📍 ${s.location || 'Sin ubicacion'}\n` +
              `⏳ En ${minutos} minutos`);
            await marcarNotificado('schedules', key, 'proximo', phone, s.title);
          }
        }
      }
    }
  }

  // ── 1b. CLASS_SCHEDULES (clases recurrentes por dia de semana) ──
  const { data: classSchedules } = await supabase
    .from('class_schedules')
    .select('*');

  if (classSchedules && classSchedules.length > 0) {
    // day_of_week se guarda con convencion Dart (1=lunes ... 7=domingo),
    // mientras que Date.getDay() es 0=domingo ... 6=sabado.
    const jsDia = new Date().getDay();
    const diaDeHoy = jsDia === 0 ? 7 : jsDia;
    for (const c of classSchedules) {
      if (c.day_of_week !== diaDeHoy) continue;
      const inicio = localInstant(hoy, c.start_time);
      if (inicio <= enDosHoras && inicio > ahora) {
        const key = `class-${c.id}-${hoy}-${c.start_time}`;
        const horario = c.end_time
          ? `${formatHora(c.start_time)} - ${formatHora(c.end_time)}`
          : formatHora(c.start_time);
        const texto = `📚 *Clase: ${c.title}*\n` +
          `⏰ ${horario}\n` +
          `⏳ En ${Math.round((inicio - ahora) / 60000)} minutos`;
        const destinos = destinosPara(usuarios, c.user_id);
        for (const phone of destinos) {
          if (!(await yaNotificado('class_schedules', key, phone))) {
            encolar(phone, texto);
            await marcarNotificado('class_schedules', key, 'proximo', phone, c.title);
          }
        }
      }
    }
  }

  // ── 2. ANNIVERSARIES ──
  const { data: anniversaries } = await supabase
    .from('anniversaries')
    .select('*');

  if (anniversaries) {
    const destinos = [FACU_NUMERO, ROCIO_NUMERO].filter(Boolean);
    for (const a of anniversaries) {
      const fecha = String(a.date).slice(0, 10);
      if (fecha === hoy) {
        const key = `anniversary-${a.id}-${hoy}`;
        const ahoraHora = horaLocal();
        if (ahoraHora >= 8 && ahoraHora <= 10) {
          for (const phone of destinos) {
            if (!(await yaNotificado('anniversaries', key, phone))) {
              encolar(phone, `🎉 *Hoy es ${a.title}!*`);
              await marcarNotificado('anniversaries', key, 'hoy', phone, a.title);
            }
          }
        }
      } else if (fecha === manana) {
        const key = `anniversary-${a.id}-${manana}-aviso`;
        for (const phone of destinos) {
          if (!(await yaNotificado('anniversaries', key, phone))) {
            encolar(phone, `📢 *Recordatorio: manana es ${a.title}*`);
            await marcarNotificado('anniversaries', key, 'manana', phone, a.title);
          }
        }
      }
    }
  }

  // ── 3. MOODS (emociones nuevas) ──
  const { data: moods } = await supabase
    .from('moods')
    .select('*, profiles:user_id(name)')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (moods) {
    for (const m of moods) {
      const key = `mood-${m.id}`;
      const destinos = destinosPara(usuarios, m.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('moods', key, phone))) {
          const nombre = m.profiles?.name || 'Alguien';
          encolar(phone, `😊 *${nombre}* registro una emocion: ${m.mood}${m.note ? ' - ' + m.note : ''}`);
          await marcarNotificado('moods', key, 'nueva', phone, m.mood);
        }
      }
    }
  }

  // ── 4. LETTERS (cartas nuevas) ──
  const { data: letters } = await supabase
    .from('letters')
    .select('*, sender:profiles!from_user(name)')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (letters) {
    for (const l of letters) {
      // Cartas selladas (apertura futura): no se spoilean al crearse.
      if (l.scheduled_open && new Date(l.scheduled_open).getTime() > Date.now()) continue;
      const key = `letter-${l.id}`;
      const destinos = destinosPara(usuarios, l.from_user);
      for (const phone of destinos) {
        if (!(await yaNotificado('letters', key, phone))) {
          const nombre = l.sender?.name || 'Alguien';
          encolar(phone, `💌 *${nombre}* te envio una carta: "${l.title}"`);
          await marcarNotificado('letters', key, 'nueva', phone, l.title);
        }
      }
    }
  }

  // ── 4b. LETTERS: ENTREGA CEREMONIAL (selladas que se abren ahora) ──
  // Cuando el momento de apertura llega, el bot "entrega" la carta con impacto.
  const { data: aabrirse } = await supabase
    .from('letters')
    .select('*, sender:profiles!from_user(name)')
    .gte('scheduled_open', desde)
    .lte('scheduled_open', ahora.toISOString())
    .order('scheduled_open', { ascending: false });

  if (aabrirse) {
    for (const l of aabrirse) {
      const oday = (l.scheduled_open || '').slice(0, 10) || hoy;
      const key = `letteropen-${l.id}-${oday}`;
      const destinos = destinosPara(usuarios, l.from_user);
      for (const phone of destinos) {
        if (!(await yaNotificado('letters', key, phone))) {
          const nombre = l.sender?.name || 'Alguien';
          encolar(phone, `💌 *${nombre}* tu carta "${l.title}" acaba de abrirse. Andá a leerla 🥹`);
          await marcarNotificado('letters', key, 'apertura', phone, l.title);
        }
      }
    }
  }

  // ── 5. CHALLENGES (retos) ──
  const { data: challenges } = await supabase
    .from('challenges')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (challenges) {
    for (const c of challenges) {
      const key = `challenge-${c.id}`;
      const destinos = destinosPara(usuarios, c.couple_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('challenges', key, phone))) {
          const tipo = c.completed ? 'completado' : c.started ? 'iniciado' : 'creado';
          encolar(phone, `🚩 Reto *${tipo}*: "${c.title}"`);
          await marcarNotificado('challenges', key, tipo, phone, c.title);
        }
      }
    }
  }

  // ── 6. GOALS (metas) ──
  const { data: goals } = await supabase
    .from('goals')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (goals) {
    for (const g of goals) {
      const key = `goal-${g.id}`;
      const destinos = destinosPara(usuarios, g.couple_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('goals', key, phone))) {
          const tipo = g.completed ? 'completada' : 'creada';
          encolar(phone, `🏅 Meta *${tipo}*: "${g.title}"`);
          await marcarNotificado('goals', key, tipo, phone, g.title);
        }
      }
    }
  }

  // ── 7. TASKS (tareas) ──
  const { data: tasks } = await supabase
    .from('tasks')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (tasks) {
    for (const t of tasks) {
      const key = `task-${t.id}`;
      const destinos = destinosPara(usuarios, t.created_by);
      for (const phone of destinos) {
        if (!(await yaNotificado('tasks', key, phone))) {
          encolar(phone, `✅ Nueva tarea: "${t.title}"${t.due_date ? ' | Vence: ' + t.due_date : ''}`);
          await marcarNotificado('tasks', key, 'nueva', phone, t.title);
        }
      }
    }
  }

  // ── 8. TRANSACTIONS (finanzas) ──
  const { data: transactions } = await supabase
    .from('transactions')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (transactions) {
    for (const t of transactions) {
      const key = `transaction-${t.id}`;
      const destinos = destinosPara(usuarios, t.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('transactions', key, phone))) {
          const tipo = t.type === 'income' ? '💰 Ingreso' : '💸 Gasto';
          encolar(phone, `${tipo}: $${t.amount} en *${t.category}*${t.description ? ' - ' + t.description : ''}`);
          await marcarNotificado('transactions', key, t.type, phone, t.description || t.category);
        }
      }
    }
  }

  // ── 9. FAVORITES ──
  const { data: favorites } = await supabase
    .from('favorites')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (favorites) {
    for (const f of favorites) {
      const key = `favorite-${f.id}`;
      const destinos = destinosPara(usuarios, f.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('favorites', key, phone))) {
          encolar(phone, `⭐ Nuevo favorito: "${f.title}" (${f.category})`);
          await marcarNotificado('favorites', key, 'nuevo', phone, f.title);
        }
      }
    }
  }

  // ── 10. NOTES ──
  const { data: notes } = await supabase
    .from('notes')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (notes) {
    for (const n of notes) {
      const key = `note-${n.id}`;
      const destinos = destinosPara(usuarios, n.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('notes', key, phone))) {
          const preview = n.content.length > 80 ? n.content.slice(0, 80) + '...' : n.content;
          encolar(phone, `📝 Nueva nota: "${preview}"`);
          await marcarNotificado('notes', key, 'nueva', phone, preview);
        }
      }
    }
  }

  // ── 11. GALLERY (fotos) ──
  const { data: gallery } = await supabase
    .from('gallery')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (gallery) {
    for (const g of gallery) {
      const key = `gallery-${g.id}`;
      const destinos = destinosPara(usuarios, g.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('gallery', key, phone))) {
          encolar(phone, `🖼️ Nueva foto${g.label ? ': "' + g.label + '"' : ''} en ${g.album || 'galeria'}`);
          await marcarNotificado('gallery', key, 'nueva', phone, g.label || 'foto');
        }
      }
    }
  }

  // ── 12. TIMELINE EVENTS ──
  const { data: timeline } = await supabase
    .from('timeline_events')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (timeline) {
    for (const e of timeline) {
      const key = `timeline-${e.id}`;
      const destinos = destinosPara(usuarios, e.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('timeline_events', key, phone))) {
          encolar(phone, `${e.emoji || '🕐'} ${e.content || 'Nuevo evento en la linea de tiempo'}`);
          await marcarNotificado('timeline_events', key, 'nuevo', phone, e.content);
        }
      }
    }
  }

  // ── 13. CUSTOM_QUESTIONS (preguntas del boton ❓ de Nosotros) ──
  const { data: preguntas } = await supabase
    .from('custom_questions')
    .select('*, sender:profiles!from_user(name)')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (preguntas) {
    for (const q of preguntas) {
      const key = `question-${q.id}`;
      const destinos = destinosPara(usuarios, q.from_user);
      for (const phone of destinos) {
        if (!(await yaNotificado('custom_questions', key, phone))) {
          const nombre = q.sender?.name || 'Alguien';
          const conRespuesta = q.answer != null && q.answer !== '';
          encolar(phone,
            conRespuesta
              ? `❓ *${nombre}* respondio una pregunta`
              : `❓ *${nombre}* te hizo una pregunta nueva`);
          await marcarNotificado('custom_questions', key, conRespuesta ? 'respondida' : 'nueva', phone, q.question);
        }
      }
    }
  }

  // ── 14. DECK CARDS (tarjetas nuevas del mazo) ──
  const { data: deckCards } = await supabase
    .from('deck_cards')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  const deckCategorias = {
    ideas: '💡 Ideas', chistes: '😂 Chistes', poemas: '📜 Poemas',
    recetas: '🍳 Recetas', retos: '🚩 Retos', random: '🎲 Random',
    sueno: '🌙 Sueno', me_paso: '🤯 Me paso',
  };

  if (deckCards) {
    for (const c of deckCards) {
      const key = `deck-${c.id}`;
      const destinos = destinosPara(usuarios, c.created_by);
      for (const phone of destinos) {
        if (!(await yaNotificado('deck_cards', key, phone))) {
          const cat = deckCategorias[c.category] || `🃏 ${c.category}`;
          const preview = (c.content || '').slice(0, 90);
          encolar(phone,
            `🃏 *Nueva tarjeta en el mazo* (${cat})\n` +
            `"${preview}${c.content && c.content.length > 90 ? '...' : ''}"`);
          await marcarNotificado('deck_cards', key, 'nueva', phone, c.content);
        }
      }
    }
  }

  // ── 15. DECK MATCH (ambos dieron me encanta a la misma tarjeta) ──
  const { data: deckMatches } = await supabase
    .from('deck_cards')
    .select('*')
    .gte('updated_at', desde);

  if (deckMatches) {
    const destinos = [FACU_NUMERO, ROCIO_NUMERO].filter(Boolean);
    for (const c of deckMatches) {
      const reacciones = (c.reactions && typeof c.reactions === 'object')
        ? Object.values(c.reactions) : [];
      const esMatch = reacciones.length >= 2 &&
        reacciones.every(r => r === 'encanta');
      if (!esMatch) continue;
      const key = `deckmatch-${c.id}`;
      for (const phone of destinos) {
        if (!(await yaNotificado('deck_cards', key, phone))) {
          const preview = (c.content || '').slice(0, 90);
          encolar(phone,
            `🃏 *FURI!!* Ambos dieron me encanta a la misma tarjeta:\n` +
            `"${preview}${c.content && c.content.length > 90 ? '...' : ''}"`);
          await marcarNotificado('deck_cards', key, 'match', phone, c.content);
        }
      }
    }
  }

  // ── 16. WORKOUT LOGS (ejercicios nuevos) ──
  const { data: workoutLogs } = await supabase
    .from('workout_logs')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (workoutLogs) {
    for (const l of workoutLogs) {
      const key = `exercise-${l.id}`;
      const destinos = destinosPara(usuarios, l.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('workout_logs', key, phone))) {
          const detalle = [
            l.series && l.reps ? `${l.series}x${l.reps}` : null,
            l.weight ? `${l.weight}kg` : null,
          ].filter(Boolean).join(' ');
          encolar(phone,
            `💪 *Nuevo ejercicio:* ${l.exercise_name}${detalle ? ' (' + detalle + ')' : ''}`);
          await marcarNotificado('workout_logs', key, 'nuevo', phone, l.exercise_name);
        }
      }
    }
  }

  // ── 17. WORKOUT COMPLETIONS (sesion del dia completada) ──
  const { data: workoutCompletions } = await supabase
    .from('workout_completions')
    .select('*')
    .gte('created_at', desde)
    .order('created_at', { ascending: false });

  if (workoutCompletions) {
    for (const c of workoutCompletions) {
      const key = `wcompletion-${c.id}`;
      const destinos = destinosPara(usuarios, c.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('workout_completions', key, phone))) {
          const dia = String(c.completed_on || '').slice(0, 10);
          encolar(phone,
            `🏋️ *Sesion de entrenamiento completada*${dia ? ' (' + dia + ')' : ''}`);
          await marcarNotificado('workout_completions', key, 'completada', phone, dia || hoy);
        }
      }
    }
  }

  // ── 18. WORKOUT CHALLENGES (retos de ejercicio) ──
  const { data: workoutChallenges } = await supabase
    .from('workout_challenges')
    .select('*')
    .gte('updated_at', desde)
    .order('updated_at', { ascending: false });

  if (workoutChallenges) {
    for (const c of workoutChallenges) {
      const aprobados = Array.isArray(c.approved_by) ? c.approved_by.length : 0;
      const completados = Array.isArray(c.completed_by) ? c.completed_by.length : 0;
      const tipo = completados >= 2 ? 'completado' : aprobados >= 2 ? 'aprobado' : 'creado';
      const key = `wchallenge-${c.id}-${tipo}`;
      const destinos = destinosPara(usuarios, c.created_by);
      for (const phone of destinos) {
        if (!(await yaNotificado('workout_challenges', key, phone))) {
          encolar(phone,
            `🏆 Reto de ejercicio *${tipo}*: "${c.title}"`);
          await marcarNotificado('workout_challenges', key, tipo, phone, c.title);
        }
      }
    }
  }

  // ── 19. RACHA ROTA (streak >= 3 dias y no entreno hoy ni ayer) ──
  const ayerStr = fechaLocal(new Date(ahora.getTime() - 24 * 60 * 60 * 1000));
  // Solo interesan las sesiones de los ultimos 120 dias: cualquier racha >= 3 que
  // se haya cortado hace mas tiempo ya fue notificada. Evita traer todo el
  // historial por usuario (el limite de respuesta de Supabase es 1000 filas).
  const hace120Dias = fechaLocal(new Date(ahora.getTime() - 120 * 24 * 60 * 60 * 1000));
  for (const [nombre, uuid] of Object.entries(usuarios)) {
    if (!uuid) continue;
    const { data: userCompletions, error: completErr } = await supabase
      .from('workout_completions')
      .select('completed_on')
      .eq('user_id', uuid)
      .gte('completed_on', hace120Dias)
      .lte('completed_on', hoy)
      .order('completed_on', { ascending: false });
    if (completErr) console.error(`Error cargando workout_completions de ${nombre}:`, completErr.message);

    const fechas = [...new Set((userCompletions || [])
      .map(c => String(c.completed_on).slice(0, 10)))];
    if (fechas.length === 0) continue;
    if (fechas.includes(hoy) || fechas.includes(ayerStr)) continue;

    const streak = diasConsecutivos(fechas);
    if (streak < 3) continue;

    const key = `streak-${uuid}-${hoy}`;
    const destinos = destinosPara(usuarios, uuid);
    for (const phone of destinos) {
      if (!(await yaNotificado('workout_completions', key, phone))) {
        const nombreLindo = nombre === 'facu' ? 'Facu' : 'Rocio';
        encolar(phone,
          `🔥 *La racha de entrenamiento de ${nombreLindo} se corto* (${streak} dias seguidos)`);
        await marcarNotificado('workout_completions', key, 'racha_rota', phone, nombre);
      }
    }
  }

  // ── 21. LOGRO DE PAREJA desbloqueado (a ambos) ──
  const { data: logros } = await supabase
    .from('couple_achievements')
    .select('*')
    .gte('awarded_at', desde)
    .order('awarded_at', { ascending: false });

  if (logros) {
    for (const lg of logros) {
      const key = `logro-${lg.achievement_code || lg.id}`;
      // Logros de pareja: los ve la pareja entera.
      for (const phone of [FACU_NUMERO, ROCIO_NUMERO].filter(Boolean)) {
        if (!(await yaNotificado('couple_achievements', key, phone))) {
          const codigo = lg.achievement_code || '';
          const emojiYDesc = descripcionLogro(codigo) || '';
          encolar(phone, `🏅 *Nuevo logro de pareja!* ${emojiYDesc}`);
          await marcarNotificado('couple_achievements', key, 'logro', phone, codigo);
        }
      }
    }
  }

  // ── 22. TRIVIA: ambos respondieron hoy (resultado del día) ──
  const { data: respuestas } = await supabase
    .from('question_answers')
    .select('user_id, guess, answer')
    .eq('date', hoy);

  const respondieron = new Set((respuestas || []).map(r => r.user_id));
  const ids = usuarios;
  const ambos = Object.entries(ids).filter(([n, uuid]) => uuid && respondieron.has(uuid)).length >= 2;
  if (ambos) {
    const key = `trivia-${hoy}`;
    for (const phone of [FACU_NUMERO, ROCIO_NUMERO].filter(Boolean)) {
      if (!(await yaNotificado('question_answers', key, phone))) {
        encolar(phone, `🎯 *Trivia de pareja lista!* Los dos respondieron. ¿Quién conoce más a quién? Mirá el marcador en la app`);
        await marcarNotificado('question_answers', key, 'ambos', phone, hoy);
      }
    }
  }

  // ── ENVIAR ──
  const numerosConMensajes = Object.keys(mensajesPorNum).filter(n => mensajesPorNum[n].length > 0);
  if (numerosConMensajes.length === 0) {
    console.log('Sin novedades para notificar.');
    return;
  }

  const header = `*F.U.R.I. - Novedades*\n${fechaLocal()} ${new Intl.DateTimeFormat('en-US', { timeZone: APP_TZ, hour12: false, hour: '2-digit', minute: '2-digit' }).format(ahora)}\n━━━━━━━━━━━━━━━\n`;

  for (const num of numerosConMensajes) {
    const texto = header + mensajesPorNum[num].join('\n\n');
    const ok = await enviarMensaje(sock, num, texto);
    if (ok) {
      // Solo marcamos como notificados los pendientes de este numero cuando el
      // mensaje se confirmo. Si fallo, quedan sin marcar y se reintentaran.
      await flushMarksPendientes(num);
    }
  }
  console.log(`Se enviaron notificaciones a ${numerosConMensajes.length} destinatarios.`);
}

// ─── MAIN ──────────────────────────────────────────────────────
async function main() {
  console.log('Bot F.U.R.I. iniciando...');
  cargarLidsCache();
  await loadSessionFromSupabase();

  // Si falta algun LID, resolverlos en una conexion descartable (onWhatsApp
  // puede romper el stream; la conexion principal solo usa el cache).
  const faltan = [FACU_NUMERO, ROCIO_NUMERO].filter(n => n && !lidCache[n]);
  if (faltan.length > 0) {
    console.log(`Faltan LIDs para: ${faltan.join(', ')}. Conexion descartable para resolverlos...`);
    await resolverLidsSolo();
  }

  await conectarYNotificar();
  console.log('Bot finalizado.');
  process.exit(0);
}

// timeout global duro: fuerza la salida aunque algo cuelgue (CI nunca colgado)
setTimeout(() => {
  console.error(`Falla: el bot superó el timeout global de ${TIMEOUT_GLOBAL_MS / 1000}s. Abortando.`);
  try { process.exit(1); } catch (e) { /* noop */ }
}, TIMEOUT_GLOBAL_MS).unref();

main().catch(err => {
  console.error('Error fatal:', err);
  process.exit(1);
});
