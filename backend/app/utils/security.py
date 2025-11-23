# app/utils/security.py
from fastapi import Header, HTTPException, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User

from passlib.context import CryptContext

# Password hashing context
pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto"
)
# ---------- Password Helpers ----------

def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


# ---------- User Extraction ----------

async def get_current_user(
    x_user_id: str = Header(None),
    db: Session = Depends(get_db)
):
    """
    Reads user ID from the X-User-ID header.
    Later: replace this with JWT verification.
    """

    if not x_user_id:
        raise HTTPException(status_code=401, detail="X-User-ID header missing")

    user = db.query(User).filter(User.id == x_user_id).first()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid user ID")

    return user
