# ============================================================
#  Generador del Inventario Normativo - SERFOR
#  Lee TODOS los PDF de una carpeta origen, los copia a documentos/
#  y genera el catalogo con la coleccion a la que pertenecen.
#
#  Uso normal (regenera el lote base, BORRA y rehace documentos/):
#    pwsh -c "& ./generar-inventario.ps1"
#
#  Agregar un LOTE NUEVO sin tocar lo ya cargado:
#    pwsh -c "& ./generar-inventario.ps1 -Origen 'C:\ruta\PDF nuevos' -Coleccion 'Normativa 2026' -Salida 'inventario-2026.js' -Anexar"
#
#  -Anexar  : no borra documentos/ y omite los PDF cuyo contenido ya este ahi.
#  -Salida  : archivo de catalogo a generar (por defecto inventario.js).
# ============================================================
param(
  [string]$Origen    = "C:\Documentos SERFOR\SERFOR\Documentos PDF\Base de Conocimiento Normas",
  [string]$Coleccion = "Normativa base",
  [string]$Salida    = "inventario.js",
  [switch]$Anexar
)

$src  = $Origen
$dest = $PSScriptRoot
$docs = Join-Path $dest "documentos"

if(-not (Test-Path $src)){ Write-Error "No existe la carpeta origen: $src"; exit 1 }

$previos = @{}   # hash -> nombre, de lo que ya vive en documentos/
if($Anexar){
  if(-not (Test-Path $docs)){ New-Item -ItemType Directory -Path $docs | Out-Null }
  foreach($p in (Get-ChildItem -LiteralPath $docs -File -Filter *.pdf)){
    $previos[(Get-FileHash -LiteralPath $p.FullName -Algorithm MD5).Hash] = $p.Name
  }
  Write-Output ("Modo -Anexar: se conservan {0} documentos ya existentes." -f $previos.Count)
} else {
  # Limpiar y recrear carpeta de documentos del sitio
  if(Test-Path $docs){ Remove-Item -LiteralPath $docs -Recurse -Force }
  New-Item -ItemType Directory -Path $docs | Out-Null
}

$files = Get-ChildItem -LiteralPath $src -Recurse -File -Filter *.pdf

function Get-Tipo($n){
  if($n -match 'DIRECTIVA|Directiva'){return 'Directiva'}
  elseif($n -match 'REGLAMENTO|Reglamento'){return 'Reglamento'}
  elseif($n -match 'ORDENANZA'){return 'Ordenanza'}
  elseif($n -match '\bTUO\b'){return 'TUO'}
  elseif($n -match 'DECRETO.?LEGISLATIVO|LEGISLATIVO|\bDL[ _-]?1\d{3}\b|\bDLeg'){return 'Decreto Legislativo'}
  elseif($n -match 'DECRETO DE URGENCIA|Decreto de Urgencia'){return 'Decreto de Urgencia'}
  elseif($n -match 'DECRETO.?SUPREMO|Decreto Supremo|\bD\.?S\.?\b|\bDS[ _-]?\d|ds-0|ds_0|d-s-n'){return 'Decreto Supremo'}
  elseif($n -match 'RESOLUC|Resoluc|\bRD[ _-]|\bRDE|\bRGG|\bRSG|\bRM-|\bRJ_|R\.D\.E|R\.M\.'){return 'Resolucion'}
  elseif($n -match 'POL.TICA|Pol.tica'){return 'Politica'}
  elseif($n -match '\bPEI\b|\bPOI\b|\bPLAN\b|\bPlan\b'){return 'Plan'}
  elseif($n -match 'ESTRATEGIA|Estrategia'){return 'Estrategia'}
  elseif($n -match 'LINEAMIENTO|Lineamiento'){return 'Lineamientos'}
  elseif($n -match 'GU.A|Gu.a'){return 'Guia'}
  elseif($n -match 'MANUAL|Manual|\bMOP\b'){return 'Manual'}
  elseif($n -match 'PROCEDIMIENTO|Procedimiento'){return 'Procedimiento'}
  elseif($n -match '\bLEY\b|\bley\b|Ley '){return 'Ley'}
  elseif($n -match 'NORMAS|NORMA '){return 'Norma'}
  else{return 'Otros'}
}

function Get-Entidad($n){
  $u = $n.ToUpper()
  if($u -match 'SERFOR'){return 'SERFOR'}
  elseif($u -match 'GENERAL-0000|DIRECTIVA GENERAL|GERENCIA GENERAL|-GG\b|GG - |GG\.|-DE\b|-OGA|-OGPP|-OG\b'){return 'SERFOR'}
  elseif($u -match 'MIDAGRI|MINAGRI'){return 'MIDAGRI'}
  elseif($u -match 'PCM|SGTD|SGD|SEGDI|SG-OACID'){return 'PCM'}
  elseif($u -match 'OSCE'){return 'OSCE'}
  elseif($u -match 'TCE|OECE'){return 'OECE'}
  elseif($u -match '\bEF\b|EF54|EF52|EF-5|EF 5|EF51'){return 'MEF'}
  elseif($u -match 'INEI'){return 'INEI'}
  elseif($u -match 'JUS|RENIEC'){return 'MINJUS / otros'}
  elseif($u -match 'VIVIENDA'){return 'MVCS'}
  elseif($u -match 'MINAM'){return 'MINAM'}
  elseif($u -match 'SERVIR|RIS|SERVIDORES CIVILES'){return 'SERVIR'}
  elseif($u -match 'MINEM'){return 'MINEM'}
  elseif($u -match '-MM\b|MUNICIPAL|ORDENANZA'){return 'Municipal'}
  else{return 'Nacional / Otros'}
}

function Get-Anio($n,$path){
  $m = [regex]::Matches($n,'(19|20)\d{2}')
  $best = $null
  foreach($x in $m){ $y=[int]$x.Value; if($y -ge 1990 -and $y -le 2027){ if(-not $best -or $y -gt $best){$best=$y} } }
  if(-not $best){ if($path -match 'PDF (20\d{2})'){ $best=[int]$Matches[1] } }   # carpeta PDF 20xx
  return $best
}

function Get-Titulo($n){
  $t = [System.IO.Path]::GetFileNameWithoutExtension($n)
  $t = $t -replace '^\d{6,}-',''
  $t = $t -replace '^\[\d+\]\s*-\s*',''
  $t = $t -replace '\s*-\s*\d{6}$',''
  $t = $t -replace '_vf.*$',''
  $t = $t -replace '-f-f|_f_f|\[F\]|\[1\]|\(2\)|\(1\)|_Copiar|\.pdf$',''
  $t = $t -replace '\s{2,}',' '
  $t = $t.Trim(' ','-','_')
  return $t
}

function Get-Slug($n){
  $t = [System.IO.Path]::GetFileNameWithoutExtension($n)
  # Quitar acentos via normalizacion Unicode (sin literales acentuados)
  $norm = $t.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object System.Text.StringBuilder
  foreach($ch in $norm.ToCharArray()){
    if([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark){ [void]$sb.Append($ch) }
  }
  $t = $sb.ToString()
  $t = $t -replace '[^a-zA-Z0-9]+','_'
  $t = $t.Trim('_')
  if($t.Length -gt 70){ $t = $t.Substring(0,70) }
  return $t.ToLower()
}

$rows = @()
$used = @{}
$hashes = @{}
$id = 0
$dupCount = 0
$yaEstaban = 0
foreach($f in ($files | Sort-Object Name)){
  # dedupe por contenido (hash) para eliminar copias idénticas
  $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5).Hash
  if($hashes.ContainsKey($h)){ $dupCount++; continue }
  # en modo -Anexar, omitir lo que ya vive en documentos/ (mismo contenido)
  if($previos.ContainsKey($h)){ $yaEstaban++; continue }
  $hashes[$h] = $true

  $id++
  $slug = Get-Slug $f.Name
  $fname = "$slug.pdf"
  if($used.ContainsKey($fname) -or (Test-Path -LiteralPath (Join-Path $docs $fname))){ $fname = "$slug`_$id.pdf" }
  $used[$fname] = $true
  Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $docs $fname) -Force

  $rows += [pscustomobject]@{
    id=$id
    tipo=(Get-Tipo $f.Name)
    titulo=(Get-Titulo $f.Name)
    entidad=(Get-Entidad $f.Name)
    anio=(Get-Anio $f.Name $f.FullName)
    estado='Vigente'
    coleccion=$Coleccion
    fecha=$f.LastWriteTime.ToString('yyyy-MM-dd')
    kb=[math]::Round($f.Length/1KB)
    archivo="documentos/$fname"
    original=$f.Name
  }
}

# -InputObject @(...) evita que un solo elemento se serialice como objeto en vez de lista
$json = if($rows.Count -eq 0){ '[]' } else { ConvertTo-Json -InputObject @($rows) -Depth 4 }
$salidaPath = if([IO.Path]::IsPathRooted($Salida)){ $Salida } else { Join-Path $dest $Salida }

# Nada nuevo que anexar: no pisar el catalogo anterior
if($rows.Count -eq 0 -and $Anexar -and (Test-Path -LiteralPath $salidaPath)){
  Write-Output "Sin documentos nuevos: se conserva el catalogo '$Salida' tal como estaba."
  Write-Output "  duplicados identicos omitidos: $dupCount  |  ya presentes en documentos/: $yaEstaban"
  return
}

$out = "// Inventario normativo SERFOR - generado desde: $src`r`n// Coleccion: $Coleccion  |  Documentos: $($rows.Count)`r`n// Regenerar con: generar-inventario.ps1`r`nconst INVENTARIO = $json;"
Set-Content -LiteralPath $salidaPath -Value $out -Encoding UTF8

Write-Output "GENERADO: $($rows.Count) documentos en '$Salida'  (coleccion: $Coleccion)"
Write-Output "  duplicados idénticos omitidos: $dupCount  |  ya presentes en documentos/: $yaEstaban"
$rows | Group-Object tipo | Sort-Object Count -Descending | ForEach-Object { Write-Output ("  {0,-22} {1}" -f $_.Name,$_.Count) }
Write-Output "Peso total copiado: $([math]::Round((Get-ChildItem $docs -Filter *.pdf | Measure-Object Length -Sum).Sum/1MB,1)) MB"