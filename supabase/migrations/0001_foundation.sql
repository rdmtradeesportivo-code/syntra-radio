begin;

create extension if not exists pgcrypto;

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated, service_role;

create type public.member_role as enum ('owner','admin','programmer','operator','commercial','viewer');
create type public.station_mode as enum ('web','fm','hybrid');
create type public.agent_status as enum ('offline','online','degraded');
create type public.media_kind as enum ('music','jingle','spot','program','voice_track','sweep');
create type public.playout_event_type as enum ('queued','started','ended','skipped','failed','live_entered','live_exited');

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  timezone text not null default 'America/Fortaleza',
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_members (
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.member_role not null,
  created_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);

create table public.stations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 120),
  slug text not null,
  mode public.station_mode not null default 'hybrid',
  timezone text not null default 'America/Fortaleza',
  stream_public_url text,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, slug)
);

create table public.studio_agents (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  station_id uuid not null references public.stations(id) on delete cascade,
  name text not null,
  device_id text not null unique,
  version text,
  status public.agent_status not null default 'offline',
  capabilities jsonb not null default '{}'::jsonb,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  kind public.media_kind not null,
  title text not null,
  artist text,
  duration_ms integer check (duration_ms is null or duration_ms >= 0),
  storage_path text not null,
  sha256 text,
  loudness_lufs numeric(6,2),
  cue_in_ms integer not null default 0 check (cue_in_ms >= 0),
  cue_out_ms integer check (cue_out_ms is null or cue_out_ms >= 0),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  description text,
  rules jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.playlist_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  playlist_id uuid not null references public.playlists(id) on delete cascade,
  media_asset_id uuid not null references public.media_assets(id) on delete restrict,
  position integer not null check (position >= 0),
  created_at timestamptz not null default now(),
  unique (playlist_id, position)
);

create table public.schedule_blocks (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  station_id uuid not null references public.stations(id) on delete cascade,
  title text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  playlist_id uuid references public.playlists(id) on delete set null,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create table public.playout_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  station_id uuid not null references public.stations(id) on delete cascade,
  agent_id uuid references public.studio_agents(id) on delete set null,
  media_asset_id uuid references public.media_assets(id) on delete set null,
  event_type public.playout_event_type not null,
  occurred_at timestamptz not null,
  idempotency_key text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (station_id, idempotency_key)
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index organization_members_user_idx on public.organization_members(user_id, organization_id);
create index stations_org_idx on public.stations(organization_id);
create index studio_agents_station_idx on public.studio_agents(station_id, last_seen_at desc);
create index media_assets_org_kind_idx on public.media_assets(organization_id, kind);
create index playlist_items_playlist_idx on public.playlist_items(playlist_id, position);
create index schedule_blocks_station_time_idx on public.schedule_blocks(station_id, starts_at, ends_at);
create index playout_events_station_time_idx on public.playout_events(station_id, occurred_at desc);
create index audit_logs_org_time_idx on public.audit_logs(organization_id, created_at desc);

create or replace function private.is_org_member(target_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1
    from public.organization_members m
    where m.organization_id = target_org
      and m.user_id = auth.uid()
  );
$$;

create or replace function private.has_org_role(target_org uuid, allowed public.member_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1
    from public.organization_members m
    where m.organization_id = target_org
      and m.user_id = auth.uid()
      and m.role = any(allowed)
  );
$$;

revoke all on function private.is_org_member(uuid) from public, anon;
revoke all on function private.has_org_role(uuid, public.member_role[]) from public, anon;
grant execute on function private.is_org_member(uuid) to authenticated, service_role;
grant execute on function private.has_org_role(uuid, public.member_role[]) to authenticated, service_role;

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.stations enable row level security;
alter table public.studio_agents enable row level security;
alter table public.media_assets enable row level security;
alter table public.playlists enable row level security;
alter table public.playlist_items enable row level security;
alter table public.schedule_blocks enable row level security;
alter table public.playout_events enable row level security;
alter table public.audit_logs enable row level security;

create policy organizations_select on public.organizations
for select to authenticated
using (private.is_org_member(id));

create policy members_select on public.organization_members
for select to authenticated
using (private.is_org_member(organization_id));

create policy stations_select on public.stations
for select to authenticated
using (private.is_org_member(organization_id));

create policy stations_write on public.stations
for all to authenticated
using (private.has_org_role(organization_id, array['owner','admin']::public.member_role[]))
with check (private.has_org_role(organization_id, array['owner','admin']::public.member_role[]));

create policy agents_select on public.studio_agents
for select to authenticated
using (private.is_org_member(organization_id));

create policy assets_select on public.media_assets
for select to authenticated
using (private.is_org_member(organization_id));

create policy assets_write on public.media_assets
for all to authenticated
using (private.has_org_role(organization_id, array['owner','admin','programmer','operator','commercial']::public.member_role[]))
with check (private.has_org_role(organization_id, array['owner','admin','programmer','operator','commercial']::public.member_role[]));

create policy playlists_select on public.playlists
for select to authenticated
using (private.is_org_member(organization_id));

create policy playlists_write on public.playlists
for all to authenticated
using (private.has_org_role(organization_id, array['owner','admin','programmer','operator']::public.member_role[]))
with check (private.has_org_role(organization_id, array['owner','admin','programmer','operator']::public.member_role[]));

create policy playlist_items_select on public.playlist_items
for select to authenticated
using (private.is_org_member(organization_id));

create policy playlist_items_write on public.playlist_items
for all to authenticated
using (private.has_org_role(organization_id, array['owner','admin','programmer','operator']::public.member_role[]))
with check (private.has_org_role(organization_id, array['owner','admin','programmer','operator']::public.member_role[]));

create policy schedule_select on public.schedule_blocks
for select to authenticated
using (private.is_org_member(organization_id));

create policy schedule_write on public.schedule_blocks
for all to authenticated
using (private.has_org_role(organization_id, array['owner','admin','programmer','operator']::public.member_role[]))
with check (private.has_org_role(organization_id, array['owner','admin','programmer','operator']::public.member_role[]));

create policy playout_select on public.playout_events
for select to authenticated
using (private.is_org_member(organization_id));

create policy audit_select on public.audit_logs
for select to authenticated
using (private.has_org_role(organization_id, array['owner','admin']::public.member_role[]));

revoke all on all tables in schema public from anon;

grant select on
  public.organizations,
  public.organization_members,
  public.stations,
  public.studio_agents,
  public.media_assets,
  public.playlists,
  public.playlist_items,
  public.schedule_blocks,
  public.playout_events
to authenticated;

grant insert, update, delete on
  public.stations,
  public.media_assets,
  public.playlists,
  public.playlist_items,
  public.schedule_blocks
to authenticated;

grant select on public.audit_logs to authenticated;

grant select, insert, update, delete on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;

alter default privileges for role postgres in schema public
  revoke select, insert, update, delete on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke usage, select on sequences from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions from public;

commit;
