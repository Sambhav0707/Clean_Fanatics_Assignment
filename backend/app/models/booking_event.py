import enum
from sqlalchemy import Column, Integer, ForeignKey, Enum, String
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin
from app.models.booking import BookingStatus


class ActorRole(str, enum.Enum):
    CUSTOMER = "CUSTOMER"
    PROVIDER = "PROVIDER"
    ADMIN = "ADMIN"
    SYSTEM = "SYSTEM"


class BookingEvent(Base, TimestampMixin):
    __tablename__ = "booking_events"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)

    from_status = Column(Enum(BookingStatus), nullable=True)
    to_status = Column(Enum(BookingStatus), nullable=False)

    actor_role = Column(Enum(ActorRole), nullable=False)
    actor_id = Column(
        Integer, nullable=True
    )  # Nullable because SYSTEM or ADMIN might not have an ID in this context yet

    # Relationship
    booking = relationship("Booking", back_populates="events")
