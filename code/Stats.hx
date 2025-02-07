
package scripts;

import com.stencyl.Engine;

class Stats
{
	public var health				: Int = 0;
	public var mana					: Int = 0;
	public var damage				: Int = 0;
	public var armor				: Int = 0;
	public var crit					: Int = 0;
	public var dodge				: Int = 0;
	public var spellPower			: Int = 0;
	public var manaRegeneration		: Int = 0;
	public var speed				: Int = 0;

	public var initiative			: Int = 0;

	public function new(?s : Stats) {
		if(s != null) {
			copy(s);
		}
	}

	public function toDynamic() {
		return {
			health: health,
			mana: mana,
			damage: damage,
			armor: armor,
			crit: crit,
			dodge: dodge,
			initiative: initiative,
			spellPower: spellPower,
			manaRegeneration: manaRegeneration,
			speed: speed
		};
	}

	public static function createFromDynamic(s : Dynamic) {	// From JSON object
		var stats = new Stats();
		if( s.health			!= null ) stats.health				= s.health		;
		if( s.damage			!= null ) stats.damage				= s.damage		;
		if( s.armor				!= null ) stats.armor				= s.armor			;
		if( s.crit				!= null ) stats.crit				= s.crit			;
		if( s.dodge				!= null ) stats.dodge				= s.dodge			;
		if( s.initiative		!= null ) stats.initiative			= s.initiative		;
		if( s.mana				!= null ) stats.mana				= s.mana			;
		if( s.spellPower		!= null ) stats.spellPower			= s.spellPower		;
		if( s.manaRegeneration	!= null ) stats.manaRegeneration	= s.manaRegeneration	;
		if( s.speed				!= null ) stats.speed				= s.speed			;
		return stats;
	}

	public static function keys() {
		return ['health', 'mana', 'damage', 'spellPower', 'armor', 'manaRegeneration', 'crit', 'dodge', 'initiative', 'speed'];
	}
	public static function getStatNamesPretty() {
		return ['Health', 'Mana', 'Damage', 'Spell Power', 'Armor', 'Mana Regen', 'Crit', 'Dodge', 'Initiative', 'Speed'];
	}

	public function forEach(func : String -> Int -> Void) {
		var statNames = getStatNamesPretty();
		var statValues = [health, mana, damage, spellPower, armor, manaRegeneration, crit, dodge, initiative, speed];
		for (i in 0...statNames.length) {
			func(statNames[i], statValues[i]);
		}
	}

	public inline function addStat(statName: String, value: Int) set(statName, get(statName) + value);
	public function set(statName: String, value: Int) {
		switch (statName) {
			case 'health'			:	health = value;
			case 'damage'			:	damage = value;
			case 'armor'			:	armor = value;
			case 'crit'				:	crit = value;
			case 'dodge'			:	dodge = value;
			case 'initiative'		:	initiative = value;
			case 'mana'				:	mana = value;
			case 'spellPower'		:	spellPower = value;
			case 'manaRegeneration'	:	mana = value;
			case 'speed'			:	speed = value;
			default: trace('WARNING: Stat ${statName} not found');
		}
	}
	public function get(statName: String) {
		switch (statName) {
			case 'health'			:	return health;
			case 'damage'			:	return damage;
			case 'armor'			:	return armor;
			case 'crit'				:	return crit;
			case 'dodge'			:	return dodge;
			case 'initiative'		:	return initiative;
			case 'mana'				:	return mana;
			case 'spellPower'		:	return spellPower;
			case 'manaRegeneration'	:	return manaRegeneration;
			case 'speed'			:	return speed;
			default: trace('WARNING: Stat ${statName} not found'); return 0;
		}
	}

	public function forEachNonZero(func : String -> Int -> Void) {
		forEach((name, value) -> {
			if (value != 0) func(name, value);
		});
	}

	public function areAllZero() {
		var nNonZeroStats = 0;
		forEachNonZero((_, _) -> nNonZeroStats++);
		return nNonZeroStats == 0;
	}
	public function getNumberOfNonZeroStats() {
		var nNonZeroStats = 0;
		forEachNonZero((_, _) -> nNonZeroStats++);
		return nNonZeroStats;
	}

	

	public function generateDescription(){
		inline function makeDesc(value, field){
			if(value == 0) return '';
			else if(value > 0)
				return '+$value $field \n ';
			else
				return '$value $field \n ';
		}
		var desc = "";
		desc += makeDesc(damage, 'Damage');
		desc += makeDesc(health, 'Max Health');
		desc += makeDesc(mana, 'Max Mana');
		desc += makeDesc(speed, 'Speed');
		desc += makeDesc(armor, 'Armor');
		desc += makeDesc(manaRegeneration, 'Mana Regen');
		desc += makeDesc(spellPower, 'Spell Power');
		desc += makeDesc(crit, 'Crit %');
		desc += makeDesc(dodge, 'Dodge %');
		desc += makeDesc(initiative, 'Initiative');
		return desc;
	}
	public function toShortString() {
		return 'HP=${health},MN=${mana},DMG=${damage},SP=${spellPower},ARM=${armor},DDG=${dodge},CRT=${crit},SPD=${speed},MR=${manaRegeneration},INI=${initiative}';
	}

	public inline function copy(s : Stats){
		health		= s.health		;
		damage		= s.damage		;
		armor			= s.armor			;
		crit			= s.crit			;
		dodge			= s.dodge			;
		initiative		= s.initiative		;
		mana			= s.mana			;
		spellPower	= s.spellPower	;
		manaRegeneration = s.manaRegeneration ;
		speed			= s.speed			;
	}

	public inline function clone(){
		var stats = new Stats();
		stats.copy(this);
		return stats;
	}

	public inline function add(s : Stats){
		health		+= s.health		;
		damage		+= s.damage	;
		armor			+= s.armor			;
		crit			+= s.crit			;
		dodge			+= s.dodge			;
		initiative		+= s.initiative		;
		mana			+= s.mana		;
		spellPower += s.spellPower;
		manaRegeneration += s.manaRegeneration;
		speed			+= s.speed			;
	}

	public inline function subtract(s : Stats){
		health			-= s.health		;
		damage			-= s.damage	;
		armor			-= s.armor			;
		crit			-= s.crit			;
		dodge			-= s.dodge			;
		initiative		-= s.initiative		;
		mana			-= s.mana		;
		spellPower -= s.spellPower;
		manaRegeneration -= s.manaRegeneration;
		speed			-= s.speed			;
	}

	public static function testStats(){
		var s = new Stats();
		s.health = 10;
		s.damage = 3;
		s.crit = 4;
		return s;
	}

	public static function isPercentage(statName: String) {
		statName = statName.toLowerCase();
		if ([
			'armor',
			'crit',
			'dodge'
		].indexOf(statName) != -1) {
			return true;
		}
		return false;
	}

}