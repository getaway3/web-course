"""Практическая работа №3 (консольная версия): PostgreSQL в Docker и работа с БД из Python (psycopg 3).
Основной проект - FastAPI-приложение в main.py; этот скрипт показывает те же SQL-операции без веб-сервера.

Предметная область варианта 1: Pet Clinic, таблица pets (id, name, species, age).
Все запросы, принимающие данные пользователя, - параметризованные (%s + кортеж значений),
конкатенация строк для SQL не используется.
"""
import os
import sys

import psycopg

if hasattr(sys.stdout, "reconfigure"):          # кириллица в консоли Windows
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

DSN = os.environ.get(
    "DATABASE_DSN",
    "host=localhost port=54329 dbname=practice user=student password=student",
)


def get_all_pets(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT id, name, species, age FROM pets ORDER BY id")
        return cur.fetchall()


def get_pet_by_id(conn, pet_id):
    with conn.cursor() as cur:
        cur.execute("SELECT id, name, species, age FROM pets WHERE id = %s", (pet_id,))
        return cur.fetchone()


def add_pet(conn, name, species, age):
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO pets (name, species, age) VALUES (%s, %s, %s) RETURNING id",
            (name, species, age),
        )
        new_id = cur.fetchone()[0]
    conn.commit()
    return new_id


def delete_pet(conn, pet_id):
    with conn.cursor() as cur:
        cur.execute("DELETE FROM pets WHERE id = %s", (pet_id,))
        deleted = cur.rowcount
    conn.commit()
    return deleted


def show(title, rows):
    print(f"\n--- {title} ---")
    for row in rows:
        print(row)


def main():
    conn = psycopg.connect(DSN)
    try:
        print("Подключение к PostgreSQL выполнено")

        show("1. Все записи", get_all_pets(conn))

        pet = get_pet_by_id(conn, 3)
        print("\n--- 2. Запись с id = 3 ---")
        print(pet if pet else "не найдена")

        new_id = add_pet(conn, "Мурка", "Кошка", 1)
        print(f"\n--- 3. Добавлена запись, id = {new_id} ---")
        show("Таблица после добавления", get_all_pets(conn))

        deleted = delete_pet(conn, new_id)
        print(f"\n--- 4. Удалено записей: {deleted} (id = {new_id}) ---")
        show("Таблица после удаления", get_all_pets(conn))
    finally:
        conn.close()   # соединение закрывается всегда
        print("\nСоединение закрыто")


if __name__ == "__main__":
    main()
