# web-course: практические работы по разработке веб-приложений

Вариант 1: **Pet Clinic** (Pet, Veterinarian). Выполнила: Акобян Г.П., гр. ВМО42.

| Папка | Тема |
|-------|------|
| `practice01/` | первый backend на FastAPI |
| `practice02/` | REST API в памяти (Pydantic), анализ HTTP |
| `practice3/` | FastAPI + PostgreSQL в Docker + psycopg: endpoints выполняют параметризованные SQL-запросы |
| `practice4/` | FastAPI + SQLAlchemy 2.x ORM (CRUD-endpoints, `echo=True`), всё в одном `main.py` |
| `practice5/` | рефакторинг ПР4: `app/`, router, schemas, models, database |

В каждой папке есть свой `README.md` (отчёт), для ПР2–5 есть скриншоты в `docs/`.
Для ПР3–5 нужен Docker: `docker compose up -d` в папке практики (порт БД 54329, одновременно запускать только одну).

Быстрый показ всех практик по Enter: двойной щелчок по `POKAZ.bat` (подробности в `ШПАРГАЛКА_к_сдаче.md`).
