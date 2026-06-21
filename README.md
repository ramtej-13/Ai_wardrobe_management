# AI Wardrobe Management System

A Python-based application to manage a user profile and an automated clothing/footwear wardrobe, powered by **MongoDB Atlas** for secure, cloud-based data persistence.

Exposes features as both a local colorized Command Line Interface (CLI) and a modern Web REST API (built with **FastAPI** and **Uvicorn**).

---

## Features

- **User Profile Management**: Store and retrieve user details (Name, Age, Gender, Height, Weight).
- **Wardrobe Item Cataloging**: Add items (e.g. Shirts, Pants, Shoes, Accessories) with automatic sequential unique ID generation (`C001`, `C002`, etc.), categories, colors, descriptions, dates, and optional image paths.
- **Smart Category Count**: Live counter showing items grouped by category (e.g. `Shirts: 5`, `Pants: 3`, `Shoes: 2`).
- **Flexible Searching**: Perform case-insensitive search across names, categories, colors, or descriptions.
- **Cloud Persistence**: Full integration with **MongoDB Atlas** using the `pymongo` library, allowing you to load and save your wardrobe securely in the cloud.
- **Colorized Interactive CLI Menu**: Aesthetic, user-friendly console dashboard with tables and category counts.
- **FastAPI Web Service**: Complete REST API wrapping all wardrobe features with automatic validation (using **Pydantic**).
- **Interactive Swagger Documentation**: Visual UI playground at `/docs` to inspect and test all web endpoints.
- **Dual Test Suites**: Automated tests validating both the Python logic (`verify_wardrobe.py`) and the Web API endpoints (`verify_api.py`).

---

## File Structure

The project is modularized into dedicated, separate Python files:

```text
├── user.py              # User class and dict serialization methods
├── wardrobe_item.py     # WardrobeItem class representing single closet items
├── wardrobe.py          # Wardrobe collection and count/search logic
├── storage.py           # MongoDB connection utility and load/save functions
├── main.py              # Application CLI entrypoint (Console Menu)
├── app.py               # Application Web API entrypoint (FastAPI routes)
├── verify_wardrobe.py   # Test suite for local classes and DB logic
├── verify_api.py        # Test suite for Web API endpoints
├── config.json          # Credentials configuration (Git-ignored)
└── README.md            # Project documentation (this file)
```

---

## Installation & Setup

### 1. Install Dependencies
Make sure you have Python 3.10+ installed. Install the required Python packages:
```bash
pip install pymongo dnspython certifi fastapi uvicorn
```

### 2. Configure Database Credentials
Create a file named `config.json` in the root directory (this file is excluded from Git commits via `.gitignore` to secure your credentials). 

Paste your MongoDB Atlas connection string and replace `<db_password>` with your database user password:
```json
{
    "mongo_uri": "mongodb+srv://Ramtej:<YOUR_ACTUAL_PASSWORD>@cluster0.pd3naoj.mongodb.net/?appName=Cluster0"
}
```

*Note: You do **not** need to manually create any databases or collections in the MongoDB Atlas dashboard. Pymongo will automatically create `wardrobe_db` and the `wardrobes` collection the first time you save.*

---

## How to Run

### 1. Run the Local CLI Application
Launch the console menu interface:
```bash
python main.py
```

### 2. Run the FastAPI Web Server
Start the local development server:
```bash
uvicorn app:app --reload
```
- Access the API at: `http://127.0.0.1:8000/`
- Open the interactive Swagger API Docs playground: **`http://127.0.0.1:8000/docs`**

---

## Running Verification Tests

The repository contains two automated test suites:

### Test Python Core & DB Persistence
```bash
python verify_wardrobe.py
```

### Test FastAPI Web Endpoints
```bash
python verify_api.py
```
*(Both scripts use a temporary `"test_wardrobe"` document in the database and automatically clean up after execution).*