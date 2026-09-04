# Inventario Normativo SERFOR — demostración

Publicación de **solo lectura** para mostrar la aplicación antes del despliegue
definitivo en el servidor IIS de SERFOR.

- Requiere iniciar sesión: el acceso lo controla Supabase (Auth + RLS).
- Los PDF viven en un bucket privado y se sirven con URLs firmadas temporales.
- Esta rama contiene únicamente el paquete de despliegue (`publicar/` de `main`).
  El código fuente, los catálogos y los scripts están en la rama `main`.

No es el sitio oficial.
