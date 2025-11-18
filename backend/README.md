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

---

## Initialize SQLAlchemy Models (Create Tables)

PeakFindr automatically creates tables on startup (no Alembic required yet).

Run:

```bash
python main.py
```

If the database is reachable, SQLAlchemy will create all tables defined in `models/`.

---

## Run the Server

Start FastAPI:

```bash
python main.py
```

### Visit:

* API Docs: **[http://localhost:8000/docs](http://localhost:8000/docs)**
* Health Check: **[http://localhost:8000/health](http://localhost:8000/health)**
* Root Page: **[http://localhost:8000](http://localhost:8000)**

---


## API Reference (Auth & Locations)

### Auth

| Method | Endpoint        | Description              | Request Body |
| ------ | --------------- | ------------------------ | ------------ |
| POST   | `/auth/register` | Register a new user      | `{ "email": str, "username": str, "password": str }`
| POST   | `/auth/login`    | Log in and validate user | `{ "email": str, "password": str }`
| GET    | `/auth/me`       | Debug header echo        | Header `X-User-ID`

### Locations

| Method | Endpoint                         | Description                        | Request Body |
| ------ | -------------------------------- | ---------------------------------- | ------------ |
| GET    | `/locations/`                    | List locations (optional filters)  | Query params `area`, `price_level` |
| POST   | `/locations/`                    | Create location                    | `LocationCreate` schema |
| GET    | `/locations/{location_id}`       | Get location details               | — |
| PUT    | `/locations/{location_id}`       | Update location                    | `LocationUpdate` schema |
| DELETE | `/locations/{location_id}`       | Delete location                    | — |
| POST   | `/locations/{location_id}/images`| Upload location image (multipart)  | file form-data |
| POST   | `/locations/{location_id}/tags`  | Add tags to location               | `{ "tags": [str, ...] }`
| DELETE | `/locations/{location_id}/tags/{tag_id}` | Remove tag from location | — |

---