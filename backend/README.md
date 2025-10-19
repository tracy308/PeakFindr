# PeakFindr Backend

## Quick Start

1. **Create virtual environment:**
   ```bash
   python -m venv venv
   ```

2. **Activate virtual environment:**
   - Windows: `venv\Scripts\activate`
   - macOS/Linux: `source venv/bin/activate`

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Copy environment file:**
   ```bash
   copy .env.example .env
   ```

5. **Run the server:**
   ```bash
   python main.py
   ```

6. **Visit:** http://localhost:8000

   - API docs: http://localhost:8000/docs
   - Health check: http://localhost:8000/health

## Next Steps

Once this basic setup works, we'll add:
- Database connection (PostgreSQL)
- Authentication
- API endpoints
- And more features incrementally