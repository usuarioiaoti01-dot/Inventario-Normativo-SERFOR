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
- **Un conjunto = una tabla = una pestaña.** La app lee de varias tablas a la vez
  (registro `FUENTES` en `index.html`) y muestra una barra de pestañas
  *Todas | Normativa base | Normativos OPR* con el conteo de cada una. Una tabla
  que aún no exista se omite sin romper nada. Dentro de una tabla, el campo
  opcional `coleccion` permite subdividir en sublotes (filtro *Toda colección*).
- **Lote OPR MIGRADO (2026-08-18):** 116 PDF / 148 MB — 70 normas de SERFOR
  (47 lineamientos + 23 directivas), todas vigentes — en su **propia tabla
  `normativos_opr`** (pestaña "Normativos OPR"), separados de los 122 originales.
  Subidos: 116, fallidos: 0. Los PDF están en el mismo bucket `documentos` con
  prefijo `opr_`, así que el visor y el asistente IA los abren sin cambios.
  Fuente y catálogo: `Documentos Normativos OPR/` e `inventario-opr.js`.
- **Módulo de administración de cuentas (2026-09-04):** perfiles
  **Administrador** y **Especialista** (antes `admin`/`lector`), pestaña
  *Usuarios* para alta, baja, cambio de perfil y restablecimiento de clave, y
  **cambio de clave obligatorio en el primer ingreso**. El alcance del
  Especialista — solo *Normativos OPR* — se hace cumplir con RLS y con la
  política del bucket, no escondiendo botones. **Falta ejecutar
  `supabase-usuarios.sql` y desplegar la función `admin-usuarios`** (Pendientes).
- **Lote DOCUMENTOS COMPLEMENTO preparado (2026-09-04):** 139 carpetas, una por
  norma, con 222 PDF. De ellos **115 son nuevos** (209,6 MB) y **102 ya estaban
  cargados**: a estos NO se les vuelve a subir nada, solo se les asigna su carpeta.
  El lote OPR pasa de 116 a **231 documentos** en **132 normas**, de las cuales
  **82 tienen varios archivos** y se muestran anidadas.
  **Falta ejecutar el SQL y migrar** (Pendientes).
- **Repo en GitHub** actualizado. ⚠️ **Es público**, no privado (verificado el
  2026-09-04 sin autenticación). No contiene credenciales — solo la clave
  `sb_publishable_` de `config.js`, que es pública por diseño, y el RLS impide
  que un anónimo lea una sola fila. Queda a decisión de la OTI si debe pasar a
  privado.
- **Demo en GitHub Pages** (2026-09-04): `https://usuarioiaoti01-dot.github.io/Inventario-Normativo-SERFOR/`,
  servida desde la rama **`gh-pages`**, que contiene Únicamente el paquete de
  `publicar/` (index.html, config.js, lib/, imagen) más `.nojekyll`. **No** expone
  código fuente, catálogos ni scripts. Es solo para enseñar la app a la Dirección
  antes del despliegue definitivo; **el destino oficial sigue siendo IIS**.
- **Aún NO publicado** en el servidor de SERFOR (paquete listo, ver Pendientes).

---

## 3. Datos clave (referencias)

| Dato | Valor |
|---|---|
| Carpeta del proyecto | `C:\Users\mmontoya\Desarrollo Claude\inventario-normativo` |
| Repo GitHub (**PÚBLICO**) | `https://github.com/usuarioiaoti01-dot/Inventario-Normativo-SERFOR` |
| Demo en GitHub Pages | `https://usuarioiaoti01-dot.github.io/Inventario-Normativo-SERFOR/` (rama `gh-pages`) |
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
8. **Cada conjunto de normativa en su propia tabla** (decisión del usuario), no
   todo en `documentos` con un campo discriminador. La app lee de varias tablas
   en paralelo según el registro `FUENTES` de `index.html` y cada una es una
   pestaña. Consecuencias resueltas:
   - Los `id` **se repiten** entre tablas (ambas son identity desde 1), así que la
     clave de selección en el frontend es compuesta: `_key = tabla + ":" + id`.
   - Los PDF de todas las tablas siguen en el **mismo bucket** `documentos`, de
     modo que el visor y la Edge Function del asistente **no cambian**.
   - Cada tabla nueva necesita su SQL (modelo: `supabase-tabla-opr.sql`) y su
     línea en `FUENTES`. Una tabla inexistente se omite sin romper la app.
   - El campo `coleccion` sobrevive como **sublote dentro de una tabla**: si una
     tabla tiene más de uno, aparece el filtro *Toda colección*. Se detecta por
     tabla, porque una puede tenerlo y otra no.
   La barra de pestañas vive **dentro** de Inventario (no como pestaña principal
   aparte) para reutilizar buscador, filtros, visor y asistente.
9. **Dos perfiles, con el alcance impuesto en la base.** `admin`
   ("Administrador") y `especialista` ("Especialista"; reemplaza a `lector`).
   El Especialista ve **solo** `normativos_opr`. Consecuencias resueltas:
   - RLS: `documentos` solo para administradores; `normativos_opr` para todos.
   - Los PDF de ambos conjuntos comparten bucket, así que la política de
     `storage.objects` deja leer al Especialista **solo** los objetos `opr\_%`.
     De ahí que el formulario de carga anteponga `opr_` cuando el destino es esa
     tabla: **el prefijo es un control de acceso, no un adorno.**
   - La política `perfil_propio_update` permitía que alguien se ascendiera solo
     con un `update`. Lo bloquea ahora el disparador `proteger_rol()`, que
     **debe dejar pasar las operaciones con `auth.uid()` nulo**: son las de la
     Edge Function actuando con `service_role`. Sin esa excepcion, el disparador
     bloquea tambien el alta de cuentas (ocurrio la primera vez).
   - Alta y baja de cuentas van por la Edge Function `admin-usuarios`: exigen
     `service_role`, que nunca puede estar en el navegador.
   - Una fuente que devuelve 0 filas no genera pestaña, para que el Especialista
     no vea un "Normativa base 0".
10. **Normas con varios documentos = campos `carpeta` + `parte`.** Una norma
   puede constar de resolución, documento, anexo y expediente. Se agrupan por
   `carpeta` y se anidan en la lista. Criterios:
   - Solo se anida si la norma tiene **más de un** documento; con uno solo se
     pinta como fila simple.
   - Pulsar la norma abre su **resolución** en el visor y despliega el resto;
     el chevron pliega sin cambiar el documento abierto.
   - Al buscar, los grupos se despliegan solos y la fila padre indica
     "N de M documentos" para que se vea que el filtro deja fuera hermanos.
   - La deduplicación compara **solo contra archivos `opr_`**. Si un PDF coincide
     con uno de la Normativa base NO cuenta como cargado: el Especialista no ve
     esa colección y su carpeta quedaría incompleta.
11. **Títulos del lote OPR:** salen del índice oficial (denominación + norma de
   aprobación), no del nombre del archivo. Cuando una norma tiene varios PDF
   (resolución + documento + anexo), la parte va **delante** en corchetes
   — `[Resolucion] …`, `[Lineamiento] …`, `[Anexo] …` — porque las
   denominaciones llegan a 300 caracteres y al final no se distinguirían.
   En la lista los títulos se recortan a 3 líneas (texto completo en el tooltip
   y en la ficha).
12. **Filtro por día:** campo `<input type="date">` en la barra de filtros, con
   botón para quitarlo. ⚠️ **Solo 116 documentos tienen fecha real** (la del
   índice oficial de OPR). Los 123 de la Normativa base llevan `2026-08-17` y los
   115 del lote complemento `2026-09-04`: son la fecha en que se copió el
   archivo, no la de la norma. Mientras no se corrija, filtrar por esos dos días
   devuelve bloques enteros sin sentido. Limpiarlo es una sentencia:
   `update public.normativos_opr set fecha = null where fecha = '2026-09-04';`
13. **Búsqueda:** inmediata a cada pulsación, por subcadena, **sin distinguir
   tildes** y abarcando también `carpeta` (número de norma) y `parte`. Antes no
   encontraba una norma por su número si este solo estaba en el nombre de la
   carpeta.
14. **UI:** columna de la lista `0.6fr` y visor `1.4fr` (30/70); cabecera
   institucional a 76 px con título 1.3rem y subtítulo .86rem; pestaña rotulada
   "Inventario OPR"; visor de PDF sin miniaturas y a tamaño real
   (`#navpanes=0&pagemode=none&zoom=100`).
   Con la lista a `0.6fr` el visor ocupa el 70 %: a 1280 px son 896, así que una
   A4 (794) y una carta (816) caben enteras al 100 %. El umbral baja a ~1135 px
   de ventana.
   La ficha del documento se quedó **solo con los botones** Descargar y Abrir en
   pestaña: el título y los datos ya están en la lista, y quitarlos da más alto
   al visor.

---

## 6. Archivos generados (en la carpeta del proyecto)

| Archivo / carpeta | Propósito | ¿Va al servidor? |
|---|---|---|
| `index.html` | La aplicación completa (login, inventario, visor, asistente) | ✅ Sí |
| `config.js` | URL + clave **pública** (anon/publishable) de Supabase | ✅ Sí |
| `lib/supabase.js` | Librería de Supabase (local) | ✅ Sí |
| `capibara-serfor.png` | Imagen del botón del asistente | ✅ Sí |
| `supabase/functions/preguntar/index.ts` | Edge Function del asistente (Deno) | ❌ Se despliega en Supabase |
| `supabase/functions/admin-usuarios/index.ts` | Edge Function de gestión de cuentas (Deno) | ❌ Se despliega en Supabase |
| `supabase-usuarios.sql` | Perfiles Administrador/Especialista, alcance y salvaguardas | ❌ Solo instalación |
| `supabase-carpetas.sql` | Campos `carpeta` y `parte`: normas con varios documentos | ❌ Solo instalación |
| `generar-inventario-complemento.ps1` | Cataloga el lote por carpetas y detecta lo ya cargado | ❌ Solo migración |
| `inventario-complemento.js` | Catálogo de los 115 PDF nuevos | ❌ Solo migración |
| `actualizar-carpetas-opr.sql` | Agrupa los 102 ya cargados sin resubirlos (generado) | ❌ Solo migración |
| `supabase-setup.sql` | Esquema BD + RLS + bucket (ejecutar 1 vez) | ❌ Solo instalación |
| `supabase-coleccion.sql` | (Opcional) campo `coleccion` para subdividir una tabla | ❌ Solo instalación |
| `supabase-tabla-opr.sql` | Crea la tabla `normativos_opr` + RLS. Modelo para futuras tablas | ❌ Solo instalación |
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

**Publicación de la demo (rama `gh-pages`)**
- Se genera desde `publicar/` con un worktree huérfano, para no mezclarla con `main`:
  `git worktree add --orphan -b gh-pages <carpeta temporal>`, copiar el contenido de
  `publicar/`, añadir `.nojekyll`, commit y `git push -u origin gh-pages`.
- Para **actualizar la demo** tras cambiar la app: repetir ese procedimiento
  (o hacer checkout de `gh-pages` en un worktree y volver a copiar `publicar/`).
  La demo **no** se actualiza sola al empujar `main`.
- `web.config` se deja fuera: es especifico de IIS y en Pages es inerte.

**Git**
- Mensajes de commit **en una sola línea** (`git commit -m "..."`). Los mensajes
  multilínea con heredoc **activaron un bloqueo de seguridad del entorno** — evitar.
- Flujo: `cd` a la carpeta → `git add -A` → `git commit -m "..."` → `git push`.
  Las credenciales de GitHub ya están cacheadas (no vuelve a pedir login).

**PowerShell / scripts**
- ⚠️ **Nombres de parámetro vs. variables internas.** PowerShell **no distingue
  mayúsculas**: un `param([string]$Inventario)` y un `$inventario = ... | ConvertFrom-Json`
  son la MISMA variable, y la restricción `[string]` convierte el array en un solo
  string sin avisar (`.Count` pasa a 1 y los campos quedan vacíos). Ya ocurrió una
  vez en `migrar-a-supabase.ps1`; la variable interna ahora se llama `$catalogo`.
  Al agregar parámetros, comprobar que ninguno choque con una variable del cuerpo.
- **Validar antes de destruir.** El script comprueba que el catálogo tenga filas,
  que todas traigan `archivo` y que los PDF existan en `documentos/` **antes** de
  vaciar la tabla. Sin eso, un catálogo mal leído dejaba la tabla vacía y subía 0.
- **Probar de verdad, no solo la sintaxis.** `Parser::ParseFile` no detectó nada de
  lo anterior. Para cambios en el migrador, levantar un servidor HTTP local que
  imite a Supabase y correr el script completo contra él.
- Ejecutar los `.ps1` con **PowerShell 7 (pwsh)** y `-ExecutionPolicy Bypass`:
  la política de la máquina es `RemoteSigned` y `./script.ps1` a secas falla con
  *"la ejecución de scripts está deshabilitada"*. Forma correcta:
  `pwsh -ExecutionPolicy Bypass -File .\script.ps1 -Param valor`.
- Mantener los scripts en **ASCII puro** (sin tildes ni emojis) para que corran
  también en `powershell.exe` 5.1.
- **Encoding explicito, siempre.** PS 5.1 lee UTF-8 como ANSI y envía los cuerpos
  HTTP en ASCII, así que los títulos con tildes llegarían corrompidos a la base.
  Por eso `migrar-a-supabase.ps1` usa `Get-Content -Encoding UTF8`,
  `ContentType 'application/json; charset=utf-8'` y manda el cuerpo como bytes
  UTF-8; y `generar-inventario-opr.ps1` usa `Import-Csv -Encoding UTF8`.
  Verificado en 5.1 y en 7.6.
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

0. ⚠️ **ROTAR LA CLAVE `service_role` — lo más urgente.** Quedó completa y
   legible en capturas de pantalla del chat. Se cambia en **Supabase → Project
   Settings → API**. La app usa una clave distinta (`sb_publishable_…` en
   `config.js`), así que el sitio no debería verse afectado; después de rotar,
   comprobar igualmente que el inventario carga y que el asistente responde.
   Borrar también las líneas con la clave en el historial de PowerShell:
   `C:\Users\mmontoya\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`
0c. **Activar el módulo de cuentas** (nada de esto rompe la app si se posterga):
   ejecutar `supabase-usuarios.sql` en el SQL Editor y desplegar la función
   `admin-usuarios` (Edge Functions → Create a new function → pegar
   `supabase/functions/admin-usuarios/index.ts` → Deploy). Detalle en `LEEME.md`.
   ⚠️ Tras el SQL, **la Normativa base deja de verse para los no administradores**:
   confirmar que las cuentas que deban verla tengan rol `admin`.
0d. **Incorporar el lote DOCUMENTOS COMPLEMENTO** (en este orden):
   1) `supabase-carpetas.sql` en el SQL Editor (crea `carpeta` y `parte`).
   2) `actualizar-carpetas-opr.sql` (agrupa los 102 ya cargados; 102 sentencias).
   3) `pwsh -ExecutionPolicy Bypass -File .\migrar-a-supabase.ps1 -SupabaseUrl "..." -ServiceKey "..." -Inventario "inventario-complemento.js" -Tabla "normativos_opr" -Anexar`
   ⚠️ `-Anexar` es imprescindible: sin él se borran los 116 que ya están.
   Suma 209,6 MB al bucket (quedaría en ~630 MB de 1 GB del plan gratuito).
   Al terminar: 231 documentos en la pestaña Normativos OPR.
1. **Redesplegar la Edge Function `preguntar`** con la última versión de
   `index.ts` (incluye el mensaje "DOCUMENTO GRANDE…" para PDF de +100 páginas) y
   **probar** con el reglamento grande (215 páginas) y con una directiva pequeña.
   *(Estaba a punto de hacerse al momento de este handoff.)*
2. **Otras claves expuestas** (además de la `service_role` del punto 0): la
   `sb_secret_` quedó visible en capturas anteriores. Rotar también la clave de
   Claude si llegó a mostrarse. Ninguna afecta a la app, que usa la pública.
3. **Publicar el sitio en IIS de SERFOR** (decidido: IIS, con internet):
   copiar el contenido de `publicar/` a `C:\inetpub\wwwroot\normativa\`, crear la
   aplicación en IIS, activar HTTPS, y poner la URL pública en Supabase
   Authentication → URL Configuration (Site URL). Pasos detallados en `LEEME.md`.
4. **Crear usuarios** para el resto del equipo. Ya no hace falta el panel de
   Supabase: se hace desde la pestaña **Usuarios** de la aplicación, una vez
   activado el módulo (punto 0c).
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
- Para **re-migrar** a Supabase: `pwsh -ExecutionPolicy Bypass -File .\migrar-a-supabase.ps1 -SupabaseUrl "https://armvuvoluoxspfjpefex.supabase.co" -ServiceKey "<service_role eyJ...>"`.
  ⚠️ Sin `-Anexar` este script **vacía la tabla** y recarga todo desde cero.
- Para **agregar un lote nuevo** sin tocar lo ya cargado: `generar-inventario.ps1`
  con `-Origen`, `-Coleccion`, `-Salida` y `-Anexar`, y luego `migrar-a-supabase.ps1`
  con `-Inventario` y `-Anexar`. Pasos completos en `LEEME.md`.
- Para **cambiar el modelo** del asistente: editar `model: "claude-haiku-4-5"` en
  `supabase/functions/preguntar/index.ts` y redeploy.
- La guía operativa completa (despliegue, asistente, Chatbase→Claude, IIS) está en
  **`LEEME.md`**.
