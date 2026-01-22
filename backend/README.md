# Backend — Booking Lifecycle & Ops Platform

## Overview

This backend implements the core booking lifecycle for an on-demand home services marketplace.
It is designed as a state-driven, role-aware system with strong guarantees around correctness, observability, and operational safety.

The system supports three distinct actors:

- **Customer** — creates and cancels bookings
- **Provider** — executes assigned bookings
- **Admin/System** — manages assignment, recovery, and overrides

The backend is intentionally authoritative: all lifecycle transitions, validations, and invariants are enforced server-side.

## Tech Stack

- **Framework**: FastAPI
- **ORM**: SQLAlchemy
- **Database**: SQLite (dev-friendly, prod-ready with PostgreSQL)
- **Architecture**: Layered (API → Service → Model)
- **State Management**: Explicit finite-state lifecycle
- **Observability**: Event sourcing via BookingEvent
- **Package Manager**: uv (Python 3.13+)

## Architecture

### Directory Structure

```
backend/
├── app/
│   ├── api/              # API route handlers (thin layer)
│   │   ├── bookings.py  # Customer & Admin booking endpoints
│   │   └── providers.py # Provider & Admin provider endpoints
│   ├── core/             # Core infrastructure
│   │   └── database.py  # SQLAlchemy engine & session management
│   ├── models/           # SQLAlchemy ORM models
│   │   ├── booking.py
│   │   ├── booking_event.py
│   │   ├── customer.py
│   │   └── provider.py
│   ├── schemas/          # Pydantic request/response models
│   │   └── booking.py
│   ├── services/         # Business logic layer
│   │   └── booking_service.py  # All booking lifecycle logic
│   └── main.py          # FastAPI app initialization
├── pyproject.toml       # Project dependencies
└── README.md
```

### Layer Responsibilities

**API Layer** (`app/api/`)
- Route definitions and HTTP handling
- Request/response serialization
- Basic role validation (defensive checks)
- Delegates to service layer

**Service Layer** (`app/services/`)
- All business logic
- State transition validation
- RBAC enforcement
- Provider availability checks
- Event creation
- Database transactions

**Model Layer** (`app/models/`)
- SQLAlchemy ORM models
- Database schema definitions
- Relationships and constraints

## Core Domain Concepts

### Booking

A booking represents a single customer request and follows a strict lifecycle:

```
PENDING
  └─> ASSIGNED
        ├─> IN_PROGRESS
        │     └─> COMPLETED
        └─> REJECTED
```

Additional terminal/failure states:

- **CANCELLED** (Customer/Admin)
- **FAILED** (Admin/System)

**Key Invariants:**
- Bookings are never deleted
- All changes are captured as events for auditability
- Status transitions are validated server-side
- COMPLETED bookings cannot be modified

### BookingEvent (Audit Trail)

Every state transition creates a `BookingEvent` containing:

- `from_status` — previous state (None for initial creation)
- `to_status` — new state
- `actor_role` — who performed the action
- `actor_id` — specific actor identifier
- `created_at` — timestamp

This enables:

- Debugging and troubleshooting
- Admin investigation
- Timeline visualization
- Post-incident analysis
- Compliance auditing

### Role-Based Access Control (RBAC)

RBAC is enforced explicitly in service logic, not assumed from the client.

| Role | Capabilities |
|------|-------------|
| **CUSTOMER** | Create booking, cancel own booking |
| **PROVIDER** | View assigned bookings, accept/reject, complete |
| **ADMIN** | Assign providers, force actions, retry, cancel, view history |
| **SYSTEM** | Automated actions (retry, assignment logic) |

Unauthorized actions always return `403 Forbidden`.

### Provider Availability & Safety

**One Active Assignment Rule**

A provider may have at most one active booking at a time.

A provider is considered **BUSY** if they have any booking with status:

- `ASSIGNED`
- `IN_PROGRESS`

This invariant is enforced server-side via `is_provider_busy()`.

Attempting to assign a booking to a BUSY provider returns:

```
403 Forbidden
"Provider is busy"
```

Frontend logic cannot bypass this rule.

## API Endpoints

### Customer APIs

#### Create Booking
```
POST /bookings/
```

Creates a new booking in `PENDING` state.

**Request Body:**
```json
{
  "customer_name": "John Doe",
  "actor_role": "CUSTOMER",
  "actor_id": 1
}
```

**Response:** `BookingResponse`

**Service Method:** `create_booking()`

**Key Logic:**
- Validates actor role is CUSTOMER
- Creates/retrieves customer record
- Initializes booking as PENDING
- Creates initial BookingEvent

---

#### Cancel Booking
```
POST /bookings/{id}/cancel
```

Allowed only for booking owner. Marks booking as `CANCELLED`.

**Request Body:**
```json
{
  "actor_role": "CUSTOMER",
  "actor_id": 1
}
```

**Service Method:** `cancel_booking_by_customer()`

**Key Logic:**
- Validates customer owns the booking
- Prevents cancellation of terminal states (COMPLETED, CANCELLED, etc.)
- Releases provider if assigned
- Creates BookingEvent

---

#### Get Booking Details
```
GET /bookings/{id}
```

Returns current booking snapshot.

**Service Method:** `get_booking_by_id()`

---

#### Get Booking Event Timeline
```
GET /bookings/{id}/events
```

Returns full lifecycle history (ordered chronologically).

**Service Method:** `get_booking_events()`

**Use Case:** Admin investigation, debugging, timeline visualization

---

### Provider APIs

#### View Assigned Bookings
```
GET /providers/{provider_id}/bookings
```

Returns only actionable bookings:

- `ASSIGNED`
- `IN_PROGRESS`

**Explicitly excludes:**
- `REJECTED`
- `COMPLETED`
- `CANCELLED`
- `FAILED`

**Service Method:** `get_assigned_bookings_for_provider()`

**Design Decision:** Providers only see actionable work. Historical/completed bookings are filtered out to reduce noise.

---

#### Accept Booking
```
POST /bookings/{id}/accept
```

Transition: `ASSIGNED → IN_PROGRESS`

**Request Body:**
```json
{
  "actor_role": "PROVIDER",
  "actor_id": 2
}
```

**Service Method:** `provider_accept_booking()`

**Key Logic:**
- Validates booking is ASSIGNED
- Validates provider owns the booking
- Transitions to IN_PROGRESS
- Creates BookingEvent

---

#### Reject Booking
```
POST /bookings/{id}/reject
```

Transition: `ASSIGNED → REJECTED`

**Service Method:** `provider_reject_booking()`

**Key Logic:**
- Validates booking is ASSIGNED
- Validates provider owns the booking
- Releases provider (sets `provider_id` to None)
- Transitions to REJECTED
- Creates BookingEvent

**Note:** Rejected bookings are no longer visible to providers (filtered out).

---

#### Complete Booking
```
POST /bookings/{id}/complete
```

Transition: `IN_PROGRESS → COMPLETED`

**Service Method:** `complete_booking()`

**Key Logic:**
- Validates booking is IN_PROGRESS
- Validates provider owns the booking
- Transitions to COMPLETED
- Creates BookingEvent
- Releases provider (makes them available again)

---

### Admin APIs

#### List Providers (Admin Only)
```
GET /admin/providers?actor_role=ADMIN
```

Returns providers with real-time availability:

**Response:**
```json
[
  {
    "id": 1,
    "name": "Provider A",
    "availability": "BUSY"
  },
  {
    "id": 2,
    "name": "Provider B",
    "availability": "AVAILABLE"
  }
]
```

**Service Method:** `is_provider_busy()` (called per provider)

**Design Decision:** Availability is computed on-demand, not cached, to ensure accuracy.

---

#### Assign Provider
```
POST /bookings/{id}/assign
```

Fails if provider is BUSY. Enforces lifecycle rules.

**Request Body:**
```json
{
  "provider_id": 2,
  "actor_role": "ADMIN",
  "actor_id": 0
}
```

**Service Method:** `assign_provider()`

**Key Logic:**
- Validates role is SYSTEM or ADMIN
- Validates booking is PENDING or REJECTED
- Checks provider availability (must be AVAILABLE)
- Assigns provider
- Transitions to ASSIGNED
- Creates BookingEvent

---

#### Force Assign Provider
```
POST /bookings/{id}/force-assign
```

Admin override. Bypasses availability checks.

**Request Body:**
```json
{
  "provider_id": 2,
  "actor_role": "ADMIN",
  "actor_id": 0
}
```

**Service Method:** `admin_force_assign()`

**Key Logic:**
- Validates role is ADMIN
- Protects COMPLETED bookings (cannot override)
- Bypasses availability check
- Assigns provider
- Transitions to ASSIGNED
- Creates BookingEvent

**Warning:** This can assign a BUSY provider. Use with caution.

---

#### Retry Booking
```
POST /bookings/{id}/retry
```

Allowed only if status is:
- `REJECTED`
- `FAILED`

Resets booking to `PENDING`.

**Request Body:**
```json
{
  "actor_role": "ADMIN",
  "actor_id": 0
}
```

**Service Method:** `retry_booking()`

**Key Logic:**
- Validates role is ADMIN or SYSTEM
- Validates booking is REJECTED or FAILED
- Resets status to PENDING
- Clears provider assignment
- Creates BookingEvent

**Design Decision:** CANCELLED bookings cannot be retried (terminal state).

---

#### Force Cancel Booking
```
POST /bookings/{id}/force-cancel
```

Admin-only cancellation.

**Request Body:**
```json
{
  "actor_role": "ADMIN",
  "actor_id": 0
}
```

**Service Method:** `admin_force_cancel()`

**Key Logic:**
- Validates role is ADMIN
- Protects COMPLETED bookings
- Transitions to CANCELLED
- Releases provider
- Creates BookingEvent

---

#### Mark Booking Failed
```
POST /bookings/{id}/mark-failed
```

Marks booking as `FAILED`.

**Request Body:**
```json
{
  "actor_role": "ADMIN",
  "actor_id": 0
}
```

**Service Method:** `admin_mark_failed()`

**Key Logic:**
- Validates role is ADMIN
- Protects COMPLETED bookings
- Transitions to FAILED
- Releases provider
- Creates BookingEvent

**Use Case:** System errors, provider no-show, etc.

---

## Service Layer Guarantees

The service layer (`app/services/booking_service.py`) enforces:

1. **Valid state transitions** — Only allowed transitions are permitted
2. **Actor ownership validation** — Customers can only cancel their own bookings
3. **Role-based permissions** — Each action checks actor role
4. **Provider availability** — Prevents double-booking
5. **Terminal-state protection** — COMPLETED bookings are immutable
6. **Event creation** — Every state change creates a BookingEvent
7. **Transaction safety** — Database operations are atomic

The API layer is thin; all business logic lives in services.

## Error Handling Philosophy

- **400 Bad Request** — invalid state transition, invalid input
- **403 Forbidden** — RBAC or ownership violation
- **404 Not Found** — invalid entity (booking/provider not found)

Errors are explicit and descriptive. No silent failures.

## Design Principles

1. **Backend-first authority** — All invariants enforced server-side
2. **State-driven logic** — Business rules based on explicit state machine
3. **No destructive deletes** — Bookings are soft-deleted (status changes)
4. **Auditability by default** — Every change creates an event
5. **Defensive programming** — Validate early, fail fast
6. **Clear separation of concerns** — API → Service → Model layers

## Development

### Prerequisites

- Python 3.13+
- [uv](https://github.com/astral-sh/uv) package manager

### Installation

```bash
# Install dependencies
uv sync

# Verify installation
uv run python -c "import fastapi; print('FastAPI installed')"
```

### Run Locally

```bash
# Start development server
uv run uvicorn app.main:app --reload

# Server runs on http://localhost:8000
# API docs available at http://localhost:8000/docs
```

### Database Initialization

Tables are auto-created on startup via SQLAlchemy metadata:

```python
# app/main.py
Base.metadata.create_all(bind=engine)
```

**Note:** In production, use proper migrations (Alembic) instead of `create_all()`.

### Health Check

```bash
curl http://localhost:8000/health
```

Returns: `{"status": "ok"}`

## Key Design Decisions

### 1. Why Event Sourcing?

Every state change creates a `BookingEvent`. This enables:
- **Debugging** — See exactly what happened and when
- **Admin tools** — Timeline visualization for investigation
- **Recovery** — Understand how bookings reached their current state
- **Compliance** — Audit trail for regulatory requirements

### 2. Why Server-Side RBAC?

Frontend clients are treated as untrusted. All role checks happen server-side:
- Prevents API abuse
- Centralized security logic
- Easy to audit and test
- Works even if frontend is compromised

### 3. Why Provider Availability Check?

The "one active assignment" rule prevents:
- Double-booking providers
- Overloading providers
- Scheduling conflicts
- Poor customer experience

This is enforced in `is_provider_busy()` and checked before every assignment.

### 4. Why Terminal State Protection?

`COMPLETED` bookings are immutable:
- Prevents accidental data corruption
- Maintains data integrity
- Clear business rule: completed work cannot be undone

### 5. Why Layered Architecture?

- **API Layer**: HTTP concerns, request/response handling
- **Service Layer**: Business logic, validation, transactions
- **Model Layer**: Data persistence, relationships

This separation makes the codebase:
- Testable (mock services, test logic independently)
- Maintainable (clear responsibilities)
- Scalable (easy to add features)

### 6. Why No Soft Delete?

Bookings are never deleted. Instead:
- Status changes to `CANCELLED` or `FAILED`
- Events preserve full history
- Data remains queryable

This ensures:
- Complete audit trail
- Ability to recover from mistakes
- Historical analysis

## Why This Design Works

- **Mirrors real-world ops systems** — Similar to production platforms (Uber, DoorDash)
- **Supports safe recovery flows** — Retry, force-assign, mark-failed
- **Prevents inconsistent state** — Server-side validation
- **Scales with additional roles** — Easy to add new actors
- **Easy to reason about under failure** — Clear state machine, event log

