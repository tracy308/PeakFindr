# app/main.py
from fastapi import FastAPI

from app.database import engine, Base
from app import models  # ensures all models are imported & registered
from app.routers import auth

app = FastAPI()


@app.on_event("startup")
def on_startup():
    # For development only; later switch to Alembic migrations
    Base.metadata.create_all(bind=engine)

app.include_router(auth.router, prefix="/auth")


@app.get("/")
def root():
    return {"message": "Backend is running"}

