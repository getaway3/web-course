. "$PSScriptRoot\demo_common.ps1"
Set-Win "Показ ПР1-ПР5"

$items = @(
    @{ Key = "1"; File = "demo_pr1.ps1"; Text = "ПР1. Первый backend на FastAPI" },
    @{ Key = "2"; File = "demo_pr2.ps1"; Text = "ПР2. REST API (GET, POST, DELETE)" },
    @{ Key = "3"; File = "demo_pr3.ps1"; Text = "ПР3. PostgreSQL в Docker + psycopg" },
    @{ Key = "4"; File = "demo_pr4.ps1"; Text = "ПР4. SQLAlchemy ORM" },
    @{ Key = "5"; File = "demo_pr5.ps1"; Text = "ПР5. Рефакторинг" }
)

while ($true) {
    Title "ПОКАЗ ПРАКТИК ПО ВЕБ-ПРИЛОЖЕНИЯМ (Жучок)"
    Say "Выбери практику цифрой и нажми Enter. В каждой практике дальше идёшь клавишей Enter."
    Write-Host ""
    foreach ($i in $items) { Write-Host ("  {0}  {1}" -f $i.Key, $i.Text) -ForegroundColor White }
    Write-Host ""
    Write-Host "  A  Все пять подряд" -ForegroundColor White
    Write-Host "  0  Выход" -ForegroundColor White
    Write-Host ""
    $c = (Read-Host "Твой выбор").Trim().ToUpper()
    if ($c -eq "0") { break }
    if ($c -eq "A" -or $c -eq "А") {
        foreach ($i in $items) { & (Join-Path $PSScriptRoot $i.File) }
        continue
    }
    $pick = $items | Where-Object { $_.Key -eq $c }
    if ($pick) { & (Join-Path $PSScriptRoot $pick.File) }
}
Stop-Server
