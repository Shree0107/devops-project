import pytest
from app.app import app

# ── Setup ────────────────────────────────────────────────────────────

@pytest.fixture
def client():
    """Creates a test client for the Flask app."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client

# ── Tests ─────────────────────────────────────────────────────────────

def test_home(client):
    """GET / should return 200 and correct keys."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.get_json()
    assert "message" in data
    assert "version" in data
    assert "status" in data

def test_health(client):
    """GET /health should return 200 and status healthy."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "healthy"

def test_greet_default(client):
    """GET /greet without name returns Hello, World!"""
    response = client.get("/greet")
    assert response.status_code == 200
    assert response.get_json()["message"] == "Hello, World!"

def test_greet_with_name(client):
    """GET /greet?name=Shree returns Hello, Shree!"""
    response = client.get("/greet?name=Shree")
    assert response.status_code == 200
    assert response.get_json()["message"] == "Hello, Shree!"

def test_greet_invalid_name(client):
    """GET /greet?name=123 returns 400 for invalid name."""
    response = client.get("/greet?name=123")
    assert response.status_code == 400
    assert "error" in response.get_json()

def test_add_success(client):
    """POST /add with valid body returns correct sum."""
    response = client.post("/add", json={"a": 5, "b": 3})
    assert response.status_code == 200
    assert response.get_json()["result"] == 8.0

def test_add_missing_fields(client):
    """POST /add without required fields returns 400."""
    response = client.post("/add", json={"a": 5})
    assert response.status_code == 400
    assert "error" in response.get_json()

def test_add_invalid_types(client):
    """POST /add with non-numeric values returns 400."""
    response = client.post("/add", json={"a": "hello", "b": "world"})
    assert response.status_code == 400
    assert "error" in response.get_json()
