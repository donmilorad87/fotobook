# 📸 Fotobook — Software Specification (Rewritten)

## 1. Overview

**Fotobook** is a software platform for photographers that simplifies how clients select photos after an event.

### The Problem
Photographers often take **thousands of photos (e.g., 3000)** at a single event.  
Afterward, clients (event organizers / "event masters") must choose which photos should be printed.

Today, clients often make selections:
- on paper lists,
- over phone calls,
- in-person,
- or through slow manual communication.

This results in a **time-consuming process** where photographers wait for clients to select photos.

### The Solution
Fotobook automates this workflow using:
- a **Desktop App** (used by photographers)
- a **Web App** (used by both photographers and clients)

Both applications share the same central database and work together to allow:
✅ photographers to upload galleries  
✅ clients to select photos online  
✅ photographers to receive selections instantly as structured data  

---

## 2. System Architecture

Fotobook consists of two main components:

### 2.1 Web Application
- Used for:
  - user accounts (photographers)
  - Google account linking
  - viewing uploaded galleries
  - client photo selection
  - order creation

✅ Tech stack: **PHP/Laravel + SQL + Vanilla JS + HTML(use only blades and web routes, no inertia, no SPA, jsut web routes and blades) + CSS**

### 2.2 Desktop Application
- Used for:
  - uploading photo galleries
  - reading orders
  - extracting selected photos locally
  - creating a `.zip` file of selected full-resolution images

✅ Must run on:
- Windows
- macOS
- Linux

---

## 3. Key Concepts

### 3.1 Gallery
A gallery is a group of photos, usually created from one event.

### 3.2 Picture
Each picture belongs to exactly one gallery.

### 3.3 Order
An order is created when a client submits their selected photos from a gallery.

---

## 4. Authentication and Google Drive Integration

### Why Google Drive?
Fotobook is intended to be a free application.  
Instead of storing images on Fotobook servers, **all images are stored in the photographer’s own Google Drive**.

Fotobook will:
- Upload images to the photographer’s Google Drive
- Store only the **public URLs** of the photos in the Fotobook database
- Use Google Drive as a free CDN / file storage

### Workflow
1. Photographer creates an account on the web app.
2. Photographer logs in.
3. Photographer connects their Google account.
4. Photographer grants Google Drive permissions.
5. Fotobook uses a **Google service account** to upload photos into the photographer’s Drive.
6. Uploaded files must be **publicly accessible** (so clients can view them).
7. After Google account linking is successful, the photographer can download the desktop app.

---

## 5. Desktop Application Specifications

### 5.1 Login
- Photographer logs into the desktop application using Fotobook credentials. -> Photographer will send its credentials to the api route of web application, and if credentials are right, web app will return token.
- After login:
  - token + credentials are stored locally in a local database (`users` table).

### 5.2 Local Database
The desktop app maintains its own local DB to store:
- photo file paths (local filesystem)
- gallery metadata
- relations between galleries and pictures

#### Local DB Tables
- `users`
- `galleries`
- `pictures`

Each picture is linked to a gallery via foreign key / relation.

### 5.3 Import Gallery from Local Folder
The photographer can select a folder containing event photos.

When a folder is selected:
- The app scans all images
- Stores each file path in the local `pictures` table
- Stores gallery in the local `galleries` table
- Links pictures to gallery

### 5.4 Deleting Galleries (Important Rule)
Photographers can delete galleries from the desktop app, but:
✅ only links and database entries are deleted  
❌ real image files must NEVER be deleted from disk

### 5.5 Submitting a Gallery to the Web App
When photographer clicks **Submit Gallery**:
1. App scans all images in the gallery
2. Each image is resized:
   - max resolution: **1920 × 1080**
3. Each image is compressed:
   - quality: **75%**
4. Compressed versions are sent through API to the web application
5. Request must include photographer authentication token

---

## 6. Web Application Specifications

### 6.1 Upload API Behavior
When web app receives uploaded images:
1. Identifies the photographer using the submitted token
2. Uploads images into the photographer’s Google Drive
3. Google Drive returns public URLs
4. Web app stores those URLs in the database
5. Gallery becomes visible online

### 6.2 Web Database Tables
The web app database includes these tables:

| Table Name   | Purpose |
|-------------|---------|
| `users`     | Authentication & photographer account data |
| `galleries` | Gallery metadata |
| `pictures`  | Picture metadata + public URLs |
| `orders`    | Client photo orders (selected photos) |

---

## 7. Client Selection Flow (Gallery Link)

Once a gallery is uploaded:
- the photographer receives a **public gallery URL**
- photographer sends that URL to a client

Client can:
✅ view all photos in the gallery  
✅ open photos in a lightbox  
✅ select photos via checkbox (in grid + lightbox)  
✅ submit selection  

When the client submits:
- an order is created in the `orders` table
- linked to the photographer + gallery
- contains selected photo IDs / URLs

---

## 8. Orders and Photographer Workflow

### 8.1 Order Viewing
Photographer can view all orders on the Orders page.

### 8.2 Export Order as JSON
Photographer can download an order as a `.json` file containing selected picture identifiers.

---

## 9. Order Processing in Desktop App

### 9.1 Load Order JSON
Photographer loads the downloaded `order.json` into the desktop app.

### 9.2 Extract Selected Photos
Desktop app will:
1. read the order JSON
2. match selected photos to local full-resolution file paths
3. copy selected photos into a new folder
4. create a `.zip` archive containing all selected full-resolution images

✅ Result: photographer gets a `.zip` file ready for printing.

---

## 10. Web Application Pages

### Public Pages
1. **Login Page**
   - homepage for photographers

### Photographer-Only Pages (requires login)
2. **Google Account Connect Page**
   - one big “Login with Google” button
   - user authorizes Drive permissions
   - app ensures Google Drive is public / accessible

3. **Download Desktop App Page**
   - photographer downloads desktop app installer

4. **Galleries Page**
   - photographer views list of their galleries

5. **Orders Page**
   - photographer views orders and downloads `.json`

6. **Profile Page**
   - edit photographer profile information

### Client Page (public link access)
7. **Gallery Page**
   - clients view images and select photos via checkbox

---

## 11. Desktop Application Pages

1. **Login Screen**
2. **Galleries Page**
   - shows galleries imported from local folders
3. **Import Photos / Extract From Folder Page**
   - select folder
   - scan pictures
   - create gallery
   - submit to web
   - load order JSON
   - export selected photos as `.zip`

---

## 12. Desktop App Technology Requirement

You requested:
- native apps for Windows, macOS, and Linux
- "vanilla code"
- no specific stack given
- use Flutter to create navtive apps. try to be vanilla as possible.

But since you requested *vanilla + native*, you are implicitly requesting **3 separate native implementations** (or a very advanced unified approach).

## 13. Dockerize desktop and web app
Create docker compose and dockerfiles for web app.