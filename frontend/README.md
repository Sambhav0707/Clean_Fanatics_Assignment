# Frontend — Booking Lifecycle Mobile App

## Overview

This Flutter mobile application provides a complete booking lifecycle management system for an on-demand home services marketplace. The app supports three distinct user roles: **Customer**, **Provider**, and **Admin**, each with role-specific interfaces and capabilities.

The frontend is built using **Clean Architecture** principles with **BLoC pattern** for state management, ensuring separation of concerns, testability, and maintainability.

## Tech Stack

- **Framework**: Flutter (Dart 3.9.2+)
- **State Management**: flutter_bloc (BLoC pattern)
- **Dependency Injection**: get_it
- **HTTP Client**: http package
- **Architecture**: Clean Architecture (Data → Domain → Presentation)
- **Reactive Programming**: rxdart (for extensions)

## Architecture

### Clean Architecture Layers

The app follows Clean Architecture with three main layers:

```
lib/
├── core/                    # Shared infrastructure
│   ├── bloc/               # BLoC observer
│   ├── constants/          # API endpoints, config
│   ├── di/                 # Dependency injection (get_it)
│   ├── errors/             # Failure classes
│   ├── network/            # API client
│   ├── session/            # Session management
│   └── utils/              # Utilities (Either, extensions)
│
└── features/                # Feature modules
    ├── admin/              # Admin feature
    ├── booking/             # Customer booking feature
    ├── provider/            # Provider feature
    └── role/                # Role selection feature
```

Each feature follows the same structure:

```
feature/
├── data/                   # Data layer
│   ├── datasources/       # Remote/local data sources
│   ├── models/            # Data models (JSON serialization)
│   └── repositories/      # Repository implementations
│
├── domain/                 # Domain layer (business logic)
│   ├── entities/          # Business entities
│   ├── repositories/      # Repository interfaces
│   └── usecases/          # Use cases (business operations)
│
└── presentation/           # Presentation layer (UI)
    ├── bloc/              # BLoC (state management)
    ├── screens/           # UI screens
    └── widgets/           # Reusable widgets
```

### Why Clean Architecture?

1. **Separation of Concerns** — Business logic is independent of UI and data sources
2. **Testability** — Each layer can be tested independently
3. **Maintainability** — Changes in one layer don't affect others
4. **Scalability** — Easy to add new features following the same pattern
5. **Reusability** — Domain logic can be reused across different platforms

## Screenshots

### Application Flow

The app follows a role-based flow where users first select their role, then access role-specific features:

1. **Role Selection** → 2. **Login/Entry** → 3. **Role-Specific Home Screen**

#### 1. Role Selection Screen
![Role Selection Screen](./assets/roll%20selector%20screen.png)

Users start by selecting their role: Customer, Provider, or Admin.

---

#### 2. Login/Entry Screens

**Customer Login:**
![Customer Login View](./assets/customer%20login%20view.png)

**Admin Login:**
![Admin Login View](./assets/admin%20login%20view%20screen.png)

---

#### 3. Role-Specific Home Screens

**Customer Home Screen:**
![Customer Home Screen](./assets/customer%20home%20screen%20view.png)

**Customer Booking View:**
![Customer Booking View](./assets/customer%20booking%20view%20screen.png)

**Provider Home Screen (View 1):**
![Provider Home View](./assets/provider%20home%20view.png)

**Provider Home Screen (View 2):**
![Provider Home View 2](./assets/provider%20home%20view%202.png)

**Admin Panel:**
![Admin Panel Screen](./assets/admin%20panel%20screen.png)

---

## Key Features

### 1. Role Selection & Mock Authentication

The app starts with a role selection screen where users choose their role:

![Role Selection Screen](./assets/roll%20selector%20screen.png)

**Why Mock Login?**

The app uses a **mock authentication system** instead of real OAuth/JWT for the following reasons:

- **Rapid Development** — Focus on core booking functionality without auth complexity
- **Demo/Testing** — Easy to switch between roles for testing different flows
- **Backend Simplicity** — Backend expects `actor_role` and `actor_id` in requests, not tokens
- **Future-Ready** — Architecture supports easy migration to real auth (just replace SessionContext initialization)

**How It Works:**

1. User selects a role (Customer/Provider/Admin)
2. For **Customer**: Enter name (ID auto-generated from timestamp)
3. For **Provider/Admin**: Enter Actor ID (must match backend provider/admin ID)
4. Session is stored in `SessionContext` via dependency injection
5. All API calls include `actor_role` and `actor_id` from session

**Key Files:**
- `lib/core/session/session_context.dart` — Stores current user session
- `lib/features/role/presentation/screens/role_selection_screen.dart` — Role selection UI
- `lib/features/role/presentation/bloc/role_bloc.dart` — Manages role selection state

---

### 2. Customer Features

**Customer Login Screen:**
![Customer Login View](./assets/customer%20login%20view.png)

**Customer Home Screen:**
![Customer Home Screen](./assets/customer%20home%20screen%20view.png)

**Customer Booking View:**
![Customer Booking View](./assets/customer%20booking%20view%20screen.png)

#### Create Booking
- Enter customer name
- Creates booking in `PENDING` status
- Auto-starts polling to track booking status

#### View Bookings
- Lists all customer bookings
- Color-coded status indicators:
  - 🟠 **PENDING** — Waiting for assignment
  - 🔵 **ASSIGNED** — Provider assigned
  - 🟣 **IN_PROGRESS** — Provider working
  - 🟢 **COMPLETED** — Service completed
  - ⚫ **CANCELLED** — Cancelled
  - 🔴 **FAILED** — System error

#### Cancel Booking
- Cancel bookings in `PENDING`, `ASSIGNED`, or `IN_PROGRESS` status
- Confirmation dialog to prevent accidental cancellation

#### Real-Time Updates
- **Automatic polling** every 5 seconds for active bookings
- UI updates silently without showing loaders during polling
- Polls all bookings except `COMPLETED` (to catch status changes from admin actions)

**Key Files:**
- `lib/features/booking/presentation/screens/customer_home_screen.dart` — Customer UI
- `lib/features/booking/presentation/bloc/booking_bloc.dart` — Booking state management
- `lib/features/booking/domain/usecases/create_booking.dart` — Create booking logic

**Design Decision: Why Polling?**

- **Simplicity** — No WebSocket infrastructure needed
- **Reliability** — Works even with intermittent connectivity
- **Backend Compatibility** — Backend is stateless REST API
- **Future-Ready** — Can be replaced with WebSockets/SSE later

---

### 3. Provider Features

**Provider Home Screen - View 1:**
![Provider Home View](./assets/provider%20home%20view.png)

**Provider Home Screen - View 2:**
![Provider Home View 2](./assets/provider%20home%20view%202.png)

#### View Assigned Bookings
- Shows only **actionable bookings** (`ASSIGNED` or `IN_PROGRESS`)
- Filters out completed, rejected, cancelled, and failed bookings
- Real-time updates via polling

#### Accept Booking
- Provider accepts an `ASSIGNED` booking
- Transitions booking to `IN_PROGRESS`
- Provider becomes BUSY (cannot accept other bookings)

#### Reject Booking
- Provider rejects an `ASSIGNED` booking
- Transitions booking to `REJECTED`
- Provider becomes available again
- Booking returns to `PENDING` (can be reassigned)

#### Complete Booking
- Provider completes an `IN_PROGRESS` booking
- Transitions booking to `COMPLETED`
- Provider becomes available again

**Key Files:**
- `lib/features/provider/presentation/screens/provider_home_screen.dart` — Provider UI
- `lib/features/provider/presentation/bloc/provider_bloc.dart` — Provider state management
- `lib/features/provider/domain/usecases/accept_booking.dart` — Accept booking logic

**Design Decision: Why Filter Bookings?**

Providers only see actionable work to:
- **Reduce Noise** — Focus on current tasks
- **Better UX** — Cleaner interface
- **Performance** — Less data to process
- **Clarity** — Clear what needs attention

---

### 4. Admin Features

**Admin Login Screen:**
![Admin Login View](./assets/admin%20login%20view%20screen.png)

**Admin Operations Panel:**
![Admin Panel Screen](./assets/admin%20panel%20screen.png)

#### Search Booking by ID
- Enter booking ID to load booking details
- Shows current status, customer ID, provider ID
- Manual load with loading indicator

#### View Booking Timeline
- Complete event history for a booking
- Shows all state transitions with timestamps
- Useful for debugging and investigation

#### Assign Provider
- Assign a provider to a `PENDING` or `REJECTED` booking
- Checks provider availability (must be AVAILABLE)
- Fails if provider is BUSY

#### Force Assign Provider
- Admin override to assign a BUSY provider
- Bypasses availability checks
- Use with caution (can cause double-booking)

#### Retry Booking
- Retry `REJECTED` or `FAILED` bookings
- Resets booking to `PENDING`
- Clears provider assignment

#### Force Cancel Booking
- Admin-only cancellation
- Can cancel any booking except `COMPLETED`
- Releases provider

#### Mark Booking Failed
- Mark booking as `FAILED` (system errors, no-show, etc.)
- Releases provider

#### Real-Time Polling
- **Silent polling** every 5 seconds for loaded booking
- **No loader during polling** — UI stays stable
- Only updates if booking data actually changed
- Preserves booking card visibility during updates

**Key Files:**
- `lib/features/admin/presentation/screens/admin_home_screen.dart` — Admin UI
- `lib/features/admin/presentation/bloc/admin_bloc.dart` — Admin state management
- `lib/features/admin/presentation/widgets/booking_timeline.dart` — Event timeline widget
- `lib/features/admin/presentation/widgets/provider_selector_modal.dart` — Provider selection modal

**Design Decision: Why Silent Polling?**

Admin polling is silent (no loader) because:
- **Better UX** — No flickering during background updates
- **Professional Feel** — Ops tools should feel responsive
- **Efficiency** — Only emits state if data changed (prevents unnecessary rebuilds)
- **Stability** — UI doesn't disappear during polling

---

## Important File Decisions

### 1. Why BLoC Pattern?

**File**: `lib/features/*/presentation/bloc/*_bloc.dart`

**Decision**: Use BLoC (Business Logic Component) for state management

**Reasons:**
- **Separation** — Business logic separated from UI
- **Testability** — Easy to test business logic without UI
- **Predictability** — State changes are explicit and traceable
- **Reusability** — Same BLoC can be used across multiple widgets
- **Debugging** — `AppBlocObserver` logs all state transitions

**Alternative Considered**: Provider, Riverpod, GetX
**Why BLoC Won**: Industry standard, excellent tooling, clear separation

---

### 2. Why Dependency Injection (get_it)?

**File**: `lib/core/di/service_locator.dart`

**Decision**: Use get_it for dependency injection

**Reasons:**
- **Testability** — Easy to mock dependencies in tests
- **Loose Coupling** — Classes don't create their own dependencies
- **Singleton Management** — Shared instances (API client, repositories)
- **Factory Pattern** — New instances for BLoCs (per screen)
- **Initialization Control** — All dependencies registered at app startup

**Example:**
```dart
// Register singleton (shared instance)
sl.registerLazySingleton(() => ApiClient(sl()));

// Register factory (new instance each time)
sl.registerFactory(() => BookingBloc(...));
```

---

### 3. Why Either<Failure, T> Pattern?

**File**: `lib/core/utils/either.dart`, `lib/core/errors/failures.dart`

**Decision**: Use Either type for error handling

**Reasons:**
- **Type Safety** — Compiler enforces error handling
- **No Exceptions** — Functional error handling (no try-catch needed)
- **Explicit Errors** — Clear error types (ServerFailure, NetworkFailure)
- **Composability** — Easy to chain operations with `fold()`

**Example:**
```dart
result.fold(
  (failure) => emit(ErrorState(failure.message)),
  (booking) => emit(LoadedState(booking)),
);
```

**Future Enhancement**: Currently used in domain layer, can be extended to data layer

---

### 4. Why Repository Pattern?

**File**: `lib/features/*/domain/repositories/*_repository.dart`

**Decision**: Abstract repository interfaces in domain layer

**Reasons:**
- **Abstraction** — Domain doesn't know about HTTP/API
- **Testability** — Easy to mock repositories
- **Flexibility** — Can swap data sources (API → Cache → Local DB)
- **Clean Architecture** — Domain layer independent of data layer

**Structure:**
```
Domain Layer (interface) → Data Layer (implementation) → API Client
```

---

### 5. Why Use Cases?

**File**: `lib/features/*/domain/usecases/*.dart`

**Decision**: Encapsulate business operations in use cases

**Reasons:**
- **Single Responsibility** — Each use case does one thing
- **Reusability** — Same use case can be used in multiple BLoCs
- **Testability** — Easy to test business logic in isolation
- **Documentation** — Use cases document what the app can do

**Example:**
```dart
class CreateBooking {
  final BookingRepository repository;
  CreateBooking(this.repository);
  
  Future<Either<Failure, Booking>> call(...) {
    return repository.createBooking(...);
  }
}
```

---

### 6. Why Polling Instead of WebSockets?

**File**: `lib/features/booking/presentation/bloc/booking_bloc.dart` (line 62)

**Decision**: Use Timer.periodic for polling instead of WebSockets

**Reasons:**
- **Simplicity** — No WebSocket server needed
- **Backend Compatibility** — Backend is REST API (stateless)
- **Reliability** — Works with intermittent connectivity
- **Resource Efficiency** — Lower server load for small user base
- **Future-Ready** — Can migrate to WebSockets later without changing UI

**Polling Strategy:**
- **Customer**: Polls all non-COMPLETED bookings every 5 seconds
- **Admin**: Polls loaded booking every 5 seconds (silent, no loader)
- **Provider**: Polls assigned bookings every 5 seconds

**Optimization**: Only emits state if booking data changed (prevents unnecessary UI rebuilds)

---

### 7. Why SessionContext Instead of Auth Tokens?

**File**: `lib/core/session/session_context.dart`

**Decision**: Store session in memory (SessionContext) instead of JWT tokens

**Reasons:**
- **Mock Authentication** — Simplified for development/demo
- **Backend Compatibility** — Backend expects `actor_role` and `actor_id` in request body
- **No Token Management** — No refresh tokens, expiration handling
- **Easy Testing** — Can switch roles instantly
- **Future-Ready** — Can replace with secure token storage later

**How It Works:**
1. User selects role and enters ID/name
2. `RoleBloc` creates `SessionContext` and registers it in get_it
3. All API calls read `actor_role` and `actor_id` from `SessionContext`
4. Session persists until app restart or role change

**Security Note**: In production, replace with secure token storage (flutter_secure_storage)

---

### 8. Why Separate Data Models and Entities?

**File**: 
- `lib/features/*/data/models/*_model.dart` (data layer)
- `lib/features/*/domain/entities/*.dart` (domain layer)

**Decision**: Separate data models (JSON) from domain entities

**Reasons:**
- **Independence** — Domain doesn't depend on API structure
- **Flexibility** — API can change without affecting domain
- **Mapping** — Transform API response to domain entity
- **Clean Architecture** — Domain layer has no external dependencies

**Example:**
```dart
// Data Model (knows about JSON)
class BookingModel {
  final int bookingId;  // API uses "id"
  Booking toEntity() => Booking(id: bookingId, ...);
}

// Domain Entity (pure business object)
class Booking {
  final int id;
  final String status;
}
```

---

### 9. Why ApiClient Abstraction?

**File**: `lib/core/network/api_client.dart`

**Decision**: Abstract HTTP client instead of using http directly

**Reasons:**
- **Centralized Error Handling** — All API errors handled in one place
- **Base URL Management** — Single source of truth for API endpoint
- **Future Enhancements** — Easy to add retry logic, interceptors, caching
- **Testability** — Easy to mock for testing

**Current Implementation:**
- Throws exceptions on HTTP errors (4xx, 5xx)
- Returns decoded JSON
- Supports GET (List/Map) and POST

**Future Enhancement**: Wrap in Either<Failure, T> for functional error handling

---

### 10. Why Preserve Booking During Polling?

**File**: `lib/features/admin/presentation/screens/admin_home_screen.dart` (line 95)

**Decision**: Store `_lastLoadedBooking` to preserve UI during polling

**Reasons:**
- **No Flickering** — Booking card doesn't disappear during polling
- **Better UX** — Smooth updates without loaders
- **State Preservation** — UI remains stable even if state temporarily changes
- **Professional Feel** — Ops tools should feel responsive

**Implementation:**
```dart
Booking? _lastLoadedBooking; // Preserve during polling

// In builder:
if (state is AdminBookingLoaded) {
  selectedBooking = state.booking;
  _lastLoadedBooking = state.booking; // Update preserved booking
} else if (state is AdminLoading && _lastLoadedBooking != null) {
  selectedBooking = _lastLoadedBooking; // Show preserved booking
}
```

---

## Directory Structure

```
frontend/
├── lib/
│   ├── core/                      # Shared infrastructure
│   │   ├── bloc/
│   │   │   └── app_bloc_observer.dart  # Logs all BLoC events
│   │   ├── constants/
│   │   │   └── api_constants.dart      # API base URL
│   │   ├── di/
│   │   │   └── service_locator.dart    # Dependency injection setup
│   │   ├── errors/
│   │   │   └── failures.dart           # Error types
│   │   ├── network/
│   │   │   └── api_client.dart         # HTTP client abstraction
│   │   ├── session/
│   │   │   ├── actor_role.dart         # Role enum
│   │   │   └── session_context.dart    # Current user session
│   │   └── utils/
│   │       ├── either.dart             # Either type for error handling
│   │       └── rx_extensions.dart      # RxDart extensions
│   │
│   ├── features/                      # Feature modules
│   │   ├── admin/                     # Admin feature
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── admin_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── admin_provider_model.dart
│   │   │   │   │   └── booking_event_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── admin_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── admin_provider.dart
│   │   │   │   │   └── booking_event.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── admin_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── assign_booking.dart
│   │   │   │       ├── force_assign_booking.dart
│   │   │   │       ├── force_cancel_booking.dart
│   │   │   │       ├── get_admin_providers.dart
│   │   │   │       ├── get_booking_events.dart
│   │   │   │       ├── mark_booking_failed.dart
│   │   │   │       └── retry_booking.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── admin_bloc.dart
│   │   │       │   ├── admin_event.dart
│   │   │       │   ├── admin_state.dart
│   │   │       │   ├── booking_events_cubit.dart
│   │   │       │   └── provider_selection_cubit.dart
│   │   │       ├── screens/
│   │   │       │   └── admin_home_screen.dart
│   │   │       └── widgets/
│   │   │           ├── booking_timeline.dart
│   │   │           └── provider_selector_modal.dart
│   │   │
│   │   ├── booking/                   # Customer booking feature
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── booking_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── booking_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── booking_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── booking.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── booking_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── cancel_booking.dart
│   │   │   │       ├── create_booking.dart
│   │   │   │       └── get_booking.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── booking_bloc.dart
│   │   │       │   ├── booking_event.dart
│   │   │       │   └── booking_state.dart
│   │   │       └── screens/
│   │   │           └── customer_home_screen.dart
│   │   │
│   │   ├── provider/                  # Provider feature
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── provider_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── provider_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── repositories/
│   │   │   │   │   └── provider_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── accept_booking.dart
│   │   │   │       ├── complete_booking.dart
│   │   │   │       ├── get_assigned_bookings.dart
│   │   │   │       └── reject_booking.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── provider_bloc.dart
│   │   │       │   ├── provider_event.dart
│   │   │       │   └── provider_state.dart
│   │   │       └── screens/
│   │   │           └── provider_home_screen.dart
│   │   │
│   │   └── role/                      # Role selection feature
│   │       └── presentation/
│   │           ├── bloc/
│   │           │   ├── role_bloc.dart
│   │           │   ├── role_event.dart
│   │           │   └── role_state.dart
│   │           └── screens/
│   │               ├── role_selection_screen.dart
│   │               └── role_home_placeholder.dart
│   │
│   └── main.dart                      # App entry point
│
├── ./assets/                            # Images and screenshots
│   ├── admin login view screen.png
│   ├── admin panel screen.png
│   ├── customer booking view screen.png
│   ├── customer home screen view.png
│   ├── customer login view.png
│   ├── provider home view.png
│   ├── provider home view 2.png
│   └── roll selector screen.png
│
├── pubspec.yaml                       # Dependencies
└── README.md                          # This file
```

## Development

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart 3.9.2 or higher
- Backend server running on `http://127.0.0.1:8000`

### Installation

```bash
# Install dependencies
flutter pub get

# Verify installation
flutter doctor
```

### Run Locally

```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Run on specific device
flutter run -d <device-id>
```

### Configuration

**API Base URL**: Edit `lib/core/constants/api_constants.dart`

```dart
class ApiConstants {
  static const String baseUrl = "http://127.0.0.1:8000"; // ### CHANGE THIS ####
}
```

For Android emulator, use `http://10.0.2.2:8000` instead of `127.0.0.1`.

### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## Key Design Principles

1. **Clean Architecture** — Separation of concerns across layers
2. **BLoC Pattern** — Predictable state management
3. **Dependency Injection** — Loose coupling, easy testing
4. **Repository Pattern** — Abstract data sources
5. **Use Cases** — Encapsulate business logic
6. **Type Safety** — Either pattern for error handling
7. **Reactive Updates** — Polling for real-time data
8. **User Experience** — Silent polling, no flickering

## Future Enhancements

1. **Real Authentication** — Replace mock login with JWT/OAuth
2. **WebSockets** — Replace polling with real-time updates
3. **Offline Support** — Cache data locally, sync when online
4. **Push Notifications** — Notify users of booking status changes
5. **Error Recovery** — Retry failed requests automatically
6. **Analytics** — Track user actions and app performance
7. **Internationalization** — Support multiple languages
8. **Dark Mode** — Theme support

## Troubleshooting

### API Connection Issues

**Problem**: Cannot connect to backend

**Solution**: 
1. Verify backend is running on `http://127.0.0.1:8000`
2. For Android emulator, use `http://10.0.2.2:8000`
3. Check `lib/core/constants/api_constants.dart`

### Polling Not Working

**Problem**: UI doesn't update automatically

**Solution**:
1. Check that booking status is not `COMPLETED` (completed bookings are not polled)
2. Verify backend is returning updated data
3. Check BLoC observer logs for state changes

### Session Lost After Hot Reload

**Problem**: SessionContext is lost after hot reload

**Solution**: This is expected behavior. Restart the app or re-select role.

## Contributing

When adding new features:

1. Follow Clean Architecture structure
2. Create use cases for business logic
3. Use BLoC for state management
4. Add error handling with Either pattern
5. Write unit tests
6. Update this README

## License

This project is part of a booking lifecycle management system assignment.

---

**For questions or issues, refer to code comments marked with `### CHANGE THIS ####` for areas that may need customization.**
