from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.deps import get_db, get_or_create_dev_user
from app.schemas.agent import AgentExecuteRequest, AgentQueryRequest, AgentQueryResponse
from app.services import agent_service, calendar_service

router = APIRouter(prefix="/agent", tags=["agent"])


@router.post("/query", response_model=AgentQueryResponse)
def query_agent(payload: AgentQueryRequest, db: Session = Depends(get_db)) -> AgentQueryResponse:
    user = get_or_create_dev_user(db)
    return agent_service.handle_query(db, user, payload.text)


@router.post("/execute")
def execute_action(payload: AgentExecuteRequest, db: Session = Depends(get_db)) -> dict:
    user = get_or_create_dev_user(db)

    if payload.tool_name == "calendar_create_event":
        event = calendar_service.create_event(
            db,
            user,
            title=payload.arguments["title"],
            start=datetime.fromisoformat(payload.arguments["start"]),
            end=datetime.fromisoformat(payload.arguments["end"]),
            description=payload.arguments.get("description"),
            location=payload.arguments.get("location"),
        )
        return {"success": True, "event_id": event.google_event_id}

    if payload.tool_name == "calendar_move_event":
        event = calendar_service.move_event(
            db,
            user,
            event_id=payload.arguments["event_id"],
            new_start=datetime.fromisoformat(payload.arguments["new_start"]),
            new_end=datetime.fromisoformat(payload.arguments["new_end"]),
        )
        if event is None:
            raise HTTPException(status_code=404, detail="Event not found")
        return {"success": True, "event_id": event.google_event_id}

    raise HTTPException(status_code=400, detail="Unsupported tool action")
