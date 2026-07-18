-- Run after schema.sql and the multi-tenant/auth policies.
-- This migration aligns the web and Flutter operational clients.

create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  location_id text not null references public.locations(id) on delete cascade,
  guest_name text not null,
  guest_phone text not null,
  guest_email text not null default '',
  reservation_date date not null,
  reservation_time text not null,
  party_size integer not null check (party_size between 1 and 30),
  notes text not null default '',
  status text not null default 'pending' check (status in ('pending','confirmed','seated','completed','cancelled')),
  created_at timestamptz not null default now()
);

alter table public.reservations enable row level security;
drop policy if exists "Anyone can request a reservation" on public.reservations;
create policy "Anyone can request a reservation" on public.reservations for insert with check (true);
drop policy if exists "Managers can view reservations" on public.reservations;
create policy "Managers can view reservations" on public.reservations for select using (public.is_manager());
drop policy if exists "Managers can update reservations" on public.reservations;
create policy "Managers can update reservations" on public.reservations for update using (public.is_manager()) with check (public.is_manager());

alter table public.orders add column if not exists order_source text not null default 'online';
alter table public.orders add column if not exists payment_method text not null default 'pay-at-counter';
alter table public.orders add column if not exists payment_status text not null default 'pending';
alter table public.orders add column if not exists amount_tendered numeric(10,2);
alter table public.orders add column if not exists kitchen_note text not null default '';
alter table public.orders add column if not exists order_reference text unique;
alter table public.orders add column if not exists access_token text;
alter table public.orders add column if not exists estimated_ready_at timestamptz;

create index if not exists orders_location_created_idx on public.orders(location_id, created_at desc);
create index if not exists orders_status_idx on public.orders(status);
create index if not exists reservations_location_date_idx on public.reservations(location_id, reservation_date, reservation_time);

create or replace function public.track_order(p_order_reference text, p_access_token text)
returns setof public.orders language sql security definer set search_path = public as $$
  select * from public.orders where order_reference = p_order_reference and access_token = p_access_token limit 1;
$$;
revoke all on function public.track_order(text, text) from public;
grant execute on function public.track_order(text, text) to anon, authenticated;

drop policy if exists "Public can create orders" on public.orders;
create policy "Public can create orders" on public.orders for insert with check (true);
drop policy if exists "Public can create order items" on public.order_items;
create policy "Public can create order items" on public.order_items for insert with check (true);
