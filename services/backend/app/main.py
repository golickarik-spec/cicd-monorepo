from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import time
import pymysql

app = FastAPI(title="CICD Example API (MySQL)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
DB_HOST = os.getenv("DB_HOST", "mysql")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "appuser")
DB_PASSWORD = os.getenv("DB_PASSWORD", "apppassword")
DB_NAME = os.getenv("DB_NAME", "appdb")


def get_conn():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )


def init_db() -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS items (
                  id INT AUTO_INCREMENT PRIMARY KEY,
                  name VARCHAR(255) NOT NULL
                )
                """
            )


class ItemIn(BaseModel):
    name: str


@app.get("/api/health")
def health():
    return {"ok": True}


@app.get("/api/items")
def list_items():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name FROM items ORDER BY id DESC")
            rows = cur.fetchall()
            return rows


@app.post("/api/items", status_code=201)
def create_item(item: ItemIn):
    name = (item.name or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="name is required")
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO items(name) VALUES (%s)", (name,))
            new_id = cur.lastrowid
            return {"id": new_id, "name": name}


@app.delete("/api/items/{item_id}", status_code=204)
def delete_item(item_id: int):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM items WHERE id = %s", (item_id,))
            if cur.rowcount == 0:
                raise HTTPException(status_code=404, detail="not found")
            return None


@app.on_event("startup")
def on_startup():
    # Retry DB connection a few times on startup to wait for MySQL
    attempts = 0
    last_err = None
    while attempts < 20:
        try:
            init_db()
            return
        except Exception as e:  # noqa: BLE001 - startup tolerance
            last_err = e
            attempts += 1
            time.sleep(1.0 + attempts * 0.25)
    raise last_err
