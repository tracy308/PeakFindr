# app/routers/auth.py
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.utils.security import hash_password, verify_password

from pydantic import BaseModel
import uuid

router = APIRouter()


# ---------- Pydantic Schemas ----------

class RegisterRequest(BaseModel):
    email: str
    username: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


# ---------- Register ----------

@router.post("/register")
def register_user(data: RegisterRequest, db: Session = Depends(get_db)):

    # Check if user already exists
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        id=uuid.uuid4(),
        email=data.email,
        username=data.username,
        password_hash=hash_password(data.password),
        role="user"
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return {
        "message": "User registered successfully",
        "user_id": str(user.id),
        "email": user.email,
        "username": user.username
    }


# ---------- Login ----------

@router.post("/login")
def login_user(data: LoginRequest, db: Session = Depends(get_db)):

    user = db.query(User).filter(User.email == data.email).first()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # MVP response: just return user_id
    return {
        "message": "Login successful",
        "user_id": str(user.id),
        "email": user.email,
        "username": user.username
    }


@router.get("/me")
def debug_header(x_user_id: str = Header(None)):
    if x_user_id is None:
        return {"message": "X-User-ID header missing"}
    return {"message": "Header received", "user_id": x_user_id}

