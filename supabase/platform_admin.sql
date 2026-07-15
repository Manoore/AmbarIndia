-- Platform owner layer for the Ambar Direct SaaS product.
create table if not exists public.platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  created_at timestamptz not null default now()
);

alter table public.organizations add column if not exists status text not null default 'active' check (status in ('active','trial','past_due','suspended'));

insert into public.platform_admins (user_id, email)
select id, lower(email) from auth.users where lower(email) = 'ambarindia@test.com'
on conflict (user_id) do nothing;

alter table public.platform_admins enable row level security;
create or replace function public.is_platform_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.platform_admins where user_id = auth.uid());
$$;

drop policy if exists "Platform admins can read platform admins" on public.platform_admins;
create policy "Platform admins can read platform admins" on public.platform_admins for select using (public.is_platform_admin());
drop policy if exists "Platform admins can manage organizations" on public.organizations;
create policy "Platform admins can manage organizations" on public.organizations for all using (public.is_platform_admin()) with check (public.is_platform_admin());
drop policy if exists "Platform admins can view staff profiles" on public.staff_profiles;
create policy "Platform admins can view staff profiles" on public.staff_profiles for select using (public.is_platform_admin());
