
package scripts;

import scripts.Constants.*;

import U.*;

import Effects.FAST;
import Effects.MEDIUM;
import Effects.SLOW;

import haxe.macro.Expr;
import haxe.macro.Context;


// To create a SpellTemplate, see SpellDatabase.hx

class SpellTemplate
{

	// Data
	public var name 		: String = "Default";
	public var description	: String = "Default";
	public var value		: EntityWithStats -> Int -> Int;		// In the popup, '@'s will be replaced by value(caster, @ index). Interpolation for calculated values basically
	public var range		: Int = 0;
	public var manaCost		: Int = 0;
	public var cooldown		: Int = 1;
	public var doJotAnimation: Bool = true;
	public var preventTurningTowardsTile: Bool = false;

	public var isFreeAction	: Bool = false;				// Does not end the turn
	public var isInstant 	: Bool = false;				// Does not have tile selection
	public var isPassive	: Bool = false;				// If true, it won't appear as a clickable spell in combat
	public var isDefault	: Bool = false;				// If true, you can't unlearn it
	public var isFriendly	: Bool = false;				// Only used for the friendly fire indicator. if true, then the "!" doesn't appear

	public var aiFlags = {
		doesHeal: false,
		doesDamage: true,
		isUsableWhileSilenced: true						// If false and the enemy is silenced, can't cast
	}

	public var effect = {
		type : NO_EFFECT,	// SKILL_SHOT, MULTI_SKILL_SHOT, ANY_ALLY, NORMAL_MOVE, NO_EFFECT, END_TURN, TARGET_IN_RANGE
		hasNoCastDelay: false,
		isDelayed: false,
		directions : {
			up	  		: false,
			left  		: false,
			down  		: false,
			right 		: false,
			upLeft		: false,
			upRight		: false,
			downLeft	: false,
			downRight	: false
		},
		anyAlly : {
			allowSelf : true
		},
		targetInRange : {
			allowSelf : true
		},
		tileInRange : {
			allowUnits: false
		},
		aoeAround : {
			allowEnemies: true,
			allowAllies: true
		},
		events: {
			learn: function(pc: PlayerCharacter) {},
			unlearn: function(pc: PlayerCharacter) {},
			combatStart: function (unit: Unit) {},
			combatEnd: function(unit: Unit) {}
		},
		tidalWaveRows: [0],
		isTidalWaveReversed: false
	}

	public var onCastStart: Unit -> Void;
	public var onTargetedEnemy: Unit -> Unit -> Void;		// caster -> target; Called on a unit when the spell hits the unit
	public var onTargetedTile: Unit -> TileSpace -> Void;	// caster -> tile; Called on a tile when the spell hits the tile
	public var onDelayedSetup: Unit -> TileSpace -> Void;	// caster -> tile; Called ON DELAYED SETUP on the targeted tile
	public var onMiss: Unit -> TileSpace -> Void;			// caster -> tile; Called when the spell does not hit a unit
	public var overrideGetTileHighlightMatrix: Unit -> Matrix<Int>;	// Caster -> tile validity matrix

	public var slashEffect = {
		animationName: "",
		duration: 0.5
	}
	public var missile = {
		animationName	: "",
		isArced			: false,
		speed			: MEDIUM
	}
	public var targetEffect = {
		animationName : "",
		duration	  : 0.5,
		rotatesWithDirection: true,
	}
	public var audio = {
		onCast: '',
		onHit: '',
		onPrepare: ''
	}
	
	public var customData: Dynamic;
	
	public var id = 0;	// Refers to its position in the SpellDatabase array
	
	// The function to call for every unit it hits:
	
	public inline function hasMissile() return missile.animationName != "";
	public inline function hasTargetEffect() return targetEffect.animationName != "";
	public inline function hasSlashEffect() return slashEffect.animationName != "";
	public inline function getIconPath() return 'Icons/${name}.png';

	public function new(n : String, d : String){
		name = n;
		description = d;
	}

	public static function createFromDynamic(givenDynamic : Dynamic){
		var spellTemp = new SpellTemplate(givenDynamic.name, givenDynamic.description);

		if (givenDynamic.name == 'Shoot Arrow') {
			trace('SHOOT ARROW: Has value? ${givenDynamic.value != null}');
		}

		spellTemp.value =
			if (givenDynamic.value != null) givenDynamic.value
			else (caster: EntityWithStats, _: Int) -> -73;
		
		if (givenDynamic.effect == null) throwAndLogError('Spell in database named ${givenDynamic.name} does not have an effect');
		
		if (givenDynamic.range != null) spellTemp.range = givenDynamic.range;
		if (givenDynamic.isFreeAction != null) spellTemp.isFreeAction = givenDynamic.isFreeAction;
		if (givenDynamic.isInstant != null) spellTemp.isInstant = givenDynamic.isInstant;
		if (givenDynamic.isPassive != null) spellTemp.isPassive = givenDynamic.isPassive;
		if (givenDynamic.manaCost != null) spellTemp.manaCost = givenDynamic.manaCost;
		if (givenDynamic.isDefault != null) spellTemp.isDefault = givenDynamic.isDefault;
		if (givenDynamic.isFriendly != null) spellTemp.isFriendly = givenDynamic.isFriendly;
		if (givenDynamic.cooldown != null) spellTemp.cooldown = givenDynamic.cooldown;

		if (givenDynamic.doJotAnimation != null) spellTemp.doJotAnimation = givenDynamic.doJotAnimation;
		if (givenDynamic.preventTurningTowardsTile != null) spellTemp.preventTurningTowardsTile = givenDynamic.preventTurningTowardsTile;
		
		spellTemp.effect.type = Constants.getConstant(givenDynamic.effect.type);

		if (givenDynamic.onCastStart != null) spellTemp.onCastStart = givenDynamic.onCastStart;
		if (givenDynamic.onMiss != null) spellTemp.onMiss = givenDynamic.onMiss;
		if (givenDynamic.onTargetedEnemy != null) spellTemp.onTargetedEnemy = givenDynamic.onTargetedEnemy;
		if (givenDynamic.onTargetedTile != null) spellTemp.onTargetedTile = givenDynamic.onTargetedTile;
		if (givenDynamic.onDelayedSetup != null) spellTemp.onDelayedSetup = givenDynamic.onDelayedSetup;
		if (givenDynamic.overrideGetTileHighlightMatrix != null) spellTemp.overrideGetTileHighlightMatrix = givenDynamic.overrideGetTileHighlightMatrix;
		if (givenDynamic.effect.directions != null) {
			if(givenDynamic.effect.directions.up 			!= null) spellTemp.effect.directions.up		= givenDynamic.effect.directions.up;
			if(givenDynamic.effect.directions.left			!= null) spellTemp.effect.directions.left		= givenDynamic.effect.directions.left;
			if(givenDynamic.effect.directions.down			!= null) spellTemp.effect.directions.down		= givenDynamic.effect.directions.down;
			if(givenDynamic.effect.directions.right		!= null) spellTemp.effect.directions.right		= givenDynamic.effect.directions.right;
			if(givenDynamic.effect.directions.upRight		!= null) spellTemp.effect.directions.upRight	= givenDynamic.effect.directions.upRight;
			if(givenDynamic.effect.directions.upLeft		!= null) spellTemp.effect.directions.upLeft	= givenDynamic.effect.directions.upLeft;
			if(givenDynamic.effect.directions.downRight	!= null) spellTemp.effect.directions.downRight	= givenDynamic.effect.directions.downRight;
			if(givenDynamic.effect.directions.downLeft		!= null) spellTemp.effect.directions.downLeft	= givenDynamic.effect.directions.downLeft;
		}
		if (givenDynamic.effect.hasNoCastDelay != null) spellTemp.effect.hasNoCastDelay = givenDynamic.effect.hasNoCastDelay;
		if (givenDynamic.effect.anyAlly != null) {
			if (givenDynamic.effect.anyAlly.allowSelf != null) spellTemp.effect.anyAlly.allowSelf = givenDynamic.effect.anyAlly.allowSelf;
		}
		if (givenDynamic.effect.targetInRange != null) {
			if (givenDynamic.effect.targetInRange.allowSelf != null) spellTemp.effect.targetInRange.allowSelf = givenDynamic.effect.targetInRange.alowSelf;
		}
		if (givenDynamic.effect.tileInRange != null) {
			if (givenDynamic.effect.tileInRange.allowUnits != null) spellTemp.effect.tileInRange.allowUnits = givenDynamic.effect.tileInRange.allowUnits;
		}
		if (givenDynamic.effect.aoeAround != null) {
			if (givenDynamic.effect.aoeAround.allowEnemies != null) spellTemp.effect.aoeAround.allowEnemies = givenDynamic.effect.aoeAround.allowEnemies;
			if (givenDynamic.effect.aoeAround.allowAllies != null) spellTemp.effect.aoeAround.allowAllies = givenDynamic.effect.aoeAround.allowAllies;
		}
		if (givenDynamic.events != null) {
			trace('WARNING: Spell ${givenDynamic.name} has events at base level, not in effects!');
		}
		if (givenDynamic.effect.events != null) {
			if (givenDynamic.effect.events.learn != null) {
				spellTemp.effect.events.learn = givenDynamic.effect.events.learn;
			}
			if (givenDynamic.effect.events.unlearn != null) {
				spellTemp.effect.events.unlearn = givenDynamic.effect.events.unlearn;
			}
			if (givenDynamic.effect.events.combatStart != null) {
				spellTemp.effect.events.combatStart = givenDynamic.effect.events.combatStart;
			}
			if (givenDynamic.effect.events.combatEnd != null) {
				spellTemp.effect.events.combatEnd = givenDynamic.effect.events.combatEnd;
			}
		}
		spellTemp.effect.isDelayed = nullOr(givenDynamic.effect.isDelayed, false);
		spellTemp.effect.tidalWaveRows = nullOr(givenDynamic.effect.tidalWaveRows, []);
		spellTemp.effect.isTidalWaveReversed = nullOr(givenDynamic.effect.isTidalWaveReversed, false);


		if (givenDynamic.slashEffect != null) {
			if (givenDynamic.slashEffect.animationName != null) spellTemp.slashEffect.animationName = givenDynamic.slashEffect.animationName;
			if (givenDynamic.slashEffect.duration != null) spellTemp.slashEffect.duration = givenDynamic.slashEffect.duration;
		}
		if (givenDynamic.missile != null) {
			if (givenDynamic.missile.animationName != null) spellTemp.missile.animationName = givenDynamic.missile.animationName;
			if (givenDynamic.missile.speed != null) spellTemp.missile.speed = Constants.getConstant(givenDynamic.missile.speed);
			if (givenDynamic.missile.isArced != null) spellTemp.missile.isArced = givenDynamic.missile.isArced;
		}
		if (givenDynamic.targetEffect != null) {
			if (givenDynamic.targetEffect.animationName != null) spellTemp.targetEffect.animationName = givenDynamic.targetEffect.animationName;
			if (givenDynamic.targetEffect.duration != null) spellTemp.targetEffect.duration = givenDynamic.targetEffect.duration;
			if (givenDynamic.targetEffect.rotatesWithDirection != null) spellTemp.targetEffect.rotatesWithDirection = givenDynamic.targetEffect.rotatesWithDirection;
		}
		if (givenDynamic.aiFlags != null) {
			if (givenDynamic.aiFlags.doesHeal != null) spellTemp.aiFlags.doesHeal = givenDynamic.aiFlags.doesHeal;
			if (givenDynamic.aiFlags.doesDamage != null) spellTemp.aiFlags.doesDamage = givenDynamic.aiFlags.doesDamage;
			if (givenDynamic.aiFlags.isUsableWhileSilenced != null) spellTemp.aiFlags.isUsableWhileSilenced = givenDynamic.aiFlags.isUsableWhileSilenced;
		}
		if (givenDynamic.audio != null) {
			spellTemp.audio.onCast = nullOr(givenDynamic.audio.onCast, '');
			spellTemp.audio.onHit = nullOr(givenDynamic.audio.onHit, '');
			spellTemp.audio.onPrepare = nullOr(givenDynamic.audio.onPrepare, '');
		}
		if (givenDynamic.customData != null) {
			spellTemp.customData = givenDynamic.customData;
		}
		return spellTemp;
		
	}
}



