# Практическая работа №3. Docker, PostgreSQL и Python (psycopg)

Вариант 1: Pet Clinic. Таблица `pets` (id, name, species, age).

## Структура
```
practice3/
├── docker-compose.yml   # PostgreSQL 16, БД practice, пользователь/пароль student/student, порт 54329
├── create_tables.sql    # создание таблицы pets
├── insert_data.sql      # 6 тестовых записей
├── main.py              # подключение через psycopg, SELECT / SELECT по id / INSERT / DELETE
├── requirements.txt
└── README.md
```

## Запуск
```bash
docker compose up -d
docker compose ps                  # контейнер practice_db должен быть healthy
pip install -r requirements.txt
python main.py
```
SQL-скрипты выполняются автоматически при первом старте контейнера (каталог
`/docker-entrypoint-initdb.d`). Чтобы пересоздать данные с нуля: `docker compose down -v`, затем `docker compose up -d`.

Проверить содержимое таблицы вручную:
```bash
docker compose exec db psql -U student -d practice -c "SELECT * FROM pets ORDER BY id;"
```

## Что делает main.py
1. подключается к PostgreSQL (`psycopg.connect`);
2. выводит все записи;
3. получает запись по `id`;
4. добавляет новую запись (`INSERT ... RETURNING id`);
5. удаляет запись по `id`;
6. закрывает соединение (`finally`).

Все запросы с пользовательскими данными – параметризованные: `cur.execute("... WHERE id = %s", (pet_id,))`.
Строки SQL не собираются конкатенацией.

## Демонстрация преподавателю
1. `docker compose up -d` и `docker compose ps`;
2. `python main.py` – видны подключение, все записи, запись с id = 3, добавление, удаление;
3. `docker compose exec db psql ...` – таблица после работы программы (добавленная запись удалена, исходные 6 записей на месте).
