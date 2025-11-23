# app/routers/users.py

from fastapi import APIRouter, Depends, HTTPException
from typing import List
from uuid import UUID
from datetime import datetime

from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    User,
    UserVisit,
    UserSaved,
    Location,
    LocationImage,
    LocationTag,
    Tag,
)
from app.utils.security import get_current_user
from app.schemas.user import UserUpdate
from app.schemas.location import LocationDetailResponse
from pydantic import BaseModel

router = APIRouter()


# --------------------------------------------------------
# INTERNAL SCHEMAS FOR PROFILE + VISITS
# --------------------------------------------------------

class VisitRecord(BaseModel):
    id: int
    location_name: str
    date: datetime
    points_earned: int = 0   # placeholder for future points system

    class Config:
        from_attributes = True


class UserProfileResponse(BaseModel):
    id: UUID
    name: str
    email: str
    level: int
    points: int
    visits: List[VisitRecord]
    reviews_count: int
    streak_days: int

    class Config:
        from_attributes = True


# --------------------------------------------------------
# GET /users/me
# --------------------------------------------------------

@router.get("/me", response_model=UserProfileResponse)
def get_my_profile(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    db_user: User | None = db.query(User).filter(User.id == user.id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Fetch visits + location names
    visit_rows = (
        db.query(UserVisit, Location)
        .join(Location, UserVisit.location_id == Location.id)
        .filter(UserVisit.user_id == db_user.id)
        .order_by(UserVisit.created_at.desc())
        .all()
    )

    visits = [
        VisitRecord(
            id=visit.id,
            location_name=loc.name,
            date=visit.created_at,
            points_earned=0,
        )
        for visit, loc in visit_rows
    ]

    profile = UserProfileResponse(
        id=db_user.id,
        name=db_user.username,
        email=db_user.email,
        level=1,          # placeholder for future level system
        points=0,         # placeholder for future points system
        visits=visits,
        reviews_count=len(db_user.reviews) if db_user.reviews else 0,
        streak_days=0,    # placeholder for future streak system
    )

    return profile


# --------------------------------------------------------
# PUT /users/me
# --------------------------------------------------------

@router.put("/me", response_model=UserProfileResponse)
def update_my_profile(
    payload: UserUpdate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    db_user: User | None = db.query(User).filter(User.id == user.id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    data = payload.dict(exclude_unset=True)

    # Enforce unique email if changed
    if "email" in data and data["email"] is not None:
        exists = (
            db.query(User)
            .filter(User.email == data["email"], User.id != db_user.id)
            .first()
        )
        if exists:
            raise HTTPException(status_code=400, detail="Email already in use")
        db_user.email = data["email"]

    if "username" in data and data["username"] is not None:
        db_user.username = data["username"]

    db.commit()
    db.refresh(db_user)

    # Re-run the same profile generation as GET /users/me
    visit_rows = (
        db.query(UserVisit, Location)
        .join(Location, UserVisit.location_id == Location.id)
        .filter(UserVisit.user_id == db_user.id)
        .order_by(UserVisit.created_at.desc())
        .all()
    )

    visits = [
        VisitRecord(
            id=visit.id,
            location_name=loc.name,
            date=visit.created_at,
            points_earned=0,
        )
        for visit, loc in visit_rows
    ]

    return UserProfileResponse(
        id=db_user.id,
        name=db_user.username,
        email=db_user.email,
        level=1,
        points=0,
        visits=visits,
        reviews_count=len(db_user.reviews) if db_user.reviews else 0,
        streak_days=0,
    )


# --------------------------------------------------------
# GET /users/{user_id}/saved-locations
# --------------------------------------------------------

@router.get("/{user_id}/saved-locations", response_model=List[LocationDetailResponse])
def get_saved_locations_for_user(
    user_id: UUID,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    saved_entries = (
        db.query(UserSaved)
        .filter(UserSaved.user_id == user_id)
        .all()
    )
    if not saved_entries:
        return []

    location_ids = [entry.location_id for entry in saved_entries]

    # Fetch base locations
    locations = (
        db.query(Location)
        .filter(Location.id.in_(location_ids))
        .all()
    )

    if not locations:
        return []

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

    # Prefetch tag objects
    tags = db.query(Tag).filter(Tag.id.in_(tag_ids)).all() if tag_ids else []
    tags_by_id = {t.id: t for t in tags}

    # Organize images & tags by location
    images_by_loc = {lid: [] for lid in location_ids}
    for img in images:
        images_by_loc.setdefault(img.location_id, []).append(img)

    tag_ids_by_loc = {lid: [] for lid in location_ids}
    for link in tag_links:
        tag_ids_by_loc.setdefault(link.location_id, []).append(link.tag_id)

    # Construct full detail responses
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


# --------------------------------------------------------
# GET /users/{user_id}/visits
# --------------------------------------------------------

@router.get("/{user_id}/visits", response_model=List[VisitRecord])
def get_user_visits(
    user_id: UUID,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Return visit history for a specific user.
    For now: only allow user to view their own visits.
    Later: can add role-based permissions.
    """

    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not allowed")

    rows = (
        db.query(UserVisit, Location)
        .join(Location, UserVisit.location_id == Location.id)
        .filter(UserVisit.user_id == user_id)
        .order_by(UserVisit.created_at.desc())
        .all()
    )

    visits = [
        VisitRecord(
            id=visit.id,
            location_name=loc.name,
            date=visit.created_at,
            points_earned=0,
        )
        for visit, loc in rows
    ]

    return visits
