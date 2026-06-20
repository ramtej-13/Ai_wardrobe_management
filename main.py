import os
import sys
import datetime
from user import User
from wardrobe_item import WardrobeItem
from wardrobe import Wardrobe
from storage import save_wardrobe, load_wardrobe

# ANSI Escape Sequences for beautiful terminal UI
CLR_RESET = "\033[0m"
CLR_HEADER = "\033[1;36m"   # Bold Cyan
CLR_SUCCESS = "\033[1;32m"  # Bold Green
CLR_WARNING = "\033[1;33m"  # Bold Yellow
CLR_ERROR = "\033[1;31m"    # Bold Red
CLR_INFO = "\033[35m"       # Magenta
CLR_TEXT = "\033[37m"       # White
CLR_BOLD = "\033[1m"

def clean_input(prompt: str) -> str:
    """Gets input from the user and strips leading/trailing whitespaces."""
    try:
        return input(prompt).strip()
    except (KeyboardInterrupt, EOFError):
        print(f"\n{CLR_ERROR}Program interrupted. Exiting...{CLR_RESET}")
        sys.exit(0)

def print_header(title: str):
    """Prints a beautiful colored header block."""
    width = 60
    print(f"\n{CLR_HEADER}" + "=" * width)
    print(title.center(width))
    print("=" * width + f"{CLR_RESET}")

def get_valid_int(prompt: str, min_val: int = 0) -> int:
    """Helper to get a valid integer input greater than or equal to min_val."""
    while True:
        val_str = clean_input(prompt)
        try:
            val = int(val_str)
            if val < min_val:
                print(f"{CLR_ERROR}Please enter a number >= {min_val}.{CLR_RESET}")
                continue
            return val
        except ValueError:
            print(f"{CLR_ERROR}Invalid input. Please enter a whole number.{CLR_RESET}")

def get_valid_float(prompt: str, min_val: float = 0.0) -> float:
    """Helper to get a valid float input greater than or equal to min_val."""
    while True:
        val_str = clean_input(prompt)
        try:
            val = float(val_str)
            if val < min_val:
                print(f"{CLR_ERROR}Please enter a number >= {min_val}.{CLR_RESET}")
                continue
            return val
        except ValueError:
            print(f"{CLR_ERROR}Invalid input. Please enter a valid decimal number.{CLR_RESET}")

def get_valid_date(prompt: str, allow_blank: bool = True) -> str:
    """Helper to get a valid date string in YYYY-MM-DD format."""
    while True:
        date_str = clean_input(prompt)
        if allow_blank and not date_str:
            return ""
        try:
            # Try parsing the date
            datetime.date.fromisoformat(date_str)
            return date_str
        except ValueError:
            print(f"{CLR_ERROR}Invalid date format. Please use YYYY-MM-DD.{CLR_RESET}")

def create_new_user() -> User:
    """Prompts the user to register a profile."""
    print_header("CREATE USER PROFILE")
    print(f"{CLR_INFO}To get started, please set up your profile details:{CLR_RESET}\n")
    
    while True:
        name = clean_input(f"{CLR_BOLD}Enter Name: {CLR_RESET}")
        if name:
            break
        print(f"{CLR_ERROR}Name cannot be empty.{CLR_RESET}")
        
    age = get_valid_int(f"{CLR_BOLD}Enter Age: {CLR_RESET}", min_val=1)
    
    while True:
        gender = clean_input(f"{CLR_BOLD}Enter Gender (e.g. Male, Female, Other): {CLR_RESET}")
        if gender:
            break
        print(f"{CLR_ERROR}Gender cannot be empty.{CLR_RESET}")
        
    height = get_valid_float(f"{CLR_BOLD}Enter Height (cm): {CLR_RESET}", min_val=1.0)
    weight = get_valid_float(f"{CLR_BOLD}Enter Weight (kg): {CLR_RESET}", min_val=1.0)
    
    print(f"\n{CLR_SUCCESS}Profile created successfully!{CLR_RESET}")
    return User(name, age, gender, height, weight)

def print_item_table(items_list):
    """Prints a beautiful ASCII table of a list of WardrobeItem objects."""
    if not items_list:
        print(f"{CLR_WARNING}No wardrobe items to display.{CLR_RESET}")
        return

    # Define table column formatting
    # Columns: ID, Name, Category, Color, Added, Image Path, Description
    header_fmt = "| {:<6} | {:<20} | {:<12} | {:<12} | {:<10} | {:<15} | {:<25} |"
    divider = "+" + "-"*8 + "+" + "-"*22 + "+" + "-"*14 + "+" + "-"*14 + "+" + "-"*12 + "+" + "-"*17 + "+" + "-"*27 + "+"
    
    print(divider)
    print(header_fmt.format("ID", "Name", "Category", "Color", "Added", "Image Path", "Description"))
    print(divider)
    
    for i in items_list:
        img_str = i.image_path if i.image_path else "None"
        desc_str = i.description if i.description else "None"
        # Truncate strings if they are too long to fit the columns
        name_t = i.name[:20]
        cat_t = i.category[:12]
        col_t = i.color[:12]
        img_t = img_str[:15]
        desc_t = desc_str[:25]
        
        print(header_fmt.format(i.id, name_t, cat_t, col_t, i.date_added, img_t, desc_t))
    print(divider)

def print_wardrobe_summary(wardrobe: Wardrobe):
    """Displays user profile, items table, and category counts."""
    # 1. Print User Profile
    u = wardrobe.user
    print(f"\n{CLR_BOLD}=== USER PROFILE ==={CLR_RESET}")
    print(f"{CLR_INFO}Name: {CLR_RESET}{u.name}  |  {CLR_INFO}Age: {CLR_RESET}{u.age}  |  {CLR_INFO}Gender: {CLR_RESET}{u.gender}  |  {CLR_INFO}Height: {CLR_RESET}{u.height} cm  |  {CLR_INFO}Weight: {CLR_RESET}{u.weight} kg")
    
    # 2. Print Items Table
    print(f"\n{CLR_BOLD}=== WARDROBE ITEMS ==={CLR_RESET}")
    print_item_table(wardrobe.get_all_items())
    
    # 3. Print Category Counts
    print(f"\n{CLR_BOLD}=== ITEM COUNTS BY CATEGORY ==={CLR_RESET}")
    counts = wardrobe.get_category_counts()
    if not counts:
        print(f"{CLR_WARNING}No categories to count.{CLR_RESET}")
    else:
        for cat, count in counts.items():
            print(f"  {CLR_BOLD}{cat}:{CLR_RESET} {count}")

def main():
    # Attempt to load data
    db_identifier = "active_wardrobe"
    wardrobe = load_wardrobe(db_identifier)
    
    if wardrobe is None or wardrobe.user is None:
        # User doesn't exist in DB, create new profile on startup
        user = create_new_user()
        wardrobe = Wardrobe(user)
        # Save it right away
        save_wardrobe(wardrobe, db_identifier)
    else:
        print_header("WARDROBE MANAGEMENT SYSTEM")
        print(f"{CLR_SUCCESS}Successfully loaded wardrobe data for {CLR_BOLD}{wardrobe.user.name}{CLR_RESET} from MongoDB Atlas!")
        
    while True:
        print_header("MAIN MENU")
        print("1. Add Wardrobe Item")
        print("2. Edit Wardrobe Item")
        print("3. Remove Wardrobe Item")
        print("4. View Wardrobe")
        print("5. Search Wardrobe Items")
        print("6. Save")
        print("7. Exit")
        print("=" * 60)
        
        choice = clean_input(f"{CLR_BOLD}Choose an option (1-7): {CLR_RESET}")
        
        if choice == "1":
            print_header("ADD NEW ITEM")
            name = clean_input(f"{CLR_BOLD}Enter Name (e.g. White Sneakers): {CLR_RESET}")
            if not name:
                print(f"{CLR_ERROR}Name cannot be empty. Cancelled addition.{CLR_RESET}")
                continue
                
            category = clean_input(f"{CLR_BOLD}Enter Category (e.g. Shirt, Pants, Shoes, Accessory): {CLR_RESET}")
            if not category:
                print(f"{CLR_ERROR}Category cannot be empty. Cancelled addition.{CLR_RESET}")
                continue
                
            color = clean_input(f"{CLR_BOLD}Enter Color: {CLR_RESET}")
            if not color:
                print(f"{CLR_ERROR}Color cannot be empty. Cancelled addition.{CLR_RESET}")
                continue
                
            description = clean_input(f"{CLR_BOLD}Enter Description / Notes: {CLR_RESET}")
            image_path = clean_input(f"{CLR_BOLD}Enter Image Path (optional, press Enter to skip): {CLR_RESET}")
            if not image_path:
                image_path = None
                
            date_added = get_valid_date(f"{CLR_BOLD}Enter Date Added (YYYY-MM-DD, press Enter for today): {CLR_RESET}", allow_blank=True)
            if not date_added:
                date_added = None
                
            item = wardrobe.add_item(
                name=name,
                category=category,
                color=color,
                description=description,
                image_path=image_path,
                date_added=date_added
            )
            print(f"\n{CLR_SUCCESS}Item added successfully! Assigned unique ID: {CLR_BOLD}{item.id}{CLR_RESET}")
            
        elif choice == "2":
            print_header("EDIT WARDROBE ITEM")
            item_id = clean_input(f"{CLR_BOLD}Enter Unique ID of the item to edit (e.g. C001): {CLR_RESET}").upper()
            item = wardrobe.find_item_by_id(item_id)
            if not item:
                print(f"{CLR_ERROR}Wardrobe item with ID {item_id} not found.{CLR_RESET}")
                continue
                
            print(f"\n{CLR_INFO}Editing {CLR_BOLD}{item.name} ({item.id}){CLR_RESET}. Press {CLR_BOLD}Enter{CLR_RESET} to keep the current value.")
            
            new_name = clean_input(f"Name [{item.name}]: ")
            if not new_name.strip():
                new_name = None
                
            new_cat = clean_input(f"Category [{item.category}]: ")
            if not new_cat.strip():
                new_cat = None
                
            new_col = clean_input(f"Color [{item.color}]: ")
            if not new_col.strip():
                new_col = None
                
            new_desc = clean_input(f"Description [{item.description}]: ")
            if not new_desc.strip():
                new_desc = None
                
            curr_img = item.image_path if item.image_path else "None"
            new_img = clean_input(f"Image Path [{curr_img}]: ")
            if not new_img.strip():
                new_img = None
            elif new_img.lower() == "none":
                new_img = ""  # clear image path
                
            new_date = get_valid_date(f"Date Added [{item.date_added}]: ", allow_blank=True)
            if not new_date.strip():
                new_date = None
                
            # Perform update
            # We convert empty string back to None for database storage
            wardrobe.edit_item(
                item_id=item_id,
                name=new_name,
                category=new_cat,
                color=new_col,
                description=new_desc,
                image_path=None if new_img == "" else new_img,
                date_added=new_date
            )
            print(f"\n{CLR_SUCCESS}Item updated successfully!{CLR_RESET}")
            
        elif choice == "3":
            print_header("REMOVE WARDROBE ITEM")
            item_id = clean_input(f"{CLR_BOLD}Enter Unique ID of the item to remove (e.g. C001): {CLR_RESET}").upper()
            item = wardrobe.find_item_by_id(item_id)
            if not item:
                print(f"{CLR_ERROR}Wardrobe item with ID {item_id} not found.{CLR_RESET}")
                continue
                
            print(f"\n{CLR_WARNING}Found item: {CLR_BOLD}{item.name} ({item.color} {item.category}){CLR_RESET}")
            confirm = clean_input(f"{CLR_BOLD}Are you sure you want to delete this item? (y/n): {CLR_RESET}").lower()
            if confirm == 'y':
                wardrobe.remove_item(item_id)
                print(f"{CLR_SUCCESS}Item removed from wardrobe.{CLR_RESET}")
            else:
                print(f"{CLR_INFO}Deletion cancelled.{CLR_RESET}")
                
        elif choice == "4":
            print_header("VIEW WARDROBE")
            print_wardrobe_summary(wardrobe)
            clean_input(f"\n{CLR_INFO}Press Enter to return to main menu...{CLR_RESET}")
            
        elif choice == "5":
            print_header("SEARCH WARDROBE ITEMS")
            query = clean_input(f"{CLR_BOLD}Search: {CLR_RESET}")
            if not query:
                print(f"{CLR_WARNING}Search query cannot be empty.{CLR_RESET}")
                continue
                
            results = wardrobe.search_items(query)
            print_header(f"SEARCH RESULTS FOR '{query.upper()}'")
            print_item_table(results)
            print(f"\n{CLR_INFO}Total matching items: {CLR_BOLD}{len(results)}{CLR_RESET}")
            clean_input(f"\n{CLR_INFO}Press Enter to return to main menu...{CLR_RESET}")
            
        elif choice == "6":
            print_header("SAVE WARDROBE DATA")
            if save_wardrobe(wardrobe, db_identifier):
                print(f"{CLR_SUCCESS}Wardrobe saved successfully to MongoDB Atlas!{CLR_RESET}")
            else:
                print(f"{CLR_ERROR}Failed to save wardrobe.{CLR_RESET}")
                
        elif choice == "7":
            print_header("EXIT SYSTEM")
            # Ask to save changes
            save_prompt = clean_input(f"{CLR_BOLD}Save changes before exiting? (y/n/cancel): {CLR_RESET}").lower()
            if save_prompt == 'y':
                save_wardrobe(wardrobe, db_identifier)
                print(f"{CLR_SUCCESS}Changes saved to MongoDB Atlas. Goodbye!{CLR_RESET}")
                break
            elif save_prompt == 'n':
                print(f"{CLR_INFO}Exiting without saving changes. Goodbye!{CLR_RESET}")
                break
            elif save_prompt == 'cancel' or save_prompt == 'c':
                print(f"{CLR_INFO}Exit cancelled.{CLR_RESET}")
                continue
            else:
                print(f"{CLR_ERROR}Invalid choice. Exit cancelled.{CLR_RESET}")
                continue
        else:
            print(f"{CLR_ERROR}Invalid option. Please choose a number from 1 to 7.{CLR_RESET}")

if __name__ == "__main__":
    main()
