-- ============================================================
--  Comprobacion de supabase-carga-por-perfil.sql
--
--  Una SOLA consulta: el editor de Supabase muestra unicamente el
--  resultado de la ultima sentencia, asi que todo va junto.
--
--  Pegar en: Supabase -> SQL Editor -> New query -> Run
-- ============================================================
select * from (
  -- 1. Las cinco politicas que instala el script
  select 1 as orden,
         'politica' as revision,
         tablename || ' / ' || policyname || ' (' || cmd || ')' as detalle,
         case when policyname in ('doc_insert','opr_insert','storage_insert',
                                  'storage_delete','storage_update')
              then 'OK' else 'sobra?' end as estado
  from pg_policies
  where (schemaname='public'  and tablename in ('documentos','normativos_opr') and cmd='INSERT')
     or (schemaname='storage' and tablename='objects' and cmd in ('INSERT','DELETE','UPDATE'))

  union all
  -- 2. Las funciones de las que dependen esas politicas
  select 2,
         'funcion',
         p.proname || '()',
         'existe'
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname='public' and p.proname in ('is_admin','ve_opr','ve_oti','rol_actual')

  union all
  -- 3. Riesgo conocido: storage_delete se apoya en objects.owner.
  --    Si Supabase ya dejo de llenar esa columna, el borrado de un
  --    archivo huerfano fallara para quien no sea administrador.
  select 3,
         'columna owner',
         count(*) filter (where owner is not null)::text || ' de ' || count(*)::text
           || ' objetos con owner no nulo',
         case when count(*)=0 then 'bucket vacio'
              when count(*) filter (where owner is not null)=0 then 'ATENCION: owner siempre nulo'
              else 'OK' end
  from storage.objects where bucket_id='documentos'
) t order by orden, detalle;
