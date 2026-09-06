-- ============================================================
--  Reglas de la tabla profiles - diagnostico y reparacion
--
--  Sintoma: mmontoya entra y la aplicacion le pone rol "Especialista",
--  pero VE los 353 documentos, incluida la Normativa base que solo puede
--  leer un administrador.
--
--  Esa contradiccion solo tiene una explicacion: la base SI lo reconoce
--  como administrador - is_admin() es SECURITY DEFINER y se salta el RLS -
--  pero la aplicacion NO puede leer su fila de profiles, porque la politica
--  de lectura falta o fue reemplazada. Sin poder leerla, la app cae al
--  perfil minimo.
--
--  Ejecutar en: Supabase -> SQL Editor -> New query -> pegar -> Run
--  Es idempotente.
-- ============================================================

-- ---------- 1. Que politicas hay AHORA sobre profiles ----------
select policyname, cmd, roles::text, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'profiles'
order by policyname;

-- ---------- 2. Existe la fila y con que rol ----------
--  El SQL Editor no pasa por RLS: aqui se ve la verdad.
select id, email, role, debe_cambiar_clave, created_at
from public.profiles
order by role, email;

-- ---------- 3. Reparacion: dejar las reglas como deben estar ----------

alter table public.profiles enable row level security;

-- Cada quien lee su propio perfil. Sin esto la app no sabe que rol tiene.
drop policy if exists "perfil_propio_select" on public.profiles;
create policy "perfil_propio_select" on public.profiles
  for select to authenticated
  using (auth.uid() = id);

-- Un administrador puede leer todos (util para la pestaña Usuarios)
drop policy if exists "perfil_admin_select" on public.profiles;
create policy "perfil_admin_select" on public.profiles
  for select to authenticated
  using (public.is_admin());

-- Cada quien edita su propio perfil. El cambio de ROL lo impide el
-- disparador proteger_rol(), no esta politica.
drop policy if exists "perfil_propio_update" on public.profiles;
create policy "perfil_propio_update" on public.profiles
  for update to authenticated
  using (auth.uid() = id);

-- ---------- 4. Comprobacion ----------
select policyname, cmd from pg_policies
where schemaname = 'public' and tablename = 'profiles'
order by policyname;
--  Esperado: perfil_admin_select (SELECT), perfil_propio_select (SELECT),
--            perfil_propio_update (UPDATE)
--
--  Y despues, en la aplicacion: mmontoya debe ver el rotulo ADMINISTRADOR
--  y las pestañas "Nuevos registros" y "Usuarios".
--
--  Si el rotulo dice "sin perfil" sobre fondo rojo, la consulta sigue
--  fallando y el aviso de la propia app indica el motivo exacto.
