-- ============================================================================
-- Maridive Fleet Vessels — shared cloud backend schema (Supabase / Postgres)
-- Run this ONCE in your Supabase project: Dashboard → SQL Editor → New query →
-- paste all of this → Run.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Profiles: one row per authenticated user, carrying the username + role.
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique not null,
  display_name text not null default '',
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles readable by authenticated" on public.profiles;
create policy "profiles readable by authenticated"
  on public.profiles for select to authenticated using (true);
-- Inserts/updates/deletes to profiles are performed only by the server-side
-- admin function (service_role), which bypasses RLS. No client write policy.

-- Auto-create a profile row whenever a new auth user is added (via the
-- dashboard or the admin function), reading username/role from user metadata.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, display_name, is_admin)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'display_name', ''),
    coalesce((new.raw_user_meta_data ->> 'is_admin')::boolean, false)
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- Generic per-module data tables. Each record is stored as JSON (the same map
-- the app already serializes), keyed by its id and vessel, so all devices
-- share one source of truth. RLS: any signed-in fleet user can read/write.
-- ----------------------------------------------------------------------------
do $$
declare
  t text;
  module_tables text[] := array[
    'readings', 'notes', 'defects', 'requisitions', 'port_calls',
    'port_requirements', 'crew_members',
    'vessel_certs', 'crew_certs', 'urgent_notifications', 'daily_tasks',
    'maintenance_records', 'vessel_specs', 'vessel_profiles',
    'handover_reports', 'ingestion_batches', 'ingestion_errors'
  ];
begin
  foreach t in array module_tables loop
    execute format('
      create table if not exists public.%I (
        id text primary key,
        vessel_id text,
        data jsonb not null default ''{}''::jsonb,
        updated_at timestamptz not null default now()
      );', t);
    execute format('create index if not exists %I on public.%I (vessel_id);',
      t || '_vessel_idx', t);
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists "fleet users full access" on public.%I;', t);
    execute format('
      create policy "fleet users full access" on public.%I
        for all to authenticated using (true) with check (true);', t);
  end loop;
end $$;

-- ----------------------------------------------------------------------------
-- Storage bucket for shared file attachments (spec PDFs, photos, documents).
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('attachments', 'attachments', false)
on conflict (id) do nothing;

drop policy if exists "attachments read" on storage.objects;
create policy "attachments read" on storage.objects
  for select to authenticated using (bucket_id = 'attachments');

drop policy if exists "attachments write" on storage.objects;
create policy "attachments write" on storage.objects
  for insert to authenticated with check (bucket_id = 'attachments');

drop policy if exists "attachments update" on storage.objects;
create policy "attachments update" on storage.objects
  for update to authenticated using (bucket_id = 'attachments');

drop policy if exists "attachments delete" on storage.objects;
create policy "attachments delete" on storage.objects
  for delete to authenticated using (bucket_id = 'attachments');
