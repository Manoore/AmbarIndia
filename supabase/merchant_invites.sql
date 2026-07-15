-- Merchant invitations created from Platform Admin.
create table if not exists public.merchant_invites (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  organization_name text not null,
  location_name text not null,
  address text not null default '',
  plan text not null default 'starter' check (plan in ('starter','growth','pro')),
  status text not null default 'pending' check (status in ('pending','accepted','cancelled')),
  invited_by uuid not null references auth.users(id),
  organization_id uuid references public.organizations(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.merchant_invites enable row level security;
drop policy if exists "Platform admins manage invitations" on public.merchant_invites;
create policy "Platform admins manage invitations" on public.merchant_invites for all using (public.is_platform_admin()) with check (public.is_platform_admin());
drop policy if exists "Invited owners can read their invitation" on public.merchant_invites;
create policy "Invited owners can read their invitation" on public.merchant_invites for select using (lower(email) = lower(auth.jwt() ->> 'email'));
drop policy if exists "Invited owners can accept their invitation" on public.merchant_invites;
create policy "Invited owners can accept their invitation" on public.merchant_invites for update using (lower(email) = lower(auth.jwt() ->> 'email') and status = 'pending') with check (lower(email) = lower(auth.jwt() ->> 'email'));

drop policy if exists "Invited users can claim profile" on public.staff_profiles;
create policy "Invited users can claim profile" on public.staff_profiles for insert with check (user_id = auth.uid() and exists (select 1 from public.merchant_invites where lower(email) = lower(auth.jwt() ->> 'email') and status = 'pending'));
drop policy if exists "Invited users can activate profile" on public.staff_profiles;
create policy "Invited users can activate profile" on public.staff_profiles for update using (user_id = auth.uid() and exists (select 1 from public.merchant_invites where lower(email) = lower(auth.jwt() ->> 'email') and status = 'pending')) with check (user_id = auth.uid());
