# PeakFindr Backend

FastAPI backend for the PeakFindr location discovery app.

## Quick Start

```bash
# 1. Create & activate virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# 2. Install dependencies
pip install -r requirements.txt

# 3. Set up environment variables
cp .env.example .env
# Edit .env with your database URL

# 4. Run the server
uvicorn app.main:app --reload
```

**API Docs:** http://localhost:8000/docs

---

## Environment Variables

```env
DATABASE_URL=postgresql://user:password@host:port/database
SECRET_KEY=your-secret-key
DEEPSEEK_API_KEY=your-deepseek-key  # For AI chatbot
```

---

## Database

Tables are created automatically on startup. For remote PostgreSQL (like Supabase), use the connection pooler URL if you have IPv6 issues:

```env
DATABASE_URL=postgresql://postgres.PROJECT:PASSWORD@aws-0-REGION.pooler.supabase.com:5432/postgres
```

---

## API Routes Overview

### Authentication (\`/auth\`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | \`/auth/register\` | — | Create account |
| POST | \`/auth/login\` | — | Login |
| GET | \`/auth/me\` | ✓ | Verify auth header |

### Locations (\`/locations\`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | \`/locations/\` | — | List all locations |
| GET | \`/locations/discover\` | ✓ | Get locations (excludes saved) |
| GET | \`/locations/recommended\` | ✓ | Get recommendations (excludes visited) |
| GET | \`/locations/by-tags?tags=hiking,scenic\` | — | Filter by tags |
| GET | \`/locations/{id}\` | — | Get location details |
| POST | \`/locations/\` | — | Create location |
| PUT | \`/locations/{id}\` | — | Update location |
| DELETE | \`/locations/{id}\` | — | Delete location |
| GET | \`/locations/{id}/image\` | — | Get location image |
| POST | \`/locations/{id}/images\` | — | Upload image |
| POST | \`/locations/{id}/tags\` | — | Add tags |

### Reviews (\`/reviews\`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | \`/reviews/\` | ✓ | All reviews (paginated) |
| GET | \`/reviews/{id}\` | ✓ | Single review |
| GET | \`/reviews/location/{id}\` | ✓ | Reviews for location |
| GET | \`/reviews/me/reviews\` | ✓ | Current user's reviews |
| POST | \`/reviews/\` | ✓ | Create review |
| PUT | \`/reviews/{id}\` | ✓ | Update review |
| DELETE | \`/reviews/{id}\` | ✓ | Delete review |
| POST | \`/reviews/{id}/photos\` | ✓ | Upload photo |

### Interactions (\`/interactions\`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | \`/interactions/like/{id}\` | ✓ | Like location |
| DELETE | \`/interactions/like/{id}\` | ✓ | Unlike |
| GET | \`/interactions/likes\` | ✓ | Get liked |
| POST | \`/interactions/save/{id}\` | ✓ | Save location |
| DELETE | \`/interactions/save/{id}\` | ✓ | Unsave |
| GET | \`/interactions/saved\` | ✓ | Get saved |
| POST | \`/interactions/visit/{id}\` | ✓ | Record visit |
| GET | \`/interactions/visits\` | ✓ | Get visits |

### Chat (\`/chat\`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | \`/chat/rooms\` | ✓ | List chat rooms |
| POST | \`/chat/rooms\` | ✓ | Create room |
| GET | \`/chat/rooms/{id}/messages\` | ✓ | Get room messages |
| POST | \`/chat/rooms/{id}/messages\` | ✓ | Send message |
| WS | \`/chat/rooms/{id}/ws\` | — | WebSocket connection |
| GET | \`/chat/{location_id}\` | ✓ | Location chat messages |
| POST | \`/chat/{location_id}\` | ✓ | Send to location chat |

### Chatbot (\`/chatbot\`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | \`/chatbot/{location_id}\` | ✓ | AI tour guide chat |

### Tags (\`/tags\`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | \`/tags/\` | — | List all tags |
| POST | \`/tags/\` | — | Create tag |
| DELETE | \`/tags/{id}\` | — | Delete tag |

---

## Authentication

Protected endpoints require the \`X-User-ID\` header:

```bash
curl -H "X-User-ID: your-uuid" http://localhost:8000/interactions/saved
```

Get your user ID from \`/auth/login\` response.

---

## Project Structure

```
backend/
├── app/
│   ├── main.py           # FastAPI app & startup
│   ├── database.py       # SQLAlchemy setup
│   ├── models/           # Database models
│   ├── routers/          # API endpoints
│   ├── schemas/          # Pydantic schemas
│   └── utils/            # Helpers (auth, etc.)
├── media/                # Uploaded images
├── scripts/              # Testing notebooks
├── requirements.txt
└── .env
```

---

## Tech Stack

- **FastAPI** - Web framework
- **SQLAlchemy** - ORM
- **PostgreSQL** - Database
- **Pydantic** - Validation
- **Uvicorn** - ASGI server
- **WebSockets** - Real-time chat
- **DeepSeek** - AI chatbot
