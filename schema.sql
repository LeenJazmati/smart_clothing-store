-- Supabase setup for the AI Headless Store.
-- Reconstructed from the fields the n8n workflow reads and writes; adjust types if your table differs.

create table if not exists public.products (
  id                    bigint generated always as identity primary key,
  name                  text        not null,
  price                 numeric     not null,
  simple_description    text,
  marketing_description text,
  category              text,
  audience              text,
  status                text        not null default 'available',  -- 'available' | 'unavailable'
  image_url             text,
  created_at            timestamptz not null default now()
);

-- Public bucket for product images (the workflow uploads to product-images/<timestamp>.jpg).
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- n8n connects with the Supabase service role key, which bypasses RLS.
-- Keep RLS enabled and do not expose the service role key to the browser.
alter table public.products enable row level security;
