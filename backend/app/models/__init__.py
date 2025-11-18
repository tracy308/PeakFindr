# app/models/__init__.py
from .user import User
from .location import Location, LocationImage, LocationTag, Tag
from .review import Review, ReviewPhoto
from .chat import ChatMessage
from .user_interactions import UserLike, UserVisit, UserSaved

# This file makes it easy to import all models from app.models
__all__ = [
    "User",
    "Location",
    "LocationImage",
    "LocationTag",
    "Tag",
    "Review",
    "ReviewPhoto",
    "ChatMessage",
    "UserLike",
    "UserVisit",
    "UserSaved",
]
