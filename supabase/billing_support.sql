-- Billing, custom domains, and platform support records.
alter table public.organizations add column if not exists stripe_customer_id text;
alter table public.organizations add column if not exists stripe_subscription_id text;
alter table public.organizations add column if not exists trial_ends_at timestamptz;
alter table public.organizations add column if not exists current_period_end timestamptz;

create table if not exists public.merchant_domains (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  domain text not null unique,
  status text not null default 'pending' check (status in ('pending','verified','failed')),
  verification_token text not null default encode(gen_random_bytes(12), 'hex'),
  verified_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  subject text not null,
  description text not null default '',
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  status text not null default 'open' check (status in ('open','in_progress','waiting','resolved')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.merchant_domains enable row level security;
alter table public.support_tickets enable row level security;
drop policy if exists "Platform admins manage domains" on public.merchant_domains;
create policy "Platform admins manage domains" on public.merchant_domains for all using (public.is_platform_admin()) with check (public.is_platform_admin());
drop policy if exists "Merchant owners view domains" on public.merchant_domains;
create policy "Merchant owners view domains" on public.merchant_domains for select using (organization_id = public.current_organization_id());
drop policy if exists "Platform admins manage support" on public.support_tickets;
create policy "Platform admins manage support" on public.support_tickets for all using (public.is_platform_admin()) with check (public.is_platform_admin());
drop policy if exists "Merchant members view support" on public.support_tickets;
create policy "Merchant members view support" on public.support_tickets for select using (organization_id = public.current_organization_id());
