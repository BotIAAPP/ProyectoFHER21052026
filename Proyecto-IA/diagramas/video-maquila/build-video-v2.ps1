[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

# =====================================================================
# Build video v2: Maquila MTO con voz Dalia Neural (es-MX) via edge-tts
# Reemplaza pista de audio del video v1 (que usaba Sabina, baja calidad)
# =====================================================================

$root = $PSScriptRoot
if (-not $root) { $root = Split-Path -Parent $MyInvocation.MyCommand.Path }

$audioDir = Join-Path $root "audio-v2"
$imgDir   = Join-Path $root "frames"
$segDir   = Join-Path $root "segments-v2"
foreach ($d in @($audioDir, $segDir)) {
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$ffExe = (Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg*" -Filter ffmpeg.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
if (-not $ffExe) { throw "FFmpeg no encontrado" }
$py = Join-Path $env:LOCALAPPDATA "Programs\Python\Python312\python.exe"
if (-not (Test-Path $py)) { throw "Python no encontrado en $py" }

Write-Host "FFmpeg: $ffExe"
Write-Host "Python: $py"

# Plain-text narrations (SSML del original convertido a texto natural con pausas via comas/punto)
# Las pausas <break time="Nms"/> se reemplazan por puntuación que edge-tts respeta naturalmente.
$narrations = @(
  # 1 Title
  "Bienvenidos a la presentación de Aliacer. Maquila al cliente bajo el modelo make to order, con materiales configurables.",
  # 2 Overview
  "Cuando el cliente nos pide una variante específica del producto, en lugar de fabricar contra inventario, su pedido dispara la producción. El cliente arma su propia receta eligiendo opciones del menú, y el sistema genera automáticamente lo que sigue.",
  # 3 Roles
  "Cinco áreas intervienen en el flujo. Ventas captura el pedido. Planeación calcula los requerimientos de material. Producción fabrica. Almacén recibe y embarca. Y Facturación cierra el ciclo.",
  # 4 Step 1
  "Paso uno. El cliente nos pide algo a la medida. Por ejemplo: rollos calibre veintiséis, ancho cuarenta y ocho pulgadas, galvalume, con flor regular, color blanco mate. Esa combinación nunca la tenemos en existencia. La fabricamos cuando él la pide.",
  # 5 Step 2
  "Paso dos. Elegimos las opciones del menú. Al teclear el código del producto, el sistema abre la pantalla de configuración. Marcamos calibre, ancho, recubrimiento, acabado, color. Las opciones se filtran solas según las que ya elegimos.",
  # 6 Decision
  "Punto de decisión. ¿El cliente nos da su propia materia prima? Si la respuesta es sí, vamos al escenario con material del cliente. Si la respuesta es no, nosotros ponemos el material y cobramos todo.",
  # 7 Step 3 CFM
  "Paso tres. Variante con material del cliente. Si el cliente nos manda sus rollos, los recibimos a un compartimento especial. Ese material nunca es nuestro. Físicamente está en nuestro almacén, pero contablemente sigue siendo del cliente. Las mermas también se descuentan de su lote.",
  # 8 Step 3 Standard
  "Paso tres. Variante estándar. Si nosotros ponemos el material, planeación calcula los requerimientos de material y reserva la cantidad exacta etiquetada con el número de pedido. Ese material ya tiene dueño. El sistema lo bloquea para cualquier otro cliente.",
  # 9 Step 4
  "Paso cuatro. Se crea y libera la orden de producción. La orden hereda la configuración del pedido, así que la lista de componentes y la ruta de fabricación ya vienen filtradas. Solo aparecen los pasos y materiales que aplican a esa variante.",
  # 10 Step 5
  "Paso cinco. La fábrica corta, procesa y confirma cada operación. Si el material es del cliente, la orden consume el material del cliente, no el nuestro.",
  # 11 Step 6
  "Paso seis. El producto terminado entra a inventario, pero apartado. No entra a las existencias libres, sino a un compartimento reservado para ese pedido. Aparece bajo el cliente y el número de pedido.",
  # 12 Step 7
  "Paso siete. Se prepara la entrega y sale al cliente. Almacén prepara y surte el material apartado, lo carga al transporte, y registra la salida.",
  # 13 Step 8
  "Paso ocho. Le facturamos al cliente. Si el material es del cliente, la factura cobra solo el servicio de maquila, no el material. Si es estándar, se cobra todo: material más servicio.",
  # 14 Glossary
  "Glosario. Términos clave: fabricación contra pedido, material configurable, planeación de requerimientos de material, inventario reservado del pedido, material proporcionado por el cliente, inventario consignado del cliente, lista de materiales, y ruta de fabricación.",
  # 15 End
  "Fin del flujo. Cliente pide, configuramos, planeamos, producimos, recibimos, embarcamos y facturamos. Gracias por su atención."
)

# --- Generate TTS WAVs with edge-tts Dalia Neural (es-MX) ---
Write-Host ""
Write-Host "=== Generando narraciones con Dalia Neural (es-MX) ==="
$voice = "es-MX-DaliaNeural"
$rate = "-5%"

# Python helper script
$ttsScript = Join-Path $audioDir "_tts.py"
@'
import truststore; truststore.inject_into_ssl()
import asyncio, sys, edge_tts
async def main():
    voice, rate, text, out = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    c = edge_tts.Communicate(text, voice, rate=rate)
    await c.save(out)
asyncio.run(main())
'@ | Out-File -Encoding utf8 $ttsScript

for ($i = 0; $i -lt $narrations.Count; $i++) {
  $idx = $i + 1
  $mp3 = Join-Path $audioDir ("slide-{0:00}.mp3" -f $idx)
  $wav = Join-Path $audioDir ("slide-{0:00}.wav" -f $idx)
  if (Test-Path $mp3) { Remove-Item $mp3 -Force }
  if (Test-Path $wav) { Remove-Item $wav -Force }

  & $py $ttsScript $voice $rate $narrations[$i] $mp3 2>&1 | Out-Null
  if (-not (Test-Path $mp3)) { throw "TTS fallo en slide $idx" }

  # Convertir MP3 a WAV 48kHz estereo (mejor calidad)
  & $ffExe -y -i $mp3 -ac 2 -ar 48000 -c:a pcm_s16le $wav -loglevel error
  $kb = [Math]::Round((Get-Item $wav).Length / 1KB)
  Write-Host ("  slide-{0:00}.wav  {1,6} KB" -f $idx, $kb)
}

# --- Build per-slide MP4 segments (reusing existing frames) ---
Write-Host ""
Write-Host "=== Generando segmentos de video (v2) ==="
$segmentList = Join-Path $segDir "list.txt"
if (Test-Path $segmentList) { Remove-Item $segmentList -Force }

for ($i = 1; $i -le $narrations.Count; $i++) {
  $imgPath = Join-Path $imgDir ("slide-{0:00}.png" -f $i)
  $wavPath = Join-Path $audioDir ("slide-{0:00}.wav" -f $i)
  $segPath = Join-Path $segDir ("seg-{0:00}.mp4" -f $i)
  if (Test-Path $segPath) { Remove-Item $segPath -Force }

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
  if (Test-Path $segPath) {
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
$finalMp4 = Join-Path $root "video-maquila-kmat-v2.mp4"
if (Test-Path $finalMp4) { Remove-Item $finalMp4 -Force }
$tmpMp4 = Join-Path $segDir "_final.mp4"
if (Test-Path $tmpMp4) { Remove-Item $tmpMp4 -Force }

$concatArgs = @(
  "-y",
  "-f", "concat",
  "-safe", "0",
  "-i", "list.txt",
  "-c", "copy",
  "_final.mp4"
)
$concatLog = Join-Path $root "ff-concat-v2.log"
Start-Process -FilePath $ffExe -ArgumentList $concatArgs -Wait -NoNewWindow -WorkingDirectory $segDir -RedirectStandardError $concatLog -RedirectStandardOutput "$concatLog.out" | Out-Null
if (Test-Path $tmpMp4) {
  Move-Item -Path $tmpMp4 -Destination $finalMp4 -Force
}

if (Test-Path $finalMp4) {
  $mb = [Math]::Round((Get-Item $finalMp4).Length / 1MB, 2)
  $ffprobe = $ffExe -replace 'ffmpeg\.exe$', 'ffprobe.exe'
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
