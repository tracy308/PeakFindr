# app/routers/chat.py
from datetime import datetime
from typing import List, Dict, Optional
import uuid

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    WebSocket,
    WebSocketDisconnect,
)
from sqlalchemy.orm import Session

from app.database import get_db, SessionLocal
from app.models import ChatMessage, Location, ChatRoom, ChatRoomMessage
from app.schemas.chat import (
    ChatMessageCreate,
    ChatMessageResponse,
    ChatRoomCreate,
    ChatRoomResponse,
    ChatRoomMessageCreate,
    ChatRoomMessageResponse,
)
from app.utils.security import get_current_user


router = APIRouter()

MAX_MESSAGES = 200   # Limit per location


# ============================================================
# EXISTING: LOCATION-SPECIFIC CHAT
# ============================================================


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
        message=payload.message,
    )

    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)

    # Enforce message limit (keep only last MAX_MESSAGES)
    prune_old_messages(location_id, db)

    return new_msg


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


# ============================================================
# NEW: SOCIAL HUB CHAT ROOMS
# Endpoints: /chat/rooms, /chat/rooms/{id}/messages, /ws
# ============================================================

# Default rooms to seed (once)
DEFAULT_ROOMS = [
    {"name": "General Chat", "category": "all"},
    {"name": "Foodies", "category": "food"},
    {"name": "Sights & Views", "category": "sights"},
    {"name": "Hiking Buddies", "category": "hiking"},
]


def ensure_default_rooms(db: Session) -> None:
    """
    Make sure our default chat rooms exist.
    Called lazily from list_chat_rooms().
    """
    existing = db.query(ChatRoom).all()
    existing_names = {r.name for r in existing}

    created = False
    for room in DEFAULT_ROOMS:
        if room["name"] not in existing_names:
            db.add(ChatRoom(name=room["name"], category=room["category"]))
            created = True

    if created:
        db.commit()


@router.get("/rooms", response_model=List[ChatRoomResponse])
def list_chat_rooms(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    """
    List all chat rooms.
    Also ensures default rooms exist on first call.
    """
    ensure_default_rooms(db)
    rooms = db.query(ChatRoom).order_by(ChatRoom.created_at.asc()).all()
    return rooms


@router.post("/rooms", response_model=ChatRoomResponse)
def create_chat_room(
    payload: ChatRoomCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    """
    Create a new chat room.
    MVP: any logged-in user can create.
    Later: restrict to admin if needed.
    """
    new_room = ChatRoom(
        name=payload.name,
        category=payload.category,
    )

    db.add(new_room)
    db.commit()
    db.refresh(new_room)

    return new_room


@router.get("/rooms/{room_id}/messages", response_model=List[ChatRoomMessageResponse])
def get_room_messages(
    room_id: uuid.UUID,
    limit: int = 50,
    before: Optional[datetime] = None,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    """
    Get messages for a room.
    - limit: max messages to return (default 50)
    - before: if provided, return messages strictly before this timestamp
    Ordered oldest → newest.
    """
    room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    query = db.query(ChatRoomMessage).filter(ChatRoomMessage.room_id == room_id)

    if before is not None:
        query = query.filter(ChatRoomMessage.created_at < before)

    # newest first, then reversed in memory to oldest → newest
    msgs = (
        query
        .order_by(ChatRoomMessage.created_at.desc())
        .limit(limit)
        .all()
    )

    msgs.reverse()
    return msgs


@router.post("/rooms/{room_id}/messages", response_model=ChatRoomMessageResponse)
def send_room_message(
    room_id: uuid.UUID,
    payload: ChatRoomMessageCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    """
    Send a message to a chat room (HTTP version).
    For real-time, the frontend will use WebSocket, but this
    endpoint gives a simple fallback / initial implementation.
    """
    room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    msg = ChatRoomMessage(
        room_id=room_id,
        user_id=user.id,
        text=payload.text,
    )

    db.add(msg)
    db.commit()
    db.refresh(msg)

    return msg


# ------------------------------------------------------------
# WebSocket Manager for /chat/rooms/{room_id}/ws
# ------------------------------------------------------------


class ConnectionManager:
    def __init__(self):
        # room_id -> list of WebSocket connections
        self.active_connections: Dict[uuid.UUID, List[WebSocket]] = {}

    async def connect(self, room_id: uuid.UUID, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.setdefault(room_id, []).append(websocket)

    def disconnect(self, room_id: uuid.UUID, websocket: WebSocket):
        connections = self.active_connections.get(room_id)
        if not connections:
            return
        if websocket in connections:
            connections.remove(websocket)
        if not connections:
            self.active_connections.pop(room_id, None)

    async def broadcast(self, room_id: uuid.UUID, message: dict):
        for connection in self.active_connections.get(room_id, []):
            await connection.send_json(message)


manager = ConnectionManager()


@router.websocket("/rooms/{room_id}/ws")
async def room_websocket_endpoint(
    websocket: WebSocket,
    room_id: str,
):
    """
    WebSocket for real-time chat in a room.

    Frontend can send messages:
      { "text": "hello world", "user_id": "<uuid-string>" }

    We store them in DB and broadcast the serialized message
    to all connected clients in this room.
    """
    try:
        room_uuid = uuid.UUID(room_id)
    except ValueError:
        # Cannot raise HTTPException in WS; just close connection.
        await websocket.close(code=1008)
        return

    await manager.connect(room_uuid, websocket)

    try:
        while True:
            data = await websocket.receive_json()
            text = data.get("text")
            user_id_str = data.get("user_id")

            if not text:
                # ignore empty payloads
                continue

            # Persist to DB
            db = SessionLocal()
            try:
                user_uuid = None
                if user_id_str:
                    try:
                        user_uuid = uuid.UUID(user_id_str)
                    except ValueError:
                        user_uuid = None

                msg = ChatRoomMessage(
                    room_id=room_uuid,
                    user_id=user_uuid,
                    text=text,
                )
                db.add(msg)
                db.commit()
                db.refresh(msg)

                payload = ChatRoomMessageResponse.model_validate(msg).model_dump()
            finally:
                db.close()

            # Broadcast to all clients in this room
            await manager.broadcast(room_uuid, payload)

    except WebSocketDisconnect:
        manager.disconnect(room_uuid, websocket)
