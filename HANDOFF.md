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
8. **UI:** columna de directivas angosta (`0.6fr`) y documento grande (`1.4fr`);
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
| `migrar-a-supabase.ps1` | Migra los PDF locales a Supabase (PowerShell) | ❌ Solo migración |
| `migrar-a-supabase.mjs` | Igual, versión Node (alternativa) | ❌ Solo migración |
| `generar-inventario.ps1` | Regenera `inventario.js` desde la carpeta fuente | ❌ Solo mantenimiento |
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
- Para **cambiar el modelo** del asistente: editar `model: "claude-haiku-4-5"` en
  `supabase/functions/preguntar/index.ts` y redeploy.
- La guía operativa completa (despliegue, asistente, Chatbase→Claude, IIS) está en
  **`LEEME.md`**.
