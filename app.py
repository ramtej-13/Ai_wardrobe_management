import os
import uuid
import shutil
from fastapi import FastAPI, HTTPException, status, File, UploadFile, Request
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional, List, Dict
from user import User
from wardrobe_item import WardrobeItem
from wardrobe import Wardrobe
from storage import save_wardrobe, load_wardrobe

app = FastAPI(
    title="AI Wardrobe Management API",
    description="Web REST API to manage user profiles, catalog wardrobe items, search, and count items using MongoDB Atlas.",
    version="1.0.0"
)

# Mount static files directory to serve uploaded images via web URLs
os.makedirs(os.path.join("static", "uploads"), exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Document identifier constant
DB_IDENTIFIER = "active_wardrobe"

# Pydantic Schemas for Request Validation
class UserSchema(BaseModel):
    name: str
    age: int
    gender: str
    height: float
    weight: float

class ItemCreateSchema(BaseModel):
    name: str
    category: str
    color: str
    description: Optional[str] = ""
    image_path: Optional[str] = None
    date_added: Optional[str] = None

class ItemEditSchema(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    color: Optional[str] = None
    description: Optional[str] = None
    image_path: Optional[str] = None
    date_added: Optional[str] = None


# Helpers
def get_wardrobe_or_error(enforce_user: bool = True) -> Wardrobe:
    """Helper to load wardrobe from DB. Raises 400 or 404 errors if state is invalid."""
    wardrobe = load_wardrobe(DB_IDENTIFIER)
    if not wardrobe:
        if enforce_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Wardrobe does not exist. Please create a user profile first via POST /user."
            )
        # If user is not enforced, return empty wardrobe wrapper
        return Wardrobe(user=None)
        
    if enforce_user and not wardrobe.user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User profile is missing. Please create a user profile first via POST /user."
        )
    return wardrobe


# Endpoints
@app.get("/", tags=["System"])
def root():
    """Health check and API overview."""
    # Attempt to load to check database connection
    try:
        wardrobe = load_wardrobe(DB_IDENTIFIER)
        db_connected = True
        has_profile = wardrobe is not None and wardrobe.user is not None
    except Exception:
        db_connected = False
        has_profile = False

    return {
        "status": "online",
        "database_connected": db_connected,
        "profile_created": has_profile,
        "message": "Welcome to the AI Wardrobe Management API! Navigate to /docs for interactive Swagger UI."
    }

@app.get("/user", response_model=UserSchema, tags=["User"])
def get_user_profile():
    """Retrieves the active user profile."""
    wardrobe = get_wardrobe_or_error(enforce_user=True)
    return wardrobe.user.to_dict()

@app.post("/user", status_code=status.HTTP_201_CREATED, tags=["User"])
def create_or_update_user_profile(user_data: UserSchema):
    """Creates a new user profile or updates the existing one."""
    # Try to load existing wardrobe, otherwise create a fresh one
    wardrobe = load_wardrobe(DB_IDENTIFIER)
    new_user = User(
        name=user_data.name,
        age=user_data.age,
        gender=user_data.gender,
        height=user_data.height,
        weight=user_data.weight
    )
    
    if not wardrobe:
        wardrobe = Wardrobe(new_user)
    else:
        wardrobe.user = new_user

    # Save immediately to MongoDB Atlas
    success = save_wardrobe(wardrobe, DB_IDENTIFIER)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save user profile to database."
        )
        
    return {"message": "User profile successfully saved!", "user": wardrobe.user.to_dict()}

@app.get("/items", tags=["Wardrobe Items"])
def get_all_wardrobe_items():
    """Retrieves all wardrobe items, category counts, and profile summary."""
    wardrobe = get_wardrobe_or_error(enforce_user=True)
    return {
        "user_name": wardrobe.user.name,
        "total_items": len(wardrobe.get_all_items()),
        "category_counts": wardrobe.get_category_counts(),
        "items": [item.to_dict() for item in wardrobe.get_all_items()]
    }

@app.post("/items", status_code=status.HTTP_201_CREATED, tags=["Wardrobe Items"])
def add_wardrobe_item(item_data: ItemCreateSchema):
    """Adds a new wardrobe item and automatically saves it to MongoDB Atlas."""
    wardrobe = get_wardrobe_or_error(enforce_user=True)
    
    new_item = wardrobe.add_item(
        name=item_data.name,
        category=item_data.category,
        color=item_data.color,
        description=item_data.description,
        image_path=item_data.image_path,
        date_added=item_data.date_added
    )
    
    success = save_wardrobe(wardrobe, DB_IDENTIFIER)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to add wardrobe item to database."
        )
        
    return {"message": "Item added successfully!", "item": new_item.to_dict()}

@app.put("/items/{item_id}", tags=["Wardrobe Items"])
def edit_wardrobe_item(item_id: str, edit_data: ItemEditSchema):
    """Edits an existing wardrobe item by its unique ID (e.g. C001)."""
    wardrobe = get_wardrobe_or_error(enforce_user=True)
    
    # Check if item exists
    item = wardrobe.find_item_by_id(item_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Wardrobe item with ID '{item_id}' not found."
        )
        
    # Update fields
    wardrobe.edit_item(
        item_id=item_id,
        name=edit_data.name,
        category=edit_data.category,
        color=edit_data.color,
        description=edit_data.description,
        image_path=edit_data.image_path,
        date_added=edit_data.date_added
    )
    
    success = save_wardrobe(wardrobe, DB_IDENTIFIER)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save edits to database."
        )
        
    return {"message": "Item updated successfully!", "item": wardrobe.find_item_by_id(item_id).to_dict()}

@app.delete("/items/{item_id}", tags=["Wardrobe Items"])
def delete_wardrobe_item(item_id: str):
    """Removes a wardrobe item from the database by its unique ID."""
    wardrobe = get_wardrobe_or_error(enforce_user=True)
    
    # Check if item exists
    item = wardrobe.find_item_by_id(item_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Wardrobe item with ID '{item_id}' not found."
        )
        
    wardrobe.remove_item(item_id)
    
    success = save_wardrobe(wardrobe, DB_IDENTIFIER)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete wardrobe item from database."
        )
        
    return {"message": f"Item '{item_id}' successfully removed from wardrobe!"}

@app.get("/items/search", tags=["Wardrobe Items"])
def search_wardrobe_items(q: str):
    """Searches wardrobe items matching the query text (case-insensitive)."""
    wardrobe = get_wardrobe_or_error(enforce_user=True)
    results = wardrobe.search_items(q)
    return {
        "query": q,
        "matches_count": len(results),
        "results": [item.to_dict() for item in results]
    }

@app.post("/items/upload", tags=["Wardrobe Items"])
def upload_wardrobe_item_image(request: Request, file: UploadFile = File(...)):
    """
    Uploads an image file (JPEG, PNG, WEBP) to the server.
    Returns the dynamic web URL where the image is served.
    """
    # 1. Validate file extension
    original_filename = file.filename
    ext = original_filename.split(".")[-1].lower() if "." in original_filename else ""
    if ext not in ["jpg", "jpeg", "png", "webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file format. Only JPG, JPEG, PNG, and WEBP image formats are allowed."
        )

    # 2. Generate a secure, unique filename to avoid collision
    unique_filename = f"{uuid.uuid4()}.{ext}"
    upload_dir = os.path.join("static", "uploads")
    file_path = os.path.join(upload_dir, unique_filename)

    # 3. Save the file to the local uploads directory
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred while saving the file: {str(e)}"
        )

    # 4. Generate the dynamic public URL
    base_url = str(request.base_url)
    image_url = f"{base_url}static/uploads/{unique_filename}"

    return {
        "message": "Image uploaded successfully!",
        "image_url": image_url,
        "filename": unique_filename
    }

