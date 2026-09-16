-- ============================================================
--  Inventario Normativo SERFOR — Rol 'lector' (solo lectura)
--
--  Para que otra aplicacion consulte el catalogo sin poder
--  modificarlo. Caso concreto: el Analisis Cualitativo Documental
--  (SACD) trae fichas y archivos del inventario.
--
--  El rol 'lector':
--    LEE   las dos tablas y descarga del bucket
--    NO    carga, ni modifica, ni borra, ni ve la gestion de cuentas
--
--  OJO: hasta ahora 've_opr()' y 've_oti()' significaban a la vez
--  "puede ver" y "puede cargar", porque coincidian. Con un rol que
--  solo lee, dejan de coincidir: este script separa las dos ideas.
--
--  Requiere supabase-tres-perfiles.sql y supabase-carga-por-perfil.sql.
--  Ejecutar en: Supabase -> SQL Editor -> New query -> pegar -> Run
--  Es idempotente.
-- ============================================================

-- ---------- 1. Admitir el nuevo rol ----------
--  La restriccion anterior solo aceptaba tres valores.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add  constraint profiles_role_check
  check (role in ('admin','especialista','normas_oti','lector'));

-- ---------- 2. Quien VE cada conjunto ----------
--  Se anade 'lector' a la lectura de ambos.
create or replace function public.ve_opr()
returns boolean language sql security definer stable set search_path = public as $$
  select coalesce(public.rol_actual() in ('admin','especialista','lector'), false);
$$;

create or replace function public.ve_oti()
returns boolean language sql security definer stable set search_path = public as $$
  select coalesce(public.rol_actual() in ('admin','normas_oti','lector'), false);
$$;

-- ---------- 3. Quien puede CARGAR en cada conjunto ----------
--  Funciones nuevas, deliberadamente SIN 'lector'. Si en el futuro
--  se agrega otro perfil de consulta, basta con no incluirlo aqui.
create or replace function public.carga_opr()
returns boolean language sql security definer stable set search_path = public as $$
  select coalesce(public.rol_actual() in ('admin','especialista'), false);
$$;

create or replace function public.carga_oti()
returns boolean language sql security definer stable set search_path = public as $$
  select coalesce(public.rol_actual() in ('admin','normas_oti'), false);
$$;

grant execute on function public.carga_opr() to authenticated;
grant execute on function public.carga_oti() to authenticated;

-- ---------- 4. Repuntar las politicas de ALTA ----------
--  Antes miraban ve_*(); ahora miran carga_*(). Sin este paso el
--  'lector' podria insertar filas, que es justo lo que no se quiere.
drop policy if exists "doc_insert" on public.documentos;
create policy "doc_insert" on public.documentos
  for insert to authenticated with check (public.carga_oti());

drop policy if exists "opr_insert" on public.normativos_opr;
create policy "opr_insert" on public.normativos_opr
  for insert to authenticated with check (public.carga_opr());

drop policy if exists "storage_insert" on storage.objects;
create policy "storage_insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'documentos'
    and (
      public.is_admin()
      or (public.carga_opr() and left(name, 4) =  'opr_')
      or (public.carga_oti() and left(name, 4) <> 'opr_')
    )
  );

--  La lectura del bucket no cambia de forma, pero al haber cambiado
--  ve_*() el 'lector' ya queda incluido: descarga de ambos conjuntos.

-- ============================================================
--  Comprobacion (una sola consulta: el editor solo muestra la ultima)
--
--    select 'politica' as que, tablename || ' / ' || policyname || ' (' || cmd || ')' as detalle
--    from pg_policies
--    where (schemaname='public'  and tablename in ('documentos','normativos_opr'))
--       or (schemaname='storage' and tablename='objects')
--    union all
--    select 'cuenta', email || ' -> ' || role from public.profiles order by 1,2;
-- ============================================================
