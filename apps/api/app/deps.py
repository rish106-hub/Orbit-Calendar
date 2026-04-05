from collections.abc import Generator
from datetime import timezone
import uuid

from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.user import User

DEV_USER_ID = uuid.UUID("11111111-1111-1111-1111-111111111111")


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_or_create_dev_user(db: Session) -> User:
    user = db.get(User, DEV_USER_ID)
    if user is None:
        user = User(
            id=DEV_USER_ID,
            email="dev@orbit.local",
            display_name="Orbit Dev User",
            default_timezone="Asia/Kolkata",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user
