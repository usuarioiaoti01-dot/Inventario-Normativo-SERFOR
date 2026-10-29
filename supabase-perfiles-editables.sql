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
--  Requiere supabase-tres-perfiles.sql y supabase-carga-por-perfil.sql.
--  Ejecutar en: Supabase -> SQL Editor -> New query -> pegar -> Run
--  Es idempotente.
-- ============================================================

-- ---------- 1. La tabla de perfiles ----------
create table if not exists public.perfiles (
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
alter table public.perfiles drop constraint if exists perfiles_clave_formato;
alter table public.perfiles add  constraint perfiles_clave_formato
  check (clave ~ '^[a-z][a-z0-9_]{1,30}$');

-- ---------- 2. Los perfiles que ya existian ----------
--  'admin' queda marcado del_sistema: es el unico que gestiona cuentas,
--  y sin el nadie podria volver a entrar a administrar.
insert into public.perfiles
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
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles drop constraint if exists profiles_role_fk;
alter table public.profiles add  constraint profiles_role_fk
  foreign key (role) references public.perfiles(clave)
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
     from public.perfiles f
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
alter table public.perfiles enable row level security;

--  Leer: cualquiera autenticado. La aplicacion lo necesita para saber que
--  mostrar, y en la definicion de un perfil no hay nada sensible.
drop policy if exists "perfiles_select" on public.perfiles;
create policy "perfiles_select" on public.perfiles
  for select to authenticated using (true);

--  Crear, modificar y borrar: solo quien gestiona cuentas.
drop policy if exists "perfiles_insert" on public.perfiles;
create policy "perfiles_insert" on public.perfiles
  for insert to authenticated with check (public.is_admin());

drop policy if exists "perfiles_update" on public.perfiles;
create policy "perfiles_update" on public.perfiles
  for update to authenticated using (public.is_admin());

drop policy if exists "perfiles_delete" on public.perfiles;
create policy "perfiles_delete" on public.perfiles
  for delete to authenticated using (public.is_admin());

-- ---------- 6. El seguro ----------
--  Un descuido en la pantalla de Perfiles no puede dejar al sistema sin
--  nadie capaz de administrarlo, ni borrar un perfil de sistema.
create or replace function public.proteger_perfiles()
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
    if (select count(*) from public.perfiles
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

drop trigger if exists perfiles_proteger on public.perfiles;
create trigger perfiles_proteger
  before update or delete on public.perfiles
  for each row execute function public.proteger_perfiles();

-- ============================================================
--  Comprobacion (una sola consulta: el editor muestra solo la ultima)
--
--    select p.orden, p.clave, p.nombre,
--           p.ve_oti, p.ve_opr, p.carga_oti, p.carga_opr,
--           p.gestiona_cuentas, p.usa_asistente, p.del_sistema,
--           (select count(*) from public.profiles u where u.role = p.clave) as cuentas
--    from public.perfiles p order by p.orden, p.clave;
--
--  Debe devolver 4 filas y 'admin' con cuentas >= 1.
-- ============================================================
