# app/routers/tags.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.models import Tag
from app.utils.security import get_current_user

router = APIRouter()


# -----------------------------------------
# 1. LIST ALL TAGS
# -----------------------------------------

@router.get("/")
def list_tags(
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Returns the list of all tags.
    Used for filter screens & admin creation UI.
    """
    tags = db.query(Tag).order_by(Tag.name.asc()).all()
    return tags



# -----------------------------------------
# 2. CREATE NEW TAG
# -----------------------------------------

@router.post("/")
def create_tag(
    name: str,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Create a new tag.
    MVP: Everyone can create.
    Later: Restrict to admin only.
    """

    # Check duplicate tag
    existing = db.query(Tag).filter(Tag.name == name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Tag already exists")

    new_tag = Tag(name=name)
    db.add(new_tag)
    db.commit()
    db.refresh(new_tag)

    return new_tag



# -----------------------------------------
# 3. DELETE TAG (optional, admin later)
# -----------------------------------------

@router.delete("/{tag_id}")
def delete_tag(
    tag_id: int,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Delete a tag.
    This does NOT break locations:
      - association table has ON DELETE CASCADE
    """

    tag = db.query(Tag).filter(Tag.id == tag_id).first()

    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")

    db.delete(tag)
    db.commit()

    return {"message": "Tag deleted successfully"}
