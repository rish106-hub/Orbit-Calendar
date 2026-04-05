from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.deps import get_db, get_or_create_dev_user
from app.schemas.user import MeResponse

router = APIRouter()


@router.get("/me", response_model=MeResponse)
def get_me(db: Session = Depends(get_db)) -> MeResponse:
    user = get_or_create_dev_user(db)
    return MeResponse(
        id=user.id,
        email=user.email,
        display_name=user.display_name,
        default_timezone=user.default_timezone,
        mode="development",
    )
