-- RoastLine - Skema Database Supabase
-- 1. TABEL PROFILES
--    id_profile mengacu ke auth.users (Supabase Auth)
create table if not exists public.profiles (
  id_profile  uuid primary key references auth.users (id) on delete cascade,
  full_name   text        not null default '',
  email       text        not null,
  created_at  timestamptz not null default now()
);

-- 2. TABEL TASKS
create table if not exists public.tasks (
  id_tasks     uuid primary key default gen_random_uuid(),
  id_profile   uuid        not null references public.profiles (id_profile) on delete cascade,
  title        text        not null,
  course       text        not null default '',
  deadline     timestamptz not null,
  notes        text        not null default '',
  is_completed boolean     not null default false,
  completed_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);


alter table public.tasks add column if not exists completed_at timestamptz;
create index if not exists tasks_id_profile_idx on public.tasks (id_profile);
create index if not exists tasks_deadline_idx   on public.tasks (deadline);


-- 3. TABEL NOTIFICATIONS
--    created_at ditambahkan untuk pengurutan

create table if not exists public.notifications (
  id_notification uuid primary key default gen_random_uuid(),
  id_profile      uuid        not null references public.profiles (id_profile) on delete cascade,
  id_tasks        uuid        references public.tasks (id_tasks) on delete cascade,
  message         text        not null,
  -- 'kind' membedakan jenis notifikasi supaya sweep reminder idempotent
  -- (task_added | reminder_24h | reminder_6h | reminder_1h | due | overdue | completed | push)
  kind            text        not null default 'info',
  is_read         boolean     not null default false,
  created_at      timestamptz not null default now()
);

alter table public.notifications add column if not exists kind    text    not null default 'info';
alter table public.notifications add column if not exists is_read boolean not null default false;
alter table public.notifications add column if not exists created_at timestamptz not null default now();

create index if not exists notifications_id_profile_idx on public.notifications (id_profile);

delete from public.notifications a
using public.notifications b
where a.id_tasks is not null
  and a.id_tasks = b.id_tasks
  and a.kind = b.kind
  and a.ctid > b.ctid;

-- Cegah duplikat notifikasi untuk kombinasi (tugas, jenis) yang sama.
-- Baris tanpa id_tasks (mis. kind='push') tidak pernah bentrok karena
-- NULL dianggap distinct oleh PostgreSQL.
create unique index if not exists notifications_task_kind_uniq
  on public.notifications (id_tasks, kind);


-- TRIGGER: otomatis buat baris profiles saat user baru registrasi
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id_profile, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.email
  )
  on conflict (id_profile) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- TRIGGER: update kolom updated_at pada tasks
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tasks_set_updated_at on public.tasks;
create trigger tasks_set_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();


-- ROW LEVEL SECURITY
-- Setiap user hanya bisa mengakses datanya sendiri
alter table public.profiles      enable row level security;
alter table public.tasks         enable row level security;
alter table public.notifications enable row level security;

-- profiles
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id_profile);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id_profile);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id_profile);

-- tasks
drop policy if exists "tasks_all_own" on public.tasks;
create policy "tasks_all_own" on public.tasks
  for all using (auth.uid() = id_profile) with check (auth.uid() = id_profile);

-- notifications
drop policy if exists "notifications_all_own" on public.notifications;
create policy "notifications_all_own" on public.notifications
  for all using (auth.uid() = id_profile) with check (auth.uid() = id_profile);
