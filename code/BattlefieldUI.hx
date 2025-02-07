

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

import scripts.SpecialEffectsFluff.*;
import Std.*;


import scripts.Constants.*;
import U.*;
using U;



class FramedUnitIcon extends FramedItem {
	public static inline var FRAMED_UNIT_ICON_FRAME_SIZE = 20;
	public static inline var FRAMED_UNIT_ICON_SIZE = 16;
	public var unitsUniqueId: Int;	// Same as the Unit's uniqueID
	public function new(imagePath: String, layer: String, x: Float, y: Float, uniqueID: Int) {
		unitsUniqueId = uniqueID;
		super(imagePath, layer, x, y, 'FrameSmall');
	}
	public override function getWidth() return FRAMED_UNIT_ICON_FRAME_SIZE;
	public override function getHeight() return FRAMED_UNIT_ICON_FRAME_SIZE;
	public override function setIcon(imagePath: String) {
		final framePadding = (FRAMED_UNIT_ICON_FRAME_SIZE - FRAMED_UNIT_ICON_SIZE) / 2;
		setupIcon(imagePath, framePadding, 'Icons/Small/NotFound.png');
	}
}

class BattlefieldUI_TurnIndicators {


	public var unitIcons: Array<FramedUnitIcon>;

	public function new() {
		unitIcons = [];
	}

	public function update() {
		for (icon in unitIcons) {
			icon.kill();
		}
		unitIcons = [];
		final allUnits = Battlefield.unitsOnBattlefield.filter(unit -> unit.isDead == false && unit.owner != NEUTRAL);
		final totalWidth = allUnits.length * (FramedUnitIcon.FRAMED_UNIT_ICON_FRAME_SIZE - 1);
		final startX = getScreenX() + (getScreenWidth() - totalWidth) / 2;
		final y = getScreenY() - 1;
		for (i in 0...allUnits.length) {
			final unit = allUnits[i];
			final x = startX + i * FramedUnitIcon.FRAMED_UNIT_ICON_FRAME_SIZE;
			unitIcons.push(new FramedUnitIcon(unit.getTurnIndicatorIconPath(), 'UI', x, y, unit.uniqueID));
		}
	}

	public function setCurrentActiveUnitTurnIndicator(id: Int) {
		for (i in 0...unitIcons.length) {
			final icon = unitIcons[i];
			icon.setFrameAnimation('FrameSmall');
			if (icon.unitsUniqueId == id)
				icon.setFrameAnimation('FrameSmallHighlighted');
		}
	}

}


class BattlefieldUI extends SimpleUI
{
	
	public static var self : BattlefieldUI;
	public var k = {
		spellButtonSize		: 38,
		spaceBetweenButtons	: 4,
		padding				: 6,
		spellButtonsMax		: 7,
		mobileExtraMargin	: 12
	}
	public function new() {
		super("BattlefieldUI");
		self = this;
	}
	
	
	
	
	public var turnIndicators: BattlefieldUI_TurnIndicators;
	public var spellButtons: Array<FramedItem>;
	public var inventoryButton: FramedItem;
	public var endTurnButton: FramedItem;
	public var swapButton: FramedItem;
	public var areSpellButtonsDisabled = false;
	public var pauseButton: SUIButton;
	public var inspectButton: SUIButton;
	var currentSpellButtonHighlight: ImageX;
	var latestSpellOwner : Unit;

	var timeSinceSpellButtonWasClicked : Float;	// In miliseconds
	var indexWhenSpellButtonWasClicked : Int;
	var isLongClicking = false;

	
	public override function load() {
		function incrementLongClickTimer() {
			if (isLongClicking == false) return;
			timeSinceSpellButtonWasClicked += 200;
			if (timeSinceSpellButtonWasClicked >= 1000) {
				if (spellButtons[indexWhenSpellButtonWasClicked].frame.isMouseOver()) {
					onLongClickOnSpell(indexWhenSpellButtonWasClicked);
				}
				isLongClicking = false;
				timeSinceSpellButtonWasClicked = 0;
			}
		}
		function resetLongClickTimer() {
			timeSinceSpellButtonWasClicked = 0;
			isLongClicking = false;
		}
		spellButtons = [];
		currentSpellButtonHighlight = null;
		inventoryButton = new FramedItem('Icons/Inventory.png', 'UI', 0, 0);
		inventoryButton.enablePopAnimation();
		inventoryButton.click = onClickOnInventory;

		endTurnButton = new FramedItem('Icons/End Turn.png', 'UI', 0, 0);
		endTurnButton.enablePopAnimation();
		endTurnButton.click = onClickOnEndTurn;
		onEnter(function() {
			if (isButtonUnavailable()) return;
			if (GUI.isOpen('SettingsUI')) return;
			endTurnButton.showKey('X');
		}, endTurnButton.frame);
		onExit(function() {
			if (isButtonUnavailable()) return;
			endTurnButton.hideKey();
		}, endTurnButton.frame);

		swapButton = new FramedItem('Icons/Swap.png', 'UI', 0, 0);
		swapButton.enablePopAnimation();
		swapButton.click = onClickOnSwap;
		onEnter(function() {
			if (isButtonUnavailable()) return;
			if (GUI.isOpen('SettingsUI')) return;
			swapButton.showKey('Tab');
		}, swapButton.frame);
		onExit(function() {
			if (isButtonUnavailable()) return;
			swapButton.hideKey();
		}, swapButton.frame);


		if (Game.isMobile) {
			U.onRelease(resetLongClickTimer);
			U.repeat(incrementLongClickTimer, 200);
		}
		for (i in 0...k.spellButtonsMax) {
			final button = new FramedItem(null, 'UI', 0, 0);
			button.enablePopAnimation();
			onEnter(function() {
				onSpellButtonMouseEnter(i);
			}, button.frame);
			onExit(function() {
				onSpellButtonMouseExit(i);
			}, button.frame);
			button.click = function() {
				onClickOnSpellButton(i);
			}
			button.clickWhenDisabled = function() {
				onDisabledClickOnSpellButton(i);
			}
			button.release = function() {
				onReleaseOnSpellButton(i);
			}
			spellButtons.push(button);
		}
		turnIndicators = new BattlefieldUI_TurnIndicators();
		U.onCharKeyPress(function(char: String) {
			if (Log.isOpen) return;
			if (areSpellButtonsDisabled || GUI.isOpen('BattlefieldUI') == false) return;
			if (Battlefield.currentlyActiveUnit == null || Battlefield.currentlyActiveUnit.owner != PLAYER) return;
			if (char == '' || char == null || char.length == 0) return;
			if ('1234567890x'.indexOf(char) == -1) return;
			if ('123456789'.indexOf(char) != -1) {						// Not 0 here
				final spellIndex = '0123456789'.indexOf(char) - 1;		// Pressing 1 activates spell 0
				if (spellIndex >= k.spellButtonsMax) return;
				if (latestSpellOwner == null) return;
				if (spellIndex >= latestSpellOwner.spells.length) return;
				final button = spellButtons[spellIndex];
				if (button.isEnabled) {
					onClickOnSpellButton(spellIndex);
					onReleaseOnSpellButton(spellIndex);
				} else {
					onDisabledClickOnSpellButton(spellIndex);
				}
				playAudio('UIGenericClickAudio');
			} else if (char == 'x') {
				onClickOnEndTurn();
				playAudio('UIGenericClickAudio');
			}
		});
		U.onKeyPress(function(charCode: UInt) {
			if (areSpellButtonsDisabled || GUI.isOpen('BattlefieldUI') == false) return;
			if (Battlefield.currentlyActiveUnit == null || Battlefield.currentlyActiveUnit.owner != PLAYER) return;
			if (charCode == 9) {	// Tab
				onClickOnSwap();
				playAudio('UIGenericClickAudio');
			}
		});

		pauseButton = MiscDatabases.generatePauseButton(() -> {
			GUI.openWith('SettingsUI', {
				onCloseClick: () -> GUI.close('SettingsUI'),
				isResolutionGrayed: true,
				isFullScreenGrayed: true
			});
		});
		inspectButton = MiscDatabases.generateInspectButton(() -> {
			Battlefield.onClickOnInspect();
		});
		close();
	}


	// open([currentlyOpenUnit])
	public override function open(?metadata : Array<Dynamic>) {
		latestSpellOwner = cast metadata[0];
		final marginOffset = if (Game.isMobile) k.mobileExtraMargin else 0;
		inventoryButton.show();
		inventoryButton.setRight(k.padding + marginOffset);
		inventoryButton.setBottom(k.padding);
		swapButton.show();
		swapButton.setRight(k.padding + ICON_FRAME_SIZE + k.padding + ICON_FRAME_SIZE + k.padding + marginOffset);
		swapButton.setBottom(k.padding);
		endTurnButton.show();
		endTurnButton.setRight(k.padding + ICON_FRAME_SIZE + k.padding + marginOffset);
		endTurnButton.setBottom(k.padding);
		for (i in 0...spellButtons.length) {
			if (i < latestSpellOwner.spells.length) {
				final buttonX = marginOffset + getScreenX() + i * (k.spellButtonSize + k.spaceBetweenButtons) + k.spaceBetweenButtons;
				final buttonY = getScreenY() + getScreenHeight() - k.padding - ICON_FRAME_SIZE;
				spellButtons[i].show();
				spellButtons[i].setX(buttonX);
				spellButtons[i].setY(buttonY);
			}
		}
		updateSpellButtons(latestSpellOwner);
		turnIndicators.setCurrentActiveUnitTurnIndicator(latestSpellOwner.uniqueID);
		BattlefieldUI_Tutorial.tryDoTutorialOnOpen();
	}
	public override function close() {
		unhighlightSpellButtons();
		inventoryButton.hide();
		endTurnButton.hide();
		swapButton.hide();
		for (button in spellButtons) {
			button.hide();
		}
	}
	
	

	// Events
	function onLongClickOnSpell(index : Int) {
		if (isButtonUnavailable(index)) return;
		var spellOwner = Battlefield.getCurrentlyActiveUnit();
		if(spellOwner.spells[index] == null) return;
		Battlefield.onLongClickOnSpell(index);
	}
	function onClickOnSpellButton(index : Int) {
		if (isButtonUnavailable(index)) return;
		isLongClicking = true;
		timeSinceSpellButtonWasClicked = 0;
		indexWhenSpellButtonWasClicked = index;
	}
	function onDisabledClickOnSpellButton(index: Int) {
		if (isButtonUnavailable(index)) return;
		if (GUI.isOpen('SpellPopupUI')) return;
		final spellOwner = Battlefield.getCurrentlyActiveUnit();
		final spellClicked = spellOwner.spells[index];
		if (spellClicked.isWasted) {
			spellOwner.say('I can\'t do that now.');
		} else if (spellClicked.cooldownRemaining > 0) {
			if (spellOwner.hasBuff('Silenced')) {
				spellOwner.say('I am silenced! I can\'t use abilities!');
			} else {
				spellOwner.say('I must wait ${spellClicked.cooldownRemaining} more turn${if (spellClicked.cooldownRemaining > 1) 's' else ''} to do that!');
			}
		} else {
			spellOwner.say('I can\'t do that.');
		}
	}
	function onReleaseOnSpellButton(index : Int) {
		if (isButtonUnavailable(index)) return;
		isLongClicking = false;
		if (indexWhenSpellButtonWasClicked != index) return;	// Not released on same spell as the one clicked
		var spellOwner = Battlefield.getCurrentlyActiveUnit();
		if (spellOwner.spells[index] == null) return;
		if (Game.isMobile && GUI.isOpen("SpellPopupUI")) {		// If there's a popup, don't do the click event
			return;
		}
		Battlefield.onClickOnSpell(index);
		final spellClicked = spellOwner.spells[index];
		BattlefieldUI_Tutorial.tryPlayerClickedOnSpell(index);
	}

	function onSpellButtonMouseEnter(index: Int) {
		if (Game.isMobile) return;
		if (isButtonUnavailable(index)) return;
		spellButtons[index].showKey('${index + 1}');
		Battlefield.onSpellButtonMouseEnter(index);
	}
	function onSpellButtonMouseExit(index: Int) {
		if (Game.isMobile) return;
		if (isButtonUnavailable(index)) return;
		spellButtons[index].hideKey();
		Battlefield.onSpellButtonMouseExit(index);
	}

	function onClickOnInventory() {	// When the button to open inv is clicked
		if (Game.isMobile && GUI.isOpen("SpellPopupUI")) return;
		if(GUI.isOpen("InventoryUI") || GUI.isOpen("PopupUI")){
			GUI.close("InventoryUI");
		} else {
			GUI.open('InventoryUI', [Player.inventory, USE, null, (itemClicked: Item) -> {
				if (itemClicked.type != 'CONSUMABLE') return;
				if (itemClicked.effect.isNonCombatOnly) return;
				GUI.openWith('PopupUI', {
					item: itemClicked,
					reason: USE,
					callback: (didUseItem: Bool, whichCharacterIndex: Int) -> {
						GUI.close('PopupUI');
						if (!didUseItem) return;
						var itemCoordinates: Position = itemClicked.consume(Player.inventory);					// Consumes the current item
						InventoryUI.self.updateItemVisuals(itemCoordinates.i, itemCoordinates.j);				// Updates inventory visuals
						itemClicked.use(Battlefield.getCurrentlyActiveUnit(), null);
					}
				});
			}]);
		}
	}
	function onClickOnEndTurn() {
		if (isButtonUnavailable()) return;
		if (Game.isMobile && GUI.isOpen("SpellPopupUI")) return;
		endTurnButton.hideKey();
		BattlefieldUI_Tutorial.tryPlayerClickedOnEndTurn();
		Battlefield.nextTurn();
	}
	function onClickOnSwap() {
		U.__CRASHIT = true;
		if (isButtonUnavailable()) return;
		if (Battlefield.getCurrentlyActiveUnit().owner != PLAYER) return;
		if (Battlefield.getAllAlivePlayerUnits().length == 1) return;
		if (Game.isMobile && GUI.isOpen("SpellPopupUI")) return;
		swapButton.hideKey();
		Battlefield.swapCharactersToAct();
		trace('Cancelling click on spell...');
		Battlefield.cancelClickOnSpell();
		trace('Done cancelled manu');
	}

	private function isButtonUnavailable(?index: Int = -1) {
		if (areSpellButtonsDisabled) return true;
		if (GUI.isOpen('SettingsUI') || !GUI.isOpen('BattlefieldUI')) return true;
		if (index == -1) return false;
		if (isOutOfBounds(Battlefield.getCurrentlyActiveUnit().spells, index)) return true;
		return false;
	}


	
	// Updates buttons to look like the current unit's spells
	public function updateSpellButtons(unit : Unit) {
		if (unit.owner != PLAYER) return;
		enableAllSpellButtons();
		latestSpellOwner = unit;
		for (i in 0...unit.spells.length) {
			final spell = unit.spells[i];
			if (spell == null) {
				spellButtons[i].setIcon(null);
				continue;
			}
			
			final hadTimer = spellButtons[i].hasTimer();
			spellButtons[i].hideTimer();
			final iconPath = spell.getIconPath();
			spellButtons[i].setIcon(
				if (ImageX.imageExists(iconPath)) iconPath
				else 'Icons/NotFound.png'
			);

			final isOnCooldown = spell.cooldownRemaining > 0;
			final isSilenced = unit.hasBuff('Silenced');
			final isOutOfMana = spell.getManaCost() > unit.mana;
			final isWasted = spell.isWasted;
			final isInfected = spell.isInfected;

			
			if (isOnCooldown && isSilenced) {
				spellButtons[i].setFrameAnimation('Silenced');
			} else if (isOnCooldown) {
				spellButtons[i].setFrameAnimation('Cooldown');
			} else if (isOutOfMana) {
				spellButtons[i].showMana('${spell.getManaCost()}');
			} else if (isInfected) {
				spellButtons[i].setFrameAnimation('Infected');
				spellButtons[i].showMana('${spell.getManaCost()}');	// Because the mana icon will be behind the frame
			} else {
				spellButtons[i].setFrameAnimation('Default');
				if (spell.getType() == NORMAL_MOVE) {
					// spellButtons[i].showMana('-1');
				} else if (spell.getType() == END_TURN) {

				} else {
					spellButtons[i].showMana('${spell.getManaCost()}');
				}
			}
			if (isOnCooldown) {
				final doTickingAnimation = if (unit.lastSpellCast != null && unit.lastSpellCast.isMoveSpell()) false else true;
				spellButtons[i].showTimer('${spell.cooldownRemaining}', doTickingAnimation);
			}
			if (isOnCooldown || isOutOfMana || isWasted) {
				disableSpellButton(i);
			}
		}
		if (Battlefield.playerUnitsToAct.length == 0) {
			swapButton.disableAndMarkAsGrayed();
		} else {
			swapButton.enableAndUnmarkAsGrayed();
		}
	}
	public function updateTurnIndicators() {
		turnIndicators.update();
	}
	public function setCurrentActiveUnitTurnIndicator(unitsUniqueId: Int) {
		turnIndicators.setCurrentActiveUnitTurnIndicator(unitsUniqueId);
	}

	public function disableSpellButton(i: Int) spellButtons[i].disableAndMarkAsGrayed();
	function enableAllSpellButtons() for (button in spellButtons) button.enableAndUnmarkAsGrayed();

	public function unhighlightSpellButtons() {
		if (currentSpellButtonHighlight != null) {
			currentSpellButtonHighlight.kill();
		}
		currentSpellButtonHighlight = null;
	}
	public function highlightSpellButton(index: Int) {
		unhighlightSpellButtons();
		spellButtons[index].frame.moveToTop();
		currentSpellButtonHighlight = new ImageX('UI/IconHighlight.png', 'UI');
		currentSpellButtonHighlight.attachToActor(
			spellButtons[index].frame,
			6,
			-6
		);
		// currentSpellButtonHighlight.setX(spellButtons[index].getX());
		// currentSpellButtonHighlight.setY(spellButtons[index].getY() - 6);
	}

	// For tutorial
	public function setTutorialState(newState: String) BattlefieldUI_Tutorial.tutorialState = newState;
	public function indicateSpell(index: Int) {
		BattlefieldUI_Tutorial.lastCreatedIndicator = indicateWithArrows(spellButtons[index].getX() + 40, spellButtons[index].getY() - 4);
	}
}

class BattlefieldUI_Tutorial {
	public static var lastCreatedIndicator: Actor;
	public static var tutorialState = 'NONE';
	public static function tryDoTutorialOnOpen() {
		if (Player.progression.tutorialDidClickOnMove == false) {
			final spellButtons = BattlefieldUI.self.spellButtons;
			lastCreatedIndicator = indicateWithArrows(spellButtons[0].getX() + 40, spellButtons[0].getY() - 4);
			tutorialState = 'WAITING_CLICK_ON_MOVE';
		}
		if (tutorialState == 'WAITING_LONG_CLICK_ON_BLOCK') {
			BattlefieldUI.self.indicateSpell(2);
		}
	}
	public static function tryPlayerClickedOnSpell(index) {
		tryPlayerClickedOnMove(index);
		tryPlayerClickedOnAttack(index);
	}
	public static function tryPlayerLongClickedOnSpell() {
		tryPlayerLongClickedOnBlock();
	}
	public static function tryPlayerClickedOnMove(index) {
		if (tutorialState != 'WAITING_CLICK_ON_MOVE') return;
		if (index != 0) {
			turnTutorialOff();
			return;
		}
		Player.progression.tutorialDidClickOnMove = true;
		removeIndicator(lastCreatedIndicator);
		final tile = Battlefield.getTile(2, 1);
		lastCreatedIndicator = indicateWithArrows(tile.getXCenter(), tile.getYCenter());
		tile.addDangerMarker('GreenMarkedCorners');
		tile.click = () -> {
			tryPlayerMoved();
		};
		Battlefield.tiles.forEach(function(t): Void {
			if (t == tile) return;
			t.click = function() {
				if (tutorialState != 'WAITING_MOVE') return;
				Battlefield.getTile(2, 1).removeDangerMarker();
				turnTutorialOff();
			}
		});
		tutorialState = 'WAITING_MOVE';
	}
	public static function tryPlayerMoved() {
		if (tutorialState != 'WAITING_MOVE') return;
		final spellButtons = BattlefieldUI.self.spellButtons;
		Player.progression.tutorialDidMoveOnce = true;
		removeIndicator(lastCreatedIndicator);
		Battlefield.getTile(2, 1).removeDangerMarker();
		tutorialState = 'NONE';
		doAfter(500, () -> {
			lastCreatedIndicator = indicateWithArrows(spellButtons[1].getX() + 40, spellButtons[1].getY() - 4);
			tutorialState = 'WAITING_CLICK_ON_ATTACK';
		});
	}
	public static function tryPlayerClickedOnAttack(index) {
		if (tutorialState != 'WAITING_CLICK_ON_ATTACK') return;
		if (index != 1) {
			turnTutorialOff();
			return;
		}
		Player.progression.tutorialDidClickOnAttack = true;
		removeIndicator(lastCreatedIndicator);
		final tile = Battlefield.getTile(2, 2);
		lastCreatedIndicator = indicateWithArrows(tile.getXCenter(), tile.getYCenter());
		tile.addDangerMarker('GreenMarkedCorners');
		tile.click = () -> {
			doAfter(750, () -> {
				tryPlayerAttacked();
			});
		};
		Battlefield.tiles.forEach(function(t): Void{
			if (t == tile) return;
			t.click = function() {
				if (tutorialState != 'WAITING_ATTACK') return;
				Battlefield.getTile(2, 2).removeDangerMarker();
				turnTutorialOff();
			}
		});
		tutorialState = 'WAITING_ATTACK';
	}
	public static function tryPlayerAttacked() {
		if (tutorialState != 'WAITING_ATTACK') return;
		final spellButtons = BattlefieldUI.self.spellButtons;
		Player.progression.tutorialDidAttackOnce = true;
		removeIndicator(lastCreatedIndicator);
		Battlefield.getTile(2, 2).removeDangerMarker();
		lastCreatedIndicator = indicateWithArrows(BattlefieldUI.self.endTurnButton.getX() + 40, BattlefieldUI.self.endTurnButton.getY() - 4);
		tutorialState = 'WAITING_CLICK_ON_END_TURN';
	}
	public static function tryPlayerClickedOnEndTurn() {
		if (tutorialState != 'WAITING_CLICK_ON_END_TURN') return;
		Player.progression.tutorialDidEndTurn = true;
		removeIndicator(lastCreatedIndicator);
		tutorialState = 'NONE';
	}

	public static function turnTutorialOff() {
		Battlefield.getRandomPlayerCharacterUnit().say("I know what to do.", 3);
		if (lastCreatedIndicator != null)
			removeIndicator(lastCreatedIndicator);
		Player.progression.tutorialDidClickOnMove = true;
		Player.progression.tutorialDidMoveOnce = true;
		Player.progression.tutorialDidClickOnAttack = true;
		Player.progression.tutorialDidAttackOnce = true;
		Player.progression.tutorialDidEndTurn = true;
		Player.progression.tutorialDidShopTutorial = true;
		tutorialState = 'NONE';
	}

	// Part 2
	public static function tryPlayerLongClickedOnBlock() {
		if (tutorialState != 'WAITING_LONG_CLICK_ON_BLOCK') return;	// Set this way from BattlefieldEncounterDatabase
		removeIndicator(lastCreatedIndicator);
		tutorialState = 'NONE';
	}
}
