-- ============================================================
--  Inventario Normativo SERFOR — Version 2.0
--  Cambios de base que piden las observaciones de OPR
--  (OBS_PROTOTIPO - Recomendaciones OPR, 15 de setiembre de 2026)
--
--  SOLO PARA LA VERSION 2.0. La 1.0 sigue funcionando con este mismo
--  esquema: todo lo de aqui ANADE, no quita ni cambia lo existente, de
--  modo que las dos publicaciones conviven sobre la misma base.
--
--  Ejecutar en: Supabase -> SQL Editor -> New query -> pegar -> Run
--  Es idempotente.
-- ============================================================

-- ---------- 1. Organo / UO Proponente (diapositivas 1, 2 y 7) ----------
--  OPR lo pide tres veces, es su prioridad. Columna nueva en ambas tablas.
alter table public.documentos      add column if not exists organo text;
alter table public.normativos_opr  add column if not exists organo text;

create index if not exists documentos_organo_idx     on public.documentos(organo);
create index if not exists normativos_opr_organo_idx on public.normativos_opr(organo);

--  Relleno automatico desde el prefijo de la resolucion. OJO: esto da el
--  organo que EMITE la resolucion, que no siempre es el que PROPONE la
--  norma. Se deja como punto de partida y el campo es editable; los que no
--  se puedan deducir quedan en NULL para completarlos a mano.
update public.normativos_opr set organo = 'Gerencia General'
  where organo is null and carpeta ~ '^\s*RGG\s*N';
update public.normativos_opr set organo = 'Dirección Ejecutiva'
  where organo is null and carpeta ~ '^\s*RDE\s*N';
update public.normativos_opr set organo = 'Secretaría General'
  where organo is null and carpeta ~ '^\s*RSG\s*N';
--  RD, RCE y los 116 sin resolucion asociada NO se tocan: no hay forma
--  honesta de deducirlos y es preferible el vacio a un dato inventado.

-- ---------- 2. Version Word del documento (diapositiva 4) ----------
--  Los .docx todavia no existen (hay 354 PDF y ningun Word). Se construye
--  la capacidad y queda vacia: el boton de descarga en Word solo aparecera
--  en los documentos que lleguen a tenerlo.
alter table public.documentos      add column if not exists archivo_word text;
alter table public.normativos_opr  add column if not exists archivo_word text;
alter table public.documentos      add column if not exists kb_word int;
alter table public.normativos_opr  add column if not exists kb_word int;

-- ---------- 3. Estado "Modificación" y a que norma modifica (diap. 7) ----------
--  OPR pide renombrar "Modificada" por "Modificación", y que al elegirlo se
--  pueda enlazar con la resolucion del documento vigente que se modifica.
update public.documentos     set estado = 'Modificación' where estado = 'Modificada';
update public.normativos_opr set estado = 'Modificación' where estado = 'Modificada';

alter table public.documentos      add column if not exists modifica_a text;
alter table public.normativos_opr  add column if not exists modifica_a text;

comment on column public.normativos_opr.modifica_a is
  'Carpeta (numero de resolucion) de la norma vigente que este documento modifica.';

-- ---------- 4. Nombres formales de las resoluciones (diapositivas 2 y 3) ----------
--  En el desplegable se veia el nombre del ARCHIVO ("Resolucion - 8256345-
--  rgg-000024-2026-gg") en vez del numero formal. Para las partes de tipo
--  Resolucion el numero formal ya esta guardado en 'carpeta', asi que esto
--  se arregla solo y al completo.
update public.normativos_opr
   set titulo = carpeta
 where parte = 'Resolucion' and carpeta is not null and carpeta <> ''
   and titulo <> carpeta;

update public.documentos
   set titulo = carpeta
 where parte = 'Resolucion' and carpeta is not null and carpeta <> ''
   and titulo <> carpeta;

--  Los documentos normativos (parte = 'Documento') NO se tocan: su numero
--  formal no esta en ningun campo y habria que extraerlo del PDF. Queda
--  pendiente y se corrige a mano o con una pasada posterior.

-- ---------- 5. Los "expedientes" se presentan como los demas (diap. 3) ----------
--  Son 25 PDF que contienen resolucion y directiva juntas. No se pueden
--  separar por software. Se marcan para que la pantalla los muestre
--  agrupados, indicando que contienen un solo archivo.
update public.normativos_opr
   set titulo = carpeta || ' — expediente completo'
 where parte = 'Expediente' and carpeta is not null and carpeta <> ''
   and titulo not like '% — expediente completo';

-- ---------- 6. Comprobacion ----------
--    select 'organo'        as campo, count(*) filter (where organo is not null)        || ' de ' || count(*) as valor from public.normativos_opr
--    union all
--    select 'word',                   count(*) filter (where archivo_word is not null)  || ' de ' || count(*) from public.normativos_opr
--    union all
--    select 'modificacion',           count(*) filter (where estado = 'Modificación')   || ' de ' || count(*) from public.normativos_opr
--    union all
--    select 'resoluciones con nombre formal',
--           count(*) filter (where parte = 'Resolucion' and titulo = carpeta) || ' de ' ||
--           count(*) filter (where parte = 'Resolucion') from public.normativos_opr;
-- ============================================================
