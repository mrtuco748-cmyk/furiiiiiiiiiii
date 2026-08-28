import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const FCM_V1_URL = 'https://fcm.googleapis.com/v1/projects/furi-7cf63/messages:send'

const SERVICE_ACCOUNT = {
  client_email: 'firebase-adminsdk-fbsvc@furi-7cf63.iam.gserviceaccount.com',
  private_key: `-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC3Xy8+qsH8P8rq
6EAW5EQq9VjIHImIMI1pmWi9K8uf+CB/P+8RbnbsNlxdUHU7ghDiAScJ5y/0Fmje
/tSJE90RDWclz3ffOV9L76XVP/b1bwS3Z4D0qLWCjgxSXJgTu70EDe7ec90OPMCI
/r+78FaLdWew5L3gNk4kgIxvLMAfz75aUp/u+P03ggvLWjDgkFuSBuCZ37Y54lNL
T+zOZ8mMj+YimjAZ4THZuRgZCYjS1NQD2X1/V/89hb6twUVn1RUgRsz0Jwxsi1RH
UpHDm8dCbPZLCev5pK7aVDU4eZy74mVfIPYvrVoopJHvqe63CDhkBGj7UoSGc2uJ
4Iy3yNA1AgMBAAECggEAJKexzYCb0107JlbzzL+ngsDVlPbjZSZzdir03W++PgV/
FYDFvMHMou5A62RUcudOkabyU0/z7YJ3RzBAcwBV/f0kY9IDn8sbqhXHHAgzyR7+
ndziUcXRtr3HZ8VbnwI1x/QzDiOyChEJ2bi2wg5KdokrB5jJ/eJNH43UxLp400LA
oB9YUixDDIG2qAaZAlno0AQxzQdT0UW3rYjMRQDxtv11C42aLE2WMR7G0Jkl4oMk
8p2iUicbkpVmKco3fOmYieYBoMaavl4Gxae9gDvaNxQdrzr1pDKN3kL/He+hF6en
04DWM6r2Ogal1YeQDwhW+dqYjFc9BiBQN9mVv/l7kQKBgQDeDCbgP/3zA/h+2z/h
0GVwxDKi1KpfO0ZADFjmQC13ht/Q6/siYh90vZr6OlEDiTDGp5IxyacESCSWMMKV
mJyf1eEznbT1rcuUFdDEy1duJiR5oQ3a3IaEcc1YAkaEm2OkFUd57zKs2DruIUGh
IFfUd7kHSWPMCPhRoyZ0FdYFOQKBgQDTaRvr5S03qKSQKFPlbJlrcgixjD4+beV2
mTT0o+AVnxzMw5bDgIS2JiwXBfNXEcqZGsPQUhxOYFbL5e8E3rSQxoWd5SGZHXNK
/cL3t32a27tiYlB3zMUsbzZqSn+E/FHH/27uyHGmqRpfohmFVoH/zzm334bBD8eP
L0ISbVa+3QKBgCKzf3fYSFWsLy+UEB24NcIzxz4PQjjzyHzF8Ta6nOBrIZtC5dJv
xz61Sv0EFBkbXZYOJhjFzOYsaBtYr3A1k3SfNjyczuT+LiyMZD39EULTjyu68bFc
eWFFb7PrVx3uMto3wR3bNe4xNLR2Wg1WQqOfujjbTU9br4MCnkXSC8pxAoGAF6lQ
9bL9v5gBax0IXsor1am6rVx77vLP1tlI4wSgZOsdBxHxAsqUj+pvztfcp2cXXNFx
DxTRlDgWHtYKTWo7nWSKueRWQVPZfpAuTRldVoK3U0ibpvzlKJb96SGTaifvY0oE
eXc3uSZ+DCwRXSoUfLQNyrWa2GrStATfCT7xkYUCgYEAmcrFJqhPNJiDKGCg/xA1
12DEdRUJ3MSfe8Mmdug1vq6hVwdhl5g2whWoe/PWjRClvxw1z1w4DgOzbs+De6d6
3LELsIfOfnR0iIysNwZppHQgmvyZDKIbqkzUOORAkvVEj3i3VL6MUQcnkAFQZmyq
3EjIYOfZWg5eWXKhIBnvz/0=
-----END PRIVATE KEY-----`,
  token_uri: 'https://oauth2.googleapis.com/token',
}

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
      iss: SERVICE_ACCOUNT.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: SERVICE_ACCOUNT.token_uri,
      exp: now + 3600,
      iat: now,
    },
    SERVICE_ACCOUNT.private_key,
  )

  const res = await fetch(SERVICE_ACCOUNT.token_uri, {
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
