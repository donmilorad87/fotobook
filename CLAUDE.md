# CLAUDE.md

This file provides comprehensive guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Full Specification

See [.plan/SPECIFICATION.md](.plan/SPECIFICATION.md) for the original project specification.
See [README.md](README.md) for architecture diagrams and deployment documentation.

---

## Project Overview

**Fotobook** is a professional photo selection platform for photographers with two components:

| Component | Technology | Purpose |
|-----------|------------|---------|
| Web Application | Laravel 12 + PHP 8.3 + PostgreSQL | Server, dashboard, public galleries, API |
| Desktop Application | Flutter 3.24 + Dart + SQLite | Local gallery management, order processing |

**Key Design Decisions:**
- Server-side rendering (Blade templates) — NO SPA, NO Inertia, NO React/Vue
- Pure SCSS for styling — NO Tailwind, NO CSS frameworks
- Vanilla ES6 JavaScript — NO jQuery, minimal dependencies
- Google Drive integration is placeholder (returns mock URLs)
- Original filenames are the key for matching orders to local files

---

## Web Application Architecture

### Directory Structure (`/web`)

```
web/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── Auth/
│   │   │   │   ├── LoginController.php      # Email/password login
│   │   │   │   ├── RegisterController.php   # User registration
│   │   │   │   └── GoogleAuthController.php # OAuth placeholder
│   │   │   ├── Api/
│   │   │   │   ├── AuthController.php       # POST /api/auth/login
│   │   │   │   ├── GalleryController.php    # POST /api/galleries
│   │   │   │   └── OrderController.php      # GET /api/orders
│   │   │   ├── DashboardController.php      # Stats overview
│   │   │   ├── GalleryController.php        # Gallery CRUD
│   │   │   ├── OrderController.php          # Order view + export
│   │   │   ├── ProfileController.php        # User profile
│   │   │   ├── DownloadController.php       # Desktop app download page
│   │   │   └── PublicGalleryController.php  # Public gallery + selection
│   │   └── Middleware/
│   │       ├── EnsureGoogleConnected.php    # Redirects if no Google
│   │       └── ApiTokenAuth.php             # Bearer token validation
│   │
│   ├── Models/
│   │   ├── User.php      # Has google tokens, api_token, galleries
│   │   ├── Gallery.php   # Auto-generates unique slug, has pictures/orders
│   │   ├── Picture.php   # Stores original_filename, google_drive_url
│   │   └── Order.php     # selected_picture_ids (JSON), export methods
│   │
│   ├── Policies/
│   │   ├── GalleryPolicy.php   # User owns gallery
│   │   └── OrderPolicy.php     # User owns order's gallery
│   │
│   └── Services/
│       ├── GoogleDriveService.php  # PLACEHOLDER - returns mock URLs
│       └── GalleryService.php      # Orchestrates gallery creation
│
├── database/migrations/
│   ├── xxxx_create_users_table.php
│   ├── xxxx_create_galleries_table.php
│   ├── xxxx_create_pictures_table.php
│   ├── xxxx_create_orders_table.php
│   └── xxxx_add_google_fields_to_users_table.php
│
├── resources/
│   ├── css/
│   │   ├── app.scss           # Main entry, imports all partials
│   │   ├── _variables.scss    # $primary: #2563eb, $gray-*, etc.
│   │   ├── _mixins.scss       # @mixin respond-to, button-base, etc.
│   │   ├── _base.scss         # Reset, typography, utilities
│   │   ├── layouts/           # _app.scss, _auth.scss, _public.scss
│   │   ├── components/        # _header, _sidebar, _gallery-grid, _lightbox
│   │   └── pages/             # _dashboard, _galleries, _orders, _profile
│   │
│   ├── js/
│   │   ├── app.js                 # Flash messages, sidebar toggle
│   │   ├── gallery-selection.js   # Photo selection + submit modal
│   │   └── lightbox.js            # Full-screen image viewer
│   │
│   └── views/
│       ├── layouts/
│       │   ├── app.blade.php      # Authenticated (sidebar + header)
│       │   ├── auth.blade.php     # Login/register (centered card)
│       │   └── public.blade.php   # Public gallery (minimal header)
│       └── [feature folders]/
│
└── routes/
    ├── web.php   # Browser routes (session auth)
    └── api.php   # Desktop API (token auth)
```

### Database Schema (PostgreSQL)

```sql
users
├── id BIGSERIAL PRIMARY KEY
├── name VARCHAR(255)
├── email VARCHAR(255) UNIQUE
├── password VARCHAR(255)
├── google_access_token TEXT (nullable)
├── google_refresh_token TEXT (nullable)
├── google_token_expires_at TIMESTAMP (nullable)
├── api_token VARCHAR(64) UNIQUE (SHA256 hashed)
└── timestamps

galleries
├── id BIGSERIAL PRIMARY KEY
├── user_id BIGINT → users(id) CASCADE
├── name VARCHAR(255)
├── slug VARCHAR(255) UNIQUE (auto-generated: name-random6)
└── timestamps

pictures
├── id BIGSERIAL PRIMARY KEY
├── gallery_id BIGINT → galleries(id) CASCADE
├── original_filename VARCHAR(255) *** KEY FOR MATCHING ***
├── google_drive_url TEXT
├── google_drive_file_id VARCHAR(255)
├── order_index INTEGER DEFAULT 0
└── timestamps

orders
├── id BIGSERIAL PRIMARY KEY
├── gallery_id BIGINT → galleries(id) CASCADE
├── client_name VARCHAR(255)
├── client_email VARCHAR(255)
├── selected_picture_ids JSONB (array of picture IDs)
└── timestamps
```

### Routes

**Web Routes (session auth):**
```
Guest:
  GET  /login                    → LoginController@showLoginForm
  POST /login                    → LoginController@login
  GET  /register                 → RegisterController@showRegistrationForm
  POST /register                 → RegisterController@register

Public:
  GET  /gallery/{slug}           → PublicGalleryController@show
  POST /gallery/{slug}/order     → PublicGalleryController@submitSelection

Authenticated + Google Connected:
  GET  /dashboard                → DashboardController@index
  GET  /galleries                → GalleryController@index
  GET  /galleries/{gallery}      → GalleryController@show
  DELETE /galleries/{gallery}    → GalleryController@destroy
  GET  /orders                   → OrderController@index
  GET  /orders/{order}           → OrderController@show
  GET  /orders/{order}/export    → OrderController@export (JSON download)
  GET  /profile                  → ProfileController@edit
  PUT  /profile                  → ProfileController@update
  GET  /download                 → DownloadController@index
```

**API Routes (Bearer token auth):**
```
POST /api/auth/login
  Request: { email, password }
  Response: { token, user: { id, name, email } }

POST /api/galleries (multipart/form-data)
  Request: name, images[]
  Response: { gallery_id, slug, pictures: [...] }

GET /api/orders
  Response: { orders: [{ order_id, gallery_name, client_name, selected_pictures: [...] }] }
```

---

## Desktop Application Architecture

### Directory Structure (`/desktop`)

```
desktop/
├── lib/
│   ├── main.dart              # Entry, DI setup, provider registration
│   ├── app.dart               # MaterialApp, theme, router
│   │
│   ├── database/
│   │   ├── database_service.dart     # SQLite init, migrations, repos
│   │   └── repositories/
│   │       ├── user_repository.dart      # Single user session
│   │       ├── gallery_repository.dart   # Local galleries CRUD
│   │       └── picture_repository.dart   # Pictures metadata
│   │
│   ├── models/
│   │   ├── user.dart          # id, email, name, token
│   │   ├── gallery.dart       # Local gallery with folder_path
│   │   ├── picture.dart       # Local picture with file_path
│   │   └── order.dart         # Parsed from JSON export
│   │
│   ├── services/
│   │   ├── api_service.dart       # HTTP client, error handling
│   │   ├── auth_service.dart      # Login, logout, session restore
│   │   ├── file_service.dart      # Folder picker, image scanner
│   │   ├── image_service.dart     # Resize 1920x1080, compress
│   │   ├── gallery_service.dart   # Import, submit, delete
│   │   └── order_service.dart     # Load JSON, match files, ZIP
│   │
│   ├── state/
│   │   └── app_state.dart     # ChangeNotifier, global state
│   │
│   └── screens/
│       ├── login_screen.dart          # Email/password form
│       ├── galleries_screen.dart      # Sidebar + gallery list
│       ├── gallery_detail_screen.dart # Pictures grid, upload
│       ├── import_gallery_screen.dart # Folder picker, preview
│       └── process_order_screen.dart  # JSON → match → ZIP
│
└── pubspec.yaml               # Dependencies
```

### Database Schema (SQLite)

```sql
users (single user session)
├── id INTEGER PRIMARY KEY (from web)
├── email TEXT UNIQUE
├── name TEXT
├── token TEXT (API token from web)
└── timestamps (TEXT ISO8601)

galleries (local galleries)
├── id INTEGER PRIMARY KEY AUTOINCREMENT
├── user_id INTEGER → users(id)
├── name TEXT
├── folder_path TEXT (original folder location)
├── picture_count INTEGER
├── submitted_at TEXT (null = local only)
├── web_gallery_id INTEGER (after upload)
├── web_slug TEXT (after upload)
└── timestamps

pictures (local picture metadata)
├── id INTEGER PRIMARY KEY AUTOINCREMENT
├── gallery_id INTEGER → galleries(id)
├── file_path TEXT (full path to original)
├── file_name TEXT *** KEY FOR MATCHING ***
├── file_size INTEGER
├── width INTEGER
├── height INTEGER
├── web_picture_id INTEGER (after upload)
└── created_at TEXT
```

### Key Services

**GalleryService:**
- `importGallery()` - Scans folder, creates DB entries with image metadata
- `submitGallery()` - Compresses images, uploads via API, marks as submitted
- `deleteGallery()` - **ONLY deletes from database, NEVER from disk**

**OrderService:**
- `loadOrderFromJson()` - Parses exported order JSON
- `matchOrderToGallery()` - Matches filenames to local pictures
- `createZipFromOrder()` - Creates ZIP archive of matched files

---

## Docker Infrastructure

### Services (docker-compose.yml)

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `postgres` | postgres:16-alpine | 5432 | Database |
| `redis` | redis:7-alpine | 6379 | Cache, sessions, queues |
| `app` | Custom PHP-FPM | 9000 | Laravel application |
| `nginx` | nginx:alpine | 8000 | Web server |
| `queue` | Same as app | - | Queue worker |
| `node` | node:20-alpine | 5173 | Vite dev server (dev profile) |

### Docker Commands

```bash
# Start production
docker compose up -d

# Start with Vite dev server
docker compose --profile dev up -d

# Run migrations
docker compose exec app php artisan migrate

# Run artisan commands
docker compose exec app php artisan <command>

# View logs
docker compose logs -f app

# Build desktop app (Linux)
cd desktop && docker build --target artifact --output type=local,dest=./dist .
```

---

## Development Commands

### Web Application

```bash
cd web

# Install dependencies
composer install
npm install

# Database
php artisan migrate
php artisan migrate:fresh --seed

# Development
php artisan serve          # PHP server on :8000
npm run dev                # Vite dev server on :5173

# Production build
npm run build

# Testing
php artisan test
php artisan test --filter=FeatureName
php artisan test --coverage

# Code quality
./vendor/bin/pint          # Laravel Pint (PSR-12)
```

### Desktop Application

```bash
cd desktop

# Dependencies
flutter pub get

# Run
flutter run -d linux       # or -d windows, -d macos

# Build
flutter build linux --release
flutter build windows --release
flutter build macos --release

# Testing
flutter test
flutter test --coverage
```

---

## Critical Implementation Details

### Filename Matching
The `original_filename` (web) and `file_name` (desktop) are the KEY for matching orders to local files. These must be preserved exactly during upload.

### Image Compression
Desktop compresses to max 1920×1080 at 75% JPEG quality before upload. Original files remain untouched on disk.

### Gallery Slug Generation
Auto-generated from name + 6 random characters: `"Wedding 2024"` → `"wedding-2024-abc123"`

### API Token Security
- Tokens are generated as 32 random bytes (64 hex chars)
- Stored as SHA256 hash in database
- Validated by comparing hash of incoming token

### Order JSON Format
```json
{
  "order_id": 1,
  "gallery_name": "Wedding 2024",
  "client_name": "Jane Smith",
  "client_email": "jane@example.com",
  "selected_pictures": [
    {"filename": "IMG_001.jpg"},
    {"filename": "IMG_042.jpg"}
  ],
  "created_at": "2024-01-15T10:30:00Z"
}
```

### Desktop Delete Safety
**CRITICAL: The desktop app NEVER deletes actual files from disk.** The `deleteGallery()` method only removes database entries. This is by design to protect photographers' original photos.

---

## Common Tasks

### Adding a New Web Route

1. Create controller in `app/Http/Controllers/`
2. Add route in `routes/web.php` or `routes/api.php`
3. Create view in `resources/views/`
4. Add SCSS in appropriate file

### Adding a New Desktop Screen

1. Create screen in `lib/screens/`
2. Add navigation from existing screen
3. Update `AppState` if new state needed

### Adding a New Database Field

**Web:**
```bash
php artisan make:migration add_field_to_table
# Edit migration
php artisan migrate
```

**Desktop:**
Update `_onCreate` in `database_service.dart` and increment `_version`

---

## Testing Strategy

### Web Tests

- Feature tests for controllers
- Unit tests for services
- API tests for desktop endpoints

### Desktop Tests

- Unit tests for services
- Unit tests for models
- Widget tests for screens

---

## Environment Variables

### Web (.env)

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=http://localhost:8000

DB_CONNECTION=pgsql
DB_HOST=postgres
DB_DATABASE=fotobook
DB_USERNAME=fotobook
DB_PASSWORD=secret

GOOGLE_CLIENT_ID=your_id
GOOGLE_CLIENT_SECRET=your_secret
GOOGLE_REDIRECT_URI=http://localhost:8000/google/callback
```

### Docker (.env in root)

```env
DB_DATABASE=fotobook
DB_USERNAME=fotobook
DB_PASSWORD=your_secure_password
WEB_PORT=8000
```
