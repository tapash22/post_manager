# Post Manager — Project Guide

This file explains how the application is wired so maintainers can trace a user action from the screen to state, domain logic, data source, and persistence. Keep it aligned with the code when flows change.

## What the app does

Post Manager is a Flutter app with Riverpod state management and GoRouter navigation. Visitors can browse and search posts. A locally stored account can sign in to create, edit, and delete posts. The home screen shows charts derived from the posts currently loaded by the posts provider. Theme preference, account data, and login session are stored locally.

Important current behavior: the active posts provider uses JSONPlaceholder over HTTP. The app also has a Hive-backed local posts repository, but the active provider does not use it. JSONPlaceholder is a demo API; successful writes are not durable server-side data. Do not describe the active posts flow as offline or persistent unless the provider is deliberately switched to local storage or backed by a real API.

## Run and verify

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

The app requires the Flutter/Dart SDK constraints in `pubspec.yaml`. The default demo account is `demo@example.com` with password `password123`. Treat it as a development convenience, not production authentication.

## Startup and app shell

1. `lib/main.dart` calls `WidgetsFlutterBinding.ensureInitialized()` and awaits `AppDatabase.initialize()` before rendering.
2. `ProviderScope` creates the Riverpod container around `MyApp`.
3. `MyApp` creates a `GoRouter` using `createAppRouter`, listens manually to `authProvider`, and refreshes the router when auth state changes. It disposes both the subscription and router.
4. The app uses Material 3 light and dark themes with Roboto and a deep-purple seed. `themeModeProvider` loads the saved theme; until it resolves, the shell uses light mode.
5. `MobileIntroLoader` wraps routed content and displays its intro animation on narrow layouts.

## Navigation and access

Routes and the drawer's primary destinations are declared in `lib/core/routing/app_router.dart`:

| Route | Screen | Access |
| --- | --- | --- |
| `/` | `HomeScreen` | Public |
| `/posts` | `PostsScreen` | Public browsing; mutations require login |
| `/about` | `AboutScreen` | Public |
| `/posts/:postId` | `PostDetailsScreen` | Public |
| `/auth` | `AuthScreen` | Public |
| `/profile` | `ProfileScreen` | Redirects to auth when signed out or auth is not ready |
| `/settings` | `SettingsScreen` | Redirects to auth when signed out or auth is not ready |

All pages use the shared fade/slide transition in `_transitionPage`. Invalid, non-positive post IDs render an invalid-ID message. The router redirect preserves a requested profile/settings destination through the auth `from` query parameter. After successful login, `AuthScreen` handles the return navigation; otherwise auth redirects to home. When changing a protected route, update both its redirect handling and the auth return behavior.

The navigation drawer reads the same `appNavigationDestinations` list as the router. It closes before navigating. Profile and settings are reached from the account menu in `AppBarActions`, not the drawer.

## Authentication flow

Main files: `features/auth/application/auth_provider.dart`, `features/auth/domain`, `features/auth/data`, and `features/auth/presentation`.

1. `AuthController.build()` creates the local repository and starts loading accounts and the saved session. Until loading completes, `AuthState.isReady` is false.
2. `LocalAuthRepository.loadAccounts()` reads Hive accounts. If there are none, it saves the demo account. The account data source can migrate the legacy `post_manager_accounts` JSON value from SharedPreferences into Hive, then removes the legacy key.
3. The current email is stored in SharedPreferences under `post_manager_current_email`; the controller resolves that email to an account to restore a session.
4. `AuthForm` validates input and calls the controller through `AuthScreen`. Registration normalizes the email, checks the name/email/password rules, generates a random salt, and stores the account. Login checks the salted SHA-256 hash and saves the current email. Logout clears that email.
5. Auth state changes refresh GoRouter, so protected routes are redirected as needed. `PostsController` separately checks `authProvider` before every mutation; browsing and details remain public.

Account records are `AuthAccountModel` Hive values; the domain layer uses `AuthAccount`. Keep storage/model conversion in the data layer. Auth here is local-only and is not a server identity system.

## Posts flow

Main files: `features/posts/domain`, `features/posts/data`, `features/posts/application/posts_provider.dart`, and `features/posts/presentation`.

### Active API-backed path

```text
PostsScreen / HomeScreen / PostDetailsScreen
  -> Riverpod postsProvider or postDetailsProvider
  -> GetPosts / GetPost / CreatePost / UpdatePost / DeletePost
  -> PostRepository interface
  -> ApiPostRepository
  -> PostApiDataSource (JSONPlaceholder HTTP client)
```

`postRepositoryProvider` currently constructs `ApiPostRepository`. `PostApiDataSource` owns an `http.Client`, checks response status and shape, and is closed when its provider is disposed. `ApiPostRepository` gets an individual post by fetching the list and finding its ID. Errors are exposed through Riverpod async state or shown by the presentation layer.

`PostsController` owns the loaded list. It supports create, update, and delete, and updates its in-memory state after successful repository calls. Updates/deletes invalidate the relevant detail provider. The controller blocks mutations for guests. `postDetailsProvider` independently loads a single post through `GetPost`.

JSONPlaceholder simulates writes and does not persist them in the remote list. The current controller also only updates its in-memory list after a write; a later refresh loads the remote fixture again. For real persistence, replace the API endpoint/backend or deliberately wire the local repository. Do not assume the unused local provider is a fallback: no automatic API-to-local fallback is implemented.

### Available local path (currently not selected)

`localPostRepositoryProvider` creates `LocalPostRepository` over `PostLocalDataSource`, which stores `PostHiveModel` records in the `posts` Hive box. It has CRUD operations, ID allocation, and not-found errors. To activate it, change the binding for `postRepositoryProvider` in `posts_provider.dart` and review API-specific behavior and tests. The local source is not synchronized with JSONPlaceholder and currently starts empty unless seeded elsewhere.

### Posts list, filters, and UI

- `postsProvider` is an `AsyncNotifierProvider<List<Post>>` that loads posts via `GetPosts`.
- `postsFilterProvider` owns the query, search field, page size, and page. `postsPageProvider` derives the filtered/paginated `PostsPage`; filtering supports title, body, or both. Page-size `-1` means all results.
- `PostsScreen` displays loading/error/data states, refreshes by invalidating `postsProvider`, and provides search, page size, pagination, details navigation, and the mutation dialog.
- A guest can open the list and details but sees a notice instead of edit/delete controls. Form errors and mutation errors are handled at the screen/dialog boundary.
- `Post` is the domain entity. API JSON and Hive records are mapped to/from this entity in their data sources.

## Home charts

`HomeScreen` watches `postsProvider`, so opening home can trigger the same API load as the posts screen. `HomeCharts` derives its chart data from the loaded list; it does not make a separate request or write analytics data.

- The bar chart shows post count grouped by `userId` (labeled `A<id>`).
- The line chart shows cumulative post count across those author IDs sorted numerically. It is a cumulative distribution, not a time-based trend; `Post` has no timestamp field.
- A grouped bar chart compares average title word count and average body word count for each `userId`, using the API's `title` and `body` fields.
- Loading, error, and empty-list states are handled in the home screen/chart component.
- Both charts use `fl_chart`. If post entities or analytics meaning changes, update `home_charts.dart` and its labels/subtitles together.

## Storage and schema

`lib/core/storage/app_database.dart` initializes Hive CE, registers generated adapters, opens `posts`, `accounts`, and `metadata`, and checks schema version 1. Keep the `schemaVersion` and migration steps in sync with any persisted model changes.

- `PostHiveModel` adapter type ID: `0` (`features/posts/data/models/post_hive_model.dart`).
- `AuthAccountModel` adapter type ID: `1` (`features/auth/data/models/auth_account_model.dart`).
- Generated files (`*.g.dart`, `lib/hive_registrar.g.dart`) must be regenerated when annotated Hive models or adapter registration change. Run `dart run build_runner build` with the configured `hive_ce_generator`, then review generated diffs.
- Theme mode and the current session email use SharedPreferences. Legacy accounts are migrated from SharedPreferences to Hive by `AuthAccountLocalDataSource`.

## Settings and shared UI

`AppSettingsStorage` persists theme mode under `post_manager_theme_mode`; `ThemeModeController` exposes it as an async Riverpod notifier. The settings switch and shared `AppBarActions` both call its `toggle()` method and show failures via snack bar.

`AppHeaderBar`, `AppBarActions`, `SmoothStateSwitcher`, and `AppNavigationDrawer` are shared presentation pieces. Prefer reusing them for new routed screens. `AboutScreen` and `HomeScreen` are public navigation destinations; profile/settings are account destinations.

## Where to make common changes

| Change | Start here |
| --- | --- |
| Add or change a route/redirect | `lib/core/routing/app_router.dart` |
| Change screen-level post behavior | `lib/features/posts/presentation/` |
| Change post state, filtering, or provider wiring | `lib/features/posts/application/posts_provider.dart` |
| Change post rules or contracts | `lib/features/posts/domain/` |
| Change API endpoint/JSON handling | `lib/features/posts/data/datasources/post_api_data_source.dart` |
| Change local post persistence | `lib/features/posts/data/datasources/post_local_data_source.dart` and `lib/core/storage/app_database.dart` |
| Change login/register/session rules | `lib/features/auth/application/auth_provider.dart` and `lib/features/auth/data/` |
| Change theme persistence | `lib/core/application/theme_provider.dart` and `lib/core/storage/app_settings_storage.dart` |
| Change home analytics | `lib/features/navigation/presentation/home_charts.dart` |
| Change Hive model fields | Model, schema/migration, generator output, and corresponding tests |

Keep UI widgets focused on rendering and interaction; put app state in Riverpod controllers/providers, contracts in the domain layer, and HTTP/Hive/SharedPreferences details in data sources. Add or update tests beside the affected feature when behavior changes.

## Tests

The `test/` tree covers the app widget, mobile intro loader, theme provider, auth provider, local post repository, and post filtering. When changing a flow, update or add a focused test for its behavior. Use `flutter analyze` for static checks and `flutter test` for the suite.

<!-- cloude-code-toolbox:mcp-skills-awareness-begin -->

### MCP & Skills awareness (Claude Code ToolBox)

_Last synced: 2026-11-21T19:11:11.841Z._

- **Full report:** `.claude/cloude-code-toolbox-mcp-skills-awareness.md` in this workspace (auto-overwritten on each scan). Use it as ground truth for configured servers and skill folders.
- **MCP:** For **live tools** in Claude Code, enable the matching server via `/mcp`. Servers are configured in `~/.claude.json` (user) and `.mcp.json` (project).
- **When the user's task matches a server** (e.g. Confluence work and a **Confluence** / **Atlassian** MCP is listed), **prefer that server id** and plan on tool use—not only file search.
- **Skills:** Folders below contain `SKILL.md`; attach or cite paths in chat when relevant.

#### Workspace MCP

- `d:\Flutter\post_manager\.mcp.json` _(workspace: post_manager)_ — _file missing_

_No active workspace servers in mcp.json._

#### User MCP

- `C:\Users\Tapash Paul\.claude.json` — _no servers defined_

_No user-scoped MCP servers are configured._

#### Project skills

_None found (or no workspace open)._

#### User skills

_None found._

<!-- cloude-code-toolbox:mcp-skills-awareness-end -->
