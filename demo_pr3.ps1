. "$PSScriptRoot\demo_common.ps1"
Set-Win "ПР3: PostgreSQL и psycopg"
$dir = Join-Path $Root "practice3"
Set-Location $dir

Title "ПР3. БАЗА ДАННЫХ В DOCKER И SQL ИЗ PYTHON: ПОКАЗ ПО ШАГАМ"
Say "Что мы делаем в третьей лабе, простыми словами:"
Write-Host "  Раньше данные жили в списке и пропадали. Теперь кладём их в настоящую БАЗУ ДАННЫХ"
Write-Host "  PostgreSQL. База запускается в Docker (это как «коробка» с готовой программой)."
Write-Host "  Python-программа подключается к базе и выполняет SQL-запросы:"
Write-Host "  показать все записи, найти по номеру, добавить, удалить."
Next

Step 1 "Проверяем, что Docker запущен" "Docker - программа, которая запускает базу. Если она не запущена, дальше ничего не заработает."
Need-Docker
Cmd "docker version"
docker version --format "Docker engine: {{.Server.Version}}"
Next

Step 2 "Смотрим файлы проекта" "docker-compose.yml - как запустить базу; create_tables.sql - как создать таблицу; insert_data.sql - какие записи в неё положить."
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

Step 4 "Смотрим таблицу pets ДО программы" "psql - это консоль самой базы. Видим 6 питомцев, которых добавил insert_data.sql."
Cmd 'docker compose exec db psql -U student -d practice -c "SELECT * FROM pets ORDER BY id;"'
Psql "SELECT * FROM pets ORDER BY id;"
Next

Step 5 "Главное правило лабы: безопасные запросы" "Данные в запрос подставляются через %s и отдельный кортеж, а НЕ склеиваются строкой. Так никто не сможет подсунуть вредный SQL (SQL-инъекция)."
Cmd "Select-String main.py -Pattern '%s'"
Select-String -Path main.py -Pattern '%s' | ForEach-Object { Write-Host ("  " + $_.Line.Trim()) -ForegroundColor White }
Next

Step 6 "Запускаем программу main.py" "Она подключается к базе и по очереди делает: 1) показать все записи, 2) найти запись с id=3, 3) добавить новую, 4) удалить её. Смотри на вывод."
Cmd "python main.py"
& $py main.py
Next

Step 7 "Смотрим таблицу ПОСЛЕ программы" "Добавленная запись была удалена, значит таблица такая же, как в начале (6 питомцев)."
Cmd 'docker compose exec db psql -U student -d practice -c "SELECT * FROM pets ORDER BY id;"'
Psql "SELECT * FROM pets ORDER BY id;"
Next

Step 8 "Выключаем базу" "down -v выключает контейнер и стирает данные, чтобы следующая практика начиналась с чистого листа."
Cmd "docker compose down -v"
Dc down -v

Finish @("база PostgreSQL запустилась в Docker (healthy)", "таблица pets создана и заполнена (6 записей)", "программа подключается через psycopg", "работают: все записи, по id, добавление, удаление", "запросы с %s (параметризованные)") `
    "«Поднимаю PostgreSQL в Docker, из Python через psycopg читаю, ищу по id, добавляю и удаляю записи; запросы параметризованные, поэтому защищены от SQL-инъекций»."
