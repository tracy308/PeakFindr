# app/schemas/chat.py
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ChatMessageBase(BaseModel):
    message: str


class ChatMessageCreate(ChatMessageBase):
    pass


class ChatMessageUpdate(BaseModel):
    message: Optional[str] = None


class ChatMessageResponse(ChatMessageBase):
    id: int
    location_id: UUID
    user_id: Optional[UUID] = None
    created_at: datetime
    username: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class ChatRoomBase(BaseModel):
    name: str
    category: Optional[str] = None  # "all", "food", "sights", "hiking"


class ChatRoomCreate(ChatRoomBase):
    pass


class ChatRoomResponse(ChatRoomBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ChatRoomMessageBase(BaseModel):
    text: str


class ChatRoomMessageCreate(ChatRoomMessageBase):
    pass


class ChatRoomMessageResponse(ChatRoomMessageBase):
    id: int
    room_id: UUID
    user_id: Optional[UUID] = None
    created_at: datetime
    username: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)