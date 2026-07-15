-- Per-location POS floor plan configuration.
alter table public.locations add column if not exists table_config jsonb not null default '[]'::jsonb;
