-- Run this after schema.sql and auth.sql in Supabase SQL Editor.
-- Secure direct ordering + kitchen tracking for the customer website and staff POS.

alter table public.orders add column if not exists order_reference text;
alter table public.orders add column if not exists access_token uuid not null default gen_random_uuid();
alter table public.orders add column if not exists payment_method text not null default 'pay-at-counter';
alter table public.orders add column if not exists payment_status text not null default 'pending';
alter table public.orders add column if not exists amount_tendered numeric(10,2);
alter table public.orders add column if not exists order_source text not null default 'online';
alter table public.orders add column if not exists kitchen_note text not null default '';
alter table public.orders add column if not exists estimated_ready_at timestamptz;
create unique index if not exists orders_order_reference_key on public.orders(order_reference) where order_reference is not null;

-- Public customers can place a new direct order but cannot read the restaurant order queue.
drop policy if exists "Public can create direct orders" on public.orders;
create policy "Public can create direct orders" on public.orders for insert
with check (status = 'new' and order_reference is not null and access_token is not null);
drop policy if exists "Public can add direct order items" on public.order_items;
create policy "Public can add direct order items" on public.order_items for insert with check (true);

-- Customer tracking requires both a private order id and a private access token kept in their browser.
create or replace function public.track_order(p_order_reference text, p_access_token uuid)
returns table(id uuid, order_reference text, status text, order_type text, estimated_ready_at timestamptz, created_at timestamptz, kitchen_note text)
language sql
security definer
set search_path = public
as $$
  select o.id, o.order_reference, o.status, o.order_type, o.estimated_ready_at, o.created_at, o.kitchen_note
  from public.orders o
  where o.order_reference = p_order_reference and o.access_token = p_access_token;
$$;
