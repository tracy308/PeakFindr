# app/schemas/location.py
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class LocationBase(BaseModel):
    name: str
    description: Optional[str] = None
    maps_url: Optional[str] = None
    price_level: Optional[int] = None
    area: Optional[str] = None
    region: Optional[str] = None
    summary: Optional[str] = None
    duration: Optional[str] = None
    opening_hours: Optional[str] = None
    region: Optional[str] = None
    summary: Optional[str] = None
    duration: Optional[str] = None
    opening_hours: Optional[str] = None

class LocationCreate(LocationBase):
    pass


class LocationUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    maps_url: Optional[str] = None
    price_level: Optional[int] = None
    area: Optional[str] = None
    region: Optional[str] = None
    summary: Optional[str] = None
    duration: Optional[str] = None
    opening_hours: Optional[str] = None

class LocationResponse(LocationBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class LocationImageBase(BaseModel):
    location_id: UUID
    file_path: str


class LocationImageCreate(LocationImageBase):
    pass


class LocationImageUpdate(BaseModel):
    file_path: Optional[str] = None


class LocationImageResponse(LocationImageBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TagBase(BaseModel):
    name: str


class TagCreate(TagBase):
    pass


class TagUpdate(BaseModel):
    name: Optional[str] = None


class TagResponse(TagBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


class LocationTagBase(BaseModel):
    location_id: UUID
    tag_id: int


class LocationTagCreate(LocationTagBase):
    pass


class LocationTagUpdate(BaseModel):
    location_id: Optional[UUID] = None
    tag_id: Optional[int] = None


class LocationTagResponse(LocationTagBase):
    tags: List[str]


class LocationDetailResponse(BaseModel):
    location: LocationResponse
    images: List[LocationImageResponse]
    tags: List[TagResponse]

    model_config = ConfigDict(from_attributes=True)


class LocationTagsResponse(BaseModel):
    added_tags: List[TagResponse]

