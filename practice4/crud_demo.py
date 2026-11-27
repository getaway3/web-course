"""Практическая работа №4 (консольная версия): SQLAlchemy 2.x ORM поверх PostgreSQL. Основной проект - FastAPI-приложение в main.py.

Таблица tasks не меняется. echo=True оставлен включённым - в консоли видны SQL-запросы,
которые SQLAlchemy формирует автоматически.
"""
import os

from sqlalchemy import String, create_engine, select
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql+psycopg://student:student@localhost:54329/practice",
)

engine = create_engine(DATABASE_URL, echo=True)


class Base(DeclarativeBase):
    pass


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(255))
    completed: Mapped[bool] = mapped_column(default=False)

    def __repr__(self):
        return f"Task(id={self.id}, title={self.title!r}, completed={self.completed})"


def banner(text):
    print(f"\n{'=' * 12} {text} {'=' * 12}")


def main():
    with Session(engine) as session:
        banner("CREATE")
        task = Task(title="Изучить SQLAlchemy", completed=False)
        session.add(task)
        session.commit()
        task_id = task.id
        print("Создана:", task)

        banner("READ: одна задача по id (session.get)")
        print(session.get(Task, task_id))

        banner("READ: список задач (select)")
        for t in session.scalars(select(Task).order_by(Task.id)).all():
            print(t)

        banner("UPDATE")
        task = session.get(Task, task_id)
        task.completed = True
        session.commit()
        print("После изменения:", session.get(Task, task_id))

        banner("DELETE")
        task = session.get(Task, task_id)
        session.delete(task)
        session.commit()
        print("После удаления session.get ->", session.get(Task, task_id))


if __name__ == "__main__":
    main()
