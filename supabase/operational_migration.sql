-- Run after schema.sql and the multi-tenant/auth policies.
-- This migration aligns the web and Flutter operational clients.

alter table public.orders add column if not exists order_source text not null default 'online';
alter table public.orders add column if not exists payment_method text not null default 'pay-at-counter';
alter table public.orders add column if not exists payment_status text not null default 'pending';
alter table public.orders add column if not exists amount_tendered numeric(10,2);
alter table public.orders add column if not exists kitchen_note text not null default '';
alter table public.orders add column if not exists order_reference text unique;
alter table public.orders add column if not exists access_token text;
alter table public.orders add column if not exists estimated_ready_at timestamptz;

create index if not exists orders_location_created_idx
  on public.orders(location_id, created_at desc);
create index if not exists orders_status_idx
  on public.orders(status);
create index if not exists reservations_location_date_idx
  on public.reservations(location_id, reservation_date, reservation_time);

-- Anonymous customers can only retrieve their own order using its reference/token.
create or replace function public.track_order(p_order_reference text, p_access_token text)
returns setof public.orders
language sql
security definer
set search_path = public
as $$
  select * from public.orders
  where order_reference = p_order_reference
    and access_token = p_access_token
  limit 1;
$$;

revoke all on function public.track_order(text, text) from public;
grant execute on function public.track_order(text, text) to anon, authenticated;

-- Keep public order creation available for the customer checkout while manager
-- updates remain governed by the existing manager policies.
drop policy if exists "Public can create orders" on public.orders;
create policy "Public can create orders" on public.orders
  for insert with check (true);
drop policy if exists "Public can create order items" on public.order_items;
create policy "Public can create order items" on public.order_items
  for insert with check (true);

