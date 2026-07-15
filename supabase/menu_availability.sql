-- Run this once in Supabase Dashboard -> SQL Editor.
-- Stores the per-location hidden menu items controlled in the Manager Portal.

alter table public.locations
add column if not exists menu_availability jsonb not null default '[]'::jsonb;
