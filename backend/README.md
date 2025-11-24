# PeakFindr Backend

A FastAPI + SQLAlchemy backend powering the PeakFindr mobile app.

---

## Quick Start

### 1. Create virtual environment

```bash
python -m venv venv
```

### 2. Activate virtual environment

**Windows**

```bash
venv\Scripts\activate
```

**macOS / Linux**

```bash
source venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

---

## Database Setup (PostgreSQL + SQLAlchemy)

PeakFindr uses **PostgreSQL** as the database and **SQLAlchemy ORM** for all operations.

### 4. Install PostgreSQL

#### macOS (Homebrew)

```bash
brew install postgresql
brew services start postgresql
```

#### Ubuntu / Linux

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo service postgresql start
```

#### Windows

Download installer:
[https://www.postgresql.org/download/windows/](https://www.postgresql.org/download/windows/)

---

### 5. Create the database

Open a terminal and login to PostgreSQL:

```bash
psql -U postgres
```

Inside the psql shell, create the database:

```sql
CREATE DATABASE peakfindr;
```

(Optional) Create a dedicated user:

```sql
CREATE USER peakuser WITH PASSWORD 'peakpassword';
GRANT ALL PRIVILEGES ON DATABASE peakfindr TO peakuser;
```

Exit psql:

```sql
\q
```

### 6. Apply latest migrations

Until Alembic is wired up, run the provided SQL scripts manually whenever new columns are introduced.

```bash
psql -d peakfindr -f backend/migrations/20250209_add_points_and_chat_tables.sql
psql -d peakfindr -f backend/migrations/20251123_add_location_optional_fields.sql
```

OR 
```bash
sudo -u postgres psql -d peakfindr -f migrations/20250209_add_points_and_chat_tables.sql
sudo -u postgres psql -d peakfindr -f migrations/20251123_add_location_optional_fields.sql
```


> Adjust the database name/connection flags if you use a different user or host.

---

## Environment File Setup

### 6. Copy example env file

```bash
copy .env.example .env
```

(or on macOS/Linux)

```bash
cp .env.example .env
```

### 7. Update your `.env` with database credentials

Example:

```env
DATABASE_URL=postgresql+psycopg2://peakuser:peakpassword@localhost/peakfindr
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

Make sure `DATABASE_URL` matches your PostgreSQL setup.

### 8. Configure the AI chatbot

The `/chatbot/{location_id}` endpoint proxies requests to **DeepSeek** so you don't ship your API key to the client.

Add your key to the environment before starting the server:

```env
DEEPSEEK_API_KEY=your-deepseek-key
```

> ⚠️ Keep this value out of source control. The backend reads the key at runtime and forwards visitor prompts along with location context so the model replies as a tour guide for that place.

---

## Initialize SQLAlchemy Models (Create Tables)

PeakFindr automatically creates tables on startup (no Alembic required yet).

Run:

```bash
uvicorn app.main:app --reload
```

If the database is reachable, SQLAlchemy will create all tables defined in `models/`.

---

## Run the Server

Start FastAPI:

```bash
uvicorn app.main:app --reload
```

### Visit:

* API Docs: **[http://localhost:8000/docs](http://localhost:8000/docs)**
* Health Check: **[http://localhost:8000/health](http://localhost:8000/health)**
* Root Page: **[http://localhost:8000](http://localhost:8000)**

---


## 📚 Complete API Reference

Only endpoints that need user context require the `X-User-ID` header. In the tables below, the **Headers** column shows when to include it; a dash (`—`) means the route is public.

---

### 🔐 Authentication (`/auth`)

| Method | Endpoint | Description | Headers | Request Body | Response |
|--------|----------|-------------|---------|--------------|----------|
| **POST** | `/auth/register` | Register new user | — | `{ "email": "user@example.com", "username": "peak_user", "password": "SecurePass123" }` | `{ "message": "User registered successfully", "user_id": "uuid", "email": "...", "username": "..." }` |
| **POST** | `/auth/login` | Authenticate user | — | `{ "email": "user@example.com", "password": "SecurePass123" }` | `{ "message": "Login successful", "user_id": "uuid", "email": "...", "username": "..." }` |
| **GET** | `/auth/me` | Debug header check | `X-User-ID: <uuid>` | — | `{ "message": "Header received", "user_id": "uuid" }` |

---

### 📍 Locations (`/locations`)

| Method | Endpoint | Description | Headers | Request Body | Response |
|--------|----------|-------------|---------|--------------|----------|
| **GET** | `/locations/recommended?limit=10` | Random recommended locations the user has not visited yet | `X-User-ID` | Query: optional `limit` (max 50) | `[{ "location": {...}, "images": [...], "tags": [...] }, ...]` |
| **GET** | `/locations/by-tags?tags=hiking,scenic&match_all=false` | Filter locations by tags (comma-separated) | — | Query: `tags` (required), `match_all` (optional, default false) | `[{ "location": {...}, "images": [...], "tags": [...] }, ...]` |
| **GET** | `/locations/` | List all locations | — | Query: `?area=<str>&price_level=<int>` | `[{ "id": "uuid", "name": "...", "description": "...", "maps_url": "...", "price_level": 1-4, "area": "...", "created_at": "..." }, ...]` |
| **POST** | `/locations/` | Create location | — | `{ "name": "Peak Tower", "description": "...", "maps_url": "...", "price_level": 2, "area": "Central" }` | `LocationResponse` |
| **GET** | `/locations/{location_id}` | Get location + images + tags | — | — | `{ "location": {...}, "images": [...], "tags": [...] }` |
| **PUT** | `/locations/{location_id}` | Update location | — | `{ "name": "New Name", "price_level": 3 }` (partial) | `LocationResponse` |
| **DELETE** | `/locations/{location_id}` | Delete location | — | — | `{ "message": "Location deleted" }` |
| **POST** | `/locations/{location_id}/images` | Upload location image | — | `multipart/form-data` with `file` | `{ "id": 1, "location_id": "uuid", "file_path": "...", "created_at": "..." }` |
| **POST** | `/locations/{location_id}/tags` | Add tags to location | — | `{ "tags": ["hiking", "scenic"] }` | `{ "added_tags": [{ "id": 1, "name": "hiking" }, ...] }` |
| **DELETE** | `/locations/{location_id}/tags/{tag_id}` | Remove tag from location | — | — | `{ "message": "Tag removed" }` |

---

### ⭐ Reviews (`/reviews`)

| Method | Endpoint | Description | Headers | Request Body | Response |
|--------|----------|-------------|---------|--------------|----------|
| **POST** | `/reviews/` | Create review | `X-User-ID` | `{ "location_id": "uuid", "rating": 5, "comment": "Amazing!" }` | `{ "id": "uuid", "user_id": "uuid", "location_id": "uuid", "rating": 5, "comment": "...", "created_at": "..." }` |
| **GET** | `/reviews/` | Get all reviews (paginated) | `X-User-ID` | Query: `?limit=50&offset=0` | `[{ "review": {...}, "photos": [...] }, ...]` |
| **GET** | `/reviews/{review_id}` | Get single review by ID | `X-User-ID` | — | `{ "review": {...}, "photos": [...] }` |
| **GET** | `/reviews/location/{location_id}` | Get reviews for location | `X-User-ID` | — | `[{ "review": {...}, "photos": [...] }, ...]` |
| **GET** | `/reviews/user/{user_id}` | Get all reviews by a user | `X-User-ID` | — | `[{ "review": {...}, "photos": [...] }, ...]` |
| **GET** | `/reviews/me/reviews` | Get current user's reviews | `X-User-ID` | — | `[{ "review": {...}, "photos": [...] }, ...]` |
| **PUT** | `/reviews/{review_id}` | Update own review | `X-User-ID` | `{ "rating": 4, "comment": "Updated" }` (partial) | `ReviewResponse` |
| **DELETE** | `/reviews/{review_id}` | Delete own review | `X-User-ID` | — | `{ "message": "Review deleted" }` |
| **POST** | `/reviews/{review_id}/photos` | Upload review photo | `X-User-ID` | `multipart/form-data` with `file` | `{ "id": 1, "review_id": "uuid", "file_path": "...", "created_at": "..." }` |

---

### 💬 Chat (`/chat`)

#### Location Chats

| Method | Endpoint | Description | Headers | Request Body | Response |
|--------|----------|-------------|---------|--------------|----------|
| **POST** | `/chat/{location_id}` | Send message to a location-specific feed | `X-User-ID` | `{ "message": "Hello everyone!" }` | `{ "id": 1, "location_id": "uuid", "user_id": "uuid", "message": "...", "created_at": "..." }` |
| **GET** | `/chat/{location_id}` | Get the most recent messages for a location | `X-User-ID` | — | `[{ "id": 1, "location_id": "uuid", "user_id": "uuid", "message": "...", "created_at": "..." }, ...]` |

#### Social Hub Rooms

| Method | Endpoint | Description | Headers | Request Body | Response |
|--------|----------|-------------|---------|--------------|----------|
| **GET** | `/chat/rooms` | List all available chat rooms (auto-seeds defaults) | `X-User-ID` | — | `[{ "id": "uuid", "name": "General Chat", "category": "all", ... }, ...]` |
| **POST** | `/chat/rooms` | Create a new chat room | `X-User-ID` | `{ "name": "Sunset Lovers", "category": "sights" }` | `ChatRoomResponse` |
| **GET** | `/chat/rooms/{room_id}/messages?limit=50&before=<ISO8601>` | Fetch paginated room history | `X-User-ID` | — | `[{ "id": "uuid", "room_id": "uuid", "text": "...", "created_at": "..." }, ...]` |
| **POST** | `/chat/rooms/{room_id}/messages` | Send a message to a room via HTTP fallback | `X-User-ID` | `{ "text": "Who's hiking today?" }` | `ChatRoomMessageResponse` |
| **WebSocket** | `/chat/rooms/{room_id}/ws` | Real-time chat stream (send `{ "text": "hi", "user_id": "uuid" }`) | — | WebSocket JSON frames | Broadcasts `ChatRoomMessageResponse` payloads to the room |

---

### 🏷️ Tags (`/tags`)

| Method | Endpoint | Description | Headers | Request Body | Response |
|--------|----------|-------------|---------|--------------|----------|
| **GET** | `/tags/` | List all tags | — | — | `[{ "id": 1, "name": "hiking" }, ...]` |
| **POST** | `/tags/` | Create new tag | — | `{ "name": "mountain" }` | `{ "id": 2, "name": "mountain" }` |
| **DELETE** | `/tags/{tag_id}` | Delete tag | — | — | `{ "message": "Tag deleted successfully" }` |

---

### 🤝 User Interactions (`/interactions`)

| Method | Endpoint | Description | Headers | Request Body | Response |
|--------|----------|-------------|---------|--------------|----------|
| **POST** | `/interactions/like/{location_id}` | Like a location | `X-User-ID` | — | `{ "message": "Location liked" }` |
| **DELETE** | `/interactions/like/{location_id}` | Unlike a location | `X-User-ID` | — | `{ "message": "Like removed" }` |
| **GET** | `/interactions/likes` | Get user's liked locations | `X-User-ID` | — | `[{ "user_id": "uuid", "location_id": "uuid", "created_at": "..." }, ...]` |
| **POST** | `/interactions/save/{location_id}` | Save a location | `X-User-ID` | — | `{ "message": "Location saved" }` |
| **DELETE** | `/interactions/save/{location_id}` | Unsave a location | `X-User-ID` | — | `{ "message": "Removed from saved" }` |
| **GET** | `/interactions/saved` | Get user's saved locations | `X-User-ID` | — | `[{ "user_id": "uuid", "location_id": "uuid", "created_at": "..." }, ...]` |
| **POST** | `/interactions/visit/{location_id}` | Record a visit | `X-User-ID` | — | `{ "message": "Visit recorded", "visit_id": "uuid" }` |
| **GET** | `/interactions/visits` | Get user's visits | `X-User-ID` | — | `[{ "id": 1, "user_id": "uuid", "location_id": "uuid", "created_at": "..." }, ...]` |

---

## 📱 Frontend Integration Guide

### Swift/iOS Setup

#### 1. Create API Client Service

```swift
import Foundation

class APIClient {
    static let shared = APIClient()
    private let baseURL = "http://localhost:8000"
    
    private init() {}
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        userId: String? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header
        if let userId = userId {
            request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        }
        
        // Encode body
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

#### 2. Define Models

```swift
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let message: String
    let user_id: String
    let email: String
    let username: String
}

struct Location: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let maps_url: String?
    let price_level: Int?
    let area: String?
    let created_at: String
}
```

#### 3. Create Service Layer

```swift
class AuthService {
    static let shared = AuthService()
    private let client = APIClient.shared
    
    func login(email: String, password: String) async throws -> LoginResponse {
        let body = LoginRequest(email: email, password: password)
        return try await client.request(
            endpoint: "/auth/login",
            method: "POST",
            body: body
        )
    }
    
    func register(email: String, username: String, password: String) async throws -> LoginResponse {
        let body = ["email": email, "username": username, "password": password]
        return try await client.request(
            endpoint: "/auth/register",
            method: "POST",
            body: body
        )
    }
}

class LocationService {
    static let shared = LocationService()
    private let client = APIClient.shared
    
    func fetchLocations(userId: String) async throws -> [Location] {
        return try await client.request(
            endpoint: "/locations/",
            userId: userId
        )
    }
    
    func likeLocation(locationId: String, userId: String) async throws -> MessageResponse {
        return try await client.request(
            endpoint: "/interactions/like/\(locationId)",
            method: "POST",
            userId: userId
        )
    }
}
```

#### 4. Use in SwiftUI Views

```swift
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            
            Button("Login") {
                Task {
                    do {
                        let response = try await AuthService.shared.login(
                            email: email,
                            password: password
                        )
                        authViewModel.userId = response.user_id
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}
```

### Key Integration Points

1. **Authentication Flow**
   - Call `/auth/register` or `/auth/login`
   - Store returned `user_id` in UserDefaults or Keychain
   - Include `user_id` in `X-User-ID` header for all subsequent requests

2. **Location Discovery**
   - Fetch locations with `/locations/`
   - Display in swipe cards or list
   - Use `/interactions/like/{id}` for swipe right
   - Use `/interactions/save/{id}` for bookmarking

3. **Reviews & Ratings**
   - POST to `/reviews/` after user visits
   - GET from `/reviews/location/{id}` to display on detail pages
   - Upload photos with multipart form data to `/reviews/{id}/photos`

4. **Real-time Chat**
   - POST messages to `/chat/{location_id}`
   - Poll GET `/chat/{location_id}` every few seconds (or use WebSockets later)

5. **Error Handling**
   - 401: User not authenticated → redirect to login
   - 403: Permission denied → show error toast
   - 404: Resource not found → show not found UI
   - 400: Validation error → display field errors

---