# AI-Driven Headless Store

A headless online clothing store (jeans, sweaters, pajamas for men, women and kids) where **n8n is the backend** and AI does the heavy lifting:

- An admin adds a product with just a name, price, short description and photo. AI writes the marketing copy and picks the category and audience.
- Customers chat with an AI shopping assistant that recommends products within their budget, using live store data.

The storefront and admin dashboard are a single static `index.html` that talks to n8n through webhooks. Arabic, right-to-left UI.

## Features

- **Storefront** with category filters and availability badges
- **Admin dashboard**: add product, toggle availability, delete product
- **AI product pipeline**: image resize (800 px, JPEG) → upload to Supabase Storage → GPT-4o-mini generates an Arabic marketing description, category and audience as JSON → row saved
- **AI shopping assistant** (GPT-4.1-mini agent): always queries available products before answering, recommends 1–3 matches within budget, never invents prices or stock, remembers session context (last 10 messages)
- **Demo mode**: with `N8N_BASE` left empty the page runs fully in the browser with sample data

## Architecture

```
index.html (storefront + admin + chat widget)
      │  HTTPS / webhooks
      ▼
n8n ── GET  /products        → Supabase: get all rows ───────────────→ { products: [...] }
    ├─ POST /add-product     → Edit Image → Supabase Storage upload
    │                          → LLM: description + category + audience
    │                          → Supabase: insert row ───────────────→ new row
    ├─ POST /update-status   → Supabase: update status ─────────────→ { ok: true }
    ├─ POST /delete-product  → Supabase: delete row ────────────────→ { ok: true }
    └─ POST /chat            → AI Agent (OpenAI + memory)
                               └─ tool: Supabase products (status = available) → { reply }
```

## Webhook contract

| Endpoint | Method | Body | Response |
|---|---|---|---|
| `/products` | GET | none | `{ "products": [ ... ] }` |
| `/add-product` | POST (multipart) | `name`, `price`, `description`, `image` (file) | created product row |
| `/update-status` | POST (JSON) | `{ "id", "status": "available" \| "unavailable" }` | `{ "ok": true }` |
| `/delete-product` | POST (JSON) | `{ "id" }` | `{ "ok": true }` |
| `/chat` | POST (JSON) | `{ "message", "session_id" }` | `{ "reply": "..." }` |

## Requirements

- n8n (self-hosted or cloud)
- Supabase project (database + storage)
- OpenAI API key
- A public URL for n8n (ngrok, a VPS, or n8n cloud) if the frontend is not served from the same machine

## Setup

1. **Supabase**: run `schema.sql` in the SQL editor. This creates the `products` table and a public `product-images` bucket.
2. **n8n**: go to **Workflows → Import from file**, choose `workflow.json`, then:
   - attach your **OpenAI** and **Supabase** credentials to the nodes that use them (Supabase: use the project URL and service role key)
   - replace `YOUR_PROJECT_REF` with your Supabase project reference in two nodes: `HTTP Request` (upload URL) and `Create a row` (image URL)
   - activate the workflow
3. **Frontend**: open `index.html` and set `N8N_BASE` to your n8n production webhook base, for example `https://your-n8n.example.com/webhook`.
4. Serve the page locally (recommended over opening the file directly):

   ```bash
   python -m http.server 8000
   # then open http://localhost:8000
   ```

   Admin dashboard: `http://localhost:8000/#/admin`

## Notes and security

- The webhooks use `allowedOrigins: *` and have no authentication. Anyone who knows the URLs can add, change or delete products. Before any real deployment, restrict the allowed origin and add a shared secret header (checked in n8n) or put the admin endpoints behind authentication.
- Never put the Supabase service role key in the frontend. It belongs only in the n8n credential.
- The product table must contain `id` and `created_at`; the storefront sorts newest first.

## Author

Leen Jazmati
