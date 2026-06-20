// Cloudflare Worker — Riz proxy. Injects the Ollama Cloud key and forwards chat requests.
// The iOS app posts the full Ollama /api/chat body; this only adds the Authorization header.
//   1) npm i -g wrangler   2) wrangler secret put OLLAMA_API_KEY   3) wrangler deploy
// Then set RizConfig.endpoint in the app to this Worker's URL (leave RizConfig.apiKey empty).
export default {
  async fetch(req, env) {
    if (req.method === 'OPTIONS') return cors(new Response(null, { status: 204 }))
    if (req.method !== 'POST') return cors(new Response('POST only', { status: 405 }))
    const upstream = await fetch('https://ollama.com/api/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${env.OLLAMA_API_KEY}` },
      body: await req.text(),
    })
    return cors(new Response(upstream.body, { status: upstream.status, headers: { 'Content-Type': 'application/json' } }))
  },
}
function cors(res) {
  res.headers.set('Access-Control-Allow-Origin', '*')
  res.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
  res.headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS')
  return res
}
