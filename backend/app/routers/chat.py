# app/routers/chat.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import uuid

from app.database import get_db
from app.models import ChatMessage, Location
from app.schemas.chat import ChatMessageCreate, ChatMessageResponse
from app.utils.security import get_current_user


router = APIRouter()

MAX_MESSAGES = 200   # Limit per location



# ------------------------------------------
# 1. SEND CHAT MESSAGE
# ------------------------------------------

@router.post("/{location_id}", response_model=ChatMessageResponse)
def send_message(
    location_id: uuid.UUID,
    payload: ChatMessageCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Send a message in a global chat room of a location.
    """

    # Validate location exists
    loc = db.query(Location).filter(Location.id == location_id).first()
    if not loc:
        raise HTTPException(status_code=404, detail="Location not found")

    # Create new chat message
    new_msg = ChatMessage(
        location_id=location_id,
        user_id=user.id,  # can be None later for anonymous
        message=payload.message
    )

    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)

    # Enforce message limit (keep only last MAX_MESSAGES)
    prune_old_messages(location_id, db)

    return new_msg



# ------------------------------------------
# 2. GET CHAT MESSAGES FOR LOCATION
# ------------------------------------------

@router.get("/{location_id}", response_model=List[ChatMessageResponse])
def get_messages(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Returns the last X messages (default MAX_MESSAGES)
    Ordered from oldest → newest
    """

    msgs = (
        db.query(ChatMessage)
          .filter(ChatMessage.location_id == location_id)
          .order_by(ChatMessage.created_at.asc())
          .limit(MAX_MESSAGES)
          .all()
    )

    return msgs



# ------------------------------------------
# Helper: Prune messages to keep last 200
# ------------------------------------------

def prune_old_messages(location_id: uuid.UUID, db: Session):
    """
    Keeps only the last MAX_MESSAGES messages.
    Deletes older ones.
    """

    total = (
        db.query(ChatMessage)
          .filter(ChatMessage.location_id == location_id)
          .count()
    )

    if total <= MAX_MESSAGES:
        return

    # Find cutoff
    cutoff_msg = (
        db.query(ChatMessage)
          .filter(ChatMessage.location_id == location_id)
          .order_by(ChatMessage.created_at.desc())
          .offset(MAX_MESSAGES)
          .first()
    )

    # Delete older messages
    db.query(ChatMessage).filter(
        ChatMessage.location_id == location_id,
        ChatMessage.created_at < cutoff_msg.created_at
    ).delete()

    db.commit()
