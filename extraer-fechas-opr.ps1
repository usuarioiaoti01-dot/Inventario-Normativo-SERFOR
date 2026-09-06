# ============================================================
#  Fecha de publicacion de las normas - lote Normativos OPR
#
#  Hoy 115 documentos llevan como fecha el dia en que se copio el archivo,
#  no la de la norma. Este script la saca del PROPIO PDF y genera el SQL
#  para corregirla.
#
#  De donde sale la fecha, por orden de preferencia:
#    1. De otro documento de la MISMA norma que ya tenga fecha oficial
#       (la del indice de OPR). Es la mas fiable: no hay que interpretar nada.
#    2. Del texto de la resolucion: "Magdalena del Mar, 06 de Enero del 2025".
#    3. Del sello de firma digital: "Fecha: 06.01.2025 19:28:21".
#    4. Si nada de eso aparece, se deja SIN fecha. Preferible a inventarla.
#
#  La fecha se aplica a TODOS los documentos de la norma: resolucion,
#  documento, anexo y expediente comparten fecha de aprobacion.
#
#  NO toca los 116 documentos que ya tienen fecha del indice oficial; los usa
#  para comprobarse a si mismo y reportar su tasa de acierto.
#
#  Requiere pdftotext (viene con Git for Windows).
#  Uso:
#    pwsh -ExecutionPolicy Bypass -File .\extraer-fechas-opr.ps1
# ============================================================
param(
  [string]$Salida = "actualizar-fechas-opr.sql"
)

$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
$docs = Join-Path $raiz "documentos"

$pdftotext = (Get-Command pdftotext -ErrorAction SilentlyContinue).Source
if(-not $pdftotext){
  Write-Error "No se encontro pdftotext. Viene con Git for Windows (C:\Program Files\Git\mingw64\bin)."
  exit 1
}

$MESES = @{
  'enero'=1;'febrero'=2;'marzo'=3;'abril'=4;'mayo'=5;'junio'=6;'julio'=7
  'agosto'=8;'setiembre'=9;'septiembre'=9;'octubre'=10;'noviembre'=11;'diciembre'=12
}

function Leer-Catalogo($archivo){
  $p = Join-Path $raiz $archivo
  if(-not (Test-Path -LiteralPath $p)){ return @() }
  $raw = Get-Content -LiteralPath $p -Raw -Encoding UTF8
  $ini = $raw.IndexOf('['); $fin = $raw.LastIndexOf(']')
  return @($raw.Substring($ini, $fin-$ini+1) | ConvertFrom-Json)
}

# Texto de la primera pagina
function Get-Texto($pdf){
  try {
    $t = & $pdftotext -l 1 -q -enc UTF-8 $pdf - 2>$null
    return ($t -join "`n")
  } catch { return "" }
}

# Fecha de emision del TEXTO de la resolucion, o $null.
#  Se exige que vaya precedida del lugar - "Magdalena del Mar, 06 de Enero del 2025" -
#  porque asi encabezan las resoluciones. Sin ese anclaje, la primera fecha de la
#  pagina suele ser la de OTRO documento citado en los VISTOS.
#  Medido sobre 69 resoluciones de fecha conocida: anclada al lugar acierta el 92%;
#  tomando la primera fecha suelta, el 86% y con el doble de errores.
#  La clase [^\W\d_] es "letra" sin listar acentos: mantiene el script en ASCII.
function Get-FechaTexto($t){
  $rx = '([^\W\d_][^\W\d_.]*(?:[ .][^\W\d_]+){0,3}),\s*(\d{1,2})\s+de\s+([^\W\d_]+)\s+d[eo]l?\s+(\d{4})'
  $m = [regex]::Match($t, $rx)
  if($m.Success){
    $mes = $MESES[$m.Groups[3].Value.ToLower()]
    if($mes){
      $d = [int]$m.Groups[2].Value; $a = [int]$m.Groups[4].Value
      if($d -ge 1 -and $d -le 31 -and $a -ge 1990 -and $a -le 2030){
        return ('{0:d4}-{1:d2}-{2:d2}' -f $a, $mes, $d)
      }
    }
  }
  return $null
}

# Respaldo: el sello de la firma digital
function Get-FechaFirma($t){
  $m = [regex]::Match($t, 'Fecha:\s*(\d{2})\.(\d{2})\.(\d{4})')
  if($m.Success){ return ('{0}-{1}-{2}' -f $m.Groups[3].Value, $m.Groups[2].Value, $m.Groups[1].Value) }
  return $null
}

# ---- Reunir todo el lote OPR: archivo, carpeta, parte, fecha oficial ----
$oficial = @{}   # archivo -> fecha del indice de OPR (la de referencia)
$carpetaDe = @{} # archivo -> carpeta
$parteDe = @{}   # archivo -> parte
$todos = New-Object System.Collections.Generic.List[string]

foreach($d in (Leer-Catalogo 'inventario-opr.js')){
  $a = $d.archivo -replace '^documentos/',''
  $todos.Add($a)
  if($d.fecha){ $oficial[$a] = $d.fecha }
}
foreach($d in (Leer-Catalogo 'inventario-complemento.js')){
  $a = $d.archivo -replace '^documentos/',''
  $todos.Add($a)
  $carpetaDe[$a] = $d.carpeta
  $parteDe[$a]   = $d.parte
}
# La carpeta de los ya cargados vive en el SQL que genero el otro script
$sqlCarp = Join-Path $raiz 'actualizar-carpetas-opr.sql'
if(Test-Path -LiteralPath $sqlCarp){
  foreach($l in (Get-Content -LiteralPath $sqlCarp -Encoding UTF8)){
    $m = [regex]::Match($l, "carpeta = '(.*?)', parte = '(.*?)' where archivo = '(.*?)';")
    if($m.Success){
      $carpetaDe[$m.Groups[3].Value] = $m.Groups[1].Value -replace "''","'"
      $parteDe[$m.Groups[3].Value]   = $m.Groups[2].Value
    }
  }
}

Write-Output ("Documentos del lote OPR : {0}" -f $todos.Count)
Write-Output ("Con fecha oficial       : {0}" -f $oficial.Count)
Write-Output ("Agrupados en normas     : {0}" -f (($carpetaDe.Values | Select-Object -Unique).Count))
Write-Output ""

# ---- 1. Fecha conocida por norma, tomada del indice oficial ----
$fechaDeCarpeta = @{}
foreach($a in $todos){
  $c = $carpetaDe[$a]
  if($c -and $oficial.ContainsKey($a) -and -not $fechaDeCarpeta.ContainsKey($c)){
    $fechaDeCarpeta[$c] = $oficial[$a]
  }
}
Write-Output ("Normas con fecha oficial heredable: {0}" -f $fechaDeCarpeta.Count)

# ---- 2. Extraer de los PDF lo que falte ----
Write-Output "Leyendo los PDF..."
$extraida = @{}      # archivo -> fecha leida del PDF
$origenDe = @{}      # archivo -> 'texto' | 'firma'
$leidos = 0
foreach($a in ($todos | Select-Object -Unique)){
  $p = Join-Path $docs $a
  if(-not (Test-Path -LiteralPath $p)){ continue }
  $leidos++
  if($leidos % 50 -eq 0){ Write-Output ("   ...{0}" -f $leidos) }
  $t = Get-Texto $p
  if(-not $t -or $t.Trim().Length -lt 50){ continue }
  $f = Get-FechaTexto $t
  if($f){ $extraida[$a] = $f; $origenDe[$a] = 'texto'; continue }
  $f = Get-FechaFirma $t
  if($f){ $extraida[$a] = $f; $origenDe[$a] = 'firma' }
}
Write-Output ("   PDF leidos: {0} | con fecha detectada: {1}" -f $leidos, $extraida.Count)
Write-Output ""

# ---- 3. Comprobacion: se mide lo que el script REALMENTE hace ----
#  No sirve comparar archivo por archivo: la fecha no se saca de cada PDF, sino
#  de la resolucion de su norma y se propaga al resto. Asi que se simula esa
#  misma decision en las normas cuya fecha oficial ya conocemos.
$ok=0; $casi=0; $mal=0; $sinDato=0
foreach($c in $fechaDeCarpeta.Keys){
  $miembros = @($carpetaDe.Keys | Where-Object { $carpetaDe[$_] -eq $c })
  $res = @($miembros | Where-Object { $parteDe[$_] -eq 'Resolucion' -and $extraida.ContainsKey($_) })
  if($res.Count -eq 0){ $sinDato++; continue }
  $propuesta = $extraida[$res[0]]
  $real = $fechaDeCarpeta[$c]
  if($propuesta -eq $real){ $ok++ }
  else {
    $d1=[datetime]::Parse($propuesta); $d2=[datetime]::Parse($real)
    if([math]::Abs(($d1-$d2).Days) -le 3){ $casi++ } else { $mal++ }
  }
}
Write-Output "COMPROBACION (normas con fecha oficial conocida, simulando la extraccion):"
Write-Output ("   exacta          : {0}" -f $ok)
Write-Output ("   a <=3 dias      : {0}" -f $casi)
Write-Output ("   no coincide     : {0}" -f $mal)
Write-Output ("   sin resolucion legible: {0}" -f $sinDato)
$tot = $ok+$casi+$mal
if($tot -gt 0){
  Write-Output ("   exactas         : {0}%" -f [math]::Round(100*$ok/$tot,1))
  Write-Output ("   dentro de 3 dias: {0}%" -f [math]::Round(100*($ok+$casi)/$tot,1))
}
Write-Output ""

# ---- 4. Fecha final por norma: primero la resolucion ----
$fechaFinalCarpeta = @{}
foreach($c in ($carpetaDe.Values | Select-Object -Unique)){
  if($fechaDeCarpeta.ContainsKey($c)){ $fechaFinalCarpeta[$c] = $fechaDeCarpeta[$c]; continue }
  $miembros = @($carpetaDe.Keys | Where-Object { $carpetaDe[$_] -eq $c })
  $res = @($miembros | Where-Object { $parteDe[$_] -eq 'Resolucion' -and $extraida.ContainsKey($_) })
  if($res.Count -gt 0){ $fechaFinalCarpeta[$c] = $extraida[$res[0]]; continue }
  $otro = @($miembros | Where-Object { $extraida.ContainsKey($_) })
  if($otro.Count -gt 0){ $fechaFinalCarpeta[$c] = $extraida[$otro[0]] }
}

# ---- 5. SQL: solo para los que NO tienen fecha oficial ----
$sql = New-Object System.Collections.Generic.List[string]
$sql.Add("-- ============================================================")
$sql.Add("--  Fecha de publicacion de las normas - lote Normativos OPR")
$sql.Add("--  Generado por extraer-fechas-opr.ps1 - NO editar a mano.")
$sql.Add("--  Solo toca los documentos SIN fecha del indice oficial.")
$sql.Add("--  Ejecutar en: Supabase -> SQL Editor -> New query -> Run")
$sql.Add("-- ============================================================")
$sql.Add("")

$puestas=0; $sinFecha=New-Object System.Collections.Generic.List[string]
foreach($a in ($todos | Select-Object -Unique)){
  if($oficial.ContainsKey($a)){ continue }          # ya tiene la buena
  $c = $carpetaDe[$a]
  $f = $null
  if($c -and $fechaFinalCarpeta.ContainsKey($c)){ $f = $fechaFinalCarpeta[$c] }
  elseif($extraida.ContainsKey($a)){ $f = $extraida[$a] }
  if($f){
    $sql.Add("update public.normativos_opr set fecha = '$f' where archivo = '$($a.Replace("'","''"))';")
    $puestas++
  } else { $sinFecha.Add($a) }
}
$sql.Add("")
$sql.Add("-- Los que no se pudieron fechar se dejan en blanco, para no inventar:")
foreach($a in $sinFecha){ $sql.Add("--   $a") }
if($sinFecha.Count -gt 0){
  $sql.Add("update public.normativos_opr set fecha = null")
  $sql.Add("  where archivo in (" + (($sinFecha | ForEach-Object { "'" + $_.Replace("'","''") + "'" }) -join ", ") + ");")
}
$sql.Add("")
$sql.Add("-- Comprobacion:")
$sql.Add("--   select count(*) from public.normativos_opr where fecha is not null;")

Set-Content -LiteralPath (Join-Path $raiz $Salida) -Value $sql -Encoding UTF8

Write-Output ("RESULTADO: {0} documentos reciben fecha, {1} quedan sin ella." -f $puestas, $sinFecha.Count)
Write-Output ("Generado: {0}" -f $Salida)
$porOrigen = $origenDe.Values | Group-Object | ForEach-Object { "{0}={1}" -f $_.Name, $_.Count }
Write-Output ("Origen de las fechas leidas: {0}" -f ($porOrigen -join '  '))
