# app/models/location.py
import uuid
from datetime import datetime

from sqlalchemy import String, Integer, Text, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Location(Base):
    __tablename__ = "locations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    maps_url: Mapped[str | None] = mapped_column(Text, nullable=True)

    price_level: Mapped[int | None] = mapped_column(Integer, nullable=True)  # e.g., 1–4
    area: Mapped[str | None] = mapped_column(String(100), nullable=True)
    region: Mapped[str | None] = mapped_column(String(100), nullable=True)
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    duration: Mapped[str | None] = mapped_column(String(100), nullable=True)
    opening_hours: Mapped[str | None] = mapped_column(String(255), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        nullable=False,
    )

    # Relationships
    images: Mapped[list["LocationImage"]] = relationship(
        "LocationImage",
        back_populates="location",
        cascade="all, delete-orphan",
    )

    tags: Mapped[list["LocationTag"]] = relationship(
        "LocationTag",
        back_populates="location",
        cascade="all, delete-orphan",
    )

    reviews: Mapped[list["Review"]] = relationship(
        "Review",
        back_populates="location",
        cascade="all, delete-orphan",
    )

    chat_messages: Mapped[list["ChatMessage"]] = relationship(
        "ChatMessage",
        back_populates="location",
        cascade="all, delete-orphan",
    )

    likes: Mapped[list["UserLike"]] = relationship(
        "UserLike",
        back_populates="location",
        cascade="all, delete-orphan",
    )

    visits: Mapped[list["UserVisit"]] = relationship(
        "UserVisit",
        back_populates="location",
        cascade="all, delete-orphan",
    )

    saved_by: Mapped[list["UserSaved"]] = relationship(
        "UserSaved",
        back_populates="location",
        cascade="all, delete-orphan",
    )


class LocationImage(Base):
    __tablename__ = "location_images"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    location_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("locations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    file_path: Mapped[str] = mapped_column(Text, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        nullable=False,
    )

    location: Mapped["Location"] = relationship("Location", back_populates="images")


class Tag(Base):
    __tablename__ = "tags"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)

    locations: Mapped[list["LocationTag"]] = relationship(
        "LocationTag",
        back_populates="tag",
        cascade="all, delete-orphan",
    )


class LocationTag(Base):
    __tablename__ = "location_tags"

    location_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("locations.id", ondelete="CASCADE"),
        primary_key=True,
    )
    tag_id: Mapped[int] = mapped_column(
        ForeignKey("tags.id", ondelete="CASCADE"),
        primary_key=True,
    )

    location: Mapped["Location"] = relationship("Location", back_populates="tags")
    tag: Mapped["Tag"] = relationship("Tag", back_populates="locations")

    __table_args__ = (
        UniqueConstraint("location_id", "tag_id", name="uq_location_tag_pair"),
    )
