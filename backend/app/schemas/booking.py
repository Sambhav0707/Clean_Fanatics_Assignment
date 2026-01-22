from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel
from app.models.booking import BookingStatus
from app.models.booking_event import ActorRole


class CreateBookingRequest(BaseModel):
    customer_name: str
    actor_role: ActorRole
    actor_id: int


class BookingEventResponse(BaseModel):
    id: int
    booking_id: int
    from_status: Optional[BookingStatus]
    to_status: BookingStatus
    actor_role: ActorRole
    actor_id: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True


class BookingResponse(BaseModel):
    id: int
    status: BookingStatus
    customer_id: int
    provider_id: Optional[int]
    events: List[BookingEventResponse] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
