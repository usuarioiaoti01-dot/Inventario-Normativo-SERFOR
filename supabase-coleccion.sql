-- ============================================================
--  Inventario Normativo SERFOR — Colecciones de documentos
--  Agrega el campo 'coleccion' para diferenciar lotes de normativa
--  (los 122 documentos ya cargados quedan en 'Normativa base').
--
--  Ejecutar UNA vez en:  Supabase → SQL Editor → New query → pegar → Run
--  Es idempotente: se puede volver a ejecutar sin efectos secundarios.
-- ============================================================

alter table public.documentos
  add column if not exists coleccion text not null default 'Normativa base';

create index if not exists documentos_coleccion_idx on public.documentos(coleccion);

-- Por si alguna fila antigua quedo sin coleccion
update public.documentos set coleccion = 'Normativa base'
  where coleccion is null or btrim(coleccion) = '';

-- Comprobacion: cuantos documentos hay por coleccion
--   select coleccion, count(*) from public.documentos group by coleccion order by 2 desc;
