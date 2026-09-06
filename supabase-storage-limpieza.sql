-- ============================================================
--  Limpieza de las reglas de lectura del bucket 'documentos'
--
--  Habia tres politicas de SELECT solapadas sobre storage.objects:
--
--    storage_select_admin  bucket_id='documentos' AND is_admin()
--    storage_select_opr    bucket_id='documentos' AND name LIKE 'documentos/op...'   <-- ROTA
--    storage_select        (la correcta, recreada despues)
--
--  La segunda comparaba contra 'documentos/opr_...', pero el nombre del
--  objeto NO incluye el nombre del bucket: es 'opr_xxx.pdf' a secas. Por eso
--  no casaba con ningun archivo y el Especialista recibia
--  "Object not found" en todos los documentos.
--
--  Aqui se dejan las cosas en UNA sola politica de lectura, facil de leer:
--    el administrador ve todo; el especialista, solo los archivos 'opr_'.
--
--  Ejecutar en: Supabase -> SQL Editor -> New query -> pegar -> Run
--  Es idempotente.
-- ============================================================

-- Fuera las solapadas
drop policy if exists "storage_select_opr"   on storage.objects;
drop policy if exists "storage_select_admin" on storage.objects;

-- Una unica regla de lectura
drop policy if exists "storage_select" on storage.objects;
create policy "storage_select" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'documentos'
    and ( public.is_admin() or left(name, 4) = 'opr_' )
  );

-- ============================================================
--  Comprobacion: deben quedar cuatro politicas, una por operacion.
--    select policyname, cmd from pg_policies
--    where schemaname='storage' and tablename='objects' order by policyname;
--
--  Esperado:
--    storage_delete_admin  DELETE
--    storage_insert_admin  INSERT
--    storage_select        SELECT
--    storage_update_admin  UPDATE
--
--  Y despues, en la aplicacion:
--    - Especialista abre un documento de Normativos OPR  -> debe verse
--    - Especialista NO ve la pestaña Normativa base      -> correcto
--    - Administrador abre uno de Normativa base          -> debe verse
-- ============================================================
