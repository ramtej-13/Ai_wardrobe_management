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
    Saves a Wardrobe instance to MongoDB.
    
    Args:
        wardrobe (Wardrobe): The Wardrobe object to save.
        identifier (str, optional): The document _id in collection. Defaults to "active_wardrobe".
        
    Returns:
        bool: True if saving succeeded, False otherwise.
    """
    client = None
    try:
        client = get_mongo_client()
        db = client["wardrobe_db"]
        collection = db["wardrobes"]
        
        data = wardrobe.to_dict()
        data["_id"] = identifier
        
        # Replace the document if it exists, otherwise insert it
        collection.replace_one({"_id": identifier}, data, upsert=True)
        return True
    except Exception as e:
        print(f"Error saving wardrobe to MongoDB: {e}")
        return False
    finally:
        if client:
            client.close()

def load_wardrobe(identifier: str = "active_wardrobe") -> Wardrobe:
    """
    Loads wardrobe data from MongoDB and deserializes it.
    
    Args:
        identifier (str, optional): The document _id in collection. Defaults to "active_wardrobe".
        
    Returns:
        Wardrobe: Deserialized Wardrobe object if document exists, or None.
    """
    client = None
    try:
        client = get_mongo_client()
        db = client["wardrobe_db"]
        collection = db["wardrobes"]
        
        data = collection.find_one({"_id": identifier})
        if not data:
            return None
            
        return Wardrobe.from_dict(data)
    except Exception as e:
        print(f"Error loading wardrobe from MongoDB: {e}")
        return None
    finally:
        if client:
            client.close()
