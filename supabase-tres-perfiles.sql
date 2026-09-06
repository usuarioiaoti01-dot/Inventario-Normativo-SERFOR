-- ============================================================
--  Inventario Normativo SERFOR — Tres perfiles de acceso
--
--    admin         "Administrador"  ve TODO y gestiona cuentas.
--    especialista  "Especialista"   ve SOLO Normativos OPR.
--    normas_oti    "Normas OTI"     ve SOLO Normas OTI (la normativa base).
--
--  Cada perfil ve su conjunto y ningun otro. El alcance se hace cumplir
--  aqui, en la base, no escondiendo botones en el navegador.
--
--  Ejecutar en: Supabase -> SQL Editor -> New query -> pegar -> Run
--  Es idempotente.
-- ============================================================

-- ---------- 1. Normalizar lo que ya hay ----------
--  Si el rol se escribio a mano puede haber quedado 'Admin', 'Administrador'
--  o con espacios. is_admin() y la Edge Function comparan contra 'admin'
--  EXACTO, asi que esas variantes dejan al usuario sin permisos aunque la
--  interfaz parezca correcta. Se unifican antes de nada.
alter table public.profiles drop constraint if exists profiles_role_valido;

update public.profiles set role = 'admin'
  where lower(btrim(role)) in ('admin','administrador','administrator');
update public.profiles set role = 'especialista'
  where lower(btrim(role)) in ('especialista','lector','profesional');
update public.profiles set role = 'normas_oti'
  where lower(btrim(role)) in ('normas_oti','normas oti','oti');

-- Cualquier valor no reconocido pasa al perfil mas restringido
update public.profiles set role = 'especialista'
  where role not in ('admin','especialista','normas_oti');

alter table public.profiles add constraint profiles_role_valido
  check (role in ('admin','especialista','normas_oti'));

-- ---------- 2. Funciones de rol, tolerantes a la grafia ----------
create or replace function public.rol_actual()
returns text language sql security definer stable set search_path = public as $$
  select lower(btrim(role)) from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean language sql security definer stable set search_path = public as $$
  select coalesce(public.rol_actual() = 'admin', false);
$$;

-- ¿Puede el usuario actual ver este conjunto?
create or replace function public.ve_opr()
returns boolean language sql security definer stable set search_path = public as $$
  select coalesce(public.rol_actual() in ('admin','especialista'), false);
$$;

create or replace function public.ve_oti()
returns boolean language sql security definer stable set search_path = public as $$
  select coalesce(public.rol_actual() in ('admin','normas_oti'), false);
$$;

grant execute on function public.rol_actual() to authenticated;
grant execute on function public.is_admin()   to authenticated;
grant execute on function public.ve_opr()     to authenticated;
grant execute on function public.ve_oti()     to authenticated;

-- ---------- 3. Alcance de cada conjunto ----------
--  Normas OTI (tabla documentos): administrador y perfil Normas OTI.
drop policy if exists "doc_select" on public.documentos;
create policy "doc_select" on public.documentos
  for select to authenticated using (public.ve_oti());

--  Normativos OPR: administrador y especialista.
drop policy if exists "opr_select" on public.normativos_opr;
create policy "opr_select" on public.normativos_opr
  for select to authenticated using (public.ve_opr());

-- ---------- 4. Alcance de los archivos ----------
--  Los PDF de ambos conjuntos comparten el bucket 'documentos'. Se distinguen
--  por el prefijo 'opr_'. Sin esta regla, un especialista podria pedir la URL
--  firmada de un PDF de Normas OTI adivinando su nombre.
--  Se dejan fuera las politicas solapadas que aparecieron desde el panel.
drop policy if exists "storage_select"       on storage.objects;
drop policy if exists "storage_select_opr"   on storage.objects;
drop policy if exists "storage_select_admin" on storage.objects;

create policy "storage_select" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'documentos'
    and (
      public.is_admin()
      or (public.ve_opr() and left(name, 4) =  'opr_')
      or (public.ve_oti() and left(name, 4) <> 'opr_')
    )
  );

-- ---------- 5. Perfiles: lectura y escritura ----------
alter table public.profiles enable row level security;

drop policy if exists "perfil_propio_select" on public.profiles;
create policy "perfil_propio_select" on public.profiles
  for select to authenticated using (auth.uid() = id);

drop policy if exists "perfil_admin_select" on public.profiles;
create policy "perfil_admin_select" on public.profiles
  for select to authenticated using (public.is_admin());

drop policy if exists "perfil_propio_update" on public.profiles;
create policy "perfil_propio_update" on public.profiles
  for update to authenticated using (auth.uid() = id);

-- ============================================================
--  Comprobacion:
--    select role, count(*) from public.profiles group by role;
--
--  Y en la aplicacion, con una cuenta de cada perfil:
--    Administrador -> pestañas Normas OTI (122) y Normativos OPR (231)
--    Especialista  -> solo Normativos OPR, sin barra de pestañas
--    Normas OTI    -> solo Normas OTI, sin barra de pestañas
--  En los tres casos los documentos deben ABRIRSE, no solo listarse.
-- ============================================================
