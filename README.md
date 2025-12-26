# Fotobook

A professional photo selection platform for photographers. Fotobook enables photographers to share galleries with clients, collect their photo selections, and process orders efficiently.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [API Documentation](#api-documentation)
- [Getting Started](#getting-started)
- [Docker Deployment](#docker-deployment)
- [Development Guide](#development-guide)
- [Testing](#testing)
- [Security Considerations](#security-considerations)

---

## Overview

Fotobook consists of two main components:

### 1. Web Application (Laravel)
A server-side rendered web application for:
- Photographer authentication and account management
- Dashboard with galleries and orders overview
- Public gallery pages for client photo selection
- Order management and JSON export
- Google Drive integration (placeholder)

### 2. Desktop Application (Flutter)
A cross-platform desktop application (Windows, macOS, Linux) for:
- Importing local photo folders as galleries
- Compressing and uploading photos to the web server
- Processing client orders (matching JSON to local files)
- Creating ZIP archives of selected photos

### Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PHOTOGRAPHER WORKFLOW                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Desktop App                    Web Server                   Client        │
│   ───────────                    ──────────                   ──────        │
│                                                                             │
│   1. Import folder ─────────────────────────────────────────────────────>   │
│      with photos                                                            │
│                                                                             │
│   2. Upload gallery ─────────────> Store photos                             │
│      (compressed)                  Generate public URL                      │
│                                                                             │
│   3. Share URL ─────────────────────────────────────────────> View gallery  │
│                                                               Select photos │
│                                                               Submit order  │
│                                                                             │
│   4. ───────────────────────────── Order received <────────────────────────│
│                                    with selections                          │
│                                                                             │
│   5. Export order JSON <─────────                                           │
│                                                                             │
│   6. Process order ─────────────────────────────────────────────────────>   │
│      (match files,                                                          │
│       create ZIP)                                                           │
│                                                                             │
│   7. Deliver photos ────────────────────────────────────────> Receive ZIP   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INFRASTRUCTURE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         Docker Compose                               │   │
│  │                                                                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │   │
│  │  │  Nginx   │  │ PHP-FPM  │  │ Postgres │  │  Redis   │            │   │
│  │  │  :8000   │──│  :9000   │──│  :5432   │  │  :6379   │            │   │
│  │  │          │  │ (Laravel)│  │          │  │          │            │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘            │   │
│  │                     │                                                │   │
│  │                     │ Queue Worker                                   │   │
│  │                     └──────────────────────────────────────────────  │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Desktop Application                              │   │
│  │                                                                      │   │
│  │  ┌──────────────────────────────────────────────────────────────┐   │   │
│  │  │                    Flutter Desktop App                        │   │   │
│  │  │                                                               │   │   │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │   │
│  │  │  │ Services │  │  State   │  │   UI     │  │  SQLite  │     │   │   │
│  │  │  │          │──│ Manager  │──│ Screens  │  │ Database │     │   │   │
│  │  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │   │   │
│  │  │       │                                                       │   │   │
│  │  │       │ HTTP/REST                                             │   │   │
│  │  │       ▼                                                       │   │   │
│  │  │  ┌──────────┐                                                 │   │   │
│  │  │  │ Web API  │─────────────────────────────────────────────────│───│───┤
│  │  │  └──────────┘                                                 │   │   │
│  │  └──────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Web Application Architecture (Laravel)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LARAVEL APPLICATION                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Routes                                                                     │
│  ──────                                                                     │
│  ├── web.php (Browser routes with sessions)                                 │
│  │   ├── /login, /register (Guest)                                         │
│  │   ├── /dashboard, /galleries, /orders, /profile (Auth + Google)         │
│  │   └── /gallery/{slug} (Public)                                          │
│  │                                                                          │
│  └── api.php (Desktop app API with token auth)                              │
│      ├── POST /api/auth/login                                               │
│      ├── POST /api/galleries                                                │
│      └── GET  /api/orders                                                   │
│                                                                             │
│  Controllers                                                                │
│  ───────────                                                                │
│  ├── Web Controllers                                                        │
│  │   ├── Auth/LoginController, RegisterController, GoogleAuthController     │
│  │   ├── DashboardController                                                │
│  │   ├── GalleryController (index, show, destroy)                           │
│  │   ├── OrderController (index, show, export)                              │
│  │   ├── ProfileController (edit, update)                                   │
│  │   └── PublicGalleryController (show, submitSelection)                    │
│  │                                                                          │
│  └── API Controllers                                                        │
│      ├── Api/AuthController (login → returns token)                         │
│      ├── Api/GalleryController (store → multipart upload)                   │
│      └── Api/OrderController (index → list orders)                          │
│                                                                             │
│  Services                                                                   │
│  ────────                                                                   │
│  ├── GoogleDriveService (placeholder for Google Drive API)                  │
│  └── GalleryService (orchestrates gallery creation)                         │
│                                                                             │
│  Middleware                                                                 │
│  ──────────                                                                 │
│  ├── EnsureGoogleConnected (redirects if Google not linked)                 │
│  └── ApiTokenAuth (validates Bearer token for API routes)                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Desktop Application Architecture (Flutter)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER DESKTOP APPLICATION                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  lib/                                                                       │
│  ├── main.dart                 App entry point, dependency injection        │
│  ├── app.dart                  MaterialApp configuration, routing           │
│  │                                                                          │
│  ├── database/                                                              │
│  │   ├── database_service.dart     SQLite initialization, migrations        │
│  │   └── repositories/                                                      │
│  │       ├── user_repository.dart      User CRUD operations                 │
│  │       ├── gallery_repository.dart   Gallery CRUD operations              │
│  │       └── picture_repository.dart   Picture CRUD operations              │
│  │                                                                          │
│  ├── models/                                                                │
│  │   ├── user.dart             User data model                              │
│  │   ├── gallery.dart          Gallery data model                           │
│  │   ├── picture.dart          Picture data model                           │
│  │   └── order.dart            Order + OrderItem data models                │
│  │                                                                          │
│  ├── services/                                                              │
│  │   ├── api_service.dart      HTTP client for web API                      │
│  │   ├── auth_service.dart     Login, logout, session management            │
│  │   ├── file_service.dart     File picking, folder scanning                │
│  │   ├── image_service.dart    Image compression (1920x1080 @ 75%)          │
│  │   ├── gallery_service.dart  Import, submit, delete galleries             │
│  │   └── order_service.dart    Load JSON, match files, create ZIP           │
│  │                                                                          │
│  ├── state/                                                                 │
│  │   └── app_state.dart        ChangeNotifier for global state              │
│  │                                                                          │
│  └── screens/                                                               │
│      ├── login_screen.dart         Email/password login form                │
│      ├── galleries_screen.dart     List of local galleries + sidebar        │
│      ├── gallery_detail_screen.dart    Pictures grid, upload, delete        │
│      ├── import_gallery_screen.dart    Folder picker, name input            │
│      └── process_order_screen.dart     JSON loader, file matcher, ZIP       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Web Application

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Laravel | 12.x |
| Language | PHP | 8.3 |
| Database | PostgreSQL | 16 |
| Cache/Session | Redis | 7 |
| Web Server | Nginx | Alpine |
| CSS | Pure SCSS | - |
| JavaScript | Vanilla ES6 | - |
| Build Tool | Vite | 6.x |

### Desktop Application

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Flutter | 3.24+ |
| Language | Dart | 3.0+ |
| Database | SQLite | - |
| State | Provider + ChangeNotifier | - |
| HTTP | http package | 1.2+ |

### Infrastructure

| Component | Technology |
|-----------|------------|
| Containerization | Docker + Docker Compose |
| Reverse Proxy | Nginx |
| Process Manager | PHP-FPM |

---

## Project Structure

```
fotobook/
├── README.md                    # This file
├── CLAUDE.md                    # AI assistant context
├── docker-compose.yml           # Docker orchestration
├── .env.example                 # Environment template
│
├── docker/                      # Docker configuration
│   ├── nginx/
│   │   ├── nginx.conf          # Nginx main config
│   │   └── conf.d/
│   │       └── default.conf    # Virtual host config
│   └── php/
│       ├── php.ini             # Production PHP settings
│       ├── php-dev.ini         # Development PHP settings
│       └── php-fpm.conf        # PHP-FPM pool config
│
├── web/                         # Laravel Web Application
│   ├── Dockerfile              # Multi-stage Docker build
│   ├── .dockerignore           # Docker build exclusions
│   ├── composer.json           # PHP dependencies
│   ├── package.json            # Node dependencies
│   ├── vite.config.js          # Vite build configuration
│   │
│   ├── app/
│   │   ├── Http/
│   │   │   ├── Controllers/
│   │   │   │   ├── Auth/
│   │   │   │   │   ├── LoginController.php
│   │   │   │   │   ├── RegisterController.php
│   │   │   │   │   └── GoogleAuthController.php
│   │   │   │   ├── Api/
│   │   │   │   │   ├── AuthController.php
│   │   │   │   │   ├── GalleryController.php
│   │   │   │   │   └── OrderController.php
│   │   │   │   ├── DashboardController.php
│   │   │   │   ├── GalleryController.php
│   │   │   │   ├── OrderController.php
│   │   │   │   ├── ProfileController.php
│   │   │   │   ├── DownloadController.php
│   │   │   │   └── PublicGalleryController.php
│   │   │   │
│   │   │   └── Middleware/
│   │   │       ├── EnsureGoogleConnected.php
│   │   │       └── ApiTokenAuth.php
│   │   │
│   │   ├── Models/
│   │   │   ├── User.php
│   │   │   ├── Gallery.php
│   │   │   ├── Picture.php
│   │   │   └── Order.php
│   │   │
│   │   ├── Policies/
│   │   │   ├── GalleryPolicy.php
│   │   │   └── OrderPolicy.php
│   │   │
│   │   └── Services/
│   │       ├── GoogleDriveService.php
│   │       └── GalleryService.php
│   │
│   ├── database/
│   │   └── migrations/
│   │       ├── xxxx_create_users_table.php
│   │       ├── xxxx_create_galleries_table.php
│   │       ├── xxxx_create_pictures_table.php
│   │       ├── xxxx_create_orders_table.php
│   │       └── xxxx_add_google_fields_to_users_table.php
│   │
│   ├── resources/
│   │   ├── css/
│   │   │   ├── app.scss                    # Main entry point
│   │   │   ├── _variables.scss             # Colors, spacing, etc.
│   │   │   ├── _mixins.scss                # Reusable mixins
│   │   │   ├── _base.scss                  # Reset, typography
│   │   │   ├── layouts/
│   │   │   │   ├── _app.scss               # Authenticated layout
│   │   │   │   ├── _auth.scss              # Auth pages
│   │   │   │   └── _public.scss            # Public gallery
│   │   │   ├── components/
│   │   │   │   ├── _header.scss
│   │   │   │   ├── _sidebar.scss
│   │   │   │   ├── _gallery-grid.scss
│   │   │   │   └── _lightbox.scss
│   │   │   └── pages/
│   │   │       ├── _dashboard.scss
│   │   │       ├── _galleries.scss
│   │   │       ├── _orders.scss
│   │   │       └── _profile.scss
│   │   │
│   │   ├── js/
│   │   │   ├── app.js                      # Main JavaScript
│   │   │   ├── gallery-selection.js        # Photo selection logic
│   │   │   └── lightbox.js                 # Image lightbox
│   │   │
│   │   └── views/
│   │       ├── layouts/
│   │       │   ├── app.blade.php           # Auth layout
│   │       │   ├── auth.blade.php          # Guest layout
│   │       │   └── public.blade.php        # Public layout
│   │       ├── components/
│   │       │   ├── sidebar.blade.php
│   │       │   └── header.blade.php
│   │       ├── auth/
│   │       │   ├── login.blade.php
│   │       │   └── register.blade.php
│   │       ├── google/
│   │       │   └── connect.blade.php
│   │       ├── dashboard/
│   │       │   └── index.blade.php
│   │       ├── galleries/
│   │       │   ├── index.blade.php
│   │       │   └── show.blade.php
│   │       ├── orders/
│   │       │   ├── index.blade.php
│   │       │   └── show.blade.php
│   │       ├── profile/
│   │       │   └── edit.blade.php
│   │       ├── download/
│   │       │   └── index.blade.php
│   │       └── public/
│   │           └── gallery.blade.php
│   │
│   └── routes/
│       ├── web.php                         # Browser routes
│       └── api.php                         # Desktop API routes
│
└── desktop/                     # Flutter Desktop Application
    ├── Dockerfile              # Build container for CI/CD
    ├── pubspec.yaml            # Dart dependencies
    │
    └── lib/
        ├── main.dart                       # App entry point
        ├── app.dart                        # MaterialApp config
        │
        ├── database/
        │   ├── database_service.dart       # SQLite management
        │   └── repositories/
        │       ├── user_repository.dart
        │       ├── gallery_repository.dart
        │       └── picture_repository.dart
        │
        ├── models/
        │   ├── user.dart
        │   ├── gallery.dart
        │   ├── picture.dart
        │   └── order.dart
        │
        ├── services/
        │   ├── api_service.dart
        │   ├── auth_service.dart
        │   ├── file_service.dart
        │   ├── image_service.dart
        │   ├── gallery_service.dart
        │   └── order_service.dart
        │
        ├── state/
        │   └── app_state.dart
        │
        └── screens/
            ├── login_screen.dart
            ├── galleries_screen.dart
            ├── gallery_detail_screen.dart
            ├── import_gallery_screen.dart
            └── process_order_screen.dart
```

---

## Database Schema

### PostgreSQL (Web Application)

```sql
-- Users table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified_at TIMESTAMP,
    password VARCHAR(255) NOT NULL,
    google_access_token TEXT,
    google_refresh_token TEXT,
    google_token_expires_at TIMESTAMP,
    api_token VARCHAR(64) UNIQUE,
    remember_token VARCHAR(100),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Galleries table
CREATE TABLE galleries (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Pictures table
CREATE TABLE pictures (
    id BIGSERIAL PRIMARY KEY,
    gallery_id BIGINT REFERENCES galleries(id) ON DELETE CASCADE,
    original_filename VARCHAR(255) NOT NULL,
    google_drive_url TEXT,
    google_drive_file_id VARCHAR(255),
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Orders table
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    gallery_id BIGINT REFERENCES galleries(id) ON DELETE CASCADE,
    client_name VARCHAR(255) NOT NULL,
    client_email VARCHAR(255) NOT NULL,
    selected_picture_ids JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### SQLite (Desktop Application)

```sql
-- Users table (single user, stores login session)
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    token TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Galleries table (local galleries)
CREATE TABLE galleries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    folder_path TEXT NOT NULL,
    picture_count INTEGER NOT NULL DEFAULT 0,
    submitted_at TEXT,
    web_gallery_id INTEGER,
    web_slug TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Pictures table (local picture metadata)
CREATE TABLE pictures (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    gallery_id INTEGER NOT NULL,
    file_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    web_picture_id INTEGER,
    created_at TEXT NOT NULL,
    FOREIGN KEY (gallery_id) REFERENCES galleries(id) ON DELETE CASCADE
);
```

---

## API Documentation

### Authentication

#### Login
```
POST /api/auth/login
Content-Type: application/json

Request:
{
    "email": "user@example.com",
    "password": "password123"
}

Response (200):
{
    "token": "abc123...",
    "user": {
        "id": 1,
        "name": "John Doe",
        "email": "user@example.com"
    }
}

Response (401):
{
    "message": "Invalid credentials"
}
```

### Galleries

#### Upload Gallery
```
POST /api/galleries
Authorization: Bearer {token}
Content-Type: multipart/form-data

Request:
- name: "Wedding 2024"
- images[]: (file) IMG_001.jpg
- images[]: (file) IMG_002.jpg
- ...

Response (201):
{
    "gallery_id": 1,
    "slug": "wedding-2024-abc123",
    "pictures": [
        {
            "id": 1,
            "original_filename": "IMG_001.jpg",
            "display_url": "https://..."
        },
        ...
    ]
}
```

### Orders

#### List Orders
```
GET /api/orders
Authorization: Bearer {token}

Response (200):
{
    "orders": [
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
    ]
}
```

### Order JSON Export Format

```json
{
    "order_id": 1,
    "gallery_name": "Wedding 2024",
    "client_name": "Jane Smith",
    "client_email": "jane@example.com",
    "selected_pictures": [
        {"filename": "IMG_001.jpg"},
        {"filename": "IMG_042.jpg"},
        {"filename": "IMG_123.jpg"}
    ],
    "created_at": "2024-01-15T10:30:00Z"
}
```

---

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Git
- (For desktop development) Flutter SDK 3.24+

### Quick Start with Docker

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/fotobook.git
   cd fotobook
   ```

2. **Copy environment file**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start the containers**
   ```bash
   docker compose up -d
   ```

4. **Run migrations**
   ```bash
   docker compose exec app php artisan migrate
   ```

5. **Generate application key**
   ```bash
   docker compose exec app php artisan key:generate
   ```

6. **Access the application**
   - Web: http://localhost:8000

### Development Setup (Without Docker)

#### Web Application

1. **Install PHP dependencies**
   ```bash
   cd web
   composer install
   ```

2. **Install Node dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

4. **Run migrations**
   ```bash
   php artisan migrate
   ```

5. **Start development servers**
   ```bash
   # Terminal 1: PHP server
   php artisan serve

   # Terminal 2: Vite dev server
   npm run dev
   ```

#### Desktop Application

1. **Install Flutter** (if not installed)
   ```bash
   # Follow instructions at https://flutter.dev/docs/get-started/install
   ```

2. **Get dependencies**
   ```bash
   cd desktop
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run -d linux   # or -d windows, -d macos
   ```

---

## Docker Deployment

### Services Overview

| Service | Description | Port |
|---------|-------------|------|
| `postgres` | PostgreSQL 16 database | 5432 |
| `redis` | Redis 7 cache/session store | 6379 |
| `app` | PHP-FPM (Laravel application) | 9000 |
| `nginx` | Nginx web server | 8000 |
| `queue` | Laravel queue worker | - |
| `node` | Vite dev server (dev only) | 5173 |

### Common Commands

```bash
# Start all services
docker compose up -d

# Start with development profile (includes Vite)
docker compose --profile dev up -d

# View logs
docker compose logs -f

# Run artisan commands
docker compose exec app php artisan <command>

# Run composer commands
docker compose exec app composer <command>

# Access PostgreSQL
docker compose exec postgres psql -U fotobook -d fotobook

# Rebuild containers
docker compose build --no-cache

# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes data)
docker compose down -v
```

### Production Deployment

1. **Update environment variables**
   ```env
   APP_ENV=production
   APP_DEBUG=false
   ```

2. **Build optimized containers**
   ```bash
   docker compose build
   ```

3. **Run migrations**
   ```bash
   docker compose exec app php artisan migrate --force
   ```

4. **Optimize Laravel**
   ```bash
   docker compose exec app php artisan config:cache
   docker compose exec app php artisan route:cache
   docker compose exec app php artisan view:cache
   ```

### Building Desktop App with Docker

```bash
cd desktop

# Build Linux binary
docker build --target artifact --output type=local,dest=./dist .

# The built application will be in ./dist/fotobook-linux/
```

---

## Development Guide

### Web Application

#### Adding a New Controller

```php
// app/Http/Controllers/NewController.php
namespace App\Http\Controllers;

class NewController extends Controller
{
    public function index()
    {
        return view('new.index');
    }
}
```

#### Adding a New Route

```php
// routes/web.php
Route::middleware('auth')->group(function () {
    Route::get('/new', [NewController::class, 'index'])->name('new.index');
});
```

#### SCSS Structure

- Variables go in `_variables.scss`
- Mixins go in `_mixins.scss`
- New components get their own file in `components/`
- Import new files in `app.scss`

### Desktop Application

#### Adding a New Screen

1. Create the screen file in `lib/screens/`
2. Add navigation in `galleries_screen.dart` or appropriate location
3. Update `AppState` if new state is needed

#### Adding a New Service

1. Create service file in `lib/services/`
2. Register in `main.dart` with `Provider`
3. Access via `context.read<ServiceName>()`

---

## Testing

### Web Application

```bash
# Run all tests
docker compose exec app php artisan test

# Run specific test
docker compose exec app php artisan test --filter=TestClassName

# Run with coverage
docker compose exec app php artisan test --coverage
```

### Desktop Application

```bash
cd desktop

# Run all tests
flutter test

# Run specific test
flutter test test/specific_test.dart

# Run with coverage
flutter test --coverage
```

---

## Security Considerations

### API Token Security
- API tokens are hashed with SHA256 before storage
- Tokens are transmitted only over HTTPS in production
- Tokens can be regenerated at any time

### File Upload Security
- File types are validated on upload
- Filenames are sanitized
- Files are stored outside the web root

### Session Security
- Sessions stored in Redis (not filesystem)
- HTTP-only, secure cookies in production
- CSRF protection on all forms

### Database Security
- Prepared statements prevent SQL injection
- Database credentials in environment variables
- PostgreSQL with strong password required

### Desktop App Security
- API tokens stored in OS secure storage
- Local SQLite database per user
- No sensitive data logged

---

## License

This project is proprietary software.

---

## Support

For issues or questions, please open an issue on GitHub.
