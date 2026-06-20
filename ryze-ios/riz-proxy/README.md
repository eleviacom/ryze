# Riz proxy (Ollama Cloud)

Thin Cloudflare Worker that keeps the Ollama Cloud key off the device and forwards
Riz chat requests from the Ryze app.

## Deploy
```
npm i -g wrangler
cd riz-proxy
wrangler secret put OLLAMA_API_KEY   # paste your Ollama Cloud key
wrangler deploy                      # prints https://riz-proxy.<you>.workers.dev
```

## Point the app at it
In `Ryze/RizService.swift`:
```swift
static let endpoint = "https://riz-proxy.<you>.workers.dev"
static let model    = "gpt-oss:120b"   // or your chosen Ollama Cloud model
static let apiKey    = ""               // empty: the Worker injects the key
```

## Direct mode (no Worker, demo only)
```swift
static let endpoint = "https://ollama.com/api/chat"
static let apiKey   = "<your Ollama Cloud key>"   // embedded in the app — demo only
```
