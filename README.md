# Post Manager

A Flutter app for managing posts offline. Posts and local demo accounts are
stored in Hive CE; theme preferences and the current login session use
SharedPreferences. Post CRUD does not require an API or an internet connection.

## Architecture

```text
Presentation screen
  -> Riverpod controller/provider
  -> Domain use case
  -> Domain repository interface
  -> Local repository implementation
  -> Local data source
  -> Hive CE box
```

```text
lib/
├── core/
│   ├── application/        # Shared application controllers
│   ├── presentation/       # Shared widgets and settings UI
│   ├── routing/            # GoRouter routes and auth guards
│   └── storage/            # Hive initialization and app settings storage
└── features/
    ├── auth/
    │   ├── application/    # Authentication state/controller
    │   ├── data/           # Hive account model and local storage
    │   ├── domain/         # Account entity
    │   └── presentation/   # Login, registration, and profile screens
    └── posts/
        ├── application/    # CRUD, search, filter, and pagination providers
        ├── data/           # Hive model, data source, local repository
        ├── domain/         # Post entity, repository contract, use cases
        └── presentation/   # Post list, details, forms, and widgets
```

`AppDatabase` initializes Hive before the app starts, opens separate `posts`,
`accounts`, and `metadata` boxes, registers generated typed adapters, and owns
the schema version. Add new Hive fields with new field numbers and advance the
schema version when stored data needs a migration.

`PostLocalDataSource` is the only post feature layer that reads or writes a Hive
box. `LocalPostRepository` implements the domain contract, and controllers call
domain use cases; presentation widgets never access Hive. The repository
contract can later have a remote or synchronized implementation without
changing the screens or domain use cases.

Post IDs are assigned locally and unique within the posts box. Missing records
produce a `PostNotFoundException`. Create, read, update, and delete changes are
persisted before the Riverpod list/detail state is updated.

Search is case-insensitive across title, body, or both. Pagination supports 5,
10, 20, and All items per page; changing the search, search field, or page size
resets the current page. Theme mode is restored from SharedPreferences.

## Local demo authentication

The demo account is seeded on first launch:

| Email | Password |
|---|---|
| `demo@example.com` | `password123` |

Registration and login are local-only. Account records are stored in their own
Hive box, passwords are stored as salted hashes (never plaintext), and the
active session is restored from SharedPreferences. GoRouter protects the
profile and settings routes, and the app requires login before allowing post
mutations.

This authentication is for demonstration and learning only. Client-side
authentication and a fast local password hash do not provide production-grade
identity verification or secure authorization. A production app needs a
trusted authentication service, a purpose-built server-side password hash, and
server-enforced permissions. Secure storage is intentionally not added because
this app has no tokens or remote credentials.

## Dependencies and generated adapters

Hive models use `hive_ce_generator`. Regenerate adapters after changing model
fields:

```powershell
flutter pub get
dart run build_runner build
```

Keep existing `@HiveField` numbers unchanged; use a new number for every added
field. The committed adapter files and Hive registrar are generated output.

## Run and test

```powershell
flutter run
flutter test
flutter analyze
```

The tests cover the existing navigation and CRUD UI, local Hive repository
operations and persistence, authentication behavior, and search/pagination.
