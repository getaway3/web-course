# Практическая работа №4. SQLAlchemy ORM

Выполнила: Акобян Г.П., гр. ВМО42. Продолжение ПР3: та же PostgreSQL в Docker (порт 54329), тот же FastAPI-проект,
но вместо ручного SQL (`cursor.execute`) используется **SQLAlchemy ORM**.

По методичке ПР4 работа ведётся с таблицей `tasks` (`id SERIAL`, `title VARCHAR(255)`, `completed BOOLEAN`); она создаётся
скриптами `create_tables.sql` и `insert_data.sql` этой папки. В ПР3 была таблица `pets` по варианту, в ПР4–5 – `tasks`, как требует методичка.

## Структура
```
practice4/
├── main.py              # ВСЁ в одном файле: FastAPI-приложение, подключение, модель Task, схемы, endpoints
├── crud_demo.py         # консольная демонстрация CRUD через ORM (дополнительно)
├── tests/test_tasks.py  # проверка API на SQLite в памяти (без PostgreSQL)
├── docker-compose.yml, create_tables.sql, insert_data.sql
├── requirements.txt
└── README.md
```
Именно такое состояние («всё в `main.py`») рефакторится в ПР5.

## Запуск
```bash
docker compose up -d
pip install -r requirements.txt
python -m uvicorn main:app --reload   # Swagger: http://127.0.0.1:8000/docs
```
SQL-запросы выводятся в консоль сервера (`echo=True`). Тесты: `pip install pytest httpx && pytest`.

## Endpoints и соответствие CRUD
| Операция | Endpoint | ORM-код | Ответ |
|---|---|---|---|
| CREATE | `POST /tasks` | `session.add(task); session.commit()` | 201 |
| READ (список) | `GET /tasks` | `session.scalars(select(Task)).all()` | 200 |
| READ (одна) | `GET /tasks/{id}` | `session.get(Task, id)` | 200 или 404 |
| UPDATE | `PUT /tasks/{id}` | `task.completed = ...; session.commit()` | 200 или 404 |
| DELETE | `DELETE /tasks/{id}` | `session.delete(task); session.commit()` | 200 или 404 |

Используется SQLAlchemy 2.x: `DeclarativeBase`, `Mapped`, `mapped_column`, `create_engine(..., echo=True)`, `Session`.
`cursor.execute(...)` для таблицы `tasks` не используется.

## Примеры SQL, сформированного SQLAlchemy (вывод `echo=True` в консоли сервера)
```
INSERT INTO tasks (title, completed) VALUES (%(title)s::VARCHAR, %(completed)s) RETURNING tasks.id
SELECT tasks.id, tasks.title, tasks.completed FROM tasks WHERE tasks.id = %(pk_1)s::INTEGER
UPDATE tasks SET completed=%(completed)s WHERE tasks.id = %(tasks_id)s::INTEGER
DELETE FROM tasks WHERE tasks.id = %(id)s::INTEGER
```
Схема работы: Python (`session.get`) → SQLAlchemy → SQL → PostgreSQL.

## Разница между `cursor.execute(...)` и `session.get(...)`
В первом случае разработчик сам пишет SQL. Во втором он работает с объектом модели `Task`,
а SQLAlchemy формирует SQL и отправляет его в PostgreSQL. SQL никуда не исчезает – его видно благодаря `echo=True`.
