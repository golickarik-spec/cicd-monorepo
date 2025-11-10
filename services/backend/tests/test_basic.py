import os
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch

# Set test environment variables
os.environ["DB_HOST"] = "localhost"
os.environ["DB_PORT"] = "3306"
os.environ["DB_USER"] = "testuser"
os.environ["DB_PASSWORD"] = "testpassword"
os.environ["DB_NAME"] = "testdb"


@pytest.fixture
def client():
    """Create a test client for the FastAPI app."""
    from app.main import app
    return TestClient(app)


@pytest.fixture
def mock_db():
    """Mock database connection."""
    with patch('app.main.get_conn') as mock_conn:
        mock_cursor = (
            mock_conn.return_value.__enter__.return_value
            .cursor.return_value.__enter__.return_value
        )
        yield mock_cursor


def test_health_endpoint(client):
    """Test health endpoint returns OK."""
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json() == {"ok": True}


def test_list_items_empty(client, mock_db):
    """Test listing items when empty."""
    mock_db.fetchall.return_value = []

    response = client.get("/api/items")
    assert response.status_code == 200
    assert response.json() == []


def test_list_items_with_data(client, mock_db):
    """Test listing items with data."""
    mock_db.fetchall.return_value = [{"id": 1, "name": "Test Item"}]

    response = client.get("/api/items")
    assert response.status_code == 200
    assert response.json() == [{"id": 1, "name": "Test Item"}]


def test_create_item_success(client, mock_db):
    """Test creating an item successfully."""
    mock_db.lastrowid = 123

    response = client.post("/api/items", json={"name": "New Item"})
    assert response.status_code == 201
    assert response.json() == {"id": 123, "name": "New Item"}


def test_create_item_empty_name(client):
    """Test creating item with empty name fails."""
    response = client.post("/api/items", json={"name": ""})
    assert response.status_code == 400
    assert response.json()["detail"] == "name is required"


def test_delete_item_success(client, mock_db):
    """Test deleting an item successfully."""
    mock_db.rowcount = 1

    response = client.delete("/api/items/123")
    assert response.status_code == 204


def test_delete_item_not_found(client, mock_db):
    """Test deleting non-existent item returns 404."""
    mock_db.rowcount = 0

    response = client.delete("/api/items/999")
    assert response.status_code == 404
    assert response.json()["detail"] == "not found"
