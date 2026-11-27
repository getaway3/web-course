. "$PSScriptRoot\demo_common.ps1"
Set-Win "ПР3: PostgreSQL и psycopg"
$dir = Join-Path $Root "practice3"
Set-Location $dir

Title "ПР3. FASTAPI + БАЗА ДАННЫХ В DOCKER (PSYCOPG): ПОКАЗ ПО ШАГАМ"
Say "Что мы делаем в третьей лабе, простыми словами:"
Write-Host "  Наш FastAPI-сервер раньше хранил питомцев в списке, и после перезапуска они пропадали."
Write-Host "  Теперь питомцы лежат в настоящей БАЗЕ ДАННЫХ PostgreSQL. База запускается в Docker"
Write-Host "  (это как «коробка» с готовой программой). Каждый адрес сервера (endpoint) выполняет"
Write-Host "  SQL-запрос к базе: показать все, найти по номеру, добавить, удалить."
Next

Step 1 "Проверяем, что Docker запущен" "Docker - программа, которая запускает базу. Если она не запущена, дальше ничего не заработает."
Need-Docker
Cmd "docker version"
docker version --format "Docker engine: {{.Server.Version}}"
Next

Step 2 "Смотрим файлы проекта" "docker-compose.yml - как запустить базу; create_tables.sql - как создать таблицу; insert_data.sql - какие записи в неё положить; main.py - наш FastAPI-сервер."
Cmd "dir"
Get-ChildItem | Format-Table Name, Length -AutoSize | Out-String | Write-Host
Cmd "Get-Content create_tables.sql"
Get-Content create_tables.sql -Encoding UTF8 | ForEach-Object { Write-Host ("  " + $_) }
Cmd "Get-Content insert_data.sql"
Get-Content insert_data.sql -Encoding UTF8 | ForEach-Object { Write-Host ("  " + $_) }
Say "В docker-compose.yml заданы: база practice, пользователь student, пароль student (как в методичке)."
Next

Step 3 "Запускаем базу" "Команда создаёт контейнер с PostgreSQL и сама выполняет оба .sql файла. Подождём, пока база проснётся (healthy)."
Reset-Db $dir
Cmd "docker compose up -d"
Dc up -d
Wait-Db
Cmd "docker compose ps"
Dc ps
Next

Step 4 "Смотрим таблицу pets ДО" "psql - это консоль самой базы. Видим 6 питомцев, которых добавил insert_data.sql."
Cmd 'docker compose exec db psql -U student -d practice -c "SELECT * FROM pets ORDER BY id;"'
Psql "SELECT * FROM pets ORDER BY id;"
Next

Step 5 "Главное правило лабы: безопасные запросы" "Данные в запрос подставляются через %s и отдельный кортеж, а НЕ склеиваются строкой. Так никто не сможет подсунуть вредный SQL (SQL-инъекция)."
Cmd "Select-String main.py -Pattern 'cur.execute'"
Select-String -Path main.py -Pattern 'cur\.execute|%s' | Where-Object { $_.Line -notmatch '^\s*"""|Все запросы' } | ForEach-Object { Write-Host ("  " + $_.Line.Trim()) -ForegroundColor White }
Next

Step 6 "Запускаем FastAPI-сервер" "Команда включает наш сервер. Он подключается к базе при каждом запросе. Адрес: http://127.0.0.1:8000"
Cmd "python -m uvicorn main:app --reload"
if (-not (Start-Server $dir "main:app")) { exit 1 }
Write-Host "Сервер запущен." -ForegroundColor Green
Next

Step 7 "Открываем Swagger" "Откроется /docs. Там видны адреса: /db-check, /pets, /pets/{id}. Каждый можно нажать кнопками Try it out -> Execute. Сейчас то же сделаем программой."
Open-Url "$Base/docs"
Next

Step 8 "Адреса, которые работают с базой" "1) /db-check - подключились ли к PostgreSQL. 2) GET /pets - все записи (SELECT). 3) GET /pets/3 - по номеру. 4) GET /pets/999 - такого нет, будет 404."
Show-Api GET "/db-check" | Out-Null
Show-Api GET "/pets" | Out-Null
Show-Api GET "/pets/3" | Out-Null
Show-Api GET "/pets/999" | Out-Null
Next

Step 9 "Добавляем и удаляем запись" "POST добавляет питомца (INSERT), код 201. DELETE удаляет (DELETE), код 200. Сервер сам даёт новый номер."
$new = Show-Api POST "/pets" '{"name":"Мурка","species":"Кошка","age":1}'
$id = ($new.Body | ConvertFrom-Json).id
Write-Host "  (новая запись получила id = $id)" -ForegroundColor DarkGray
Cmd 'docker compose exec db psql -U student -d practice -c "SELECT * FROM pets ORDER BY id;"   (запись уже в базе)'
Psql "SELECT * FROM pets ORDER BY id;"
Show-Api DELETE "/pets/$id" | Out-Null
Show-Api GET "/pets/$id" | Out-Null
Next

Step 10 "Смотрим таблицу ПОСЛЕ" "Добавленная запись удалена, значит таблица такая же, как в начале (6 питомцев). Данные хранятся в базе, а не в памяти программы."
Cmd 'docker compose exec db psql -U student -d practice -c "SELECT * FROM pets ORDER BY id;"'
Psql "SELECT * FROM pets ORDER BY id;"
Next

Step 11 "Выключаем сервер и базу" "down -v выключает контейнер и стирает данные, чтобы следующая практика начиналась с чистого листа."
Stop-Server
Cmd "docker compose down -v"
Dc down -v

Finish @("база PostgreSQL запустилась в Docker (healthy)", "таблица pets создана и заполнена (6 записей)", "FastAPI-сервер подключается через psycopg", "endpoints: все записи, по id, добавление (201), удаление", "запросы с %s (параметризованные)") `
    "«К FastAPI-серверу из прошлых лаб подключила PostgreSQL в Docker: каждый адрес делает SQL-запрос через psycopg, запросы параметризованные, поэтому защищены от SQL-инъекций»."
