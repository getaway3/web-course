"""Проверка, что API после рефакторинга работает так же, как в ПР4: POST/GET/PUT/DELETE /tasks.
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
    assert set(paths["/tasks/"]) == {"get", "post"}
    assert set(paths["/tasks/{task_id}"]) == {"get", "put", "delete"}


def test_get_empty(client):
    r = client.get("/tasks/")
    assert r.status_code == 200 and r.json() == []


def test_post_then_get(client):
    r = client.post("/tasks/", json={"title": "Изучить архитектуру FastAPI", "completed": False})
    assert r.status_code == 201
    created = r.json()
    assert created == {"id": 1, "title": "Изучить архитектуру FastAPI", "completed": False}
    assert client.get("/tasks/").json() == [created]
    assert client.get("/tasks/1").json() == created


def test_update_and_delete(client):
    client.post("/tasks/", json={"title": "задача"})
    r = client.put("/tasks/1", json={"title": "задача", "completed": True})
    assert r.status_code == 200 and r.json()["completed"] is True
    assert client.delete("/tasks/1").status_code == 200
    assert client.get("/tasks/1").status_code == 404


def test_completed_defaults_to_false(client):
    r = client.post("/tasks/", json={"title": "без completed"})
    assert r.json()["completed"] is False


def test_validation_error(client):
    assert client.post("/tasks/", json={"completed": True}).status_code == 422
