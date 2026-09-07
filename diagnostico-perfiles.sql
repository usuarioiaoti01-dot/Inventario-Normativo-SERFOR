-- ============================================================
--  Diagnostico: el perfil no cambia a Normas OTI
--
--  UNA SOLA consulta a proposito: el SQL Editor de Supabase muestra
--  unicamente el resultado de la ultima sentencia, asi que un diagnostico
--  repartido en varias se pierde.
--
--  Ejecutar en: Supabase -> SQL Editor -> New query -> Run
-- ============================================================

with comprobaciones as (
  select 1 as orden, 'funcion ve_oti' as comprobacion,
         coalesce((select 'existe' from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                   where n.nspname = 'public' and p.proname = 've_oti' limit 1), '>>> FALTA') as resultado
  union all
  select 2, 'funcion ve_opr',
         coalesce((select 'existe' from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                   where n.nspname = 'public' and p.proname = 've_opr' limit 1), '>>> FALTA')
  union all
  select 3, 'funcion rol_actual',
         coalesce((select 'existe' from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                   where n.nspname = 'public' and p.proname = 'rol_actual' limit 1), '>>> FALTA')
  union all
  select 4, 'profiles_guard (NO deberia existir)',
         coalesce((select '>>> PRESENTE: es el que bloquea el cambio de rol'
                   from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                   where n.nspname = 'public' and p.proname = 'profiles_guard' limit 1), 'retirado, ok')
  union all
  select 5, 'disparadores en profiles',
         coalesce((select string_agg(tgname, ', ') from pg_trigger
                   where tgrelid = 'public.profiles'::regclass and not tgisinternal), 'ninguno')
  union all
  select 6, 'restriccion de roles validos',
         coalesce((select pg_get_constraintdef(oid) from pg_constraint
                   where conname = 'profiles_role_valido' limit 1), '>>> FALTA')
  union all
  select 7, 'lectura de documentos (Normas OTI)',
         coalesce((select qual from pg_policies
                   where schemaname = 'public' and tablename = 'documentos' and cmd = 'SELECT' limit 1), '>>> FALTA')
  union all
  select 8, 'lectura de normativos_opr',
         coalesce((select qual from pg_policies
                   where schemaname = 'public' and tablename = 'normativos_opr' and cmd = 'SELECT' limit 1), '>>> FALTA')
  union all
  select 9, 'lectura del bucket',
         coalesce((select qual from pg_policies
                   where schemaname = 'storage' and tablename = 'objects' and policyname = 'storage_select' limit 1), '>>> FALTA')
  union all
  select 10, 'perfiles registrados',
         (select string_agg(email || ' = ' || role, '  |  ' order by role, email) from public.profiles)
)
select comprobacion, resultado from comprobaciones order by orden;

-- ============================================================
--  COMO LEER EL RESULTADO
--
--  Si alguna linea dice ">>> FALTA", o si profiles_guard sale
--  ">>> PRESENTE":
--      supabase-tres-perfiles.sql NO se aplico. Ejecutalo completo.
--
--  Si todo existe y irengifo sigue en 'especialista':
--      el cambio se intento y fallo. Hazlo desde la pestaña Usuarios y
--      copia el mensaje de error que muestre la aplicacion.
-- ============================================================
