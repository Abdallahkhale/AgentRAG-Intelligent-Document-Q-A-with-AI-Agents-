# GroundedLens Flutter client

This Flutter application is the web client for GroundedLens. It lets a user upload supported documents, see the current document list, and ask questions against the retrieval backend.

## Responsibilities

- Select one or more PDF, DOCX, TXT, CSV, or Markdown files.
- Upload document bytes to `POST /upload-file/`.
- Send questions to `POST /query` and display the returned answer.
- Keep the client API endpoint configurable per environment.

## Run locally

From this directory:

```bash
flutter pub get
flutter run -d chrome --dart-define=AGENTRAG_API_URL=http://localhost:5027
```

The backend URL is read in `lib/core/config/app_config.dart`. For a staging or tunnel endpoint, provide a different `AGENTRAG_API_URL` value at run time. Do not add credentials or temporary tunnel URLs to source control.

## Build for the web

```bash
flutter build web --release --dart-define=AGENTRAG_API_URL=https://your-api.example.com
```

The client expects the backend to allow the deployed web origin through CORS. The current backend notebook is configured for demonstration and should be hardened before public deployment.

## Code map

```text
lib/
├── core/config/app_config.dart  # Runtime API configuration
└── main.dart                    # Material app, chat state, upload/query UI
```

The UI is intentionally kept small for this prototype. The next refactor should extract an API client, document model, chat state, and reusable widgets as the feature grows.
