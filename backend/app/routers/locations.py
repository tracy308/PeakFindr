# app/routers/locations.py

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid
import os
from datetime import datetime

from app.database import get_db
from app.models import (
    Location, LocationImage, Tag, LocationTags
)
from app.utils.security import get_current_user

router = APIRouter()

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UPLOAD_FOLDER = os.path.join(BASE_DIR, "..", "media", "location_images")

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    
# -------------------------------
# 1. CREATE LOCATION
# -------------------------------

@router.post("/")
def create_location(
    name: str,
    description: Optional[str] = None,
    maps_url: Optional[str] = None,
    price_level: Optional[int] = None,
    area: Optional[str] = None,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Creates a new location.
    MVP: Open to all authenticated users.
    Later: Restrict to admin role.
    """

    new_location = Location(
        id=uuid.uuid4(),
        name=name,
        description=description,
        maps_url=maps_url,
        price_level=price_level,
        area=area
    )

    db.add(new_location)
    db.commit()
    db.refresh(new_location)

    return new_location



# -------------------------------
# 2. LIST LOCATIONS
# -------------------------------

@router.get("/")
def list_locations(
    area: Optional[str] = None,
    price_level: Optional[int] = None,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Returns all locations with optional filters.
    Later: Use for swipe/random logic.
    """

    query = db.query(Location)

    if area:
        query = query.filter(Location.area == area)

    if price_level:
        query = query.filter(Location.price_level == price_level)

    return query.all()



# -------------------------------
# 3. GET SINGLE LOCATION + IMAGES + TAGS
# -------------------------------

@router.get("/{location_id}")
def get_location(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):

    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    # Fetch images
    images = db.query(LocationImage).filter(LocationImage.location_id == location_id).all()

    # Fetch tags
    tag_links = db.query(LocationTags).filter(LocationTags.location_id == location_id).all()
    tag_ids = [t.tag_id for t in tag_links]
    tags = db.query(Tag).filter(Tag.id.in_(tag_ids)).all()

    return {
        "location": location,
        "images": images,
        "tags": tags,
    }



# -------------------------------
# 4. UPDATE LOCATION
# -------------------------------

@router.put("/{location_id}")
def update_location(
    location_id: uuid.UUID,
    name: Optional[str] = None,
    description: Optional[str] = None,
    maps_url: Optional[str] = None,
    price_level: Optional[int] = None,
    area: Optional[str] = None,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):

    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    if name is not None:
        location.name = name
    if description is not None:
        location.description = description
    if maps_url is not None:
        location.maps_url = maps_url
    if price_level is not None:
        location.price_level = price_level
    if area is not None:
        location.area = area

    db.commit()
    db.refresh(location)

    return location



# -------------------------------
# 5. DELETE LOCATION
# -------------------------------

@router.delete("/{location_id}")
def delete_location(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):

    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    db.delete(location)
    db.commit()

    return {"message": "Location deleted"}



# -------------------------------
# 6. UPLOAD IMAGE TO LOCATION
# -------------------------------

@router.post("/{location_id}/images")
async def upload_location_image(
    location_id: uuid.UUID,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):

    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    # Create unique file name
    filename = f"{location_id}_{uuid.uuid4()}.jpg"
    file_path = os.path.join(UPLOAD_FOLDER, filename)

    # Save file locally
    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)

    new_image = LocationImage(
        location_id=location_id,
        file_path=file_path
    )

    db.add(new_image)
    db.commit()
    db.refresh(new_image)

    return new_image



# -------------------------------
# 7. ADD TAGS TO LOCATION
# -------------------------------

@router.post("/{location_id}/tags")
def add_tags_to_location(
    location_id: uuid.UUID,
    tags: List[str],
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):

    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    added_tags = []

    for tag_name in tags:
        # Get or create tag
        tag = db.query(Tag).filter(Tag.name == tag_name).first()
        if not tag:
            tag = Tag(name=tag_name)
            db.add(tag)
            db.commit()
            db.refresh(tag)

        # Link location ↔ tag
        exists = db.query(LocationTags).filter(
            LocationTags.location_id == location_id,
            LocationTags.tag_id == tag.id
        ).first()

        if not exists:
            db.add(LocationTags(location_id=location_id, tag_id=tag.id))
            added_tags.append(tag)

    db.commit()

    return {"added_tags": added_tags}



# -------------------------------
# 8. REMOVE TAG FROM LOCATION
# -------------------------------

@router.delete("/{location_id}/tags/{tag_id}")
def remove_tag_from_location(
    location_id: uuid.UUID,
    tag_id: int,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):

    link = db.query(LocationTags).filter(
        LocationTags.location_id == location_id,
        LocationTags.tag_id == tag_id
    ).first()

    if not link:
        raise HTTPException(status_code=404, detail="Tag not attached to location")

    db.delete(link)
    db.commit()

    return {"message": "Tag removed"}