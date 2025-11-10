# backend
backend for cicd project
## Backend (Python FastAPI + MySQL)

### Setup

1) Create and activate a virtualenv (recommended)
```
python -m venv .venv
./.venv/Scripts/activate  # Windows PowerShell
```

2) Install dependencies
```
pip install -r requirements.txt
```

3) Run the server
```
set DB_HOST=localhost
set DB_PORT=3306
set DB_USER=appuser
set DB_PASSWORD=apppassword
set DB_NAME=appdb
uvicorn app.main:app --reload --port 8000
```

API will be available at `http://localhost:8000`.

### Docker Compose (recommended)

From repo root:
```
docker compose up --build
```
This starts `mysql`, `backend`, and `frontend` with correct networking.
