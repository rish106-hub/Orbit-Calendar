from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routes.agent import router as agent_router
from app.routes.booking import router as booking_router
from app.routes.calendar import router as calendar_router
from app.routes.me import router as me_router

app = FastAPI(title="Orbit Calendar API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.web_origin],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(me_router, prefix="/api")
app.include_router(calendar_router, prefix="/api")
app.include_router(agent_router, prefix="/api")
app.include_router(booking_router, prefix="/api")


@app.get("/health")
def healthcheck() -> dict[str, str]:
    return {"status": "ok", "service": "orbit-api"}
