-- Run this once in Supabase Dashboard -> SQL Editor.
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
