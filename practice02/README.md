# Практическая работа №2. HTTP-запросы и REST API в FastAPI

Вариант 1: **Pet Clinic**. Выполнила: Акобян Г.П., гр. ВМО42.
Данные хранятся в памяти (списки Python), БД не используется. Модели Pydantic: `PetCreate`, `Pet`, `VeterinarianCreate`, `Veterinarian`.

## Запуск

```bash
python -m pip install -r requirements.txt
python -m uvicorn main:app --reload
```

Swagger UI: http://127.0.0.1:8000/docs. Скриншоты: `docs/swagger-endpoints.png` (все endpoints в Swagger UI),
`docs/swagger-schemas-pydantic.png` (модели Pydantic `Pet`, `PetCreate`, `Veterinarian`, `VeterinarianCreate` в разделе Schemas).
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

GET-запрос снят в **F12 → Network** браузера (скриншоты `docs/devtools-get-headers.png` и
`docs/devtools-get-response.png`); значения POST (201) сняты с реального сервера запросом curl.
Запросы выполнялись из Swagger UI (кнопка Try it out → Execute).

### GET `/pets/1`

| | |
|---|---|
| HTTP Method | GET |
| Request URL | http://127.0.0.1:8000/pets/1 |
| Status Code | 200 OK |
| Request Headers | `Accept: */*`, `Accept-Encoding: gzip, deflate, br, zstd`, `Accept-Language: ru,en;q=0.9`, `Connection: keep-alive`, `Host: 127.0.0.1:8000`, `Referer: http://127.0.0.1:8000/docs`, `Sec-Fetch-Mode: cors`, `User-Agent: …` (браузера) |
| Response Headers | `Content-Type: application/json`, `Content-Length: 81`, `Server: uvicorn`, `Date: Fri, 20 Nov 2026 23:46:20 GMT` |
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

Ошибка, пойманная в DevTools: POST `/pets` с `"veterinarian_id": 0` → **404 Not Found**, тело
`{"detail":"Veterinarian with id=0 not found"}` (такого ветеринара нет, API проверяет связь). Скриншоты:
`docs/devtools-post-error404-general.png`, `docs/devtools-post-error404-request-headers.png`.
Пример тела запроса в Swagger теперь подставляется без `veterinarian_id`, поэтому POST по умолчанию возвращает 201.

## Контрольные вопросы (кратко)

1. **REST API** — стиль построения веб-интерфейса: ресурсы адресуются URL, действия задаются HTTP-методами, обмен обычно в JSON.
2. **Endpoint** — конкретный адрес и метод, например `GET /pets/{id}`.
3. **GET** читает, **POST** создаёт, **DELETE** удаляет ресурс.
4. **JSON** — текстовый формат данных: объекты `{}`, массивы `[]`, строки, числа, true/false/null.
5. **Status Code** сообщает результат: 2xx — успех, 4xx — ошибка клиента (404, 422), 5xx — ошибка сервера.
6. **Request** — то, что клиент отправляет (метод, URL, заголовки, тело); **Response** — ответ сервера (код, заголовки, тело).
7. F12 → вкладка **Network** → выбрать запрос → Headers.
8. **Request Headers** отправляет клиент (кто он, что принимает, формат тела), **Response Headers** — сервер (тип и размер ответа, дата, сервер).
