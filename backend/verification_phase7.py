import requests
import json
import random

BASE_URL = "http://127.0.0.1:8000"
ADMIN_ROLE = "ADMIN"
PROVIDER_ROLE = "PROVIDER"
CUSTOMER_ROLE = "CUSTOMER"


def test_admin_provider_list():
    print("--- Testing /admin/providers ---")

    # 1. Admin Access -> Should Succeed
    try:
        response = requests.get(
            f"{BASE_URL}/admin/providers", params={"actor_role": ADMIN_ROLE}
        )
        if response.status_code == 200:
            print(
                f"✅ Admin Access Successful. Providers count: {len(response.json())}"
            )
        else:
            print(f"❌ Admin Access Failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Admin Access Error: {e}")

    # 2. Provider Access -> Should Fail
    response = requests.get(
        f"{BASE_URL}/admin/providers", params={"actor_role": PROVIDER_ROLE}
    )
    if response.status_code == 403:
        print("✅ Provider Access Restricted (403)")
    else:
        print(f"❌ Provider Access Check Failed: Got {response.status_code}")

    # 3. Customer Access -> Should Fail
    response = requests.get(
        f"{BASE_URL}/admin/providers", params={"actor_role": CUSTOMER_ROLE}
    )
    if response.status_code == 403:
        print("✅ Customer Access Restricted (403)")
    else:
        print(f"❌ Customer Access Check Failed: Got {response.status_code}")


def test_provider_booking_visibility():
    print("\n--- Testing Provider Booking Visibility (Strict) ---")
    provider_id = 999
    customer_id = 888

    # Create dummy provider (simulated by assigning to ID 999)
    # Bookings setup

    # 1. PENDING booking (Should NOT be visible)
    # Create booking
    req = {
        "customer_name": "Test Customer",
        "actor_role": CUSTOMER_ROLE,
        "actor_id": customer_id,
    }
    resp = requests.post(f"{BASE_URL}/bookings/create", json=req)
    if resp.status_code != 200:
        print("❌ Setup Failed: Could not create booking")
        return
    pending_booking_id = resp.json()["id"]

    # 2. ASSIGNED booking (Should BE visible)
    resp = requests.post(f"{BASE_URL}/bookings/create", json=req)
    assigned_booking_id = resp.json()["id"]
    # Assign (Requires Admin)
    # Need to assume provider exists? Since simulation, maybe not enforced strictly for 'assign' call if provider availability check is bypassed or if we can inject provider?
    # Our 'assign_provider' checks for Provider existence in DB: "provider = db.query(Provider)... if not provider: 404"
    # So we need a real provider. Let's use the Admin List endpoint to find one!

    admin_resp = requests.get(
        f"{BASE_URL}/admin/providers", params={"actor_role": ADMIN_ROLE}
    )
    providers = admin_resp.json()
    if not providers:
        print("❌ No providers found in DB to test assignment with.")
        return

    active_provider = providers[0]
    provider_id = active_provider["id"]
    print(f"Using Provider ID: {provider_id}")

    # Assign
    assign_req = {
        "provider_id": provider_id,
        "actor_role": ADMIN_ROLE,
        "actor_id": 900,  # Admin ID
    }
    requests.post(f"{BASE_URL}/bookings/{assigned_booking_id}/assign", json=assign_req)

    # 3. REJECTED booking (Should NOT be visible)
    resp = requests.post(f"{BASE_URL}/bookings/create", json=req)
    rejected_booking_id = resp.json()["id"]
    requests.post(f"{BASE_URL}/bookings/{rejected_booking_id}/assign", json=assign_req)
    # Reject
    reject_req = {"actor_role": PROVIDER_ROLE, "actor_id": provider_id}
    requests.post(f"{BASE_URL}/bookings/{rejected_booking_id}/reject", json=reject_req)

    # 4. IN_PROGRESS booking (Should BE visible)
    resp = requests.post(f"{BASE_URL}/bookings/create", json=req)
    inprogress_booking_id = resp.json()["id"]
    requests.post(
        f"{BASE_URL}/bookings/{inprogress_booking_id}/assign", json=assign_req
    )
    # Accept
    accept_req = {"actor_role": PROVIDER_ROLE, "actor_id": provider_id}
    requests.post(
        f"{BASE_URL}/bookings/{inprogress_booking_id}/accept", json=accept_req
    )

    # 5. COMPLETED booking (Should NOT be visible)
    resp = requests.post(f"{BASE_URL}/bookings/create", json=req)
    completed_booking_id = resp.json()["id"]
    requests.post(f"{BASE_URL}/bookings/{completed_booking_id}/assign", json=assign_req)
    requests.post(f"{BASE_URL}/bookings/{completed_booking_id}/accept", json=accept_req)
    # Complete
    requests.post(
        f"{BASE_URL}/bookings/{completed_booking_id}/complete", json=accept_req
    )

    # CHECK VISIBILITY
    print("Checking visibility...")
    resp = requests.get(f"{BASE_URL}/providers/{provider_id}/bookings", params={})
    if resp.status_code != 200:
        print(f"❌ Failed to get provider bookings: {resp.status_code}")
        return

    visible_bookings = resp.json()
    visible_ids = [b["id"] for b in visible_bookings]

    # VALIDATION
    passed = True

    if assigned_booking_id in visible_ids:
        print(f"✅ ASSIGNED booking ({assigned_booking_id}) is visible.")
    else:
        print(f"❌ ASSIGNED booking ({assigned_booking_id}) is NOT visible.")
        passed = False

    if inprogress_booking_id in visible_ids:
        print(f"✅ IN_PROGRESS booking ({inprogress_booking_id}) is visible.")
    else:
        print(f"❌ IN_PROGRESS booking ({inprogress_booking_id}) is NOT visible.")
        passed = False

    if pending_booking_id in visible_ids:
        print(f"❌ PENDING booking ({pending_booking_id}) is visible (Should NOT be).")
        passed = False
    else:
        print(f"✅ PENDING booking ({pending_booking_id}) is correctly hidden.")

    if rejected_booking_id in visible_ids:
        print(
            f"❌ REJECTED booking ({rejected_booking_id}) is visible (Should NOT be)."
        )
        passed = False
    else:
        print(f"✅ REJECTED booking ({rejected_booking_id}) is correctly hidden.")

    if completed_booking_id in visible_ids:
        print(
            f"❌ COMPLETED booking ({completed_booking_id}) is visible (Should NOT be)."
        )
        passed = False
    else:
        print(f"✅ COMPLETED booking ({completed_booking_id}) is correctly hidden.")

    if passed:
        print("🎉 All Visibility Rules PASSED.")
    else:
        print("⚠️ Some rules FAILED.")


if __name__ == "__main__":
    try:
        test_admin_provider_list()
        test_provider_booking_visibility()
    except Exception as e:
        print(f"Test Execution Error: {e}")
