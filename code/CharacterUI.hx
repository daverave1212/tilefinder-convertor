

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

import Std.int;

import scripts.Constants.*;
import U.*;
using U;

class CharacterInventoryUI {

	public static var k = {
		width				: -1,
		height				: -1,
		padding 			: 6,
		marginSides			: -1,
		marginBottom		: 13
	}


	public var icons: Array<FramedItem>;

	public function new() {
		k.width	 = 2 * ICON_FRAME_SIZE + 1 * k.padding;
		k.height = 2 * ICON_FRAME_SIZE + 1 * k.padding;
		icons = [for (_ in 0...PlayerCharacter.k.inventorySize) null];
		k.marginSides = int((CharacterUI.k.rightPanelWidth - k.width) / 2);
	}

	function click(iconClicked: Int) {
		if(!GUI.isOpen('CharacterUI')) return;
		CharacterUI.self.onClickOnItem(iconClicked);
	}

	public function killAllImages() {
		for (icon in icons) if (icon != null) icon.kill();
	}
	function getBackgroundImage() return CharacterUI.self.background;
	function getItemsAreaX() return int(CharacterUI.getRightPanelX() + k.marginSides);
	function getItemsAreaY() return int(getBackgroundImage().getY() + getBackgroundImage().getHeight() - k.marginBottom - k.height);

	public function close(){
		killAllImages();
	}

	public function open(){
		killAllImages();
		var currentlyOpenCharacter: PlayerCharacter = CharacterUI.self.currentlyOpenCharacter;
		for (i in 0...PlayerCharacter.k.inventorySize) {
			final item = currentlyOpenCharacter.equippedItems[i];
			final rowIndex = if (i == 0 || i == 1) 0 else 1;
			final colIndex = if (i == 0 || i == 2) 0 else 1;
			final x = getItemsAreaX() + colIndex * (ICON_FRAME_SIZE + k.padding);
			final y = getItemsAreaY() + rowIndex * (ICON_FRAME_SIZE + k.padding);
			icons[i] = new FramedItem(if (item == null) null else item.imagePath, 'CharacterUIIcons', x, y, 'Item');
			SpecialEffectsFluff.addPopBehaviorToActor(icons[i].frame);
			icons[i].click = () -> { click(i); }
		}
	}

}

class CharacterStatsUI {

	// All offsets are from the background
	public static var k = {
		descriptorOffsetX: 282,
		statNumberOffsetX: 377,
		statNumberOffsetY: 22,
		descriptorOffsetY: 23,
		spaceBetweenStats: 19,
		backgroundsOffsetX: 259,
		backgroundsOffsetY: 21
	}

	public var backgrounds : Array<ImageX>;
	public var descriptors : Array<TextLine>;
	public var statNumbers : Array<TextLine>;

	public function new(){
		backgrounds = [
			new ImageX('UI/StatBackgrounds/Damage.png', 'CharacterUIStatBackgrounds'),
			new ImageX('UI/StatBackgrounds/Armor.png', 'CharacterUIStatBackgrounds'),
			new ImageX('UI/StatBackgrounds/SpellPower.png', 'CharacterUIStatBackgrounds'),
			new ImageX('UI/StatBackgrounds/ManaRegen.png', 'CharacterUIStatBackgrounds'),
			new ImageX('UI/StatBackgrounds/Crit.png', 'CharacterUIStatBackgrounds'),
			new ImageX('UI/StatBackgrounds/Dodge.png', 'CharacterUIStatBackgrounds'),
			new ImageX('UI/StatBackgrounds/Speed.png', 'CharacterUIStatBackgrounds'),
		];
		TextLine.useFont(getFont(BROWN_ON_BROWN_TITLE_FONT));
		descriptors = [
			new TextLine('Damage'),
			new TextLine('Armor'),
			new TextLine('Spell Power'),
			new TextLine('Mana Regen'),
			new TextLine('Crit'),
			new TextLine('Dodge'),
			new TextLine('Movement')
		];
		TextLine.useFont(getFont(STAT_NUMBER_FONT));
		statNumbers = [for (i in 0...7) new TextLine('')];
		recalculatePosition();
		close();
	}

	function getBackgroundImage() return CharacterUI.self.background;

	function recalculatePosition() {
		var background = getBackgroundImage();
		for (i in 0...7) {
			backgrounds[i].setX(background.getX() + k.backgroundsOffsetX);
			backgrounds[i].setY(background.getY() + k.backgroundsOffsetY + i * k.spaceBetweenStats);
			descriptors[i].setSceneX(background.getX() + k.descriptorOffsetX);
			descriptors[i].setSceneY(background.getY() + k.descriptorOffsetY + i * k.spaceBetweenStats);
			statNumbers[i].alignLeft();
			statNumbers[i].setSceneX(background.getX() + k.statNumberOffsetX);
			statNumbers[i].setSceneY(background.getY() + k.statNumberOffsetY + i * k.spaceBetweenStats);
		}
	}

	public function open(playerCharacter: PlayerCharacter){
		for (b in backgrounds) b.show();
		for (d in descriptors) d.enable();
		for (s in statNumbers) s.enable();
		recalculatePosition();
		statNumbers[0].setText('' + playerCharacter.stats.damage);
		statNumbers[1].setText('' + playerCharacter.stats.armor + '%');
		statNumbers[2].setText('' + playerCharacter.stats.spellPower);
		statNumbers[3].setText('' + playerCharacter.stats.manaRegeneration);
		statNumbers[4].setText('' + playerCharacter.stats.crit + '%');
		statNumbers[5].setText('' + playerCharacter.stats.dodge + '%');
		statNumbers[6].setText('' + playerCharacter.stats.speed);
	}

	public function close(){
		for (b in backgrounds) b.hide();
		for (d in descriptors) d.disable();
		for (s in statNumbers) s.disable();
	}

}

class CharacterSpellsUI {


	public var k = {
		spaceBetweenButtons	: 4,
		padding				: 6,
		activePassiveButtonsOffsetX: 20,
		spellPanelWidth: 238,
		spellsOffsetY: 3,
		spellsBoxYFromBottom: 65,
		spellsBoxHeight: 47,
		spellsPanelYBottomFromBottom: 12
	}

	// public var spellButtons : Array<SUIButton>;
	public var spellButtons: Array<FramedItem>;

	public var activeToggleButton:  SUIButton;
	public var passiveToggleButton: SUIButton;
	public var spellsState = 'ACTIVE';	// or PASSIVE;

	function getCharacterSpellIndexByButtonIndex(buttonIndex : Int) return buttonIndex + 2;

	public function new() {
		spellButtons = [];
		for (i in 0...PlayerCharacter.k.maxNumberOfSpellsOfAType) {
			final spellButton = new FramedItem(null, 'CharacterUIIcons', 0, 0, 'Spell');
			SpecialEffectsFluff.addPopBehaviorToActor(spellButton.frame);
			spellButton.click = function() {
				if (GUI.isOpen('CharacterUI') == false) return;
				if (spellsState == 'ACTIVE') onClickOnActiveSpellButton(i);
				else onClickOnPassiveSpellButton(i);
			}
			spellButtons.push(spellButton);
		}
		activeToggleButton = new SUIButton('CharacterUISpellsToggle', 'CharacterUIIcons', 'Active', { enablePopAnimations: false });
		activeToggleButton.setText('Normal', getFont(BROWN_ON_BROWN_TITLE_FONT));
		activeToggleButton.click = () -> toggleActivePassive();
		passiveToggleButton = new SUIButton('CharacterUISpellsToggle', 'CharacterUIIcons', 'Inactive', { enablePopAnimations: false });
		passiveToggleButton.setText('Passive', getFont(BROWN_ON_BROWN_TITLE_FONT));
		passiveToggleButton.click = () -> toggleActivePassive();
		recalculatePosition();
		close();
	}

	function recalculatePosition() {
		final background = CharacterUI.self.background;
		final spellBoxY = background.getY() + background.getHeight() - k.spellsBoxYFromBottom;
		final spellY = spellBoxY + (k.spellsBoxHeight - ICON_FRAME_SIZE) / 2;
		final totalSpellWidth = PlayerCharacter.k.maxNumberOfSpellsOfAType * ICON_FRAME_SIZE + (PlayerCharacter.k.maxNumberOfSpellsOfAType - 1) * k.spaceBetweenButtons;
		final spellStartX = background.getX() + (k.spellPanelWidth - totalSpellWidth) / 2;
		for (i in 0...PlayerCharacter.k.maxNumberOfSpellsOfAType) {
			var spellButton = spellButtons[i];
			spellButton.setY(spellY);
			spellButton.setX(spellStartX + i * (ICON_FRAME_SIZE + k.spaceBetweenButtons));	
		}
		var toggleY = background.getY() + background.getHeight() - k.spellsPanelYBottomFromBottom - CharacterUI.k.bottomBorderWidth;
		activeToggleButton.setSceneY(toggleY);
		activeToggleButton.setSceneX(background.getX() + k.activePassiveButtonsOffsetX);
		passiveToggleButton.setSceneY(toggleY);
		passiveToggleButton.setSceneX(activeToggleButton.getSceneX() + activeToggleButton.getWidth());
	}

	function updateSpellButtons() {
		final spellsDisplayed: Array<SpellTemplate> =
			if (spellsState == 'ACTIVE') CharacterUI.self.currentlyOpenCharacter.getActiveUnlearnableSpells()
			else CharacterUI.self.currentlyOpenCharacter.getPassiveSpells();
		for (i in 0...PlayerCharacter.k.maxNumberOfSpellsOfAType) {
			spellButtons[i].show();
			spellButtons[i].setIcon(
				if (i < spellsDisplayed.length) spellsDisplayed[i].getIconPath()
				else null
			);
		}
	}

	public function open(playerCharacter: PlayerCharacter){
		recalculatePosition();
		updateSpellButtons();
		activeToggleButton.show();
		passiveToggleButton.show();
	}
	public function close(){
		for (sb in spellButtons) {
			sb.hide();
		}
		activeToggleButton.hide();
		passiveToggleButton.hide();
	}
	public function onClickOnActiveSpellButton(buttonIndex: Int) {
		final spells = CharacterUI.self.currentlyOpenCharacter.getActiveUnlearnableSpells();
		final chosenSpell = if (isOutOfBounds(spells, buttonIndex)) null else spells[buttonIndex];
		CharacterUI.self.onClickOnSpell(chosenSpell);
		
	}
	public function onClickOnPassiveSpellButton(buttonIndex: Int) {
		final spells = CharacterUI.self.currentlyOpenCharacter.getPassiveSpells();
		final chosenSpell = if (isOutOfBounds(spells, buttonIndex)) null else spells[buttonIndex];
		CharacterUI.self.onClickOnSpell(chosenSpell);
	}

	public function toggleActivePassive() {
		if (spellsState == 'ACTIVE') {
			spellsState = 'PASSIVE';
			activeToggleButton.setAnimation('Inactive');
			passiveToggleButton.setAnimation('Active');
		} else {
			spellsState = 'ACTIVE';
			activeToggleButton.setAnimation('Active');
			passiveToggleButton.setAnimation('Inactive');
		}
		updateSpellButtons();
	}

}

class CharacterBarsUI {

	public static var k = {
		overlayOffsetX: 5,
		overlayOffsetY: 155,
		overlay_healthX: 28,		// From overlay
		overlay_healthY: 2,
		overlay_manaX: 31,
		overlay_manaY: 15,
		overlay_healthTextY: 3,
		overlay_manaTextY: 16,
		// overlay_xpX: 1,
		// overlay_xpY: 31,
	}

	public var barsUnderlay	: Actor;
	public var barsOverlay  : Actor;
	public var healthBar	: ResourceBar;
	public var manaBar		: ResourceBar;

	public var healthText	: TextLine;
	public var manaText		: TextLine;

	public function new() {
		TextLine.useFont(getFont(SHADED_FONT));
		healthText  = new TextLine('');
		TextLine.useFont(getFont(SHADED_FONT));
		manaText  	= new TextLine('');
		healthText.alignCenter();
		manaText.alignCenter();
		barsUnderlay = createActor('CharacterUIBarsUnderlay', 'CharacterUIBarsUnderlay');	
		barsOverlay = createActor('CharacterUIBarsOverlay', 'CharacterUIBarsOverlay');	
		healthBar	= new ResourceBar('CharacterUIBar', 'CharacterUIBars', 10, {initialAnimation: 'Health'});
		manaBar 	= new ResourceBar('CharacterUIBar', 'CharacterUIBars', 10, {initialAnimation: 'Mana'});
		recalculatePosition();
		close();
	}

	function recalculatePosition() {
		var background = CharacterUI.self.background;
		barsUnderlay.setX(background.getX() + k.overlayOffsetX);
		barsUnderlay.setY(background.getY() + k.overlayOffsetY);
		barsOverlay.setX(background.getX() + k.overlayOffsetX);
		barsOverlay.setY(background.getY() + k.overlayOffsetY);
		healthBar.setX(barsOverlay.getX() + k.overlay_healthX);
		healthBar.setY(barsOverlay.getY() + k.overlay_healthY);
		manaBar.setX(barsOverlay.getX() + k.overlay_manaX);
		manaBar.setY(barsOverlay.getY() + k.overlay_manaY);
		healthText.setSceneX(barsOverlay.getXCenter());
		healthText.setSceneY(barsOverlay.getY() + k.overlay_healthTextY);
		manaText.setSceneX(barsOverlay.getXCenter());
		manaText.setSceneY(barsOverlay.getY() + k.overlay_manaTextY);
	}

	public function close() {
		barsOverlay.disableActorDrawing();
		barsUnderlay.disableActorDrawing();
		healthBar.hide();
		manaBar.hide();
		healthText.disable();
		manaText.disable();
	}

	public function open(pc) {
		barsOverlay.enableActorDrawing();
		barsUnderlay.enableActorDrawing();
		healthBar.show();
		manaBar.show();
		healthBar.reset(pc.stats.health);
		healthBar.set(pc.health);
		manaBar.reset(pc.stats.mana);
		manaBar.set(pc.mana);
		healthText.enable();
		manaText.enable();
		recalculatePosition();
		healthText.setText(pc.health + '/' + pc.stats.health);
		manaText.setText(pc.stats.mana + '/' + pc.stats.mana);	// Always full mana
	}

}


class CharacterUI extends SimpleUI
{
	public static var self : CharacterUI;

	public static var k = {
		bottomBorderWidth: 6,
		borderWidth: 5,
		backgroundPadding: 12,
		backgroundY: 3,
		modelBottomCenterYOffset: 115,
		modelXOffset: 118,
		rightPanelWidth: 154,
		nameX: 123,
		nameY: 14
	}

	// public var currentlyOpenCharacter : CharacterInTown;
	public var currentlyOpenCharacter: PlayerCharacter;
	public var onOpen: Void -> Void;
	public var onClose: Void -> Void;
	public var onSpellClick: Void -> Void;
	public var onItemClick: Void -> Void;

	var inventoryUI : CharacterInventoryUI;
	var statsUI		: CharacterStatsUI;
	var spellsUI	: CharacterSpellsUI;
	var barsUI		: CharacterBarsUI;
	
	var characterName  : TextLine;
	var characterModel : Actor;

	public var overlay		: ImageX;
	public var background	: ImageX;
	public var closeButton	: Actor;
	
	public function new() {
		super("CharacterUI");
        self = this;
	}

	public static function getRightPanelX() return self.background.getX() + self.background.getWidth() - k.rightPanelWidth;
	
	public override function load() {
		currentlyOpenCharacter = null;
		onOpen = null;
		onClose = null;
		onSpellClick = null;
		onItemClick = null;
		overlay = new ImageX('UI/BlackScreen.png', 'Underlay');
		overlay.setAlpha(0.5);
		background = new ImageX('UI/CharacterUIBackground.png', 'CharacterUI');
		inventoryUI = new CharacterInventoryUI();
		statsUI = new CharacterStatsUI();
		spellsUI = new CharacterSpellsUI();
		barsUI = new CharacterBarsUI();
		characterModel = createActor("UnitActor", "CharacterModel");
		characterModel.growTo(2, 2, 0, Easing.linear);
		characterName = new TextLine('', getFont(BROWN_ON_BROWN_TITLE_FONT), 0, 0);
		characterName.alignCenter();
		closeButton = createActor('ItemPopupCloseButton', 'CharacterUICloseButtonLayer');
		onClick(() -> {
			if (!!!GUI.isOpen('CharacterUI')) return;
			GUI.close('CharacterUI');
		}, closeButton);
		SpecialEffectsFluff.addPopBehaviorToActor(closeButton, (_) -> GUI.isOpen('CharacterUI'));	// Only if it's open
        close();
	}
	
	public override function openWith(?options: Dynamic) {
		overlay.show();
		overlay.centerOnScreen();
		background.show();
		background.centerOnScreen();
		background.setY(getScreenY() + k.backgroundY);
		currentlyOpenCharacter = cast options.currentlyOpenCharacter;
		onOpen = cast options.onOpen;
		onClose = cast options.onClose;
		onItemClick = cast options.onItemClick;
		onSpellClick = cast options.onSpellClick;
		inventoryUI.open();
		statsUI.open(currentlyOpenCharacter);
		spellsUI.open(currentlyOpenCharacter);
		barsUI.open(currentlyOpenCharacter);
		characterModel.enableActorDrawing();
		characterModel.setAnimation(currentlyOpenCharacter.getClassName());
		var modelX = background.getX() + k.modelXOffset - characterModel.getWidth() / 2;
		var modelY = background.getY() + k.modelBottomCenterYOffset - characterModel.getHeight();
		characterModel.setX(modelX);
		characterModel.setY(modelY);
		characterName.setSceneX(background.getX() + k.nameX);
		characterName.setSceneY(background.getY() + k.nameY);
		characterName.setText(currentlyOpenCharacter.name.toUpperCase());
		characterName.enable();
		MiscDatabases.setupCloseButton(closeButton, background);
		if (onOpen != null) {
			onOpen();
		}
	}

	public function reopen() {
		GUI.close('CharacterUI');
		GUI.openWith('CharacterUI', {
			currentlyOpenCharacter: currentlyOpenCharacter,
			onOpen: onOpen,
			onClose: onClose,
			onItemClick: onItemClick,
			onSpellClick: onSpellClick
		});
	}
	
	public override function close() {
		overlay.hide();
		inventoryUI.close();
		statsUI.close();
		spellsUI.close();
		barsUI.close();
		background.hide();
		characterModel.disableActorDrawing();
		closeButton.disableActorDrawing();
		characterName.disable();
		if (onClose != null) {
			onClose();
		}
	}

	public function onClickOnItem(itemIndex) {
		if (itemIndex == -1) return;
		var clickedItem = currentlyOpenCharacter.equippedItems[itemIndex];
		if (clickedItem == null) {
			GUI.close('CharacterUI');
			if (onItemClick != null) onItemClick();
			GUI.openWith('InventoryUI', {
				inventory: Player.inventory,
				character: currentlyOpenCharacter,
				reason: EQUIP,
				onClose: () -> reopen(),
				onItemClick: (itemClicked: Item) -> {
					if (itemClicked.type != 'GEAR') return;
					if (currentlyOpenCharacter.hasItem(itemClicked.name)) return;
					GUI.openWith('PopupUI', {
						item: itemClicked,
						reason: EQUIP,
						onClose: () -> {
							GUI.close('InventoryUI');
						},
						callback: (wasActionButtonClicked: Bool, _: Int) -> {
							if (wasActionButtonClicked) {
								playAudio('EquipAudio');
								var result = currentlyOpenCharacter.equipItemFromInventory(itemClicked, Player.inventory);
							}
							GUI.close('PopupUI');
						}
					});
				}
			});
		} else {
			GUI.close('CharacterUI');
			if (onItemClick != null) onItemClick();
			GUI.openWith('PopupUI', {
				item: clickedItem,
				reason: UNEQUIP,
				onClose: () -> {
					reopen();
				},
				callback: (wasActionButtonClicked: Bool, _: Int) -> {
					if (wasActionButtonClicked) {
						var unequipResult = currentlyOpenCharacter.unequipItemToInventory(clickedItem, Player.inventory);
						playAudio('EquipAudio');
					}
					GUI.close('PopupUI');
				}
			});
		}
	}

	public function onClickOnSpell(spellTemp: SpellTemplate) {
		GUI.close('CharacterUI');
		if (onSpellClick != null) onSpellClick();

		function onClickOnEquippedSpell() {
			GUI.openWith('SpellPopupUI', {
				spellName: spellTemp.name,
				entityWithStats: currentlyOpenCharacter,
				reason: UNLEARN,
				onClose: () -> {
					reopen();
				},
				callback: (didUnlearn: Bool) -> {
					if (didUnlearn) {
						currentlyOpenCharacter.unequipSpell(spellTemp.name);
					}
				}
			});
		}
		function onClickOnEmptySpellSlot() {
			GUI.openWith('InventoryUI', {
				inventory: Player.inventory,
				reason: LEARN_SPELL,
				character: currentlyOpenCharacter,
				onItemClick: (itemClicked: Item) -> {
					if (itemClicked.type != 'SPELL') return;
					final spellName = ItemsDatabase.getSpellNameFromItemName(itemClicked.name);
					if (currentlyOpenCharacter.hasSpell(spellName)) return;
					final spellName = ItemsDatabase.getSpellNameFromItemName(itemClicked.name);
					final canLearnSpell = currentlyOpenCharacter.hasSlotForSpell(spellName) && currentlyOpenCharacter.canClassLearnSpell(spellName);
					final reason = if (canLearnSpell) LEARN_SPELL else INSPECT;
					GUI.openWith('PopupUI', {
						item: itemClicked,
						reason: reason,
						onClose: () -> {
							GUI.close('InventoryUI');
						},
						callback: (didLearnSpell: Bool, _: Int) -> {
							if (didLearnSpell) {
								currentlyOpenCharacter.equipSpellFromInventory(itemClicked, Player.inventory);
							}
							GUI.close('PopupUI');
						}
					});
				},
				onClose: () -> reopen()
			});
		}

		if (spellTemp != null) {
			onClickOnEquippedSpell();
		} else {
			onClickOnEmptySpellSlot();
		}
	}

	
}




