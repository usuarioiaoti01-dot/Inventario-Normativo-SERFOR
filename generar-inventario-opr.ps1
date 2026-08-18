# ============================================================
#  Catalogo del lote "Normativa OPR" - SERFOR
#  Lee el indice (indice_opr.csv), copia los PDF descargados a
#  documentos/ y genera el catalogo inventario-opr.js listo para
#  migrar a Supabase.
#
#  A diferencia de generar-inventario.ps1 (que deduce tipo, titulo y
#  entidad del nombre del archivo), aqui la metadata sale del indice
#  oficial: denominacion, norma de aprobacion, tipo, estado y fecha.
#
#  Orden de uso:
#    1) pwsh -ExecutionPolicy Bypass -File .\descargar_documentos_normativos_opr.ps1
#    2) pwsh -ExecutionPolicy Bypass -File .\generar-inventario-opr.ps1
#    3) ./migrar-a-supabase.ps1 -SupabaseUrl "..." -ServiceKey "..." -Inventario "inventario-opr.js" -Anexar
#
#  Se puede volver a ejecutar sin problema: reconstruye el catalogo desde cero
#  y sobrescribe en documentos/ solo los PDF de este lote (prefijo opr_).
# ============================================================
#  La pestaña del inventario la define la TABLA (normativos_opr -> "Normativos OPR"),
#  no este parametro. -Coleccion sirve para subdividir dentro de esa tabla: si se le
#  da un valor distinto al de la tabla, aparece como filtro "Toda coleccion" y en la
#  ficha del documento. Por defecto coincide, para no rotular dos veces lo mismo.
param(
  [string]$Coleccion = "Normativos OPR",
  [string]$Salida    = "inventario-opr.js"
)

$ErrorActionPreference = 'Stop'
$root  = $PSScriptRoot
$base  = Join-Path $root "Documentos Normativos OPR"
$csv   = Join-Path $base "indice_opr.csv"
$docs  = Join-Path $root "documentos"

if(-not (Test-Path -LiteralPath $csv)){ Write-Error "No se encontro el indice: $csv"; exit 1 }
if(-not (Test-Path -LiteralPath $docs)){ New-Item -ItemType Directory -Path $docs | Out-Null }

$filas = Import-Csv -LiteralPath $csv
Write-Output ("Indice OPR: {0} archivos listados." -f $filas.Count)

# Cuantos archivos tiene cada norma (Tipo + Item): si son varios, el titulo
# lleva sufijo para distinguir la resolucion del documento y del anexo.
$porNorma = @{}
foreach($f in $filas){
  $k = "$($f.Tipo)|$($f.Item)"
  if($porNorma.ContainsKey($k)){ $porNorma[$k]++ } else { $porNorma[$k] = 1 }
}
Write-Output ("Normas distintas: {0}." -f $porNorma.Count)

# 'Lineamiento' -> 'Lineamientos' para que coincida con los tipos de la app
function Get-TipoApp($t){ if($t -eq 'Lineamiento'){ 'Lineamientos' } else { $t } }

function Get-Sufijo($tipoArchivo, $tipo){
  switch -Wildcard ($tipoArchivo){
    'Resolucion'  { 'Resolucion' }
    'Anexo'       { 'Anexo' }
    'Documento*'  { if($tipo -eq 'Lineamiento'){ 'Lineamiento' } else { 'Directiva' } }
    default       { $tipoArchivo }
  }
}

$rows = @()
$faltantes = @()
$id = 0
foreach($f in $filas){
  $origen = Join-Path $root ($f.'Ruta Relativa' -replace '/','\')
  if(-not (Test-Path -LiteralPath $origen)){
    $faltantes += $f.'Nombre de Archivo Local'
    continue
  }

  $id++
  $fname = "opr_" + $f.'Nombre de Archivo Local'
  Copy-Item -LiteralPath $origen -Destination (Join-Path $docs $fname) -Force
  $info = Get-Item -LiteralPath $origen

  # Titulo: denominacion + norma. Si la norma tiene varios archivos, la parte va
  # DELANTE: las denominaciones son largas y dos filas de la misma norma se
  # verian identicas si la etiqueta quedara al final.
  $titulo = "$($f.Denominacion) - $($f.'Norma de Aprobacion')"
  if($porNorma["$($f.Tipo)|$($f.Item)"] -gt 1){
    $titulo = "[$(Get-Sufijo $f.'Tipo de Archivo' $f.Tipo)] $titulo"
  }

  # Anio: de la fecha; si falta, del numero de la norma (p. ej. D000034-2025)
  $anio = $null
  if($f.Fecha -and $f.Fecha -match '^(\d{4})-'){ $anio = [int]$Matches[1] }
  elseif($f.'Norma de Aprobacion' -match '-((?:19|20)\d{2})'){ $anio = [int]$Matches[1] }

  $fecha = if($f.Fecha -match '^\d{4}-\d{2}-\d{2}$'){ $f.Fecha } else { $null }

  $rows += [pscustomobject]@{
    id        = $id
    tipo      = (Get-TipoApp $f.Tipo)
    titulo    = $titulo
    entidad   = 'SERFOR'
    anio      = $anio
    estado    = if($f.Estado -eq 'Vigente'){ 'Vigente' } else { 'Derogada' }
    coleccion = $Coleccion
    fecha     = $fecha
    kb        = [math]::Round($info.Length/1KB)
    archivo   = "documentos/$fname"
    original  = $f.'Nombre de Archivo Local'
  }
}

if($faltantes.Count -gt 0){
  Write-Output ""
  Write-Output ("FALTAN {0} PDF por descargar. Ejecute primero:" -f $faltantes.Count)
  Write-Output "  pwsh -ExecutionPolicy Bypass -File .\descargar_documentos_normativos_opr.ps1"
  $faltantes | Select-Object -First 5 | ForEach-Object { Write-Output "    - $_" }
  if($faltantes.Count -gt 5){ Write-Output ("    ... y {0} mas" -f ($faltantes.Count - 5)) }
}

if($rows.Count -eq 0){
  Write-Output ""
  Write-Output "No se genero catalogo: no hay ningun PDF disponible todavia."
  return
}

$json = ConvertTo-Json -InputObject @($rows) -Depth 4
$salidaPath = if([IO.Path]::IsPathRooted($Salida)){ $Salida } else { Join-Path $root $Salida }
$out = "// Inventario normativo SERFOR - lote OPR, generado desde: indice_opr.csv`r`n// Coleccion: $Coleccion  |  Documentos: $($rows.Count)`r`n// Regenerar con: generar-inventario-opr.ps1`r`nconst INVENTARIO = $json;"
Set-Content -LiteralPath $salidaPath -Value $out -Encoding UTF8

Write-Output ""
Write-Output ("GENERADO: {0} documentos en '{1}'  (coleccion: {2})" -f $rows.Count, $Salida, $Coleccion)
$rows | Group-Object tipo | Sort-Object Count -Descending | ForEach-Object { Write-Output ("  {0,-16} {1}" -f $_.Name, $_.Count) }
$pesados = $rows | Where-Object { $_.kb -gt 50000 }
if($pesados){
  Write-Output ""
  Write-Output ("AVISO: {0} archivo(s) superan los 50 MB y fallaran al subir (limite del plan gratuito):" -f $pesados.Count)
  $pesados | ForEach-Object { Write-Output ("    - {0} ({1} MB)" -f $_.original, [math]::Round($_.kb/1024,1)) }
}
