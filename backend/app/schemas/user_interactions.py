# app/schemas/user_interactions.py
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class _UserLocationBase(BaseModel):
    user_id: UUID
    location_id: UUID


class UserLikeCreate(_UserLocationBase):
    pass


class UserLikeUpdate(BaseModel):
    user_id: Optional[UUID] = None
    location_id: Optional[UUID] = None


class UserLikeResponse(_UserLocationBase):
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserSavedCreate(_UserLocationBase):
    pass


class UserSavedUpdate(BaseModel):
    user_id: Optional[UUID] = None
    location_id: Optional[UUID] = None


class UserSavedResponse(_UserLocationBase):
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserVisitBase(_UserLocationBase):
    pass


class UserVisitCreate(UserVisitBase):
    created_at: Optional[datetime] = None
    points_earned: int = 0


class UserVisitUpdate(BaseModel):
    user_id: Optional[UUID] = None
    location_id: Optional[UUID] = None
    created_at: Optional[datetime] = None
    points_earned: Optional[int] = None


class UserVisitResponse(UserVisitBase):
    id: int
    created_at: datetime
    points_earned: int

    model_config = ConfigDict(from_attributes=True)
