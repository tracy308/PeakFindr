# app/routers/interactions.py
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import uuid
from datetime import datetime

from app.database import get_db
from app.models import (
    Location,
    UserLike,
    UserSaved,
    UserVisit,
    User,
)
from app.schemas.user_interactions import (
    UserLikeResponse,
    UserSavedResponse,
    UserVisitResponse,
)
from app.utils.security import get_current_user


router = APIRouter()

POINTS_PER_CHECKIN = 10


# ------------------------------------------------------------
# Helper: Ensure location exists
# ------------------------------------------------------------
def validate_location(location_id: uuid.UUID, db: Session):
    loc = db.query(Location).filter(Location.id == location_id).first()
    if not loc:
        raise HTTPException(status_code=404, detail="Location not found")
    return loc


# ============================================================
# USER LIKES
# ============================================================

@router.post("/like/{location_id}")
def like_location(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    validate_location(location_id, db)

    existing = db.query(UserLike).filter(
        UserLike.user_id == user.id,
        UserLike.location_id == location_id
    ).first()

    if existing:
        return {"message": "Already liked"}

    new_like = UserLike(
        user_id=user.id,
        location_id=location_id
    )

    db.add(new_like)
    db.commit()

    return {"message": "Location liked"}


@router.delete("/like/{location_id}")
def unlike_location(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    validate_location(location_id, db)

    deleted = db.query(UserLike).filter(
        UserLike.user_id == user.id,
        UserLike.location_id == location_id
    ).delete()

    db.commit()

    if deleted:
        return {"message": "Like removed"}
    else:
        return {"message": "Was not liked"}


@router.get("/likes", response_model=List[UserLikeResponse])
def get_user_likes(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    likes = db.query(UserLike).filter(UserLike.user_id == user.id).all()
    return likes



# ============================================================
# USER SAVED LOCATIONS
# ============================================================

@router.post("/save/{location_id}")
def save_location(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    validate_location(location_id, db)

    existing = db.query(UserSaved).filter(
        UserSaved.user_id == user.id,
        UserSaved.location_id == location_id
    ).first()

    if existing:
        return {"message": "Already saved"}

    new_save = UserSaved(
        user_id=user.id,
        location_id=location_id
    )

    db.add(new_save)
    db.commit()

    return {"message": "Location saved"}


@router.delete("/save/{location_id}")
def unsave_location(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    validate_location(location_id, db)

    deleted = db.query(UserSaved).filter(
        UserSaved.user_id == user.id,
        UserSaved.location_id == location_id
    ).delete()

    db.commit()

    if deleted:
        return {"message": "Removed from saved"}
    else:
        return {"message": "Was not saved"}


@router.get("/saved", response_model=List[UserSavedResponse])
def get_user_saved(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    saved = db.query(UserSaved).filter(UserSaved.user_id == user.id).all()
    return saved



# ============================================================
# USER VISITS
# ============================================================

@router.post("/visit/{location_id}")
def add_visit(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    validate_location(location_id, db)

    saved_entry = db.query(UserSaved).filter(
        UserSaved.user_id == user.id,
        UserSaved.location_id == location_id,
    ).first()

    if not saved_entry:
        raise HTTPException(
            status_code=400,
            detail="Location must be saved before you can check in",
        )

    visit = UserVisit(
        user_id=user.id,
        location_id=location_id,
        created_at=datetime.utcnow(),
        points_earned=POINTS_PER_CHECKIN,
    )

    db.add(visit)

    # Remove from saved once checked in
    db.query(UserSaved).filter(
        UserSaved.user_id == user.id,
        UserSaved.location_id == location_id,
    ).delete()

    # Award points + level up
    db_user: User | None = db.query(User).filter(User.id == user.id).first()
    if db_user:
        db_user.points = (db_user.points or 0) + POINTS_PER_CHECKIN
        db_user.level = max(1, (db_user.points // 100) + 1)

    db.commit()
    db.refresh(visit)
    if db_user:
        db.refresh(db_user)

    return {
        "message": "Visit recorded",
        "visit_id": visit.id,
        "points_awarded": POINTS_PER_CHECKIN,
        "total_points": db_user.points if db_user else POINTS_PER_CHECKIN,
        "level": db_user.level if db_user else 1,
    }


@router.get("/visits", response_model=List[UserVisitResponse])
def get_user_visits(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    visits = (
        db.query(UserVisit)
        .filter(UserVisit.user_id == user.id)
        .order_by(UserVisit.created_at.desc())
        .all()
    )
    return visits
