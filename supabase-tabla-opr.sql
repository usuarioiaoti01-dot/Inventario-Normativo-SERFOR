-- ============================================================
--  Inventario Normativo SERFOR — Tabla "Normativos OPR"
--
--  Crea una tabla SEPARADA para los lineamientos y directivas de OPR,
--  con la misma estructura y las mismas reglas de seguridad que
--  public.documentos. En la aplicacion aparece como una pestaña propia.
--
--  Los PDF siguen en el MISMO bucket privado 'documentos', asi que el
--  visor y el asistente IA funcionan sin ningun cambio.
--
--  Nombre fisico: normativos_opr  (en minusculas y con guion bajo).
--  Postgres exige comillas dobles en cada consulta si el nombre lleva
--  espacios o mayusculas; el rotulo "Normativos OPR" es el que se
--  muestra en la interfaz.
--
--  Ejecutar UNA vez en:  Supabase → SQL Editor → New query → pegar → Run
--  Es idempotente: se puede volver a ejecutar sin efectos secundarios.
-- ============================================================

create table if not exists public.normativos_opr (
  id         bigint generated always as identity primary key,
  tipo       text not null,
  titulo     text not null,
  entidad    text,
  anio       int,
  estado     text default 'Vigente',       -- Vigente | Modificada | Derogada
  coleccion  text not null default 'Normativos OPR',  -- sublote dentro de esta tabla
  fecha      date,
  kb         int,
  archivo    text not null,                 -- ruta del PDF dentro del bucket 'documentos'
  original   text,
  created_at timestamptz default now(),
  created_by uuid references auth.users(id)
);

create index if not exists normativos_opr_tipo_idx      on public.normativos_opr(tipo);
create index if not exists normativos_opr_anio_idx      on public.normativos_opr(anio);
create index if not exists normativos_opr_coleccion_idx on public.normativos_opr(coleccion);

alter table public.normativos_opr enable row level security;

-- Lectura: cualquier usuario autenticado
drop policy if exists "opr_select" on public.normativos_opr;
create policy "opr_select" on public.normativos_opr
  for select to authenticated using (true);

-- Insertar / actualizar / borrar: solo administradores
drop policy if exists "opr_insert_admin" on public.normativos_opr;
create policy "opr_insert_admin" on public.normativos_opr
  for insert to authenticated with check (public.is_admin());

drop policy if exists "opr_update_admin" on public.normativos_opr;
create policy "opr_update_admin" on public.normativos_opr
  for update to authenticated using (public.is_admin());

drop policy if exists "opr_delete_admin" on public.normativos_opr;
create policy "opr_delete_admin" on public.normativos_opr
  for delete to authenticated using (public.is_admin());

-- ============================================================
--  Comprobacion:
--    select count(*) from public.normativos_opr;   -- debe dar 116 tras migrar
-- ============================================================
