# Практическая работа №4. SQLAlchemy ORM

Продолжение практики №3: та же PostgreSQL в Docker (порт 54329). По методичке ПР4 работа ведётся с таблицей `tasks`
(`id SERIAL`, `title VARCHAR(255)`, `completed BOOLEAN`); она создаётся скриптами `create_tables.sql` и `insert_data.sql` этой папки.
В ПР3 использовалась таблица `pets` по варианту (Pet Clinic), в ПР4–5 – `tasks`, как требует методичка.

## Запуск
```bash
docker compose up -d
pip install -r requirements.txt
python main.py
```

## Что реализовано (`main.py`)
| Требование | Где |
|---|---|
| `create_engine(..., echo=True)` | `engine` |
| модель на `DeclarativeBase`, `Mapped`, `mapped_column` | класс `Task` |
| работа через `Session`, без `cursor.execute` | `with Session(engine) as session` |
| CREATE | `session.add(task); session.commit()` |
| READ | `session.get(Task, id)` и `session.scalars(select(Task)).all()` |
| UPDATE | `task.completed = True; session.commit()` |
| DELETE | `session.delete(task); session.commit()` |

Демонстрация создаёт новую задачу, читает, изменяет и удаляет именно её – исходные 5 записей остаются нетронутыми.

## Примеры SQL, сформированного SQLAlchemy (вывод `echo=True`)
Вставьте в отчёт фрагменты из консоли после запуска (не менее двух). Вид запросов:
```
INSERT INTO tasks (title, completed) VALUES (%(title)s, %(completed)s) RETURNING tasks.id
SELECT tasks.id, tasks.title, tasks.completed FROM tasks WHERE tasks.id = %(pk_1)s
UPDATE tasks SET completed=%(completed)s WHERE tasks.id = %(tasks_id)s
DELETE FROM tasks WHERE tasks.id = %(id)s
```
(точные имена параметров зависят от версии SQLAlchemy).

## Разница между `cursor.execute(...)` и `session.get(...)`
В первом случае разработчик сам пишет SQL. Во втором он работает с объектом модели `Task`,
а SQLAlchemy формирует SQL и отправляет его в PostgreSQL. SQL никуда не исчезает – его видно благодаря `echo=True`.
