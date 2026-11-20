"""Создание приложения и подключение Router."""
from fastapi import FastAPI

from app.routers import tasks

app = FastAPI(title="Tasks API")

app.include_router(tasks.router)
