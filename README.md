# AI Wardrobe Management System

A Python-based CLI application to manage a user profile and an automated clothing and footwear wardrobe, powered by **MongoDB Atlas** for secure, cloud-based data persistence.

---

## Features

- **User Profile Management**: Store and retrieve user details (Name, Age, Gender, Height, Weight).
- **Wardrobe Item Cataloging**: Add items (e.g. Shirts, Pants, Shoes, Accessories) with automatic sequential unique ID generation (`C001`, `C002`, etc.), categories, colors, descriptions, dates, and optional image paths.
- **Smart Category Count**: Live counter showing items grouped by category (e.g. `Shirts: 5`, `Pants: 3`, `Shoes: 2`).
- **Flexible Searching**: Perform case-insensitive search across names, categories, colors, or descriptions.
- **Cloud Persistence**: Full integration with **MongoDB Atlas** using the `pymongo` library, allowing you to load and save your wardrobe securely in the cloud under a generalized `"items"` database array.
- **Colorized Interactive Menu**: Aesthetic, user-friendly CLI terminal interface with clear headers and layouts.
- **Integrated Test Suite**: Quick-run verification script testing all modules and database integration.

---

## File Structure

The project is modularized into dedicated, separate Python files:

```text
├── user.py              # User class and deserialization methods
├── wardrobe_item.py     # WardrobeItem class representing single wardrobe items
├── wardrobe.py          # Wardrobe collection and count/search logic
├── storage.py           # MongoDB connection utility and load/save functions
├── main.py              # Application entrypoint hosting the interactive CLI
├── verify_wardrobe.py   # Automated integration test suite
├── config.json          # Credentials configuration (Git-ignored)
└── README.md            # Project documentation (this file)
```

---

## Installation & Setup

### 1. Install Dependencies
Make sure you have Python 3.10+ installed. Install the required Python packages:
```bash
pip install pymongo dnspython certifi
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

### Run the Application CLI
Launch the main application interface:
```bash
python main.py
```
On your first run, the system will recognize there is no existing database document and will guide you to create your user profile. Subsequent runs will load your profile and wardrobe catalog automatically from the cloud.

### Run Verification Tests
To run the automated test suite and confirm that your database connection and operations work successfully:
```bash
python verify_wardrobe.py
```
This script runs operations under a separate `test_wardrobe` document and automatically deletes it afterwards to keep your database clean.