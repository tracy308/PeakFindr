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
from app.models import ChatMessage, Location, ChatRoom, ChatRoomMessage, User
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


def serialize_chat_message(message: ChatMessage, username: str | None = None) -> ChatMessageResponse:
    return ChatMessageResponse(
        id=message.id,
        location_id=message.location_id,
        user_id=message.user_id,
        message=message.message,
        created_at=message.created_at,
        username=username,
    )


def serialize_room_message(message: ChatRoomMessage, username: str | None = None) -> ChatRoomMessageResponse:
    return ChatRoomMessageResponse(
        id=message.id,
        room_id=message.room_id,
        user_id=message.user_id,
        text=message.text,
        created_at=message.created_at,
        username=username,
    )


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

    return serialize_chat_message(new_msg, user.username)


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
        db.query(ChatMessage, User.username)
        .join(User, ChatMessage.user_id == User.id, isouter=True)
        .filter(ChatMessage.location_id == location_id)
        .order_by(ChatMessage.created_at.asc())
        .limit(MAX_MESSAGES)
        .all()
    )

    return [serialize_chat_message(msg, username) for msg, username in msgs]


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


@router.websocket("/{location_id}/ws")
async def location_websocket_endpoint(websocket: WebSocket, location_id: str):
    """
    Real-time chat tied to a specific location.

    Expects JSON payloads:
      {"text": "hello", "user_id": "<uuid>"}
    """
    try:
        loc_uuid = uuid.UUID(location_id)
    except ValueError:
        await websocket.close(code=1008)
        return

    db = SessionLocal()
    try:
        loc_exists = db.query(Location.id).filter(Location.id == loc_uuid).first()
        if not loc_exists:
            await websocket.close(code=1008)
            return
    finally:
        db.close()

    await location_manager.connect(loc_uuid, websocket)

    try:
        while True:
            data = await websocket.receive_json()
            text = data.get("text")
            user_id_str = data.get("user_id") or websocket.headers.get("x-user-id")

            if not text:
                continue

            db = SessionLocal()
            try:
                user_uuid = None
                user_obj: User | None = None
                if user_id_str:
                    try:
                        user_uuid = uuid.UUID(str(user_id_str))
                        user_obj = db.query(User).filter(User.id == user_uuid).first()
                    except ValueError:
                        user_uuid = None

                msg = ChatMessage(
                    location_id=loc_uuid,
                    user_id=user_uuid,
                    message=text,
                )
                db.add(msg)
                db.commit()
                db.refresh(msg)

                payload = serialize_chat_message(msg, user_obj.username if user_obj else None).model_dump()
                prune_old_messages(loc_uuid, db)
            finally:
                db.close()

            await location_manager.broadcast(loc_uuid, payload)
    except WebSocketDisconnect:
        location_manager.disconnect(loc_uuid, websocket)


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

    query = (
        db.query(ChatRoomMessage, User.username)
        .join(User, ChatRoomMessage.user_id == User.id, isouter=True)
        .filter(ChatRoomMessage.room_id == room_id)
    )

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
    return [serialize_room_message(msg, username) for msg, username in msgs]


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

    return serialize_room_message(msg, user.username)


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


room_manager = ConnectionManager()
location_manager = ConnectionManager()


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
        await websocket.close(code=1008)
        return

    await room_manager.connect(room_uuid, websocket)

    try:
        while True:
            data = await websocket.receive_json()
            text = data.get("text")
            user_id_str = data.get("user_id")

            if not text:
                continue

            db = SessionLocal()
            try:
                user_uuid = None
                user_obj: User | None = None
                if user_id_str:
                    try:
                        user_uuid = uuid.UUID(user_id_str)
                        user_obj = db.query(User).filter(User.id == user_uuid).first()
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

                payload = serialize_room_message(msg, user_obj.username if user_obj else None).model_dump()
            finally:
                db.close()

            await room_manager.broadcast(room_uuid, payload)

    except WebSocketDisconnect:
        room_manager.disconnect(room_uuid, websocket)
