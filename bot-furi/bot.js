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

  const sesionCoincide = Object.keys(session).some(f => f.includes(MI_NUMERO || ''));
  if (!sesionCoincide) {
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
function conectarYNotificar() {
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
          console.log('Conexion cerrada, reintentando...');
          setTimeout(async () => {
            try {
              await conectarYNotificar();
              resolve();
            } catch (e) {
              console.error('Error en reintento:', e.message);
              resolve();
            }
          }, 3000);
        }
      }
    });

    sock.ev.on('creds.update', async () => {
      await saveCreds();
      await saveSessionToSupabase();
    });

    setTimeout(() => {
      if (!resuelto) {
        console.log('Timeout: no se pudo conectar en 60s. Si es CI, la sesion puede estar vencida.');
        resuelto = true;
        resolve();
      }
    }, 60000);
  });
}

// ─── UTIL: ENVIAR MENSAJE ─────────────────────────────────────
async function enviarMensaje(sock, phone, mensaje) {
  const jid = phone.includes('@s.whatsapp.net') ? phone : `${phone}@s.whatsapp.net`;
  try {
    await sock.sendMessage(jid, { text: mensaje });
    console.log(`Mensaje enviado a ${phone}`);
    return true;
  } catch (e) {
    console.error(`Error enviando a ${phone}:`, e.message);
    return false;
  }
}

// ─── UTIL: YA FUE NOTIFICADO? ─────────────────────────────────
async function yaNotificado(tabla, registroId) {
  const { data } = await supabase
    .from(NOTIF_TABLE)
    .select('id')
    .eq('tabla', tabla)
    .eq('registro_id', String(registroId))
    .limit(1);

  return data && data.length > 0;
}

// ─── UTIL: MARCAR COMO NOTIFICADO ─────────────────────────────
async function marcarNotificado(tabla, registroId, tipo, phone, mensaje) {
  await supabase.from(NOTIF_TABLE).insert({
    tabla,
    registro_id: String(registroId),
    tipo,
    phone,
    mensaje,
  });
}

// ─── FORMATO DE HORA ──────────────────────────────────────────
function formatHora(hora) {
  if (!hora) return '';
  return hora.slice(0, 5);
}

// ─── VERIFICAR EVENTOS ────────────────────────────────────────
async function verificarYNotificar(sock) {
  console.log('Verificando eventos...');
  const mensajes = [];

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
        if (!(await yaNotificado('schedules', key))) {
          const minutos = Math.round((inicio - ahora) / 60000);
          mensajes.push(
            `📅 *${s.title}*\n` +
            `⏰ ${formatHora(s.startTime)} - ${formatHora(s.endTime)}\n` +
            `📍 ${s.location || 'Sin ubicacion'}\n` +
            `⏳ En ${minutos} minutos`
          );
          await marcarNotificado('schedules', key, 'proximo', MI_NUMERO, s.title);
        }
      }
    }
  }

  // ── 2. ANNIVERSARIES ──
  const { data: anniversaries } = await supabase
    .from('anniversaries')
    .select('*');

  if (anniversaries) {
    for (const a of anniversaries) {
      const fecha = new Date(a.date).toISOString().slice(0, 10);
      if (fecha === hoy) {
        const key = `anniversary-${a.id}-${hoy}`;
        const ahoraHora = ahora.getHours();
        if (ahoraHora >= 8 && ahoraHora <= 10 && !(await yaNotificado('anniversaries', key))) {
          mensajes.push(`🎉 *Hoy es ${a.title}!*`);
          await marcarNotificado('anniversaries', key, 'hoy', MI_NUMERO, a.title);
        }
      } else if (fecha === manana) {
        const key = `anniversary-${a.id}-${manana}-aviso`;
        if (!(await yaNotificado('anniversaries', key))) {
          mensajes.push(`📢 *Recordatorio: manana es ${a.title}*`);
          await marcarNotificado('anniversaries', key, 'manana', MI_NUMERO, a.title);
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
      if (!(await yaNotificado('moods', key))) {
        const nombre = m.profiles?.name || 'Alguien';
        mensajes.push(`😊 *${nombre}* registro una emocion: ${m.mood}${m.note ? ' - ' + m.note : ''}`);
        await marcarNotificado('moods', key, 'nueva', MI_NUMERO, m.mood);
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
      if (!(await yaNotificado('letters', key))) {
        const nombre = l.from_user?.name || 'Alguien';
        mensajes.push(`💌 *${nombre}* te envio una carta: "${l.title}"`);
        await marcarNotificado('letters', key, 'nueva', MI_NUMERO, l.title);
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
      if (!(await yaNotificado('challenges', key))) {
        const tipo = c.completed ? 'completado' : c.started ? 'iniciado' : 'creado';
        mensajes.push(`🚩 Reto *${tipo}*: "${c.title}"`);
        await marcarNotificado('challenges', key, tipo, MI_NUMERO, c.title);
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
      if (!(await yaNotificado('goals', key))) {
        const tipo = g.completed ? 'completada' : 'creada';
        mensajes.push(`🏅 Meta *${tipo}*: "${g.title}"`);
        await marcarNotificado('goals', key, tipo, MI_NUMERO, g.title);
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
      if (!(await yaNotificado('tasks', key))) {
        mensajes.push(`✅ Nueva tarea: "${t.title}"${t.due_date ? ' | Vence: ' + t.due_date : ''}`);
        await marcarNotificado('tasks', key, 'nueva', MI_NUMERO, t.title);
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
      if (!(await yaNotificado('transactions', key))) {
        const tipo = t.type === 'income' ? '💰 Ingreso' : '💸 Gasto';
        mensajes.push(`${tipo}: $${t.amount} en *${t.category}*${t.description ? ' - ' + t.description : ''}`);
        await marcarNotificado('transactions', key, t.type, MI_NUMERO, t.description || t.category);
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
      if (!(await yaNotificado('favorites', key))) {
        mensajes.push(`⭐ Nuevo favorito: "${f.title}" (${f.category})`);
        await marcarNotificado('favorites', key, 'nuevo', MI_NUMERO, f.title);
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
      if (!(await yaNotificado('notes', key))) {
        const preview = n.content.length > 80 ? n.content.slice(0, 80) + '...' : n.content;
        mensajes.push(`📝 Nueva nota: "${preview}"`);
        await marcarNotificado('notes', key, 'nueva', MI_NUMERO, preview);
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
      if (!(await yaNotificado('gallery', key))) {
        mensajes.push(`🖼️ Nueva foto${g.label ? ': "' + g.label + '"' : ''} en ${g.album || 'galeria'}`);
        await marcarNotificado('gallery', key, 'nueva', MI_NUMERO, g.label || 'foto');
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
      if (!(await yaNotificado('timeline_events', key))) {
        mensajes.push(`${e.emoji || '🕐'} ${e.content || 'Nuevo evento en la linea de tiempo'}`);
        await marcarNotificado('timeline_events', key, 'nuevo', MI_NUMERO, e.content);
      }
    }
  }

  // ── ENVIAR ──
  if (mensajes.length === 0) {
    console.log('Sin novedades para notificar.');
    return;
  }

  const header = `*F.U.R.I. - Novedades*\n${new Date().toLocaleString('es-AR')}\n━━━━━━━━━━━━━━━\n`;
  const texto = header + mensajes.join('\n\n');

  const destinatarios = [FACU_NUMERO, ROCIO_NUMERO].filter(Boolean);
  for (const num of destinatarios) {
    await enviarMensaje(sock, num, texto);
  }
  console.log(`Se enviaron ${mensajes.length} notificaciones a ${destinatarios.length} destinatarios.`);
}

// ─── MAIN ──────────────────────────────────────────────────────
async function main() {
  console.log('Bot F.U.R.I. iniciando...');
  await loadSessionFromSupabase();
  await conectarYNotificar();
  console.log('Bot finalizado.');
  process.exit(0);
}

main().catch(err => {
  console.error('Error fatal:', err);
  process.exit(1);
});
