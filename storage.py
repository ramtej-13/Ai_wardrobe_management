import json
import os
from wardrobe import Wardrobe

def save_wardrobe(wardrobe: Wardrobe, filename: str = "wardrobe.json") -> bool:
    """
    Saves a Wardrobe instance to a JSON file.
    
    Args:
        wardrobe (Wardrobe): The Wardrobe object to save.
        filename (str, optional): The target filename. Defaults to "wardrobe.json".
        
    Returns:
        bool: True if saving succeeded, False otherwise.
    """
    try:
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(wardrobe.to_dict(), f, indent=4, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"Error saving wardrobe to {filename}: {e}")
        return False

def load_wardrobe(filename: str = "wardrobe.json") -> Wardrobe:
    """
    Loads wardrobe data from a JSON file and deserializes it.
    
    Args:
        filename (str, optional): The source filename. Defaults to "wardrobe.json".
        
    Returns:
        Wardrobe: Deserialized Wardrobe object if file exists, or None.
    """
    if not os.path.exists(filename):
        return None
        
    try:
        with open(filename, "r", encoding="utf-8") as f:
            data = json.load(f)
            return Wardrobe.from_dict(data)
    except (json.JSONDecodeError, KeyError, TypeError, ValueError) as e:
        print(f"Warning: Could not parse {filename} ({e}). Starting with a fresh wardrobe.")
        return None
    except Exception as e:
        print(f"Error loading {filename}: {e}")
        return None
