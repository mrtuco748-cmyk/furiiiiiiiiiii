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
    fs.writeFileSync(path.join(AUTH_DIR, filename), JSON.stringify(content));
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
// entrega. Para no dejar mensajes "en cola" que se pierden al cerrar el socket,
// esperamos el ACK del servidor (status SERVER_ACK=1 o superior) con timeout y
// reintentamos si no se confirma.
async function enviarMensaje(sock, phone, mensaje) {
  const jid = phone.includes('@s.whatsapp.net') ? phone : `${phone}@s.whatsapp.net`;
  try {
    const res = await sock.sendMessage(jid, { text: mensaje });
    const id = res?.key?.id;

    // Esperamos confirmacion del servidor (SERVER_ACK). Usamos una ventana
    // generosa porque la sesion restaurada puede tardar en confirmar. NO
    // reintentamos el envio del mismo mensaje: enviarlo de nuevo duplica la
    // entrega (WhatsApp ya lo recibio aunque el ACK tarde).
    const confirmado = await esperarAck(sock, id, 20000);
    if (confirmado) {
      console.log(`Mensaje enviado a ${phone}`);
    } else {
      console.log(`Mensaje a ${phone} entregado a WhatsApp (sin ACK oportuno en 20s).`);
    }
    return true;
  } catch (e) {
    console.error(`Error enviando a ${phone}:`, e.message);
    return false;
  }
}

// Espera el ACK de un mensaje enviado (status >= SERVER_ACK). Resuelve true si
// WhatsApp confirma que el mensaje fue recibido por su servidor.
function esperarAck(sock, id, timeoutMs) {
  return new Promise((resolve) => {
    if (!id) return resolve(false);
    const timer = setTimeout(() => {
      sock.ev.off('messages.update', handler);
      resolve(false);
    }, timeoutMs);
    const handler = (updates) => {
      for (const u of updates) {
        if (u.key?.id === id && (u.status === 1 || u.status === 2 || u.status === 3)) {
          clearTimeout(timer);
          sock.ev.off('messages.update', handler);
          resolve(true);
          return;
        }
      }
    };
    sock.ev.on('messages.update', handler);
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

  const { data } = await query;
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
  const { data } = await supabase.from('profiles').select('id, name');
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
  if (usuarios.facu && creatorId === usuarios.facu) return [ROCIO_NUMERO].filter(Boolean);
  if (usuarios.rocio && creatorId === usuarios.rocio) return [FACU_NUMERO].filter(Boolean);
  return [FACU_NUMERO, ROCIO_NUMERO].filter(Boolean);
}

// ─── FORMATO DE HORA ──────────────────────────────────────────
function formatHora(hora) {
  if (!hora) return '';
  return hora.slice(0, 5);
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
  const haceUnaHora = new Date(ahora.getTime() - 60 * 60 * 1000).toISOString();
  const enDosHoras = new Date(ahora.getTime() + 2 * 60 * 60 * 1000);

  const hoy = ahora.toISOString().slice(0, 10);
  const manana = new Date(ahora.getTime() + 24 * 60 * 60 * 1000).toISOString().slice(0, 10);

  // ── 1. SCHEDULES (clases/eventos) ──
  const { data: schedules } = await supabase
    .from('schedules')
    .select('*')
    .eq('date', hoy)
    .order('startTime');

  if (schedules) {
    for (const s of schedules) {
      const inicio = new Date(`${s.date}T${s.startTime}`);
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
              `⏳ En ${minutos} minutos`,
              'schedules', key, 'proximo', s.title);
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
      const inicio = new Date(`${hoy}T${c.start_time}`);
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
            encolar(phone, texto, 'class_schedules', key, 'proximo', c.title);
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
      const fecha = new Date(a.date).toISOString().slice(0, 10);
      if (fecha === hoy) {
        const key = `anniversary-${a.id}-${hoy}`;
        const ahoraHora = ahora.getHours();
        if (ahoraHora >= 8 && ahoraHora <= 10) {
          for (const phone of destinos) {
            if (!(await yaNotificado('anniversaries', key, phone))) {
              encolar(phone, `🎉 *Hoy es ${a.title}!*`, 'anniversaries', key, 'hoy', a.title);
              await marcarNotificado('anniversaries', key, 'hoy', phone, a.title);
            }
          }
        }
      } else if (fecha === manana) {
        const key = `anniversary-${a.id}-${manana}-aviso`;
        for (const phone of destinos) {
          if (!(await yaNotificado('anniversaries', key, phone))) {
            encolar(phone, `📢 *Recordatorio: manana es ${a.title}*`, 'anniversaries', key, 'manana', a.title);
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
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (moods) {
    for (const m of moods) {
      const key = `mood-${m.id}`;
      const destinos = destinosPara(usuarios, m.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('moods', key, phone))) {
          const nombre = m.profiles?.name || 'Alguien';
          encolar(phone, `😊 *${nombre}* registro una emocion: ${m.mood}${m.note ? ' - ' + m.note : ''}`, 'moods', key, 'nueva', m.mood);
          await marcarNotificado('moods', key, 'nueva', phone, m.mood);
        }
      }
    }
  }

  // ── 4. LETTERS (cartas nuevas) ──
  const { data: letters } = await supabase
    .from('letters')
    .select('*, from_user:profiles!from_user(name)')
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (letters) {
    for (const l of letters) {
      const key = `letter-${l.id}`;
      const destinos = destinosPara(usuarios, l.from_user);
      for (const phone of destinos) {
        if (!(await yaNotificado('letters', key, phone))) {
          const nombre = l.from_user?.name || 'Alguien';
          encolar(phone, `💌 *${nombre}* te envio una carta: "${l.title}"`, 'letters', key, 'nueva', l.title);
          await marcarNotificado('letters', key, 'nueva', phone, l.title);
        }
      }
    }
  }

  // ── 5. CHALLENGES (retos) ──
  const { data: challenges } = await supabase
    .from('challenges')
    .select('*')
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (challenges) {
    for (const c of challenges) {
      const key = `challenge-${c.id}`;
      const destinos = destinosPara(usuarios, c.couple_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('challenges', key, phone))) {
          const tipo = c.completed ? 'completado' : c.started ? 'iniciado' : 'creado';
          encolar(phone, `🚩 Reto *${tipo}*: "${c.title}"`, 'challenges', key, tipo, c.title);
          await marcarNotificado('challenges', key, tipo, phone, c.title);
        }
      }
    }
  }

  // ── 6. GOALS (metas) ──
  const { data: goals } = await supabase
    .from('goals')
    .select('*')
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (goals) {
    for (const g of goals) {
      const key = `goal-${g.id}`;
      const destinos = destinosPara(usuarios, g.couple_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('goals', key, phone))) {
          const tipo = g.completed ? 'completada' : 'creada';
          encolar(phone, `🏅 Meta *${tipo}*: "${g.title}"`, 'goals', key, tipo, g.title);
          await marcarNotificado('goals', key, tipo, phone, g.title);
        }
      }
    }
  }

  // ── 7. TASKS (tareas) ──
  const { data: tasks } = await supabase
    .from('tasks')
    .select('*')
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (tasks) {
    for (const t of tasks) {
      const key = `task-${t.id}`;
      const destinos = destinosPara(usuarios, t.created_by);
      for (const phone of destinos) {
        if (!(await yaNotificado('tasks', key, phone))) {
          encolar(phone, `✅ Nueva tarea: "${t.title}"${t.due_date ? ' | Vence: ' + t.due_date : ''}`, 'tasks', key, 'nueva', t.title);
          await marcarNotificado('tasks', key, 'nueva', phone, t.title);
        }
      }
    }
  }

  // ── 8. TRANSACTIONS (finanzas) ──
  const { data: transactions } = await supabase
    .from('transactions')
    .select('*')
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (transactions) {
    for (const t of transactions) {
      const key = `transaction-${t.id}`;
      const destinos = destinosPara(usuarios, t.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('transactions', key, phone))) {
          const tipo = t.type === 'income' ? '💰 Ingreso' : '💸 Gasto';
          encolar(phone, `${tipo}: $${t.amount} en *${t.category}*${t.description ? ' - ' + t.description : ''}`, 'transactions', key, t.type, t.description || t.category);
          await marcarNotificado('transactions', key, t.type, phone, t.description || t.category);
        }
      }
    }
  }

  // ── 9. FAVORITES ──
  const { data: favorites } = await supabase
    .from('favorites')
    .select('*')
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (favorites) {
    for (const f of favorites) {
      const key = `favorite-${f.id}`;
      const destinos = destinosPara(usuarios, f.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('favorites', key, phone))) {
          encolar(phone, `⭐ Nuevo favorito: "${f.title}" (${f.category})`, 'favorites', key, 'nuevo', f.title);
          await marcarNotificado('favorites', key, 'nuevo', phone, f.title);
        }
      }
    }
  }

  // ── 10. NOTES ──
  const { data: notes } = await supabase
    .from('notes')
    .select('*')
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (notes) {
    for (const n of notes) {
      const key = `note-${n.id}`;
      const destinos = destinosPara(usuarios, n.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('notes', key, phone))) {
          const preview = n.content.length > 80 ? n.content.slice(0, 80) + '...' : n.content;
          encolar(phone, `📝 Nueva nota: "${preview}"`, 'notes', key, 'nueva', preview);
          await marcarNotificado('notes', key, 'nueva', phone, preview);
        }
      }
    }
  }

  // ── 11. GALLERY (fotos) ──
  const { data: gallery } = await supabase
    .from('gallery')
    .select('*')
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (gallery) {
    for (const g of gallery) {
      const key = `gallery-${g.id}`;
      const destinos = destinosPara(usuarios, g.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('gallery', key, phone))) {
          encolar(phone, `🖼️ Nueva foto${g.label ? ': "' + g.label + '"' : ''} en ${g.album || 'galeria'}`, 'gallery', key, 'nueva', g.label || 'foto');
          await marcarNotificado('gallery', key, 'nueva', phone, g.label || 'foto');
        }
      }
    }
  }

  // ── 12. TIMELINE EVENTS ──
  const { data: timeline } = await supabase
    .from('timeline_events')
    .select('*')
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (timeline) {
    for (const e of timeline) {
      const key = `timeline-${e.id}`;
      const destinos = destinosPara(usuarios, e.user_id);
      for (const phone of destinos) {
        if (!(await yaNotificado('timeline_events', key, phone))) {
          encolar(phone, `${e.emoji || '🕐'} ${e.content || 'Nuevo evento en la linea de tiempo'}`, 'timeline_events', key, 'nuevo', e.content);
          await marcarNotificado('timeline_events', key, 'nuevo', phone, e.content);
        }
      }
    }
  }

  // ── 13. CUSTOM_QUESTIONS (preguntas del boton ❓ de Nosotros) ──
  const { data: preguntas } = await supabase
    .from('custom_questions')
    .select('*, from_user:profiles!from_user(name)')
    .gte('created_at', haceUnaHora)
    .order('created_at', { ascending: false });

  if (preguntas) {
    for (const q of preguntas) {
      const key = `question-${q.id}`;
      const destinos = destinosPara(usuarios, q.from_user);
      for (const phone of destinos) {
        if (!(await yaNotificado('custom_questions', key, phone))) {
          const nombre = q.from_user?.name || 'Alguien';
          const conRespuesta = q.answer != null && q.answer !== '';
          encolar(phone,
            conRespuesta
              ? `❓ *${nombre}* respondio una pregunta`
              : `❓ *${nombre}* te hizo una pregunta nueva`,
            'custom_questions', key, conRespuesta ? 'respondida' : 'nueva', q.question);
          await marcarNotificado('custom_questions', key, conRespuesta ? 'respondida' : 'nueva', phone, q.question);
        }
      }
    }
  }

  // ── ENVIAR ──
  const numerosConMensajes = Object.keys(mensajesPorNum).filter(n => mensajesPorNum[n].length > 0);
  if (numerosConMensajes.length === 0) {
    console.log('Sin novedades para notificar.');
    return;
  }

  const header = `*F.U.R.I. - Novedades*\n${new Date().toLocaleString('es-AR')}\n━━━━━━━━━━━━━━━\n`;

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
  await loadSessionFromSupabase();
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
