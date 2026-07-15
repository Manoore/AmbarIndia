-- Ambar Direct product foundation. Run after schema.sql, auth.sql, team.sql,
-- and the other existing migrations.

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  plan text not null default 'starter' check (plan in ('starter','growth','pro')),
  tagline text not null default '',
  logo_url text not null default '',
  primary_color text not null default '#5b1723',
  accent_color text not null default '#d9ff75',
  owner_user_id uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

alter table public.staff_profiles add column if not exists organization_id uuid references public.organizations(id) on delete cascade;
alter table public.locations add column if not exists organization_id uuid references public.organizations(id) on delete cascade;

-- Create the original Ambar workspace and attach existing records.
insert into public.organizations (name, slug, plan, owner_user_id)
select 'Ambar India', 'ambar-india', 'pro', id
from auth.users
where lower(email) = 'ambarindia@test.com'
on conflict (slug) do nothing;

update public.staff_profiles
set organization_id = (select id from public.organizations where slug = 'ambar-india')
where lower(email) = 'ambarindia@test.com' and organization_id is null;

update public.locations
set organization_id = (select id from public.organizations where slug = 'ambar-india')
where organization_id is null;

alter table public.organizations enable row level security;
drop policy if exists "Owners can view their organization" on public.organizations;
create policy "Owners can view their organization" on public.organizations for select using (owner_user_id = auth.uid() or exists (select 1 from public.staff_profiles where user_id = auth.uid() and organization_id = organizations.id));
drop policy if exists "Authenticated users can create an organization" on public.organizations;
create policy "Authenticated users can create an organization" on public.organizations for insert with check (owner_user_id = auth.uid());
drop policy if exists "Public can view organization brand" on public.organizations;
create policy "Public can view organization brand" on public.organizations for select using (true);
drop policy if exists "Owners can update their organization" on public.organizations;
create policy "Owners can update their organization" on public.organizations for update using (owner_user_id = auth.uid()) with check (owner_user_id = auth.uid());

create or replace function public.current_organization_id()
returns uuid language sql stable security definer set search_path = public as $$
  select organization_id from public.staff_profiles where user_id = auth.uid() limit 1;
$$;

drop policy if exists "Managers manage locations" on public.locations;
create policy "Managers manage locations" on public.locations for all using (public.is_manager() and organization_id = public.current_organization_id()) with check (public.is_manager() and organization_id = public.current_organization_id());

drop policy if exists "Owners can create their profile" on public.staff_profiles;
create policy "Owners can create their profile" on public.staff_profiles for insert with check (user_id = auth.uid() and lower(email) = lower((select email from auth.users where id = auth.uid())));
