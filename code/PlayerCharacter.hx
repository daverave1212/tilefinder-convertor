
package scripts;

import com.stencyl.Engine;

import scripts.Constants.*;
import Math.max;
import Std.int;


import U.*;


// A set of data for a character the player has
// EntityWithStats just means it has stats (Stats), resistances (Resistances) and a name, health and mana
class PlayerCharacter extends EntityWithStats
{

	public static var k = {
		inventorySize : 4,
		maxNumberOfSpellsOfAType: 5	// Passive or Active (5 passive max, 5 active max)
	}

	public var characterClass	: CharacterClass;
	public var level			: Int;

	public var experience		: Int = 0;

	public var equippedItems 	: Array<Item>;
	public var equippedSpells	: Array<String>;

	public var customData = {
		ints: new Map<String, Int>(),
		strings: new Map<String, String>()
	}


	public function toDynamic() {
		var playerCharacter = {
			name: name,
			characterClassName: characterClass.name,
			level: level,
			
			health: health,
			mana: mana,
			stats: stats.toDynamic(),
			resistances: resistances.toDynamic(),
			amplifications: amplifications.toDynamic(),
			experience: experience,
			
			equippedItems: equippedItems.map(item -> if (item != null) item.name else null),
			equippedSpells: equippedSpells
		}
		return playerCharacter;
	}
	public static function createFromDynamic(dyn: Dynamic) {
		var playerCharacter = new PlayerCharacter(dyn.name, dyn.characterClassName);
		playerCharacter.level = dyn.level;
		
		playerCharacter.health = dyn.health;
		playerCharacter.mana = dyn.mana;
		playerCharacter.stats = Stats.createFromDynamic(dyn.stats);
		playerCharacter.resistances = if (dyn.resistances != null) Resistances.createFromDynamic(dyn.resistances) else new Resistances();
		playerCharacter.amplifications = if (dyn.amplifications != null) Amplifications.createFromDynamic(dyn.amplifications) else new Amplifications();
		playerCharacter.experience = dyn.experience;

		final itemNames: Array<String> = dyn.equippedItems;
		playerCharacter.equippedItems = itemNames.map(itemName -> if (itemName != null) ItemsDatabase.get(itemName) else null);
		playerCharacter.equippedSpells = dyn.equippedSpells;
		
		return playerCharacter;
	}



	public function new(n, charClassName : String) {
		trace('Creating character with class ${charClassName}');
		name = n;
		characterClass = CharacterClassDatabase.get(charClassName);
		level = 1;
		stats = characterClass.stats.clone();
		resistances = new Resistances();
		amplifications = new Amplifications();
		equippedItems = [for (_ in 0...k.inventorySize) null];
		health = stats.health;
		mana = stats.mana;
		customData.ints = [];
		customData.strings = [];
		if (Player.progression.defeatedNatas)
			Player.setupNatasPermanentBuffs(this);
		equippedSpells = characterClass.startingSpells.copy();
		final permanentPassives = Player.progression.lectureTablePassives.filter(cs -> cs.char == charClassName).map(cs -> cs.spell);
		final filteredPermanentPassives = permanentPassives.filter(spellName -> spellName != 'Tuberculosis' && spellName != 'Soul Drain');	// For older saved games, to make sure it doesn't crash
		for (spell in filteredPermanentPassives) {
			equipSpell(spell);
		}
		if (Player.progression.didMarcelineDefeatedEncounter) {
			final availableSpells = CharacterClassDatabase.get(charClassName).availableSpells.map(name -> SpellDatabase.get(name)).filter(s -> s.isPassive == false);
			shuffle(availableSpells);
			for (spell in availableSpells) {
				if (hasSlotForSpell(spell.name)) {
					equipSpell(spell.name);
					break;
				}
			}
		}
		if (Player.isTurboModeEnabled) {
			// stats.health = 900;
			// health = 900;
			// stats.damage = 98;
			// stats.spellPower = 98;
		}
	}

	public function equipItemStandalone(?item : Item, ?itemName: String) {
		if (itemName != null)
			item = ItemsDatabase.get(itemName);
		var firstEmptySlotPos = U.getFirstNull(equippedItems);
		if (firstEmptySlotPos == -1) return false;
		equippedItems[firstEmptySlotPos] = item;
		addItemStats(item);
		return true;
	}
	public function equipItemFromInventory(?pos : Int, ?item : Item, inventory : Inventory<Item>) { // Returns true if item was equipped. False if not.
		if (pos != null) {
			item = equippedItems[pos];
		}
		if (item == null) throw 'Null item when calling equipItemFromInventory; given pos is $pos';
		var didEquip = equipItemStandalone(item);
		var didRemove = inventory.findAndRemove(item);
		recalculateCurrentHealthAndMana();
		return (didEquip && didRemove);
	}
	public function subtractItemStats(item: Item) {
		if (item.stats != null) {
			stats.subtract(item.stats);
			health = int(max(health - item.stats.health, 1));
			mana = int(max(mana - item.stats.mana, 1));
		}
		if (item.resistances != null) resistances.subtract(item.resistances);
		if (item.amplifications != null) amplifications.subtract(item.amplifications);
	}
	public function addItemStats(item: Item) {
		if (item.stats != null) {
			stats.add(item.stats);
			health += item.stats.health;
			mana += item.stats.mana;
		}
		if (item.resistances != null) resistances.add(item.resistances);
		if (item.amplifications != null) amplifications.add(item.amplifications);
	}
	public function removeItem(itemName: String): Item {
		var pos = -1;
		for (i in 0...equippedItems.length) {
			if (equippedItems[i] != null && equippedItems[i].name == itemName) {
				pos = i;
				break;
			}
		}
		if (pos == -1) return null;
		final item = equippedItems[pos];
		subtractItemStats(item);
		equippedItems[pos] = null;
		return item;
	}
	public function unequipItemToInventory(?item : Item, ?pos : Int, inventory : Inventory<Item>) {
		function unequipItem(?item : Item, ?pos : Int) {
			if(item != null && pos == null)
				pos = equippedItems.indexOf(item);
			if(pos == -1 || pos >= k.inventorySize) return;
			item = equippedItems[pos];
			subtractItemStats(item);
			equippedItems[pos] = null;
		}
		if (inventory.isFull())	return false;
		unequipItem(item, pos);
		inventory.add(item);
		recalculateCurrentHealthAndMana();
		return true;
	}

	public function equipSpell(spellName : String) {
		if (spellName == null) throw 'Null spell name given to equipSpell';
		if (hasSlotForSpell(spellName) == false) {
			trace('WARNING: Can not equip spell ${spellName} with full equip slots!');
			return;
		}
		playAudio('EquipSpellAudio');
		equippedSpells.push(spellName);
		SpellDatabase.get(spellName).effect.events.learn(this);
	}
	public function unequipSpell(?index : Int, ?spellName : String) {
		if (spellName != null) {
			index = getEquippedSpellIndexByName(spellName);
		}
		equippedSpells.splice(index, 1);
		SpellDatabase.get(spellName).effect.events.learn(this);
	}
	public function equipSpellFromInventory(tome: Item, inventory: Inventory<Item>) {
		final spellName = ItemsDatabase.getSpellNameFromItemName(tome.name);
		if (hasSlotForSpell(spellName) == false) {
			trace('WARNING: Can not equip spell ${spellName} with full equip slots!');
			return;
		}
		tome.consume(inventory);
		equipSpell(spellName);
	}
	public function replaceEquippedSpell(spellName: String, replaceWith: String) {
		final spellIndex = equippedSpells.indexOf(spellName);
		if (spellIndex == -1) {
			trace('WARNING: No spell ${spellName} equipped on ${name}');
			return;
		}
		equippedSpells[spellIndex] = replaceWith;
		final spellTemplate = SpellDatabase.get(spellName);
		if (spellTemplate == null) {
			throw 'ERROR: No spell named ${replaceWith} found for replacing!';
		}
		spellTemplate.effect.events.learn(this);
	}
	public function useItemFromInventory(item: Item) {
		item.use(null, this);
		item.consume(Player.inventory);
	}

	public function canClassLearnSpell(spellName: String) {
		return characterClass.availableSpells.indexOf(spellName) != -1;
	}
	public function hasSlotForSpell(spellName: String) {
			final spell = SpellDatabase.get(spellName);
			if (spell.isPassive) {
				if (getPassiveSpells().length >= k.maxNumberOfSpellsOfAType) {
					return false;
				}
			} else {
				if (getActiveUnlearnableSpells().length >= k.maxNumberOfSpellsOfAType) {
					return false;
				}
			}
			return true;
		}
	public function hasSpell(spellName: String) return equippedSpells.indexOf(spellName) != -1;
	public function getSpells(): Array<SpellTemplate> return equippedSpells.map(name -> SpellDatabase.get(name));
	public function getActiveUnlearnableSpells(): Array<SpellTemplate> return getSpells().filter(templ -> !!!templ.isDefault && !!!templ.isPassive);
	public function getPassiveSpells(): Array<SpellTemplate> return getSpells().filter(templ -> templ.isPassive);
	public function getPassiveSpellNames(): Array<String> return getPassiveSpells().map(templ -> templ.name);
	public function getPassiveBindableSpellNames(): Array<String> return getPassiveSpellNames().filter(name -> ['Soul Drain', 'Tuberculosis'].indexOf(name) == -1);
	public function getAudioOnHit() return characterClass.audio.onHit;
	public function getAudioOnDeath() return characterClass.audio.onDeath;
	public function getEquippedItems() return equippedItems.filter(item -> item != null);
	public function hasAudioOnHit() return characterClass.audio.onHit != null && characterClass.audio.onHit.length > 0;
	public function hasAudioOnDeath() return characterClass.audio.onDeath != null && characterClass.audio.onDeath.length > 0;
	public function hasFullActiveUnlearnableSpells() return getActiveUnlearnableSpells().length == k.maxNumberOfSpellsOfAType;
	public function hasFullPassiveSpells() return getPassiveSpells().length == k.maxNumberOfSpellsOfAType;
	public function getMissingHealth() return stats.health - health;
	public function isDead() return health <= 0;

	public function getEquippedSpellIndexByName(name) {
		for (i in 0...equippedSpells.length) {
			if (name == equippedSpells[i]) return i;
		}
		return -1;
	}	

	function recalculateCurrentHealthAndMana() {
		// TODO: There is definitely something wrong here lol
		var healthDeficit = stats.health - health;
		var manaDeficit = stats.mana - mana;
		health = stats.health - healthDeficit;
		mana = stats.mana - manaDeficit;
	}


	public inline function getClassName() return characterClass.name;
	public inline function getCombatStartQuotes() return characterClass.combatStartQuotes.copy();
	public inline function getKillQuotes() return characterClass.killQuotes.copy();
	public inline function getMaxHealth() return stats.health;
	public function hasItem(itemName: String) return getEquippedItems().map(item -> item.name).indexOf(itemName) != -1;
	public function hasSpecificItem(item: Item) return getEquippedItems().indexOf(item) != -1;
	public function isInventoryFull() return equippedItems.filter(item -> item != null).length == k.inventorySize;


	public function damage(amount: Int) {
		health -= amount;
		if (health < 0) {
			health = 0;
		}
	}
	public function heal(amount: Int) {
		trace('Healing character ${name} for ${amount}');
		health += amount;
		if (health > stats.health) {
			health = stats.health;
		}
	}
	public function replenish(amount: Int) {
		mana += amount;
		if (mana > stats.mana) {
			mana = stats.mana;
		}
	}
	public function levelUp() {
		stats.health += 1;
		stats.mana += 1;
		stats.damage += 1;
		stats.spellPower += 1;
	}
	public function addExperience(xp : Int) {
		experience += xp;
		if (experience >= getExperienceNeededToLevelUp()) {
			experience = getExperienceNeededToLevelUp() - xp;
			levelUp();
		}
	}
	public function getExperienceNeededToLevelUp() {
		return 5 + level * 5;
	}

	public function isAmongUnits(units : Array<Unit>) {
		return units.filter(unit -> unit.name == getClassName()).length >= 1;
	}

	public function healAtEndOfCombat() {
		if (hasSpell('Hero Health')) {
			final healAmount = SpellDatabase.get('Hero Health').customData.healAmount;
			heal(healAmount);
		}
		heal(int(0.2 * stats.health));
	}


}