# ============================================================
#  Migracion del inventario local -> Supabase  (version PowerShell)
#  Sube los PDF de documentos/ al Storage y carga la metadata en la tabla.
#  No requiere Node. Compatible con Windows PowerShell 5.1 y PowerShell 7.
#
#  Uso (una sola linea):
#    ./migrar-a-supabase.ps1 -SupabaseUrl "https://TU-PROYECTO.supabase.co" -ServiceKey "TU_SECRET_KEY"
#
#  El SECRET_KEY esta en:  Supabase -> Project Settings -> API -> service_role / sb_secret
#  OJO: es una clave SECRETA. Usala solo aqui, en tu equipo.
# ============================================================
param(
  [Parameter(Mandatory=$true)][string]$SupabaseUrl,
  [Parameter(Mandatory=$true)][string]$ServiceKey
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$SupabaseUrl = $SupabaseUrl.TrimEnd('/')
$bucket = 'documentos'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- Leer catalogo local (inventario.js) ----
$invPath = Join-Path $here 'inventario.js'
if(-not (Test-Path $invPath)){ Write-Error "No se encontro inventario.js"; exit 1 }
$raw = Get-Content -LiteralPath $invPath -Raw
$start = $raw.IndexOf('[')
$end   = $raw.LastIndexOf(']')
$json  = $raw.Substring($start, $end - $start + 1)
$inventario = $json | ConvertFrom-Json
Write-Host ("Catalogo local: {0} documentos." -f $inventario.Count) -ForegroundColor Cyan

$headers = @{ apikey = $ServiceKey; Authorization = "Bearer $ServiceKey" }

# ---- 1. Vaciar la tabla (sincronizacion completa) ----
Write-Host "Limpiando tabla documentos..." -NoNewline
try {
  Invoke-RestMethod -Method Delete -Uri "$SupabaseUrl/rest/v1/documentos?id=gt.0" `
    -Headers ($headers + @{ Prefer = 'return=minimal' }) | Out-Null
  Write-Host " ok" -ForegroundColor Green
} catch { Write-Host (" advertencia: " + $_.Exception.Message) -ForegroundColor Yellow }

# ---- 2. Subir cada PDF + insertar fila ----
$subidos = 0; $fallidos = 0
foreach($d in $inventario){
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
    $row = @{
      tipo = $d.tipo; titulo = $d.titulo; entidad = $d.entidad; anio = $anio
      estado = $estado; fecha = $d.fecha; kb = $kb
      archivo = $local; original = $d.original
    } | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri "$SupabaseUrl/rest/v1/documentos" `
      -Headers ($headers + @{ Prefer = 'return=minimal' }) `
      -ContentType 'application/json' -Body $row | Out-Null

    $subidos++
    if($subidos % 10 -eq 0){ Write-Host ("   ...{0}/{1}" -f $subidos, $inventario.Count) -ForegroundColor DarkGray }
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
