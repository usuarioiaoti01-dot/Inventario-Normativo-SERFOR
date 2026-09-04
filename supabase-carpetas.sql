-- ============================================================
--  Inventario Normativo SERFOR — Normas con varios documentos
--
--  Una norma puede constar de varios PDF que se complementan:
--  la resolucion que la aprueba, el documento normativo en si,
--  sus anexos y el expediente. Estos dos campos permiten
--  agruparlos y mostrarlos anidados en la aplicacion:
--
--    carpeta  identifica la norma  (p. ej. 'RDE N° D000030-2023-MIDAGRI-SERFOR-DE')
--    parte    el papel del archivo (Resolucion | Documento | Anexo | Expediente)
--
--  Los documentos sueltos dejan 'carpeta' en NULL y se siguen
--  mostrando como una fila simple.
--
--  Ejecutar UNA vez en:  Supabase → SQL Editor → New query → pegar → Run
--  Es idempotente: se puede volver a ejecutar sin efectos secundarios.
-- ============================================================

alter table public.normativos_opr add column if not exists carpeta text;
alter table public.normativos_opr add column if not exists parte   text;

create index if not exists normativos_opr_carpeta_idx on public.normativos_opr(carpeta);

-- La misma estructura en la Normativa base, por si mas adelante se agrupa alli
alter table public.documentos add column if not exists carpeta text;
alter table public.documentos add column if not exists parte   text;

create index if not exists documentos_carpeta_idx on public.documentos(carpeta);

-- ============================================================
--  Orden de ejecucion para incorporar el lote "DOCUMENTOS COMPLEMENTO":
--
--    1) Este archivo                       (crea los dos campos)
--    2) actualizar-carpetas-opr.sql        (agrupa los que YA estaban cargados)
--    3) migrar-a-supabase.ps1 con
--       -Inventario "inventario-complemento.js" -Tabla "normativos_opr" -Anexar
--
--  Comprobacion:
--    select count(*) from public.normativos_opr;                        -- 231
--    select count(distinct carpeta) from public.normativos_opr
--      where carpeta is not null;                                       -- 135
-- ============================================================
