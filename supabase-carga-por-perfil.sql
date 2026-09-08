-- ============================================================
--  Inventario Normativo SERFOR — Cada perfil carga en SU conjunto
--
--  Hasta ahora solo el administrador podia subir documentos. Ahora:
--
--    admin         sube a los dos conjuntos
--    especialista  sube SOLO a Normativos OPR
--    normas_oti    sube SOLO a Normas OTI
--
--  Nadie puede escribir en el conjunto que no le corresponde, y eso se
--  hace cumplir aqui: aunque alguien manipule el navegador, la base lo
--  rechaza.
--
--  Requiere haber ejecutado antes supabase-tres-perfiles.sql, de donde
--  salen las funciones ve_opr() y ve_oti().
--
--  Ejecutar en: Supabase -> SQL Editor -> New query -> pegar -> Run
--  Es idempotente.
-- ============================================================

-- ---------- 1. Alta de filas en cada tabla ----------
--  Normas OTI (tabla documentos): administrador y perfil Normas OTI.
drop policy if exists "doc_insert_admin" on public.documentos;
drop policy if exists "doc_insert"       on public.documentos;
create policy "doc_insert" on public.documentos
  for insert to authenticated with check (public.ve_oti());

--  Normativos OPR: administrador y especialista.
drop policy if exists "opr_insert_admin" on public.normativos_opr;
drop policy if exists "opr_insert"       on public.normativos_opr;
create policy "opr_insert" on public.normativos_opr
  for insert to authenticated with check (public.ve_opr());

--  Modificar y borrar siguen siendo cosa del administrador: aqui solo se
--  abre el ALTA. Quien se equivoque al subir debe pedir la correccion.
--  (Si mas adelante se quiere permitir borrar lo propio, hay que anadir
--   una columna con el autor y filtrar por ella.)

-- ---------- 2. Subida de archivos al bucket ----------
--  El prefijo 'opr_' decide a que conjunto pertenece el archivo, asi que
--  la regla de escritura usa el mismo criterio que la de lectura: nadie
--  puede colocar un archivo en el conjunto ajeno.
drop policy if exists "storage_insert_admin" on storage.objects;
drop policy if exists "storage_insert"       on storage.objects;
create policy "storage_insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'documentos'
    and (
      public.is_admin()
      or (public.ve_opr() and left(name, 4) =  'opr_')
      or (public.ve_oti() and left(name, 4) <> 'opr_')
    )
  );

-- ---------- 3. Deshacer una subida a medias ----------
--  Si el archivo sube pero la fila falla, la aplicacion borra el archivo
--  para no dejarlo huerfano. Para que eso funcione sin dar permiso de
--  borrado general, cada quien puede borrar UNICAMENTE lo que subio.
drop policy if exists "storage_delete_admin" on storage.objects;
drop policy if exists "storage_delete"       on storage.objects;
create policy "storage_delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'documentos'
    and ( public.is_admin() or owner = auth.uid() )
  );

--  Reemplazar un archivo existente sigue reservado al administrador
drop policy if exists "storage_update_admin" on storage.objects;
drop policy if exists "storage_update"       on storage.objects;
create policy "storage_update" on storage.objects
  for update to authenticated
  using (bucket_id = 'documentos' and public.is_admin());

-- ============================================================
--  Comprobacion:
--    select tablename, policyname, cmd
--    from pg_policies
--    where (schemaname='public'  and tablename in ('documentos','normativos_opr'))
--       or (schemaname='storage' and tablename='objects')
--    order by tablename, cmd, policyname;
--
--  Y en la aplicacion, con una cuenta de cada perfil:
--    Especialista -> "Nuevos registros" visible; solo puede guardar en
--                    Normativos OPR
--    Normas OTI   -> "Nuevos registros" visible; solo puede guardar en
--                    Normas OTI
--    Ninguno de los dos ve la pestana "Usuarios".
-- ============================================================
