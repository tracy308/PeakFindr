from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid
import os
from sqlalchemy import func

from app.database import get_db
from app.models import (
    Location, LocationImage, Tag, LocationTag, UserVisit
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


# ---------------------------------------------------------------------
# 0. RECOMMENDED LOCATIONS (Personalized — requires authenticated user)
# ---------------------------------------------------------------------
@router.get("/recommended", response_model=List[LocationDetailResponse])
def get_recommended_locations(
    limit: int = 10,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    """
    Personalized recommendations:
    - Excludes locations the user has visited.
    - Random ordering (future: category-based).
    """
    # limit sanity check
    limit = max(1, min(limit, 50))

    visited_subq = (
        db.query(UserVisit.location_id)
        .filter(UserVisit.user_id == user.id)
        .subquery()
    )

    locations = (
        db.query(Location)
        .filter(~Location.id.in_(visited_subq))
        .order_by(func.random())
        .limit(limit)
        .all()
    )

    if not locations:
        return []

    location_ids = [loc.id for loc in locations]

    # Prefetch images
    images = (
        db.query(LocationImage)
        .filter(LocationImage.location_id.in_(location_ids))
        .all()
    )

    # Prefetch tag links
    tag_links = (
        db.query(LocationTag)
        .filter(LocationTag.location_id.in_(location_ids))
        .all()
    )
    tag_ids = [link.tag_id for link in tag_links]

    # Prefetch tags
    tags = db.query(Tag).filter(Tag.id.in_(tag_ids)).all() if tag_ids else []

    # Build maps
    images_by_loc = {}
    for img in images:
        images_by_loc.setdefault(img.location_id, []).append(img)

    tags_by_id = {t.id: t for t in tags}

    tag_ids_by_loc = {}
    for link in tag_links:
        tag_ids_by_loc.setdefault(link.location_id, []).append(link.tag_id)

    results = []
    for loc in locations:
        loc_images = images_by_loc.get(loc.id, [])
        loc_tag_ids = tag_ids_by_loc.get(loc.id, [])
        loc_tags = [tags_by_id[tid] for tid in loc_tag_ids if tid in tags_by_id]

        results.append({
            "location": loc,
            "images": loc_images,
            "tags": loc_tags,
        })

    return results


# ---------------------------------------------------------------------
# 1. CREATE LOCATION (Public — no authentication required)
# ---------------------------------------------------------------------
@router.post("/", response_model=LocationResponse)
def create_location(
    payload: LocationCreate,
    db: Session = Depends(get_db),
):
    new_location = Location(
        id=uuid.uuid4(),
        **payload.model_dump()
    )
    db.add(new_location)
    db.commit()
    db.refresh(new_location)
    return new_location


# ---------------------------------------------------------------------
# 2. LIST LOCATIONS (Public)
# ---------------------------------------------------------------------
@router.get("/", response_model=List[LocationResponse])
def list_locations(
    area: Optional[str] = None,
    price_level: Optional[int] = None,
    db: Session = Depends(get_db),
):
    query = db.query(Location)

    if area:
        query = query.filter(Location.area == area)
    if price_level:
        query = query.filter(Location.price_level == price_level)

    return query.all()


# ---------------------------------------------------------------------
# 3. GET SINGLE LOCATION + IMAGES + TAGS (Public)
# ---------------------------------------------------------------------
@router.get("/{location_id}", response_model=LocationDetailResponse)
def get_location(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    images = db.query(LocationImage).filter(LocationImage.location_id == location_id).all()

    tag_links = db.query(LocationTag).filter(LocationTag.location_id == location_id).all()
    tag_ids = [t.tag_id for t in tag_links]
    tags = db.query(Tag).filter(Tag.id.in_(tag_ids)).all() if tag_ids else []

    return {
        "location": location,
        "images": images,
        "tags": tags,
    }


# ---------------------------------------------------------------------
# 4. UPDATE LOCATION (Public for now — later restrict to admin)
# ---------------------------------------------------------------------
@router.put("/{location_id}", response_model=LocationResponse)
def update_location(
    location_id: uuid.UUID,
    payload: LocationUpdate,
    db: Session = Depends(get_db),
):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(location, key, value)

    db.commit()
    db.refresh(location)
    return location


# ---------------------------------------------------------------------
# 5. DELETE LOCATION (Public — admin restriction later)
# ---------------------------------------------------------------------
@router.delete("/{location_id}")
def delete_location(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    db.delete(location)
    db.commit()
    return {"message": "Location deleted"}


# ---------------------------------------------------------------------
# 6. UPLOAD IMAGE TO LOCATION (Public)
# ---------------------------------------------------------------------
@router.post("/{location_id}/images", response_model=LocationImageResponse)
async def upload_location_image(
    location_id: uuid.UUID,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    filename = f"{location_id}_{uuid.uuid4()}.jpg"
    file_path = os.path.join(UPLOAD_FOLDER, filename)

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


# ---------------------------------------------------------------------
# 7. ADD TAGS TO LOCATION (Public)
# ---------------------------------------------------------------------
@router.post("/{location_id}/tags", response_model=LocationTagsResponse)
def add_tags_to_location(
    location_id: uuid.UUID,
    payload: LocationTagsRequest,
    db: Session = Depends(get_db),
):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    added_tags = []

    for tag_name in payload.tags:
        tag = db.query(Tag).filter(Tag.name == tag_name).first()
        if not tag:
            tag = Tag(name=tag_name)
            db.add(tag)
            db.commit()
            db.refresh(tag)

        exists = db.query(LocationTag).filter(
            LocationTag.location_id == location_id,
            LocationTag.tag_id == tag.id
        ).first()

        if not exists:
            db.add(LocationTag(location_id=location_id, tag_id=tag.id))
            added_tags.append(tag)

    db.commit()

    return {"added_tags": added_tags}


# ---------------------------------------------------------------------
# 8. REMOVE TAG FROM LOCATION (Public)
# ---------------------------------------------------------------------
@router.delete("/{location_id}/tags/{tag_id}")
def remove_tag_from_location(
    location_id: uuid.UUID,
    tag_id: int,
    db: Session = Depends(get_db),
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
