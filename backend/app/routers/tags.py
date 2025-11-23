# app/routers/tags.py

from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Tag
from app.schemas.location import TagCreate, TagResponse

router = APIRouter()


# -----------------------------------------
# 1. LIST ALL TAGS (Public)
# -----------------------------------------
@router.get("/", response_model=List[TagResponse])
def list_tags(
    db: Session = Depends(get_db),
):
    """
    Returns the list of all tags.
    Used for filter screens, search screens,
    and tag selection during location creation.
    """
    tags = db.query(Tag).order_by(Tag.name.asc()).all()
    return tags


# -----------------------------------------
# 2. CREATE NEW TAG (Public)
# -----------------------------------------
@router.post("/", response_model=TagResponse)
def create_tag(
    payload: TagCreate,
    db: Session = Depends(get_db),
):
    """
    Create a new tag.
    MVP: Public endpoint.
    Future: Restrict to admin only.
    """
    # Check duplicate
    existing = db.query(Tag).filter(Tag.name == payload.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Tag already exists")

    new_tag = Tag(name=payload.name)
    db.add(new_tag)
    db.commit()
    db.refresh(new_tag)

    return new_tag


# -----------------------------------------
# 3. DELETE TAG (Public — may restrict later)
# -----------------------------------------
@router.delete("/{tag_id}")
def delete_tag(
    tag_id: int,
    db: Session = Depends(get_db),
):
    """
    Delete a tag.
    Safe due to ON DELETE CASCADE on link table.
    """
    tag = db.query(Tag).filter(Tag.id == tag_id).first()

    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")

    db.delete(tag)
    db.commit()

    return {"message": "Tag deleted successfully"}
