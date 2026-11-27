"""Проверка API из ПР4 без PostgreSQL: подменяем Session на SQLite в памяти."""
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import Session  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

import main  # noqa: E402


@pytest.fixture()
def client():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    main.Base.metadata.create_all(engine)

    def override():
        with Session(engine) as session:
            yield session

    main.app.dependency_overrides[main.get_session] = override
    yield TestClient(main.app)
    main.app.dependency_overrides.clear()


def test_crud_cycle(client):
    created = client.post("/tasks", json={"title": "Изучить SQLAlchemy"})
    assert created.status_code == 201
    task = created.json()
    assert task == {"id": 1, "title": "Изучить SQLAlchemy", "completed": False}

    assert client.get("/tasks").json() == [task]
    assert client.get("/tasks/1").json() == task

    updated = client.put("/tasks/1", json={"title": "Изучить SQLAlchemy", "completed": True})
    assert updated.status_code == 200 and updated.json()["completed"] is True

    deleted = client.delete("/tasks/1")
    assert deleted.status_code == 200 and "deleted" in deleted.json()["message"]
    assert client.get("/tasks/1").status_code == 404
    assert client.get("/tasks").json() == []


def test_not_found(client):
    assert client.get("/tasks/999").status_code == 404
    assert client.put("/tasks/999", json={"title": "x"}).status_code == 404
    assert client.delete("/tasks/999").status_code == 404


def test_validation(client):
    assert client.post("/tasks", json={"completed": True}).status_code == 422


def test_routes_registered(client):
    paths = client.get("/openapi.json").json()["paths"]
    assert set(paths["/tasks"]) == {"get", "post"}
    assert set(paths["/tasks/{task_id}"]) == {"get", "put", "delete"}
