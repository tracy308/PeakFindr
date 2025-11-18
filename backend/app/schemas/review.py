# app/schemas/review.py
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ReviewBase(BaseModel):
    rating: int
    comment: Optional[str] = None


class ReviewCreate(ReviewBase):
    location_id: UUID


class ReviewUpdate(BaseModel):
    rating: Optional[int] = None
    comment: Optional[str] = None


class ReviewResponse(ReviewBase):
    id: UUID
    user_id: UUID
    location_id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ReviewPhotoBase(BaseModel):
    review_id: UUID
    file_path: str


class ReviewPhotoCreate(ReviewPhotoBase):
    pass


class ReviewPhotoUpdate(BaseModel):
    file_path: Optional[str] = None


class ReviewPhotoResponse(ReviewPhotoBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ReviewWithPhotosResponse(BaseModel):
    review: ReviewResponse
    photos: List[ReviewPhotoResponse]

    model_config = ConfigDict(from_attributes=True)
