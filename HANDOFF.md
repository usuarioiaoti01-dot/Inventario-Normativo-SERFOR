# HANDOFF — Inventario Normativo SERFOR

> Documento de traspaso. Léelo completo antes de continuar el trabajo.
> Última actualización: 2026-08-18.

---

## 1. Objetivo

Aplicación web para **consultar, buscar, descargar y ampliar la normativa
institucional del SERFOR** (Servicio Nacional Forestal y de Fauna Silvestre, Perú),
con un **asistente de IA** que responde preguntas sobre el contenido de cada
documento. Inspirada en la página POI de la ATU (`transparencia.atu.gob.pe/PTE/POI/`),
pero con buscador, filtros, visor incrustado, acceso por usuario y asistente IA.

**Usuario/dueño:** Dirección/Oficina de TI (OTI) de SERFOR.
Contacto/admin: `mmontoya@serfor.gob.pe`.

---

## 2. Estado actual (funcionando)

- **Frontend estático** (HTML/JS, sin framework) conectado a **Supabase**
  (PostgreSQL + Storage + Auth). Funciona: login, inventario, buscador, filtros,
  visor de PDF, carga de nuevos documentos (solo admin) y asistente IA.
- **122 documentos** normativos migrados a Supabase (de 123; falló 1 por tamaño —
  ver Pendientes).
- **Asistente IA operativo** con la API de Claude vía Edge Function (probado y
  respondiendo con citas de página en documentos pequeños).
- **Colecciones (lotes) implementadas:** cada documento tiene un campo `coleccion`
  y el Inventario muestra una barra de pestañas *Todas | Normativa base | …* cuando
  hay más de una. Los 122 documentos ya cargados quedan en `Normativa base`.
  Falta ejecutar `supabase-coleccion.sql` en Supabase para crear el campo.
- **Lote OPR preparado (116 PDF, 148 MB):** 70 normas de SERFOR (47 lineamientos +
  23 directivas), todas vigentes, descargadas en `Documentos Normativos OPR/`,
  copiadas a `documentos/` con prefijo `opr_` y catalogadas en `inventario-opr.js`
  con la colección **`Lineamientos y Directivas OPR`**. Ninguna supera los 50 MB.
  **Falta subirlo a Supabase** (ver Pendientes).
- **Repo en GitHub** actualizado.
- **Aún NO publicado** en el servidor de SERFOR (paquete listo, ver Pendientes).

---

## 3. Datos clave (referencias)

| Dato | Valor |
|---|---|
| Carpeta del proyecto | `C:\Users\mmontoya\Desarrollo Claude\inventario-normativo` |
| Repo GitHub (privado) | `https://github.com/usuarioiaoti01-dot/Inventario-Normativo-SERFOR` |
| Proyecto Supabase (ref) | `armvuvoluoxspfjpefex` → `https://armvuvoluoxspfjpefex.supabase.co` |
| Región Supabase | us-east-1 |
| Usuario admin de la app | `mmontoya@serfor.gob.pe` (rol `admin` en tabla `profiles`) |
| Modelo de IA | `claude-haiku-4-5` (configurado en la Edge Function) |
| Edge Function | `preguntar` (secreto `ANTHROPIC_API_KEY`) |
| Carpeta fuente de los PDF | `C:\Documentos SERFOR\SERFOR\Documentos PDF\Base de Conocimiento Normas` |
| Entorno | Windows 11, PowerShell. **Node NO está instalado.** |

---

## 4. Arquitectura

```
Navegador (index.html + config.js + lib/supabase.js)
   ├─ Datos/PDF/Login  →  Supabase (Postgres, Storage privado, Auth)
   └─ Asistente IA     →  Edge Function "preguntar"  →  API de Claude (Haiku 4.5)
```

- **Metadata** de cada documento → tabla `public.documentos`.
- **PDF** → bucket **privado** `documentos` (se sirven con URLs firmadas temporales).
- **Acceso por usuario**: login obligatorio; roles `lector` y `admin` (tabla
  `profiles`). Solo `admin` sube documentos. Reglas en `supabase-setup.sql` (RLS).
- **Asistente**: la clave de Claude es secreta y vive SOLO en el secreto
  `ANTHROPIC_API_KEY` de la Edge Function; nunca en el navegador. La función
  verifica sesión, descarga el PDF con service role y consulta a Claude con citas
  de página. Documentos de **>100 páginas** → responde "DOCUMENTO GRANDE - TENGO
  LIMITADO A SOLO DOCUMENTOS DE 100 PAGINAS O MENOS".

---

## 5. Decisiones tomadas

1. **Supabase** como backend (Postgres + Storage + Auth) para hacer la app
   sostenible, multiusuario y con carga de documentos.
2. **Acceso controlado por admin** (nadie se auto-registra), **solo admins suben**
   documentos, **PDF privados** (URLs firmadas). Todas configurables.
3. **Asistente IA con la API de Claude (Anthropic)**, NO Chatbase. Se descartó
   Chatbase. Modelo **Haiku 4.5** (el más económico) por el saldo limitado.
4. **Alcance del asistente = Opción A**: responde sobre **un documento a la vez**.
   Pendiente Opción B (RAG sobre todo el conjunto). Ver Pendientes.
5. **Asistente como botón flotante** "Consulta Contenido" (abajo-derecha, mascota
   capibara, color ámbar), NO como pestaña.
6. **Librería de Supabase alojada localmente** (`lib/supabase.js`), no desde CDN,
   para no depender de un CDN externo en el servidor de SERFOR.
7. **Migración con service_role JWT legacy** (no la clave nueva `sb_secret_`, que da
   401 en las llamadas REST).
8. **Lotes de normativa = campo `coleccion`**, no fecha de carga: es explícito,
   no envejece solo y sirve para futuros lotes. La barra de pestañas vive **dentro**
   de Inventario (no como pestaña principal aparte) para reutilizar buscador,
   filtros, visor y asistente. Se oculta sola si solo hay una colección.
9. **Títulos del lote OPR:** salen del índice oficial (denominación + norma de
   aprobación), no del nombre del archivo. Cuando una norma tiene varios PDF
   (resolución + documento + anexo), la parte va **delante** en corchetes
   — `[Resolucion] …`, `[Lineamiento] …`, `[Anexo] …` — porque las
   denominaciones llegan a 300 caracteres y al final no se distinguirían.
   En la lista los títulos se recortan a 3 líneas (texto completo en el tooltip
   y en la ficha).
10. **UI:** columna de directivas angosta (`0.6fr`) y documento grande (`1.4fr`);
   denominación "Inventario Normativo SERFOR"; visor de PDF sin panel de miniaturas
   (`#navpanes=0&pagemode=none&view=FitH`).

---

## 6. Archivos generados (en la carpeta del proyecto)

| Archivo / carpeta | Propósito | ¿Va al servidor? |
|---|---|---|
| `index.html` | La aplicación completa (login, inventario, visor, asistente) | ✅ Sí |
| `config.js` | URL + clave **pública** (anon/publishable) de Supabase | ✅ Sí |
| `lib/supabase.js` | Librería de Supabase (local) | ✅ Sí |
| `capibara-serfor.png` | Imagen del botón del asistente | ✅ Sí |
| `supabase/functions/preguntar/index.ts` | Edge Function del asistente (Deno) | ❌ Se despliega en Supabase |
| `supabase-setup.sql` | Esquema BD + RLS + bucket (ejecutar 1 vez) | ❌ Solo instalación |
| `supabase-coleccion.sql` | Agrega el campo `coleccion` a una base ya creada (idempotente) | ❌ Solo instalación |
| `migrar-a-supabase.ps1` | Migra los PDF locales a Supabase (PowerShell) | ❌ Solo migración |
| `migrar-a-supabase.mjs` | Igual, versión Node (alternativa) | ❌ Solo migración |
| `generar-inventario.ps1` | Genera el catálogo; con `-Coleccion` / `-Anexar` arma lotes nuevos | ❌ Solo mantenimiento |
| `descargar_documentos_normativos_opr.ps1` | Descarga los 116 PDF del lote OPR desde `cdn.www.gob.pe` (reintentable) | ❌ Solo migración |
| `generar-inventario-opr.ps1` | Catálogo del lote OPR desde el índice oficial (no adivina por nombre de archivo) | ❌ Solo migración |
| `Documentos Normativos OPR/` | Índice (xlsx + csv), LEEME y los 116 PDF descargados | ❌ (PDF excluidos de git) |
| `inventario-opr.js` | Catálogo del lote OPR, listo para migrar | ❌ Solo migración |
| `inventario.js` | Catálogo local (fuente de la migración) | ❌ Solo migración |
| `documentos/` | 123 PDF locales (~272 MB) | ❌ (viven en Supabase; excluidos de git) |
| `publicar/` | Paquete listo para copiar a IIS (index.html, config.js, lib/, imagen, web.config) | ✅ Este es lo que se copia |
| `LEEME.md` | Guía completa de instalación, uso, asistente y publicación | ❌ Referencia |
| `HANDOFF.md` | Este documento | ❌ Referencia |
| `.gitignore` | Excluye `documentos/` del repo | — |

> **`documentos/` está excluido de git** (`.gitignore`) por tamaño; los PDF viven
> en Supabase Storage.

---

## 7. Criterios de redacción y convenciones

**Idioma y tono**
- Responder e interactuar **en español**, tono institucional y claro (contexto
  gestión pública peruana: Ley N° 32069 de Contrataciones, CEPLAN, etc.).
- Ser conciso y accionable: recomendar, no listar exhaustivamente. Confirmar antes
  de acciones difíciles de revertir.

**Seguridad (crítico)**
- **NUNCA** poner claves secretas en el frontend ni en el repo. En `config.js`
  solo va la clave **pública** (anon/publishable). La clave de Claude
  (`sk-ant-...`) y la `service_role` viven solo en secretos del servidor
  (Edge Function / línea de comandos), nunca versionadas.
- Antes de cada `git push`, **escanear** que no se cuelen `sk-ant-`, `sb_secret_`
  ni JWT `service_role` (`eyJ...`) en archivos versionados.
- Las claves `service_role`/`sb_secret` quedaron **visibles en capturas** del chat →
  ver Pendientes (rotarlas).

**Git**
- Mensajes de commit **en una sola línea** (`git commit -m "..."`). Los mensajes
  multilínea con heredoc **activaron un bloqueo de seguridad del entorno** — evitar.
- Flujo: `cd` a la carpeta → `git add -A` → `git commit -m "..."` → `git push`.
  Las credenciales de GitHub ya están cacheadas (no vuelve a pedir login).

**PowerShell / scripts**
- Ejecutar los `.ps1` con **PowerShell 7 (pwsh)**, NO con `powershell.exe` 5.1
  (lee UTF-8 como ANSI y rompe caracteres). Alternativa: mantener los scripts en
  **ASCII puro** (sin tildes ni emojis) para que corran en cualquiera.
- Node no está instalado → preferir soluciones en PowerShell.

**Código**
- Escribir en el estilo del código existente (mismo idioma de comentarios, misma
  densidad, mismas convenciones). App estática sin framework: HTML/CSS/JS plano.
- Temas claro/oscuro por tokens CSS; nada de colores "hardcodeados" fuera de tokens.

**Verificación en navegador**
- Para probar la app localmente se usa el navegador integrado (preview) o
  `python -m http.server`. La app **no** funciona por `file://` (los PDF y Supabase
  requieren HTTP). El panel del navegador a veces no compone frames → verificar por
  `read_console_messages` / `javascript_tool` en vez de screenshot.

---

## 8. Pendientes (lo que falta)

0. **Activar las colecciones en la base (bloquea el lote nuevo):** ejecutar
   `supabase-coleccion.sql` en **Supabase → SQL Editor**. Hasta que se ejecute,
   la app detecta que la columna no existe y funciona exactamente como antes
   (sin barra de pestañas y sin el campo Colección en el formulario), así que se
   puede publicar `index.html` sin riesgo. Lo que **sí** requiere el SQL es cargar
   un lote nuevo con su propia colección. Después de eso, queda
   pendiente **decidir de dónde salen los PDF del lote nuevo** (carpeta origen) y
   cómo se llamará la colección; el procedimiento está en `LEEME.md` →
   *Agregar un lote nuevo de documentos*.
0b. **Subir el lote OPR a Supabase** (después del SQL de arriba). Todo lo local ya
   está hecho; falta un solo comando con la clave `service_role` (pwsh 7, desde la
   carpeta del proyecto):

   ```
   ./migrar-a-supabase.ps1 -SupabaseUrl "https://armvuvoluoxspfjpefex.supabase.co" -ServiceKey "<service_role eyJ...>" -Inventario "inventario-opr.js" -Anexar
   ```

   `-Anexar` es imprescindible: sin él el script **vacía la tabla** y se perderían
   los 122 documentos ya cargados. Al terminar, la app debe mostrar la barra
   *Todas | Normativa base | Lineamientos y Directivas OPR* con 122 y 116.
1. **Redesplegar la Edge Function `preguntar`** con la última versión de
   `index.ts` (incluye el mensaje "DOCUMENTO GRANDE…" para PDF de +100 páginas) y
   **probar** con el reglamento grande (215 páginas) y con una directiva pequeña.
   *(Estaba a punto de hacerse al momento de este handoff.)*
2. **Rotar/regenerar las claves expuestas** en Supabase (Settings → API):
   la `service_role` (eyJ…) y la `sb_secret_`, que quedaron visibles en capturas.
   No afecta a la app (usa la clave pública). También conviene rotar la clave de
   Claude si se mostró.
3. **Publicar el sitio en IIS de SERFOR** (decidido: IIS, con internet):
   copiar el contenido de `publicar/` a `C:\inetpub\wwwroot\normativa\`, crear la
   aplicación en IIS, activar HTTPS, y poner la URL pública en Supabase
   Authentication → URL Configuration (Site URL). Pasos detallados en `LEEME.md`.
4. **Crear usuarios** para el resto del equipo (Supabase → Authentication → Add
   user; entran como `lector`; a quien sea admin, `update public.profiles set
   role='admin' where email='...'`).
5. **Documento pendiente:** `RM-324-2015-MINAM` (~62 MB) no se migró por superar el
   límite de 50 MB del plan gratuito de Supabase. Opciones: comprimirlo <50 MB,
   subir de plan, o dejarlo fuera.
6. **Opción B del asistente (RAG)** — preguntar sobre **todo el conjunto** a la vez
   (embeddings + pgvector). Es el siguiente escalón; también resolvería los
   documentos de +100 páginas (que hoy solo muestran el aviso de límite).
7. **Afinar datos del catálogo** (opcional): estados (todos quedaron "Vigente" por
   defecto), duplicados de algunas normas, y títulos derivados del nombre de archivo.

---

## 9. Cómo continuar

- Para **regenerar el catálogo** tras agregar PDF a la carpeta fuente:
  `pwsh -c "& ./generar-inventario.ps1"` y luego re-migrar.
- Para **re-migrar** a Supabase: `./migrar-a-supabase.ps1 -SupabaseUrl "https://armvuvoluoxspfjpefex.supabase.co" -ServiceKey "<service_role eyJ...>"` (pwsh 7).
  ⚠️ Sin `-Anexar` este script **vacía la tabla** y recarga todo desde cero.
- Para **agregar un lote nuevo** sin tocar lo ya cargado: `generar-inventario.ps1`
  con `-Origen`, `-Coleccion`, `-Salida` y `-Anexar`, y luego `migrar-a-supabase.ps1`
  con `-Inventario` y `-Anexar`. Pasos completos en `LEEME.md`.
- Para **cambiar el modelo** del asistente: editar `model: "claude-haiku-4-5"` en
  `supabase/functions/preguntar/index.ts` y redeploy.
- La guía operativa completa (despliegue, asistente, Chatbase→Claude, IIS) está en
  **`LEEME.md`**.
