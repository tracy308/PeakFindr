# app/models/chat.py
from datetime import datetime
from typing import TYPE_CHECKING
import uuid

from sqlalchemy import Text, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


if TYPE_CHECKING:
    from app.models.location import Location
    from app.models.user import User


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    location_id: Mapped["UUID"] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("locations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    user_id: Mapped["UUID"] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    message: Mapped[str] = mapped_column(Text, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        nullable=False,
        index=True,
    )

    # Relationships
    location: Mapped["Location"] = relationship("Location", back_populates="chat_messages")
    user: Mapped["User"] = relationship("User", back_populates="chat_messages")


# ================================
# NEW: SOCIAL HUB CHAT ROOM MODELS
# ================================


class ChatRoom(Base):
    __tablename__ = "chat_rooms"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    # e.g., "all", "food", "sights", "hiking"
    category: Mapped[str | None] = mapped_column(String(50), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        nullable=False,
    )

    # Relationship to room messages
    messages: Mapped[list["ChatRoomMessage"]] = relationship(
        "ChatRoomMessage",
        back_populates="room",
        cascade="all, delete-orphan",
    )


class ChatRoomMessage(Base):
    __tablename__ = "chat_room_messages"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    room_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("chat_rooms.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    user_id: Mapped["UUID | None"] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    text: Mapped[str] = mapped_column(Text, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        nullable=False,
        index=True,
    )

    # Relationships
    room: Mapped["ChatRoom"] = relationship("ChatRoom", back_populates="messages")
    user: Mapped["User"] = relationship("User")  # no back_populates needed for now