"""HTTP-эндпоинты для задач."""
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_session
from app.models import Task
from app.schemas import TaskCreate, TaskRead

router = APIRouter(prefix="/tasks", tags=["Tasks"])


@router.get("/", response_model=list[TaskRead])
def get_tasks(session: Session = Depends(get_session)):
    return session.scalars(select(Task).order_by(Task.id)).all()


@router.post("/", response_model=TaskRead)
def create_task(data: TaskCreate, session: Session = Depends(get_session)):
    task = Task(title=data.title, completed=data.completed)
    session.add(task)
    session.commit()
    session.refresh(task)
    return task
