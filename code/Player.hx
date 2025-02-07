
package scripts;


import com.stencyl.graphics.G;
import com.stencyl.graphics.BitmapWrapper;

import com.stencyl.behavior.Script;
import com.stencyl.behavior.Script.*;
import com.stencyl.behavior.ActorScript;
import com.stencyl.behavior.SceneScript;
import com.stencyl.behavior.TimedTask;

import com.stencyl.models.Actor;
import com.stencyl.models.GameModel;
import com.stencyl.models.actor.Animation;
import com.stencyl.models.actor.ActorType;
import com.stencyl.models.actor.Collision;
import com.stencyl.models.actor.Group;
import com.stencyl.models.Scene;
import com.stencyl.models.Sound;
import com.stencyl.models.Region;
import com.stencyl.models.Font;
import com.stencyl.models.Joystick;

import com.stencyl.Engine;
import com.stencyl.Input;
import com.stencyl.Key;
import com.stencyl.utils.Utils;

import openfl.ui.Mouse;
import openfl.display.Graphics;
import openfl.display.BlendMode;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.TouchEvent;
import openfl.net.URLLoader;

import box2D.common.math.B2Vec2;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2Fixture;
import box2D.dynamics.joints.B2Joint;

import com.stencyl.utils.motion.*;

import U.*;
import Std.int;

import scripts.Game.q;

import scripts.Constants.*;

class Player
{
	
	public static var k = {
		inventoryNRows : 3,
		inventoryNCols : 6
	};
	
	public static var gold: Int = 0;
	public static var totalGoldAcquiredThisRun: Int = 0;
	public static var inventory: Inventory<Item>;
	public static var characters: Array<PlayerCharacter> = [];
	public static var mercenaries: Array<PlayerMercenary> = [];

	public static var isTurboModeEnabled = false;
	public static var isAIModeEnabled = false;


	// Variables
	public static var updateVersion = '2023-02-01';	// Change this every update
	public static var patchNotes = '
		${updateVersion}
		Bugfixes and Balance Updates.
		Check the FAQ on the store page.
		Press here for full patch notes.
	';
	public static var patchNotesMobile = '
		${updateVersion}
		Released on Android!
		Notify me for any bug you find!
	';
	public static var patchNotesURL = 'https://store.steampowered.com/news/app/1927570';
	public static var saveVersion = '1.20demo';			// Change this hardcoded value when progression changes

	// @:keepSub used for reflection, for debugging; used only in LogCommands
	@:keepSub public static var progression = {
		nRunsAttempted: 0,
		nRunsCompleted: 0,

		// Tutorial
		tutorialDidClickOnMove: false,
		tutorialDidMoveOnce: false,
		tutorialDidClickOnAttack: false,
		tutorialDidAttackOnce: false,
		tutorialDidEndTurn: false,
		tutorialDidShopTutorial: false,
		tutorialIsDone: false,
		tutorialDidUnlockableSelect: false,
		tutorialMetGoblinOnce: false,
		tutorialMetCrystalOnce: false,

		// Run-to-run storing
		currentJourneyIndex: 0,
		nCombatsWonThisRun: 0,
		hasNatasBuff: false,
		piratesItemsStored: new Array<String>(),
		piratesGoldStored: 0,

		// Permanent unlockables
		isRangerUnlocked: false,
		isMageUnlocked: false,
		isCellarKeyFound: false,
		hasStartingGear: false,
		isFallenHeroReunited: false,
		didTalkToNatasOnce: false,
		nTileShardsFound: 0,
		isVampireWeakened: false,

		// Lecture Table
		lectureTablePassives: new Array<{char: String, spell: String}>(),

		// Dialogue Encounters done
		didKingIntro: false,
		didMarcelineEncounter: false,
		didMarcelineEncounter2: false,
		didKingPleadEncounter: false,
		didKingDefeatedEncounter: false,
		didMarcelineDefeatedEncounter: false,

		defeatedStormjr2: false,
		didStormjrAskWhoIsYourBrother: false,
		didStormjrAskHowDoWeDefeatTyl: false,
		didStormjrAskWhoIsLordOfHell: false,
		didStormjr3Dialogue: false,
		didNatasClarificationDialogue: false,

		didNanaJoyMeeting: false,
		defeatedSandman: false,
		didNanaJoyAfterDialogue: false,

		// Bosses defeated
		defeatedPumpzilla: false,
		defeatedStormjr: false,
		defeatedSpatula1: false,
		defeatedBlessedChildren: false,
		defeatedCaptainStashton: false,
		defeatedSpatula2: false,
		defeatedFatherAlmund: false,
		sidedWith: 'none',	// Marceline or King
		defeatedKingOrMarceline: false,
		defeatedTyl: false,
		defeatedNatas: false,
	}


	public static function toDynamic() {
		var player = {
			gold: gold,
			itemsInInventory:
				if (inventory == null) []
				else inventory.filterToArray(item -> item != null).map(item -> item.name),
			characters: characters.map(character -> character.toDynamic()),
			progression: progression
		}
		return player;
	}
	public static function loadFromDynamic(dyn: Dynamic) {
		trace('Loading player from dynamic');
		
		// Normalize the Dynamic object to make sure it's compatible with current progression
		if (dyn.nRunsAttempted == null) dyn.nRunsAttempted = 0;
		if (dyn.nRunsCompleted == null) dyn.nRunsCompleted = 0;

		gold = dyn.gold;
		inventory.clear();
		final itemsInInventory: Array<String> = dyn.itemsInInventory;
		inventory.addArray(itemsInInventory.map(itemName -> ItemsDatabase.get(itemName)));
		characters = dyn.characters.map(charDyn -> PlayerCharacter.createFromDynamic(charDyn));
		progression = dyn.progression;
	}
	public static function resetProgression() {
		progression = {
			nRunsAttempted: 0,
			nRunsCompleted: 0,

			// Tutorial
			tutorialDidClickOnMove: false,
			tutorialDidMoveOnce: false,
			tutorialDidClickOnAttack: false,
			tutorialDidAttackOnce: false,
			tutorialDidEndTurn: false,
			tutorialDidShopTutorial: false,
			tutorialIsDone: false,
			tutorialDidUnlockableSelect: false,
			tutorialMetGoblinOnce: false,
			tutorialMetCrystalOnce: false,
	
			// Run-to-run storing
			currentJourneyIndex: 0,
			nCombatsWonThisRun: 0,
			hasNatasBuff: false,
			piratesItemsStored: new Array<String>(),
			piratesGoldStored: 0,
	
			// Permanent unlockables
			isRangerUnlocked: false,
			isMageUnlocked: false,
			isCellarKeyFound: false,
			hasStartingGear: false,
			isFallenHeroReunited: false,
			didTalkToNatasOnce: false,
			defeatedNatas: false,
			nTileShardsFound: 0,
			isVampireWeakened: false,
	
			// Lecture Table
			lectureTablePassives: new Array<{char: String, spell: String}>(),
	
			// Dialogue Encounters done
			didKingIntro: false,
			didMarcelineEncounter: false,
			didMarcelineEncounter2: false,
			didKingPleadEncounter: false,
			didKingDefeatedEncounter: false,
			didMarcelineDefeatedEncounter: false,
	
			defeatedStormjr2: false,
			didStormjrAskWhoIsYourBrother: false,
			didStormjrAskHowDoWeDefeatTyl: false,
			didStormjrAskWhoIsLordOfHell: false,
			didStormjr3Dialogue: false,
			didNatasClarificationDialogue: false,

			didNanaJoyMeeting: false,
			defeatedSandman: false,
			didNanaJoyAfterDialogue: false,
	
			// Bosses defeated
			defeatedPumpzilla: false,
			defeatedStormjr: false,
			defeatedSpatula1: false,
			defeatedBlessedChildren: false,
			defeatedCaptainStashton: false,
			defeatedSpatula2: false,
			defeatedFatherAlmund: false,
			sidedWith: 'none',	// Marceline or King
			defeatedKingOrMarceline: false,
			defeatedTyl: false
		}
	}
	public static function curateProgression() {	// This is used to clear problems and bugs from older versions; called on Game.load
		if (progression.lectureTablePassives != null) {
			progression.lectureTablePassives = progression.lectureTablePassives.filter(cs -> SpellDatabase.spellExists(cs.spell));
		}
	}

	public static function init() {
		gold = 0;
		totalGoldAcquiredThisRun = 0;
		inventory = new Inventory<Item>(k.inventoryNRows, k.inventoryNCols);
		characters = [];
	}

	public static function addCharacter(name: String, className: String) {
		var theCharacter = new PlayerCharacter(name, className);
		characters.push(theCharacter);
		return theCharacter;
	}
	public static function addMercenary(name: String) {
		mercenaries.push(new PlayerMercenary(UnitsDatabase.get(name)));
	}

	public static function getCharacter(charName : String) {
		var chars = characters.filter(function(character) return character.name == charName);
		if (chars.length == 1) return chars[0];
		return null;
	}

	public static function autoequipItem(item: Item) {
		if (item.type != 'GEAR') throwAndLogError('Can not equip a non GEAR item ${item.name}!');
		for (character in characters) {
			if (character.hasItem(item.name)) continue;
			if (character.isInventoryFull()) continue;
			if (Player.hasItem(item.name)) {
				character.equipItemFromInventory(item, inventory);
				return true;
			} else {
				character.equipItemStandalone(item);
				return true;
			}
		}
		return false;
	}
	public static function autolearnSpell(tome: Item) {
		if (tome.type != 'SPELL') throwAndLogError('Can not learn a non SPELL item ${tome.name}!');
		final spellName = ItemsDatabase.getSpellNameFromItemName(tome.name);
		var isSpellAlreadyEquippedOnACharacter = false;
		var charactersThatCanEquipThis: Array<PlayerCharacter> = [];
		for (character in characters) {
			final hasSpellAvailable = character.characterClass.availableSpells.indexOf(spellName) != -1;
			final isSpellEquipped   = character.equippedSpells.indexOf(spellName) != -1;
			final hasAvailableSlots = character.hasSlotForSpell(spellName);
			if (hasAvailableSlots == false) {
				continue;
			}
			if (hasSpellAvailable) {
				charactersThatCanEquipThis.push(character);
			}
			if (isSpellEquipped) {
				isSpellAlreadyEquippedOnACharacter = true;
				break;
			}
		}
		if (charactersThatCanEquipThis.length == 0) return false;	// If nobody can equip this, don't do anything
		if (isSpellAlreadyEquippedOnACharacter) return false;		// If a character already has this equipped, don't do anything
		if (charactersThatCanEquipThis.length > 1) return false;	// If it's possible for multiple characters to learn this, don't do anything
		final spellTemplate = SpellDatabase.get(ItemsDatabase.getSpellNameFromItemName(tome.name));
		final characterToEquip = charactersThatCanEquipThis[0];
		if (spellTemplate.isPassive && characterToEquip.hasFullPassiveSpells()) return false;
		if (spellTemplate.isPassive == false && characterToEquip.hasFullActiveUnlearnableSpells()) return false;
		if (hasItem(tome.name)) {
			characterToEquip.equipSpellFromInventory(tome, inventory);
		} else {
			characterToEquip.equipSpell(ItemsDatabase.getSpellNameFromItemName(tome.name));
		}
		return true;
	}
	public static function autolearnOrEquip(item: Item) {
		if (item.type == 'GEAR') {
			autoequipItem(item);
		}
		if (item.type == 'SPELL') {
			if (Game.savedSettings.autoEquipSpells) {
				autolearnSpell(item);
			}
		}
	}
	public static function tryBuyItemFromInventory(item: Item, inv: Inventory<Item>) {
		if (gold < item.price) return false;
		if (inventory.isFull()) return false;
		item.consume(inv);
		inventory.add(item);
		gold -= item.price;
		autolearnOrEquip(item);
		return true;
	}
	public static function sellItem(item: Item) {
		item.consume(inventory);
		gold += int(item.getSellPrice());
	}

	public static var _disableMessagesIntro = false;

	public static function startTutorialRun() {
		reset();
		var andrew = Player.addCharacter('Andrew', 'Knight');
		andrew.equippedSpells.remove('Block');
		playMusic('DarkTensionMusic');
		Chapters.getTutorialChapter().doOnStartEventAndThen(() -> {});
	}
	public static function reset() {
		characters = [];
		mercenaries = [];
		inventory = new Inventory<Item>(k.inventoryNRows, k.inventoryNCols);
		progression.currentJourneyIndex = -1;
		progression.nCombatsWonThisRun = 0;
		setGameAttribute('IsInRun', 'NO');
		gold = 30;
	}
	public static function startNewRun(willDisplayAd = false) {
		function doMessages(andThen) {
			playAudioNow('AdventureMusic', U.MUSIC_CHANNEL);
			final messages: Array<String> = MiscDatabases.getNewGameMessagesBasedOnNRuns(progression.nRunsAttempted);
			progression.nRunsAttempted += 1;
			doAfter(100, () -> {
				if (willDisplayAd) {
					MessageScreen.showInterstitialAdOnNextMessageScreen();
				}
				MessageScreen.goToMessageScreenOptionsAndThen(messages[0], { color: 'WHITE', initialPauseDuration: 2500 }, () -> {
					if (messages.length == 1) {
						andThen();
						return;
					}
					MessageScreen.goToMessageScreenWhiteAndThen(messages[1], () -> {
						if (messages.length == 2) {
							andThen();
							return;
						}
						MessageScreen.goToMessageScreenWhiteAndThen(messages[2], () -> {
							andThen();
						});
					});
				});
			});
		}
		function selectCharacterAndStart() {
			CharacterSelect.goToCharacterSelect(() -> {
				if (progression.hasNatasBuff) {
					progression.hasNatasBuff = false;
					PlayerProgression.setupNatasTemporaryBuffs();
				}
				Chapters.getRegularRun().doOnStartEventAndThen(() -> {
					startNextJourneyInThisChapter();
				});
			});
		}
		reset();
		if (isTurboModeEnabled == false && _disableMessagesIntro == false) {
			doMessages(() -> {
				selectCharacterAndStart();
			});
		} else {
			selectCharacterAndStart();
		}
	}
	public static function startNextJourneyInThisChapter() {
		q('P P: Next journey.');
		progression.currentJourneyIndex ++;
		q('P P: currentJourneyIndex: ${progression.currentJourneyIndex}');
		if (getCurrentJourneyInCurrentChapter() == null) {
			q('ERROR: Current journey is null!!!');
			return;
		}
		while (getCurrentJourneyInCurrentChapter().isSpecial) {
			progression.currentJourneyIndex ++;
		}
		q('P P: Found journey: ${progression.currentJourneyIndex}');
		startNewJourney(progression.currentJourneyIndex);
	}
	public static function startNewJourney(journeyIndex: Int) {
		q('P P: Starting new journey.');
		progression.currentJourneyIndex = journeyIndex;
		final currentJourney = getCurrentJourneyInCurrentChapter();
		q('P P: Current journey null? ${currentJourney == null}');
		if (currentJourney != null && currentJourney.preventMessageScreen == false && isTurboModeEnabled == false) {
			q('P P: Going to loading...');
			FakeLoadingScreen.goToFakeLoadingScreenAndThen(() -> {
				q('P P: Going to message with name ${currentJourney.name}...');
				MessageScreen.goToMessageScreenWhiteAndThen(currentJourney.name, () -> {
					q('P P: Going to map and generating.');
					GameMap.goToMapSceneAndGenerate(currentJourney);
				});
			});
		} else {
			q('P P: Going to map and generating.');
			GameMap.goToMapSceneAndGenerate(currentJourney);
		}
	}
	public static function checkGameOver() {
		return characters.map(chr -> chr.isDead() == false).length == 0;
	}
	public static function continueJourney() {
		q('P: Continuing journey.');
		if (GameMap.isLastAccessedNodeLastInJourney()) {
			final currentChapter = getCurrentChapter();	// This might change after doOnJourneyEndAndThen...
			q('P P: Yes, last node.');
			q('P P: Current chapter: ${if (currentChapter != null) currentChapter.name else "NULL"}');
			q('P P: currentJouyenry: ${progression.currentJourneyIndex}');
			final wasLastJourneyInChapter = progression.currentJourneyIndex == currentChapter.journeys.length - 1;
			q('P P: Last journey? ${wasLastJourneyInChapter}. Doing journey end events.');
			final wasTutorialRun = currentChapter == Chapters.getTutorialChapter();
			getCurrentJourneyInCurrentChapter().doOnJourneyEndAndThen(() -> {
				q('P P: Done.');
				if (wasLastJourneyInChapter) {
					GameMap.clear();
					reset();
					Game.save(() -> {
						if (wasTutorialRun) {
							var willDisplayAd = true;
							Game.newGame(willDisplayAd);
						} else {
							changeScene('MenuScene');
						}
					});
				} else {
					q('P P: Starting next journey...');
					MessageScreen.showInterstitialAdOnNextMessageScreen();
					startNextJourneyInThisChapter();
				}
			});
		} else {
			GameMap.goToMapSceneAndContinue();
		}
	}

	public static function giveGold(amount: Int) {
		gold += amount;
		totalGoldAcquiredThisRun += amount;
	}
	public static function giveExtraGold(amount: Int) {
		gold += amount;
	}
	public static function giveItem(?itemName: String, ?item: Item) {
		if (item == null) {
			if (itemName == null || ItemsDatabase.get(itemName) == null) {
				final message = 'null item given or item with name ${itemName} does not exist';
				warnLog(message);
				item = ItemsDatabase.getOopsie(message);
			} else {
				item = ItemsDatabase.get(itemName);
				inventory.add(item);
			}
		} else if (inventory.isFull()) {
			giveGold(item.getSellPrice());
		} else {
			inventory.add(item);
		}
	}
	public static function hasItem(itemName: String) return inventory.findByFunc(i -> i != null && i.name == itemName) != null;
	public static function getItem(itemName: String) {
		final foundItems = inventory.filterToArray(i -> i != null && i.name == itemName);
		final foundItem = if (foundItems == null || foundItems.length == 0) null else foundItems[0];
		return foundItem;
	}
	public static function hasItemEquipped(itemName: String) {
		getNEquippedItemsWithName(itemName) > 0;
	}
	public static function getCharacterWithItem(item: Item): PlayerCharacter {
		for (pc in characters) {
			if (pc.hasSpecificItem(item)) return pc;
		}
		return null;
	}
	public static function getNEquippedItemsWithName(itemName: String) {
		return getAllEquippedItems().filter(i -> i != null && i.name == itemName).length;
	}
	public static function removeItem(i: Item): Bool {
		if (i == null) throwAndLogError('Null item received in removeItem');
		final itemPos: Position = inventory.find(i);
		if (itemPos == null) return false;
		inventory.remove(itemPos.i, itemPos.j);
		return true;
	}
	public static function getLevel() {
		if (GameMap.lastAccessedNode != null) return GameMap.lastAccessedNode.level;
		if (getCurrentChapter() == Chapters.getTutorialChapter()) return 1;
		if (progression.currentJourneyIndex <= 0) return 1;
		if (progression.currentJourneyIndex == 1) return 4;
		if (progression.currentJourneyIndex == 2) return 4;	// Hell
		if (progression.currentJourneyIndex == 3) return 4;	// Somnium
		if (progression.currentJourneyIndex == 4) return 5;	// Somnium
		trace('Unknown player level: currentJourneyIndex = ${progression.currentJourneyIndex}');
		return 1;
	}
	public static function getRandomCharacterIndex() return randomIntBetween(0, characters.length - 1);

	public static function isAnyCharacterDead() {
		return characters.filter(chr -> chr.isDead()).length > 0;
	}
	public static function areAllPlayerCharactersDead() return characters.filter(c -> c.isDead() == false).length == 0;
	public static function distributeHealthAmongCharacters() {
		var totalHealth = 0;
		for (health in characters.map(chr -> chr.health)) {
			totalHealth += health;
		}
		trace('Calclated total health at ${totalHealth}');
		if (totalHealth % characters.length > 0)
			totalHealth += (characters.length - totalHealth % characters.length);
		trace('Next at ${totalHealth}');
		final healthPerCharacter = int(totalHealth / characters.length);
		trace('Health per char = ${healthPerCharacter}');
		for (character in characters) {
			character.health = if (character.getMaxHealth() < healthPerCharacter) character.getMaxHealth() else healthPerCharacter;
			trace('Set character ${character.name} health to ${character.health}');
		}
	}
	public static function healAllCharactersAtEndOfCombat() for (c in characters) c.healAtEndOfCombat();

	public static function getCurrentChapter(): GameChapter {
		return
			if (progression.tutorialIsDone == false) Chapters.getTutorialChapter()
			else Chapters.getRegularRun();
	}
	public static function getCurrentJourneyInCurrentChapter(): ChapterJourney {
		trace('Chapter is normal?: ${getCurrentChapter() == Chapters.getRegularRun()}');
		trace('Index: ${progression.currentJourneyIndex}');
		return getCurrentChapter().journeys[progression.currentJourneyIndex];
	}
	public static function getAllEquippedSpells() {
		final allEquippedSpells = mergeArrays(characters.map(chr -> chr.equippedSpells));
		final spellsWithoutDupes = removeDuplicates(allEquippedSpells);
		spellsWithoutDupes.remove('Attack');
		spellsWithoutDupes.remove('Block');
		spellsWithoutDupes.remove('Shoot Arrow');
		spellsWithoutDupes.remove('Throw Net');
		spellsWithoutDupes.remove('Magic Arrow');
		spellsWithoutDupes.remove('Drain Mana');
		spellsWithoutDupes.remove('Move');
		spellsWithoutDupes.remove('End Turn');
		return spellsWithoutDupes;
	}
	public static function getAllEquippedItems() {
		var items: Array<Item> = [];
		for (char in characters) {
			items = items.concat(char.getEquippedItems());
		}
		return items;
	}
	public static function getAllInventoryItems() {
		return inventory.filterToArray(item -> item != null);
	}

	public static function hasFox() {	// Returns that pc index if any of the characters has Fox Companion
		for (i in 0...characters.length) {
			final pc = characters[i];
			if (pc.hasSpell('Fox Companion'))
				return i;
		}
		return -1;
	}
	public static function hasMage() {
		for (c in characters) {
			if (c.getClassName() == 'Mage') return true;
		}
		return false;
	}

	public static function setupNatasPermanentBuffs(pc: PlayerCharacter) PlayerProgression.setupNatasPermanentBuffs(pc);
	public static function giveRandomItemsForTesting() {
		final possibleItems = ItemsDatabase.getPossibileItemsWithOptions({
			maxLevel: 2,
			type: 'GEAR',
			maxRarity: ARTIFACT,
			excludeTags: [SPECIAL_ITEM]
		});
		shuffle(possibleItems);
		final yesItems = possibleItems.slice(0, 8);
		for (item in yesItems) {
			Player.autoequipItem(item);
		}

		final possibleTomes = ItemsDatabase.getPossibileItemsWithOptions({
			usableTome: true,
			maxLevel: 2
		});
		shuffle(possibleTomes);
		final yesTomes = possibleTomes.slice(0, 3);
		for (tome in yesTomes) {
			if (tome.name != 'Oopsie')
				Player.autolearnSpell(tome);
			else
				Player.giveItem(null, tome);
		}
	}

}


class PlayerProgression {
	public static function setupNatasTemporaryBuffs() {
		if (Player.characters == null || Player.characters.length == 0) throwAndLogError('No player characters to setup Natas buffs for!');
		final pc = Player.characters[0];
		pc.equipSpell('Fiery Presence');
        pc.equipSpell('Soul Drain');
	}
	public static function setupNatasPermanentBuffs(pc: PlayerCharacter) {
		pc.stats.health += 4;
		pc.heal(4);
		pc.stats.spellPower += 2;
	}
}