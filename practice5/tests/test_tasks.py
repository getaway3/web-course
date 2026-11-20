"""Проверка, что API после рефакторинга работает: POST /tasks/ и GET /tasks/.
Тесты используют SQLite в памяти вместо PostgreSQL (подмена зависимости get_session).
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.database import get_session
from app.main import app
from app.models import Base


@pytest.fixture()
def client():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    Base.metadata.create_all(engine)

    def override():
        with Session(engine) as session:
            yield session

    app.dependency_overrides[get_session] = override
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_routes_are_registered(client):
    paths = client.get("/openapi.json").json()["paths"]
    assert "get" in paths["/tasks/"] and "post" in paths["/tasks/"]


def test_get_empty(client):
    r = client.get("/tasks/")
    assert r.status_code == 200 and r.json() == []


def test_post_then_get(client):
    r = client.post("/tasks/", json={"title": "Изучить архитектуру FastAPI", "completed": False})
    assert r.status_code == 200
    created = r.json()
    assert created == {"id": 1, "title": "Изучить архитектуру FastAPI", "completed": False}
    assert client.get("/tasks/").json() == [created]


def test_completed_defaults_to_false(client):
    r = client.post("/tasks/", json={"title": "без completed"})
    assert r.json()["completed"] is False


def test_validation_error(client):
    assert client.post("/tasks/", json={"completed": True}).status_code == 422
