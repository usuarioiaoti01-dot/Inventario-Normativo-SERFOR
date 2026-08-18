# ============================================================
#  Migracion del inventario local -> Supabase  (version PowerShell)
#  Sube los PDF de documentos/ al Storage y carga la metadata en la tabla.
#  No requiere Node. Compatible con Windows PowerShell 5.1 y PowerShell 7.
#
#  Uso (una sola linea) - migracion completa, VACIA la tabla antes:
#    ./migrar-a-supabase.ps1 -SupabaseUrl "https://TU-PROYECTO.supabase.co" -ServiceKey "TU_SECRET_KEY"
#
#  Cargar un conjunto en SU PROPIA tabla (p. ej. el lote OPR):
#    ./migrar-a-supabase.ps1 -SupabaseUrl "..." -ServiceKey "..." -Inventario "inventario-opr.js" -Tabla "normativos_opr"
#
#  Agregar filas a una tabla conservando lo que ya tiene:
#    ./migrar-a-supabase.ps1 -SupabaseUrl "..." -ServiceKey "..." -Inventario "inventario-2026.js" -Anexar
#
#  -Tabla      : tabla destino (por defecto 'documentos'). Debe existir; para la de
#                OPR, ejecutar antes supabase-tabla-opr.sql en el SQL Editor.
#  -Anexar     : NO vacia la tabla; solo agrega las filas del catalogo indicado.
#  -Inventario : catalogo local a migrar (por defecto inventario.js).
#  -Coleccion  : fuerza la coleccion de todas las filas (si no, se usa la del catalogo).
#
#  Los PDF de TODAS las tablas van al mismo bucket privado 'documentos'.
#
#  El SECRET_KEY esta en:  Supabase -> Project Settings -> API -> service_role / sb_secret
#  OJO: es una clave SECRETA. Usala solo aqui, en tu equipo.
# ============================================================
param(
  [Parameter(Mandatory=$true)][string]$SupabaseUrl,
  [Parameter(Mandatory=$true)][string]$ServiceKey,
  [string]$Inventario = "inventario.js",
  [string]$Tabla      = "documentos",
  [string]$Coleccion,
  [switch]$Anexar
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$SupabaseUrl = $SupabaseUrl.TrimEnd('/')
$bucket = 'documentos'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- Leer catalogo local (inventario.js) ----
$invPath = if([IO.Path]::IsPathRooted($Inventario)){ $Inventario } else { Join-Path $here $Inventario }
if(-not (Test-Path $invPath)){ Write-Error "No se encontro el catalogo: $invPath"; exit 1 }
# -Encoding UTF8 explicito: Windows PowerShell 5.1 leeria el archivo como ANSI
# y los titulos con tildes llegarian corrompidos a la base.
$raw = Get-Content -LiteralPath $invPath -Raw -Encoding UTF8
$start = $raw.IndexOf('[')
$end   = $raw.LastIndexOf(']')
$json  = $raw.Substring($start, $end - $start + 1)
# OJO: la variable NO puede llamarse $inventario. PowerShell no distingue
# mayusculas, asi que chocaria con el parametro [string]$Inventario y su
# restriccion de tipo convertiria el array en UN SOLO string (Count = 1).
$catalogo = @($json | ConvertFrom-Json)
Write-Host ("Catalogo local ({0}): {1} documentos." -f $Inventario, $catalogo.Count) -ForegroundColor Cyan
Write-Host ("Tabla destino: {0}   |   Bucket: {1}" -f $Tabla, $bucket) -ForegroundColor Cyan

# ---- Validar ANTES de borrar nada ----
# El orden importa: vaciar la tabla y fallar despues dejaria la tabla vacia.
if($catalogo.Count -eq 0){
  Write-Error "El catalogo no tiene documentos. No se toca la tabla."; exit 1
}
$sinArchivo = @($catalogo | Where-Object { -not $_.archivo }).Count
if($sinArchivo -gt 0){
  Write-Error "$sinArchivo fila(s) del catalogo no tienen 'archivo'. No se toca la tabla."; exit 1
}
$ausentes = @()
foreach($d in $catalogo){
  $rel = ($d.archivo -replace '^documentos/','')
  if(-not (Test-Path -LiteralPath (Join-Path $here (Join-Path 'documentos' $rel)))){ $ausentes += $rel }
}
if($ausentes.Count -gt 0){
  Write-Host ("Faltan {0} PDF en documentos/ (los {1} primeros):" -f $ausentes.Count, [Math]::Min(5,$ausentes.Count)) -ForegroundColor Yellow
  $ausentes | Select-Object -First 5 | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
  Write-Error "Faltan archivos locales. No se toca la tabla."; exit 1
}
Write-Host ("Verificado: los {0} PDF estan en documentos/." -f $catalogo.Count) -ForegroundColor Green

$headers = @{ apikey = $ServiceKey; Authorization = "Bearer $ServiceKey" }

# ---- 1. Vaciar la tabla (solo en migracion completa) ----
if($Anexar){
  Write-Host "Modo -Anexar: la tabla NO se vacia; solo se agregan las filas de este catalogo." -ForegroundColor Cyan
} else {
  Write-Host ("Limpiando tabla {0}..." -f $Tabla) -NoNewline
  try {
    Invoke-RestMethod -Method Delete -Uri "$SupabaseUrl/rest/v1/$Tabla`?id=gt.0" `
      -Headers ($headers + @{ Prefer = 'return=minimal' }) | Out-Null
    Write-Host " ok" -ForegroundColor Green
  } catch { Write-Host (" advertencia: " + $_.Exception.Message) -ForegroundColor Yellow }
}

# ---- 2. Subir cada PDF + insertar fila ----
$subidos = 0; $fallidos = 0
foreach($d in $catalogo){
  $local = ($d.archivo -replace '^documentos/','')
  $localPath = Join-Path $here (Join-Path 'documentos' $local)
  try {
    if(-not (Test-Path -LiteralPath $localPath)){ throw "no existe el archivo local" }
    $enc = [uri]::EscapeDataString($local)

    # Subir al Storage (upsert)
    Invoke-WebRequest -Method Post -Uri "$SupabaseUrl/storage/v1/object/$bucket/$enc" `
      -Headers ($headers + @{ 'x-upsert' = 'true' }) `
      -ContentType 'application/pdf' -InFile $localPath -UseBasicParsing | Out-Null

    # Insertar fila
    $estado = if($d.estado){ $d.estado } else { 'Vigente' }
    $kb   = if($null -ne $d.kb){ [int][math]::Round([double]$d.kb) } else { $null }
    $anio = if($null -ne $d.anio -and "$($d.anio)" -ne ''){ [int]$d.anio } else { $null }
    $col = if($Coleccion){ $Coleccion } elseif($d.coleccion){ $d.coleccion } else { 'Normativa base' }
    $row = @{
      tipo = $d.tipo; titulo = $d.titulo; entidad = $d.entidad; anio = $anio
      estado = $estado; coleccion = $col; fecha = $d.fecha; kb = $kb
      archivo = $local; original = $d.original
    } | ConvertTo-Json -Compress
    # charset=utf-8 explicito: sin el, PS 5.1 manda el cuerpo en ASCII y las tildes se pierden
    Invoke-RestMethod -Method Post -Uri "$SupabaseUrl/rest/v1/$Tabla" `
      -Headers ($headers + @{ Prefer = 'return=minimal' }) `
      -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($row)) | Out-Null

    $subidos++
    if($subidos % 10 -eq 0){ Write-Host ("   ...{0}/{1}" -f $subidos, $catalogo.Count) -ForegroundColor DarkGray }
  } catch {
    $fallidos++
    $detail = $_.Exception.Message
    try {
      $resp = $_.Exception.Response
      if($resp){ $sr = New-Object System.IO.StreamReader($resp.GetResponseStream()); $detail = $sr.ReadToEnd() }
    } catch {}
    Write-Host ("   [fallo] {0} : {1}" -f $local, $detail) -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host ("Migracion terminada. Subidos: {0}  |  Fallidos: {1}" -f $subidos, $fallidos) -ForegroundColor Green
