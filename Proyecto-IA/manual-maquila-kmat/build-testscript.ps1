# Build Word test script (.docx) from JSON data via Word COM.
# ASCII-only script; all accented Spanish content lives in the UTF-8 JSON.
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
if(-not $root){ $root = Split-Path -Parent $MyInvocation.MyCommand.Path }
$jsonPath = Join-Path $root "testscript-data.json"
$outPath  = Join-Path $root "script-pruebas-maquila-kmat.docx"

Write-Host "Root: $root"
Write-Host "JSON: $jsonPath (exists=$(Test-Path $jsonPath))"

# Read JSON forcing UTF-8 (avoids PS 5.1 codepage mojibake)
$jsonText = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
$data = $jsonText | ConvertFrom-Json

# Colors (Word uses BGR int, like Excel)
$OCEAN = 95*65536 + 58*256 + 31      # #1F3A5F
$WHITE = 16777215
$ACCENT = 27*65536 + 95*256 + 216    # #D85F1B -> B=27 G=95 R=216
$GRAYBG = 0xF0EEE8

# Word constants
$wdStory = 6
$wdAlignLeft = 0; $wdAlignCenter = 1
$wdFormatDocx = 16

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

try {
    $doc = $word.Documents.Add()
    $sel = $word.Selection

    # Page margins (in points; 1 inch = 72 pt)
    $doc.PageSetup.TopMargin = 54
    $doc.PageSetup.BottomMargin = 54
    $doc.PageSetup.LeftMargin = 54
    $doc.PageSetup.RightMargin = 54

    function Para([string]$text, [int]$size, [bool]$bold, [int]$color, [int]$align, [int]$spaceAfter){
        $sel.ParagraphFormat.Alignment = $align
        $sel.ParagraphFormat.SpaceAfter = $spaceAfter
        $sel.Font.Name = "Calibri"
        $sel.Font.Size = $size
        $sel.Font.Bold = $bold
        $sel.Font.Color = $color
        $sel.TypeText($text)
        $sel.TypeParagraph()
    }

    function Bullets($items){
        foreach($it in $items){
            $sel.ParagraphFormat.Alignment = $wdAlignLeft
            $sel.ParagraphFormat.SpaceAfter = 3
            $sel.Font.Name = "Calibri"; $sel.Font.Size = 10.5; $sel.Font.Bold = $false; $sel.Font.Color = 0x333333
            $sel.TypeText([char]0x2022 + "  " + [string]$it)
            $sel.TypeParagraph()
        }
    }

    # ============ TITLE BLOCK ============
    Para $data.titulo 26 $true $OCEAN $wdAlignLeft 4
    Para $data.subtitulo 14 $false 0x4A4D55 $wdAlignLeft 2
    Para $data.sistema 11 $true $ACCENT $wdAlignLeft 12

    # ============ META TABLE ============
    $metaRows = $data.meta.Count
    $rng = $sel.Range
    $tbl = $doc.Tables.Add($rng, $metaRows, 2)
    $tbl.Borders.Enable = $true
    $tbl.Range.Font.Name = "Calibri"
    $tbl.Range.Font.Size = 10
    $tbl.Columns.Item(1).Width = 130
    $tbl.Columns.Item(2).Width = 360
    for($i=0; $i -lt $metaRows; $i++){
        $r = $i + 1
        $k = [string]$data.meta[$i][0]
        $v = [string]$data.meta[$i][1]
        $c1 = $tbl.Cell($r,1).Range; $c1.Text = $k; $c1.Font.Bold = $true; $c1.Font.Color = $OCEAN
        $tbl.Cell($r,1).Shading.BackgroundPatternColor = $GRAYBG
        $c2 = $tbl.Cell($r,2).Range; $c2.Text = $v; $c2.Font.Bold = $false; $c2.Font.Color = 0x222222
    }
    $sel.EndKey($wdStory) | Out-Null
    $sel.TypeParagraph()

    # ============ OBJETIVO ============
    Para "1. Objetivo" 14 $true $OCEAN $wdAlignLeft 4
    Para ([string]$data.objetivo) 10.5 $false 0x333333 $wdAlignLeft 10

    # ============ ALCANCE ============
    Para "2. Alcance de la prueba" 14 $true $OCEAN $wdAlignLeft 4
    Bullets $data.alcance
    $sel.TypeParagraph()

    # ============ PRECONDICIONES ============
    Para "3. Precondiciones generales" 14 $true $OCEAN $wdAlignLeft 4
    Bullets $data.precondiciones
    $sel.TypeParagraph()

    # ============ LEYENDA ============
    Para ([string]$data.leyenda) 9.5 $true 0x6B2E0A $wdAlignLeft 12

    # ============ CASOS DE PRUEBA ============
    Para "4. Casos de prueba" 14 $true $OCEAN $wdAlignLeft 8

    $caseNum = 0
    foreach($caso in $data.casos){
        $caseNum++

        # Case heading
        $sel.ParagraphFormat.Alignment = $wdAlignLeft
        $sel.ParagraphFormat.SpaceBefore = 8
        $sel.ParagraphFormat.SpaceAfter = 2
        $sel.Font.Name = "Calibri"; $sel.Font.Size = 13; $sel.Font.Bold = $true; $sel.Font.Color = $WHITE
        $sel.Shading.BackgroundPatternColor = $OCEAN
        $sel.TypeText("  " + [string]$caso.id + "   |   " + [string]$caso.transaccion + "   |   " + [string]$caso.nombre + "  ")
        $sel.TypeParagraph()
        # reset shading
        $sel.Shading.BackgroundPatternColor = -16777216
        $sel.ParagraphFormat.SpaceBefore = 0

        Para ("Objetivo: " + [string]$caso.objetivo) 10 $false 0x333333 $wdAlignLeft 2
        Para ("Precondiciones: " + [string]$caso.precondiciones) 10 $false 0x333333 $wdAlignLeft 6

        # Steps table: header + N steps
        $nSteps = $caso.pasos.Count
        $rng2 = $sel.Range
        $st = $doc.Tables.Add($rng2, $nSteps + 1, 6)
        $st.Borders.Enable = $true
        $st.Range.Font.Name = "Calibri"
        $st.Range.Font.Size = 9
        $st.Columns.Item(1).Width = 28
        $st.Columns.Item(2).Width = 120
        $st.Columns.Item(3).Width = 110
        $st.Columns.Item(4).Width = 120
        $st.Columns.Item(5).Width = 70
        $st.Columns.Item(6).Width = 42

        $headers = @("#","Accion","Datos de entrada","Resultado esperado","Resultado obtenido","Estado")
        for($c=0; $c -lt 6; $c++){
            $hc = $st.Cell(1, $c+1).Range
            $hc.Text = $headers[$c]
            $hc.Font.Bold = $true
            $hc.Font.Color = $WHITE
            $st.Cell(1, $c+1).Shading.BackgroundPatternColor = $OCEAN
        }
        for($s=0; $s -lt $nSteps; $s++){
            $rr = $s + 2
            $paso = $caso.pasos[$s]
            $st.Cell($rr,1).Range.Text = [string]($s+1)
            $st.Cell($rr,2).Range.Text = [string]$paso[0]
            $st.Cell($rr,3).Range.Text = [string]$paso[1]
            $st.Cell($rr,4).Range.Text = [string]$paso[2]
            $st.Cell($rr,5).Range.Text = ""
            $st.Cell($rr,6).Range.Text = ""
        }
        $sel.EndKey($wdStory) | Out-Null
        $sel.TypeParagraph()
    }

    # ============ FIRMA ============
    Para "5. Cierre y firma" 14 $true $OCEAN $wdAlignLeft 6
    foreach($linea in $data.firma){
        Para ([string]$linea) 10 $false 0x222222 $wdAlignLeft 8
    }

    # ============ SAVE ============
    if(Test-Path $outPath){ Remove-Item $outPath -Force }
    $savePath = [string]$outPath
    $doc.SaveAs2($savePath, $wdFormatDocx)
    $doc.Close()
    Write-Host ""
    Write-Host "LISTO: $outPath"
    if(Test-Path $outPath){ Write-Host ("Tamano: {0} KB" -f [Math]::Round((Get-Item $outPath).Length/1024)) }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    Write-Host "Linea: $($_.InvocationInfo.ScriptLineNumber)"
    throw
}
finally {
    try { $word.Quit() } catch {}
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
}
