import os
from user import User
from wardrobe_item import WardrobeItem
from wardrobe import Wardrobe
from storage import save_wardrobe, load_wardrobe

def run_tests():
    print("=== STARTING WARDROBE VERIFICATION TESTS ===")
    
    # 1. Create User
    print("\n1. Testing User Creation...")
    user = User("Alex Mercer", 28, "Non-Binary", 175.5, 68.2)
    assert user.name == "Alex Mercer"
    assert user.age == 28
    assert user.gender == "Non-Binary"
    assert user.height == 175.5
    assert user.weight == 68.2
    print("User profile created successfully.")
    
    # 2. Create Wardrobe & Add Items
    print("\n2. Testing Wardrobe Creation and Add Item...")
    wardrobe = Wardrobe(user)
    
    # Add identical items to test unique IDs
    c1 = wardrobe.add_item("White Shirt", "Shirt", "White", "Formal shirt", None, "2026-06-01")
    c2 = wardrobe.add_item("White Shirt", "Shirt", "White", "Casual linen shirt", "C:/images/white_shirt_2.png", "2026-06-10")
    c3 = wardrobe.add_item("Blue Jeans", "Pants", "Blue", "Slim fit denim", None, "2026-06-12")
    c4 = wardrobe.add_item("Black Sneakers", "Shoes", "Black", "Running shoes", "C:/images/sneakers.png", "2026-06-14")
    
    print(f"Added items: {[c.name for c in wardrobe.get_all_items()]}")
    
    # Check IDs
    print(f"Item 1 ID: {c1.id} (Expected C001)")
    print(f"Item 2 ID: {c2.id} (Expected C002)")
    print(f"Item 3 ID: {c3.id} (Expected C003)")
    print(f"Item 4 ID: {c4.id} (Expected C004)")
    assert c1.id == "C001"
    assert c2.id == "C002"
    assert c3.id == "C003"
    assert c4.id == "C004"
    
    # Verify duplicates have unique IDs
    assert c1.id != c2.id
    print("Unique ID verification passed.")

    # 3. Test Category Counts
    print("\n3. Testing Category Counts...")
    counts = wardrobe.get_category_counts()
    print(f"Category counts: {counts}")
    assert counts["Shirt"] == 2
    assert counts["Pants"] == 1
    assert counts["Shoes"] == 1
    print("Category counting verification passed.")

    # 4. Test Search
    print("\n4. Testing Search...")
    # Search for color "White" (should return both white shirts)
    white_search = wardrobe.search_items("White")
    print(f"Search 'White' results count: {len(white_search)}")
    assert len(white_search) == 2
    
    # Search for specific ID "C003"
    id_search = wardrobe.search_items("C003")
    print(f"Search 'C003' results: {[c.name for c in id_search]}")
    assert len(id_search) == 1
    assert id_search[0].name == "Blue Jeans"
    
    # Search for part of description "linen"
    desc_search = wardrobe.search_items("linen")
    print(f"Search 'linen' results: {[c.name for c in desc_search]}")
    assert len(desc_search) == 1
    assert desc_search[0].id == "C002"
    print("Search verification passed.")

    # 5. Test Edit Item
    print("\n5. Testing Edit Item...")
    # Edit the description of C001
    success = wardrobe.edit_item("C001", description="Super-formal tuxedo shirt", color="Off-White")
    assert success
    edited_item = wardrobe.find_item_by_id("C001")
    print(f"Edited Item C001: Description='{edited_item.description}', Color='{edited_item.color}'")
    assert edited_item.description == "Super-formal tuxedo shirt"
    assert edited_item.color == "Off-White"
    # Verify unchanged attributes remained the same
    assert edited_item.name == "White Shirt"
    print("Edit item verification passed.")

    # 6. Test Remove Item
    print("\n6. Testing Remove Item...")
    # Remove C002
    success_remove = wardrobe.remove_item("C002")
    assert success_remove
    assert wardrobe.find_item_by_id("C002") is None
    # Verify list count decreased to 3
    assert len(wardrobe.get_all_items()) == 3
    print("Remove item verification passed.")

    # 7. Test Save and Load from MongoDB
    print("\n7. Testing Save and Load from MongoDB...")
    test_db = "test_wardrobe"
    
    # Pre-clean
    from storage import get_mongo_client
    client = get_mongo_client()
    db = client["wardrobe_db"]
    collection = db["wardrobes"]
    collection.delete_one({"_id": test_db})
        
    save_result = save_wardrobe(wardrobe, test_db)
    assert save_result
    
    # Check it actually exists in database and uses "items" key
    db_doc = collection.find_one({"_id": test_db})
    assert db_doc is not None
    assert db_doc["user"]["name"] == "Alex Mercer"
    assert "items" in db_doc
    assert "clothes" not in db_doc
    print("Database key verification passed (uses 'items' list instead of 'clothes').")
    
    loaded_wardrobe = load_wardrobe(test_db)
    assert loaded_wardrobe is not None
    assert loaded_wardrobe.user.name == "Alex Mercer"
    assert len(loaded_wardrobe.get_all_items()) == 3
    
    # Check that sequential ID counter persists
    assert loaded_wardrobe.next_id_num == 5
    
    # Add new item after loading and check ID
    c_new = loaded_wardrobe.add_item("Red Tie", "Accessory", "Red", "Silk tie")
    print(f"New Item ID after reload: {c_new.id} (Expected C005)")
    assert c_new.id == "C005"
    
    # Cleanup
    collection.delete_one({"_id": test_db})
    client.close()
        
    print("\nSave and Load serialization verification passed.")
    print("\n=== ALL TESTS PASSED SUCCESSFULLY! ===")

if __name__ == "__main__":
    run_tests()
