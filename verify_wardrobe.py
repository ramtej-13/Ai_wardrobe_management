import os
from user import User
from clothing import Clothing
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
    
    # 2. Create Wardrobe & Add Clothes
    print("\n2. Testing Wardrobe Creation and Add Clothing...")
    wardrobe = Wardrobe(user)
    
    # Add identical clothing items to test unique IDs
    c1 = wardrobe.add_clothing("White Shirt", "Shirt", "White", "Formal shirt", None, "2026-06-01")
    c2 = wardrobe.add_clothing("White Shirt", "Shirt", "White", "Casual linen shirt", "C:/images/white_shirt_2.png", "2026-06-10")
    c3 = wardrobe.add_clothing("Blue Jeans", "Pants", "Blue", "Slim fit denim", None, "2026-06-12")
    c4 = wardrobe.add_clothing("Black Sneakers", "Shoes", "Black", "Running shoes", "C:/images/sneakers.png", "2026-06-14")
    
    print(f"Added items: {[c.name for c in wardrobe.get_all_clothing()]}")
    
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
    white_search = wardrobe.search_clothing("White")
    print(f"Search 'White' results count: {len(white_search)}")
    assert len(white_search) == 2
    
    # Search for specific ID "C003"
    id_search = wardrobe.search_clothing("C003")
    print(f"Search 'C003' results: {[c.name for c in id_search]}")
    assert len(id_search) == 1
    assert id_search[0].name == "Blue Jeans"
    
    # Search for part of description "linen"
    desc_search = wardrobe.search_clothing("linen")
    print(f"Search 'linen' results: {[c.name for c in desc_search]}")
    assert len(desc_search) == 1
    assert desc_search[0].id == "C002"
    print("Search verification passed.")

    # 5. Test Edit Clothing
    print("\n5. Testing Edit Clothing...")
    # Edit the description of C001
    success = wardrobe.edit_clothing("C001", description="Super-formal tuxedo shirt", color="Off-White")
    assert success
    edited_item = wardrobe.find_clothing_by_id("C001")
    print(f"Edited Item C001: Description='{edited_item.description}', Color='{edited_item.color}'")
    assert edited_item.description == "Super-formal tuxedo shirt"
    assert edited_item.color == "Off-White"
    # Verify unchanged attributes remained the same
    assert edited_item.name == "White Shirt"
    print("Edit clothing verification passed.")

    # 6. Test Remove Clothing
    print("\n6. Testing Remove Clothing...")
    # Remove C002
    success_remove = wardrobe.remove_clothing("C002")
    assert success_remove
    assert wardrobe.find_clothing_by_id("C002") is None
    # Verify list count decreased to 3
    assert len(wardrobe.get_all_clothing()) == 3
    print("Remove clothing verification passed.")

    # 7. Test Save and Load
    print("\n7. Testing Save and Load from JSON...")
    test_db = "wardrobe_test.json"
    if os.path.exists(test_db):
        os.remove(test_db)
        
    save_result = save_wardrobe(wardrobe, test_db)
    assert save_result
    assert os.path.exists(test_db)
    
    loaded_wardrobe = load_wardrobe(test_db)
    assert loaded_wardrobe is not None
    assert loaded_wardrobe.user.name == "Alex Mercer"
    assert len(loaded_wardrobe.get_all_clothing()) == 3
    
    # Check that sequential ID counter persists
    assert loaded_wardrobe.next_id_num == 5
    
    # Add new item after loading and check ID
    c_new = loaded_wardrobe.add_clothing("Red Tie", "Accessory", "Red", "Silk tie")
    print(f"New Item ID after reload: {c_new.id} (Expected C005)")
    assert c_new.id == "C005"
    
    # Cleanup
    if os.path.exists(test_db):
        os.remove(test_db)
        
    print("\nSave and Load serialization verification passed.")
    print("\n=== ALL TESTS PASSED SUCCESSFULLY! ===")

if __name__ == "__main__":
    run_tests()
