-- ============================================================
--  Inventario Normativo SERFOR — Perfiles editables
--
--  Hasta ahora los perfiles estaban escritos en el codigo: para crear
--  uno nuevo habia que tocar el SQL, la Edge Function y el HTML. Ahora
--  viven en una tabla y se administran desde la pantalla Usuarios.
--
--  CAMBIO DE FONDO: el control de acceso pasa a ser DATO. Las funciones
--  que deciden quien ve que ya no llevan la lista de roles dentro: la
--  consultan. Un cambio en la pantalla de Perfiles cambia permisos de
--  verdad, en el acto. Por eso el perfil que gestiona cuentas esta
--  protegido por un disparador (seccion 6).
--
--  OJO CON EL NOMBRE: la tabla se llama 'perfiles_acceso', no 'perfiles'.
--  En esta base ya hay una tabla 'perfiles' que pertenece a OTRA aplicacion
--  (columnas id, nombre, rol, email). No se toca.
--
--  Requiere supabase-tres-perfiles.sql y supabase-carga-por-perfil.sql.
--  Ejecutar en: Supabase -> SQL Editor -> New query -> pegar -> Run
--  Es idempotente.
-- ============================================================

-- ---------- 0. Comprobacion previa ----------
--  'create table if not exists' no avisa cuando ya existe una tabla con ese
--  nombre y otra forma: se salta la creacion sin decir nada y el error
--  aparece cien lineas despues, con un mensaje que no apunta a la causa.
--  Asi fallo el primer intento contra 'perfiles'. Mejor fallar aqui y claro.
do $guardia$
begin
  if exists (select 1 from information_schema.tables
             where table_schema = 'public' and table_name = 'perfiles_acceso')
     and not exists (select 1 from information_schema.columns
                     where table_schema = 'public' and table_name = 'perfiles_acceso'
                       and column_name = 'clave') then
    raise exception
      'Ya existe public.perfiles_acceso con otra estructura (le falta la columna "clave"). Revisala antes de seguir: este script no la va a modificar.';
  end if;
end
$guardia$;

-- ---------- 1. La tabla de perfiles ----------
create table if not exists public.perfiles_acceso (
  clave        text primary key,               -- 'admin', 'especialista', ...
  nombre       text not null,                  -- 'Administrador'
  descripcion  text,
  ve_oti       boolean not null default false,
  ve_opr       boolean not null default false,
  carga_oti    boolean not null default false,
  carga_opr    boolean not null default false,
  gestiona_cuentas boolean not null default false,
  usa_asistente    boolean not null default false,
  del_sistema  boolean not null default false,  -- protegido: no se borra
  orden        int     not null default 50,     -- para listarlos de forma estable
  created_at   timestamptz default now()
);

--  La clave es un identificador, no un rotulo: minusculas, sin espacios.
alter table public.perfiles_acceso drop constraint if exists perfiles_acceso_clave_formato;
alter table public.perfiles_acceso add  constraint perfiles_acceso_clave_formato
  check (clave ~ '^[a-z][a-z0-9_]{1,30}$');

-- ---------- 2. Los perfiles que ya existian ----------
--  'admin' queda marcado del_sistema: es el unico que gestiona cuentas,
--  y sin el nadie podria volver a entrar a administrar.
insert into public.perfiles_acceso
  (clave, nombre, descripcion, ve_oti, ve_opr, carga_oti, carga_opr,
   gestiona_cuentas, usa_asistente, del_sistema, orden)
values
  ('admin', 'Administrador',
   'Ve todo, carga en ambos conjuntos y gestiona las cuentas.',
   true,  true,  true,  true,  true,  true,  true,  10),

  ('especialista', 'Especialista',
   'Solo Normativos OPR: consulta y carga.',
   false, true,  false, true,  false, false, false, 20),

  ('normas_oti', 'Normas OTI',
   'Solo la base normativa: consulta y carga.',
   true,  false, true,  false, false, false, false, 30),

  ('lector', 'Lector',
   'Consulta ambos conjuntos. No carga ni administra. Pensado para que otra aplicacion lea el catalogo.',
   true,  true,  false, false, false, false, false, 40)
on conflict (clave) do nothing;   -- si ya existen, se respetan sus cambios

-- ---------- 3. La columna role pasa a apuntar a esta tabla ----------
--  Antes era una lista cerrada en un CHECK; ahora es una referencia, asi
--  que crear un perfil basta para poder asignarlo.
--
--  OJO: esa restriccion se ha llamado de dos formas a lo largo del proyecto
--  ('profiles_role_valido' en supabase-usuarios.sql y supabase-tres-perfiles.sql,
--  'profiles_role_check' en supabase-rol-lector.sql), de modo que la base puede
--  tener DOS a la vez y bastaba con que sobreviviera una para seguir
--  rechazando los perfiles nuevos. Por eso no se nombran: se retiran todas
--  las que miren a 'role', se llamen como se llamen.
do $limpia$
declare r record;
begin
  for r in
    select con.conname
    from pg_constraint con
    join pg_class     c on c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'profiles'
      and con.contype = 'c'                                   -- solo CHECK
      and pg_get_constraintdef(con.oid) ilike '%role%'
  loop
    execute format('alter table public.profiles drop constraint %I', r.conname);
    raise notice 'Retirada la restriccion %', r.conname;
  end loop;
end
$limpia$;

alter table public.profiles drop constraint if exists profiles_role_fk;
alter table public.profiles add  constraint profiles_role_fk
  foreign key (role) references public.perfiles_acceso(clave)
  on update cascade        -- renombrar la clave arrastra las cuentas
  on delete restrict;      -- no se borra un perfil que alguien usa

-- ---------- 4. Las funciones dejan de llevar la lista dentro ----------
--  Conservan nombre y firma, asi que las politicas RLS que ya existen
--  siguen sirviendo sin tocarlas.
create or replace function public.permiso(p text)
returns boolean language sql security definer stable set search_path = public as $fn$
  select coalesce(
    (select case p
       when 've_oti'    then f.ve_oti
       when 've_opr'    then f.ve_opr
       when 'carga_oti' then f.carga_oti
       when 'carga_opr' then f.carga_opr
       when 'cuentas'   then f.gestiona_cuentas
       when 'asistente' then f.usa_asistente
     end
     from public.perfiles_acceso f
     where f.clave = public.rol_actual()), false);
$fn$;

create or replace function public.ve_opr()
returns boolean language sql security definer stable set search_path = public as $fn$
  select public.permiso('ve_opr');
$fn$;

create or replace function public.ve_oti()
returns boolean language sql security definer stable set search_path = public as $fn$
  select public.permiso('ve_oti');
$fn$;

create or replace function public.carga_opr()
returns boolean language sql security definer stable set search_path = public as $fn$
  select public.permiso('carga_opr');
$fn$;

create or replace function public.carga_oti()
returns boolean language sql security definer stable set search_path = public as $fn$
  select public.permiso('carga_oti');
$fn$;

create or replace function public.is_admin()
returns boolean language sql security definer stable set search_path = public as $fn$
  select public.permiso('cuentas');
$fn$;

grant execute on function public.permiso(text) to authenticated;

-- ---------- 5. Quien puede leer y tocar los perfiles ----------
alter table public.perfiles_acceso enable row level security;

--  Leer: cualquiera autenticado. La aplicacion lo necesita para saber que
--  mostrar, y en la definicion de un perfil no hay nada sensible.
drop policy if exists "perfiles_acceso_select" on public.perfiles_acceso;
create policy "perfiles_acceso_select" on public.perfiles_acceso
  for select to authenticated using (true);

--  Crear, modificar y borrar: solo quien gestiona cuentas.
drop policy if exists "perfiles_acceso_insert" on public.perfiles_acceso;
create policy "perfiles_acceso_insert" on public.perfiles_acceso
  for insert to authenticated with check (public.is_admin());

drop policy if exists "perfiles_acceso_update" on public.perfiles_acceso;
create policy "perfiles_acceso_update" on public.perfiles_acceso
  for update to authenticated using (public.is_admin());

drop policy if exists "perfiles_acceso_delete" on public.perfiles_acceso;
create policy "perfiles_acceso_delete" on public.perfiles_acceso
  for delete to authenticated using (public.is_admin());

-- ---------- 6. El seguro ----------
--  Un descuido en la pantalla de Perfiles no puede dejar al sistema sin
--  nadie capaz de administrarlo, ni borrar un perfil de sistema.
create or replace function public.proteger_perfiles_acceso()
returns trigger language plpgsql security definer set search_path = public as $fn$
begin
  if TG_OP = 'DELETE' then
    if old.del_sistema then
      raise exception 'El perfil "%" es del sistema y no se puede eliminar.', old.nombre;
    end if;
    return old;
  end if;

  --  Nadie puede quitarle la gestion de cuentas al ultimo que la tiene
  if old.gestiona_cuentas and not new.gestiona_cuentas then
    if (select count(*) from public.perfiles_acceso
        where gestiona_cuentas and clave <> old.clave) = 0 then
      raise exception 'Debe quedar al menos un perfil que gestione cuentas.';
    end if;
  end if;

  --  Un perfil de sistema conserva su condicion
  if old.del_sistema and not new.del_sistema then
    raise exception 'No se puede quitar la condicion de perfil de sistema.';
  end if;

  return new;
end;$fn$;

drop trigger if exists perfiles_acceso_proteger on public.perfiles_acceso;
create trigger perfiles_acceso_proteger
  before update or delete on public.perfiles_acceso
  for each row execute function public.proteger_perfiles_acceso();

-- ============================================================
--  Comprobacion (una sola consulta: el editor muestra solo la ultima)
--
--    select p.orden, p.clave, p.nombre,
--           p.ve_oti, p.ve_opr, p.carga_oti, p.carga_opr,
--           p.gestiona_cuentas, p.usa_asistente, p.del_sistema,
--           (select count(*) from public.profiles u where u.role = p.clave) as cuentas
--    from public.perfiles_acceso p order by p.orden, p.clave;
--
--  Debe devolver 4 filas y 'admin' con cuentas >= 1.
-- ============================================================
