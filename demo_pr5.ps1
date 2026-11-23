. "$PSScriptRoot\demo_common.ps1"
Set-Win "ПР5: рефакторинг"
$dir = Join-Path $Root "practice5"
Set-Location $dir

Title "ПР5. РЕФАКТОРИНГ FASTAPI: ПОКАЗ ПО ШАГАМ"
Say "Что мы делаем в пятой лабе, простыми словами:"
Write-Host "  Раньше весь код лежал в одном файле. Теперь РАЗЛОЖИМ его по папкам и файлам,"
Write-Host "  чтобы каждый файл отвечал за одно дело. Программа работает так же, как раньше:"
Write-Host "  меняется только порядок в коде, а не то, что видит пользователь."
Next

Step 1 "Смотрим новую структуру проекта" "Это главное в лабе: каждый файл - своя ответственность."
Cmd "tree app /F"
Get-ChildItem -Path app -Recurse -File | Where-Object { $_.FullName -notmatch '__pycache__' } |
    ForEach-Object { Write-Host ("  " + $_.FullName.Substring($dir.Length + 1)) }
Write-Host ""
Write-Host "  main.py          - создаёт приложение и подключает router" -ForegroundColor White
Write-Host "  database.py      - подключение к базе и Session" -ForegroundColor White
Write-Host "  models.py        - описание таблиц (SQLAlchemy)" -ForegroundColor White
Write-Host "  schemas.py       - проверка входных данных (Pydantic)" -ForegroundColor White
Write-Host "  routers/tasks.py - адреса /tasks/ (GET и POST)" -ForegroundColor White
Next

Step 2 "Как это склеивается: main.py" "В main.py всего пара строк: создали приложение и подключили router через include_router. Без этой строки адресов /tasks/ в приложении не было бы."
Cmd "Get-Content app\main.py"
Get-Content app\main.py -Encoding UTF8 | ForEach-Object { Write-Host ("  " + $_) }
Next

Step 3 "Проверяем, что Docker запущен и запускаем базу" "База та же, что в ПР4 (таблица tasks)."
Need-Docker
Reset-Db $dir
Cmd "docker compose up -d"
Dc up -d
Wait-Db
Next

Step 4 "Запускаем приложение" "Команда другая, чем раньше: теперь main.py лежит внутри папки app, поэтому app.main:app."
Cmd "python -m uvicorn app.main:app --reload"
if (-not (Start-Server $dir "app.main:app")) { exit 1 }
Write-Host "Приложение запущено." -ForegroundColor Green
Next

Step 5 "Открываем Swagger" "Должны быть два адреса: POST /tasks/ и GET /tasks/."
Open-Url "$Base/docs"
Next

Step 6 "Проверка POST и GET (то же, что ты нажмёшь в Swagger)" "POST создаёт задачу и возвращает её. GET /tasks/ показывает список, в котором новая задача уже есть."
Show-Api POST "/tasks/" '{"title":"Изучить архитектуру FastAPI","completed":false}' | Out-Null
Show-Api GET "/tasks/" | Out-Null
Next

Step 7 "Автотесты" "5 проверок подтверждают, что после рефакторинга API работает так же."
Cmd "python -m pytest -q"
& $py -m pytest -q 2>&1 | Select-Object -Last 3
Next

Step 8 "Останавливаем всё" "Выключаем сервер и базу."
Stop-Server
Cmd "docker compose down -v"
Dc down -v
Write-Host "Готово." -ForegroundColor Green

Finish @("структура app/: main, database, models, schemas, routers/tasks", "router подключён через include_router", "работают POST /tasks/ и GET /tasks/", "API не изменился после рефакторинга") `
    "«Разложила приложение по файлам: подключение к БД, модели, схемы и адреса отдельно, main.py только собирает; API работает так же, как до рефакторинга»."
