[Console]::OutputEncoding=[System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

# =====================================================================
# Build video: Maquila MTO con materiales configurables
# Pipeline: Sabina TTS (es-MX, SSML) + msedge headless + FFmpeg
# =====================================================================

$root = $PSScriptRoot
if(-not $root){ $root = Split-Path -Parent $MyInvocation.MyCommand.Path }
$presentacion = Join-Path (Split-Path -Parent $root) "maquila-mto-kmat-presentacion.html"
Write-Host "Root: $root"
Write-Host "HTML: $presentacion (exists=$(Test-Path $presentacion))"

$audioDir = Join-Path $root "audio"
$imgDir   = Join-Path $root "frames"
$segDir   = Join-Path $root "segments"
if(-not (Test-Path $audioDir)){ [System.IO.Directory]::CreateDirectory($audioDir) | Out-Null }
if(-not (Test-Path $imgDir)){   [System.IO.Directory]::CreateDirectory($imgDir)   | Out-Null }
if(-not (Test-Path $segDir)){   [System.IO.Directory]::CreateDirectory($segDir)   | Out-Null }

# --- Locate FFmpeg ---
$ffExe = (Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg*" -Filter ffmpeg.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
if(-not $ffExe){ throw "FFmpeg no encontrado" }
Write-Host "FFmpeg: $ffExe"

# --- Locate Edge ---
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if(-not (Test-Path $edge)){ $edge = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }
if(-not (Test-Path $edge)){ throw "msedge.exe no encontrado" }
Write-Host "Edge:  $edge"

# =====================================================================
# Narrations as SSML -Mexican Spanish (es-MX)
# Convenciones:
#   <say-as interpret-as="spell-out">XYZ</say-as>  → deletrea letras
#   <break time="Nms"/>                            → pausas
#   <sub alias="cómo pronunciar">texto escrito</sub>
#   <emphasis>palabra</emphasis>                   → énfasis natural
#   <prosody rate="-5%">                           → velocidad ligeramente más lenta
# =====================================================================

$ssmlHeader = '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="es-MX"><prosody rate="-5%">'
$ssmlFooter = '</prosody></speak>'

$narrationBodies = @(
# 1 · Title
@'
Bienvenidos a la presentación de Aliacer.
<break time="500ms"/>
Maquila al cliente bajo el modelo <sub alias="meik tu order">make to order</sub>,
<break time="200ms"/>
con materiales configurables.
'@,

# 2 · Overview
@'
Cuando el cliente nos pide una variante específica del producto,
<break time="250ms"/>
en lugar de fabricar contra inventario,
<break time="200ms"/>
su pedido dispara la producción.
<break time="400ms"/>
El cliente arma su propia receta eligiendo opciones del menú,
y el sistema genera automáticamente lo que sigue.
'@,

# 3 · Roles
@'
Cinco áreas intervienen en el flujo.
<break time="300ms"/>
Ventas captura el pedido.
<break time="200ms"/>
Planeación corre el <say-as interpret-as="spell-out">MRP</say-as>.
<break time="200ms"/>
Producción fabrica.
<break time="200ms"/>
Almacén recibe y embarca.
<break time="200ms"/>
Y Facturación cierra el ciclo.
'@,

# 4 · Step 1
@'
<emphasis>Paso uno.</emphasis>
<break time="300ms"/>
El cliente nos pide algo a la medida.
<break time="300ms"/>
Por ejemplo:
<break time="200ms"/>
rollos calibre veintiséis,
ancho cuarenta y ocho pulgadas,
<sub alias="galvalume">galvalume</sub>,
con flor regular,
color blanco mate.
<break time="400ms"/>
Esa combinación nunca la tenemos en stock.
La fabricamos cuando él la pide.
'@,

# 5 · Step 2
@'
<emphasis>Paso dos.</emphasis>
<break time="300ms"/>
Elegimos las opciones del menú.
<break time="300ms"/>
Al teclear el código del producto,
el sistema abre la pantalla de configuración.
<break time="300ms"/>
Marcamos calibre, ancho, recubrimiento, acabado, color.
<break time="400ms"/>
Las opciones se filtran solas según las que ya elegimos.
'@,

# 6 · Decision
@'
<emphasis>Punto de decisión.</emphasis>
<break time="400ms"/>
¿El cliente nos da su propia materia prima?
<break time="500ms"/>
Si la respuesta es sí,
vamos al escenario <say-as interpret-as="spell-out">CFM</say-as>.
<break time="300ms"/>
Si la respuesta es no,
nosotros ponemos el material y cobramos todo.
'@,

# 7 · Step 3 CFM
@'
<emphasis>Paso tres. Variante <say-as interpret-as="spell-out">CFM</say-as>.</emphasis>
<break time="400ms"/>
Si el cliente nos manda sus rollos,
los recibimos a un compartimento especial.
<break time="400ms"/>
Ese material nunca es nuestro.
<break time="300ms"/>
Físicamente está en nuestro almacén,
pero contablemente sigue siendo del cliente.
<break time="400ms"/>
Las mermas también se descuentan de su lote.
'@,

# 8 · Step 3 Standard
@'
<emphasis>Paso tres. Variante estándar.</emphasis>
<break time="400ms"/>
Si nosotros ponemos el material,
planeación corre el <say-as interpret-as="spell-out">MRP</say-as>
y reserva la cantidad exacta etiquetada con el número de pedido.
<break time="400ms"/>
Ese material ya tiene dueño.
<break time="300ms"/>
El sistema lo bloquea para cualquier otro cliente.
'@,

# 9 · Step 4
@'
<emphasis>Paso cuatro.</emphasis>
<break time="300ms"/>
Se crea y libera la orden de producción.
<break time="400ms"/>
La orden hereda la configuración del pedido,
así que la lista de componentes y la ruta de fabricación
ya vienen filtradas.
<break time="300ms"/>
Solo aparecen los pasos y materiales que aplican a esa variante.
'@,

# 10 · Step 5
@'
<emphasis>Paso cinco.</emphasis>
<break time="300ms"/>
La fábrica corta, procesa y confirma cada operación.
<break time="400ms"/>
Si el flujo es <say-as interpret-as="spell-out">CFM</say-as>,
la orden consume el material del cliente,
no el nuestro.
'@,

# 11 · Step 6
@'
<emphasis>Paso seis.</emphasis>
<break time="300ms"/>
El producto terminado entra a inventario,
<break time="200ms"/>
pero apartado.
<break time="400ms"/>
No entra al stock libre,
sino a un compartimento reservado para ese pedido.
<break time="300ms"/>
Aparece bajo el cliente y el número de pedido.
'@,

# 12 · Step 7
@'
<emphasis>Paso siete.</emphasis>
<break time="300ms"/>
Se prepara la entrega y sale al cliente.
<break time="400ms"/>
Almacén hace picking del material apartado,
lo carga al transporte,
y registra la salida.
'@,

# 13 · Step 8
@'
<emphasis>Paso ocho.</emphasis>
<break time="300ms"/>
Le facturamos al cliente.
<break time="400ms"/>
Si el flujo es <say-as interpret-as="spell-out">CFM</say-as>,
la factura cobra solo el servicio de maquila,
no el material.
<break time="300ms"/>
Si es estándar, se cobra todo:
material más servicio.
'@,

# 14 · Glossary
@'
<emphasis>Glosario.</emphasis>
<break time="400ms"/>
Términos clave:
<break time="200ms"/>
<sub alias="meik tu order">make to order</sub>,
<break time="200ms"/>
material configurable,
<break time="200ms"/>
<say-as interpret-as="spell-out">MRP</say-as>,
<break time="200ms"/>
stock especial <say-as interpret-as="spell-out">E</say-as>,
<break time="200ms"/>
<say-as interpret-as="spell-out">CFM</say-as>,
<break time="200ms"/>
stock especial <say-as interpret-as="spell-out">O</say-as>,
<break time="200ms"/>
<say-as interpret-as="spell-out">BOM</say-as>,
<break time="200ms"/>
y ruta.
'@,

# 15 · End
@'
<emphasis>Fin del flujo.</emphasis>
<break time="500ms"/>
Cliente pide, configuramos, planeamos, producimos,
<break time="200ms"/>
recibimos, embarcamos y facturamos.
<break time="500ms"/>
Gracias por su atención.
'@
)

# Assemble full SSML documents
$narrations = $narrationBodies | ForEach-Object { $ssmlHeader + $_ + $ssmlFooter }

# --- Generate TTS WAVs with Microsoft Sabina (es-MX) using SSML ---
Write-Host ""
Write-Host "=== Generando narraciones con Sabina (es-MX, SSML) ==="
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$sabina = $synth.GetInstalledVoices() | Where-Object { $_.VoiceInfo.Name -like '*Sabina*' } | Select-Object -First 1
if(-not $sabina){ throw "Voz Sabina (es-MX) no encontrada" }
$synth.SelectVoice($sabina.VoiceInfo.Name)
$synth.Volume = 100

for($i = 0; $i -lt $narrations.Count; $i++){
    $idx = $i + 1
    $wavPath = Join-Path $audioDir ("slide-{0:00}.wav" -f $idx)
    if(Test-Path $wavPath){ Remove-Item $wavPath -Force }
    $synth.SetOutputToWaveFile($wavPath)
    try {
        $synth.SpeakSsml($narrations[$i])
    } catch {
        Write-Host ("  slide-{0:00} SSML FAIL: {1}" -f $idx, $_.Exception.Message)
        # Fallback: strip XML tags and use plain text
        $plain = [Regex]::Replace($narrationBodies[$i], '<[^>]+>', '')
        $synth.Speak($plain)
    }
    $synth.SetOutputToNull()
    $bytes = (Get-Item $wavPath).Length
    Write-Host ("  slide-{0:00}.wav  {1,6} KB" -f $idx, [Math]::Round($bytes/1024))
}
$synth.Dispose()

# --- Capture slide screenshots with Edge headless (reuse if present) ---
Write-Host ""
Write-Host "=== Capturando slides con Edge headless ==="
$uri = ([System.Uri]$presentacion).AbsoluteUri
$tmpProfile = Join-Path $env:TEMP "edge-hf-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpProfile -Force | Out-Null

for($i = 1; $i -le $narrations.Count; $i++){
    $imgPath = Join-Path $imgDir ("slide-{0:00}.png" -f $i)
    if(Test-Path $imgPath){
        Write-Host ("  slide-{0:00}.png  (reuse)" -f $i)
        continue
    }
    $url = "$uri#$i"
    $args = @(
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--no-sandbox",
        "--user-data-dir=$tmpProfile",
        "--window-size=1920,1080",
        "--virtual-time-budget=2000",
        "--screenshot=$imgPath",
        $url
    )
    Start-Process -FilePath $edge -ArgumentList $args -Wait -WindowStyle Hidden | Out-Null
    if(Test-Path $imgPath){
        Write-Host ("  slide-{0:00}.png  {1,5} KB" -f $i, [Math]::Round((Get-Item $imgPath).Length / 1024))
    }
}
Remove-Item $tmpProfile -Recurse -Force -ErrorAction SilentlyContinue

# --- Build per-slide MP4 segments (image + audio) ---
Write-Host ""
Write-Host "=== Generando segmentos de video por slide ==="
$segmentList = Join-Path $segDir "list.txt"
if(Test-Path $segmentList){ Remove-Item $segmentList -Force }

for($i = 1; $i -le $narrations.Count; $i++){
    $imgPath = Join-Path $imgDir ("slide-{0:00}.png" -f $i)
    $wavPath = Join-Path $audioDir ("slide-{0:00}.wav" -f $i)
    $segPath = Join-Path $segDir ("seg-{0:00}.mp4" -f $i)
    if(Test-Path $segPath){ Remove-Item $segPath -Force }

    $ffArgs = @(
        "-y",
        "-loop", "1",
        "-i", "`"$imgPath`"",
        "-i", "`"$wavPath`"",
        "-c:v", "libx264",
        "-tune", "stillimage",
        "-pix_fmt", "yuv420p",
        "-vf", "scale=1920:1080:flags=lanczos,format=yuv420p",
        "-r", "30",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        "`"$segPath`""
    )
    $logPath = Join-Path $segDir ("ff-{0:00}.log" -f $i)
    Start-Process -FilePath $ffExe -ArgumentList $ffArgs -Wait -NoNewWindow -RedirectStandardError $logPath -RedirectStandardOutput "$logPath.out" | Out-Null
    if(Test-Path $segPath){
        $mb = [Math]::Round((Get-Item $segPath).Length / 1MB, 2)
        Write-Host ("  seg-{0:00}.mp4  {1,5} MB" -f $i, $mb)
        [System.IO.File]::AppendAllText($segmentList, ("file '{0}'`n" -f ("seg-{0:00}.mp4" -f $i)), [System.Text.Encoding]::ASCII)
    } else {
        Write-Host ("  seg-{0:00}.mp4  FAIL -ver $logPath")
    }
}

# --- Concatenate segments into final MP4 ---
Write-Host ""
Write-Host "=== Concatenando segmentos ==="
$finalMp4 = Join-Path $root "video-maquila-kmat.mp4"
if(Test-Path $finalMp4){ Remove-Item $finalMp4 -Force }
$tmpMp4 = Join-Path $segDir "_final.mp4"
if(Test-Path $tmpMp4){ Remove-Item $tmpMp4 -Force }

$concatArgs = @(
    "-y",
    "-f", "concat",
    "-safe", "0",
    "-i", "list.txt",
    "-c", "copy",
    "_final.mp4"
)
$concatLog = Join-Path $root "ff-concat.log"
Start-Process -FilePath $ffExe -ArgumentList $concatArgs -Wait -NoNewWindow -WorkingDirectory $segDir -RedirectStandardError $concatLog -RedirectStandardOutput "$concatLog.out" | Out-Null
if(Test-Path $tmpMp4){
    Move-Item -Path $tmpMp4 -Destination $finalMp4 -Force
}

if(Test-Path $finalMp4){
    $mb = [Math]::Round((Get-Item $finalMp4).Length / 1MB, 2)
    $ffprobe = $ffExe -replace 'ffmpeg\.exe$','ffprobe.exe'
    $dur = & $ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $finalMp4
    $durSec = [Math]::Round([double]$dur, 1)
    Write-Host ""
    Write-Host "===================== LISTO ====================="
    Write-Host "Archivo: $finalMp4"
    Write-Host ("Size: {0} MB  |  Duration: {1} s" -f $mb, $durSec)
    Write-Host "================================================="
} else {
    Write-Host "ERROR: video final no generado -ver $concatLog"
}
