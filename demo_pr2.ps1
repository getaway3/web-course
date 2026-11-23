. "$PSScriptRoot\demo_common.ps1"
Set-Win "ПР2: REST API"
Set-Location (Join-Path $Root "practice02")

Title "ПР2. REST API (ПИТОМЦЫ И ВЕТЕРИНАРЫ): ПОКАЗ ПО ШАГАМ"
Say "Что мы делаем во второй лабе, простыми словами:"
Write-Host "  Делаем сервер, который умеет работать с объектами (питомцы, ветеринары):"
Write-Host "    GET     - показать (список или один),"
Write-Host "    POST    - создать нового,"
Write-Host "    DELETE  - удалить."
Write-Host "  Данные хранятся прямо в программе (в списках Python), базы данных пока нет."
Write-Host "  Pydantic проверяет, что нам прислали правильные данные."
Next

Step 1 "Смотрим, какие адреса и модели есть в коде" "Классы с BaseModel - это Pydantic-модели (проверка данных). Строки @app... - адреса."
Cmd "Select-String main.py -Pattern '^class |^@app'"
Select-String -Path main.py -Pattern '^class |^@app' | ForEach-Object { Write-Host ("  " + $_.Line) }
Next

Step 2 "Запускаем сервер" "Сервер откроется в отдельном свёрнутом окне. Адрес: http://127.0.0.1:8000"
Cmd "python -m uvicorn main:app --reload"
if (-not (Start-Server (Get-Location).Path "main:app")) { exit 1 }
Write-Host "Сервер запущен." -ForegroundColor Green
Next

Step 3 "Открываем Swagger" "В браузере откроется /docs. Здесь можно нажимать кнопки Try it out -> Execute. Мы сейчас сделаем то же самое программой, а потом ты повторишь руками."
Open-Url "$Base/docs"
Next

Step 4 "GET: смотрим данные" "GET только читает. Должен быть код 200. Для питомца, которого нет (id 999), будет 404 = «не найдено»."
Show-Api GET "/pets" | Out-Null
Show-Api GET "/pets/1" | Out-Null
Show-Api GET "/pets/999" | Out-Null
Show-Api GET "/veterinarians" | Out-Null
Show-Api GET "/info" | Out-Null
Next

Step 5 "POST: создаём нового питомца" "POST создаёт. Правильный ответ - 201 Created (создано). Сервер сам присваивает id."
$new = Show-Api POST "/pets" '{"name":"Мурка","species":"Кошка","age":1}'
$id = ($new.Body | ConvertFrom-Json).id
Write-Host "  (новый питомец получил id = $id)" -ForegroundColor DarkGray
Next

Step 6 "POST с ошибкой: проверка Pydantic" "Пришлём неправильные данные (возраст -1). Pydantic не пропустит: код 422 = «данные неверные». Это и есть проверка входных данных."
Show-Api POST "/pets" '{"name":"Ошибка","species":"Кошка","age":-1}' | Out-Null
Next

Step 7 "DELETE: удаляем питомца" "DELETE удаляет. Ответ 200 и сообщение. Если запросить удалённого ещё раз - будет 404."
Show-Api DELETE "/pets/$id" | Out-Null
Show-Api GET "/pets/$id" | Out-Null
Next

Step 8 "Автотесты" "6 маленьких проверок, которые сами нажимают на все кнопки и сверяют коды ответов."
Cmd "python -m pytest -q"
& $py -m pytest -q 2>&1 | Select-Object -Last 3
Next

Step 9 "F12 -> Network: смотрим запрос глазами браузера" "СДЕЛАЙ САМА (так просит методичка): открой /docs, нажми F12, вкладка Network. Потом в Swagger выполни GET /pets/{id} (введи 1) и POST /pets. В Network щёлкни по запросу и покажи: Method, Request URL, Status Code, Request Headers, Response Headers, Response Body. Для чистоты: Ctrl+Shift+M выключает режим телефона."
Open-Url "$Base/docs"
Write-Host ""
Write-Host "Request Headers - то, что отправил браузер. Response Headers - то, что ответил сервер." -ForegroundColor White
Next

Step 10 "Останавливаем сервер" "Освобождаем порт 8000."
Stop-Server
Write-Host "Сервер остановлен." -ForegroundColor Green

Finish @("GET список и GET по id (с ошибкой 404)", "POST создаёт и возвращает 201", "DELETE удаляет", "Pydantic проверяет данные (422)", "показан F12 -> Network") `
    "«REST API для питомцев и ветеринаров: GET читает, POST создаёт (201), DELETE удаляет, Pydantic проверяет данные, запросы разобрала в DevTools»."
