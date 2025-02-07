// Constants
package scripts;

import U.*;
import Std.int;
import Math.min;
import Math.max;

class Constants
{
		// URL's
	public static var URL_DISCORD = 'https://discord.gg/7V88C8Z2pu';
	public static var URL_STEAM = 'https://store.steampowered.com/app/1927570/Tilefinder/';
	public static var URL_FEEDBACK = 'https://docs.google.com/forms/d/e/1FAIpQLSc85rLVfI5sslGkkZqdyKR0mzaCJXhWOYMO3rVRq5sFvnjVqA/viewform?usp=sf_link';

	public static var BUTTON_TEXT_Y = -2;
	
	public static inline var ICON_FRAME_SIZE = 38;
	public static inline var ICON_SIZE = 32;

		// Spell Types
	public static inline var NO_EFFECT					= 0;
	public static inline var NORMAL_MOVE				= 1;
	public static inline var SKILL_SHOT					= 2;
	public static inline var MULTI_SKILL_SHOT			= 3;
	public static inline var ANY_ALLY					= 4;
	public static inline var END_TURN					= 5;
	public static inline var TARGET_IN_RANGE			= 6;
	public static inline var AOE_AROUND					= 7;
	public static inline var CHARGE						= 8;
	public static inline var HORSE_MOVE					= 9;
	public static inline var SKILL_SHOT_SPLIT			= 10;
	public static inline var TILE_IN_RANGE				= 11;
	public static inline var SKILL_SHOT_PIERCING		= 12;
	public static inline var SKILL_SHOT_GHOST			= 13;
	public static inline var TIDAL_WAVE					= 14;
	public static inline var TELEPORT_MOVE				= 15;
	public static inline var FLY_MOVE					= 16;
	public static inline var CRYSTAL_MOVE				= 17;
	public static inline var PLAYER_CRYSTAL_MOVE		= 18;
	public static inline var CUSTOM_EFFECT				= 19;


		// Directions
	public static inline var NO_DIRECTION	= 0;
	public static inline var UP				= 1;
	public static inline var RIGHT			= 2;
	public static inline var LEFT 			= 3;
	public static inline var DOWN 			= 4;
	public static inline var UP_RIGHT		= 12;
	public static inline var UP_LEFT		= 13;
	public static inline var DOWN_RIGHT		= 42;
	public static inline var DOWN_LEFT		= 43;
	public static inline function getRandomDirection() return randomIntBetween(1, 8);
	public static inline function getDirections() return [UP, RIGHT, DOWN, LEFT, UP_RIGHT, UP_LEFT, DOWN_RIGHT, DOWN_LEFT];

	public static function getOppositeDirection(direction: Int) {
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
	public static function getNextIInDirection(i: Int, direction: Int): Int {
		switch (direction) {
			case UP, UP_RIGHT, UP_LEFT: return i - 1;
			case DOWN, DOWN_RIGHT, DOWN_LEFT: return i + 1;
			default: return i;
		}
	}
	public static function getNextJInDirection(j: Int, direction: Int): Int {
		switch (direction) {
			case LEFT, UP_LEFT, DOWN_LEFT: return j - 1;
			case RIGHT, UP_RIGHT, DOWN_RIGHT: return j + 1;
			default: return j;
		}
	}
	public static function getDirectionJoined(vert: Int, hor: Int) {
		return int(vert * 10 + hor);
	}
	public static function getDiagonalBounceDirectionPriorities(currentDirection: Int): Array<Int> {
		// Assuming an object is moving in currentDirection and it hit a wall,
		// Returns an array containing the directions in which it can bounce,
		// In order of priority
		// (does not check if they are free; it just returns the priorities)
		switch (currentDirection) {	// The order of these checks matters!
			case DOWN_LEFT:
				return [UP_LEFT, DOWN_RIGHT, UP_RIGHT];
			case UP_LEFT:
				return [DOWN_LEFT, UP_RIGHT, DOWN_RIGHT];
			case UP_RIGHT:
				return [DOWN_RIGHT, UP_LEFT, DOWN_LEFT];
			case DOWN_RIGHT:
				return [UP_RIGHT, DOWN_LEFT, UP_LEFT];
			default: return [NO_DIRECTION];				
		}
	}


		// Owners
	public static inline var NOBODY		= -1;
	public static inline var NEUTRAL	= 0;
	public static inline var PLAYER		= 1;
	public static inline var ENEMY		= 2;

		// Damage Types
	public static inline var PHYSICAL	= 0;
	public static inline var FIRE 		= 1;
	public static inline var COLD 		= 2;
	public static inline var DARK 		= 3;
	public static inline var MAGIC		= 4;
	public static inline var PURE 		= 5;
	public static inline var SHOCK 		= 6;

		// Open Inventory Scopes
	public static inline var BUY		  	= 0;
	public static inline var SELL		  	= 1;
	public static inline var USE		  	= 2;	// Battlefield only
	public static inline var EQUIP		  	= 3;
	public static inline var UNEQUIP	  	= 4;
	public static inline var INSPECT	  	= 5;
	public static inline var LEARN_SPELL  	= 6;
	public static inline var UNLEARN_SPELL	= 7;
	public static inline var LOOT  		  	= 8;	// After Combat only
	public static inline var TRIBUTE		= 9;	// For giving to an Event

		// Open Spell Popup Scopes
	public static inline var VIEW = 0;
	public static inline var UNLEARN = 1;
	public static inline var LEARN = 2;	

		// Town Click States
	public static inline var IN_TOWN		= 0;
    public static inline var BUYING 		= 2;
    public static inline var SELLING		= 3;
    public static inline var EQUIPPING		= 4;
    public static inline var UNEQUIPPING	= 5;
	public static inline var INSPECTING_CHARACTER = 6;
	public static inline var CHOOSING_SPELL_TO_LEARN = 7;





		// Item Types
	public static inline var GEAR			= 'GEAR';
	public static inline var CONSUMABLE		= 'CONSUMABLE';
	public static inline var JUNK			= 'JUNK';
	public static inline var SPELL			= 'SPELL';

		// Item Rarities
	public static inline var ANY_RARITY	= -1;
	public static inline var TRASH		= 1;
	public static inline var COMMON 	= 2;
	public static inline var RARE		= 3;
	public static inline var EPIC		= 4;
	public static inline var ARTIFACT	= 5;
	public static function getRarityImageGlow1(rarity: Int): ImageX {
		final mapping = [
			TRASH => null,
			COMMON => null,
			RARE => 'UI/FrameGlow/Blue.png',
			EPIC => 'UI/FrameGlow/Purple.png',
			ARTIFACT => 'UI/FrameGlow/Orange.png'
		];
		final path = mapping[rarity];
		if (path == null) return null;
		return new ImageX(path, 'ItemIconsLayer');
	}
	public static function getRarityImageGlow2(rarity: Int): ImageX {
		final mapping = [
			TRASH => null,
			COMMON => null,
			RARE => 'UI/FrameGlow/Blue2.png',
			EPIC => 'UI/FrameGlow/Purple2.png',
			ARTIFACT => 'UI/FrameGlow/Orange2.png'
		];
		final path = mapping[rarity];
		if (path == null) return null;
		return new ImageX(path, 'ItemIconsLayer');
	}

		// Item Tags
	public static inline var TRINKET = 1;
	public static inline var METAL = 2;
	public static inline var SPECIAL_ITEM = 3;
	public static inline var CLOTH = 4;
	public static inline var LIQUID = 5;
	public static inline var UNHOLY = 6;
	public static inline var ORE = 7;
	public static inline var PLANT = 8;
	public static inline var MAGICAL = 9;
	public static inline var WEAPON = 10;
	public static inline var ARMOR = 11;
	public static inline var ULTRA_RARE = 12;

	public static function itemTagToString(tag: Int) {
		final name = switch(tag) {
			case TRINKET: 'TRINKET';
			case METAL: 'METAL';
			case SPECIAL_ITEM: 'SPECIAL_ITEM';
			case CLOTH: 'CLOTH';
			case LIQUID: 'LIQUID';
			case UNHOLY: 'UNHOLY';
			case ORE: 'ORE';
			case PLANT: 'PLANT';
			case MAGICAL: 'MAGICAL';
			case WEAPON : 'WEAPON';
			case ARMOR : 'ARMOR';
			case ULTRA_RARE : 'ULTRA_RARE';
			default: '<Unknown Tag: ${tag}>';
		}
		return name;
	}




	// MapNode Types
	public static inline var BATTLEFIELD_ENCOUNTER	= 'BATTLEFIELD_ENCOUNTER';
	public static inline var BLACKSMITH = 'BLACKSMITH';
	public static inline var MERCHANT = 'MERCHANT';
	public static inline var NANA_JOY = 'NANA_JOY';
	public static inline var CAMPFIRE = 'CAMPFIRE';
	public static inline var EVENT = 'EVENT';
	public static inline var ROOT_NODE = 'ROOT_NODE';

	public static var validMapNodeTypes = [BATTLEFIELD_ENCOUNTER, BLACKSMITH, MERCHANT, NANA_JOY];
	public static function isMapNodeTypeValid(nodeType: String) return validMapNodeTypes.indexOf(nodeType) != -1;

		// Font ID's
	public static inline var PRICE_FONT_ID				= 16;
	public static inline var ITEM_DESCRIPTION_FONT_ID 	= 54;
	public static inline var BROWN_ON_BROWN_TITLE_FONT	= 53;
	public static inline var STAT_NUMBER_FONT			= 54;
	public static inline var MANA_FONT					= 59;
	public static inline var ITEM_FLAVOR_FONT 			= 93;
	public static inline var BASE_FONT 					= 52;
	public static inline var DEBUG_FONT 				= 43;
	public static inline var COMBAT_TEXT_FONT 			= 80;
	public static inline var GAME_OVER_FONT 			= 118;
	public static inline var BIG_WHITE_FONT 			= 119;
	public static inline var BUTTON_TEXT_FONT 			= 121;
	public static inline var SHADED_FONT	 			= 125;
	public static inline var SHADED_FONT_BIG 			= 126;
	public static inline var SHADED_FONT_BIG_GREEN		= 221;
	public static inline var SHADED_FONT_BIG_BLUE		= 411;
	public static inline var SHADED_FONT_BIG_RED		= 412;
	public static inline var SHADED_FONT_BARS 			= 429;
	public static inline var FAKE_LOADING_SCREEN_FONT	= 439;
	public static inline var PATCH_NOTES_FONT			= 461;
	public static inline var UPDATE_VERSION_FONT		= 462;

		// LOOT TYPES
	public static inline var NO_LOOT		= 'NO_LOOT';
	public static inline var RANDOM_ITEM	= 'RANDOM_ITEM';

		// Audio Channels
	public static inline var MUSIC_CHANNEL		= 1;
	public static inline var VOICE_CHANNEL		= 2;
	public static inline var EFFECTS_CHANNEL	= 3;
	public static inline var UI_CHANNEL			= 4;
	public static inline var MISC_CHANNEL		= 5;



	public static var constants = [
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
		'TIDAL_WAVE' 				=> TIDAL_WAVE,

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
	];

	public static function getConstant(constantName : String) {
		if (constants.exists(constantName))
			return constants[constantName];
		throwAndLogError('Constant "${constantName}" is not registered to an actual value.');
		throw 'See logs above.';
	}

	public static function directionToString(direction : Int) {
		var directions = [
			NO_DIRECTION	=> "NO_DIRECTION",
			UP				=> "UP",
			RIGHT			=> "RIGHT",
			LEFT 			=> "LEFT",
			DOWN 			=> "DOWN",
			UP_RIGHT		=> "UP_RIGHT",
			UP_LEFT			=> "UP_LEFT",
			DOWN_RIGHT		=> "DOWN_RIGHT",
			DOWN_LEFT		=> "DOWN_LEFT"
		];
		return directions[direction];
	}

	public static var availableZones = ['Town', 'Forest', 'Beach', 'Swamp', 'Caves', 'Castle'];
}