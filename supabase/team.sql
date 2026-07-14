-- Run after auth.sql. Adds role-based team management and screen restrictions.

create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.staff_profiles where user_id = auth.uid() and role = 'owner');
$$;

-- A staff profile is created as a cashier when a team member first activates
-- their secure email sign-in. Owners can then assign their final role and locations.
create or replace function public.create_staff_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.staff_profiles (user_id, email, role)
  values (new.id, lower(new.email), 'cashier')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_staff_created on auth.users;
create trigger on_auth_staff_created
after insert on auth.users
for each row execute procedure public.create_staff_profile();

drop policy if exists "Owners can view staff" on public.staff_profiles;
create policy "Owners can view staff" on public.staff_profiles for select using (public.is_owner());
drop policy if exists "Owners can add staff" on public.staff_profiles;
create policy "Owners can add staff" on public.staff_profiles for insert with check (public.is_owner());
drop policy if exists "Owners can update staff" on public.staff_profiles;
create policy "Owners can update staff" on public.staff_profiles for update using (public.is_owner()) with check (public.is_owner());
drop policy if exists "Owners can remove staff" on public.staff_profiles;
create policy "Owners can remove staff" on public.staff_profiles for delete using (public.is_owner());
