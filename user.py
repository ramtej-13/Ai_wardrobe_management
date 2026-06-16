class User:
    def __init__(self, name: str, age: int, gender: str, height: float, weight: float):
        """
        Initializes a User profile.
        
        Args:
            name (str): Name of the user.
            age (int): Age of the user.
            gender (str): Gender of the user.
            height (float): Height in centimeters.
            weight (float): Weight in kilograms.
        """
        self.name = name
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight

    def to_dict(self) -> dict:
        """Serializes the user object to a dictionary."""
        return {
            "name": self.name,
            "age": self.age,
            "gender": self.gender,
            "height": self.height,
            "weight": self.weight
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'User':
        """Deserializes a dictionary to a User object."""
        return cls(
            name=data["name"],
            age=data["age"],
            gender=data["gender"],
            height=data["height"],
            weight=data["weight"]
        )
