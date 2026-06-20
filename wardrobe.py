import datetime
from user import User
from wardrobe_item import WardrobeItem

class Wardrobe:
    def __init__(self, user: User = None):
        """
        Initializes a Wardrobe.
        
        Args:
            user (User, optional): The user who owns this wardrobe. Defaults to None.
        """
        self.user = user
        self.items = []
        self.next_id_num = 1

    def generate_unique_id(self) -> str:
        """Generates the next unique ID string, e.g., C001, C002."""
        return f"C{self.next_id_num:03d}"

    def add_item(self, name: str, category: str, color: str, description: str, image_path: str = None, date_added: str = None) -> WardrobeItem:
        """
        Creates and adds a new wardrobe item with a unique ID.
        
        Args:
            name (str): Name of the item.
            category (str): Category (e.g. Shirt, Pants, Shoes).
            color (str): Color of the item.
            description (str): Description or details.
            image_path (str, optional): Path to the image. Defaults to None.
            date_added (str, optional): Date when added. Defaults to today's date (YYYY-MM-DD).
            
        Returns:
            WardrobeItem: The newly created WardrobeItem object.
        """
        if not date_added:
            date_added = datetime.date.today().isoformat()
            
        item_id = self.generate_unique_id()
        self.next_id_num += 1
        
        new_item = WardrobeItem(
            item_id=item_id,
            name=name,
            category=category,
            color=color,
            description=description,
            date_added=date_added,
            image_path=image_path
        )
        self.items.append(new_item)
        return new_item

    def edit_item(self, item_id: str, name: str = None, category: str = None, color: str = None, description: str = None, image_path: str = None, date_added: str = None) -> bool:
        """
        Edits fields of a wardrobe item by its unique ID.
        Only fields that are not None will be updated.
        
        Args:
            item_id (str): Unique ID of the item to edit.
            
        Returns:
            bool: True if the item was found and edited, False otherwise.
        """
        item = self.find_item_by_id(item_id)
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

    def remove_item(self, item_id: str) -> bool:
        """
        Removes a wardrobe item by its unique ID.
        
        Args:
            item_id (str): Unique ID of the item to remove.
            
        Returns:
            bool: True if removed, False if not found.
        """
        item = self.find_item_by_id(item_id)
        if item:
            self.items.remove(item)
            return True
        return False

    def find_item_by_id(self, item_id: str) -> WardrobeItem:
        """Helper to find a wardrobe item by its unique ID (case-insensitive)."""
        target_id = item_id.strip().upper()
        for i in self.items:
            if i.id.upper() == target_id:
                return i
        return None

    def get_all_items(self) -> list:
        """Returns the list of all items."""
        return self.items

    def search_items(self, query: str) -> list:
        """
        Performs a case-insensitive search across name, category, color, description, date_added, image_path, or unique ID.
        
        Args:
            query (str): The search term.
            
        Returns:
            list: List of matching WardrobeItem objects.
        """
        q = query.strip().lower()
        results = []
        for i in self.items:
            if (q in i.id.lower() or
                q in i.name.lower() or
                q in i.category.lower() or
                q in i.color.lower() or
                q in i.description.lower() or
                q in i.date_added.lower() or
                (i.image_path and q in i.image_path.lower())):
                results.append(i)
        return results

    def get_category_counts(self) -> dict:
        """
        Counts items grouped by category.
        Categories are capitalized for display consistency.
        
        Returns:
            dict: Dictionary of category counts, e.g., {"Shirts": 5, "Pants": 3}.
        """
        counts = {}
        for i in self.items:
            cat = i.category.strip().capitalize() if i.category else "Uncategorized"
            counts[cat] = counts.get(cat, 0) + 1
        return counts

    def to_dict(self) -> dict:
        """Serializes the wardrobe, user, and unique ID state to a dictionary."""
        return {
            "user": self.user.to_dict() if self.user else None,
            "next_id_num": self.next_id_num,
            "items": [i.to_dict() for i in self.items]
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'Wardrobe':
        """Deserializes a dictionary to a Wardrobe object."""
        user_data = data.get("user")
        user = User.from_dict(user_data) if user_data else None
        
        wardrobe = cls(user)
        wardrobe.next_id_num = data.get("next_id_num", 1)
        
        items_data = data.get("items", [])
        for i_data in items_data:
            wardrobe.items.append(WardrobeItem.from_dict(i_data))
            
        return wardrobe
