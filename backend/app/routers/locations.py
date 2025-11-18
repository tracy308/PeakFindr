# app/routers/locations.py
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid
import os

from app.database import get_db
from app.models import (
    Location, LocationImage, Tag, LocationTag
)
from app.schemas.location import (
    LocationCreate,
    LocationUpdate,
    LocationResponse,
    LocationImageResponse,
    LocationTagsRequest,
    LocationDetailResponse,
    LocationTagsResponse,
)
from app.utils.security import get_current_user

router = APIRouter()

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UPLOAD_FOLDER = os.path.join(BASE_DIR, "..", "media", "location_images")

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    
# -------------------------------
# 1. CREATE LOCATION
# -------------------------------

@router.post("/", response_model=LocationResponse)
def create_location(
    payload: LocationCreate,
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
        **payload.model_dump()
    )

    db.add(new_location)
    db.commit()
    db.refresh(new_location)

    return new_location



# -------------------------------
# 2. LIST LOCATIONS
# -------------------------------

@router.get("/", response_model=List[LocationResponse])
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

@router.get("/{location_id}", response_model=LocationDetailResponse)
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
    tag_links = db.query(LocationTag).filter(LocationTag.location_id == location_id).all()
    tag_ids = [t.tag_id for t in tag_links]
    tags = db.query(Tag).filter(Tag.id.in_(tag_ids)).all() if tag_ids else []

    return {
        "location": location,
        "images": images,
        "tags": tags,
    }



# -------------------------------
# 4. UPDATE LOCATION
# -------------------------------

@router.put("/{location_id}", response_model=LocationResponse)
def update_location(
    location_id: uuid.UUID,
    payload: LocationUpdate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):

    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(location, key, value)

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

@router.post("/{location_id}/images", response_model=LocationImageResponse)
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

@router.post("/{location_id}/tags", response_model=LocationTagsResponse)
def add_tags_to_location(
    location_id: uuid.UUID,
    payload: LocationTagsRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):

    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    added_tags = []

    for tag_name in payload.tags:
        # Get or create tag
        tag = db.query(Tag).filter(Tag.name == tag_name).first()
        if not tag:
            tag = Tag(name=tag_name)
            db.add(tag)
            db.commit()
            db.refresh(tag)

        # Link location ↔ tag
        exists = db.query(LocationTag).filter(
            LocationTag.location_id == location_id,
            LocationTag.tag_id == tag.id
        ).first()

        if not exists:
            db.add(LocationTag(location_id=location_id, tag_id=tag.id))
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

    link = db.query(LocationTag).filter(
        LocationTag.location_id == location_id,
        LocationTag.tag_id == tag_id
    ).first()

    if not link:
        raise HTTPException(status_code=404, detail="Tag not attached to location")

    db.delete(link)
    db.commit()

    return {"message": "Tag removed"}