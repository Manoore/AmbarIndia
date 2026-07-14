-- Run this after schema.sql in Supabase Dashboard -> SQL Editor.
-- It makes Amberindia@test.com the initial owner and locks manager writes to staff.

create table if not exists public.staff_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  role text not null check (role in ('owner', 'manager', 'cashier', 'kitchen')),
  location_ids jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.staff_profiles enable row level security;

create or replace function public.is_manager()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.staff_profiles
    where user_id = auth.uid() and role in ('owner', 'manager')
  );
$$;

-- This backfills the owner whether the Authentication user was created before or after schema.sql.
-- Create the user under Authentication -> Users with this exact email before running this script.
insert into public.staff_profiles (user_id, email, role)
select id, lower(email), 'owner'
from auth.users
where lower(email) = 'amberindia@test.com'
on conflict (user_id) do update set email = excluded.email, role = 'owner';

drop policy if exists "Staff can read own profile" on public.staff_profiles;
create policy "Staff can read own profile" on public.staff_profiles for select using (user_id = auth.uid());

drop policy if exists "Managers manage locations" on public.locations;
create policy "Managers manage locations" on public.locations for all using (public.is_manager()) with check (public.is_manager());
drop policy if exists "Managers manage menu items" on public.menu_items;
create policy "Managers manage menu items" on public.menu_items for all using (public.is_manager()) with check (public.is_manager());
drop policy if exists "Managers manage rewards offers" on public.rewards_offers;
create policy "Managers manage rewards offers" on public.rewards_offers for all using (public.is_manager()) with check (public.is_manager());
drop policy if exists "Staff manage orders" on public.orders;
create policy "Staff manage orders" on public.orders for all using (public.is_manager()) with check (public.is_manager());
drop policy if exists "Staff manage order items" on public.order_items;
create policy "Staff manage order items" on public.order_items for all using (public.is_manager()) with check (public.is_manager());
