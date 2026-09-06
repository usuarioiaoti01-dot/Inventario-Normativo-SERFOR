-- ============================================================
--  Inventario Normativo SERFOR — Modulo de administracion de cuentas
--
--  Define dos perfiles y hace cumplir su alcance EN LA BASE, no solo
--  en la interfaz:
--
--    admin        "Administrador" — control total: ve todo, sube
--                 documentos y gestiona cuentas.
--    especialista "Especialista"  — solo consulta y descarga los
--                 documentos de "Normativos OPR".
--
--  Ejecutar UNA vez en:  Supabase → SQL Editor → New query → pegar → Run
--  Es idempotente: se puede volver a ejecutar sin efectos secundarios.
-- ============================================================

-- ---------- 1. Perfiles: nuevo rol y cambio de clave inicial ----------

-- El rol 'lector' pasa a llamarse 'especialista'
update public.profiles set role = 'especialista' where role = 'lector';

-- Marca de "debe cambiar la clave en el primer ingreso".
-- Las cuentas que YA existen no deben verse obligadas: se marcan en false.
do $$
begin
  if not exists (select 1 from information_schema.columns
                 where table_schema='public' and table_name='profiles'
                   and column_name='debe_cambiar_clave') then
    alter table public.profiles add column debe_cambiar_clave boolean not null default true;
    update public.profiles set debe_cambiar_clave = false;   -- solo las preexistentes
  end if;
end$$;

-- Solo se admiten estos dos roles
alter table public.profiles drop constraint if exists profiles_role_valido;
alter table public.profiles add  constraint profiles_role_valido
  check (role in ('admin','especialista'));

-- Los usuarios nuevos nacen como especialistas
alter table public.profiles alter column role set default 'especialista';

-- ---------- 2. Impedir que alguien se ascienda a si mismo ----------
-- La politica "perfil_propio_update" permite editar el propio perfil, lo que
-- SIN esto dejaria a un especialista hacerse administrador con un update.
create or replace function public.proteger_rol()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- Sin usuario final detras (auth.uid() nulo) la operacion viene del servidor:
  -- la Edge Function 'admin-usuarios' actuando con service_role, que ya verifico
  -- por su cuenta que quien llama es administrador. Ahi no se estorba.
  --   Un anonimo no puede llegar hasta aqui: las politicas RLS de profiles exigen
  --   auth.uid() = id o is_admin(), asi que su update no alcanza ninguna fila.
  if auth.uid() is null then
    return new;
  end if;

  if new.role is distinct from old.role and not public.is_admin() then
    raise exception 'Solo un administrador puede cambiar el rol.';
  end if;
  return new;
end;$$;

drop trigger if exists profiles_proteger_rol on public.profiles;
create trigger profiles_proteger_rol
  before update on public.profiles
  for each row execute function public.proteger_rol();

-- ---------- 3. Alcance de los documentos ----------
-- Normativa base (tabla documentos): SOLO administradores.
drop policy if exists "doc_select" on public.documentos;
create policy "doc_select" on public.documentos
  for select to authenticated using (public.is_admin());

-- Normativos OPR: administradores y especialistas.
drop policy if exists "opr_select" on public.normativos_opr;
create policy "opr_select" on public.normativos_opr
  for select to authenticated using (true);

-- ---------- 4. Alcance de los archivos (defensa en profundidad) ----------
-- Los PDF de ambos conjuntos comparten el bucket 'documentos'. Sin esto, un
-- especialista podria pedir una URL firmada de un PDF de la normativa base
-- adivinando su ruta. Los archivos del lote OPR llevan el prefijo 'opr_'.
--   Se comparan los cuatro primeros caracteres en vez de usar LIKE: asi no
--   depende de como interprete la base la barra invertida ni el guion bajo.
drop policy if exists "storage_select" on storage.objects;
create policy "storage_select" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'documentos'
    and (public.is_admin() or left(name, 4) = 'opr_')
  );

-- ============================================================
--  Comprobaciones:
--    select role, count(*) from public.profiles group by role;
--    select email, role, debe_cambiar_clave from public.profiles order by role;
--
--  Convencion que sostiene el punto 4: todo PDF que se cargue en la tabla
--  normativos_opr debe guardarse con el prefijo 'opr_'. El formulario de la
--  aplicacion ya lo hace automaticamente.
-- ============================================================
