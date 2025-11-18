# app/schemas/user.py
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class UserBase(BaseModel):
    email: str
    username: str
    role: str = "user"


class UserCreate(UserBase):
    password_hash: str


class UserUpdate(BaseModel):
    email: Optional[str] = None
    username: Optional[str] = None
    password_hash: Optional[str] = None
    role: Optional[str] = None


class UserResponse(UserBase):
    id: UUID
    password_hash: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
