using System;

// Constants


public class Constants
{
		// URL"s
	public static string URL_DISCORD = "https://discord.gg/7V88C8Z2pu";
	public static string URL_STEAM = "https://store.steampowered.com/app/1927570/Tilefinder/";
	public static string URL_FEEDBACK = "https://docs.google.com/forms/d/e/1FAIpQLSc85rLVfI5sslGkkZqdyKR0mzaCJXhWOYMO3rVRq5sFvnjVqA/viewform?usp=sf_link";

	public static int BUTTON_TEXT_Y = -2;
	
	public static int ICON_FRAME_SIZE = 38;
	public static int ICON_SIZE = 32;

		// Spell Types
	public static int NO_EFFECT					= 0;
	public static int NORMAL_MOVE				= 1;
	public static int SKILL_SHOT					= 2;
	public static int MULTI_SKILL_SHOT			= 3;
	public static int ANY_ALLY					= 4;
	public static int END_TURN					= 5;
	public static int TARGET_IN_RANGE			= 6;
	public static int AOE_AROUND					= 7;
	public static int CHARGE						= 8;
	public static int HORSE_MOVE					= 9;
	public static int SKILL_SHOT_SPLIT			= 10;
	public static int TILE_IN_RANGE				= 11;
	public static int SKILL_SHOT_PIERCING		= 12;
	public static int SKILL_SHOT_GHOST			= 13;
	public static int TIDAL_WAVE					= 14;
	public static int TELEPORT_MOVE				= 15;
	public static int FLY_MOVE					= 16;
	public static int CRYSTAL_MOVE				= 17;
	public static int PLAYER_CRYSTAL_MOVE		= 18;
	public static int CUSTOM_EFFECT				= 19;


		// Directions
	public static int NO_DIRECTION	= 0;
	public static int UP				= 1;
	public static int RIGHT			= 2;
	public static int LEFT 			= 3;
	public static int DOWN 			= 4;
	public static int UP_RIGHT		= 12;
	public static int UP_LEFT		= 13;
	public static int DOWN_RIGHT		= 42;
	public static int DOWN_LEFT		= 43;
	public static function GetRandomDirection() return randomintBetween(1, 8);
	public static function GetDirections() return [UP, RIGHT, DOWN, LEFT, UP_RIGHT, UP_LEFT, DOWN_RIGHT, DOWN_LEFT };

	public static function GetOppositeDirection(int direction) {
		switch (direction) {
			case UP: return DOWN;
			case UP_RIGHT: return DOWN_LEFT;
			case RIGHT: return LEFT;
			case DOWN_RIGHT: return UP_LEFT;
			case DOWN: return UP;
			case DOWN_LEFT: return UP_RIGHT;
			case LEFT: return RIGHT;
			case UP_LEFT: return DOWN_RIGHT;
			default: return NO_DIRECTION;
		}
	}
	public static function GetNextIInDirection(int i,int  int direction) {
		switch (direction) {
			case UP, UP_RIGHT, UP_LEFT: return i - 1;
			case DOWN, DOWN_RIGHT, DOWN_LEFT: return i + 1;
			default: return i;
		}
	}
	public static function GetNextJInDirection(int j,int  int direction) {
		switch (direction) {
			case LEFT, UP_LEFT, DOWN_LEFT: return j - 1;
			case RIGHT, UP_RIGHT, DOWN_RIGHT: return j + 1;
			default: return j;
		}
	}
	public static function GetDirectionJoined(int vert, int hor) {
		return int(vert * 10 + hor);
	}
	public static int[] GetDiagonalBounceDirectionPriorities(int currentDirection) {
		// Assuming an object is moving in currentDirection and it hit a wall,
		// Returns an array containing the directions in which it can bounce,
		// In order of priority
		// (does not check if they are free; it just returns the priorities)
		switch (currentDirection) {	// The order of these checks matters!
			case DOWN_LEFT:
				return [UP_LEFT, DOWN_RIGHT, UP_RIGHT };
			case UP_LEFT:
				return [DOWN_LEFT, UP_RIGHT, DOWN_RIGHT };
			case UP_RIGHT:
				return [DOWN_RIGHT, UP_LEFT, DOWN_LEFT };
			case DOWN_RIGHT:
				return [UP_RIGHT, DOWN_LEFT, UP_LEFT };
			default: return [NO_DIRECTION };				
		}
	}


		// Owners
	public static int NOBODY		= -1;
	public static int NEUTRAL	= 0;
	public static int PLAYER		= 1;
	public static int ENEMY		= 2;

		// Damage Types
	public static int PHYSICAL	= 0;
	public static int FIRE 		= 1;
	public static int COLD 		= 2;
	public static int DARK 		= 3;
	public static int MAGIC		= 4;
	public static int PURE 		= 5;
	public static int SHOCK 		= 6;

		// Open Inventory Scopes
	public static int BUY		  	= 0;
	public static int SELL		  	= 1;
	public static int USE		  	= 2;	// Battlefield only
	public static int EQUIP		  	= 3;
	public static int UNEQUIP	  	= 4;
	public static int INSPECT	  	= 5;
	public static int LEARN_SPELL  	= 6;
	public static int UNLEARN_SPELL	= 7;
	public static int LOOT  		  	= 8;	// After Combat only
	public static int TRIBUTE		= 9;	// For giving to an Event

		// Open Spell Popup Scopes
	public static int VIEW = 0;
	public static int UNLEARN = 1;
	public static int LEARN = 2;	

		// Town Click States
	public static int IN_TOWN		= 0;
    public static int BUYING 		= 2;
    public static int SELLING		= 3;
    public static int EQUIPPING		= 4;
    public static int UNEQUIPPING	= 5;
	public static int INSPECTING_CHARACTER = 6;
	public static int CHOOSING_SPELL_TO_LEARN = 7;





		// Item Types
	public static string GEAR			= "string GEAR";
	public static string CONSUMABLE		= "string CONSUMABLE";
	public static string JUNK			= "string JUNK";
	public static string SPELL			= "string SPELL";

		// Item Rarities
	public static int ANY_RARITY	= -1;
	public static int TRASH		= 1;
	public static int COMMON 	= 2;
	public static int RARE		= 3;
	public static int EPIC		= 4;
	public static int ARTIFACT	= 5;
	public static ImageX GetRarityImageGlow1(int rarity) {
		var mapping = { 
			TRASH => null,
			COMMON => null,
			RARE => "UI/FrameGlow/Blue.png",
			EPIC => "UI/FrameGlow/Purple.png",
			ARTIFACT => "UI/FrameGlow/Orange.png"
		 };
		var path = mapping[rarity };
		if (path == null) return null;
		return new ImageX(path, "ItemIconsLayer");
	}
	public static ImageX GetRarityImageGlow2(int rarity) {
		var mapping = { 
			TRASH => null,
			COMMON => null,
			RARE => "UI/FrameGlow/Blue2.png",
			EPIC => "UI/FrameGlow/Purple2.png",
			ARTIFACT => "UI/FrameGlow/Orange2.png"
		 };
		var path = mapping[rarity };
		if (path == null) return null;
		return new ImageX(path, "ItemIconsLayer");
	}

		// Item Tags
	public static int TRINKET = 1;
	public static int METAL = 2;
	public static int SPECIAL_ITEM = 3;
	public static int CLOTH = 4;
	public static int LIQUID = 5;
	public static int UNHOLY = 6;
	public static int ORE = 7;
	public static int PLANT = 8;
	public static int MAGICAL = 9;
	public static int WEAPON = 10;
	public static int ARMOR = 11;
	public static int ULTRA_RARE = 12;

	public static function ItemTagTostring(int tag) {
		var name = switch(tag) {
			case TRINKET: "TRINKET";
			case METAL: "METAL";
			case SPECIAL_ITEM: "SPECIAL_ITEM";
			case CLOTH: "CLOTH";
			case LIQUID: "LIQUID";
			case UNHOLY: "UNHOLY";
			case ORE: "ORE";
			case PLANT: "PLANT";
			case MAGICAL: "MAGICAL";
			case WEAPON : "WEAPON";
			case ARMOR : "ARMOR";
			case ULTRA_RARE : "ULTRA_RARE";
			"<Unknown Tag: ${tag}>" default;
		}
		return name;
	}




	// MapNode Types
	public static string BATTLEFIELD_ENCOUNTER	= "string BATTLEFIELD_ENCOUNTER";
	public static string BLACKSMITH = "string BLACKSMITH";
	public static string MERCHANT = "string MERCHANT";
	public static string NANA_JOY = "string NANA_JOY";
	public static string CAMPFIRE = "string CAMPFIRE";
	public static string EVENT = "string EVENT";
	public static string ROOT_NODE = "string ROOT_NODE";

	public static var validMapNodeTypes = { BATTLEFIELD_ENCOUNTER, BLACKSMITH, MERCHANT, NANA_JOY };
	public static bool IsMapNodeTypeValid(string nodeType) return validMapNodeTypes.IndexOf(nodeType) != -1;

		// Font ID"s
	public static int PRICE_FONT_ID				= 16;
	public static int ITEM_DESCRIPTION_FONT_ID 	= 54;
	public static int BROWN_ON_BROWN_TITLE_FONT	= 53;
	public static int STAT_NUMBER_FONT			= 54;
	public static int MANA_FONT					= 59;
	public static int ITEM_FLAVOR_FONT 			= 93;
	public static int BASE_FONT 					= 52;
	public static int DEBUG_FONT 				= 43;
	public static int COMBAT_TEXT_FONT 			= 80;
	public static int GAME_OVER_FONT 			= 118;
	public static int BIG_WHITE_FONT 			= 119;
	public static int BUTTON_TEXT_FONT 			= 121;
	public static int SHADED_FONT	 			= 125;
	public static int SHADED_FONT_BIG 			= 126;
	public static int SHADED_FONT_BIG_GREEN		= 221;
	public static int SHADED_FONT_BIG_BLUE		= 411;
	public static int SHADED_FONT_BIG_RED		= 412;
	public static int SHADED_FONT_BARS 			= 429;
	public static int FAKE_LOADING_SCREEN_FONT	= 439;
	public static int PATCH_NOTES_FONT			= 461;
	public static int UPDATE_VERSION_FONT		= 462;

		// LOOT TYPES
	public static string NO_LOOT		= "string NO_LOOT";
	public static string RANDOM_ITEM	= "string RANDOM_ITEM";

		// Audio Channels
	public static int MUSIC_CHANNEL		= 1;
	public static int VOICE_CHANNEL		= 2;
	public static int EFFECTS_CHANNEL	= 3;
	public static int UI_CHANNEL			= 4;
	public static int MISC_CHANNEL		= 5;



	public static var constants = { 
		"FAST"						=> Effects.FAST,
		"MEDIUM" 					=> Effects.MEDIUM,
		"SLOW"						=> Effects.SLOW,

		"NO_EFFECT"					=> NO_EFFECT,
		"CUSTOM_EFFECT"				=> CUSTOM_EFFECT,
		"NORMAL_MOVE"				=> NORMAL_MOVE,
		"FLY_MOVE"					=> FLY_MOVE,
		"CRYSTAL_MOVE"				=> CRYSTAL_MOVE,
		"PLAYER_CRYSTAL_MOVE"		=> PLAYER_CRYSTAL_MOVE,
		"HORSE_MOVE"				=> HORSE_MOVE,
		"TELEPORT_MOVE"				=> TELEPORT_MOVE,
		"SKILL_SHOT"				=> SKILL_SHOT,
		"SKILL_SHOT_SPLIT"			=> SKILL_SHOT_SPLIT,
		"MULTI_SKILL_SHOT"			=> MULTI_SKILL_SHOT,
		"ANY_ALLY"					=> ANY_ALLY,
		"END_TURN"					=> END_TURN,
		"TARGET_IN_RANGE"			=> TARGET_IN_RANGE,
		"AOE_AROUND" 				=> AOE_AROUND,
		"CHARGE"	 				=> CHARGE,
		"TILE_IN_RANGE"				=> TILE_IN_RANGE,
		"SKILL_SHOT_PIERCING" 		=> SKILL_SHOT_PIERCING,
		"SKILL_SHOT_GHOST" 			=> SKILL_SHOT_GHOST,
		"TIDAL_WAVE" 				=> TIDAL_WAVE,

		"PHYSICAL"					=> PHYSICAL,
		"FIRE"						=> FIRE,
		"COLD"						=> COLD,
		"DARK"						=> DARK,
		"PURE"						=> PURE,
			
		"TRASH"						=> TRASH,
		"COMMON" 					=> COMMON,
		"RARE"						=> RARE,
		"EPIC"						=> EPIC,
		"ARTIFACT"					=> ARTIFACT
	 };

	public static function GetConstant(string constantName) {
		if (constants.Exists(constantName))
			return constants[constantName };
		throwAndLogError("Constant "${constantName}" is not registered to an actual value.");
		throw "See logs above.";
	}

	public static function DirectionTostring(int direction) {
		var directions = { 
			NO_DIRECTION	=> "NO_DIRECTION",
			UP				=> "UP",
			RIGHT			=> "RIGHT",
			LEFT 			=> "LEFT",
			DOWN 			=> "DOWN",
			UP_RIGHT		=> "UP_RIGHT",
			UP_LEFT			=> "UP_LEFT",
			DOWN_RIGHT		=> "DOWN_RIGHT",
			DOWN_LEFT		=> "DOWN_LEFT"
		 };
		return directions[direction };
	}

	public static var availableZones = { "Town", "Forest", "Beach", "Swamp", "Caves", "Castle" };
}