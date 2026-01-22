from fastapi import APIRouter, Depends, Body
from sqlalchemy.orm import Session
from typing import List, Optional

from app.core.database import SessionLocal
from app.models.booking_event import ActorRole
from app.schemas.booking import BookingResponse
from app.services import booking_service
from pydantic import BaseModel

router = APIRouter()


# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Request Models (Inline as per plan to avoid schemas clutter/modifications)
class AssignProviderRequest(BaseModel):
    provider_id: int
    actor_role: ActorRole
    actor_id: Optional[int] = None


class ProviderActionRequest(BaseModel):
    actor_role: ActorRole
    actor_id: int


# 1. ASSIGN PROVIDER
@router.post("/bookings/{booking_id}/assign", response_model=BookingResponse)
def assign_provider(
    booking_id: int, request: AssignProviderRequest, db: Session = Depends(get_db)
):
    """
    Assign a provider to a booking.
    Role: SYSTEM or ADMIN.
    """
    return booking_service.assign_provider(
        db,
        booking_id=booking_id,
        provider_id=request.provider_id,
        actor_role=request.actor_role,
    )


# 1.5 ADMIN: GET ALL PROVIDERS
class ProviderDTO(BaseModel):
    id: int
    name: str
    availability: str  # "AVAILABLE" or "BUSY"

    class Config:
        from_attributes = True


@router.get("/admin/providers", response_model=List[ProviderDTO])
def get_all_providers(
    actor_role: ActorRole,  # Passed as query param for simplicity or header if we had auth middleware
    db: Session = Depends(get_db),
):
    """
    Get list of all providers.
    Role: ADMIN ONLY.
    """
    if actor_role != ActorRole.ADMIN:
        from fastapi import HTTPException

        raise HTTPException(status_code=403, detail="Forbidden: Admin access only")

    from app.models.provider import Provider

    providers = db.query(Provider).all()
    results = []
    for p in providers:
        is_busy = booking_service.is_provider_busy(db, p.id)
        results.append(
            ProviderDTO(
                id=p.id,
                name=p.name,
                availability="BUSY" if is_busy else "AVAILABLE",
            )
        )
    return results


# 2. VIEW ASSIGNED BOOKINGS (STRICT FILTER)
@router.get("/providers/{provider_id}/bookings", response_model=List[BookingResponse])
def get_provider_bookings(provider_id: int, db: Session = Depends(get_db)):
    """
    Get bookings assigned to provider.
    STRICT FILTER: Only ASSIGNED and IN_PROGRESS.
    """
    return booking_service.get_assigned_bookings_for_provider(db, provider_id)


# 3. ACCEPT BOOKING
@router.post("/bookings/{booking_id}/accept", response_model=BookingResponse)
def accept_booking(
    booking_id: int, request: ProviderActionRequest, db: Session = Depends(get_db)
):
    """
    Provider accepts an assigned booking.
    Role: PROVIDER.
    """
    # Validation logic is in service layer (checks actor_role implicit context if needed, but here checks constraints)
    # The service layer checks if booking.provider_id == request.actor_id generally
    if request.actor_role != ActorRole.PROVIDER:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=403, detail="Only providers can perform this action"
        )

    # Service layer `provider_accept_booking` takes `actor_id` (provider_id).

    return booking_service.provider_accept_booking(
        db, booking_id=booking_id, actor_id=request.actor_id
    )


# 4. REJECT BOOKING
@router.post("/bookings/{booking_id}/reject", response_model=BookingResponse)
def reject_booking(
    booking_id: int, request: ProviderActionRequest, db: Session = Depends(get_db)
):
    """ """
    if request.actor_role != ActorRole.PROVIDER:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=403, detail="Only providers can perform this action"
        )
    return booking_service.provider_reject_booking(
        db, booking_id=booking_id, actor_id=request.actor_id
    )


# 5. COMPLETE BOOKING
@router.post("/bookings/{booking_id}/complete", response_model=BookingResponse)
def complete_booking(
    booking_id: int, request: ProviderActionRequest, db: Session = Depends(get_db)
):
    """
    Provider completes an IN_PROGRESS booking.
    Role: PROVIDER.
    """
    if request.actor_role != ActorRole.PROVIDER:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=403, detail="Only providers can perform this action"
        )

    return booking_service.complete_booking(
        db, booking_id=booking_id, actor_id=request.actor_id
    )


# 6. FORCE ASSIGN (ADMIN)
@router.post("/bookings/{booking_id}/force-assign", response_model=BookingResponse)
def force_assign_provider(
    booking_id: int, request: AssignProviderRequest, db: Session = Depends(get_db)
):
    """
    Admin forces assignment of a booking to a provider.
    Role: ADMIN.
    """
    if request.actor_role != ActorRole.ADMIN:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=403, detail="Only ADMIN can perform force assignment."
        )

    return booking_service.admin_force_assign(
        db,
        booking_id=booking_id,
        provider_id=request.provider_id,
        actor_id=(
            request.actor_id if request.actor_id else 0
        ),  # Should rely on implicit actor_id if provided or default
        # Plan said AssignProviderRequest. actor_id should be present for ADMIN actions usually.
        # But schema has it as Optional. Let's assume passed.
    )
