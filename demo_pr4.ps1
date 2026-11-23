. "$PSScriptRoot\demo_common.ps1"
Set-Win "ПР4: SQLAlchemy ORM"
$dir = Join-Path $Root "practice4"
Set-Location $dir

Title "ПР4. SQLALCHEMY ORM: ПОКАЗ ПО ШАГАМ"
Say "Что мы делаем в четвёртой лабе, простыми словами:"
Write-Host "  В ПР3 мы САМИ писали SQL-запросы. Здесь SQL за нас пишет библиотека SQLAlchemy."
Write-Host "  Таблицу tasks мы описываем как обычный Python-класс Task, а действия делаем над объектами:"
Write-Host "    session.add(task)  - создать,  session.get(Task, 1) - прочитать,"
Write-Host "    task.completed = True - изменить,  session.delete(task) - удалить."
Write-Host "  А настоящий SQL при этом виден в консоли (настройка echo=True)."
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

Step 3 "Смотрим, как таблица описана классом" "Класс Task = таблица tasks. Mapped и mapped_column - современный способ описать столбцы. Engine - подключение к базе, Session - «рабочий сеанс» с объектами."
Cmd "Select-String main.py -Pattern 'class Task' -Context 0,5"
Select-String -Path main.py -Pattern 'class Task' -Context 0,5 | ForEach-Object {
    $_.Line | ForEach-Object { Write-Host ("  " + $_) -ForegroundColor White }
    $_.Context.PostContext | ForEach-Object { Write-Host ("  " + $_) -ForegroundColor White }
}
Cmd "Select-String main.py -Pattern 'create_engine|Session\('"
Select-String -Path main.py -Pattern 'create_engine\(|with Session' | ForEach-Object { Write-Host ("  " + $_.Line.Trim()) -ForegroundColor White }
Next

Step 4 "Запускаем программу и смотрим SQL" "Программа делает 4 действия: CREATE, READ, UPDATE, DELETE. Между ними бежат строки INFO sqlalchemy - это настоящий SQL, который SQLAlchemy сформировала сама: INSERT, SELECT, UPDATE, DELETE."
Cmd "python main.py"
& $py main.py 2>&1 | Where-Object { $_ -notmatch 'pg_catalog|current_schema|standard_conforming|\[raw sql\]|\[cached|\[generated' }
Next

Step 5 "Главная мысль лабы" "cursor.execute(...) - SQL пишу я. session.get(Task, 1) - SQL формирует SQLAlchemy. Но SQL никуда не исчез, его видно в консоли (echo=True)."
Write-Host ""
Write-Host "Для отчёта возьми два примера SQL из вывода выше, например:" -ForegroundColor DarkGray
Write-Host "  INSERT INTO tasks (title, completed) VALUES (...) RETURNING tasks.id" -ForegroundColor White
Write-Host "  SELECT tasks.id, tasks.title, tasks.completed FROM tasks WHERE tasks.id = ..." -ForegroundColor White
Next

Step 6 "Проверяем таблицу после программы" "Задача создалась, изменилась и удалилась - в таблице снова 5 исходных задач."
Cmd 'docker compose exec db psql -U student -d practice -c "SELECT * FROM tasks ORDER BY id;"'
Psql "SELECT * FROM tasks ORDER BY id;"
Next

Step 7 "Выключаем базу" "Чистим за собой."
Cmd "docker compose down -v"
Dc down -v

Finish @("подключение через SQLAlchemy (Engine)", "модель Task (Mapped, mapped_column)", "работа через Session", "CREATE, READ, UPDATE, DELETE выполнены", "SQL виден в консоли (echo=True)") `
    "«Таблицу tasks описала классом Task; создаю, читаю, меняю и удаляю объекты через Session, SQL формирует SQLAlchemy, и он виден благодаря echo=True»."
