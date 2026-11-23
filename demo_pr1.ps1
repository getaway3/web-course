. "$PSScriptRoot\demo_common.ps1"
Set-Win "ПР1: первый backend"
Set-Location (Join-Path $Root "practice01")

Title "ПР1. ПЕРВЫЙ BACKEND НА FASTAPI: ПОКАЗ ПО ШАГАМ"
Say "Что мы делаем в первой лабе, простыми словами:"
Write-Host "  Пишем маленькую программу-СЕРВЕР. Ты открываешь в браузере адрес,"
Write-Host "  а программа отвечает данными. Например: адрес /about -> {""course"": ""Web Development""}."
Write-Host "  Программа написана на FastAPI, а запускает её сервер uvicorn."
Next

Step 1 "Проверяем, что всё нужное установлено" "Нужны Python (язык), Git (хранит историю изменений) и две библиотеки: fastapi и uvicorn."
Cmd "python --version"; & $py --version
Cmd "git --version"; git --version
Cmd "pip show fastapi uvicorn"
& $py -m pip show fastapi uvicorn 2>$null | Select-String "^Name|^Version"
Next

Step 2 "Смотрим папку проекта" "В папке practice01: main.py (сама программа), requirements.txt (список библиотек), README.md (описание)."
Cmd "dir"
Get-ChildItem | Format-Table Name, Length -AutoSize | Out-String | Write-Host
Next

Step 3 "Смотрим код (файл main.py)" "Строка @app.get(""/about"") значит «по адресу /about отвечай вот этой функцией». То, что функция вернёт (return), браузер покажет как JSON."
Cmd "Get-Content main.py   (самое важное)"
Write-Host ""
Write-Host 'app = FastAPI()                      <- создали приложение' -ForegroundColor White
Write-Host ''
Write-Host '@app.get("/")                        <- адрес "/" (главная страница)' -ForegroundColor White
Write-Host 'async def root():' -ForegroundColor White
Write-Host '    return {"message": "Hello Web"}  <- вот что увидит браузер' -ForegroundColor White
Write-Host ''
Write-Host '@app.get("/info")                    <- твоё индивидуальное задание' -ForegroundColor White
Write-Host '    return {"theme": "Pet Clinic", ...}' -ForegroundColor White
Write-Host ""
Write-Host "Все адреса в файле (команда ищет строки с @app.get):" -ForegroundColor DarkGray
Select-String -Path main.py -Pattern '^@app\.get' | ForEach-Object { Write-Host ("  " + $_.Line) }
Next

Step 4 "Запускаем сервер" "Команда включает сервер в отдельном свёрнутом окне. Адрес сервера: http://127.0.0.1:8000"
Cmd "python -m uvicorn main:app --reload"
if (-not (Start-Server (Get-Location).Path "main:app")) { exit 1 }
Write-Host "Сервер запущен." -ForegroundColor Green
Next

Step 5 "Открываем главную страницу в браузере" "Сейчас откроется браузер. Ты должна увидеть: {""message"":""Hello Web""}. Это и есть ответ нашей программы."
Open-Url "$Base/"
Next

Step 6 "Открываем Swagger (панель с кнопками)" "Откроется /docs. Нажми на любой адрес -> Try it out -> Execute. Внизу увидишь ответ и код 200 (200 = всё хорошо)."
Open-Url "$Base/docs"
Next

Step 7 "Проверяем все 7 адресов подряд" "Программа сама обращается к каждому адресу и показывает код ответа и данные. Все должны быть 200."
foreach ($p in "/", "/about", "/users", "/info", "/hello", "/contacts", "/status") { Show-Api GET $p | Out-Null }
Next

Step 8 "Git: проверяем историю изменений" "Git запоминает версии проекта. Коммит = сохранённая версия. Первый коммит этой лабы называется «Initial FastAPI project»."
Set-Location $Root
Cmd "git log --oneline"
git log --oneline | Select-Object -Last 3
Cmd "git status"
git status | Select-Object -First 2
Next

Step 9 "Останавливаем сервер" "Выключаем сервер, чтобы освободить порт 8000 для следующей практики."
Stop-Server
Write-Host "Сервер остановлен." -ForegroundColor Green

Finish @("проект на FastAPI запускается", "семь адресов отвечают JSON с кодом 200", "работает Swagger (/docs)", "есть git-репозиторий и коммит") `
    "«Я сделала сервер на FastAPI: по адресу он отдаёт данные в JSON, Swagger проверяет адреса кнопками, версии сохранены в git»."
