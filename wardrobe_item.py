class WardrobeItem:
    def __init__(self, item_id: str, name: str, category: str, color: str, description: str, date_added: str, image_path: str = None):
        """
        Initializes a Wardrobe item.
        
        Args:
            item_id (str): Unique identifier (e.g. C001).
            name (str): Name of the item (e.g. White Shirt).
            category (str): Category (e.g. Shirt, Pants, Shoes).
            color (str): Color of the item.
            description (str): Description or notes.
            date_added (str): Date added (format YYYY-MM-DD).
            image_path (str, optional): File path to the item image. Defaults to None.
        """
        self.id = item_id
        self.name = name
        self.category = category
        self.color = color
        self.description = description
        self.date_added = date_added
        self.image_path = image_path

    def to_dict(self) -> dict:
        """Serializes the item object to a dictionary."""
        return {
            "id": self.id,
            "name": self.name,
            "category": self.category,
            "color": self.color,
            "description": self.description,
            "date_added": self.date_added,
            "image_path": self.image_path
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'WardrobeItem':
        """Deserializes a dictionary to a WardrobeItem object."""
        return cls(
            item_id=data["id"],
            name=data["name"],
            category=data["category"],
            color=data["color"],
            description=data["description"],
            date_added=data["date_added"],
            image_path=data.get("image_path")
        )
