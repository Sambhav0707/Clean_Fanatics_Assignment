from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.models.booking import Booking, BookingStatus
from app.models.customer import Customer
from app.models.booking_event import BookingEvent, ActorRole
from app.models.provider import Provider
from app.schemas.booking import CreateBookingRequest


def create_booking(db: Session, request: CreateBookingRequest) -> Booking:
    """
    Creates a new booking for a customer.
    Simulates identity by checking/creating the customer based on actor_id.
    """
    # 1. Validate Role
    if request.actor_role != ActorRole.CUSTOMER:
        raise HTTPException(
            status_code=403, detail="Only customers can create bookings."
        )

    # 2. Simulate Identity (Customer Lookup / Creation)
    # in a real app, this would come from an Auth token
    customer = db.query(Customer).filter(Customer.id == request.actor_id).first()
    if not customer:
        customer = Customer(id=request.actor_id, name=request.customer_name)
        db.add(customer)
        # Flush to ensure customer exists in simulation before booking references it
        # (Though we provided ID manually so it's fine, but good practice)
        db.flush()

    # 3. Create Booking (PENDING state)
    new_booking = Booking(
        customer_id=customer.id,
        status=BookingStatus.PENDING,
        provider_id=None,  # No provider assigned yet
    )
    db.add(new_booking)
    db.flush()  # Flush to generate booking.id for the event

    # 4. Create Booking Event (Observability)
    # Log the initial state transition (NULL -> PENDING)
    event = BookingEvent(
        booking_id=new_booking.id,
        from_status=None,
        to_status=BookingStatus.PENDING,
        actor_role=ActorRole.CUSTOMER,
        actor_id=customer.id,
    )
    db.add(event)

    # 5. Commit Transaction
    db.commit()
    db.refresh(new_booking)
    return new_booking


def get_booking_by_id(db: Session, booking_id: int) -> Booking:
    """
    Fetches a booking by ID. Raises 404 if not found.
    """
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


def get_booking_events(db: Session, booking_id: int) -> list[BookingEvent]:
    """
    Fetches all events for a booking, ordered by creation time.
    """
    # Verify booking exists first
    get_booking_by_id(db, booking_id)

    # Return events ordered by oldest first
    return (
        db.query(BookingEvent)
        .filter(BookingEvent.booking_id == booking_id)
        .order_by(BookingEvent.created_at.asc())
        .all()
    )


def assign_provider(
    db: Session, booking_id: int, provider_id: int, actor_role: ActorRole
) -> Booking:
    """
    Assigns a provider to a booking.
    Enforces role (SYSTEM/ADMIN) and provider availability.
    """
    # 1. Validate Role
    if actor_role not in [ActorRole.SYSTEM, ActorRole.ADMIN]:
        raise HTTPException(
            status_code=403, detail="Only SYSTEM or ADMIN can assign providers."
        )

    # 2. Fetch Booking and validate status
    booking = get_booking_by_id(db, booking_id)
    if booking.status not in [BookingStatus.PENDING, BookingStatus.REJECTED]:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot assign booking in status {booking.status}. Must be PENDING or REJECTED.",
        )

    # 3. Fetch Provider (Simulate existence/check)
    # Note: Provider needs to exist in DB. We assume checking valid ID logic here or trust existence.
    provider = db.query(Provider).filter(Provider.id == provider_id).first()
    # Explicitly raise 404 as per refinement requirements
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")

    # 4. Check Provider Availability (BUSY check)
    busy_booking = (
        db.query(Booking)
        .filter(
            Booking.provider_id == provider_id,
            Booking.status.in_([BookingStatus.ASSIGNED, BookingStatus.IN_PROGRESS]),
        )
        .first()
    )
    if busy_booking:
        raise HTTPException(
            status_code=403, detail="Provider is currently BUSY with another booking."
        )

    # 5. Assign Provider & Update Status
    previous_status = booking.status
    booking.provider_id = provider_id
    booking.status = BookingStatus.ASSIGNED

    # 6. Log Event
    event = BookingEvent(
        booking_id=booking.id,
        from_status=previous_status,
        to_status=BookingStatus.ASSIGNED,
        actor_role=actor_role,
        actor_id=None,  # SYSTEM/ADMIN might not have ID in this context
    )
    db.add(event)

    db.commit()
    db.refresh(booking)
    return booking


def get_assigned_bookings_for_provider(db: Session, provider_id: int) -> list[Booking]:
    """
    Returns bookings assigned to a specific provider.
    No state changes.
    """
    return (
        db.query(Booking)
        .filter(Booking.provider_id == provider_id)
        .filter(Booking.status.in_([BookingStatus.ASSIGNED, BookingStatus.IN_PROGRESS]))
        .all()
    )


def provider_accept_booking(db: Session, booking_id: int, actor_id: int) -> Booking:
    """
    Provider accepts an assigned booking.
    """
    booking = get_booking_by_id(db, booking_id)

    # Validate: Status and Ownership
    if booking.status != BookingStatus.ASSIGNED:
        raise HTTPException(
            status_code=400, detail="Booking must be ASSIGNED to accept."
        )
    if booking.provider_id != actor_id:
        raise HTTPException(
            status_code=403, detail="Booking is not assigned to this provider."
        )

    previous_status = booking.status
    booking.status = BookingStatus.IN_PROGRESS

    # Log Event
    event = BookingEvent(
        booking_id=booking.id,
        from_status=previous_status,
        to_status=BookingStatus.IN_PROGRESS,
        actor_role=ActorRole.PROVIDER,
        actor_id=actor_id,
    )
    db.add(event)

    db.commit()
    db.refresh(booking)
    return booking


def provider_reject_booking(db: Session, booking_id: int, actor_id: int) -> Booking:
    """
    Provider rejects an assigned booking.
    """
    booking = get_booking_by_id(db, booking_id)

    # Validate: Status and Ownership
    if booking.status != BookingStatus.ASSIGNED:
        raise HTTPException(
            status_code=400, detail="Booking must be ASSIGNED to reject."
        )
    if booking.provider_id != actor_id:
        raise HTTPException(
            status_code=403, detail="Booking is not assigned to this provider."
        )

    previous_status = booking.status
    booking.status = BookingStatus.REJECTED
    booking.provider_id = None  # Provide is un-assigned on rejection

    # Log Event
    event = BookingEvent(
        booking_id=booking.id,
        from_status=previous_status,
        to_status=BookingStatus.REJECTED,
        actor_role=ActorRole.PROVIDER,
        actor_id=actor_id,
    )
    db.add(event)

    db.commit()
    db.refresh(booking)
    return booking


def complete_booking(db: Session, booking_id: int, actor_id: int) -> Booking:
    """
    Provider completes an IN_PROGRESS booking.
    """
    booking = get_booking_by_id(db, booking_id)

    # Validate: Status and Ownership
    if booking.status != BookingStatus.IN_PROGRESS:
        raise HTTPException(
            status_code=400, detail="Booking must be IN_PROGRESS to complete."
        )
    if booking.provider_id != actor_id:
        raise HTTPException(
            status_code=403, detail="Booking is not assigned to this provider."
        )

    previous_status = booking.status
    booking.status = BookingStatus.COMPLETED

    # Log Event
    event = BookingEvent(
        booking_id=booking.id,
        from_status=previous_status,
        to_status=BookingStatus.COMPLETED,
        actor_role=ActorRole.PROVIDER,
        actor_id=actor_id,
    )
    db.add(event)

    db.commit()
    db.refresh(booking)
    return booking


def cancel_booking_by_customer(db: Session, booking_id: int, actor_id: int) -> Booking:
    """
    Customer cancels a booking.
    """
    booking = get_booking_by_id(db, booking_id)

    # Validate: Ownership
    if booking.customer_id != actor_id:
        raise HTTPException(
            status_code=403,
            detail="Only the customer who created the booking can cancel it.",
        )

    # Validate: Status
    if booking.status in [
        BookingStatus.COMPLETED,
        BookingStatus.CANCELLED,
        BookingStatus.REJECTED,
        BookingStatus.FAILED,
    ]:
        raise HTTPException(
            status_code=400, detail="Cannot cancel a booking in a terminal state."
        )

    previous_status = booking.status
    booking.status = BookingStatus.CANCELLED

    # Release provider (if any)
    booking.provider_id = None

    # Log Event
    event = BookingEvent(
        booking_id=booking.id,
        from_status=previous_status,
        to_status=BookingStatus.CANCELLED,
        actor_role=ActorRole.CUSTOMER,
        actor_id=actor_id,
    )
    db.add(event)

    db.commit()
    db.refresh(booking)
    return booking


def cancel_booking_by_admin(
    db: Session, booking_id: int, actor_id: int, reason: str = None
) -> Booking:
    """
    Admin cancels a booking forcefully.
    """
    booking = get_booking_by_id(db, booking_id)

    # Validate: Status (Terminal check)
    if booking.status in [
        BookingStatus.COMPLETED,
        BookingStatus.CANCELLED,
        BookingStatus.REJECTED,
        BookingStatus.FAILED,
    ]:
        raise HTTPException(
            status_code=400, detail="Cannot cancel a booking in a terminal state."
        )

    previous_status = booking.status
    booking.status = BookingStatus.CANCELLED

    # Release provider (if any)
    booking.provider_id = None

    # Log Event
    event = BookingEvent(
        booking_id=booking.id,
        from_status=previous_status,
        to_status=BookingStatus.CANCELLED,
        actor_role=ActorRole.ADMIN,
        actor_id=actor_id,
    )
    db.add(event)

    db.commit()
    db.refresh(booking)
    return booking


def retry_booking(
    db: Session, booking_id: int, actor_role: ActorRole, actor_id: int
) -> Booking:
    """
    Retry a failed or rejected booking. Resets to PENDING.
    Role: ADMIN or SYSTEM.
    """
    # 1. Validate Role
    if actor_role not in [ActorRole.ADMIN, ActorRole.SYSTEM]:
        raise HTTPException(
            status_code=403, detail="Only ADMIN or SYSTEM can retry bookings."
        )

    booking = get_booking_by_id(db, booking_id)

    # 2. Validate Status
    # [FIX] STRICT: Only REJECTED or FAILED bookings can be retried.
    # CANCELLED is terminal and cannot be retried.
    if booking.status not in [BookingStatus.REJECTED, BookingStatus.FAILED]:
        raise HTTPException(
            status_code=400, detail="Only REJECTED or FAILED bookings can be retried."
        )

    previous_status = booking.status
    booking.status = BookingStatus.PENDING
    booking.provider_id = None  # Reset provider

    # Log Event
    event = BookingEvent(
        booking_id=booking.id,
        from_status=previous_status,
        to_status=BookingStatus.PENDING,
        actor_role=actor_role,
        actor_id=actor_id,
    )
    db.add(event)

    db.commit()
    db.refresh(booking)
    return booking


def admin_force_assign(
    db: Session, booking_id: int, provider_id: int, actor_id: int
) -> Booking:
    """
    Admin forces assignment of a booking to a provider.
    Bypasses availability checks. DANGEROUS.
    """
    booking = get_booking_by_id(db, booking_id)

    # [FIX] Protect COMPLETED bookings from override
    if booking.status == BookingStatus.COMPLETED:
        raise HTTPException(
            status_code=400, detail="Completed bookings cannot be overridden."
        )

    # Validate Provider existence
    provider = db.query(Provider).filter(Provider.id == provider_id).first()
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")

    previous_status = booking.status
    booking.status = BookingStatus.ASSIGNED
    booking.provider_id = provider_id

    # Log Event
    event = BookingEvent(
        booking_id=booking.id,
        from_status=previous_status,
        to_status=BookingStatus.ASSIGNED,
        actor_role=ActorRole.ADMIN,
        actor_id=actor_id,
    )
    db.add(event)

    db.commit()
    db.refresh(booking)
    return booking


def admin_force_cancel(db: Session, booking_id: int, actor_id: int) -> Booking:
    """
    Admin forces cancellation of a booking.
    """
    booking = get_booking_by_id(db, booking_id)

    # [FIX] Protect COMPLETED bookings from override
    if booking.status == BookingStatus.COMPLETED:
        raise HTTPException(
            status_code=400, detail="Completed bookings cannot be overridden."
        )

    previous_status = booking.status
    booking.status = BookingStatus.CANCELLED

    booking.provider_id = None

    # Log Event
    event = BookingEvent(
        booking_id=booking.id,
        from_status=previous_status,
        to_status=BookingStatus.CANCELLED,
        actor_role=ActorRole.ADMIN,
        actor_id=actor_id,
    )
    db.add(event)

    db.commit()
    db.refresh(booking)
    return booking


def admin_mark_failed(db: Session, booking_id: int, actor_id: int) -> Booking:
    """
    Admin marks a booking as FAILED.
    """
    booking = get_booking_by_id(db, booking_id)

    # [FIX] Protect COMPLETED bookings from override
    if booking.status == BookingStatus.COMPLETED:
        raise HTTPException(
            status_code=400, detail="Completed bookings cannot be overridden."
        )

    previous_status = booking.status
    booking.status = BookingStatus.FAILED
    booking.provider_id = None

    # Log Event
    event = BookingEvent(
        booking_id=booking.id,
        from_status=previous_status,
        to_status=BookingStatus.FAILED,
        actor_role=ActorRole.ADMIN,
        actor_id=actor_id,
    )
    db.add(event)

    db.commit()
    db.refresh(booking)
    return booking


def is_provider_busy(db: Session, provider_id: int) -> bool:
    """
    Checks if a provider is currently BUSY (has ASSIGNED or IN_PROGRESS booking).
    """
    busy_booking = (
        db.query(Booking)
        .filter(
            Booking.provider_id == provider_id,
            Booking.status.in_([BookingStatus.ASSIGNED, BookingStatus.IN_PROGRESS]),
        )
        .first()
    )
    return busy_booking is not None
