

package scripts;

import scripts.Constants.*;

import Std.int;
import Math.*;


import U.*;
using U;



class Item
{

	public var id				: Int = 0;				// Position in Array
	public var name 			: String = "ITEM";
	public var level 			: Int = 1;
	public var tags				: Array<Int> = [];
	public var rarity 			: Int = TRASH;
	public var imagePath 		: String;
	public var price 			: Int = 0;
	public var isStackable  	: Bool = false;
	public var type				: String = "GEAR";	// SPELL or CONSUMABLE or JUNK
	public var flavor			: String = "";
	public var nStacks 			: Int = 0;
	public var stats 			: Stats;
	public var resistances		: Resistances;
	public var amplifications	: Amplifications;
	public var effect = {
		description: "",
		healAmount: 0,
		replenishAmount: 0,
		audio: '',
		isCombatOnly: false,
		isNonCombatOnly: false
	}
	public var onUse			: Unit -> ?PlayerCharacter -> Void;
	public var onCombatStart	: Unit -> Void;
	public var onCombatEnd		: Unit -> Void;
	public var customData: Dynamic = null;

	public var appearCondition	: Void -> Bool;		// If this is false, then it will not be selected for loot or shop

	public function new() {}
	
	public function isAvailable() return appearCondition != null && appearCondition();
	public inline function setSellPrice(sellPrice: Int) price = realPriceFromSellPrice(sellPrice);
	public inline function getSellPrice(): Int return Std.int(price / 5);
	public inline function getDescription() return if (flavor != null && flavor.length > 0) flavor else if (effect.description != null) effect.description else 'None';
	public function getSpellTemplate(): SpellTemplate {
		if (type != 'SPELL') throw 'ERROR: Can not get spell from item ${name}; it is not a spell';
		final spellName = ItemsDatabase.getSpellNameFromItemName(name);
		final spellTemplate = SpellDatabase.get(spellName);
		return spellTemplate;
	}
	public static inline function realPriceFromSellPrice(sellPrice: Int): Int return sellPrice * 2;
	public inline function hasNoStats() return stats == null || stats.areAllZero();
	public inline function isSpecial() return tags.indexOf(SPECIAL_ITEM) != -1;
	public function getNumberOfNonZeroStats() return if (stats == null) 0 else stats.getNumberOfNonZeroStats();
	public inline function hasTag(tag: Int) {
		return tags.indexOf(tag) != -1;
	}
	public function reduceQuality(): Void {
		price = int(price * 0.8);
		if (stats == null) return;
		stats.health = int(stats.health * 0.8);
		stats.mana = int(stats.mana * 0.8);
		stats.damage = int(stats.damage * 0.8);
		stats.dodge = int(stats.dodge * 0.8);
		stats.armor = int(stats.armor * 0.8);
		stats.manaRegeneration = int(stats.manaRegeneration * 0.8);
		stats.spellPower = int(stats.spellPower * 0.8);
		stats.initiative = int(stats.initiative * 0.8);
	}
	public function improveQuality(?byScale = 1.5): Void {
		function getImprovedStat(oldValue: Int): Int {
			if (oldValue == 0) return oldValue;
			if (int(oldValue * byScale) != oldValue) return int(oldValue * byScale); // If it makes any difference
			if (oldValue < 0) {													// Otherwise just change it by 1
				return oldValue - 1;
			} else {
				return oldValue + 1;
			}
		}
		if (stats == null) return;
		stats.health = getImprovedStat(stats.health);
		stats.mana = getImprovedStat(stats.mana);
		stats.damage = getImprovedStat(stats.damage);
		stats.dodge = getImprovedStat(stats.dodge);
		stats.armor = getImprovedStat(stats.armor);
		stats.spellPower = getImprovedStat(stats.spellPower);
		stats.initiative = getImprovedStat(stats.initiative);
	}

	public function use(user : Unit, ?playerCharacter: PlayerCharacter) {
		if (effect.audio.length > 0)
			playAudio(effect.audio);
		if (onUse != null)
			onUse(user, playerCharacter);
	}


	// Consumes 1 charge from the item.
	// If charges become less than 0, removes the item
	public function consume(parentInventory : Inventory<Item>){
		var coordinates = parentInventory.find(this);
		if(coordinates == null) return null;
		if(isStackable){
			nStacks--;
			if(nStacks == 0){
				parentInventory.remove(coordinates.i, coordinates.j);
			}
		} else {
			parentInventory.remove(coordinates.i, coordinates.j);
		}
		return coordinates;
	}

	public function clone() {
		var item = new Item();
		item.id					= this.id;
		item.name 				= this.name;
		item.type 	 			= this.type;
		item.level 				= this.level;
		item.tags 				= this.tags;
		item.rarity 			= this.rarity;
		item.imagePath 			= this.imagePath;
		item.price 				= this.price;
		item.isStackable  		= this.isStackable;		
		item.nStacks 			= this.nStacks;
		item.flavor 			= this.flavor;
		item.stats 				= if (this.stats != null) this.stats.clone() else null;
		item.resistances		= if (this.resistances != null) this.resistances.clone() else null;
		item.amplifications		= if (this.amplifications != null) this.amplifications.clone() else null;
		item.effect.description = this.effect.description;
		item.effect.healAmount 	= this.effect.healAmount;
		item.effect.audio 		= this.effect.audio;
		item.effect.isCombatOnly= this.effect.isCombatOnly;
		item.effect.isNonCombatOnly= this.effect.isNonCombatOnly;
		item.onUse				= this.onUse;
		item.onCombatStart		= this.onCombatStart;
		item.onCombatEnd		= this.onCombatEnd;
		item.appearCondition	= this.appearCondition;
		return item;
	}


	public static function createFromDynamic(i: Dynamic) {
		var item = new Item();
		item.name = i.name;
		if (i.imagePath != null) item.imagePath = i.imagePath;
		if (i.icon != null) item.imagePath = i.icon;
		if (i.level	!= null) item.level	= i.level;
		if (i.rarity != null) item.rarity	= i.rarity;
		if (i.tags != null) item.tags	= i.tags;
		if (i.price != null) item.price	= i.price;
		if (i.isStackable != null) item.isStackable	= i.isStackable;
		if (i.type != null) item.type	= i.type;
		if (i.nStacks != null) item.nStacks	= i.nStacks;
		if (i.flavor != null) item.flavor = i.flavor;
		if (i.stats != null) {
			var stats = i.stats;
			item.stats = Stats.createFromDynamic(stats);
		}
		if (i.resistances != null) {
			var resistances = i.resistances;
			item.resistances = Resistances.createFromDynamicForItem(resistances);
		}
		if (i.amplifications != null){
			var amplifications = i.amplifications;
			item.amplifications = Amplifications.createFromDynamic(amplifications);
		}
		if (i.effect != null){
			if (i.effect.description != null) item.effect.description = i.effect.description;
			if (i.effect.healAmount != null) item.effect.healAmount = i.effect.healAmount;
			if (i.effect.replenishAmount != null) item.effect.replenishAmount = i.effect.replenishAmount;
			if (i.effect.audio != null) item.effect.audio = i.effect.audio;
			if (i.effect.isCombatOnly != null) item.effect.isCombatOnly = i.effect.isCombatOnly;
			if (i.effect.isNonCombatOnly != null) item.effect.isNonCombatOnly = i.effect.isNonCombatOnly;
		}
		if (i.type == 'CONSUMABLE' && i.onUse == null) {
			// throwAndLogError('Consumable ${i.name} has no onUse function.');
		}
		item.onUse = i.onUse;
		item.onCombatStart = i.onCombatStart;
		item.onCombatEnd = i.onCombatEnd;
		item.appearCondition = i.appearCondition;
		return item;
	}

}