import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ─── SECRETOS (Equipo 1 - 2026-09-01) ────────────────────────────────────────
// El service account de Firebase (clave privada) ya NO vive hardcodeado en el
// código. Se lee de la variable de entorno FIREBASE_SERVICE_ACCOUNT (un JSON
// completo) seteada con:
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT='{...json del service account}'
// Campos requeridos: client_email, private_key, token_uri, project_id.
// SUPABASE_URL y SUPABASE_ANON_KEY se leen del entorno de la Edge Function.
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || ''

interface ServiceAccount {
  client_email: string
  private_key: string
  token_uri: string
  project_id: string
}

let serviceAccount: ServiceAccount | null = null
if (FIREBASE_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT) as ServiceAccount
  } catch (e) {
    console.error('FIREBASE_SERVICE_ACCOUNT no es un JSON válido:', e)
    serviceAccount = null
  }
}

const FCM_V1_URL = serviceAccount?.project_id
  ? `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`
  : ''

function base64url(buf: ArrayBuffer): string {
  const str = btoa(String.fromCharCode(...new Uint8Array(buf)))
  return str.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function textEncode(s: string): Uint8Array {
  return new TextEncoder().encode(s)
}

async function signJWT(header: object, payload: object, pemKey: string): Promise<string> {
  const pemContents = pemKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\n/g, '')

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0))

  const key = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const headerB64 = base64url(textEncode(JSON.stringify(header)))
  const payloadB64 = base64url(textEncode(JSON.stringify(payload)))
  const toSign = `${headerB64}.${payloadB64}`

  const sig = await crypto.subtle.sign(
    { name: 'RSASSA-PKCS1-v1_5' },
    key,
    textEncode(toSign),
  )

  return `${toSign}.${base64url(sig)}`
}

let cachedToken: { token: string; expires: number } | null = null

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  if (cachedToken && cachedToken.expires > now + 60) {
    return cachedToken.token
  }

  const jwt = await signJWT(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: serviceAccount!.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: serviceAccount!.token_uri,
      exp: now + 3600,
      iat: now,
    },
    serviceAccount!.private_key,
  )

  const res = await fetch(serviceAccount!.token_uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const data = await res.json()
  cachedToken = { token: data.access_token, expires: now + (data.expires_in ?? 3600) }
  return cachedToken!.token
}

serve(async (req) => {
  if (!serviceAccount) {
    return new Response('Firebase service account not configured (FIREBASE_SERVICE_ACCOUNT env missing)', { status: 500 })
  }

  const authHeader = req.headers.get('Authorization')?.replace('Bearer ', '')
  if (!authHeader) return new Response('Unauthorized', { status: 401 })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
  )

  let body: any
  try { body = await req.json() } catch { return new Response('Invalid JSON', { status: 400 }) }

  const { user_id, title, body: msgBody, data } = body
  if (!user_id || !title) return new Response('Missing fields', { status: 400 })

  const { data: tokens, error } = await supabase
    .from('device_tokens')
    .select('token, platform')
    .eq('user_id', user_id)
    .gte('created_at', new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString())

  if (error || !tokens || tokens.length === 0) {
    console.log('No tokens for user:', user_id)
    return new Response('No tokens', { status: 200 })
  }

  let accessToken: string
  try { accessToken = await getAccessToken() }
  catch (e) {
    console.error('Auth error:', e)
    return new Response('Auth failed', { status: 500 })
  }

  const results = []
  for (const t of tokens) {
    try {
      const res = await fetch(FCM_V1_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: t.token,
            notification: { title, body: msgBody ?? title },
            data: Object.fromEntries(
              Object.entries(data ?? {}).map(([k, v]) => [k, String(v)])
            ),
            android: {
              priority: 'high',
              notification: {
                channel_id: 'furi_notifications',
                sound: 'default',
              },
            },
          },
        }),
      })

      const result = await res.json()
      results.push({ ok: res.ok, status: res.status, response: result })

      // Poda automatica: FCM devuelve UNREGISTERED (404) para tokens de
      // instalaciones desinstaladas o regenerados. Si los dejamos, cada push
      // intenta enviar a tokens muertos para siempre. Los eliminamos.
      const errorCode = result?.error?.details?.[0]?.errorCode
        ?? result?.error?.status
      if (!res.ok && (errorCode === 'UNREGISTERED' || result?.error?.status === 'NOT_FOUND')) {
        const del = await supabase
          .from('device_tokens')
          .delete()
          .eq('token', t.token)
          .eq('user_id', user_id)
        if (del.error) console.error('Error podando token:', del.error.message)
        else console.log('Token podado (UNREGISTERED):', t.token.slice(0, 12) + '...')
      }
    } catch (e) {
      results.push({ error: String(e) })
    }
  }

  return new Response(JSON.stringify({ sent: results.length, results }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
