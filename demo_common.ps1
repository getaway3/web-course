# Общие функции для пошаговых показов ПР1-ПР5. Подключается командой:  . "$PSScriptRoot\demo_common.ps1"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONIOENCODING = "utf-8"
$env:PATH = $env:PATH + ";C:\Program Files\Docker\Docker\resources\bin"
$Root = $PSScriptRoot
$py = Join-Path $Root ".venv\Scripts\python.exe"
if (-not (Test-Path $py)) { $py = "python" }
$Auto = ($env:DEMO_AUTO -eq "1")          # автоматический режим: без пауз и без браузера (для проверки)
$Base = "http://127.0.0.1:8000"

function Set-Win($t) { try { $Host.UI.RawUI.WindowTitle = $t } catch { } }
function Title($text) {
    try { Clear-Host } catch { }
    Write-Host $text -ForegroundColor Green
    Write-Host ""
}
function Say($text) { Write-Host $text -ForegroundColor Yellow }
function Step($n, $title, $explain) {
    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor DarkGray
    Write-Host "ШАГ $n. $title" -ForegroundColor Green
    if ($explain) { Write-Host $explain -ForegroundColor Yellow }
    Write-Host ("=" * 72) -ForegroundColor DarkGray
}
function Cmd($text) { Write-Host "> $text" -ForegroundColor Cyan }
function Next {
    if ($Auto) { return }
    Write-Host ""
    Read-Host "Нажми Enter, чтобы идти дальше" | Out-Null
}
function Open-Url($url) {
    if ($Auto) { Write-Host "(браузер: $url)" -ForegroundColor DarkGray; return }
    Start-Process $url
}

function Stop-Server {
    Get-CimInstance Win32_Process -Filter "Name='python.exe'" |
        Where-Object { $_.CommandLine -like '*uvicorn*' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 700
}
function Start-Server($dir, $module) {
    Stop-Server
    Start-Process -FilePath $py -ArgumentList @("-m", "uvicorn", $module, "--port", "8000") `
        -WorkingDirectory $dir -WindowStyle Minimized
    for ($i = 0; $i -lt 25; $i++) {
        Start-Sleep -Milliseconds 600
        try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "$Base/openapi.json" | Out-Null; return $true } catch { }
    }
    Write-Host "Сервер не запустился. Закрой другие окна с серверами и запусти показ ещё раз." -ForegroundColor Red
    return $false
}

function Api($method, $path, $json = $null) {
    $p = @{ Uri = "$Base$path"; Method = $method; UseBasicParsing = $true; TimeoutSec = 15 }
    if ($json) {
        $p.Body = [System.Text.Encoding]::UTF8.GetBytes($json)
        $p.ContentType = "application/json; charset=utf-8"
    }
    try {
        $r = Invoke-WebRequest @p
        $code = [int]$r.StatusCode
        $body = (New-Object System.IO.StreamReader($r.RawContentStream, [System.Text.Encoding]::UTF8)).ReadToEnd()
    } catch {
        $resp = $_.Exception.Response
        if ($null -eq $resp) { return @{ Code = 0; Body = $_.Exception.Message } }
        $code = [int]$resp.StatusCode
        $st = $resp.GetResponseStream()
        try { $st.Position = 0 } catch { }
        $body = (New-Object System.IO.StreamReader($st, [System.Text.Encoding]::UTF8)).ReadToEnd()
        if ([string]::IsNullOrEmpty($body) -and $_.ErrorDetails -and $_.ErrorDetails.Message) { $body = $_.ErrorDetails.Message }
    }
    return @{ Code = $code; Body = $body }
}
function Show-Api($method, $path, $json = $null) {
    $r = Api $method $path $json
    $color = if ($r.Code -ge 200 -and $r.Code -lt 300) { "Green" } else { "Red" }
    $b = $r.Body; if ($b.Length -gt 230) { $b = $b.Substring(0, 230) + " ..." }
    Write-Host ("{0,-6} {1,-18}" -f $method, $path) -NoNewline
    Write-Host (" -> {0}" -f $r.Code) -ForegroundColor $color -NoNewline
    Write-Host ("   {0}" -f $b)
    return $r
}

function Need-Docker {
    docker info *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Docker не запущен!" -ForegroundColor Red
        Write-Host "Запусти Docker Desktop (значок кита), дождись «Engine running» и запусти показ снова." -ForegroundColor Yellow
        if (-not $Auto) { Read-Host "Нажми Enter, чтобы закрыть" | Out-Null }
        exit 1
    }
}
function Reset-Db($dir) {
    docker rm -f practice_db *> $null
    Push-Location $dir; docker compose down -v *> $null; Pop-Location
}
function Wait-Db {
    for ($i = 0; $i -lt 40; $i++) {
        $s = docker inspect -f "{{.State.Health.Status}}" practice_db 2>$null
        if ($s -eq "healthy") { Write-Host "База данных готова (healthy)." -ForegroundColor Green; return }
        Start-Sleep -Seconds 2
    }
    Write-Host "База не стала healthy вовремя." -ForegroundColor Red
}
function Dc { docker compose @args 2>&1 | ForEach-Object { "$_" } | Write-Host }
function Psql($sql) { docker compose exec -T db psql -U student -d practice -c $sql }

function Finish($lines, $phrase) {
    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor DarkGray
    Write-Host "ИТОГ - ЧТО ДОЛЖНО БЫТЬ:" -ForegroundColor Green
    foreach ($l in $lines) { Write-Host "  [x] $l" }
    Write-Host ""
    Write-Host "Что сказать преподавателю одной фразой:" -ForegroundColor Yellow
    Write-Host "  $phrase"
    Write-Host ""
    if (-not $Auto) { Read-Host "Готово. Нажми Enter, чтобы закрыть" | Out-Null }
}
