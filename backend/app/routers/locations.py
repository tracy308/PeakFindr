from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid
import os
from sqlalchemy import func
from sqlalchemy.exc import SQLAlchemyError
from fastapi.responses import FileResponse
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
    TagResponse,
)
from app.utils.security import get_current_user

router = APIRouter()

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UPLOAD_FOLDER = os.path.join(BASE_DIR, "..", "media", "location_images")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def normalize_name(name: str) -> str:
    """
    Convert location name into the filename format:
    - lowercase
    - no spaces
    - no apostrophes
    """
    return (
        name.lower()
            .replace(" ", "")
            .replace("'", "")
    )

@router.get("/{location_id}/image")
def get_location_image(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
):
    """
    Returns the main image for a location by deriving the
    filename from the location name.
    """
    # 1. Fetch location
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    # 2. Convert name -> filename pattern
    normalized = normalize_name(location.name)
    filename = f"{normalized}.jpg"  # adjust if png or jpeg exists

    # 3. Build full disk path
    file_path = os.path.join(
        BASE_DIR,
        "..",
        "media",
        "location_images",
        filename
    )

    # 4. Check existence
    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=404,
            detail=f"Image '{filename}' not found"
        )

    # 5. Serve the file
    return FileResponse(file_path, media_type="image/jpeg")

def _commit(db: Session):
    """Commit helper with rollback on failure."""
    try:
        db.commit()
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error: {str(e)}"
        )


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

    images = (
        db.query(LocationImage)
        .filter(LocationImage.location_id.in_(location_ids))
        .all()
    )

    tag_links = (
        db.query(LocationTag)
        .filter(LocationTag.location_id.in_(location_ids))
        .all()
    )
    tag_ids = [link.tag_id for link in tag_links]
    tags = db.query(Tag).filter(Tag.id.in_(tag_ids)).all() if tag_ids else []

    images_by_loc = {}
    for img in images:
        images_by_loc.setdefault(img.location_id, []).append(img)

    tags_by_id = {t.id: t for t in tags}

    tag_ids_by_loc = {}
    for link in tag_links:
        tag_ids_by_loc.setdefault(link.location_id, []).append(link.tag_id)

    results: List[LocationDetailResponse] = []
    for loc in locations:
        loc_images = images_by_loc.get(loc.id, [])
        loc_tag_ids = tag_ids_by_loc.get(loc.id, [])
        loc_tags = [tags_by_id[tid] for tid in loc_tag_ids if tid in tags_by_id]

        results.append(
            LocationDetailResponse.model_validate({
                "location": loc,
                "images": loc_images,
                "tags": loc_tags
            })
        )

    return results


# ---------------------------------------------------------------------
# 0.5. FILTER LOCATIONS BY TAGS (Public)
# ---------------------------------------------------------------------
@router.get("/by-tags", response_model=List[LocationDetailResponse])
def filter_locations_by_tags(
    tags: str,  # comma-separated tag names, e.g., "hiking,scenic"
    match_all: bool = False,  # if True, location must have ALL tags; if False, ANY tag
    db: Session = Depends(get_db),
):
    """
    Filter locations by tags.
    - tags: comma-separated tag names (e.g., "hiking,scenic,sunset")
    - match_all: if True, returns locations with ALL specified tags; if False, returns locations with ANY tag
    
    Returns location details including images and tags.
    """
    if not tags or not tags.strip():
        raise HTTPException(status_code=400, detail="Tags parameter is required")
    
    # Parse tag names
    tag_names = [name.strip().lower() for name in tags.split(",") if name.strip()]
    
    if not tag_names:
        raise HTTPException(status_code=400, detail="No valid tags provided")
    
    # Find tag IDs
    tag_objects = db.query(Tag).filter(Tag.name.in_(tag_names)).all()
    
    if not tag_objects:
        # No matching tags found - return empty list
        return []
    
    found_tag_ids = [tag.id for tag in tag_objects]
    
    if match_all:
        # Location must have ALL specified tags
        # Count how many of the specified tags each location has
        location_tag_counts = (
            db.query(LocationTag.location_id, func.count(LocationTag.tag_id).label('tag_count'))
            .filter(LocationTag.tag_id.in_(found_tag_ids))
            .group_by(LocationTag.location_id)
            .having(func.count(LocationTag.tag_id) == len(found_tag_ids))
            .all()
        )
        matching_location_ids = [loc_id for loc_id, _ in location_tag_counts]
    else:
        # Location must have ANY of the specified tags
        matching_location_ids = (
            db.query(LocationTag.location_id)
            .filter(LocationTag.tag_id.in_(found_tag_ids))
            .distinct()
            .all()
        )
        matching_location_ids = [loc_id for (loc_id,) in matching_location_ids]
    
    if not matching_location_ids:
        return []
    
    # Fetch matching locations
    locations = (
        db.query(Location)
        .filter(Location.id.in_(matching_location_ids))
        .all()
    )
    
    # Prefetch images and tags for these locations
    images = (
        db.query(LocationImage)
        .filter(LocationImage.location_id.in_(matching_location_ids))
        .all()
    )
    
    tag_links = (
        db.query(LocationTag)
        .filter(LocationTag.location_id.in_(matching_location_ids))
        .all()
    )
    all_tag_ids = [link.tag_id for link in tag_links]
    
    all_tags = db.query(Tag).filter(Tag.id.in_(all_tag_ids)).all() if all_tag_ids else []
    
    # Build lookup maps
    images_by_loc = {}
    for img in images:
        images_by_loc.setdefault(img.location_id, []).append(img)
    
    tags_by_id = {t.id: t for t in all_tags}
    
    tag_ids_by_loc = {}
    for link in tag_links:
        tag_ids_by_loc.setdefault(link.location_id, []).append(link.tag_id)
    
    results = []
    for loc in locations:
        loc_images = images_by_loc.get(loc.id, [])
        loc_tag_ids = tag_ids_by_loc.get(loc.id, [])
        loc_tags = [tags_by_id[tid] for tid in loc_tag_ids if tid in tags_by_id]
        
        results.append(
            LocationDetailResponse.model_validate({
                "location": loc,
                "images": loc_images,
                "tags": loc_tags
            })
        )
    
    return results


# ---------------------------------------------------------------------
# 1. CREATE LOCATION (Public — no authentication required)
# ---------------------------------------------------------------------
@router.post("/", response_model=LocationResponse)
def create_location(
    payload: LocationCreate,
    db: Session = Depends(get_db),
):
    try:
        new_location = Location(
            id=uuid.uuid4(),
            **payload.model_dump()
        )
        db.add(new_location)
        _commit(db)
        db.refresh(new_location)
        return LocationResponse.model_validate(new_location)
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


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
    if price_level is not None:
        query = query.filter(Location.price_level == price_level)

    locations = query.all()
    return [LocationResponse.model_validate(loc) for loc in locations]


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

    return LocationDetailResponse.model_validate({
        "location": location,
        "images": images,
        "tags": tags,
    })


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

    _commit(db)
    db.refresh(location)
    return LocationResponse.model_validate(location)


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
    _commit(db)
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
    disk_path = os.path.join(UPLOAD_FOLDER, filename)

    content = await file.read()
    with open(disk_path, "wb") as f:
        f.write(content)

    # Store relative path in DB (usually better than absolute)
    rel_path = os.path.join("media", "location_images", filename)

    new_image = LocationImage(
        location_id=location_id,
        file_path=rel_path
    )

    db.add(new_image)
    _commit(db)
    db.refresh(new_image)

    return LocationImageResponse.model_validate(new_image)


# ---------------------------------------------------------------------
# 6.1. ADD IMAGE BY FILE PATH (Public)
# ---------------------------------------------------------------------
@router.post("/{location_id}/images/from-path", response_model=LocationImageResponse)
def add_location_image_from_path(
    location_id: uuid.UUID,
    file_path: str,
    db: Session = Depends(get_db),
):
    """
    Directly attach an existing image file to a location.
    This does NOT upload or write files — only adds DB entry.
    """
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    # Ensure consistent relative path usage
    if not file_path.startswith("media/location_images/"):
        file_path = f"media/location_images/{file_path}"

    # Create the DB row
    img = LocationImage(
        location_id=location_id,
        file_path=file_path
    )

    db.add(img)
    _commit(db)
    db.refresh(img)

    return LocationImageResponse.model_validate(img)


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

    added_tags: List[Tag] = []

    try:
        for tag_name in payload.tags:
            tag_name = tag_name.strip()
            if not tag_name:
                continue

            tag = db.query(Tag).filter(Tag.name == tag_name).first()
            if not tag:
                tag = Tag(name=tag_name)
                db.add(tag)
                _commit(db)
                db.refresh(tag)

            exists = db.query(LocationTag).filter(
                LocationTag.location_id == location_id,
                LocationTag.tag_id == tag.id
            ).first()

            if not exists:
                db.add(LocationTag(location_id=location_id, tag_id=tag.id))
                added_tags.append(tag)

        _commit(db)

        # Return only Tag objects per schema
        return LocationTagsResponse.model_validate({
            "added_tags": added_tags
        })

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


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
    _commit(db)

    return {"message": "Tag removed"}
