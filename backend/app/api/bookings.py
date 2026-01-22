from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.core.database import SessionLocal
from app.schemas.booking import (
    CreateBookingRequest,
    BookingResponse,
    BookingEventResponse,
)
from app.services import booking_service

router = APIRouter()


# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/", response_model=BookingResponse)
def create_booking(request: CreateBookingRequest, db: Session = Depends(get_db)):
    """
    Create a new booking as a customer.
    """
    return booking_service.create_booking(db, request)


@router.get("/{booking_id}", response_model=BookingResponse)
def get_booking(booking_id: int, db: Session = Depends(get_db)):
    """
    Get booking details by ID.
    """
    return booking_service.get_booking_by_id(db, booking_id)


@router.get("/{booking_id}/events", response_model=List[BookingEventResponse])
def get_booking_events(booking_id: int, db: Session = Depends(get_db)):
    """
    Get all state change events for a specific booking.
    """
    return booking_service.get_booking_events(db, booking_id)


# Request Models for Cancellation (Inline to avoid schema churn)
from pydantic import BaseModel
from app.models.booking_event import ActorRole
from typing import Optional


class CustomerCancelRequest(BaseModel):
    actor_role: ActorRole
    actor_id: int


class AdminCancelRequest(BaseModel):
    actor_role: ActorRole
    actor_id: int
    reason: str


@router.post("/{booking_id}/cancel", response_model=BookingResponse)
def cancel_booking(
    booking_id: int, request: CustomerCancelRequest, db: Session = Depends(get_db)
):
    """
    Customer cancels a booking.
    """
    # Explicit Role Check
    if request.actor_role != ActorRole.CUSTOMER:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=403,
            detail="Only customers can perform this action via this endpoint.",
        )

    return booking_service.cancel_booking_by_customer(
        db, booking_id=booking_id, actor_id=request.actor_id
    )


@router.post("/{booking_id}/cancel/admin", response_model=BookingResponse)
def cancel_booking_admin(
    booking_id: int, request: AdminCancelRequest, db: Session = Depends(get_db)
):
    """
    Admin cancels a booking.
    """
    # Explicit Role Check
    if request.actor_role != ActorRole.ADMIN:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=403, detail="Only admins can perform this action."
        )

    return booking_service.cancel_booking_by_admin(
        db, booking_id=booking_id, actor_id=request.actor_id, reason=request.reason
    )


# Phase 6: Recovery Endpoints


class RetryRequest(BaseModel):
    actor_role: ActorRole
    actor_id: int


class AdminActionRequest(BaseModel):
    actor_role: ActorRole
    actor_id: int


@router.post("/{booking_id}/retry", response_model=BookingResponse)
def retry_booking(
    booking_id: int, request: RetryRequest, db: Session = Depends(get_db)
):
    """
    Retry a failed/rejected booking.
    """
    # Role Check handled in service but good to have here too
    if request.actor_role not in [ActorRole.ADMIN, ActorRole.SYSTEM]:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=403, detail="Only ADMIN or SYSTEM can retry bookings."
        )

    return booking_service.retry_booking(
        db,
        booking_id=booking_id,
        actor_role=request.actor_role,
        actor_id=request.actor_id,
    )


@router.post("/{booking_id}/force-cancel", response_model=BookingResponse)
def force_cancel_booking(
    booking_id: int, request: AdminActionRequest, db: Session = Depends(get_db)
):
    """
    Admin forces cancellation.
    """
    if request.actor_role != ActorRole.ADMIN:
        from fastapi import HTTPException

        raise HTTPException(status_code=403, detail="Only ADMIN can force cancel.")

    return booking_service.admin_force_cancel(
        db, booking_id=booking_id, actor_id=request.actor_id
    )


@router.post("/{booking_id}/mark-failed", response_model=BookingResponse)
def mark_booking_failed(
    booking_id: int, request: AdminActionRequest, db: Session = Depends(get_db)
):
    """
    Admin marks booking as FAILED.
    """
    if request.actor_role != ActorRole.ADMIN:
        from fastapi import HTTPException

        raise HTTPException(status_code=403, detail="Only ADMIN can mark failed.")

    return booking_service.admin_mark_failed(
        db, booking_id=booking_id, actor_id=request.actor_id
    )
