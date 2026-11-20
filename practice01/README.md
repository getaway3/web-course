# Практическая работа №1. Первый FastAPI backend

Вариант 1: **Pet Clinic** (сущности Pet, Veterinarian). Выполнила: Акобян Г.П., гр. ВМО42.

## Запуск

```bash
python -m pip install -r requirements.txt
python -m uvicorn main:app --reload
```

- http://127.0.0.1:8000 → `{"message": "Hello Web"}`
- http://127.0.0.1:8000/docs — Swagger UI

## Endpoints

| Метод | URL | Ответ |
|-------|-----|-------|
| GET | `/` | `{"message": "Hello Web"}` |
| GET | `/about` | `{"course": "Web Development"}` |
| GET | `/users` | `{"users": ["Alex", "Maria", "Ivan"]}` |
| GET | `/info` | индивидуальное задание: `{"theme": "Pet Clinic", "entities": ["Pet", "Veterinarian"], ...}` |
| GET | `/hello` | домашнее задание |
| GET | `/contacts` | домашнее задание |
| GET | `/status` | домашнее задание: `{"status": "ok", ...}` |

## Git

```bash
git init
git status
git add .
git commit -m "Initial FastAPI project"
```

## Результат

Работающий FastAPI-проект, 7 endpoints, Swagger UI, git-репозиторий с коммитами.
