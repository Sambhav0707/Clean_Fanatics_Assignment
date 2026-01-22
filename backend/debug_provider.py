import requests
import sys

BASE_URL = "http://127.0.0.1:8000"
ADMIN_ROLE = "ADMIN"
PROVIDER_ROLE = "PROVIDER"
CUSTOMER_ROLE = "CUSTOMER"


def debug_provider_flow():
    print("--- Debugging Provider Flow ---")

    # 1. Access Admin to find a provider
    print("1. Find Provider...")
    resp = requests.get(
        f"{BASE_URL}/admin/providers", params={"actor_role": ADMIN_ROLE}
    )
    if resp.status_code != 200:
        print(f"FAILED to get providers: {resp.text}")
        return
    providers = resp.json()
    if not providers:
        print("No providers found.")
        return
    provider_id = providers[0]["id"]
    print(f"Using Provider ID: {provider_id}")

    # 2. Create Booking
    print("2. Create Booking...")
    req = {
        "customer_name": "Debug Customer",
        "actor_role": CUSTOMER_ROLE,
        "actor_id": 777,
    }
    resp = requests.post(f"{BASE_URL}/bookings/create", json=req)
    if resp.status_code != 200:
        print(f"FAILED to create booking: {resp.text}")
        return
    booking_id = resp.json()["id"]
    print(f"Booking ID: {booking_id}")

    # 3. Assign
    print(f"3. Assign Booking {booking_id} to Provider {provider_id}...")
    assign_req = {"provider_id": provider_id, "actor_role": ADMIN_ROLE, "actor_id": 999}
    resp = requests.post(f"{BASE_URL}/bookings/{booking_id}/assign", json=assign_req)
    if resp.status_code != 200:
        print(f"FAILED to assign: {resp.text}")
        return

    # 4. Check Visibility (Should be ASSIGNED)
    print("4. Check Visibility (ASSIGNED)...")
    resp = requests.get(f"{BASE_URL}/providers/{provider_id}/bookings")
    bookings = resp.json()
    found = any(b["id"] == booking_id for b in bookings)
    print(f"Booking found in list? {found}")
    if not found:
        print(f"CRITICAL: Booking not seen after assignment. Bookings: {bookings}")
        return

    # 5. Accept
    print("5. Accept Booking...")
    accept_req = {"actor_role": PROVIDER_ROLE, "actor_id": provider_id}
    resp = requests.post(f"{BASE_URL}/bookings/{booking_id}/accept", json=accept_req)
    if resp.status_code != 200:
        print(f"FAILED to accept: {resp.text}")
        return
    print(f"Accept Response Status: {resp.json()['status']}")

    # 6. Check Visibility (Should be IN_PROGRESS)
    print("6. Check Visibility (IN_PROGRESS)...")
    resp = requests.get(f"{BASE_URL}/providers/{provider_id}/bookings")
    bookings = resp.json()
    found = False
    for b in bookings:
        if b["id"] == booking_id:
            print(f"-> Found booking {b['id']} with status: {b['status']}")
            found = True
            break

    if found:
        print("✅ SUCCESS: Booking is visible after Accept.")
    else:
        print("❌ FAILURE: Booking DISAPPEARED after Accept.")
        print("Full list returned:", bookings)


if __name__ == "__main__":
    debug_provider_flow()
