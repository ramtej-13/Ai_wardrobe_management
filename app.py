import os
import uuid
import shutil
import json
from PIL import Image
import google.generativeai as genai
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

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
@app.middleware("http")
async def add_no_cache_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

# Mount static files directory to serve uploaded images via web URLs
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    print("\n--- FASTAPI VALIDATION ERROR DETAILS ---")
    print(f"Errors: {exc.errors()}")
    try:
        body = await request.body()
        print(f"Request Body: {body.decode('utf-8')}")
    except Exception:
        pass
    print("----------------------------------------\n")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors(), "body": str(exc.body)},
    )

os.makedirs(os.path.join("static", "uploads"), exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Load Gemini API key from config.json
CONFIG_FILE = "config.json"
gemini_key = None
if os.path.exists(CONFIG_FILE):
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            config = json.load(f)
            gemini_key = config.get("gemini_api_key")
    except Exception as e:
        print(f"Error reading Gemini key from config: {e}")

if gemini_key:
    genai.configure(api_key=gemini_key)

# Document identifier constant
DB_IDENTIFIER = "active_wardrobe"

# Pydantic Schemas for Request Validation
class UserSchema(BaseModel):
    name: str
    age: int
    gender: str
    height: float
    weight: float
    location: Optional[str] = ""
    budget: Optional[str] = ""
    preferred_style: Optional[str] = ""
    occupation: Optional[str] = None
    body_type: Optional[str] = None
    body_build: Optional[str] = None
    skin_tone: Optional[str] = None
    undertone: Optional[str] = None
    hair_color: Optional[str] = None
    face_shape: Optional[str] = None
    facial_hair: Optional[str] = None
    estimated_height: Optional[str] = None

class ItemCreateSchema(BaseModel):
    name: str
    category: str
    color: str
    description: Optional[str] = ""
    fit: Optional[str] = ""
    image_path: Optional[str] = None
    date_added: Optional[str] = None

class ItemEditSchema(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    color: Optional[str] = None
    description: Optional[str] = None
    fit: Optional[str] = None
    image_path: Optional[str] = None
    date_added: Optional[str] = None


class RecommendationRequest(BaseModel):
    occasion: str


# Helpers
def get_db_identifier(request: Request) -> str:
    """Extracts X-User-Email header to form a clean, isolated user DB document identifier."""
    email = request.headers.get("X-User-Email")
    print(f"[API HEADER CHECK] X-User-Email header value: '{email}'")
    if email:
        email = email.strip().lower()
        if not email.endswith("@gmail.com"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Authentication failed. Only Gmail (@gmail.com) accounts are permitted."
            )
        sanitized = email.replace("@", "_").replace(".", "_")
        return f"wardrobe_{sanitized}"
    return "active_wardrobe"

def get_wardrobe_or_error(db_id: str, enforce_user: bool = True) -> Wardrobe:
    """Helper to load wardrobe from DB. Raises 400 or 404 errors if state is invalid."""
    wardrobe = load_wardrobe(db_id)
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
def root(request: Request):
    """Health check and API overview."""
    db_id = get_db_identifier(request)
    # Attempt to load to check database connection
    try:
        wardrobe = load_wardrobe(db_id)
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
def get_user_profile(request: Request):
    """Retrieves the active user profile."""
    db_id = get_db_identifier(request)
    wardrobe = get_wardrobe_or_error(db_id, enforce_user=True)
    return wardrobe.user.to_dict()

@app.post("/user", status_code=status.HTTP_201_CREATED, tags=["User"])
def create_or_update_user_profile(request: Request, user_data: UserSchema):
    """Creates a new user profile or updates the existing one."""
    db_id = get_db_identifier(request)
    # Try to load existing wardrobe, otherwise create a fresh one
    wardrobe = load_wardrobe(db_id)
    new_user = User(
        name=user_data.name,
        age=user_data.age,
        gender=user_data.gender,
        height=user_data.height,
        weight=user_data.weight,
        location=user_data.location,
        budget=user_data.budget,
        preferred_style=user_data.preferred_style,
        occupation=user_data.occupation,
        body_type=user_data.body_type,
        body_build=user_data.body_build,
        skin_tone=user_data.skin_tone,
        undertone=user_data.undertone,
        hair_color=user_data.hair_color,
        face_shape=user_data.face_shape,
        facial_hair=user_data.facial_hair,
        estimated_height=user_data.estimated_height
    )
    
    if not wardrobe:
        wardrobe = Wardrobe(new_user)
    else:
        wardrobe.user = new_user

    # Save immediately to MongoDB Atlas
    success = save_wardrobe(wardrobe, db_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save user profile to database."
        )
        
    return {"message": "User profile successfully saved!", "user": wardrobe.user.to_dict()}

@app.get("/items", tags=["Wardrobe Items"])
def get_all_wardrobe_items(request: Request):
    """Retrieves all wardrobe items, category counts, and profile summary."""
    db_id = get_db_identifier(request)
    wardrobe = get_wardrobe_or_error(db_id, enforce_user=True)
    return {
        "user_name": wardrobe.user.name,
        "total_items": len(wardrobe.get_all_items()),
        "category_counts": wardrobe.get_category_counts(),
        "items": [item.to_dict() for item in wardrobe.get_all_items()]
    }

@app.post("/items", status_code=status.HTTP_201_CREATED, tags=["Wardrobe Items"])
def add_wardrobe_item(request: Request, item_data: ItemCreateSchema):
    """Adds a new wardrobe item and automatically saves it to MongoDB Atlas."""
    db_id = get_db_identifier(request)
    wardrobe = get_wardrobe_or_error(db_id, enforce_user=True)
    
    new_item = wardrobe.add_item(
        name=item_data.name,
        category=item_data.category,
        color=item_data.color,
        description=item_data.description,
        fit=item_data.fit,
        image_path=item_data.image_path,
        date_added=item_data.date_added
    )
    
    success = save_wardrobe(wardrobe, db_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to add wardrobe item to database."
        )
        
    return {"message": "Item added successfully!", "item": new_item.to_dict()}

@app.put("/items/{item_id}", tags=["Wardrobe Items"])
def edit_wardrobe_item(request: Request, item_id: str, edit_data: ItemEditSchema):
    """Edits an existing wardrobe item by its unique ID (e.g. C001)."""
    db_id = get_db_identifier(request)
    wardrobe = get_wardrobe_or_error(db_id, enforce_user=True)
    
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
        fit=edit_data.fit,
        image_path=edit_data.image_path,
        date_added=edit_data.date_added
    )
    
    success = save_wardrobe(wardrobe, db_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save edits to database."
        )
        
    return {"message": "Item updated successfully!", "item": wardrobe.find_item_by_id(item_id).to_dict()}

@app.delete("/items/{item_id}", tags=["Wardrobe Items"])
def delete_wardrobe_item(request: Request, item_id: str):
    """Removes a wardrobe item from the database by its unique ID."""
    db_id = get_db_identifier(request)
    wardrobe = get_wardrobe_or_error(db_id, enforce_user=True)
    
    # Check if item exists
    item = wardrobe.find_item_by_id(item_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Wardrobe item with ID '{item_id}' not found."
        )
        
    wardrobe.remove_item(item_id)
    
    success = save_wardrobe(wardrobe, db_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete wardrobe item from database."
        )
        
    return {"message": f"Item '{item_id}' successfully removed from wardrobe!"}

@app.get("/items/search", tags=["Wardrobe Items"])
def search_wardrobe_items(request: Request, q: str):
    """Searches wardrobe items matching the query text (case-insensitive)."""
    db_id = get_db_identifier(request)
    wardrobe = get_wardrobe_or_error(db_id, enforce_user=True)
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


def parse_gemini_json(text: str) -> dict:
    import re
    cleaned = text.strip()
    if cleaned.startswith("```"):
        match = re.search(r"```(?:json)?\s*(.*?)\s*```", cleaned, re.DOTALL)
        if match:
            cleaned = match.group(1).strip()
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        raise ValueError(f"Failed to parse JSON from Gemini response: {text}")


def get_nested_attribute(data: dict, key: str) -> dict:
    val = data.get(key)
    if isinstance(val, dict):
        return {
            "value": val.get("value") or "",
            "confidence": float(val.get("confidence")) if val.get("confidence") is not None else 0.0
        }
    return {"value": val or "", "confidence": 0.0}


@app.post("/items/analyze", tags=["Wardrobe Items"])
def analyze_wardrobe_item_image(request: Request, file: UploadFile = File(...)):
    """
    Uploads an image file, saves it, runs it through Gemini 2.5 Flash to automatically
    detect Category, Color, and a detailed Description, and returns these details.
    """
    # 1. Ensure Gemini is configured
    global gemini_key
    if not gemini_key:
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    config = json.load(f)
                    gemini_key = config.get("gemini_api_key")
            except Exception as e:
                print(f"Error reading Gemini key from config: {e}")
        if gemini_key:
            genai.configure(api_key=gemini_key)

    if not gemini_key:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Gemini API Key is not configured in config.json. Please add your key first."
        )

    # 2. Validate file extension
    original_filename = file.filename
    ext = original_filename.split(".")[-1].lower() if "." in original_filename else ""
    if ext not in ["jpg", "jpeg", "png", "webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file format. Only JPG, JPEG, PNG, and WEBP image formats are allowed."
        )

    # 3. Generate a secure, unique filename to avoid collision
    unique_filename = f"{uuid.uuid4()}.{ext}"
    upload_dir = os.path.join("static", "uploads")
    file_path = os.path.join(upload_dir, unique_filename)

    # 4. Save the file to the local uploads directory
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred while saving the file: {str(e)}"
        )

    # 5. Use Gemini to analyze the image
    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        with Image.open(file_path) as img:
            prompt = (
                "Analyze the uploaded wardrobe item image. "
                "Return a JSON object where each field contains a 'value' (the detected string) "
                "and a 'confidence' (an estimated confidence score as a decimal between 0.0 and 1.0, e.g., 0.95). "
                "The fields to return are:\n"
                "- 'category' (e.g. Shirt, Pants, Shoes, Dress, Jacket, Accessory)\n"
                "- 'color' (primary color)\n"
                "- 'description' (a detailed fashion-oriented description describing fabric, pattern, and sleeve type if applicable)\n"
                "- 'fit' (e.g. Slim, Regular, Loose, Oversized, Tailored)\n\n"
                "Keep the JSON clean and do not wrap it in markdown tags."
            )
            response = model.generate_content([prompt, img])
        analysis = parse_gemini_json(response.text)
    except Exception as e:
        if os.path.exists(file_path):
            try:
                os.remove(file_path)
            except Exception:
                pass
        err_msg = str(e)
        if "429" in err_msg or "ResourceExhausted" in err_msg or "quota" in err_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Gemini API rate limit exceeded (Free tier allows 5 requests/minute). Please wait a few seconds before trying again."
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gemini image analysis failed: {err_msg}"
        )

    # 6. Generate the dynamic public URL
    base_url = str(request.base_url)
    image_url = f"{base_url}static/uploads/{unique_filename}"

    return {
        "category": get_nested_attribute(analysis, "category"),
        "color": get_nested_attribute(analysis, "color"),
        "description": get_nested_attribute(analysis, "description"),
        "fit": get_nested_attribute(analysis, "fit"),
        "image_path": image_url
    }


@app.get("/wardrobe", tags=["Wardrobe Items"])
def get_wardrobe_dashboard(request: Request):
    """
    Retrieves all wardrobe items grouped by their categories.
    """
    db_id = get_db_identifier(request)
    wardrobe = get_wardrobe_or_error(db_id, enforce_user=True)
    grouped = {}
    for item in wardrobe.get_all_items():
        cat = item.category.strip().capitalize() if item.category else "Uncategorized"
        if cat not in grouped:
            grouped[cat] = []
        grouped[cat].append(item.to_dict())
    return grouped


@app.get("/wardrobe/analytics", tags=["Wardrobe Items"])
def get_wardrobe_analytics(request: Request):
    """
    Calculates wardrobe analytics: total clothes, category breakdown, and most common color.
    """
    db_id = get_db_identifier(request)
    wardrobe = get_wardrobe_or_error(db_id, enforce_user=True)
    items = wardrobe.get_all_items()
    total_items = len(items)
    
    category_counts = wardrobe.get_category_counts()
    
    # Calculate most common color
    color_counts = {}
    for item in items:
        if item.color:
            color = item.color.strip().capitalize()
            color_counts[color] = color_counts.get(color, 0) + 1
            
    most_common_color = None
    if color_counts:
        most_common_color = max(color_counts, key=color_counts.get)
        
    return {
        "total_items": total_items,
        "category_counts": category_counts,
        "most_common_color": most_common_color
    }


@app.post("/profile/analyze", tags=["User"])
def analyze_user_profile_photos(
    request: Request,
    front_image: UploadFile = File(...),
    side_image: UploadFile = File(...),
    face_image: UploadFile = File(...)
):
    """
    Uploads front full body, side full body, and face images.
    Uses Gemini 2.5 Flash to analyze the images and return the detected
    body type, skin tone, undertone, and hair color as structured JSON.
    """
    # 1. Ensure Gemini is configured
    global gemini_key
    if not gemini_key:
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    config = json.load(f)
                    gemini_key = config.get("gemini_api_key")
            except Exception as e:
                print(f"Error reading Gemini key from config: {e}")
        if gemini_key:
            genai.configure(api_key=gemini_key)

    if not gemini_key:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Gemini API Key is not configured in config.json. Please add your key first."
        )

    # 2. Validate file extensions
    images = {
        "front_image": front_image,
        "side_image": side_image,
        "face_image": face_image
    }
    saved_paths = []

    for name, file in images.items():
        original_filename = file.filename
        ext = original_filename.split(".")[-1].lower() if "." in original_filename else ""
        if ext not in ["jpg", "jpeg", "png", "webp"]:
            # Clean up already saved files
            for path in saved_paths:
                if os.path.exists(path):
                    try:
                        os.remove(path)
                    except Exception:
                        pass
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported format for {name}. Only JPG, JPEG, PNG, and WEBP formats are allowed."
            )

        unique_filename = f"{uuid.uuid4()}.{ext}"
        upload_dir = os.path.join("static", "uploads")
        file_path = os.path.join(upload_dir, unique_filename)
        saved_paths.append(file_path)

        try:
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
        except Exception as e:
            # Clean up already saved files
            for path in saved_paths:
                if os.path.exists(path):
                    try:
                        os.remove(path)
                    except Exception:
                        pass
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"An error occurred while saving {name}: {str(e)}"
            )

    # 3. Use Gemini to analyze the images
    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        with Image.open(saved_paths[0]) as front_img, \
             Image.open(saved_paths[1]) as side_img, \
             Image.open(saved_paths[2]) as face_img:
            
            prompt = (
                "You are a professional fashion and styling assistant. Analyze the three uploaded photos of a user: "
                "1. A front full-body photo, 2. A side full-body photo, and 3. A face photo. "
                "Determine the user's physical attributes. "
                "Return a JSON object where each attribute contains a 'value' (the detected string) and "
                "a 'confidence' (an estimated confidence score as a decimal between 0.0 and 1.0, e.g., 0.92). "
                "The attributes to detect are:\n"
                "- 'body_type' (e.g., Hourglass, Pear, Rectangle, Inverted Triangle, Athletic, Oval)\n"
                "- 'body_build' (e.g., Slim, Average, Athletic, Muscular, Heavy)\n"
                "- 'skin_tone' (e.g., Fair, Light, Medium, Olive, Tan, Dark, Deep)\n"
                "- 'undertone' (Warm, Cool, Neutral)\n"
                "- 'hair_color' (e.g., Black, Brown, Blonde, Red, Grey, White)\n"
                "- 'face_shape' (e.g., Oval, Round, Square, Heart, Diamond)\n"
                "- 'facial_hair' (e.g., Beard, Mustache, Clean Shaven, stubble)\n"
                "- 'estimated_height' (e.g., 170-175 cm)\n\n"
                "Keep the JSON clean, do not wrap it in markdown formatting, and only return the JSON object."
            )
            response = model.generate_content([prompt, front_img, side_img, face_img])
        
        analysis = parse_gemini_json(response.text)
    except Exception as e:
        err_msg = str(e)
        if "429" in err_msg or "ResourceExhausted" in err_msg or "quota" in err_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Gemini API rate limit exceeded. Please wait a few seconds before trying again."
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gemini profile analysis failed: {err_msg}"
        )
    finally:
        # Clean up temporary saved files on disk
        for path in saved_paths:
            if os.path.exists(path):
                try:
                    os.remove(path)
                except Exception:
                    pass

    return {
        "body_type": get_nested_attribute(analysis, "body_type"),
        "body_build": get_nested_attribute(analysis, "body_build"),
        "skin_tone": get_nested_attribute(analysis, "skin_tone"),
        "undertone": get_nested_attribute(analysis, "undertone"),
        "hair_color": get_nested_attribute(analysis, "hair_color"),
        "face_shape": get_nested_attribute(analysis, "face_shape"),
        "facial_hair": get_nested_attribute(analysis, "facial_hair"),
        "estimated_height": get_nested_attribute(analysis, "estimated_height")
    }


@app.post("/recommend", tags=["Outfit Recommendations"])
def recommend_outfit(request: Request, req: RecommendationRequest):
    """
    Recommends a styled outfit (top, bottom, shoes) from the user's wardrobe items
    matching the user's physical profile characteristics and a target occasion.
    """
    db_id = get_db_identifier(request)
    # 1. Load active wardrobe and verify user profile exists
    wardrobe = load_wardrobe(db_id)
    if not wardrobe or not wardrobe.user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User profile has not been created yet. Please set up a user profile first."
        )

    # 2. Check that the wardrobe contains items
    if not wardrobe.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Your wardrobe is empty. Please add some items to your wardrobe first."
        )

    # 3. Securely check and configure Gemini API key
    global gemini_key
    if not gemini_key:
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    config = json.load(f)
                    gemini_key = config.get("gemini_api_key")
            except Exception as e:
                print(f"Error reading Gemini key: {e}")
        if gemini_key:
            genai.configure(api_key=gemini_key)

    if not gemini_key:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Gemini API Key is not configured. Please add your key first."
        )

    # 4. Format user profile context
    user = wardrobe.user
    profile_summary = (
        f"Gender: {user.gender}, Age: {user.age}, Preferred Style: {user.preferred_style or 'Not specified'}, "
        f"Location: {user.location or 'Not specified'}, Budget: {user.budget or 'Not specified'}, "
        f"Occupation: {user.occupation or 'Not specified'}. "
        f"AI Physical Profile: Body Type: {user.body_type or 'Unknown'}, Body Build: {user.body_build or 'Unknown'}, "
        f"Skin Tone: {user.skin_tone or 'Unknown'}, Undertone: {user.undertone or 'Unknown'}, "
        f"Hair Color: {user.hair_color or 'Unknown'}, Face Shape: {user.face_shape or 'Unknown'}, "
        f"Facial Hair: {user.facial_hair or 'Unknown'}, Height: {user.estimated_height or 'Unknown'}."
    )

    # 5. Format items list context
    items_list = []
    for item in wardrobe.items:
        items_list.append({
            "id": item.id,
            "name": item.name,
            "category": item.category,
            "color": item.color,
            "description": item.description,
            "fit": item.fit
        })

    # 6. Call Gemini model for styling recommendation
    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        prompt = (
            "You are a professional fashion stylist. Your task is to recommend a styled outfit combining "
            "exactly one top (e.g. Shirt, T-shirt, Sweatshirt, Jacket), one bottom (e.g. Pants, Cargo, Jeans, Shorts, Skirt), "
            "and one shoes item from the user's actual wardrobe items. You must choose items ONLY from the provided list.\n\n"
            f"User Profile Summary:\n{profile_summary}\n\n"
            f"Target Occasion: {req.occasion}\n\n"
            f"User's Wardrobe Items:\n{json.dumps(items_list, indent=2)}\n\n"
            "Rules:\n"
            "1. Select items that make the most cohesive, color-harmonious, and occasion-appropriate outfit.\n"
            "2. Under 'reason', provide bullet points describing how the selections match the occasion, the user's styling preferences, physical features (e.g., skin undertone, body type), and garment fits (e.g., pairing slim-fit items with relaxed-fit items appropriately).\n"
            "3. Only select from existing items. If no items match a category (e.g., no shoes are in the wardrobe), return null for that category ID.\n\n"
            "Return a JSON object in this format:\n"
            "{\n"
            "  \"top_id\": \"selected_top_item_id_or_null\",\n"
            "  \"bottom_id\": \"selected_bottom_item_id_or_null\",\n"
            "  \"shoes_id\": \"selected_shoes_item_id_or_null\",\n"
            "  \"reason\": \"• Bullet point 1\\n• Bullet point 2\"\n"
            "}\n\n"
            "Do not return markdown tags, return only the raw JSON object."
        )
        response = model.generate_content(prompt)
        rec_data = parse_gemini_json(response.text)
    except Exception as e:
        err_msg = str(e)
        if "429" in err_msg or "ResourceExhausted" in err_msg or "quota" in err_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Gemini API rate limit exceeded. Please wait a few seconds before trying again."
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Recommendation engine failed: {err_msg}"
        )

    # 7. Map recommended IDs back to complete items
    top_item = wardrobe.find_item_by_id(rec_data.get("top_id")) if rec_data.get("top_id") else None
    bottom_item = wardrobe.find_item_by_id(rec_data.get("bottom_id")) if rec_data.get("bottom_id") else None
    shoes_item = wardrobe.find_item_by_id(rec_data.get("shoes_id")) if rec_data.get("shoes_id") else None

    # Helper serializer
    def serialize_item(item_id, item_obj):
        if not item_obj:
            return None
        return {
            "id": item_id,
            "name": item_obj.name,
            "category": item_obj.category,
            "color": item_obj.color,
            "description": item_obj.description,
            "fit": item_obj.fit,
            "image_path": item_obj.image_path,
            "date_added": item_obj.date_added
        }

    return {
        "top": serialize_item(rec_data.get("top_id"), top_item),
        "bottom": serialize_item(rec_data.get("bottom_id"), bottom_item),
        "shoes": serialize_item(rec_data.get("shoes_id"), shoes_item),
        "reason": rec_data.get("reason") or "No reason provided."
    }


