import datetime
from user import User
from clothing import Clothing

class Wardrobe:
    def __init__(self, user: User = None):
        """
        Initializes a Wardrobe.
        
        Args:
            user (User, optional): The user who owns this wardrobe. Defaults to None.
        """
        self.user = user
        self.clothes = []
        self.next_id_num = 1

    def generate_unique_id(self) -> str:
        """Generates the next unique ID string, e.g., C001, C002."""
        return f"C{self.next_id_num:03d}"

    def add_clothing(self, name: str, category: str, color: str, description: str, image_path: str = None, date_added: str = None) -> Clothing:
        """
        Creates and adds a new clothing item with a unique ID.
        
        Args:
            name (str): Name of the clothing.
            category (str): Category (e.g. Shirt, Pants).
            color (str): Color of the clothing.
            description (str): Description or details.
            image_path (str, optional): Path to the image. Defaults to None.
            date_added (str, optional): Date when added. Defaults to today's date (YYYY-MM-DD).
            
        Returns:
            Clothing: The newly created clothing object.
        """
        if not date_added:
            date_added = datetime.date.today().isoformat()
            
        item_id = self.generate_unique_id()
        self.next_id_num += 1
        
        new_item = Clothing(
            item_id=item_id,
            name=name,
            category=category,
            color=color,
            description=description,
            date_added=date_added,
            image_path=image_path
        )
        self.clothes.append(new_item)
        return new_item

    def edit_clothing(self, clothing_id: str, name: str = None, category: str = None, color: str = None, description: str = None, image_path: str = None, date_added: str = None) -> bool:
        """
        Edits fields of a clothing item by its unique ID.
        Only fields that are not None will be updated.
        
        Args:
            clothing_id (str): Unique ID of the clothing item to edit.
            
        Returns:
            bool: True if the item was found and edited, False otherwise.
        """
        item = self.find_clothing_by_id(clothing_id)
        if not item:
            return False
            
        if name is not None:
            item.name = name
        if category is not None:
            item.category = category
        if color is not None:
            item.color = color
        if description is not None:
            item.description = description
        if image_path is not None:
            item.image_path = image_path
        if date_added is not None:
            item.date_added = date_added
            
        return True

    def remove_clothing(self, clothing_id: str) -> bool:
        """
        Removes a clothing item by its unique ID.
        
        Args:
            clothing_id (str): Unique ID of the clothing item to remove.
            
        Returns:
            bool: True if removed, False if not found.
        """
        item = self.find_clothing_by_id(clothing_id)
        if item:
            self.clothes.remove(item)
            return True
        return False

    def find_clothing_by_id(self, clothing_id: str) -> Clothing:
        """Helper to find a clothing item by its unique ID (case-insensitive)."""
        target_id = clothing_id.strip().upper()
        for c in self.clothes:
            if c.id.upper() == target_id:
                return c
        return None

    def get_all_clothing(self) -> list:
        """Returns the list of all clothes."""
        return self.clothes

    def search_clothing(self, query: str) -> list:
        """
        Performs a case-insensitive search across name, category, color, description, date_added, image_path, or unique ID.
        
        Args:
            query (str): The search term.
            
        Returns:
            list: List of matching Clothing objects.
        """
        q = query.strip().lower()
        results = []
        for c in self.clothes:
            if (q in c.id.lower() or
                q in c.name.lower() or
                q in c.category.lower() or
                q in c.color.lower() or
                q in c.description.lower() or
                q in c.date_added.lower() or
                (c.image_path and q in c.image_path.lower())):
                results.append(c)
        return results

    def get_category_counts(self) -> dict:
        """
        Counts clothes grouped by category.
        Categories are capitalized for display consistency.
        
        Returns:
            dict: Dictionary of category counts, e.g., {"Shirts": 5, "Pants": 3}.
        """
        counts = {}
        for c in self.clothes:
            cat = c.category.strip().capitalize() if c.category else "Uncategorized"
            counts[cat] = counts.get(cat, 0) + 1
        return counts

    def to_dict(self) -> dict:
        """Serializes the wardrobe, user, and unique ID state to a dictionary."""
        return {
            "user": self.user.to_dict() if self.user else None,
            "next_id_num": self.next_id_num,
            "clothes": [c.to_dict() for c in self.clothes]
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'Wardrobe':
        """Deserializes a dictionary to a Wardrobe object."""
        user_data = data.get("user")
        user = User.from_dict(user_data) if user_data else None
        
        wardrobe = cls(user)
        wardrobe.next_id_num = data.get("next_id_num", 1)
        
        clothes_data = data.get("clothes", [])
        for c_data in clothes_data:
            wardrobe.clothes.append(Clothing.from_dict(c_data))
            
        return wardrobe
