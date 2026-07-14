-- Run this once in Supabase Dashboard -> SQL Editor.
-- It creates the shared, multi-location foundation for the Ambar Direct demo.

create extension if not exists pgcrypto;

create table if not exists public.locations (
  id text primary key,
  name text not null,
  address text not null default '',
  phone text not null default '',
  services jsonb not null default '[]'::jsonb,
  hours jsonb not null default '{}'::jsonb,
  reward_offer text not null default '',
  menu_note text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  location_id text not null references public.locations(id) on delete cascade,
  category text not null,
  name text not null,
  description text not null default '',
  price numeric(10,2) not null,
  image_url text,
  available boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.rewards_offers (
  id uuid primary key default gen_random_uuid(),
  location_id text not null references public.locations(id) on delete cascade,
  title text not null,
  details text not null default '',
  active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  location_id text not null references public.locations(id),
  order_type text not null check (order_type in ('dine-in','pickup','delivery','phone','qr-table')),
  status text not null default 'new' check (status in ('new','preparing','ready','completed','cancelled')),
  guest_name text,
  guest_phone text,
  table_number text,
  subtotal numeric(10,2) not null default 0,
  total numeric(10,2) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  menu_item_id uuid references public.menu_items(id),
  name text not null,
  unit_price numeric(10,2) not null,
  quantity integer not null default 1,
  notes text not null default ''
);

-- Temporary demo policy: the site may read locations. Keep manager writes locked down
-- until staff authentication is connected. Do not add an anonymous write policy in production.
alter table public.locations enable row level security;
alter table public.menu_items enable row level security;
alter table public.rewards_offers enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists "Public can view active locations" on public.locations;
create policy "Public can view active locations" on public.locations for select using (is_active = true);
drop policy if exists "Public can view available menu items" on public.menu_items;
create policy "Public can view available menu items" on public.menu_items for select using (available = true);
drop policy if exists "Public can view active offers" on public.rewards_offers;
create policy "Public can view active offers" on public.rewards_offers for select using (active = true);

-- Seed the existing Clifton restaurant. Safe to run again.
insert into public.locations (id, name, address, phone, services, hours, reward_offer, menu_note)
values ('clifton', 'Ambar India Clifton', '350 Ludlow Ave, Cincinnati, OH 45220', '(513) 281-7000', '["dine-in","pickup","delivery","catering"]', '{"sunday":"10:30 AM – 9:30 PM","weekday":"10:30 AM – 10:00 PM","saturday":"10:30 AM – 10:00 PM"}', 'Free Garlic Naan with orders over $35', 'Our complete Clifton menu, made fresh to order.')
on conflict (id) do update set name = excluded.name, address = excluded.address, phone = excluded.phone, services = excluded.services, hours = excluded.hours, reward_offer = excluded.reward_offer, menu_note = excluded.menu_note, updated_at = now();
