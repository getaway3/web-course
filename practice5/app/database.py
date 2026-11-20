"""Подключение к PostgreSQL и Session (Dependency Injection для роутеров)."""
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql+psycopg://student:student@localhost:54329/practice",
)

engine = create_engine(DATABASE_URL)


def get_session():
    with Session(engine) as session:
        yield session
