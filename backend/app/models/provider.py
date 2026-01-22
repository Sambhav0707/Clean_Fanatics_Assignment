from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin


class Provider(Base, TimestampMixin):
    __tablename__ = "providers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)

    # Relationship to bookings
    bookings = relationship("Booking", back_populates="provider")
