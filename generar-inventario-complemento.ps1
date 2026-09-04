# ============================================================
#  Lote "DOCUMENTOS COMPLEMENTO" - Inventario Normativo SERFOR
#
#  Cada CARPETA es una norma; los archivos que contiene se complementan
#  (RESOLUCION, DOCUMENTO, ANEXO, EXPEDIENTE) y en la aplicacion se
#  muestran anidados bajo ella.
#
#  Produce DOS archivos:
#    inventario-complemento.js    catalogo de los PDF que faltan por subir
#    actualizar-carpetas-opr.sql  asigna su carpeta a los que YA estan
#                                 cargados, sin volver a subirlos
#
#  Uso:
#    pwsh -ExecutionPolicy Bypass -File .\generar-inventario-complemento.ps1
#
#  Es repetible: compara por contenido (hash), asi que nunca duplica.
# ============================================================
param(
  [string]$Origen    = "Documentos Normativos OPR\DOCUMENTOS COMPLEMENTO",
  [string]$Coleccion = "Normativos OPR",
  [string]$Salida    = "inventario-complemento.js",
  [string]$SalidaSql = "actualizar-carpetas-opr.sql"
)

$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
$base = if([IO.Path]::IsPathRooted($Origen)){ $Origen } else { Join-Path $raiz $Origen }
$docs = Join-Path $raiz "documentos"

if(-not (Test-Path -LiteralPath $base)){ Write-Error "No existe la carpeta origen: $base"; exit 1 }
if(-not (Test-Path -LiteralPath $docs)){ New-Item -ItemType Directory -Path $docs | Out-Null }

# ---- Lo que ya vive en el lote OPR, indexado por contenido ----
#  Solo se comparan los archivos con prefijo 'opr_', que son los de la tabla
#  normativos_opr. Si un PDF coincide con uno de la Normativa base NO cuenta como
#  cargado: un Especialista no ve esa coleccion, asi que igual hay que subirlo
#  aqui o su carpeta le quedaria incompleta.
$yaCargados = @{}
foreach($f in (Get-ChildItem -LiteralPath $docs -File -Filter opr_*.pdf)){
  $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5).Hash
  if(-not $yaCargados.ContainsKey($h)){ $yaCargados[$h] = $f.Name }
}
Write-Output ("Ya cargados en el lote OPR: {0} archivos." -f $yaCargados.Count)

function Get-Slug($t){
  $norm = $t.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object System.Text.StringBuilder
  foreach($ch in $norm.ToCharArray()){
    if([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark){ [void]$sb.Append($ch) }
  }
  $t = $sb.ToString() -replace '[^a-zA-Z0-9]+','_'
  $t = $t.Trim('_')
  if($t.Length -gt 60){ $t = $t.Substring(0,60) }
  return $t.ToLower()
}

# La parte que cumple cada archivo dentro de su norma
function Get-Parte($nombre){
  if($nombre -match '^\s*RESOLUCION\s*-'){ return 'Resolucion' }
  if($nombre -match '^\s*DOCUMENTO\s*-'){ return 'Documento' }
  if($nombre -match '^\s*ANEXO\s*-'){ return 'Anexo' }
  if($nombre -match '^\s*EXPEDIENTE\s*-'){ return 'Expediente' }
  return 'Documento'
}

# Texto util del nombre del archivo, ya sin el prefijo de parte
function Get-Descripcion($nombre){
  $t = [IO.Path]::GetFileNameWithoutExtension($nombre)
  $t = $t -replace '^\s*(RESOLUCION|DOCUMENTO|ANEXO|EXPEDIENTE)\s*-\s*',''
  $t = $t -replace '[_]+',' '
  $t = $t -replace '\[[A-Za-z0-9]\]',''
  $t = $t -replace '\(\d+\)',''
  $t = $t -replace '\s{2,}',' '
  return $t.Trim(' ','-')
}

# El tipo de norma se decide mirando toda la carpeta
function Get-TipoCarpeta($carpeta, $archivos){
  $todo = ($carpeta + ' ' + ($archivos -join ' ')).ToUpper()
  if($todo -match 'LINEAMIENTO'){ return 'Lineamientos' }
  if($todo -match 'DIRECTIVA'){ return 'Directiva' }
  if($todo -match 'PROTOCOLO|PROCEDIMIENTO'){ return 'Procedimiento' }
  if($todo -match 'MANUAL'){ return 'Manual' }
  # OJO: 'PLAN\b' NO sirve. El guion bajo cuenta como caracter de palabra, asi que
  # no habria limite en 'PLAN_NACIONAL...', y muchos archivos usan guiones bajos.
  # Se exige un separador explicito para no confundirlo con PLANIFICACION o PLANTA.
  if($todo -match 'PLAN[\s_\-]'){ return 'Plan' }
  if($todo -match 'GUIA'){ return 'Guia' }
  return 'Resolucion'
}

function Get-Anio($carpeta){
  $m = [regex]::Matches($carpeta,'(19|20)\d{2}')
  $mejor = $null
  foreach($x in $m){ $y=[int]$x.Value; if($y -ge 1990 -and $y -le 2030){ if(-not $mejor -or $y -gt $mejor){ $mejor=$y } } }
  return $mejor
}

$nuevos = @()          # filas que hay que subir
$reasignar = @()       # ya cargados: solo se les asigna su carpeta
$asignados = @{}       # archivo -> carpeta, para no asignarlo dos veces
$carpetasGemelas = @() # carpetas del origen con identico contenido
$vacias = @()
$dupInternos = 0
$vistos = @{}
$id = 0

foreach($dir in (Get-ChildItem -LiteralPath $base -Directory | Sort-Object Name)){
  $archivos = @(Get-ChildItem -LiteralPath $dir.FullName -File -Filter *.pdf | Sort-Object Name)
  if($archivos.Count -eq 0){ $vacias += $dir.Name; continue }

  $carpeta = $dir.Name
  $tipo    = Get-TipoCarpeta $carpeta $archivos.Name
  $anio    = Get-Anio $carpeta

  foreach($a in $archivos){
    $h = (Get-FileHash -LiteralPath $a.FullName -Algorithm MD5).Hash
    $parte = Get-Parte $a.Name

    if($yaCargados.ContainsKey($h)){
      # Mismo contenido ya subido: no se resube, solo se le dice a que carpeta pertenece.
      # Si el MISMO archivo aparece en dos carpetas del origen (numero de norma escrito
      # de dos formas), se queda con la primera: una fila no puede estar en dos sitios.
      $nombre = $yaCargados[$h]
      if($asignados.ContainsKey($nombre)){
        if($asignados[$nombre] -ne $carpeta){
          $carpetasGemelas += "$($asignados[$nombre])  ==  $carpeta"
        }
        continue
      }
      $asignados[$nombre] = $carpeta
      $reasignar += [pscustomobject]@{ archivo=$nombre; carpeta=$carpeta; parte=$parte }
      continue
    }
    if($vistos.ContainsKey($h)){ $dupInternos++; continue }
    $vistos[$h] = $true

    $id++
    $fname = "opr_" + (Get-Slug ($carpeta + '_' + $parte)) + "_$id.pdf"
    Copy-Item -LiteralPath $a.FullName -Destination (Join-Path $docs $fname) -Force

    # El titulo describe el archivo, no repite el numero de la norma: ese ya lo
    # muestra la fila padre. Si el nombre no aporta nada, se cae al generico.
    $desc = Get-Descripcion $a.Name
    $titulo = if($desc.Length -gt 3){ "$parte - $desc" } else { "$carpeta - $parte" }

    $nuevos += [pscustomobject]@{
      id        = $id
      tipo      = $tipo
      titulo    = $titulo
      entidad   = 'SERFOR'
      anio      = $anio
      estado    = 'Vigente'
      coleccion = $Coleccion
      carpeta   = $carpeta
      parte     = $parte
      fecha     = $a.LastWriteTime.ToString('yyyy-MM-dd')
      kb        = [math]::Round($a.Length/1KB)
      archivo   = "documentos/$fname"
      original  = $a.Name
    }
  }
}

# ---- Catalogo de lo que falta subir ----
$salidaPath = Join-Path $raiz $Salida
if($nuevos.Count -gt 0){
  $json = ConvertTo-Json -InputObject @($nuevos) -Depth 4
  $out = "// Inventario normativo SERFOR - lote DOCUMENTOS COMPLEMENTO`r`n// Coleccion: $Coleccion  |  Documentos: $($nuevos.Count)`r`n// Regenerar con: generar-inventario-complemento.ps1`r`nconst INVENTARIO = $json;"
  Set-Content -LiteralPath $salidaPath -Value $out -Encoding UTF8
} else {
  Write-Output "Sin archivos nuevos: no se genera catalogo."
}

# ---- Asignacion de carpeta a lo que ya estaba cargado ----
$sqlPath = Join-Path $raiz $SalidaSql
$sql = New-Object System.Collections.Generic.List[string]
$sql.Add("-- ============================================================")
$sql.Add("--  Asigna carpeta y parte a los documentos del lote OPR que YA")
$sql.Add("--  estaban cargados, para que se agrupen igual que los nuevos.")
$sql.Add("--  Generado por generar-inventario-complemento.ps1 - NO editar a mano.")
$sql.Add("--  Ejecutar en: Supabase -> SQL Editor -> New query -> Run")
$sql.Add("-- ============================================================")
$sql.Add("")
foreach($r in $reasignar){
  $c = $r.carpeta.Replace("'","''")
  $a = $r.archivo.Replace("'","''")
  $p = $r.parte
  $sql.Add("update public.normativos_opr set carpeta = '$c', parte = '$p' where archivo = '$a';")
}
$sql.Add("")
$sql.Add("-- Comprobacion:")
$sql.Add("--   select carpeta, count(*) from public.normativos_opr where carpeta is not null group by carpeta order by 2 desc;")
Set-Content -LiteralPath $sqlPath -Value $sql -Encoding UTF8

Write-Output ""
Write-Output ("NUEVOS a subir        : {0}" -f $nuevos.Count)
Write-Output ("YA cargados, reagrupar: {0}" -f $reasignar.Count)
Write-Output ("Duplicados internos   : {0}" -f $dupInternos)
Write-Output ("Carpetas vacias       : {0}" -f $vacias.Count)
foreach($v in $vacias){ Write-Output "    - $v" }
if($carpetasGemelas.Count -gt 0){
  $g = $carpetasGemelas | Select-Object -Unique
  Write-Output ""
  Write-Output ("AVISO: {0} par(es) de carpetas con el MISMO contenido (el numero de norma" -f $g.Count)
  Write-Output "       esta escrito de dos formas). Se conserva la primera de cada par:"
  foreach($x in $g){ Write-Output "    - $x" }
}
if($nuevos.Count -gt 0){
  Write-Output ""
  Write-Output ("Peso de lo nuevo: {0} MB" -f [math]::Round(($nuevos | Measure-Object kb -Sum).Sum/1024,1))
  $nuevos | Group-Object tipo | Sort-Object Count -Descending | ForEach-Object { Write-Output ("  {0,-16} {1}" -f $_.Name,$_.Count) }
}
