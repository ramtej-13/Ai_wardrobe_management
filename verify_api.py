from fastapi.testclient import TestClient
import app  # import our app module
from storage import get_mongo_client

# Override the database identifier to prevent polluting the active wardrobe
app.DB_IDENTIFIER = "test_wardrobe"

client = TestClient(app.app)

def run_api_tests():
    print("=== STARTING FASTAPI ENDPOINT TESTS ===")

    # 0. Pre-clean test document in MongoDB Atlas
    print("\n0. Pre-cleaning test document...")
    mongo_client = get_mongo_client()
    db = mongo_client["wardrobe_db"]
    collection = db["wardrobes"]
    collection.delete_one({"_id": "test_wardrobe"})
    mongo_client.close()
    print("Test document cleared.")

    # 1. Test root health check
    print("\n1. Testing Root Health Check...")
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "online"
    assert data["database_connected"] is True
    print("Root health check passed successfully.")

    # 2. Test GET /user before profile is created (should fail with 400 Bad Request)
    print("\n2. Testing GET /user (Pre-profile)...")
    response = client.get("/user")
    assert response.status_code == 400
    assert "Please create a user profile first" in response.json()["detail"]
    print("GET /user pre-profile check passed (properly blocked).")

    # 3. Test POST /user (Create profile)
    print("\n3. Testing POST /user (Create Profile)...")
    user_payload = {
        "name": "Sarah Connor",
        "age": 35,
        "gender": "Female",
        "height": 168.0,
        "weight": 58.5
    }
    response = client.post("/user", json=user_payload)
    assert response.status_code == 201
    res_data = response.json()
    assert res_data["user"]["name"] == "Sarah Connor"
    print("POST /user profile creation passed.")

    # 4. Test GET /user (Post-profile)
    print("\n4. Testing GET /user (Post-profile)...")
    response = client.get("/user")
    assert response.status_code == 200
    assert response.json()["name"] == "Sarah Connor"
    print("GET /user profile retrieval passed.")

    # 5. Test POST /items (Add first item)
    print("\n5. Testing POST /items (Add Item 1)...")
    item1_payload = {
        "name": "White Shirt",
        "category": "Shirt",
        "color": "White",
        "description": "Formal oxford cotton shirt",
        "date_added": "2026-06-20"
    }
    response = client.post("/items", json=item1_payload)
    assert response.status_code == 201
    res_data = response.json()
    assert res_data["item"]["id"] == "C001"
    assert res_data["item"]["name"] == "White Shirt"
    print("Item 1 (C001) added successfully.")

    # 6. Test POST /items (Add second item)
    print("\n6. Testing POST /items (Add Item 2)...")
    item2_payload = {
        "name": "Black Sneakers",
        "category": "Shoes",
        "color": "Black",
        "description": "Running sneakers",
        "date_added": "2026-06-21"
    }
    response = client.post("/items", json=item2_payload)
    assert response.status_code == 201
    res_data = response.json()
    assert res_data["item"]["id"] == "C002"
    assert res_data["item"]["name"] == "Black Sneakers"
    print("Item 2 (C002) added successfully.")

    # 7. Test GET /items (View Wardrobe)
    print("\n7. Testing GET /items (View Wardrobe)...")
    response = client.get("/items")
    assert response.status_code == 200
    res_data = response.json()
    assert res_data["total_items"] == 2
    assert res_data["category_counts"]["Shirt"] == 1
    assert res_data["category_counts"]["Shoes"] == 1
    assert len(res_data["items"]) == 2
    print("GET /items wardrobe view passed.")

    # 7a. Test GET /wardrobe (Dashboard Grouped by Category)
    print("\n7a. Testing GET /wardrobe (Grouped Category Dashboard)...")
    response = client.get("/wardrobe")
    assert response.status_code == 200
    res_data = response.json()
    assert "Shirt" in res_data
    assert "Shoes" in res_data
    assert len(res_data["Shirt"]) == 1
    assert len(res_data["Shoes"]) == 1
    assert res_data["Shirt"][0]["id"] == "C001"
    assert res_data["Shoes"][0]["id"] == "C002"
    print("GET /wardrobe category grouping dashboard verified successfully.")

    # 7b. Test GET /wardrobe/analytics (Wardrobe Analytics)
    print("\n7b. Testing GET /wardrobe/analytics...")
    response = client.get("/wardrobe/analytics")
    assert response.status_code == 200
    res_data = response.json()
    assert res_data["total_items"] == 2
    assert res_data["category_counts"]["Shirt"] == 1
    assert res_data["category_counts"]["Shoes"] == 1
    assert res_data["most_common_color"] in ["White", "Black"]
    print("GET /wardrobe/analytics successfully verified.")

    # 8. Test GET /items/search (Search query)
    print("\n8. Testing GET /items/search...")
    response = client.get("/items/search?q=White")
    assert response.status_code == 200
    res_data = response.json()
    assert res_data["matches_count"] == 1
    assert res_data["results"][0]["name"] == "White Shirt"
    print("Search query verification passed.")

    # 9. Test PUT /items/{item_id} (Edit item details)
    print("\n9. Testing PUT /items/{item_id} (Edit Item)...")
    edit_payload = {
        "color": "Off-White",
        "description": "Super-formal linen shirt"
    }
    response = client.put("/items/C001", json=edit_payload)
    assert response.status_code == 200
    res_data = response.json()
    assert res_data["item"]["color"] == "Off-White"
    assert res_data["item"]["description"] == "Super-formal linen shirt"
    # Verify name was not modified
    assert res_data["item"]["name"] == "White Shirt"
    print("Item editing verification passed.")

    # 10. Test DELETE /items/{item_id} (Delete item)
    print("\n10. Testing DELETE /items/{item_id}...")
    response = client.delete("/items/C002")
    assert response.status_code == 200
    print("Item C002 deleted successfully.")

    # 11. Verify deletion in /items count
    print("\n11. Verifying deletion count...")
    response = client.get("/items")
    assert response.status_code == 200
    res_data = response.json()
    assert res_data["total_items"] == 1
    assert "Shoes" not in res_data["category_counts"]
    print("Item deletion check passed.")

    # 12. Test POST /items/upload (Image Upload & static serving)
    print("\n12. Testing Image Upload Endpoint...")
    import os
    
    # Mock file bytes and metadata
    file_payload = {"file": ("test_pic.png", b"fake_image_bytes_here", "image/png")}
    response = client.post("/items/upload", files=file_payload)
    assert response.status_code == 200
    res_data = response.json()
    assert "image_url" in res_data
    assert "filename" in res_data
    
    filename = res_data["filename"]
    local_path = os.path.join("static", "uploads", filename)
    
    # Assert file exists on disk
    assert os.path.exists(local_path)
    print(f"File successfully created locally at: {local_path}")
    
    # Assert static file routing works via test client
    static_response = client.get(f"/static/uploads/{filename}")
    assert static_response.status_code == 200
    assert static_response.content == b"fake_image_bytes_here"
    print("Static file serving verified.")
    
    # Cleanup physical file on disk
    os.remove(local_path)
    assert not os.path.exists(local_path)
    print("Local test file cleaned up from static folder.")

    # 13. Test POST /items/analyze (Gemini Vision integration)
    print("\n13. Testing Image Analysis Endpoint (Gemini Integration)...")
    from io import BytesIO
    from PIL import Image
    
    # Generate 100x100 solid red image in memory
    img = Image.new("RGB", (100, 100), color="red")
    img_byte_arr = BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_bytes = img_byte_arr.getvalue()
    
    file_payload = {"file": ("red_shirt_test.jpg", img_bytes, "image/jpeg")}
    response = client.post("/items/analyze", files=file_payload)
    assert response.status_code == 200
    res_data = response.json()
    
    assert "category" in res_data
    assert "color" in res_data
    assert "description" in res_data
    assert "image_path" in res_data
    
    # Print the analysis results for logging
    print("Gemini image analysis returned:")
    print(f"  Category: {res_data['category']}")
    print(f"  Color: {res_data['color']}")
    print(f"  Description: {res_data['description']}")
    print(f"  Image Path: {res_data['image_path']}")
    
    # Verify the image was saved on disk and can be retrieved, then cleanup
    image_url = res_data["image_path"]
    filename = image_url.split("/")[-1]
    test_local_path = os.path.join("static", "uploads", filename)
    assert os.path.exists(test_local_path)
    os.remove(test_local_path)
    print("Analysis test file cleaned up from static folder.")

    # 14. Test POST /profile/analyze (Gemini profile analysis integration)
    print("\n14. Testing User Profile Photo Analysis (Gemini Multimodal)...")
    
    # Generate mock images in memory
    front_img = Image.new("RGB", (100, 100), color="blue")
    side_img = Image.new("RGB", (100, 100), color="green")
    face_img = Image.new("RGB", (100, 100), color="pink")
    
    front_bytes = BytesIO()
    front_img.save(front_bytes, format='JPEG')
    front_data = front_bytes.getvalue()
    
    side_bytes = BytesIO()
    side_img.save(side_bytes, format='JPEG')
    side_data = side_bytes.getvalue()
    
    face_bytes = BytesIO()
    face_img.save(face_bytes, format='JPEG')
    face_data = face_bytes.getvalue()
    
    profile_payload = {
        "front_image": ("front_body.jpg", front_data, "image/jpeg"),
        "side_image": ("side_body.jpg", side_data, "image/jpeg"),
        "face_image": ("face.jpg", face_data, "image/jpeg")
    }
    
    response = client.post("/profile/analyze", files=profile_payload)
    assert response.status_code == 200
    res_data = response.json()
    
    assert "body_type" in res_data
    assert "body_build" in res_data
    assert "skin_tone" in res_data
    assert "undertone" in res_data
    assert "hair_color" in res_data
    assert "face_shape" in res_data
    assert "facial_hair" in res_data
    assert "estimated_height" in res_data
    
    print("Gemini profile analysis returned:")
    print(f"  Body Type: {res_data['body_type']}")
    print(f"  Body Build: {res_data['body_build']}")
    print(f"  Skin Tone: {res_data['skin_tone']}")
    print(f"  Undertone: {res_data['undertone']}")
    print(f"  Hair Color: {res_data['hair_color']}")
    print(f"  Face Shape: {res_data['face_shape']}")
    print(f"  Facial Hair: {res_data['facial_hair']}")
    print(f"  Estimated Height: {res_data['estimated_height']}")
    print("Profile photo analysis verified successfully.")

    # 15. Test POST /user and GET /user with detailed AI profile attributes
    print("\n15. Testing Profile Saving & Loading with AI Attributes...")
    detailed_user_payload = {
        "name": "John Connor",
        "age": 15,
        "gender": "Male",
        "height": 160.0,
        "weight": 52.0,
        "location": "Los Angeles",
        "budget": "Mid",
        "preferred_style": "Casual/Streetwear",
        "occupation": "Student",
        "body_type": res_data['body_type'],
        "body_build": res_data['body_build'],
        "skin_tone": res_data['skin_tone'],
        "undertone": res_data['undertone'],
        "hair_color": res_data['hair_color'],
        "face_shape": res_data['face_shape'],
        "facial_hair": res_data['facial_hair'],
        "estimated_height": res_data['estimated_height']
    }
    # Update profile
    response = client.post("/user", json=detailed_user_payload)
    assert response.status_code == 201
    
    # Retrieve profile
    response = client.get("/user")
    assert response.status_code == 200
    retrieved_user = response.json()
    assert retrieved_user["name"] == "John Connor"
    assert retrieved_user["location"] == "Los Angeles"
    assert retrieved_user["budget"] == "Mid"
    assert retrieved_user["preferred_style"] == "Casual/Streetwear"
    assert retrieved_user["occupation"] == "Student"
    assert retrieved_user["body_type"] == res_data['body_type']
    assert retrieved_user["body_build"] == res_data['body_build']
    assert retrieved_user["skin_tone"] == res_data['skin_tone']
    assert retrieved_user["undertone"] == res_data['undertone']
    assert retrieved_user["hair_color"] == res_data['hair_color']
    assert retrieved_user["face_shape"] == res_data['face_shape']
    assert retrieved_user["facial_hair"] == res_data['facial_hair']
    assert retrieved_user["estimated_height"] == res_data['estimated_height']
    print("Profile save and load with AI attributes verified successfully.")

    # 16. Cleanup database document
    print("\n16. Cleaning up database test document...")
    mongo_client = get_mongo_client()
    db = mongo_client["wardrobe_db"]
    collection = db["wardrobes"]
    collection.delete_one({"_id": "test_wardrobe"})
    mongo_client.close()
    print("Database test document successfully removed.")

    print("\n=== ALL FASTAPI ENDPOINT TESTS PASSED SUCCESSFULLY! ===")

if __name__ == "__main__":
    run_api_tests()
