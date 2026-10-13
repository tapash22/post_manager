# Post Manager

A Flutter app for viewing posts and creating, editing, and deleting posts by
title and body.

The app uses JSONPlaceholder (`https://jsonplaceholder.typicode.com`) as a demo
API. JSONPlaceholder simulates create, update, and delete requests but does not
persist changes. The app reflects successful mutations in the current list;
refreshing or restarting reloads the original demo data.

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
