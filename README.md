# Post Manager

A Flutter app for viewing posts and creating, editing, and deleting posts by
title and body.

The app uses JSONPlaceholder (`https://jsonplaceholder.typicode.com`) as a demo
API. JSONPlaceholder simulates create, update, and delete requests but does not
persist changes. The app reflects successful mutations in the current list;
refreshing or restarting reloads the original demo data.

## Search and pagination

On the Posts screen, use the search field and Title/Body selector to filter
posts case-insensitively. Results are paginated by 10 by default; use the page
size selector to show 5, 10, 20, or all matching posts and the previous/next
controls to move between pages. Search and page-size changes return to the
first page.

## Demo accounts

Register and log in locally to enable post creation, editing, and deletion.
Account records and the signed-in session are stored on the device using
SharedPreferences. Passwords are stored as salted hashes. A sample account is
seeded on first launch:

```text
Email: demo@example.com
Password: password123
```

This is demo-only authentication, not production security. The API does not
enforce these user permissions, and the local app cannot provide server-side
authorization.

## Configure the API

Copy `.env.example` to `.env` in the project root, then set `API_BASE_URL` to
your backend URL, including its port, for example:

```env
API_BASE_URL=http://localhost:3000
```

Restart the app after changing `.env` so the new value is loaded. When running
in Chrome, the API server must be reachable from the browser and allow
cross-origin requests from the Flutter web app's origin. The `.env` values are
bundled with the app, so do not put secrets or private credentials in this file.

## Run

```sh
flutter pub get
flutter run
```
