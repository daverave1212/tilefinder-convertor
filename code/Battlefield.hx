
package scripts;

import haxe.Json;
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
import U.doAfter;
using U;

import scripts.Constants.*;
import scripts.SpecialEffectsFluff.sayAlert;
import scripts.SpecialEffectsFluff.sayBubble;
import Std.int;

import scripts.Game.q;
// Main class for BattlefieldScene
class Battlefield
{

	public static inline var CLICKING_ON_SPELLS			= 0;
	public static inline var CHOOSING_SPELL_TARGET		= 1;
	public static inline var WAITING					= 2;
	public static inline var IN_DIALOGUE				= 3;
	public static inline var IN_SETTINGS				= 4;


	public static var k = {
		nTileRows : 5,
		nTileCols : 7,
		tilesYOffsetFromCenter: 15,
		resolutionOffsetsY: [		// For tiles and background, depending on screen height
			320 => 0,
			270 => -15,
			360 => 0,
			292 => -10
		]
	}

	public static var backgroundImage 				: ImageX;
	public static var blackScreenBitmap				: BitmapData;	
	public static var blackScreen					: ImageX;

	public static var isCombatAlreadyEnded			: Bool = false;
	public static var currentWaveIndex				: Int = 0;
	public static var currentBattlefieldEncounter	: BattlefieldEncounter = null;
	public static var previousWavePlayerUnits		: Array<Unit>;					// When combat ends, it's set there; it's then reset at the start of the next battle, after loading previous heroes mana and hp
	public static var allEnemiesKilled				: Array<Unit>;					// When combat ends, they are saved here
	
	public static var chest = {														// Setup by the death event of Chest
		isDead: false,
		goldDropped: 0,
		itemDroppedName: 'Placeholder'
	}
	public static var killedVampireLord 			: Bool = false;					// Made true by the death event of Vampire Lord

	public static var selectedSpellIndex 			: Int;
	public static var clickState 					: Int = CLICKING_ON_SPELLS;

	public static var tiles 						: Matrix<TileSpace>;
	
	public static var lastFoughtEncounterName		: String;
	public static var unitsOnBattlefield 			: Array<Unit>;
	public static var trapsOnBattlefield			: Array<Trap>;
	public static var playerUnitsToAct				: Array<Unit>;		// All of these are included in unitsOnBattlefield
	public static var enemyUnitsToAct				: Array<Unit>;		// All of these are included in unitsOnBattlefield
	public static var currentlyActiveUnit			: Unit;
	public static var currentRound					: Int = 0;
	
	public static var floatingTextManager 	 		: FloatingTextManager;
	public static var scrollingTextManagerGreen		: ScrollingTextManager;
	public static var scrollingTextManagerBlue		: ScrollingTextManager;
	public static var scrollingTextManagerRed		: ScrollingTextManager;
	public static var missileParticleSpawner 		: ParticleSpawner;
	public static var effectParticleSpawner  		: ParticleSpawner;

	public static var lastTriggeredSay				: SayerReturnObject;
	public static var encounterData					: Dynamic;
	public static var lastBattlefieldEncounter		: BattlefieldEncounter;

	public static var isInspectOn					: Bool = false;
	
	public static var customData = {
		ints: new Map<String, Int>(),
		strings: new Map<String, String>()
	}

	// Flow and Start
	public static function start() {		// Called from the scene itself

		// Log
		Game.q('B: Starting combat with ${Player.characters.length} PCs.');
		for (i in 0...Player.characters.length) {
			final pc = Player.characters[i];
			if (pc == null) {
				Game.q('  B: NULL PC at index ${i}');
			} else {
				Game.q('  B: pc[${i}] = ${haxe.Json.stringify(pc.toDynamic())}');
			}
		}

		// Setup functions
		function resetBattlefield() {
			unitsOnBattlefield = [];
			playerUnitsToAct = [];
			enemyUnitsToAct = [];
			currentlyActiveUnit = null;
			monsterPopup = null;
			if (currentWaveIndex == 0) {
				resetChest();
				allEnemiesKilled = [];
			}
			currentRound = 0;
			BattlefieldEventDispatcher.resetEvents();
			clearCustomData();
		}
		function assertOk() {
			if (currentBattlefieldEncounter == null) throwAndLogError('currentBattlefieldEncounter not set!!!');
		}
		function spawnTiles() {
			tiles = new Matrix<TileSpace>(k.nTileRows, k.nTileCols);
			var spaceBetweenTiles = TileSpace.k.spaceBetweenTiles;
			var totalTileWidth  = k.nTileCols * TileSpace.k.width  + (k.nTileCols - 1) * spaceBetweenTiles;
			var totalTileHeight = k.nTileRows * TileSpace.k.height + (k.nTileRows - 1) * spaceBetweenTiles;
			var startX = getScreenX() + (getScreenWidth() - totalTileWidth) / 2;
			var startY = getScreenY() + (getScreenHeight() - totalTileHeight) / 2 + k.tilesYOffsetFromCenter + k.resolutionOffsetsY[getScreenHeight()];
			for(y in 0...k.nTileRows)
				for(x in 0...k.nTileCols){
					tiles.set(y, x, new TileSpace(startX + x*spaceBetweenTiles + x*TileSpace.k.width, startY + y*spaceBetweenTiles + y*TileSpace.k.height));
					tiles.get(y, x).matrixX = x;
					tiles.get(y, x).matrixY = y;
				}
		}
		function spawnPlayerCharacter(pc: PlayerCharacter, heroI: Int, heroJ: Int) {
			final hero = Unit.createFromPlayerCharacter(pc, PLAYER);
			hero.putOnTile(getTile(heroI, heroJ));
			if (currentBattlefieldEncounter.flipUnits) {
				hero.flipHorizontally();
			}
			unitsOnBattlefield.push(hero);
			if (currentWaveIndex > 0 && startedAtWave0()) {		// Set the hp and manas to the same 
				var previousWaveHero = previousWavePlayerUnits.filter(unit -> unit.name == hero.name)[0];
				hero.health = previousWaveHero.health;
				hero.mana = previousWaveHero.mana;
				hero.updateBars();
			}
		}
		function spawnMercenaries() {
			for (mercenary in Player.mercenaries) {
				final randomPC = getRandomAlivePlayerUnit();
				final tile = randomPC.tileOn.getRandomEmptyNeighbor();
				if (tile != null) {
					final merc = Unit.createFromPlayerMercenary(mercenary, PLAYER);
					merc.health = mercenary.health;
					merc.putOnTile(tile);
					if (currentBattlefieldEncounter.flipUnits) {
						merc.flipHorizontally();
					}
					unitsOnBattlefield.push(merc);
				}
			}
			addOnUnitDeathEvent((killer, unit) -> {
				if (unit.isMercenary()) {
					Player.mercenaries.remove(unit.playerMercenary);
				}
			});
		}
		function spawnUnitsOnBattlefield(encounterWave : BattlefieldEncounterWave) {
			if (encounterWave == null) throwAndLogError('Null battlefieldEncounter given to spawnUnitsOnBattlefield!!');
			// shuffle(encounterWave.playerPositions);
			if (Player.characters.length == 0) {
				trace('WARNING: Player has 0 characters!');
			}
			for (i in 0...Player.characters.length) {
				if (isOutOfBounds(encounterWave.playerPositions, i)) {
					trace('WARNING: No space to spawn ${Player.characters[i].getClassName()}');
					continue;
				}
				var heroI = encounterWave.playerPositions[i].i;
				var heroJ = encounterWave.playerPositions[i].j;
				spawnPlayerCharacter(Player.characters[i], heroI, heroJ);
			}
			for (i in 0...encounterWave.enemyNames.length) {
				spawnEnemy(encounterWave.enemyNames[i], encounterWave.enemyPositions[i].i, encounterWave.enemyPositions[i].j);
			}
			spawnMercenaries();
			previousWavePlayerUnits = [];
		}
		function spawnTraps(encounterWave : BattlefieldEncounterWave) {
			trapsOnBattlefield = [];
			if (!encounterWave.hasTraps()) return;
			for (i in 0...encounterWave.trapNames.length) {
				var trapName = encounterWave.trapNames[i];
				var trapPosition = encounterWave.trapPositions[i];
				var trap = Trap.createFromTemplate(trapName, getTileByPos(trapPosition));
			}
		}
		function setupBackgroundImageAndCamera(currentWave: BattlefieldEncounterWave) {
			centerCameraInScene();
			backgroundImage = new ImageX(currentWave.getBackgroundImagePath(), 'Background');
			backgroundImage.centerOnScreen();
			backgroundImage.setY(backgroundImage.getY() + k.resolutionOffsetsY[getScreenHeight()]);
		}
		function sortUnitsByInitiative() {
			unitsOnBattlefield.sort((u1, u2) -> u2.stats.initiative - u1.stats.initiative);
		}
		function setupKeyboard() {
			onEscapeKeyPress(() -> {
				// toggleMenu();
			});
			onCharKeyPress((char) -> {
				if (char != 'q') return;
				toggleInspectOn();
			});
			onCharKeyRelease((char) -> {
				if (char != 'q') return;
				toggleInspectOff();
			});
		}
		function setupMusic() {
			if (currentBattlefieldEncounter.hasFlag('BOSS_MUSIC'))
				playMusic('BattleMusicBoss');
			else if (currentBattlefieldEncounter.hasFlag('DARK_MUSIC'))
				playMusic('DarkTensionMusic');
			else
				playMusic('BattleMusicNormal');
		}
		function setupTextManagers() {
			floatingTextManager    		= new FloatingTextManager(getFont(SHADED_FONT_BIG), -0.4);
			scrollingTextManagerGreen 	= new ScrollingTextManager(getFont(SHADED_FONT_BIG_GREEN));
			scrollingTextManagerBlue 	= new ScrollingTextManager(getFont(SHADED_FONT_BIG_BLUE));
			scrollingTextManagerRed 	= new ScrollingTextManager(getFont(SHADED_FONT_BIG_RED));
			missileParticleSpawner		= new ParticleSpawner(0, 0);
			effectParticleSpawner 		= new ParticleSpawner(0, 0);
		} 
		function setupBlackScreen() {
			blackScreenBitmap = getExternalImage('UI/BlackScreen.png');
			blackScreen = new ImageX(blackScreenBitmap, 'SayHintBlur');
			blackScreen.centerOnScreen();
			blackScreen.setAlpha(0.5);
			blackScreen.hide();
		}
		function setupEnvironment() {
			SpecialEffectsFluff.tryStartSpawningBattlefieldSea(currentBattlefieldEncounter);
			SpecialEffectsFluff.tryStartSpawningLeaves(currentBattlefieldEncounter.waves[0].background);
			SpecialEffectsFluff.tryStartSpawningStalagmites(currentBattlefieldEncounter.waves[0].background);
			SpecialEffectsFluff.tryStartSpawningMist(currentBattlefieldEncounter.waves[0].background);
		}
		function startCombat() {
			if (Player.isTurboModeEnabled) {
				trace('ye turb');
				if (currentBattlefieldEncounter.level <= 1) {
					trace('end yes');
					endCombat(true);
					return;
				} else if (currentBattlefieldEncounter.testDamageTaken != null) {	// Quick combat
					trace('a take damag');
					final damageTaken = currentBattlefieldEncounter.testDamageTaken();
					for (i in 0...damageTaken) {
						getRandomPlayerCharacterUnit().damage(1);
					}
					final areAllPlayerCharacterUnitsDead = unitsOnBattlefield.filter(function(u) return !u.isDead && u.owner == PLAYER).length == 0;
					trace('Endiing');
					if (areAllPlayerCharacterUnitsDead) {
						endCombat(false);
					} else {
						endCombat(true);
					}
					trace('tehe dn');
					return;
				}
			}
			trace('New rong');
			newRound(() -> {		// Necessary to highlight tiles and do whatever round-start effects at the start of combat
				Game.q('B: New round script done. Updating turn indicators for start...');
				BattlefieldUI.self.updateTurnIndicators();
				Game.q('B: Next turning...');
				nextTurn();
			});
		}


		assertOk();

		GUI.startBeforeLoading();
		GUI.load("BattlefieldUI");
		GUI.load("InventoryUI");
		GUI.load("PopupUI");
		GUI.load('SpellPopupUI');
		GUI.load('SettingsUI');
		
		isCombatAlreadyEnded = false;
		var currentWave = currentBattlefieldEncounter.waves[currentWaveIndex];
		
		resetBattlefield();

		setupMusic();
		setupKeyboard();
		
		setupBackgroundImageAndCamera(currentWave);
		setupBlackScreen();
		setupEnvironment();
		
		setupTextManagers();

		
		spawnTiles();
		spawnUnitsOnBattlefield(currentWave);
		spawnTraps(currentWave);
		sortUnitsByInitiative();
		
		BattlefieldEventDispatcher.doCombatStartEvents();
		U.onClick(() -> { onClickOnAnything(); });
		
		if (currentWave.hasStartEvents() || currentBattlefieldEncounter.hasFlag('GOBLIN') || currentBattlefieldEncounter.hasFlag('EXPLODING_CRYSTAL')) {
			BattlefieldEventDispatcher.doStartDialogueEvents(() -> {
				startCombat();
			});
		} else {
			trace('Saying random qote');
			getRandomAlivePlayerUnit().sayRandomStartQuote();
			trace('said. startinv xaomb');
			startCombat();
		}
	}
	public static function goToBattle(encounterName: String, ?waveNumber: Int = 0) {	// Resets the Battlefield and goes to it
		currentBattlefieldEncounter = BattlefieldEncounterDatabase.get(encounterName);
		lastBattlefieldEncounter = currentBattlefieldEncounter;
		lastFoughtEncounterName = encounterName;
		currentWaveIndex = waveNumber;
		allEnemiesKilled = [];
		resetChest();
		U.changeScene('BattlefieldScene');
	}



	// Spawn functions
	public static function spawnUnit(unitName: String, i: Int, j: Int, owner: Int) {
		final unitTemplate = UnitsDatabase.get(unitName);
		final unit = Unit.createFromUnitTemplate(unitTemplate, owner);
		if (unit.hasSpell('Player Owned')) {
			unit.setOwner(PLAYER);
		}
		unit.putOnTile(getTile(i, j));
		unitsOnBattlefield.push(unit);
		if (unit.owner == PLAYER) {
			playerUnitsToAct.push(unit);
		} else if (unit.owner == ENEMY) {
			enemyUnitsToAct.push(unit);
		}
		unit.doOnSpawnEvent();
		return unit;
	}
	public static function spawnUnitOnTile(unitName: String, tile: TileSpace, owner: Int) {
		return spawnUnit(unitName, tile.getI(), tile.getJ(), owner);
	}
	public static function spawnEnemyOnTile(unitName: String, tile: TileSpace) return spawnEnemy(unitName, tile.getI(), tile.getJ());
	public static function spwanEnemyAroundTile(unitName: String, tile: TileSpace) {
		if (tile.hasUnit() == false)
			return spawnEnemyOnTile(unitName, tile);
		final randomTile: TileSpace = tile.getRandomEmptyNeighbor();
		if (randomTile == null)
			return null;
		return spawnEnemyOnTile(unitName, randomTile);
	}
	public static function spawnEnemy(unitName: String, i: Int, j: Int) {
		var unitOwner = if (UnitsDatabase.get(unitName).isObstacle) NEUTRAL else ENEMY;
		var unit = spawnUnit(unitName, i, j, unitOwner);
		if (currentBattlefieldEncounter.flipUnits) {
			unit.flipHorizontally();
		}
		return unit;
	}
	public static function spawnEnemyFromOutOfScreen(unitName, i, j) {
		var unit = spawnEnemy(unitName, i, j);
		var originalX = unit.actor.getX();
		unit.actor.setX(getScreenX() + getScreenWidth() + 50);
		unit.actor.moveTo(originalX, unit.actor.getY(), 0.5, Easing.expoIn);
		return unit;
	}
	public static function spawnTrap(trapName: String, ?tile: TileSpace, ?i: Int, ?j: Int) {
		if (tile == null) tile = getTile(i, j);
		if (tile.hasTrap()) {
			trace('WARNING: Could not spawn ${trapName} on tile at ${tile.toString()} since there is already a trap there, ${tile.trapOnIt.name}');
			return null;
		}
		var trap = Trap.createFromTemplate(trapName, tile);
		trapsOnBattlefield.push(trap);
		return trap;
	}
	static function resetUnitsToAct() {
		playerUnitsToAct = getAllAlivePlayerUnits();
		enemyUnitsToAct = getAllAliveEnemyUnits();
	}


	// User Input
	public static function cancelClickOnSpell() {
		BattlefieldUI.self.unhighlightSpellButtons();
		unhighlightAllTiles();
		clickState = CLICKING_ON_SPELLS;
	}
	public static function onClickOnSpell(clickedSpellIndex : Int) {	// Called from BattlefieldUI when a valid button is clicked or from keyboard
		if (clickedSpellIndex >= getCurrentlyActiveUnit().spells.length) return;	// To prevent from keyboard
		final clickedSpell = getCurrentlyActiveUnit().spells[clickedSpellIndex];
		if (isAnyLargeUIOpen() || Log.isOpen) return;
		if (clickState != CLICKING_ON_SPELLS && clickState != CHOOSING_SPELL_TARGET) return;
		if (clickedSpell.cooldownRemaining > 0) {
			getCurrentlyActiveUnit().say('I must wait ${clickedSpell.cooldownRemaining} more turn${if (clickedSpell.cooldownRemaining > 1) 's' else ''} to do that!');
			return;
		}
		if (clickedSpell.getManaCost() > getCurrentlyActiveUnit().mana) {
			getCurrentlyActiveUnit().say('Not enough mana!');
			return;
		}
		BattlefieldUI.self.unhighlightSpellButtons();
		unhighlightAllTiles();
		if (clickedSpell.isInstant()) {
			currentPlayerCastSpellOnTileAndContinue(clickedSpellIndex, getCurrentlyActiveUnit().tileOn);
		} else {
			BattlefieldUI.self.highlightSpellButton(clickedSpellIndex);
			highlightValidTiles(getCurrentlyActiveUnit(), clickedSpell);
			selectedSpellIndex = clickedSpellIndex;
			clickState = CHOOSING_SPELL_TARGET;
		}
		if (GUI.isOpen('SpellPopupUI')) {
			GUI.close('SpellPopupUI');
		}
	}
	public static function onLongClickOnSpell(clickedSpellIndex) {		// Called from BattlefieldUI when a valid button is long clicked
		if (clickState != CLICKING_ON_SPELLS) return;
		if (GUI.isOpen('InventoryUI')) return;		
		var clickedSpell = getCurrentlyActiveUnit().spells[clickedSpellIndex];
		if (clickedSpell == null) return;
		GUI.openWith('SpellPopupUI', {
			spellName: clickedSpell.getName(),
			entityWithStats: getCurrentlyActiveUnit(),
			reason: VIEW
		});
	}
	public static function onSpellButtonMouseEnter(index: Int) {
		if (isAnyLargeUIOpen()) return;
		var clickedSpell = getCurrentlyActiveUnit().spells[index];
		if (clickedSpell == null) return;
		if (GUI.isOpen('SpellPopupUI')) {
			GUI.close('SpellPopupUI');
		}
		GUI.openWith('SpellPopupUI', {
			spellName: clickedSpell.getName(),
			entityWithStats: getCurrentlyActiveUnit(),
			reason: VIEW,
			followCursor: true,
			showCloseButton: false,
			showBlackOverlay: false
		});
	}
	public static function onSpellButtonMouseExit(index: Int) {
		if (GUI.isOpen('SpellPopupUI') == false) return;
		var clickedSpell = getCurrentlyActiveUnit().spells[index];
		if (clickedSpell == null) return;
		GUI.close('SpellPopupUI');
	}
	
	public static function onClickOnTile(clickedTile : TileSpace) {
		if (clickState != CHOOSING_SPELL_TARGET) return;
		if (!clickedTile.isHighlighted) return;
		if (isAnyLargeUIOpen()) return;
		BattlefieldUI.self.unhighlightSpellButtons();
		unhighlightAllTiles();
		currentPlayerCastSpellOnTileAndContinue(selectedSpellIndex, clickedTile);
	}
	public static function onClickOnUnit(clickedUnit : Unit) {
		clickedUnit.traceAllInfo();
	}
	public static function onEnterUnit(unit: Unit) {}
	public static function onExitUnit(unit: Unit) {}
	static var monsterPopup: MonsterPopupUI = null;
	public static function onEnterTile(tile: TileSpace) {
		function getHypoMonsterPopupX() return getScreenX() + if (getMouseX() < getScreenWidth() / 3 * 2) getMouseX() + 2 else (getMouseX() - 2 - monsterPopup.getWidth());
		function getHypoMonsterPopupY() return getScreenY() + getMouseY() - monsterPopup.getHeight() / 2;
		function initMonsterPopup() {
			monsterPopup = new MonsterPopupUI();
			monsterPopup.close();
			doEvery(20, () -> {
				if (monsterPopup.isShown == false) return;
				monsterPopup.setXY(getHypoMonsterPopupX(), getHypoMonsterPopupY());
			});
		}
		
		if (clickState == WAITING) return;
		if (isAnyLargeUIOpen()) return;
		
		tile.markColor('WhiteAlternative');
		if (tile.hasUnit()) {
			if (isInspectOn) {
				if (monsterPopup == null) {
					initMonsterPopup();
				}
				monsterPopup.open({
					name: tile.unitOnIt.name,
					description: tile.unitOnIt.getDescription(),
					initialX: getHypoMonsterPopupX(),
					initialY: getHypoMonsterPopupY(),
					buffs: tile.unitOnIt.activeBuffs
				});
			}
			
			if (tile.unitOnIt.tilesMarkedRed == null || tile.unitOnIt.tilesMarkedRed.length == 0)
				return;
			for (tile in tile.unitOnIt.tilesMarkedRed) {
				tile.markColor('RedOpaque');
			}
		} else if (tile.hasTrap()) {
			if (isInspectOn) {
				if (monsterPopup == null) {
					initMonsterPopup();
				}
				monsterPopup.open({
					name: tile.trapOnIt.name,
					description: tile.trapOnIt.description,
					initialX: getHypoMonsterPopupX(),
					initialY: getHypoMonsterPopupY()
				});
			}
		}
	}
	public static function onExitTile(?tile: TileSpace) {	// tile argument does nothing
		unmarkAllHoveringTiles();
		unmarkAllDelayedTargetedTiles();
		if (monsterPopup == null) return;
		if (monsterPopup.isShown) {
			monsterPopup.close();
		}
	}
	public static function onClickOnAnything() {
		unmarkAllHoveringTiles();
		unmarkAllDelayedTargetedTiles();
	}
	public static function onClickOnInspect() {
		if (isInspectOn) {
			toggleInspectOff();
		} else {
			toggleInspectOn();
		}
	}

	static function unmarkAllDelayedTargetedTiles() {
		tiles.forEach(t -> {
			t.unmarkColor('RedOpaque');
		});
	}
	static function unmarkAllHoveringTiles() {
		tiles.forEach(t -> {
			final wasAMarkerRemoved = t.unmarkColor('WhiteAlternative');
		});
	}

	// Events
	public static function currentPlayerCastSpellOnTileAndContinue(spellIndex: Int, tile: TileSpace) {	// Current unit casts given spell on the given tile, then continues
		function isOutOfActions() {
			if (Game.savedSettings.autoEndTurn == false) return false;
			if (areAllEnemiesDead()) return true;
			if (Player.progression.tutorialDidEndTurn == false) return false;
			final unit = getCurrentlyActiveUnit();
			final usableSpells = unit.spells
				.filter(spell -> spell.cooldownRemaining <= 0 && spell.isWasted == false && spell.getName() != 'End Turn')
				.filter(spell -> unit.hasManaForSpell(spell));
			if (usableSpells.length > 0) return false;
			return true;
		}
		final selectedSpell = getCurrentlyActiveUnit().spells[spellIndex];
		
		if (selectedSpell.isFreeAction()) {
			clickState = WAITING;
			disablePlayerControl();
			currentlyActiveUnit.castSpellAndThen(selectedSpell, tile, function() {
				if (isOutOfActions()) {
					nextTurn();
				} else {
					clickState = CLICKING_ON_SPELLS;
					enablePlayerControl();
				}
			});
	   } else {
			disablePlayerControl();
			if (selectedSpell.getType() == END_TURN) {
				unhighlightAllTiles();
				nextTurn();
			}
			else getCurrentlyActiveUnit().castSpellAndThen(selectedSpell, tile, function() {
				nextTurn();
			});
	   }
	}
	public static function updateUI() {
		if (GUI.isOpen('Battlefield') && isPlayerTurnNow()) {
			BattlefieldUI.self.updateSpellButtons(getCurrentlyActiveUnit());
		}
	}
	
	public static function addOnUnitMoveEvent(event: Unit -> TileSpace -> Void) BattlefieldEventDispatcher.addOnUnitMoveEvent(event);
	public static function addOnUnitDeathEvent(event: Unit -> Unit -> Void) BattlefieldEventDispatcher.addOnUnitDeathEvent(event);
	public static function addAfterUnitDeathEvent(event: Unit -> TileSpace -> Void) BattlefieldEventDispatcher.addAfterUnitDeathEvent(event);
	public static function addAfterUnitTakingDamageEvent(event: Unit -> Unit -> Int -> Int -> Void) BattlefieldEventDispatcher.addAfterUnitTakingDamageEvent(event);
	public static function addOnUnitCastSpellEvent(event: Unit -> Spell -> TileSpace -> Void) BattlefieldEventDispatcher.addOnUnitCastSpellEvent(event);
	public static function addAfterUnitCastSpellEvent(event: Unit -> Spell -> TileSpace -> Void) BattlefieldEventDispatcher.addAfterUnitCastSpellEvent(event);
	public static function addOnRoundEndEvent(event: Int -> Void) BattlefieldEventDispatcher.addOnRoundEndEvent(event);
	public static function addAfterTurnEndEvent(event: Void -> Void) BattlefieldEventDispatcher.addAfterTurnEndEvent(event);

	public static function triggerOnUnitPushedEvents(unit: Unit) {
		BattlefieldEventDispatcher.checkAndTriggerSpikeBarricades(unit);
	}
	public static function triggerOnUnitMoveEvents(unit: Unit, previousTile: TileSpace) {
		BattlefieldEventDispatcher.triggerOnUnitMoveEvents(unit, previousTile);
		BattlefieldEventDispatcher.checkAndTriggerSpikeBarricades(unit);
	}
	public static function triggerOnUnitDeathEvents(killer: Unit, victim: Unit) BattlefieldEventDispatcher.triggerOnUnitDeathEvents(killer, victim);
	public static function triggerAfterUnitDeathEvents(unit: Unit, tileWhereDied: TileSpace) BattlefieldEventDispatcher.triggerAfterUnitDeathEvents(unit, tileWhereDied);
	public static function triggerAfterUnitTakingDamageEvent(source: Unit, victim: Unit, amount: Int, type: Int) BattlefieldEventDispatcher.triggerAfterUnitTakingDamageEvent(source, victim, amount, type);
	public static function triggerOnUnitCastSpellEvents(caster: Unit, spell: Spell, tile: TileSpace) BattlefieldEventDispatcher.triggerOnUnitCastSpellEvents(caster, spell, tile);
	public static function triggerAfterUnitCastSpellEvents(caster: Unit, spell: Spell, tile: TileSpace) BattlefieldEventDispatcher.triggerAfterUnitCastSpellEvents(caster, spell, tile);
	public static function triggerAfterTurnEndEvents() BattlefieldEventDispatcher.triggerAfterTurnEndEvents();

	// Tiles
	static function highlightValidTiles(caster : Unit, spell : Spell) {	// Called when the player clicks on a spell; It highlights available tiles for targeting
		function highlightTiles(validityMatrix : Matrix<Int>)
			tiles.forEachIndices(function(i, j) {
				if (validityMatrix.get(i,j) == Pathing.VALID) {
					final theTile = tiles.get(i, j);
					theTile.highlight();
					if (theTile.hasUnit() && theTile.unitOnIt.owner == PLAYER && spell.isFriendly() == false) {
						theTile.showFriendlyFireIndicator();
					}
				}
			});
		var validityMatrix = spell.getTileHighlightMatrix(caster);
		highlightTiles(validityMatrix);
	}
	public static function unhighlightAllTiles() tiles.forEach(function(tile: TileSpace) {
		tile.unhighlight();
		tile.hideFriendlyFireIndicator();
	});
	public static function markTilesRed(validityMatrix: Matrix<Int>) {
		validityMatrix.forEachIndices((i, j) -> {
			if (validityMatrix.get(i, j) == Pathing.VALID)
				getTile(i, j).addDangerMarker();
		});
	}

	
	
	
	// Turn stuff
	public static var halfASecond = 400;
	public static var quarterSecond = 250;
	public static var isPreventingNextTurn = false;
	public static var didPreventNextTurn = false;
	public static function preventNextTurnOnce() isPreventingNextTurn = true;
	public static function unpreventNextTurn() isPreventingNextTurn = false;
	public static function pauseNextTurn() isPreventingNextTurn = true;
	public static function resumeNextTurn() {
		if (didPreventNextTurn) {
			nextTurn();
		}
		else
			unpreventNextTurn();
	}
	public static function endCombatIfDone() {
		final areAllPlayerCharacterUnitsDead = unitsOnBattlefield.filter(function(u) return !u.isDead && u.owner == PLAYER).length == 0;
		if (areAllPlayerCharacterUnitsDead) {
			endCombat(false);
			return true;
		}
		if (areAllEnemiesDead()) {
			endCombat(true);
			return true;
		}
		return false;
	}
	public static function nextTurn() {
		function isNextTurnPrevented() {
			if (isPreventingNextTurn) {
				isPreventingNextTurn = false;
				didPreventNextTurn = true;
				return true;
			}
			didPreventNextTurn = false;
			return false;
		}
		function maybeTriggerCurrentUnitTurnEnd() {
			if (currentlyActiveUnit != null) {	// Is null if it's the first turn in the
				if (getCurrentlyActiveUnit().isDead) return;
				currentlyActiveUnit.unmarkTurnTile();
				getCurrentlyActiveUnit().onTurnEnd();
			}
			triggerAfterTurnEndEvents();
		}
		function maybeNewRoundAndThen(callback: Void -> Void) {
			if (playerUnitsToAct.length == 0 && enemyUnitsToAct.length == 0) {
				newRound(() -> {	// Trigger onTurnStart for all player units and set everything up
					callback();
				});
			} else {
				callback();
			}
		}
		function doOnTurnStartIfEnemyAndThen(callback: Void -> Void) {
			if (currentlyActiveUnit.owner == PLAYER) {
				callback();
			} else {
				currentlyActiveUnit.onTurnStart(() -> {
					callback();
				});
			}
		}
		function nextUnit(andThen: Void -> Void) {
			playerUnitsToAct = playerUnitsToAct.filter(u -> u.isDead == false);		// Remove remaining dead units every time
			enemyUnitsToAct = enemyUnitsToAct.filter(u -> u.isDead == false);		// Remove remaining dead units every time
			maybeNewRoundAndThen(function(): Void {											// If new round, trigger onTurnStart for all player units
				if (playerUnitsToAct.length > 0) {
					currentlyActiveUnit = playerUnitsToAct.shift();
				} else {
					currentlyActiveUnit = enemyUnitsToAct.shift();
				} if (currentlyActiveUnit == null) {
					Game.q('B: ERROR: null currentlyActiveUnit!');
					return;
				}
				Game.q('B: Starting turn of ${currentlyActiveUnit.name}');
				BattlefieldUI.self.setCurrentActiveUnitTurnIndicator(currentlyActiveUnit.uniqueID);
				doAfterFrom('nextUnit(${currentlyActiveUnit.name})', 250, () -> {
					doOnTurnStartIfEnemyAndThen(() -> {
						andThen();
					});
				});
			});
		}
		function unstunCurrentUnit() {
			currentlyActiveUnit.unstun();
			if (currentlyActiveUnit.isEnemy() && currentlyActiveUnit.hasAISpellSequence())
				currentlyActiveUnit.nextSpellInSequence();
		}
		
		if (isCombatAlreadyEnded) {
			Game.q('B: Can not next turn because combat is finished.');
			return;
		}

		unmarkAllDelayedTargetedTiles();
		unmarkAllHoveringTiles();
		disablePlayerControl();					// Disable first thing, to make sure nothing wicked happens
		if (isNextTurnPrevented()) return;		// If was prevented from outside (will resume from outside as well)
		final didCombatEnd = endCombatIfDone();
		if (didCombatEnd) return;

		maybeTriggerCurrentUnitTurnEnd();		// Might have triggered nextTurn on death (or be null = the first turn in combat)

		if (isPlayerTurnNow()) {
			
		}

		nextUnit(function() {					// Setup next unit and do on its turn start events
			if (currentlyActiveUnit == null) {
				Game.q('ERROR: currentlyActiveUnit is null at nextUnit!!!');
				return;
			}
			if (currentlyActiveUnit.isDead) {	// Might have died from its onTurnStart
				doAfterFrom('nextUnit currentlyActiveUnit.isDead', halfASecond, nextTurn);
				return;
			}
			if (currentlyActiveUnit.isStunned()) {
				unstunCurrentUnit();
				doAfterFrom('nextUnit currentlyActiveUnit.isStunned()', halfASecond, nextTurn);
				return;
			}

			currentlyActiveUnit.markTurnTile();
			if (currentlyActiveUnit.owner == PLAYER) {
				enablePlayerControl();
			} else if (currentlyActiveUnit.owner == ENEMY) {
				disablePlayerControl();
				doAfterFrom('nextUnit currentlyActiveUnit.owner == ENEMY (first) ${currentlyActiveUnit.name}', quarterSecond, () -> {
					AI.takeTurnAndThen(currentlyActiveUnit, () -> {
						doAfterFrom('nextUnit currentlyActiveUnit.owner == ENEMY (second) ${currentlyActiveUnit.name}', quarterSecond, () -> {
							nextTurn();
						});
					});
				});
			}
		});
	}
	public static function newRound(andThen: Void -> Void) {
		q('B: New round. Doing end of round events...');
		BattlefieldEventDispatcher.doEndOfRoundEvents();
		q('B: Done events.');
		resetUnitsToAct();
		final newPlayerUnitsToAct = [];
		currentRound ++;
		q('B: Starting round ${currentRound}.');
		
		function doPlayerUnitsOnTurnStartAndContinue() {							// For player units, this happens at the start of the round
			final playerUnitsToDoTurnStart = playerUnitsToAct.copy();
			function doNextOnTurnStart() {
				if (playerUnitsToDoTurnStart.length == 0) {
					playerUnitsToAct = newPlayerUnitsToAct;
					q('B B: Finished newRound function.');
					andThen();
				} else {
					final unit = playerUnitsToDoTurnStart.shift();
					unit.onTurnStart(() -> {
						q('B B B: Done turnStart for ${if (unit == null) "null" else unit.name}}.');
						if (unit.isDead) {
							doNextOnTurnStart();
							return;
						}
						if (unit.isStunned()) {
							unit.unstun();
						} else {
							newPlayerUnitsToAct.push(unit);
						}
						doNextOnTurnStart();
					});
				}
			}
			doNextOnTurnStart();
		}
		doPlayerUnitsOnTurnStartAndContinue();
	}
	public static function enablePlayerControl() {
		clickState = CLICKING_ON_SPELLS;
		GUI.close('BattlefieldUI');
		GUI.open('BattlefieldUI', [getCurrentlyActiveUnit()]);
	}
	public static function disablePlayerControl() {
		cancelClickOnSpell();
		clickState = WAITING;
		GUI.close('BattlefieldUI');
	}
	public static function isPlayerTurnNow() return currentlyActiveUnit != null && currentlyActiveUnit.owner == PLAYER;
	public static function swapCharactersToAct() {
		trace('A');
		if (currentlyActiveUnit.owner != PLAYER) return;
		trace('B');
		if (currentlyActiveUnit.tileOn.isMarkedForTurn()) {
			trace('C');
			currentlyActiveUnit.unmarkTurnTile();
			trace('D');
		}
		playerUnitsToAct = playerUnitsToAct.filter(u -> u.isDead == false);		// Remove remaining dead units every time
		playerUnitsToAct.push(currentlyActiveUnit);								// Move it to the end of the queue
		currentlyActiveUnit = playerUnitsToAct.shift();
		trace('E');
		if (currentlyActiveUnit.isDead) {										// Maybe not needed, but for safety
			trace('F');
			swapCharactersToAct();
		} else {
			trace('G');
			currentlyActiveUnit.markTurnTile();
			trace('H');
			GUI.close('SpellPopupUI');
			trace('I');
			disablePlayerControl();
			trace('J');
			enablePlayerControl();
			trace('K');
		}
	}
	public static function endCombat(didPlayerWin : Bool, ?testOptions: Dynamic) {
		if (isCombatAlreadyEnded) {
			Game.q('B: Combat already ended once. No point.');
			return;
		}
		isCombatAlreadyEnded = true;
		q('B: Ending combat with status: ${didPlayerWin}');
		function setupPlayerHealths() {
			for (pu in unitsOnBattlefield.filter(u -> u.isPlayerCharacter())) {
				pu.playerCharacter.health = if (pu.health < 0) 0 else pu.health;
			}
			Player.healAllCharactersAtEndOfCombat();
		}
		stopMusic();
		if (didPlayerWin == false) {
			q('B B: Game Over.');
			Game.gameOver();
			return;
		}

		Player.progression.nCombatsWonThisRun += 1;

		allEnemiesKilled = allEnemiesKilled.concat(getAllDeadUnits().filter(unit -> unit.owner == Constants.ENEMY));

		q('B B: Doing end events...');
		BattlefieldEventDispatcher.doEndEvents(() -> {
			q('B B: Done.');
			if (isLastWave()) {
				final thisBattlefieldEncounter = currentBattlefieldEncounter;
				currentBattlefieldEncounter = null;
				currentWaveIndex = 0;
				setupPlayerHealths();
				final skipAfterCombat =
					if (isGoblinDead()) true
					else if (getCurrentNode() == null) true
					else if (getCurrentNode().skipAfterCombat) true
					else false;

				if (skipAfterCombat) {
					thisBattlefieldEncounter.doAfterCombatEventIfExists(() -> {
						Player.continueJourney();
					});
				} else {
					thisBattlefieldEncounter.doAfterCombatEventIfExists(() -> {
						AfterCombat.goToAfterCombat(
							thisBattlefieldEncounter.level,
							if (testOptions != null) testOptions else getCurrentNode().afterCombatOptions,
							(item) -> {
								Player.continueJourney();
							}
						);
					});
				}
			} else {
				trace('IIIEEEE MENOMAN??!');
				currentWaveIndex ++;
				previousWavePlayerUnits = getAllPlayerUnits();
				U.changeScene('BattlefieldScene');
			}
		});
	}
	static var lastMarkedTurnTile: TileSpace;
	
	// Getters and Setters and Misc
	public static inline function getTile(i : Int, j : Int) return tiles.get(i, j);
	public static inline function getTileByPos(pos : Position) return tiles.getByPos(pos);
	public static inline function getCurrentlyActiveUnit() return currentlyActiveUnit;
	public static inline function getRandomTile() return getTile(randomIntBetween(0, k.nTileRows - 1), randomIntBetween(0, k.nTileCols - 1));
	public static function getRandomTileWithNoUnit(): TileSpace {
		var tileFound = getRandomTile();
		var nTries = 0;
		while (tileFound.hasUnit() && nTries < 10) {
			tileFound = getRandomTile();
			nTries ++;
		}
		if (nTries >= 10) return null;
		return tileFound;
	}
	public static function getRandomTileWithNoTrap(): TileSpace {
		var tileFound = getRandomTile();
		var nTries = 0;
		while (tileFound.hasTrap() && nTries < 10) {
			tileFound = getRandomTile();
			nTries ++;
		}
		if (nTries >= 10) return null;
		return tileFound;
	}
	public static function getUnit(i : Int, j : Int) return tiles.get(i, j).unitOnIt;
	public static function getAllAlivePlayerUnits() return unitsOnBattlefield.filter(function(unit) return unit.owner == PLAYER && unit.isDead == false);
	public static function getAllAliveEnemyUnits() return unitsOnBattlefield.filter(function(unit) return unit.owner == ENEMY && unit.isDead == false);
	public static function getAllAliveNeutralUnits() return unitsOnBattlefield.filter(function(unit) return unit.owner == NEUTRAL && unit.isDead == false);
	public static function getAllAliveUnitsWithName(name: String) return getAllAliveUnits().filter(u -> u.name == name);
	public static function getRandomUnitWithName(name: String): Unit return randomOf(getAllAliveUnitsWithName(name));
	public static function getAllAliveUnitsWithOwner(owner: Int) {
		if (owner == PLAYER) return Battlefield.getAllAlivePlayerUnits();
		else if (owner == ENEMY) return Battlefield.getAllAliveEnemyUnits();
		else if (owner == NEUTRAL) return Battlefield.getAllAliveNeutralUnits();
		else throwAndLogError('No such owner: ${owner}');
		return null;
	}
	public static function getAllAliveUnits() {
		return unitsOnBattlefield.filter(u -> u.isDead == false);
	}
	public static function getAllPlayerUnits() return unitsOnBattlefield.filter(function(unit) return unit.owner == PLAYER);
	public static function getAllAlivePlayerCharacterUnits() return getAllPlayerUnits().filter(unit -> unit.isPlayerCharacter() && unit.isDead == false);
	public static function areAllPlayerUnitsAlive() return getAllPlayerUnits().length == getAllAlivePlayerUnits().length;
	public static function getAllUnitsInRegion(i1: Int, j1: Int, i2: Int, j2: Int) {
		return unitsOnBattlefield.filter(
			u -> u.isDead == false &&
			i1 <= u.getI() && u.getI() <= i2 &&
			j1 <= u.getJ() && u.getJ() <= j2
		);
	}
	public static function getRandomAlivePlayerUnit() return getAllAlivePlayerUnits()[randomIndex(getAllAlivePlayerUnits())];
	public static function getRandomPlayerCharacterUnit(): Unit return randomOf(getAllAlivePlayerCharacterUnits());
	public static function getRandomEnemyUnit() return getAllAliveEnemyUnits()[randomIndex(getAllAliveEnemyUnits())];
	public static function getEnemyUnitWithName(name) return getAllAliveEnemyUnits().filter(unit -> unit.name == name)[0];
	public static function getAllDeadUnits() return unitsOnBattlefield.filter(unit -> unit.isDead);
	public static function getAllDeadEnemyUnits() return unitsOnBattlefield.filter(unit -> unit.isDead && unit.owner == ENEMY);
	public static function getCurrentWave() {
		return currentBattlefieldEncounter.waves[currentWaveIndex];
	}
	public static function setCurrentBattlefieldEncounter(encounterName : String) currentBattlefieldEncounter = BattlefieldEncounterDatabase.get(encounterName);
	public static function getUnitByName(name: String) {
		var units = unitsOnBattlefield.filter(unit -> unit.name == name && unit.isDead == false);
		if (unitsOnBattlefield.indexOf(null) >= 0) trace('WARNING: Null unit found among ${unitsOnBattlefield.map(u -> u.name)}');
		if (units.length == 0) trace('WARNING: No unit named ${name} found among ${unitsOnBattlefield.map(u -> u.name)}');
		return if (units.length >= 1) units[0] else null;
	}
	public static function getUnitByNameLike(namePart: String) {
		namePart = namePart.toLowerCase();
		var units = unitsOnBattlefield.filter(unit -> unit.name.toLowerCase().indexOf(namePart) != -1 && unit.isDead == false);
		if (unitsOnBattlefield.indexOf(null) >= 0) trace('WARNING: Null unit found among ${unitsOnBattlefield.map(u -> u.name)}');
		if (units.length == 0) trace('WARNING: No unit named like ${namePart} found among ${unitsOnBattlefield.map(u -> u.name)}');
		return if (units.length >= 1) units[0] else null;
	}
	public static function hasUnit(name: String) return getUnitByName(name) != null;
	public static function getPlayerUnit(name: String) { var units = getAllPlayerUnits().filter(unit -> unit.name == name); return if (units.length == 1) units[0] else null; }
	public static function getCurrentNode() return GameMap.lastAccessedNode;
	public static function sayFromUnitAndWait(fromUnit: Unit, sayWhat: String, ?xOffset = 0, ?yOffset = -5) {
		if (fromUnit == null) throwAndLogError('Null fromUnit given with sayWhat="${sayWhat}"');
		lastTriggeredSay = fromUnit.say(sayWhat, -1, yOffset, xOffset);
	}
	public static function sayFromActorAndWait(actor: Actor, sayWhat: String, ?yOffset = 0) {
		lastTriggeredSay = sayBubble(sayWhat, actor.getXCenter(), actor.getYCenter() - 40, -1);
	}
	public static function sayFromActor(actor: Actor, sayWhat: String, seconds: Float = 2, ?yOffset = 0) {
		sayBubble(sayWhat, actor.getXCenter(), actor.getYCenter() - 40, seconds);
	}
	public static function alertAndWait(text, x: Int, y: Int) lastTriggeredSay = sayAlert(text, x, y, -1);
	public static function resetBlur() blackScreenBitmap = getExternalImage('UI/BlackScreen.png');
	public static function showBlur() blackScreen.show();
	public static function hideBlur() blackScreen.hide();
	public static function cutBlur(x, y, width, height) {
		var blackSquare = U.createBlackBitmapData(width, height);
		clearImageUsingMask(blackScreenBitmap, blackSquare, int(x / Engine.SCALE), int(y / Engine.SCALE));
	}
	public static function startedAtWave0() return previousWavePlayerUnits != null && previousWavePlayerUnits.length > 0;
	public static function toggleMenu() {
		if (clickState != CLICKING_ON_SPELLS && clickState != IN_SETTINGS) return;
		switch (clickState) {
			case CLICKING_ON_SPELLS:
				GUI.close('BattlefieldUI');
				GUI.openWith('SettingsUI', {
					isResolutionGrayed: true,
					isFullScreenGrayed: true
				});
				clickState = IN_SETTINGS;
			case IN_SETTINGS:
				GUI.close('SettingsUI');
				GUI.open('BattlefieldUI', [getCurrentlyActiveUnit()]);
				clickState = CLICKING_ON_SPELLS;
		}
	}
	public static function resetChest() {
		chest.isDead = false;
		chest.goldDropped = 0;
		chest.itemDroppedName = 'Placeholder';
	}
	static function isLastWave() return currentWaveIndex == currentBattlefieldEncounter.waves.length - 1;
	public static function areAllEnemiesDead() return unitsOnBattlefield.filter(function(u) return !u.isDead && u.owner == ENEMY).length == 0;
	public static function clearCustomData() {
		customData = {
			ints: new Map<String, Int>(),
			strings: new Map<String, String>()
		};
	}
	public static function initCustomInt(name: String, value: Int) {
		if (customData.ints.exists(name) == false) {
			customData.ints[name] = value;
		}
	}
	public static function initCustomString(name: String, value: String) {
		if (customData.strings.exists(name) == false) {
			customData.strings[name] = value;
		}
	}
	static function isGoblinDead() return unitsOnBattlefield.filter(unit -> unit.isDead && unit.name == 'Goblin').length > 0;
	public static function setBackground(path: String) {
		path = extrapolatePNGPathWithBasePath(path, 'Images/Backgrounds');
		if (path.indexOf('Images/') == -1) path = 'Images/Backgrounds/${path}.png';
		if (backgroundImage != null) {
			try {
				backgroundImage.kill();
			} catch (e: String) {

			}
		}
		backgroundImage = new ImageX(path, 'Background');
		backgroundImage.centerOnScreen();
		backgroundImage.setY(backgroundImage.getY() + k.resolutionOffsetsY[getScreenHeight()]);
	}
	static function isAnyLargeUIOpen() return GUI.isOpen('InventoryUI') || GUI.isOpen('SettingsUI');
	public static function toggleInspectOn() {
		if (isInspectOn) return;
		isInspectOn = true;
		final tileBeingHovered = TileSpace.getTileByMouseCoordinates();
		if (tileBeingHovered != null) {
			onExitTile();
			onEnterTile(tileBeingHovered);
		}
		BattlefieldUI.self.inspectButton.actor.setAnimation('Active');
	}
	public static function toggleInspectOff() {
		if (isInspectOn == false) return;
		isInspectOn = false;
		onExitTile();	// Hide monster popup
		BattlefieldUI.self.inspectButton.actor.setAnimation('Inactive');
	}

}


class BattlefieldEventDispatcher {

	public static function resetEvents() {
		onUnitMoveEvents = [];
		onUnitDeathEvents = [];
		afterUnitDeathEvents = [];
		afterUnitTakingDamageEvents = [];
		onUnitCastSpellEvents = [];
		afterUnitCastSpellEvents = [];
		onRoundEndEvents = [];
		afterTurnEndEvents = [];

		Unit.addFearfulEventMechanicToBattlefield();
	}
	public static function doCombatStartEvents() {
		for (unit in Battlefield.unitsOnBattlefield) {
			if (unit.unitTemplate != null && unit.unitTemplate.onCombatStart != null && unit.isAlive()) {
				unit.unitTemplate.onCombatStart(unit);
			}
			if (unit.isPlayerCharacter()) {
				for (item in unit.playerCharacter.getEquippedItems()) {
					if (item.onCombatStart != null) {
						item.onCombatStart(unit);
					}
				}
			}
		}
		final currentWave = Battlefield.getCurrentWave();
		if (currentWave.events.begin != null) {
			currentWave.events.begin();
		}
		function doAndRemovePassiveSpellEvents() {
			for (unit in Battlefield.unitsOnBattlefield) {
				for (spell in unit.spells) {
					spell.doCombatStartEvent(unit);
				}
				unit.removePassiveSpells();	// No worries, hasSpell still works because it searches the template/PC spells
			}
		}
		doAndRemovePassiveSpellEvents();
	}

	public static function doStartDialogueEvents(callback : Void -> Void) {
		trace('Doing start dialogue events.');
		function addTutorialDialogueIfNecessary(startEvents: Array<Void -> Void>) {
			final shouldDoGoblinTut = Battlefield.hasUnit('Goblin') && Player.progression.tutorialMetGoblinOnce == false;
			trace('  shouldDoGoblinTut? ${shouldDoGoblinTut}');
			trace('  Player.progression.tutorialMetGoblinOnce? ${Player.progression.tutorialMetGoblinOnce}');
			if (shouldDoGoblinTut) {
				Player.progression.tutorialMetGoblinOnce = true;
				trace('  start events before: ${startEvents.length}');
				for (e in BattlefieldEncounterDatabase.getTutorialGoblinDialogue()) startEvents.push(e);
				trace('  start events after: ${startEvents.length}');
			}
			final shouldDoCrystalTut = Battlefield.hasUnit('Exploding Crystal') && Player.progression.tutorialMetCrystalOnce == false;
			if (shouldDoCrystalTut) {
				Player.progression.tutorialMetCrystalOnce = true;
				for (e in BattlefieldEncounterDatabase.getTutorialCrystalDialogue()) startEvents.push(e);
			}
		}
		Battlefield.clickState = Battlefield.IN_DIALOGUE;
		var currentWave = Battlefield.getCurrentWave();
		var startEvents = currentWave.events.start.copy();
		addTutorialDialogueIfNecessary(startEvents);
		var eventsFinished = false;

		function doNextEventOrCallback() {
			Battlefield.hideBlur();
			if (Battlefield.lastTriggeredSay != null)
				Sayer.remove(Battlefield.lastTriggeredSay);
			if (startEvents.length == 0) {
				Battlefield.clickState = Battlefield.WAITING;
				eventsFinished = true;
				callback();
			} else {
				var firstEvent = startEvents.shift();
				firstEvent();
			}
		}

		U.onClick(() -> {
			if (eventsFinished) return;
			else doNextEventOrCallback();
		});

	
		doNextEventOrCallback();

	}

	public static function doEndEvents(andThen: Void -> Void) {
		function doCombatEndSpellEvents() {
			Game.q('B: Doing doCombatEndSpellEvents');
			for (unit in Battlefield.getAllAlivePlayerCharacterUnits()) {
				Game.q('  B: At unit ${unit.name}');
				for (spell in unit.playerCharacter.getSpells()) {
					Game.q('    B: At spell ${spell.name}');
					spell.effect.events.combatEnd(unit);
				}
			}
			Game.q('B: Ok done with spells.');
		}
		function makeChestDisappearAndThen(andThen: Void -> Void) {
			Game.q('B: Doing chest disappear animation...');
			final chestUnit = Battlefield.getUnitByName('Treasure Chest');
			if (chestUnit != null) {
				SpecialEffectsFluff.doChestDisappearAnimation(chestUnit.actor, () -> {
					Game.q('  B: Done chest.');
					andThen();
				});
			} else {
				Game.q('  B: Done chest.');
				andThen();
			}
		}
		function doItemCombatEndEvents() {
			Game.q('B: Doing doItemCombatEndEvents...');
			for (unit in Battlefield.getAllPlayerUnits()) {
				if (unit.isPlayerCharacter()) {
					Game.q('  B: At unit ${unit.name}');
					for (item in unit.playerCharacter.getEquippedItems()) {
						if (item.onCombatEnd != null) {
							Game.q('    B: Doing item ${item.name} onCombatEnd...');
							item.onCombatEnd(unit);
							Game.q('    B: Done.');
						}
					}
				}
			}
			Game.q('B: Finished doitemCombatEndEvents');
		}

		Battlefield.clickState = Battlefield.IN_DIALOGUE;
		var currentWave: BattlefieldEncounterWave;
		var endEvents: Array<Void -> Void>;

		try {
			currentWave = Battlefield.getCurrentWave();
			endEvents = currentWave.events.end;
		} catch (e: Any) {
			Game.q('ERROR: failed to get currentWave or endEvents.');
			Game.q('${e}');
			andThen();
			return;
		}
		
		
		var eventsFinished = false;

		doCombatEndSpellEvents();
		doItemCombatEndEvents();
		

		function doNextEventOrCallback() {
			try {
				Battlefield.hideBlur();
				if (Battlefield.lastTriggeredSay != null)
					Sayer.remove(Battlefield.lastTriggeredSay);
				if (endEvents.length == 0) {
					Battlefield.clickState = Battlefield.WAITING;
					eventsFinished = true;
					doAfterFrom('doNextEventOrCallback', Battlefield.halfASecond, () -> {
						makeChestDisappearAndThen(andThen);
					});
				} else {
					var firstEvent = endEvents.shift();
					firstEvent();
				}
			} catch (e: Any) {
				Game.q('ERROR: doNextEventOrCallback');
				Game.q('${e}');
				return;
			}
		}

		U.onClick(() -> {
			if (eventsFinished) return;
			else doNextEventOrCallback();
		});

		Game.q('B: Trying to do the finish events.');
		try {
			currentWave.events.finish();
		}
		Game.q('B: Done finish.');
		doNextEventOrCallback();	
	}

	public static function doEndOfRoundEvents() {
		for (trap in Battlefield.trapsOnBattlefield) {
			if (trap.isDead()) continue;
			trap.age ++;
			if (trap.onRoundEnd != null) trap.onRoundEnd(trap);
		}
		for (unit in Battlefield.unitsOnBattlefield) {
			if (unit.isDead) continue;
			unit.doOnRoundEndEvent();
		}
		triggerOnRoundEndEvents();
		BattlefieldUI.self.updateTurnIndicators();
	}

	public static var onUnitMoveEvents: Array<Unit -> TileSpace -> Void> = [];
	public static function addOnUnitMoveEvent(event: Unit -> TileSpace -> Void) onUnitMoveEvents.push(event);
	public static function triggerOnUnitMoveEvents(unit: Unit, previousTile: TileSpace) {
		for (event in onUnitMoveEvents) {
			event(unit, previousTile);
		}
	}

	public static var onUnitDeathEvents: Array<Unit -> Unit -> Void> = [];	// Killer -> Victim -> Void
	public static function addOnUnitDeathEvent(event: Unit -> Unit -> Void) onUnitDeathEvents.push(event);
	public static function triggerOnUnitDeathEvents(killer: Unit, victim: Unit) {
		for (event in onUnitDeathEvents) {
			event(killer, victim);
		}
	}

	public static var afterUnitDeathEvents: Array<Unit -> TileSpace -> Void> = [];
	public static function addAfterUnitDeathEvent(event: Unit -> TileSpace -> Void) afterUnitDeathEvents.push(event);
	public static function triggerAfterUnitDeathEvents(unit: Unit, tileWhereDied: TileSpace) {
		for (event in afterUnitDeathEvents) {
			event(unit, tileWhereDied);
		}
	}

	public static var afterUnitTakingDamageEvents: Array<Unit -> Unit -> Int -> Int -> Void> = [];	// Source -> Victim -> Amoint -> Type
	public static function addAfterUnitTakingDamageEvent(event: Unit -> Unit -> Int -> Int -> Void) {
		afterUnitTakingDamageEvents.push(event);
	}
	public static function triggerAfterUnitTakingDamageEvent(source: Unit, victim: Unit, amount: Int, type: Int) {
		for (event in afterUnitTakingDamageEvents) {
			event(source, victim, amount, type);
		}
	}

	public static var onUnitCastSpellEvents: Array<Unit -> Spell -> TileSpace -> Void> = [];
	public static function addOnUnitCastSpellEvent(event: Unit -> Spell -> TileSpace -> Void) onUnitCastSpellEvents.push(event);
	public static function triggerOnUnitCastSpellEvents(caster: Unit, spell: Spell, tile: TileSpace) {
		for (e in onUnitCastSpellEvents) {
			e(caster, spell, tile);
		}
	}

	public static var afterUnitCastSpellEvents: Array<Unit -> Spell -> TileSpace -> Void> = [];
	public static function addAfterUnitCastSpellEvent(event: Unit -> Spell -> TileSpace -> Void) afterUnitCastSpellEvents.push(event);
	public static function triggerAfterUnitCastSpellEvents(caster: Unit, spell: Spell, tile: TileSpace) {
		for (e in afterUnitCastSpellEvents) {
			e(caster, spell, tile);
		}
	}

	public static var onRoundEndEvents: Array<Int -> Void> = [];	// Round Number -> Void
	public static function addOnRoundEndEvent(event: Int -> Void) onRoundEndEvents.push(event);
	static function triggerOnRoundEndEvents() {
		for (event in onRoundEndEvents) {
			event(Battlefield.currentRound);
		}
	}

	public static var afterTurnEndEvents: Array<Void -> Void> = [];
	public static function addAfterTurnEndEvent(event: Void -> Void) afterTurnEndEvents.push(event);
	public static function triggerAfterTurnEndEvents() {
		for (event in afterTurnEndEvents) {
			event();
		}
	}

	public static function checkAndTriggerSpikeBarricades(unit: Unit) {
		final barricadeTiles = unit.tileOn.getNeighbors().filter(tile -> tile.hasUnit() && tile.unitOnIt.name == 'Spike Barricade');
		if (barricadeTiles.length > 0) {
			final barricade = barricadeTiles[0].unitOnIt;
			barricadeTiles[0].flashTargeted();
			unit.damage(barricadeTiles.length * 2, PURE, barricade);
		}
	}


}