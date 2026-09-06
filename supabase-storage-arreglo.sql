-- ============================================================
--  Regla de acceso al bucket, reescrita sin patrones
--
--  La version anterior usaba  name like 'opr\_%'.  Depende de como
--  interprete la base la barra invertida (standard_conforming_strings)
--  y de que el guion bajo se escape bien. Comparar los cuatro primeros
--  caracteres no depende de nada de eso.
--
--  Ejecutar en: Supabase -> SQL Editor -> New query -> pegar -> Run
--  Es idempotente.
-- ============================================================

drop policy if exists "storage_select" on storage.objects;
create policy "storage_select" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'documentos'
    and ( public.is_admin() or left(name, 4) = 'opr_' )
  );

-- ============================================================
--  Comprobacion, ejecutando como el usuario que falla no es posible
--  desde el SQL Editor; se verifica en la aplicacion:
--    - entrar como Especialista y abrir un documento de Normativos OPR
--    - entrar como Administrador y abrir uno de Normativa base
--
--  Si tras esto el Especialista sigue viendo "Object not found", el
--  archivo no esta en el bucket: ver diagnostico-archivos.sql, consulta 3.
-- ============================================================
