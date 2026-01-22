# Booking Lifecycle Management System

This project implements a role-driven, state-machine–based booking system for an on-demand home services marketplace.

The goal of the assignment was not just to "build features", but to demonstrate:

- ✅ Correct handling of real-world workflows
- ✅ Clear role separation (Customer, Provider, Admin)
- ✅ Strong backend authority
- ✅ Safe operational controls
- ✅ Clean frontend–backend contract
- ✅ Observability through event history

The system is designed to behave like a production platform, not a demo app.

## Table of Contents

- [High-Level Architecture](#high-level-architecture)
- [How I Approached the Assignment](#how-i-approached-the-assignment)
- [Core Design Decisions](#core-design-decisions)
- [Installation & Setup](#installation--setup)
- [Running the Application](#running-the-application)
- [Project Structure](#project-structure)
- [What Happens If We Scale This System](#what-happens-if-we-scale-this-system)
- [What This Assignment Demonstrates](#what-this-assignment-demonstrates)

## High-Level Architecture

```
                 ┌──────────────┐
                 │   Customer   │
                 │ (Flutter UI) │
                 └──────┬───────┘
                        │
                        ▼
                 ┌──────────────┐
                 │   Provider   │
                 │ (Flutter UI) │
                 └──────┬───────┘
                        │
                        ▼
┌──────────┐     ┌────────────────────┐     ┌──────────────┐
│  Admin   │ ──▶ │   FastAPI Backend  │ ──▶ │   Database   │
│ (Flutter │     │  (State + RBAC +   │     │ (Bookings & │
│   UI)    │     │   Service Layer)   │     │   Events)   │
└──────────┘     └────────────────────┘     └──────────────┘
                         │
                         ▼
                BookingEvent (Audit Log)
```

### System Components

**Backend (FastAPI)**
- State-driven booking lifecycle management
- Role-based access control (RBAC)
- Service layer enforcing business rules
- Event sourcing for observability
- SQLite database (production-ready with PostgreSQL)

**Frontend (Flutter)**
- Clean Architecture with BLoC pattern
- Role-specific UIs (Customer, Provider, Admin)
- Real-time polling for status updates
- Mock authentication for rapid development

## How I Approached the Assignment

I approached this assignment in incremental, hardened phases, similar to how a real product evolves:

1. **Define the core booking lifecycle**
   → Explicit states, valid transitions, no hidden logic

2. **Enforce backend authority early**
   → Frontend is never trusted for permissions or state

3. **Build role-specific flows independently**
   - Customer: create & cancel
   - Provider: accept, reject, complete
   - Admin: assign, recover, override

4. **Add observability instead of shortcuts**
   - Booking events instead of silent state changes
   - Read-only timelines for Admins

5. **Harden edge cases**
   - One active assignment per provider
   - Retry only from valid states
   - No destructive deletes

6. **Reflect backend guarantees in the UI**
   - State-driven buttons
   - Confirmation dialogs for irreversible actions
   - Clear error handling (e.g., provider busy)

This ensured **correctness first, UX second, and scalability third**.

## Core Design Decisions

### 1. State Machine over Flags

Bookings move through explicit states:

```
PENDING → ASSIGNED → IN_PROGRESS → COMPLETED
```

Plus failure/terminal states: `REJECTED`, `CANCELLED`, `FAILED`

**This avoids:**
- Boolean explosions
- Hidden transitions
- Ambiguous UI behavior

### 2. Backend Is the Source of Truth

- All role validation happens server-side
- All lifecycle transitions are enforced in services
- Frontend reacts to backend responses only

**This prevents:**
- UI-based privilege escalation
- Inconsistent state across clients

### 3. One Active Assignment per Provider

A provider can have only one booking in `ASSIGNED` or `IN_PROGRESS` status.

- Enforced in backend
- Exposed to Admin via availability
- Reflected in Provider UI

This mirrors real-world workforce constraints.

### 4. Event-Based Observability

Instead of mutating state silently:
- Every change creates a `BookingEvent`

**Benefits:**
- Debugging
- Admin investigation
- Timeline visualization
- Audit trail

**No booking is ever deleted.**

### 5. Admin as an Ops Tool, Not a Dashboard

Admins:
- Act on specific booking IDs
- Do not browse all bookings
- Use recovery tools deliberately

This mirrors real internal ops tools where actions come from alerts or escalations.

## Installation & Setup

### Prerequisites

**Backend:**
- Python 3.13 or higher
- [uv](https://github.com/astral-sh/uv) package manager

**Frontend:**
- Flutter SDK 3.9.2 or higher
- Dart 3.9.2 or higher

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd Clean_fanatics_assignment
```

### Step 2: Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies using uv
uv sync

# Verify installation
uv run python -c "import fastapi; print('FastAPI installed successfully')"
```

**Expected Output:**
```
FastAPI installed successfully
```

### Step 3: Frontend Setup

```bash
# Navigate to frontend directory (from project root)
cd ../frontend

# Install Flutter dependencies
flutter pub get

# Verify installation
flutter doctor
```

**Expected Output:**
- Flutter SDK installed
- No critical issues

### Step 4: Configure API Endpoint (if needed)

If your backend runs on a different host/port, update the API base URL:

**File:** `frontend/lib/core/constants/api_constants.dart`

```dart
class ApiConstants {
  static const String baseUrl = "http://127.0.0.1:8000"; // Default
  // For Android emulator, use: "http://10.0.2.2:8000"
  // For iOS simulator, use: "http://localhost:8000"
}
```

## Running the Application

### Step 1: Start the Backend Server

**Terminal 1 - Backend:**

```bash
cd backend
uv run uvicorn app.main:app --reload
```

**Expected Output:**
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

**Verify Backend:**
- Open browser: http://localhost:8000/docs
- You should see the FastAPI Swagger documentation
- Health check: http://localhost:8000/health

### Step 2: Start the Flutter App

**Terminal 2 - Frontend:**

```bash
cd frontend
flutter run
```

**Or run on specific device:**
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

**For Android Emulator:**
- Ensure emulator is running
- Update API base URL to `http://10.0.2.2:8000` if needed

**For iOS Simulator:**
- Ensure simulator is running
- API base URL `http://127.0.0.1:8000` should work

**For Physical Device:**
- Connect device via USB or WiFi
- Update API base URL to your machine's IP address (e.g., `http://192.168.1.100:8000`)

### Step 3: Using the Application

1. **Select Role**: Choose Customer, Provider, or Admin
2. **Enter Credentials**:
   - **Customer**: Enter name (ID auto-generated)
   - **Provider/Admin**: Enter Actor ID (must match backend)
3. **Interact**: Use role-specific features

**Example Flow:**
1. Start as **Customer** → Create booking
2. Switch to **Admin** → Assign provider to booking
3. Switch to **Provider** → Accept and complete booking
4. Switch back to **Customer** → See completed status

## Project Structure

```
Clean_fanatics_assignment/
├── backend/                    # FastAPI backend
│   ├── app/
│   │   ├── api/               # API route handlers
│   │   ├── core/              # Database, config
│   │   ├── models/            # SQLAlchemy models
│   │   ├── schemas/           # Pydantic schemas
│   │   ├── services/          # Business logic
│   │   └── main.py            # FastAPI app
│   ├── pyproject.toml          # Dependencies
│   └── README.md              # Backend documentation
│
├── frontend/                   # Flutter mobile app
│   ├── lib/
│   │   ├── core/              # Shared infrastructure
│   │   └── features/          # Feature modules
│   │       ├── admin/         # Admin feature
│   │       ├── booking/       # Customer booking
│   │       ├── provider/      # Provider feature
│   │       └── role/          # Role selection
│   ├── assets/                # Images, screenshots
│   ├── pubspec.yaml           # Flutter dependencies
│   └── README.md              # Frontend documentation
│
└── README.md                   # This file
```

## Detailed Documentation

- **[Backend README](backend/README.md)** - Complete backend architecture, API endpoints, and design decisions
- **[Frontend README](frontend/README.md)** - Complete frontend architecture, features, and implementation details

## What Happens If We Scale This System

If this system were to scale, the following changes would be natural:

### Backend Scaling

- **Database**: Replace SQLite with PostgreSQL
- **Indexing**: Add proper indexes on:
  - `booking.status`
  - `provider_id`
  - `customer_id`
  - `created_at` (for time-based queries)
- **Background Workers**: Introduce Celery / RQ for:
  - Auto-retry failed bookings
  - Timeout handling
  - Scheduled tasks
- **Service Split**: Separate into microservices:
  - Booking Service
  - Provider Service
  - Ops Service
  - Notification Service

### Frontend Scaling

- **Real-Time Updates**: Replace polling with WebSockets for:
  - Provider updates
  - Admin dashboards
  - Customer notifications
- **Pagination**: Add pagination for:
  - Admin booking history
  - Customer booking list
  - Provider assignment history
- **Authentication**: Introduce proper authentication:
  - JWT tokens
  - OAuth integration
  - Secure token storage
- **Offline Support**: Add local caching and sync

### Platform Enhancements

- **SLA Tracking**: Monitor booking completion times
- **Provider Performance**: Track metrics (acceptance rate, completion time)
- **Alerting**: Notify on stuck bookings, provider availability
- **Multi-Provider Assignment**: Support team-based assignments
- **Geo-Based Selection**: Assign providers based on location
- **Feature Flags**: Control force actions, experimental features

**The current architecture does not block any of this.**

## What This Assignment Demonstrates

✅ **Systems thinking, not just CRUD**
- State machines, event sourcing, observability

✅ **Comfort with backend authority**
- Server-side validation, RBAC enforcement

✅ **Realistic ops and recovery flows**
- Retry, force-assign, mark-failed

✅ **Clean separation of concerns**
- Clean Architecture, layered design

✅ **Defensive engineering mindset**
- Edge case handling, error recovery

✅ **Ability to reason about failure modes**
- What happens when provider is busy?
- What if booking gets stuck?
- How do we recover from errors?

## Troubleshooting

### Backend Issues

**Problem**: `uv: command not found`
```bash
# Install uv
pip install uv
# Or on macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Problem**: Port 8000 already in use
```bash
# Kill process on port 8000
# Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# macOS/Linux:
lsof -ti:8000 | xargs kill -9
```

**Problem**: Database errors
```bash
# Delete and recreate database
cd backend
rm sql_app.db
uv run uvicorn app.main:app --reload
```

### Frontend Issues

**Problem**: Cannot connect to backend
- Verify backend is running on `http://127.0.0.1:8000`
- Check `frontend/lib/core/constants/api_constants.dart`
- For Android emulator, use `http://10.0.2.2:8000`
- For physical device, use your machine's IP address

**Problem**: Flutter dependencies not installing
```bash
flutter clean
flutter pub get
```

**Problem**: Images not showing in README
- Ensure `assets/` folder exists in `frontend/` directory
- Image paths are relative to README location

## Development Workflow

1. **Start Backend**: `cd backend && uv run uvicorn app.main:app --reload`
2. **Start Frontend**: `cd frontend && flutter run`
3. **Make Changes**: Backend auto-reloads, Flutter hot-reloads
4. **Test Flow**: Switch between roles to test different scenarios

## Testing Scenarios

### Customer Flow
1. Create booking → Status: PENDING
2. Wait for assignment → Status: ASSIGNED
3. Provider accepts → Status: IN_PROGRESS
4. Provider completes → Status: COMPLETED

### Provider Flow
1. View assigned bookings (only ASSIGNED/IN_PROGRESS)
2. Accept booking → Status: IN_PROGRESS
3. Complete booking → Status: COMPLETED, Provider available

### Admin Flow
1. Search booking by ID
2. View booking timeline (all events)
3. Assign provider (checks availability)
4. Force assign (bypasses availability)
5. Retry failed/rejected bookings
6. Force cancel or mark failed

## License

This project is part of a booking lifecycle management system assignment.

---

**For detailed documentation:**
- [Backend Documentation](backend/README.md)
- [Frontend Documentation](frontend/README.md)

**Questions?** Refer to code comments marked with `### CHANGE THIS ####` for areas that may need customization.
