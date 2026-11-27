"""Практическая работа №3: PostgreSQL в Docker и работа с БД из Python (psycopg 3).

FastAPI-проект из ПР1–ПР2 продолжается: данные питомцев теперь хранятся не в списке Python,
а в таблице pets базы PostgreSQL (вариант 1: Pet Clinic). Каждый endpoint выполняет SQL-запрос.

Все запросы, принимающие данные пользователя, - параметризованные (%s + кортеж значений),
конкатенация строк для SQL не используется.

Запуск:  python -m uvicorn main:app --reload      Swagger: http://127.0.0.1:8000/docs
"""
import os
from contextlib import contextmanager

import psycopg
from fastapi import FastAPI, HTTPException
from psycopg.rows import dict_row
from pydantic import BaseModel, Field

DSN = os.environ.get(
    "DATABASE_DSN",
    "host=localhost port=54329 dbname=practice user=student password=student",
)

app = FastAPI(title="Pet Clinic API (ПР3: PostgreSQL + psycopg)")


class PetCreate(BaseModel):
    name: str = Field(min_length=1, examples=["Мурка"])
    species: str = Field(min_length=1, examples=["Кошка"])
    age: int = Field(ge=0, le=60, examples=[1])


# ---------- подключение к БД ----------
@contextmanager
def get_conn():
    """Открывает соединение с PostgreSQL и гарантированно закрывает его."""
    conn = psycopg.connect(DSN, row_factory=dict_row)
    try:
        yield conn
    finally:
        conn.close()


# ---------- SQL-операции (все с параметрами %s) ----------
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
            "INSERT INTO pets (name, species, age) VALUES (%s, %s, %s) RETURNING id, name, species, age",
            (name, species, age),
        )
        pet = cur.fetchone()
    conn.commit()
    return pet


def delete_pet(conn, pet_id):
    with conn.cursor() as cur:
        cur.execute("DELETE FROM pets WHERE id = %s", (pet_id,))
        deleted = cur.rowcount
    conn.commit()
    return deleted


# ---------- endpoints ----------
@app.get("/db-check")
def db_check():
    """Проверка подключения к PostgreSQL."""
    try:
        with get_conn() as conn:
            version = conn.execute("SELECT version() AS v").fetchone()["v"]
    except psycopg.OperationalError as exc:
        raise HTTPException(status_code=503, detail=f"База данных недоступна: {exc}")
    return {"connected": True, "database": "practice", "version": version}


@app.get("/pets")
def list_pets():
    """SELECT всех записей."""
    with get_conn() as conn:
        return get_all_pets(conn)


@app.get("/pets/{pet_id}")
def get_pet(pet_id: int):
    """SELECT записи по id."""
    with get_conn() as conn:
        pet = get_pet_by_id(conn, pet_id)
    if pet is None:
        raise HTTPException(status_code=404, detail=f"Pet with id={pet_id} not found")
    return pet


@app.post("/pets", status_code=201)
def create_pet(data: PetCreate):
    """INSERT новой записи."""
    with get_conn() as conn:
        return add_pet(conn, data.name, data.species, data.age)


@app.delete("/pets/{pet_id}")
def remove_pet(pet_id: int):
    """DELETE записи по id."""
    with get_conn() as conn:
        deleted = delete_pet(conn, pet_id)
    if deleted == 0:
        raise HTTPException(status_code=404, detail=f"Pet with id={pet_id} not found")
    return {"message": f"Pet {pet_id} deleted"}
