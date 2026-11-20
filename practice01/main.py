"""Практическая работа №1. Первый backend на FastAPI.

Тема варианта 1: Pet Clinic (сущности Pet и Veterinarian).
Запуск:  python -m uvicorn main:app --reload
Swagger: http://127.0.0.1:8000/docs
"""
from fastapi import FastAPI

app = FastAPI(title="Pet Clinic API (ПР1)")


@app.get("/")
async def root():
    return {"message": "Hello Web"}


@app.get("/about")
async def about():
    return {"course": "Web Development"}


@app.get("/users")
async def users():
    return {"users": ["Alex", "Maria", "Ivan"]}


# Индивидуальное задание: информация по теме варианта (variants_group_2.md, вариант 1)
@app.get("/info")
async def info():
    return {
        "theme": "Pet Clinic",
        "entities": ["Pet", "Veterinarian"],
        "description": "Ветеринарная клиника: питомцы и ветеринары",
    }


# Домашнее задание
@app.get("/hello")
async def hello():
    return {"message": "Hello from Pet Clinic"}


@app.get("/contacts")
async def contacts():
    return {
        "clinic": "Pet Clinic",
        "phone": "+7 (863) 000-00-00",
        "email": "info@petclinic.example",
        "address": "Ростов-на-Дону, пл. Гагарина, 1",
    }


@app.get("/status")
async def status():
    return {"status": "ok", "service": "pet-clinic-api"}
