# Практическая работа №2. HTTP-запросы и REST API в FastAPI

Вариант 1: **Pet Clinic**. Выполнила: Акобян Г.П., гр. ВМО42.
Данные хранятся в памяти (списки Python), БД не используется. Модели Pydantic: `PetCreate`, `Pet`, `VeterinarianCreate`, `Veterinarian`.

## Запуск

```bash
python -m pip install -r requirements.txt
python -m uvicorn main:app --reload
```

Swagger UI: http://127.0.0.1:8000/docs (скриншот: `docs/swagger-ui.jpg`).
Тесты: `pip install pytest httpx && pytest` (6 тестов).

## Endpoints

| Метод | URL | Успех | Ошибки |
|-------|-----|-------|--------|
| GET | `/pets` | 200, список | |
| GET | `/pets/{id}` | 200, объект | 404, если нет |
| POST | `/pets` | **201**, созданный объект | 422 (неверные данные), 404 (нет такого ветеринара) |
| DELETE | `/pets/{id}` | 200, `{"message": "Pet N deleted"}` | 404 |
| GET/POST/DELETE | `/veterinarians`, `/veterinarians/{id}` | то же | DELETE: 409, если у ветеринара есть питомцы |
| GET | `/info` | 200, информация о проекте | |

Пример тела POST `/pets`: `{"name": "Мурка", "species": "Кошка", "age": 1}`.

## Анализ HTTP (DevTools → Network)

Значения ниже сняты с реального сервера (`uvicorn`, запросы curl и `fetch` из браузера).
Для отчёта повтори запросы в Swagger UI с открытой вкладкой **F12 → Network** и сделай скриншот.

### GET `/pets/1`

| | |
|---|---|
| HTTP Method | GET |
| Request URL | http://127.0.0.1:8000/pets/1 |
| Status Code | 200 OK |
| Request Headers | `Host: 127.0.0.1:8000`, `User-Agent: curl/8.7.1` (в браузере: свой User-Agent), `Accept: */*` |
| Response Headers | `content-type: application/json`, `content-length: 81`, `server: uvicorn`, `date: …` |
| Response Body | `{"name":"Барсик","species":"Кошка","age":3,"veterinarian_id":1,"id":1}` |

### POST `/pets`

| | |
|---|---|
| HTTP Method | POST |
| Request URL | http://127.0.0.1:8000/pets |
| Status Code | **201 Created** |
| Request Headers | `Host: 127.0.0.1:8000`, `Content-Type: application/json`, `Accept: application/json`, `Content-Length: 40` |
| Request Body | `{"name":"Murka","species":"Cat","age":1}` |
| Response Headers | `content-type: application/json`, `content-length: 70`, `server: uvicorn`, `date: …` |
| Response Body | `{"name":"Murka","species":"Cat","age":1,"veterinarian_id":null,"id":4}` |

Ошибка для сравнения: GET `/pets/999` → **404 Not Found**, тело `{"detail":"Pet with id=999 not found"}`.

## Контрольные вопросы (кратко)

1. **REST API** — стиль построения веб-интерфейса: ресурсы адресуются URL, действия задаются HTTP-методами, обмен обычно в JSON.
2. **Endpoint** — конкретный адрес и метод, например `GET /pets/{id}`.
3. **GET** читает, **POST** создаёт, **DELETE** удаляет ресурс.
4. **JSON** — текстовый формат данных: объекты `{}`, массивы `[]`, строки, числа, true/false/null.
5. **Status Code** сообщает результат: 2xx — успех, 4xx — ошибка клиента (404, 422), 5xx — ошибка сервера.
6. **Request** — то, что клиент отправляет (метод, URL, заголовки, тело); **Response** — ответ сервера (код, заголовки, тело).
7. F12 → вкладка **Network** → выбрать запрос → Headers.
8. **Request Headers** отправляет клиент (кто он, что принимает, формат тела), **Response Headers** — сервер (тип и размер ответа, дата, сервер).
