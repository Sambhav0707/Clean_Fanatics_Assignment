from fastapi import FastAPI
from app.core.database import engine, Base

# Import models to ensure they are registered with Base.metadata
from app.models.customer import Customer
from app.models.provider import Provider
from app.models.booking import Booking
from app.models.booking_event import BookingEvent

# Create tables on startup (for Phase 1 simplicity, no migrations yet)
Base.metadata.create_all(bind=engine)

app = FastAPI()

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

from app.api import bookings, providers

app.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
app.include_router(providers.router, tags=["providers"])


@app.get("/health")
def health_check():
    """
    Health check endpoint to verify the service is running.
    """
    return {"status": "ok"}
