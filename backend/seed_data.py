from app.core.database import SessionLocal, engine, Base
from app.models.provider import Provider
from app.models.booking import Booking  # Needed for relationship resolution
from app.models.customer import Customer  # Good practice to have all models loaded
from app.models.booking_event import (
    BookingEvent,
)  # Needed for Booking relationship resolution


def seed_providers():
    db = SessionLocal()
    try:
        # Create tables if they don't exist (just in case)
        Base.metadata.create_all(bind=engine)

        providers_to_create = [
            {"id": 10, "name": "Provider A"},
            {"id": 20, "name": "Provider B"},
            {"id": 30, "name": "Provider C"},
            {"id": 50, "name": "Provider Busy"},
            {"id": 99, "name": "Provider Z"},
        ]

        print("Seeding Providers...")
        for p_data in providers_to_create:
            existing = db.query(Provider).filter(Provider.id == p_data["id"]).first()
            if not existing:
                provider = Provider(id=p_data["id"], name=p_data["name"])
                db.add(provider)
                print(f"Created Provider: {p_data['name']} (ID: {p_data['id']})")
            else:
                print(f"Provider already exists: {p_data['name']} (ID: {p_data['id']})")

        db.commit()
        print("✅ Seeding Complete!")

    except Exception as e:
        print(f"❌ Error seeding data: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_providers()
