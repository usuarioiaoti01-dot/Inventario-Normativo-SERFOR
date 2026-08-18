# Documentos Normativos OPR

Esta carpeta organiza los documentos listados en `LISTA_DOCUMENTOS_NORMATIVOS_OPR_v.01`.

Según el índice `Indice_Documentos_Normativos_OPR.xlsx` (que es la fuente de verdad y
coincide exactamente con el script de descarga):

- **70 normas** del ámbito forestal y de fauna silvestre: **47 lineamientos** y
  **23 directivas**, todas de SERFOR y todas en estado **Vigente**.
- **116 archivos PDF**: 70 resoluciones, 43 documentos (lineamiento/directiva) y 3 anexos.
  Una misma norma puede tener 1, 2 o 3 archivos.

## Contenido

```
Documentos Normativos OPR/
├── Indice_Documentos_Normativos_OPR.xlsx   <- catalogo completo (70 normas, 116 archivos)
├── indice_opr.csv                          <- el mismo indice en CSV (lo lee el generador)
├── Lineamiento/
│   └── Vigente/         <- 47 normas / 75 PDF (se descargan con el script)
└── Directiva/
    └── Vigente/         <- 23 normas / 41 PDF
```

El script de descarga (`descargar_documentos_normativos_opr.ps1`) vive un nivel arriba,
junto a los demás scripts del proyecto (`generar-inventario.ps1`, etc.).

## Por que las carpetas estan vacias

Los 116 PDF están alojados en `cdn.www.gob.pe` (servidor del Estado peruano). El entorno
en la nube donde se generó este catálogo **no tiene salida a ese dominio** (bloqueado por
política de red del sandbox), por lo que no fue posible descargarlos automáticamente.

## Como completar la descarga (un solo paso)

1. Abra **PowerShell 7** (`pwsh`) en el equipo donde está esta carpeta
   (`C:\Users\mmontoya\Desarrollo Claude\inventario-normativo`).
2. Ejecute:
   ```powershell
   pwsh -ExecutionPolicy Bypass -File .\descargar_documentos_normativos_opr.ps1
   ```
3. El script crea las 4 subcarpetas (si no existen) y descarga los 116 PDF en el lugar
   que indica el índice Excel (columna "Ruta Relativa"). Es seguro volver a ejecutarlo:
   los archivos ya descargados se omiten, y si algo falla queda registrado en
   `errores_descarga.csv` dentro de esta misma carpeta.

## Incorporarlos a la aplicación web

Estas normas entran al inventario web como una **colección aparte** (`Normativa OPR`),
de modo que quedan diferenciadas de los 122 documentos ya migrados: el Inventario
muestra una barra de pestañas *Todas | Normativa base | Normativa OPR*.

Después de descargar los PDF con el paso anterior:

```powershell
# 1) Una sola vez: crear el campo 'coleccion' en Supabase
#    (SQL Editor -> pegar supabase-coleccion.sql -> Run)

# 2) Armar el catalogo del lote a partir del indice
pwsh -ExecutionPolicy Bypass -File .\generar-inventario-opr.ps1

# 3) Subir SOLO este lote, sin tocar lo ya cargado
./migrar-a-supabase.ps1 -SupabaseUrl "https://armvuvoluoxspfjpefex.supabase.co" -ServiceKey "<service_role>" -Inventario "inventario-opr.js" -Anexar
```

El detalle está en `LEEME.md` → *Agregar un lote nuevo de documentos*.
