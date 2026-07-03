class User:
    def __init__(self, name: str, age: int, gender: str, height: float, weight: float,
                 location: str = "", budget: str = "", preferred_style: str = "", occupation: str = None,
                 body_type: str = None, body_build: str = None, skin_tone: str = None, undertone: str = None,
                 hair_color: str = None, face_shape: str = None, facial_hair: str = None, estimated_height: str = None):
        """
        Initializes a User profile.
        
        Args:
            name (str): Name of the user.
            age (int): Age of the user.
            gender (str): Gender of the user.
            height (float): Height in centimeters.
            weight (float): Weight in kilograms.
            location (str): Location/city.
            budget (str): Budget preference (e.g. Low, Mid, High).
            preferred_style (str): Preferred styling style (e.g. Casual, Formal, Streetwear).
            occupation (str, optional): User's occupation.
            body_type (str, optional): AI-detected body type.
            body_build (str, optional): AI-detected body build.
            skin_tone (str, optional): AI-detected skin tone.
            undertone (str, optional): AI-detected undertone.
            hair_color (str, optional): AI-detected hair color.
            face_shape (str, optional): AI-detected face shape.
            facial_hair (str, optional): AI-detected facial hair.
            estimated_height (str, optional): AI-estimated height.
        """
        self.name = name
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.location = location
        self.budget = budget
        self.preferred_style = preferred_style
        self.occupation = occupation
        
        # AI attributes
        self.body_type = body_type
        self.body_build = body_build
        self.skin_tone = skin_tone
        self.undertone = undertone
        self.hair_color = hair_color
        self.face_shape = face_shape
        self.facial_hair = facial_hair
        self.estimated_height = estimated_height

    def to_dict(self) -> dict:
        """Serializes the user object to a dictionary."""
        return {
            "name": self.name,
            "age": self.age,
            "gender": self.gender,
            "height": self.height,
            "weight": self.weight,
            "location": self.location,
            "budget": self.budget,
            "preferred_style": self.preferred_style,
            "occupation": self.occupation,
            "body_type": self.body_type,
            "body_build": self.body_build,
            "skin_tone": self.skin_tone,
            "undertone": self.undertone,
            "hair_color": self.hair_color,
            "face_shape": self.face_shape,
            "facial_hair": self.facial_hair,
            "estimated_height": self.estimated_height
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'User':
        """Deserializes a dictionary to a User object."""
        return cls(
            name=data["name"],
            age=data["age"],
            gender=data["gender"],
            height=data["height"],
            weight=data["weight"],
            location=data.get("location", ""),
            budget=data.get("budget", ""),
            preferred_style=data.get("preferred_style", ""),
            occupation=data.get("occupation"),
            body_type=data.get("body_type"),
            body_build=data.get("body_build"),
            skin_tone=data.get("skin_tone"),
            undertone=data.get("undertone"),
            hair_color=data.get("hair_color"),
            face_shape=data.get("face_shape"),
            facial_hair=data.get("facial_hair"),
            estimated_height=data.get("estimated_height")
        )
