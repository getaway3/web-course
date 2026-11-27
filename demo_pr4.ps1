. "$PSScriptRoot\demo_common.ps1"
Set-Win "ПР4: SQLAlchemy ORM"
$dir = Join-Path $Root "practice4"
Set-Location $dir

Title "ПР4. FASTAPI + SQLALCHEMY ORM: ПОКАЗ ПО ШАГАМ"
Say "Что мы делаем в четвёртой лабе, простыми словами:"
Write-Host "  В ПР3 мы САМИ писали SQL-запросы. Здесь SQL за нас пишет библиотека SQLAlchemy."
Write-Host "  Таблицу tasks мы описываем как обычный Python-класс Task, а адреса сервера работают с объектами:"
Write-Host "    session.add(task) - создать,  session.get(Task, 1) - прочитать,"
Write-Host "    task.completed = True - изменить,  session.delete(task) - удалить."
Write-Host "  А настоящий SQL при этом виден в журнале сервера (настройка echo=True)."
Write-Host "  Весь код пока лежит в ОДНОМ файле main.py - в ПР5 мы разложим его по папкам."
Next

Step 1 "Проверяем, что Docker запущен" "База снова работает в Docker."
Need-Docker
Cmd "docker version"
docker version --format "Docker engine: {{.Server.Version}}"
Next

Step 2 "Запускаем базу с таблицей tasks" "В этой практике по методичке таблица называется tasks (id, title, completed), в ней 5 задач."
Reset-Db $dir
Cmd "docker compose up -d"
Dc up -d
Wait-Db
Cmd 'docker compose exec db psql -U student -d practice -c "SELECT * FROM tasks ORDER BY id;"'
Psql "SELECT * FROM tasks ORDER BY id;"
Next

Step 3 "Смотрим код: всё в одном main.py" "Класс Task = таблица tasks (Mapped и mapped_column - современный способ описать столбцы). Engine - подключение к базе, Session - «рабочий сеанс» с объектами. Ниже - что именно находится в файле."
Cmd "Select-String main.py -Pattern '^class |^engine|^app =|^@app'"
Select-String -Path main.py -Pattern '^class |^engine|^app =|^@app|^def get_session' | ForEach-Object { Write-Host ("  " + $_.Line) -ForegroundColor White }
Next

Step 4 "Запускаем FastAPI-сервер" "Сервер включается в фоне. Все SQL-запросы, которые SQLAlchemy формирует, записываются в журнал - мы их покажем."
Cmd "python -m uvicorn main:app --reload"
if (-not (Start-Server $dir "main:app" -Log)) { exit 1 }
Write-Host "Сервер запущен." -ForegroundColor Green
Next

Step 5 "Открываем Swagger" "Откроется /docs. Там 5 адресов для задач: GET /tasks, POST /tasks, GET /tasks/{id}, PUT /tasks/{id}, DELETE /tasks/{id} - это CREATE, READ, UPDATE, DELETE."
Open-Url "$Base/docs"
Next

Step 6 "READ и CREATE" "GET /tasks - список задач. POST /tasks - создаёт новую задачу (код 201). Сервер сам присваивает номер."
Show-Api GET "/tasks" | Out-Null
$new = Show-Api POST "/tasks" '{"title":"Изучить SQLAlchemy","completed":false}'
$id = ($new.Body | ConvertFrom-Json).id
Write-Host "  (новая задача получила id = $id)" -ForegroundColor DarkGray
Show-Api GET "/tasks/$id" | Out-Null
Next

Step 7 "UPDATE и DELETE" "PUT меняет задачу (отметим выполненной). DELETE удаляет. После удаления запрос по этому номеру даст 404."
Show-Api PUT "/tasks/$id" '{"title":"Изучить SQLAlchemy","completed":true}' | Out-Null
Show-Api DELETE "/tasks/$id" | Out-Null
Show-Api GET "/tasks/$id" | Out-Null
Next

Step 8 "Смотрим SQL, который SQLAlchemy написала САМА" "Вот журнал сервера: INSERT, SELECT, UPDATE, DELETE - мы их не писали, мы только работали с объектами Task. Это и есть главная мысль лабы: SQL никуда не исчез, его просто формирует библиотека."
Cmd "(журнал сервера, echo=True)"
Show-SqlLog
Write-Host ""
Write-Host "Для отчёта возьми два примера SQL из этого вывода (например INSERT и SELECT)." -ForegroundColor DarkGray
Next

Step 9 "Проверяем таблицу после" "Задача создалась, изменилась и удалилась - в таблице снова 5 исходных задач."
Cmd 'docker compose exec db psql -U student -d practice -c "SELECT * FROM tasks ORDER BY id;"'
Psql "SELECT * FROM tasks ORDER BY id;"
Next

Step 10 "Автотесты" "4 проверки прогоняют все 5 адресов (на временной базе, без Docker)."
Cmd "python -m pytest -q"
& $py -m pytest -q 2>&1 | Select-Object -Last 3
Next

Step 11 "Выключаем сервер и базу" "Чистим за собой."
Stop-Server
Cmd "docker compose down -v"
Dc down -v

Finish @("подключение через SQLAlchemy (Engine, Session)", "модель Task (Mapped, mapped_column)", "FastAPI endpoints: CREATE, READ, UPDATE, DELETE", "SQL виден в журнале сервера (echo=True)", "весь код в одном main.py (в ПР5 будет разложен)") `
    "«Таблицу tasks описала классом Task; адреса FastAPI создают, читают, меняют и удаляют объекты через Session, SQL формирует SQLAlchemy, и он виден благодаря echo=True»."
