# app/routers/interactions.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import uuid
from datetime import datetime

from app.database import get_db
from app.models import (
    Location,
    UserLike,
    UserSaved,
    UserVisit
)
from app.utils.security import get_current_user


router = APIRouter()


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


@router.get("/likes")
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


@router.get("/saved")
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

    visit = UserVisit(
        id=uuid.uuid4(),
        user_id=user.id,
        location_id=location_id,
        created_at=datetime.utcnow()
    )

    db.add(visit)
    db.commit()

    return {"message": "Visit recorded", "visit_id": visit.id}


@router.get("/visits")
def get_user_visits(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    visits = db.query(UserVisit).filter(UserVisit.user_id == user.id).all()
    return visits
