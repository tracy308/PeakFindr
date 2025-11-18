# app/database.py
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from dotenv import load_dotenv

# Load env vars from .env
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL is not set in environment variables.")

# ---------- SQLAlchemy Base Class ----------

class Base(DeclarativeBase):
    """Base class for all models."""
    pass

# ---------- Engine & Session Factory ----------

# echo=True -> logs SQL to console (good for debug, turn off in prod)
engine = create_engine(DATABASE_URL, echo=True)

SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)

# ---------- Dependency for FastAPI Routes ----------

def get_db():
    """
    FastAPI dependency that provides a DB session.
    Use it in routes as: db: Session = Depends(get_db)
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
