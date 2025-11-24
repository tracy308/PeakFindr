# app/routers/chatbot.py
from __future__ import annotations

import os
from typing import List, Literal
import uuid

import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Location
from app.utils.security import get_current_user

router = APIRouter()


class ChatTurn(BaseModel):
    role: Literal["user", "assistant"]
    content: str


class ChatBotRequest(BaseModel):
    message: str
    history: List[ChatTurn] = Field(default_factory=list)


class ChatBotResponse(BaseModel):
    reply: str
    location_id: uuid.UUID


async def _generate_reply(prompt: list[dict[str, str]]) -> str:
    api_key = os.getenv("DEEPSEEK_API_KEY")
    if not api_key:
        return "I'm here to help, but the AI guide isn't configured yet."

    headers = {"Authorization": f"Bearer {api_key}"}
    payload = {"model": "deepseek-chat", "messages": prompt, "stream": False}

    try:
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.post(
                "https://api.deepseek.com/chat/completions",
                headers=headers,
                json=payload,
            )
            resp.raise_for_status()
            data = resp.json()
            return data.get("choices", [{}])[0].get("message", {}).get(
                "content", "I can help you explore!"
            )
    except Exception:
        return "I'm having trouble reaching the AI guide right now. Please try again later."


@router.post("/{location_id}", response_model=ChatBotResponse)
async def chat_with_bot(
    location_id: uuid.UUID,
    payload: ChatBotRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    system_prompt = (
        "You are a friendly, knowledgeable tour guide for this destination. "
        "Keep responses concise, helpful, and focused on the location."
    )

    location_context = " ".join(
        part
        for part in [
            f"You are helping a visitor explore {location.name}.",
            f"Area: {location.area}." if location.area else "",
            f"Region: {location.region}." if getattr(location, "region", None) else "",
            f"Overview: {location.description}." if location.description else "",
            f"Summary: {location.summary}." if getattr(location, "summary", None) else "",
        ]
        if part
    )

    messages: list[dict[str, str]] = [
        {"role": "system", "content": system_prompt},
        {"role": "assistant", "content": f"Hi, I'm your tour guide for {location.name}."},
    ]
    if location_context:
        messages.append({"role": "system", "content": location_context})
    for turn in payload.history:
        messages.append({"role": turn.role, "content": turn.content})
    messages.append({"role": "user", "content": payload.message})

    reply_text = await _generate_reply(messages)

    return ChatBotResponse(reply=reply_text, location_id=location_id)
