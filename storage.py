import json
import os
from pymongo import MongoClient
from wardrobe import Wardrobe

CONFIG_FILE = "config.json"

def get_mongo_client() -> MongoClient:
    """
    Reads the MongoDB URI from config.json.
    If not found, prompts the user to input it and saves it.
    
    Returns:
        MongoClient: The established MongoClient instance.
    """
    mongo_uri = None
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                config = json.load(f)
                mongo_uri = config.get("mongo_uri")
        except Exception as e:
            print(f"Error reading config: {e}")

    if not mongo_uri:
        print("\n=== MONGODB ATLAS SETUP ===")
        print("Please enter your MongoDB Atlas Connection URI.")
        print("Example: mongodb+srv://username:password@cluster.xxxx.mongodb.net/?appName=Cluster0")
        mongo_uri = input("URI: ").strip()
        
        # Save to config.json
        try:
            with open(CONFIG_FILE, "w", encoding="utf-8") as f:
                json.dump({"mongo_uri": mongo_uri}, f, indent=4)
            print(f"Connection URI saved to {CONFIG_FILE} successfully!")
        except Exception as e:
            print(f"Could not save connection URI to file: {e}")

    import certifi
    try:
        # We specify a short server selection timeout so that if the URI is wrong, it fails fast
        # tlsAllowInvalidCertificates=True helps bypass strict SSL/TLS handshake rules on Python 3.13
        return MongoClient(mongo_uri, serverSelectionTimeoutMS=5000, tlsCAFile=certifi.where(), tlsAllowInvalidCertificates=True)
    except Exception as e:
        print(f"Failed to initialize MongoClient: {e}")
        raise e

def save_wardrobe(wardrobe: Wardrobe, identifier: str = "active_wardrobe") -> bool:
    """
    Saves a Wardrobe instance to MongoDB with isolated local JSON file fallback.
    
    Args:
        wardrobe (Wardrobe): The Wardrobe object to save.
        identifier (str, optional): The document _id in collection. Defaults to "active_wardrobe".
        
    Returns:
        bool: True if saving succeeded, False otherwise.
    """
    client = None
    fallback_name = f"wardrobe_fallback_{identifier}.json"
    fallback_path = os.path.join(os.path.dirname(__file__), fallback_name)
    try:
        client = get_mongo_client()
        # Verify connection to Atlas
        client.admin.command('ping')
        
        db = client["wardrobe_db"]
        collection = db["wardrobes"]
        
        data = wardrobe.to_dict()
        data["_id"] = identifier
        
        # Replace the document if it exists, otherwise insert it
        collection.replace_one({"_id": identifier}, data, upsert=True)
        
        # Keep local backup in sync
        try:
            with open(fallback_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=4)
        except Exception:
            pass
            
        return True
    except Exception as e:
        print(f"Error saving wardrobe to MongoDB Atlas: {e}. Falling back to local storage.")
        try:
            data = wardrobe.to_dict()
            data["_id"] = identifier
            with open(fallback_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=4)
            print(f"Wardrobe saved successfully to local fallback: {fallback_path}")
            return True
        except Exception as local_err:
            print(f"Critical error: Failed to save to local backup: {local_err}")
            return False
    finally:
        if client:
            client.close()

def load_wardrobe(identifier: str = "active_wardrobe") -> Wardrobe:
    """
    Loads wardrobe data from MongoDB or isolated local fallback JSON.
    
    Args:
        identifier (str, optional): The document _id in collection. Defaults to "active_wardrobe".
        
    Returns:
        Wardrobe: Deserialized Wardrobe object if document exists, or None.
    """
    client = None
    fallback_name = f"wardrobe_fallback_{identifier}.json"
    fallback_path = os.path.join(os.path.dirname(__file__), fallback_name)
    
    # Try to migrate the old general backup file if user-specific one doesn't exist
    if not os.path.exists(fallback_path):
        old_path = os.path.join(os.path.dirname(__file__), "wardrobe_fallback.json")
        if os.path.exists(old_path):
            try:
                with open(old_path, "r", encoding="utf-8") as f:
                    old_data = json.load(f)
                
                old_user_name = old_data.get("user", {}).get("name", "").lower()
                identifier_lower = identifier.lower()
                
                if (old_user_name and old_user_name in identifier_lower) or "active_wardrobe" in identifier_lower:
                    print(f"Migrating old backup data to isolated backup for user: {old_user_name}")
                    old_data["_id"] = identifier
                    with open(fallback_path, "w", encoding="utf-8") as f:
                        json.dump(old_data, f, indent=4)
            except Exception as migration_err:
                print(f"Error during backup migration: {migration_err}")

    try:
        client = get_mongo_client()
        # Verify connection to Atlas
        client.admin.command('ping')
        
        db = client["wardrobe_db"]
        collection = db["wardrobes"]
        
        data = collection.find_one({"_id": identifier})
        if not data:
            # Try to read user-specific local fallback
            if os.path.exists(fallback_path):
                print(f"Loading from user-specific local fallback json: {fallback_path}")
                with open(fallback_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    return Wardrobe.from_dict(data)
            return None
            
        return Wardrobe.from_dict(data)
    except Exception as e:
        print(f"Error loading wardrobe from MongoDB Atlas: {e}. Checking local storage fallback.")
        try:
            if os.path.exists(fallback_path):
                print(f"Loading from local fallback: {fallback_path}")
                with open(fallback_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    return Wardrobe.from_dict(data)
        except Exception as local_err:
            print(f"Failed to read local fallback: {local_err}")
        return None
    finally:
        if client:
            client.close()
