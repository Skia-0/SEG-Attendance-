from app import create_app
from app.extensions import db
from app.models import Hub, Cohort, Coordinator

app = create_app()

def seed_data():
    with app.app_context():
        # Ensure all tables exist
        db.create_all()

        # Seed Hub
        hub = Hub.query.filter_by(name="Accra Central Hub").first()
        if not hub:
            hub = Hub(name="Accra Central Hub", location="Accra, Ghana")
            db.session.add(hub)
            db.session.commit()
            print(f"Created Hub: '{hub.name}' with ID: {hub.hub_id}")
        else:
            print(f"Existing Hub Found: '{hub.name}' with ID: {hub.hub_id}")

        # Seed Cohort
        cohort = Cohort.query.filter_by(name="Poultry Management", hub_id=hub.hub_id).first()
        if not cohort:
            cohort = Cohort(
                name="Poultry Management",
                hub_id=hub.hub_id,
                min_attendance_percent=80
            )
            db.session.add(cohort)
            db.session.commit()
            print(f"Created Cohort: '{cohort.name}' with ID: {cohort.cohort_id}")
        else:
            print(f"Existing Cohort Found: '{cohort.name}' with ID: {cohort.cohort_id}")

        # Seed Coordinator
        coordinator = Coordinator.query.filter_by(phone="0200000001").first()
        if not coordinator:
            coordinator = Coordinator(
                full_name="Test Coordinator",
                phone="0200000001",
                hub_id=hub.hub_id
            )
            coordinator.set_password("password123")
            db.session.add(coordinator)
            db.session.commit()
            print(f"Created Coordinator: '{coordinator.full_name}' with ID: {coordinator.coordinator_id}")
        else:
            print(f"Existing Coordinator Found: '{coordinator.full_name}' with ID: {coordinator.coordinator_id}")

        print("\nSeeding successfully completed!")
        print(f"Use Phone: {coordinator.phone if coordinator else '0200000001'} and Password: password123 to log in.")

if __name__ == "__main__":
    seed_data()
