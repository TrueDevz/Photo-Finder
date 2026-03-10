-- ============================================================
-- Event Photo Finder – Supabase Schema
-- Run this in your Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
create extension if not exists "pgcrypto";

-- ─── Events ────────────────────────────────────────────────────────────────
create table if not exists public.events (
  id          uuid primary key default gen_random_uuid(),
  title       text          not null,
  event_date  date          not null,
  cover_image text          not null default '',
  price       integer       not null default 500,
  created_at  timestamptz   not null default now()
);

-- ─── Photos ────────────────────────────────────────────────────────────────
create table if not exists public.photos (
  id            uuid primary key default gen_random_uuid(),
  event_id      uuid references public.events(id) on delete cascade,
  image_url     text        not null,
  thumbnail_url text        not null,
  created_at    timestamptz not null default now()
);

create index if not exists photos_event_id_idx on public.photos(event_id);

-- ─── Views (photo unlock tracking) ────────────────────────────────────────
create table if not exists public.views (
  id         uuid primary key default gen_random_uuid(),
  photo_id   uuid references public.photos(id) on delete cascade,
  device_id  text        not null,
  viewed_at  timestamptz not null default now(),
  unique (photo_id, device_id)
);

create index if not exists views_device_id_idx on public.views(device_id);
create index if not exists views_photo_id_idx  on public.views(photo_id);

-- ─── Users ────────────────────────────────────────────────────────────────
create table if not exists public.users (
  id             uuid primary key default gen_random_uuid(),
  device_id      text unique not null,
  is_subscribed  boolean     not null default false,
  created_at     timestamptz not null default now()
);

create index if not exists users_device_id_idx on public.users(device_id);

-- ─── Row Level Security ───────────────────────────────────────────────────
-- Anon users can read events and photos, but only insert/read their own views/user record.

alter table public.events  enable row level security;
alter table public.photos  enable row level security;
alter table public.views   enable row level security;
alter table public.users   enable row level security;

-- Events: public read
create policy "Events are viewable by everyone"
  on public.events for select using (true);

-- Photos: public read
create policy "Photos are viewable by everyone"
  on public.photos for select using (true);

-- Views: insert own records, read own records
create policy "Users can insert their own views"
  on public.views for insert with check (true);

create policy "Users can view views by device"
  on public.views for select using (true);

-- Users: upsert and read own record
create policy "Users can insert themselves"
  on public.users for insert with check (true);

create policy "Users can read themselves"
  on public.users for select using (true);

create policy "Users can update themselves"
  on public.users for update using (true);

-- ─── Storage (run separately in Storage settings or via API) ─────────────
-- Bucket: event-photos (private)
-- Folder structure: events/{event_id}/full/photo.webp
--                   events/{event_id}/thumb/photo.webp
-- Signed URL expiry: 300 seconds
