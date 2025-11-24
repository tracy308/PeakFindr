# app/routers/reviews.py
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
import uuid
import os

from app.database import get_db
from app.models import Review, ReviewPhoto, Location
from app.schemas.review import (
    ReviewCreate,
    ReviewUpdate,
    ReviewResponse,
    ReviewPhotoResponse,
    ReviewWithPhotosResponse,
)
from app.utils.security import get_current_user

router = APIRouter()

# ------------------------------------
# File upload directory
# ------------------------------------

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UPLOAD_FOLDER = os.path.join(BASE_DIR, "..", "media", "review_photos")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)



# ------------------------------------
# 1. CREATE REVIEW
# ------------------------------------

@router.post("/", response_model=ReviewResponse)
def create_review(
    payload: ReviewCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Create a review for a location.
    Rating must be between 1 and 5.
    """

    # Verify location exists
    location = db.query(Location).filter(Location.id == payload.location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    if payload.rating < 1 or payload.rating > 5:
        raise HTTPException(status_code=400, detail="Rating must be between 1 and 5")

    new_review = Review(
        id=uuid.uuid4(),
        user_id=user.id,
        location_id=payload.location_id,
        rating=payload.rating,
        comment=payload.comment
    )

    db.add(new_review)
    db.commit()
    db.refresh(new_review)

    return new_review



# ------------------------------------
# 2. GET SINGLE REVIEW BY ID
# ------------------------------------

@router.get("/{review_id}", response_model=ReviewWithPhotosResponse)
def get_review_by_id(
    review_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Get a single review by its ID, including photos.
    """
    review = db.query(Review).filter(Review.id == review_id).first()
    
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    photos = (
        db.query(ReviewPhoto)
        .filter(ReviewPhoto.review_id == review_id)
        .all()
    )
    
    return {
        "review": review,
        "photos": photos
    }


# ------------------------------------
# 3. LIST ALL REVIEWS (Public)
# ------------------------------------

@router.get("/", response_model=List[ReviewWithPhotosResponse])
def get_all_reviews(
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Returns all reviews with photos, paginated.
    Useful for admin views or public review feeds.
    """
    reviews = (
        db.query(Review)
        .order_by(Review.created_at.desc())
        .limit(limit)
        .offset(offset)
        .all()
    )
    
    results = []
    for r in reviews:
        photos = (
            db.query(ReviewPhoto)
            .filter(ReviewPhoto.review_id == r.id)
            .all()
        )
        
        results.append({
            "review": r,
            "photos": photos
        })
    
    return results


# ------------------------------------
# 4. LIST REVIEWS FOR A LOCATION
# ------------------------------------

@router.get("/location/{location_id}", response_model=List[ReviewWithPhotosResponse])
def get_reviews_for_location(
    location_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Returns all reviews + photos for a location.
    """

    reviews = db.query(Review).filter(Review.location_id == location_id).all()

    results = []
    for r in reviews:
        photos = (
            db.query(ReviewPhoto)
            .filter(ReviewPhoto.review_id == r.id)
            .all()
        )

        results.append({
            "review": r,
            "photos": photos
        })

    return results


# ------------------------------------
# 5. LIST REVIEWS BY USER
# ------------------------------------

@router.get("/user/{user_id}", response_model=List[ReviewWithPhotosResponse])
def get_reviews_by_user(
    user_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Returns all reviews created by a specific user, with photos.
    Useful for user profile pages.
    """
    reviews = (
        db.query(Review)
        .filter(Review.user_id == user_id)
        .order_by(Review.created_at.desc())
        .all()
    )
    
    results = []
    for r in reviews:
        photos = (
            db.query(ReviewPhoto)
            .filter(ReviewPhoto.review_id == r.id)
            .all()
        )
        
        results.append({
            "review": r,
            "photos": photos
        })
    
    return results


# ------------------------------------
# 6. GET CURRENT USER'S REVIEWS
# ------------------------------------

@router.get("/me/reviews", response_model=List[ReviewWithPhotosResponse])
def get_my_reviews(
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Returns all reviews created by the authenticated user.
    """
    reviews = (
        db.query(Review)
        .filter(Review.user_id == user.id)
        .order_by(Review.created_at.desc())
        .all()
    )
    
    results = []
    for r in reviews:
        photos = (
            db.query(ReviewPhoto)
            .filter(ReviewPhoto.review_id == r.id)
            .all()
        )
        
        results.append({
            "review": r,
            "photos": photos
        })
    
    return results



# ------------------------------------
# 7. UPDATE REVIEW
# ------------------------------------

@router.put("/{review_id}", response_model=ReviewResponse)
def update_review(
    review_id: uuid.UUID,
    payload: ReviewUpdate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    A user can update ONLY their own review.
    """

    review = db.query(Review).filter(Review.id == review_id).first()

    if not review:
        raise HTTPException(status_code=404, detail="Review not found")

    if review.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not your review")

    data = payload.model_dump(exclude_unset=True)

    if "rating" in data:
        rating_value = data["rating"]
        if rating_value < 1 or rating_value > 5:
            raise HTTPException(status_code=400, detail="Rating must be 1-5")
        review.rating = rating_value

    if "comment" in data:
        review.comment = data["comment"]

    db.commit()
    db.refresh(review)

    return review



# ------------------------------------
# 8. DELETE REVIEW
# ------------------------------------

@router.delete("/{review_id}")
def delete_review(
    review_id: uuid.UUID,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    A user can delete their own review.
    """

    review = db.query(Review).filter(Review.id == review_id).first()

    if not review:
        raise HTTPException(status_code=404, detail="Review not found")

    if review.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not your review")

    db.delete(review)
    db.commit()

    return {"message": "Review deleted"}



# ------------------------------------
# 9. UPLOAD REVIEW PHOTO
# ------------------------------------

@router.post("/{review_id}/photos", response_model=ReviewPhotoResponse)
async def upload_review_photo(
    review_id: uuid.UUID,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Upload a photo for a review.
    """

    review = db.query(Review).filter(Review.id == review_id).first()

    if not review:
        raise HTTPException(status_code=404, detail="Review not found")

    if review.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not your review")

    # Save image
    filename = f"{review_id}_{uuid.uuid4()}.jpg"
    file_path = os.path.join(UPLOAD_FOLDER, filename)

    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)

    photo = ReviewPhoto(
        review_id=review_id,
        file_path=file_path
    )

    db.add(photo)
    db.commit()
    db.refresh(photo)

    return photo
