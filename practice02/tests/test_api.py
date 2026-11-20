"""Проверка REST API (ПР2) через TestClient: коды ответов и тела."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient  # noqa: E402

import main  # noqa: E402

client = TestClient(main.app)


def test_list_pets():
    r = client.get("/pets")
    assert r.status_code == 200 and len(r.json()) >= 3


def test_get_pet_and_404():
    assert client.get("/pets/1").json()["name"] == "Барсик"
    r = client.get("/pets/999")
    assert r.status_code == 404 and "not found" in r.json()["detail"]


def test_create_and_delete_pet():
    r = client.post("/pets", json={"name": "Мурка", "species": "Кошка", "age": 1})
    assert r.status_code == 201
    pet = r.json()
    assert pet["id"] > 3 and pet["veterinarian_id"] is None
    assert client.get(f"/pets/{pet['id']}").status_code == 200
    d = client.delete(f"/pets/{pet['id']}")
    assert d.status_code == 200 and "deleted" in d.json()["message"]
    assert client.get(f"/pets/{pet['id']}").status_code == 404
    assert client.delete(f"/pets/{pet['id']}").status_code == 404


def test_validation_errors():
    assert client.post("/pets", json={"name": "X"}).status_code == 422
    assert client.post("/pets", json={"name": "X", "species": "Y", "age": -1}).status_code == 422
    assert client.post("/pets", json={"name": "X", "species": "Y", "age": 1, "veterinarian_id": 999}).status_code == 404


def test_veterinarians_crud_and_conflict():
    r = client.post("/veterinarians", json={"name": "Ольга Ким", "specialization": "Дерматолог"})
    assert r.status_code == 201
    vid = r.json()["id"]
    assert client.get(f"/veterinarians/{vid}").json()["name"] == "Ольга Ким"
    assert client.delete("/veterinarians/1").status_code == 409     # у ветеринара 1 есть питомец
    assert client.delete(f"/veterinarians/{vid}").status_code == 200
    assert client.get(f"/veterinarians/{vid}").status_code == 404


def test_info():
    assert client.get("/info").json()["project"] == "Pet Clinic API"
