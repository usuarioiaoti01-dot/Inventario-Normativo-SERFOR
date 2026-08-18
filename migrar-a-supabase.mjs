// ============================================================
//  Migración del inventario local → Supabase
//  Sube los PDF de documentos/ al Storage y carga la metadata en la tabla.
//
//  Requisitos: Node 18 o superior (trae fetch incorporado).
//
//  Uso (PowerShell):
//    $env:SUPABASE_URL="https://TU-PROYECTO.supabase.co"
//    $env:SUPABASE_SERVICE_ROLE_KEY="TU_SERVICE_ROLE_KEY"
//    node migrar-a-supabase.mjs
//
//  ⚠️ La service_role key es SECRETA. Úsala solo aquí, en tu equipo.
//     No la subas al servidor ni la pongas en config.js.
// ============================================================

import { readFile, readdir } from 'node:fs/promises';
import { join } from 'node:path';

const URL = process.env.SUPABASE_URL;
const KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BUCKET = 'documentos';

if (!URL || !KEY) {
  console.error('❌ Falta definir SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY como variables de entorno.');
  process.exit(1);
}

// ---- Leer el catálogo local (inventario.js) ----
const invText = await readFile('inventario.js', 'utf8');
const m = invText.match(/const\s+INVENTARIO\s*=\s*(\[[\s\S]*\]);?\s*$/);
if (!m) { console.error('❌ No se pudo leer INVENTARIO desde inventario.js'); process.exit(1); }
const inventario = JSON.parse(m[1]);
console.log(`📋 ${inventario.length} documentos en el catálogo local.`);

const h = (extra = {}) => ({ apikey: KEY, Authorization: `Bearer ${KEY}`, ...extra });

// ---- 1. Vaciar la tabla (sincronización completa) ----
process.stdout.write('🧹 Limpiando tabla documentos... ');
let r = await fetch(`${URL}/rest/v1/documentos?id=gt.0`, { method: 'DELETE', headers: h({ Prefer: 'return=minimal' }) });
console.log(r.ok ? 'ok' : `error ${r.status}`);

// ---- 2. Subir cada PDF al Storage + insertar fila ----
let subidos = 0, fallidos = 0;
for (const d of inventario) {
  const local = d.archivo.replace(/^documentos\//, '');   // nombre de archivo
  const path  = local;                                     // ruta dentro del bucket
  try {
    const bytes = await readFile(join('documentos', local));
    // Subir al Storage (con upsert)
    const up = await fetch(`${URL}/storage/v1/object/${BUCKET}/${encodeURIComponent(path)}`, {
      method: 'POST',
      headers: h({ 'Content-Type': 'application/pdf', 'x-upsert': 'true' }),
      body: bytes,
    });
    if (!up.ok && up.status !== 200) throw new Error(`storage ${up.status}: ${await up.text()}`);

    // Insertar fila
    const row = {
      tipo: d.tipo, titulo: d.titulo, entidad: d.entidad, anio: d.anio,
      estado: d.estado || 'Vigente', fecha: d.fecha, kb: d.kb,
      archivo: path, original: d.original,
    };
    const ins = await fetch(`${URL}/rest/v1/documentos`, {
      method: 'POST',
      headers: h({ 'Content-Type': 'application/json', Prefer: 'return=minimal' }),
      body: JSON.stringify(row),
    });
    if (!ins.ok) throw new Error(`insert ${ins.status}: ${await ins.text()}`);

    subidos++;
    if (subidos % 10 === 0) console.log(`   ...${subidos}/${inventario.length}`);
  } catch (e) {
    fallidos++;
    console.error(`   ⚠️  ${local}: ${e.message}`);
  }
}

console.log(`\n✅ Migración terminada. Subidos: ${subidos}  |  Fallidos: ${fallidos}`);
