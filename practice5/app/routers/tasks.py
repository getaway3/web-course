"""HTTP-эндпоинты для задач (перенесены из main.py ПР4 без изменения путей и поведения)."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_session
from app.models import Task
from app.schemas import TaskCreate, TaskRead

router = APIRouter(prefix="/tasks", tags=["Tasks"])


@router.get("/", response_model=list[TaskRead])
def get_tasks(session: Session = Depends(get_session)):
    return session.scalars(select(Task).order_by(Task.id)).all()


@router.post("/", response_model=TaskRead, status_code=201)
def create_task(data: TaskCreate, session: Session = Depends(get_session)):
    task = Task(title=data.title, completed=data.completed)
    session.add(task)
    session.commit()
    session.refresh(task)
    return task


@router.get("/{task_id}", response_model=TaskRead)
def get_task(task_id: int, session: Session = Depends(get_session)):
    task = session.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail=f"Task with id={task_id} not found")
    return task


@router.put("/{task_id}", response_model=TaskRead)
def update_task(task_id: int, data: TaskCreate, session: Session = Depends(get_session)):
    task = session.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail=f"Task with id={task_id} not found")
    task.title = data.title
    task.completed = data.completed
    session.commit()
    session.refresh(task)
    return task


@router.delete("/{task_id}")
def delete_task(task_id: int, session: Session = Depends(get_session)):
    task = session.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail=f"Task with id={task_id} not found")
    session.delete(task)
    session.commit()
    return {"message": f"Task {task_id} deleted"}
