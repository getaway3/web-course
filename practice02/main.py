"""Практическая работа №2. REST API на FastAPI: Pet Clinic (вариант 1).

Данные хранятся в памяти (обычные списки Python), база данных не используется.
Две коллекции предметной области: /pets (Pet) и /veterinarians (Veterinarian).

Запуск:  python -m uvicorn main:app --reload
Swagger: http://127.0.0.1:8000/docs
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="Pet Clinic API (ПР2)", version="1.0")


# ---------- Pydantic-модели ----------
class VeterinarianCreate(BaseModel):
    name: str = Field(min_length=1, examples=["Иван Петров"])
    specialization: str = Field(min_length=1, examples=["Терапевт"])


class Veterinarian(VeterinarianCreate):
    id: int


class PetCreate(BaseModel):
    # Пример тела запроса в Swagger UI: без veterinarian_id (иначе Swagger подставит 0 и получится 404)
    model_config = {"json_schema_extra": {"examples": [{"name": "Мурка", "species": "Кошка", "age": 1}]}}

    name: str = Field(min_length=1, examples=["Барсик"])
    species: str = Field(min_length=1, examples=["Кошка"])
    age: int = Field(ge=0, le=60, examples=[3])
    veterinarian_id: int | None = Field(default=None, description="id ветеринара (необязательно)")


class Pet(PetCreate):
    id: int


# ---------- Данные в памяти ----------
veterinarians: list[Veterinarian] = [
    Veterinarian(id=1, name="Иван Петров", specialization="Терапевт"),
    Veterinarian(id=2, name="Мария Соколова", specialization="Хирург"),
]
pets: list[Pet] = [
    Pet(id=1, name="Барсик", species="Кошка", age=3, veterinarian_id=1),
    Pet(id=2, name="Рекс", species="Собака", age=5, veterinarian_id=2),
    Pet(id=3, name="Кеша", species="Попугай", age=2),
]
_next_id = {"pets": 4, "veterinarians": 3}


def _new_id(collection: str) -> int:
    value = _next_id[collection]
    _next_id[collection] += 1
    return value


def _find(items, item_id: int, what: str):
    for item in items:
        if item.id == item_id:
            return item
    raise HTTPException(status_code=404, detail=f"{what} with id={item_id} not found")


# ---------- Служебное ----------
@app.get("/info")
def info():
    return {
        "project": "Pet Clinic API",
        "version": "1.0",
        "theme": "Pet Clinic",
        "entities": ["Pet", "Veterinarian"],
        "storage": "in-memory",
    }


# ---------- Pets ----------
@app.get("/pets", response_model=list[Pet])
def list_pets():
    return pets


@app.get("/pets/{pet_id}", response_model=Pet)
def get_pet(pet_id: int):
    return _find(pets, pet_id, "Pet")


@app.post("/pets", response_model=Pet, status_code=201)
def create_pet(data: PetCreate):
    if data.veterinarian_id is not None:
        _find(veterinarians, data.veterinarian_id, "Veterinarian")   # 404, если ветеринара нет
    pet = Pet(id=_new_id("pets"), **data.model_dump())
    pets.append(pet)
    return pet


@app.delete("/pets/{pet_id}")
def delete_pet(pet_id: int):
    pets.remove(_find(pets, pet_id, "Pet"))
    return {"message": f"Pet {pet_id} deleted"}


# ---------- Veterinarians ----------
@app.get("/veterinarians", response_model=list[Veterinarian])
def list_veterinarians():
    return veterinarians


@app.get("/veterinarians/{vet_id}", response_model=Veterinarian)
def get_veterinarian(vet_id: int):
    return _find(veterinarians, vet_id, "Veterinarian")


@app.post("/veterinarians", response_model=Veterinarian, status_code=201)
def create_veterinarian(data: VeterinarianCreate):
    vet = Veterinarian(id=_new_id("veterinarians"), **data.model_dump())
    veterinarians.append(vet)
    return vet


@app.delete("/veterinarians/{vet_id}")
def delete_veterinarian(vet_id: int):
    vet = _find(veterinarians, vet_id, "Veterinarian")
    if any(p.veterinarian_id == vet_id for p in pets):
        raise HTTPException(status_code=409, detail="Veterinarian has pets, reassign or delete them first")
    veterinarians.remove(vet)
    return {"message": f"Veterinarian {vet_id} deleted"}
