# Практическая работа №3. Docker, PostgreSQL и работа с БД из Python (psycopg)

Вариант 1: **Pet Clinic**, таблица `pets` (id, name, species, age). Выполнила: Акобян Г.П., гр. ВМО42.

Проект из ПР1–ПР2 (FastAPI) продолжается: питомцы теперь хранятся не в списке Python, а в **PostgreSQL**, который запущен в Docker.
Каждый endpoint выполняет SQL-запрос через `psycopg`.

## Структура
```
practice3/
├── docker-compose.yml   # PostgreSQL 16 в Docker: БД practice, пользователь/пароль student/student, порт 54329
├── create_tables.sql    # создание таблицы pets
├── insert_data.sql      # 6 тестовых записей
├── main.py              # FastAPI-приложение: endpoints + SQL через psycopg
├── console_demo.py      # те же SQL-операции в консоли, без веб-сервера (дополнительно)
├── requirements.txt
└── README.md
```

## Запуск
```bash
docker compose up -d
docker compose ps                     # контейнер practice_db должен быть healthy
pip install -r requirements.txt
python -m uvicorn main:app --reload   # Swagger: http://127.0.0.1:8000/docs
```
SQL-скрипты выполняются автоматически при первом старте контейнера (каталог `/docker-entrypoint-initdb.d`).
Пересоздать данные с нуля: `docker compose down -v`, затем `docker compose up -d`.
Содержимое таблицы вручную:
```bash
docker compose exec db psql -U student -d practice -c "SELECT * FROM pets ORDER BY id;"
```

## Endpoints (каждый = SQL-запрос)
| Метод | Адрес | SQL | Ответ |
|---|---|---|---|
| GET | `/db-check` | `SELECT version()` | 200, подключение выполнено |
| GET | `/pets` | `SELECT ... FROM pets ORDER BY id` | 200, список |
| GET | `/pets/{id}` | `SELECT ... WHERE id = %s` | 200 или 404 |
| POST | `/pets` | `INSERT ... VALUES (%s, %s, %s) RETURNING ...` | 201, созданная запись |
| DELETE | `/pets/{id}` | `DELETE ... WHERE id = %s` | 200 или 404 |

Пример тела POST: `{"name": "Мурка", "species": "Кошка", "age": 1}`.

## Обязательное требование: параметризованные запросы
Все запросы с данными пользователя используют `%s` и отдельный кортеж значений:
```python
cur.execute("SELECT id, name, species, age FROM pets WHERE id = %s", (pet_id,))
```
Склейки строк в SQL нет. Это защищает от SQL-инъекций. Соединение закрывается в `finally` после каждого запроса.

## Демонстрация преподавателю
1. `docker compose up -d` и `docker compose ps` (healthy);
2. `uvicorn main:app`, в Swagger: `GET /db-check` (подключение), `GET /pets` (все записи), `GET /pets/3` (по id);
3. `POST /pets` (добавление, 201), `DELETE /pets/{id}` (удаление);
4. `docker compose exec db psql ...` до и после: содержимое таблицы изменилось и вернулось к исходному.
Консольная версия: `python console_demo.py` (те же четыре операции с выводом в консоль).
