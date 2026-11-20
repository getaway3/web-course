"""Pydantic-схемы: проверяют входные данные и описывают ответы API."""
from pydantic import BaseModel, ConfigDict


class TaskCreate(BaseModel):
    title: str
    completed: bool = False


class TaskRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    completed: bool
