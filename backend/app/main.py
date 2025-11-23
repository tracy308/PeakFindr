# app/main.py
from fastapi import FastAPI

from app.database import engine, Base
from app import models  # ensures all models are imported & registered
from app.routers import auth, chat, locations, interactions, reviews, tags, users

app = FastAPI()


@app.on_event("startup")
def on_startup():
    # For development only; later switch to Alembic migrations
    Base.metadata.create_all(bind=engine)

app.include_router(users.router, prefix="/users")
app.include_router(auth.router, prefix="/auth")
app.include_router(chat.router, prefix="/chat")
app.include_router(locations.router, prefix="/locations")
app.include_router(interactions.router, prefix="/interactions")
app.include_router(reviews.router, prefix="/reviews")
app.include_router(tags.router, prefix="/tags")

@app.get("/")
def root():
    return {"message": "Backend is running"}

