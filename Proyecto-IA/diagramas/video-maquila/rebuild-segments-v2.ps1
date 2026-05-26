[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$audioDir = Join-Path $root "audio-v2"
$imgDir   = Join-Path $root "frames"
$segDir   = Join-Path $root "segments-v2"

$ffExe = (Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg*" -Filter ffmpeg.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
Write-Host "FFmpeg: $ffExe"

Write-Host ""
Write-Host "=== Generando segmentos de video (v2) ==="
$segmentList = Join-Path $segDir "list.txt"
if (Test-Path $segmentList) { Remove-Item $segmentList -Force }

for ($i = 1; $i -le 15; $i++) {
  $imgPath = Join-Path $imgDir ("slide-{0:00}.png" -f $i)
  $wavPath = Join-Path $audioDir ("slide-{0:00}.wav" -f $i)
  $segPath = Join-Path $segDir ("seg-{0:00}.mp4" -f $i)
  if (Test-Path $segPath) { Remove-Item $segPath -Force }

  $ffArgs = @(
    "-y", "-loop", "1",
    "-i", "`"$imgPath`"",
    "-i", "`"$wavPath`"",
    "-c:v", "libx264", "-tune", "stillimage",
    "-pix_fmt", "yuv420p",
    "-vf", "scale=1920:1080:flags=lanczos,format=yuv420p",
    "-r", "30",
    "-c:a", "aac", "-b:a", "192k",
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
    Write-Host ("  seg-{0:00}.mp4  FAIL")
  }
}

Write-Host ""
Write-Host "=== Concatenando ==="
$finalMp4 = Join-Path $root "video-maquila-kmat-v2.mp4"
if (Test-Path $finalMp4) { Remove-Item $finalMp4 -Force }
$tmpMp4 = Join-Path $segDir "_final.mp4"
if (Test-Path $tmpMp4) { Remove-Item $tmpMp4 -Force }

$concatLog = Join-Path $root "ff-concat-v2.log"
Start-Process -FilePath $ffExe -ArgumentList @("-y","-f","concat","-safe","0","-i","list.txt","-c","copy","_final.mp4") -Wait -NoNewWindow -WorkingDirectory $segDir -RedirectStandardError $concatLog -RedirectStandardOutput "$concatLog.out" | Out-Null

if (Test-Path $tmpMp4) { Move-Item $tmpMp4 $finalMp4 -Force }

if (Test-Path $finalMp4) {
  $mb = [Math]::Round((Get-Item $finalMp4).Length / 1MB, 2)
  $ffprobe = $ffExe -replace 'ffmpeg\.exe$','ffprobe.exe'
  $dur = & $ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $finalMp4
  Write-Host ""
  Write-Host "===================== LISTO ====================="
  Write-Host "Archivo: $finalMp4"
  Write-Host ("Size: {0} MB  |  Duration: {1} s" -f $mb, [Math]::Round([double]$dur,1))
  Write-Host "================================================="
} else {
  Write-Host "ERROR ver $concatLog"
}
