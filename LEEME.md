# Inventario Normativo — SERFOR

Aplicación web para consultar, buscar, descargar y **ampliar** la normativa
institucional, con **base de datos PostgreSQL (Supabase)**, **acceso por usuario**
y **carga de nuevos documentos**.

## Contenido de esta carpeta

```
inventario-normativo/
├── index.html               ← la aplicación (login, inventario, nuevos registros)
├── config.js                ← tus credenciales de Supabase (URL + clave anon)
├── supabase-setup.sql       ← esquema de base de datos + seguridad (ejecutar 1 vez)
├── migrar-a-supabase.mjs    ← sube los 123 PDF actuales a Supabase (Node 18+)
├── generar-inventario.ps1   ← (opcional) regenera inventario.js desde la carpeta local
├── inventario.js            ← catálogo local (solo se usa para la migración inicial)
├── documentos/              ← 123 PDF locales (fuente para la migración inicial)
└── LEEME.md                 ← este archivo
```

Cómo funciona una vez conectado:
- Los **datos** de cada documento viven en la tabla `documentos` de Postgres.
- Los **PDF** viven en el *Storage* privado de Supabase (bucket `documentos`).
- La página **lee todo desde Supabase** y genera enlaces temporales firmados
  para ver/descargar cada PDF solo a usuarios con sesión iniciada.

---

## Puesta en marcha (una sola vez)

### Paso 1 — Crear el proyecto Supabase
1. Entra a **https://supabase.com** → *Start your project* (plan gratuito sirve para empezar).
2. Crea un proyecto (elige región cercana, p. ej. *South America (São Paulo)*).
3. Espera a que termine de aprovisionar.

### Paso 2 — Crear la base de datos y la seguridad
1. En el proyecto, ve a **SQL Editor → New query**.
2. Abre `supabase-setup.sql`, copia todo y pégalo. Pulsa **Run**.
   Esto crea las tablas `profiles` y `documentos`, el bucket `documentos`,
   y todas las reglas de acceso (RLS).

### Paso 3 — Conectar la página
1. Ve a **Project Settings → API**.
2. Copia **Project URL** y la clave **anon public**.
3. Pégalas en `config.js`:
   ```js
   const SUPABASE_URL = "https://TU-PROYECTO.supabase.co";
   const SUPABASE_ANON_KEY = "eyJhbGciOi...";  // clave anon (pública)
   ```

### Paso 4 — Crear el primer usuario administrador
1. En Supabase: **Authentication → Users → Add user** (correo + contraseña).
2. En **SQL Editor**, conviértelo en administrador (cambia el correo):
   ```sql
   update public.profiles set role = 'admin'
   where email = 'adm-claude@serfor.gob.pe';
   ```

### Paso 5 — Subir los 123 documentos actuales
En PowerShell, dentro de esta carpeta (requiere **Node 18+**):
```powershell
$env:SUPABASE_URL="https://TU-PROYECTO.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY="TU_SERVICE_ROLE_KEY"   # Settings → API → service_role (SECRETA)
node migrar-a-supabase.mjs
```
> La **service_role key** es secreta y omnipotente: úsala solo en tu equipo para
> esta migración. No la pongas en `config.js` ni la subas al servidor.

Al terminar, tendrás los 123 PDF y su metadata en Supabase.

---

## Uso diario

- **Ingresar:** cada usuario entra con su correo y contraseña.
- **Consultar:** buscar, filtrar por tipo/entidad/año y ver el PDF incrustado.
- **Nuevos registros** (solo administradores): pestaña para subir un PDF nuevo con
  sus datos; queda guardado en la base y visible para todos al instante.

### Dar acceso a más usuarios (compartir)
1. Publica la página (ver abajo) y comparte la URL.
2. Crea la cuenta de cada persona en **Authentication → Users → Add user**
   (o activa invitaciones por correo en Supabase).
3. Por defecto entran como **lector**. Para hacer a alguien administrador:
   ```sql
   update public.profiles set role='admin' where email='persona@serfor.gob.pe';
   ```

---

## Publicar la página

La app es estática (HTML + JS). Solo necesitas servir `index.html` y `config.js`.
Opciones:
- **Servidor web de SERFOR (IIS/Apache):** copia `index.html` y `config.js`.
  Ya **no** necesitas subir la carpeta `documentos/` al servidor: los PDF se
  sirven desde Supabase. (`documentos/`, `inventario.js`, los `.ps1/.mjs` y
  `supabase-setup.sql` son solo para la instalación/migración.)
- **Supabase Hosting / Vercel / Netlify:** también sirven, subiendo los dos archivos.

> Requiere conexión a internet (la app usa la API de Supabase y carga la
> biblioteca `@supabase/supabase-js` desde un CDN). Si el servidor de SERFOR no
> tiene salida a internet, avísame y adapto la app para alojar esa biblioteca
> localmente.

---

## Configuración aplicada (se puede cambiar)

| Decisión | Valor por defecto | Dónde se cambia |
|---|---|---|
| Registro de usuarios | Controlado por admin | Authentication (Supabase) |
| Quién sube documentos | Solo administradores | políticas RLS en `supabase-setup.sql` |
| Visibilidad de PDF | Privados (enlaces firmados) | bucket `documentos` (privado) |

Si quieres otra combinación (p. ej. auto-registro con dominio @serfor.gob.pe, o
que todos los usuarios puedan subir), dímelo y ajusto el SQL y la app.
