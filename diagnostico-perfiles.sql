-- ============================================================
--  Diagnostico: el perfil no cambia a Normas OTI
--
--  Una sola consulta que dice si supabase-tres-perfiles.sql llego a
--  aplicarse. Si no, el disparador profiles_guard() sigue vivo y bloquea
--  el cambio de rol incluso a la Edge Function (que actua con
--  service_role, donde auth.uid() es NULL).
--
--  Ejecutar en: Supabase -> SQL Editor -> New query -> Run
-- ============================================================

select 'funcion ve_oti'          as comprobacion,
       coalesce((select 'existe' from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                 where n.nspname='public' and p.proname='ve_oti' limit 1), 'FALTA') as estado
union all
select 'funcion ve_opr',
       coalesce((select 'existe' from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                 where n.nspname='public' and p.proname='ve_opr' limit 1), 'FALTA')
union all
select 'funcion rol_actual',
       coalesce((select 'existe' from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                 where n.nspname='public' and p.proname='rol_actual' limit 1), 'FALTA')
union all
select 'disparador profiles_guard (NO deberia estar)',
       coalesce((select 'PRESENTE - es el que bloquea' from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                 where n.nspname='public' and p.proname='profiles_guard' limit 1), 'retirado, ok')
union all
select 'disparadores en profiles',
       coalesce((select string_agg(tgname, ', ') from pg_trigger
                 where tgrelid='public.profiles'::regclass and not tgisinternal), 'ninguno')
union all
select 'restriccion de roles validos',
       coalesce((select pg_get_constraintdef(oid) from pg_constraint
                 where conname='profiles_role_valido' limit 1), 'FALTA')
union all
select 'regla de lectura de documentos',
       coalesce((select qual from pg_policies
                 where schemaname='public' and tablename='documentos' and cmd='SELECT' limit 1), 'FALTA')
union all
select 'regla de lectura de normativos_opr',
       coalesce((select qual from pg_policies
                 where schemaname='public' and tablename='normativos_opr' and cmd='SELECT' limit 1), 'FALTA');

-- ---------- Y los roles tal como estan ----------
select email, role, quote_literal(role) as tal_cual
from public.profiles order by role, email;

-- ============================================================
--  COMO LEER EL RESULTADO
--
--  Si ve_oti / ve_opr / rol_actual dicen FALTA, o si profiles_guard
--  aparece PRESENTE:
--      -> supabase-tres-perfiles.sql NO se aplico. Ejecutalo completo.
--
--  Si todo existe y el rol de irengifo sigue siendo 'especialista':
--      -> el cambio de rol se intento y fallo. Cambialo desde la pestaña
--         Usuarios y copia el mensaje de error que muestre la aplicacion.
-- ============================================================
