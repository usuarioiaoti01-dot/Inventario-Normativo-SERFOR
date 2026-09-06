-- ============================================================
--  Diagnostico: "No se pudo abrir el archivo: Object not found"
--
--  Ese mensaje NO distingue dos causas muy distintas: Supabase Storage
--  responde lo mismo si el archivo no existe que si una regla de acceso
--  lo oculta. Estas consultas las separan.
--
--  Ejecutar como ADMINISTRADOR en: Supabase -> SQL Editor -> New query -> Run
--  (el SQL Editor no pasa por RLS, asi que ve todo lo que hay de verdad)
-- ============================================================

-- ---------- 1. ¿Cuantos archivos hay realmente en el bucket? ----------
--  Esperado: 354 en total y 231 con prefijo opr_
select
  count(*)                                          as archivos_en_bucket,
  count(*) filter (where left(name,4) = 'opr_')     as del_lote_opr,
  count(*) filter (where left(name,4) <> 'opr_')    as de_normativa_base
from storage.objects
where bucket_id = 'documentos';

-- ---------- 2. ¿Esta el archivo concreto que fallo? ----------
select name, created_at, (metadata->>'size')::bigint as bytes
from storage.objects
where bucket_id = 'documentos'
  and name in (
    'opr_rgg_n_d000025_2026_midagri_serfor_gg_resolucion_101.pdf',
    'opr_rgg_n_d000025_2026_midagri_serfor_gg_documento_100.pdf'
  );
--  Si devuelve 2 filas -> el archivo SI esta: el problema es la regla de acceso.
--  Si devuelve 0 filas -> el archivo NO se subio: hay que resubir el lote.

-- ---------- 3. Filas de la tabla que NO tienen su archivo en el bucket ----------
--  Esta es la lista de documentos que darian "Object not found" a cualquiera.
select d.archivo, d.titulo
from public.normativos_opr d
left join storage.objects o
       on o.bucket_id = 'documentos' and o.name = d.archivo
where o.id is null
order by d.archivo;

-- ---------- 4. Comprobar la regla de acceso del Especialista ----------
--  Debe devolver true para los tres primeros y false para el ultimo.
select
  'opr_ejemplo.pdf'  like 'opr\_%'  as opr_coincide,
  ('opr_rgg_n_d000025_2026_midagri_serfor_gg_resolucion_101.pdf' like 'opr\_%')
                                    as el_que_fallo_coincide,
  left('opr_rgg_n_d000025_2026_midagri_serfor_gg_resolucion_101.pdf',4) = 'opr_'
                                    as con_left_coincide,
  'directiva_general.pdf' like 'opr\_%' as base_no_coincide;

-- ---------- 5. Politicas activas sobre el bucket ----------
select policyname, cmd, roles::text, qual
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
order by policyname;
