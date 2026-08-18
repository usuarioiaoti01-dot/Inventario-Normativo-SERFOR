-- ============================================================
--  Inventario Normativo SERFOR — Esquema de base de datos
--  Ejecutar UNA vez en:  Supabase → SQL Editor → New query → pegar → Run
-- ============================================================

-- ---------- 1. Perfiles de usuario (con rol) ----------
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text,
  nombre     text,
  role       text not null default 'lector',   -- 'lector' | 'admin'
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

-- Cada usuario puede ver y editar su propio perfil
drop policy if exists "perfil_propio_select" on public.profiles;
create policy "perfil_propio_select" on public.profiles
  for select to authenticated using (auth.uid() = id);

drop policy if exists "perfil_propio_update" on public.profiles;
create policy "perfil_propio_update" on public.profiles
  for update to authenticated using (auth.uid() = id);

-- Al registrarse un usuario, se crea su perfil automáticamente
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email)
    on conflict (id) do nothing;
  return new;
end;$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Helper: ¿el usuario actual es admin?
create or replace function public.is_admin()
returns boolean language sql security definer stable set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- ---------- 2. Catálogo de documentos ----------
create table if not exists public.documentos (
  id         bigint generated always as identity primary key,
  tipo       text not null,
  titulo     text not null,
  entidad    text,
  anio       int,
  estado     text default 'Vigente',       -- Vigente | Modificada | Derogada
  coleccion  text not null default 'Normativa base',  -- lote/grupo al que pertenece
  fecha      date,
  kb         int,
  archivo    text not null,                 -- ruta del PDF dentro del bucket 'documentos'
  original   text,
  created_at timestamptz default now(),
  created_by uuid references auth.users(id)
);

create index if not exists documentos_tipo_idx on public.documentos(tipo);
create index if not exists documentos_anio_idx on public.documentos(anio);
create index if not exists documentos_coleccion_idx on public.documentos(coleccion);

alter table public.documentos enable row level security;

-- Lectura: cualquier usuario autenticado
drop policy if exists "doc_select" on public.documentos;
create policy "doc_select" on public.documentos
  for select to authenticated using (true);

-- Insertar / actualizar / borrar: solo administradores
drop policy if exists "doc_insert_admin" on public.documentos;
create policy "doc_insert_admin" on public.documentos
  for insert to authenticated with check (public.is_admin());

drop policy if exists "doc_update_admin" on public.documentos;
create policy "doc_update_admin" on public.documentos
  for update to authenticated using (public.is_admin());

drop policy if exists "doc_delete_admin" on public.documentos;
create policy "doc_delete_admin" on public.documentos
  for delete to authenticated using (public.is_admin());

-- ---------- 3. Almacenamiento de archivos (bucket privado) ----------
insert into storage.buckets (id, name, public)
  values ('documentos', 'documentos', false)
  on conflict (id) do nothing;

-- Leer archivos: cualquier autenticado (se usan URLs firmadas temporales)
drop policy if exists "storage_select" on storage.objects;
create policy "storage_select" on storage.objects
  for select to authenticated using (bucket_id = 'documentos');

-- Subir archivos: solo administradores
drop policy if exists "storage_insert_admin" on storage.objects;
create policy "storage_insert_admin" on storage.objects
  for insert to authenticated with check (bucket_id = 'documentos' and public.is_admin());

drop policy if exists "storage_update_admin" on storage.objects;
create policy "storage_update_admin" on storage.objects
  for update to authenticated using (bucket_id = 'documentos' and public.is_admin());

drop policy if exists "storage_delete_admin" on storage.objects;
create policy "storage_delete_admin" on storage.objects
  for delete to authenticated using (bucket_id = 'documentos' and public.is_admin());

-- ============================================================
--  DESPUÉS de crear tu primer usuario (Authentication → Users → Add user),
--  conviértelo en administrador ejecutando (cambia el correo):
--
--    update public.profiles set role = 'admin'
--    where email = 'adm-claude@serfor.gob.pe';
-- ============================================================
