"""Практическая работа №4: SQLAlchemy 2.x ORM в FastAPI-приложении.

Таблица tasks из практики №3 (PostgreSQL в Docker) не меняется: мы заменяем «ручной» SQL (cursor.execute)
на ORM. В этом файле, как и до рефакторинга в ПР5, находится всё сразу: создание FastAPI-приложения,
подключение к PostgreSQL, SQLAlchemy-модель, Pydantic-схемы и endpoints.

echo=True оставлен включённым: в консоли сервера видны SQL-запросы, которые SQLAlchemy формирует сама.

Запуск:  python -m uvicorn main:app --reload      Swagger: http://127.0.0.1:8000/docs
"""
import os

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict
from sqlalchemy import String, create_engine, select
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column

# ---------- подключение к PostgreSQL ----------
DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql+psycopg://student:student@localhost:54329/practice",
)

engine = create_engine(DATABASE_URL, echo=True)


def get_session():
    """Выдаёт Session на время одного запроса (Dependency Injection)."""
    with Session(engine) as session:
        yield session


# ---------- SQLAlchemy-модель (таблица tasks) ----------
class Base(DeclarativeBase):
    pass


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(255))
    completed: Mapped[bool] = mapped_column(default=False)


# ---------- Pydantic-схемы ----------
class TaskCreate(BaseModel):
    title: str
    completed: bool = False


class TaskRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    completed: bool


# ---------- FastAPI-приложение и endpoints ----------
app = FastAPI(title="Tasks API (ПР4: SQLAlchemy ORM)")


@app.get("/tasks", response_model=list[TaskRead])
def list_tasks(session: Session = Depends(get_session)):
    """READ: список задач (select)."""
    return session.scalars(select(Task).order_by(Task.id)).all()


@app.get("/tasks/{task_id}", response_model=TaskRead)
def get_task(task_id: int, session: Session = Depends(get_session)):
    """READ: одна задача по id (session.get)."""
    task = session.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail=f"Task with id={task_id} not found")
    return task


@app.post("/tasks", response_model=TaskRead, status_code=201)
def create_task(data: TaskCreate, session: Session = Depends(get_session)):
    """CREATE: новая задача (session.add + commit)."""
    task = Task(title=data.title, completed=data.completed)
    session.add(task)
    session.commit()
    session.refresh(task)
    return task


@app.put("/tasks/{task_id}", response_model=TaskRead)
def update_task(task_id: int, data: TaskCreate, session: Session = Depends(get_session)):
    """UPDATE: изменить задачу (меняем поля объекта + commit)."""
    task = session.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail=f"Task with id={task_id} not found")
    task.title = data.title
    task.completed = data.completed
    session.commit()
    session.refresh(task)
    return task


@app.delete("/tasks/{task_id}")
def delete_task(task_id: int, session: Session = Depends(get_session)):
    """DELETE: удалить задачу (session.delete + commit)."""
    task = session.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail=f"Task with id={task_id} not found")
    session.delete(task)
    session.commit()
    return {"message": f"Task {task_id} deleted"}
