

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

class PopupUI_Instance {

	public static var k = {
		icon: {
			offsetX:	9,		// Relative to the background image, which is centered
			offsetY:	16
		},
		title: {
			offsetY:	30,
			offsetX:	98		// Relative to the background, and refers to the center of the text
		},
		stats: {
			spaceBetween: 		3,
			backgroundsHeight: 	16,
			backgroundsWidth: 	120,
			backgroundsOffsetX: 39,
			descriptorsOffsetX: 22,
			descriptorsOffsetY: 57,
			numbersOffsetX:		117,
			numbersOffsetY:		55
		},
		descBox: {
			offsetYFromBottomPartY: 12,
			width: 		140,
			height: 	100,
			lineSpacing: 8
		},
		other: {
			middleHeightIfNoStats: 30,
			middlePaddingGeneral: 9,
			actionButtonOffsetYFromBottom: -14
		}
	}

	public var backgroundPanel			: PanelVerticable;
	public var framedItem				: FramedItem;

	public var closeButton				: Actor;
	public var actionButton				: SButton;

	public var currentPlayerCharacterIndex  : Int;
	public var characterIndicator: CurrentCharacterIndicatorUIComponent;

	public var currentlyOpenItem		: Item;
	public var currentlyOpenInventory	: Inventory<Item>;
	public var currentlyOpenCharacter	: PlayerCharacter;			// Only exists if the given scope was EQUIP
	public var callback					: Bool -> Int -> Void;		// actionButtonClicked -> currentPlayerCharacterIndex -> Void
	public var onClose					: Void -> Void;
	public var yOffset					: Float = 0;

	public var reason					: Int;

	public var titleTextLine			: TextLine;
	public var descriptionTextBox		: TextBox;
	public var statBackgrounds			: Map<String, ImageX>;	// Since they're images, preload them
	public var statDescriptors			: Array<TextLine>;
	public var statNumbers				: Array<TextLine>;

	var allowClicks						: Bool = false;		// To prevent click propagation and triggering a click immediately on open
	var showCloseButton					: Bool = true;


	public inline function isThisOpen() return backgroundPanel.imageTop.isShown;

	public function new(hasCloseButtonSlot = true) {
		final bitmapTop = if (hasCloseButtonSlot) PopupUI.backgroundBitmapTop else PopupUI.backgroundBitmapTopAlternative;
		backgroundPanel	 	= new PanelVerticable(bitmapTop, PopupUI.backgroundBitmapMiddle, PopupUI.backgroundBitmapBottom, 'ItemPopup');
		framedItem			= new FramedItem('Icons/NotFound.png', 'ItemPopupIcon', 0, 0);
		closeButton 		= createActor('ItemPopupCloseButton', 'ItemPopupIcon');
		SpecialEffectsFluff.addPopBehaviorToActor(closeButton, 1.0, (_) -> GUI.isOpen('PopupUI'));
		actionButton 		= new SButton("ItemPopupActionButton", "ItemPopup", 'tbd');
		titleTextLine		= new TextLine(' ', getFont(BROWN_ON_BROWN_TITLE_FONT), 0, 0);
		titleTextLine.alignCenter();
		descriptionTextBox  = new TextBox(k.descBox.width, k.descBox.height, 0, 0, PopupUI.flavorFont);
		descriptionTextBox.centerHorizontally = true;
		descriptionTextBox.centerVertically = true;
		descriptionTextBox.lineSpacing = k.descBox.lineSpacing;

		characterIndicator = new CurrentCharacterIndicatorUIComponent();

		statBackgrounds = [
			'Health' 		=> new ImageX('UI/StatBackgrounds/Health.png', 'ItemPopupStatBackgrounds'),
			'Mana' 			=> new ImageX('UI/StatBackgrounds/Mana.png', 'ItemPopupStatBackgrounds'),
			'Damage' 		=> new ImageX('UI/StatBackgrounds/Damage.png', 'ItemPopupStatBackgrounds'),
			'Spell Power' 	=> new ImageX('UI/StatBackgrounds/SpellPower.png', 'ItemPopupStatBackgrounds'),
			'Armor' 		=> new ImageX('UI/StatBackgrounds/Armor.png', 'ItemPopupStatBackgrounds'),
			'Mana Regen' 	=> new ImageX('UI/StatBackgrounds/ManaRegen.png', 'ItemPopupStatBackgrounds'),
			'Crit' 			=> new ImageX('UI/StatBackgrounds/Crit.png', 'ItemPopupStatBackgrounds'),
			'Dodge' 		=> new ImageX('UI/StatBackgrounds/Dodge.png', 'ItemPopupStatBackgrounds'),
			'Initiative' 	=> new ImageX('UI/StatBackgrounds/Initiative.png', 'ItemPopupStatBackgrounds'),
			'Speed' 		=> new ImageX('UI/StatBackgrounds/Speed.png', 'ItemPopupStatBackgrounds')
		];
		statDescriptors = [for (i in 0...10) new TextLine('', getFont(BROWN_ON_BROWN_TITLE_FONT))];
		statNumbers = [for (i in 0...10) new TextLine('', getFont(STAT_NUMBER_FONT))];
		onClick(closeButtonClick, closeButton);
		actionButton.click = actionButtonClick;
		close();
	}

	public function openWith(?options: Dynamic) {
		currentlyOpenItem = options.item;
		currentlyOpenInventory = options.inventory;
		reason = options.reason;
		currentlyOpenCharacter = options.character;
		callback = options.callback;
		onClose = options.onClose;
		showCloseButton = if (options.showCloseButton != null) options.showCloseButton else true;
		yOffset = if (options.yOffset != null) options.yOffset else 0;
		final x = if (options.x != null) options.x else getScreenXCenter() - backgroundPanel.getWidth() / 2;
		allowClicks = false;
		U.doAfter(100, () -> { allowClicks = true; });	// Only allow clicks after 0.1 seconds (to prevent click propagation problems)
		openPopup(x);
	}

	private function openPopup(x: Float) {
		function getTotalStatsHeight(): Float {
			final nNonZeroStats: Int = currentlyOpenItem.getNumberOfNonZeroStats();
			final statBGHeight = statBackgrounds['Health'].getHeight();
			final totalStatsHeight: Float =
				if (nNonZeroStats == 0) 0
				else nNonZeroStats * statBGHeight + (nNonZeroStats - 1) * k.stats.spaceBetween;
			return totalStatsHeight;
		}
		function recalculateHeight() {
			final nNonZeroStats = currentlyOpenItem.getNumberOfNonZeroStats();
			final newMiddleHeight =
				if (nNonZeroStats == 0)	descriptionTextBox.nLines * k.descBox.lineSpacing + 16
				else
					k.other.middlePaddingGeneral + 
					getTotalStatsHeight() +
					k.other.middlePaddingGeneral +
					descriptionTextBox.getActualHeight() +
					k.other.middlePaddingGeneral;
			backgroundPanel.setMiddleHeight(int(newMiddleHeight));
		}
		function recalculatePositions() {
			backgroundPanel.centerVertically();
			backgroundPanel.setY(backgroundPanel.getY() + yOffset);
			backgroundPanel.setX(x);
			if (showCloseButton) {
				MiscDatabases.setupCloseButton(closeButton, backgroundPanel.imageTop);
			}
			actionButton.setSceneXCenter(backgroundPanel.getXCenter());
			actionButton.setBottomFrom(k.other.actionButtonOffsetYFromBottom, backgroundPanel.getYBottom() - getScreenY());
			framedItem.setX(backgroundPanel.getX() + k.icon.offsetX);
			framedItem.setY(backgroundPanel.getY() + k.icon.offsetY);
			framedItem.startGlowingByRarity(currentlyOpenItem.rarity);
			titleTextLine.setSceneX(backgroundPanel.getX() + k.title.offsetX);
			titleTextLine.setSceneY(backgroundPanel.getY() + k.title.offsetY);
			if (currentlyOpenItem.hasNoStats()) {
				final descBoxY = backgroundPanel.imageTop.getYBottom() + backgroundPanel.getMiddleHeight() / 2;
				descriptionTextBox.setPosition(backgroundPanel.getXCenter(), descBoxY);
			} else {
				final descBoxY =
					backgroundPanel.imageMiddle.getY() +
					k.other.middlePaddingGeneral +
					getTotalStatsHeight() + 
					k.other.middlePaddingGeneral +
					descriptionTextBox.getActualHeight() / 2;
				descriptionTextBox.setPosition(backgroundPanel.getXCenter(), descBoxY);
			}
		}
		function drawStats() {
			var i = 0;
			final yStart = backgroundPanel.getMiddleY() + k.other.middlePaddingGeneral;
			if (currentlyOpenItem.type == 'GEAR' && currentlyOpenItem.stats != null) {
				currentlyOpenItem.stats.forEachNonZero((name, value) -> {
					var bgx = backgroundPanel.getXCenter() - k.stats.backgroundsWidth / 2;
					var bgy = yStart + i * (k.stats.backgroundsHeight + k.stats.spaceBetween);
					var descx = bgx + k.stats.descriptorsOffsetX;
					var descy = bgy + 2;
					var nrx = bgx + k.stats.numbersOffsetX;
					var nry = bgy + 1;
					statBackgrounds[name].show();
					statBackgrounds[name].setX(bgx);
					statBackgrounds[name].setY(bgy);
					statDescriptors[i].enable();
					statDescriptors[i].setText(name);
					statDescriptors[i].setSceneX(descx);
					statDescriptors[i].setSceneY(descy);
					statNumbers[i].enable();
					statNumbers[i].alignLeft();
					statNumbers[i].setText(value + if (Stats.isPercentage(name)) '%' else '');
					statNumbers[i].setSceneX(nrx);
					statNumbers[i].setSceneY(nry);
					i++;
				});
			}
		}
		
		backgroundPanel.show();
		framedItem.show();
		framedItem.setIcon(currentlyOpenItem.imagePath);
		descriptionTextBox.startDrawing();
		descriptionTextBox.setText(currentlyOpenItem.getDescription());
		titleTextLine.enable();
		recalculateHeight();
		recalculatePositions();
		drawStats();
		titleTextLine.setText(currentlyOpenItem.name);
		if (showCloseButton) {
			closeButton.enableActorDrawing();
			closeButton.growTo(1, 1, 0);
		}
		actionButton.show();
		if (reason == USE && getCurrentSceneName() != 'BattlefieldScene') {
			final allowClicksOnlyIfPopup = () -> GUI.isOpen('PopupUI');
			characterIndicator.open(backgroundPanel.getY() + 20, backgroundPanel.getX(), allowClicksOnlyIfPopup);
		}
		switch (reason) {
			case USE: actionButton.setText('USE', PopupUI.actionButtonFont, BUTTON_TEXT_Y);
			case SELL: actionButton.setText('SELL', PopupUI.actionButtonFont, BUTTON_TEXT_Y);
			case BUY: actionButton.setText('BUY', PopupUI.actionButtonFont, BUTTON_TEXT_Y);
			case EQUIP: actionButton.setText('EQUIP', PopupUI.actionButtonFont, BUTTON_TEXT_Y);
			case UNEQUIP: actionButton.setText('UNEQUIP', PopupUI.actionButtonFont, BUTTON_TEXT_Y);
			case LEARN_SPELL: actionButton.setText('LEARN', PopupUI.actionButtonFont, BUTTON_TEXT_Y);
			case LOOT: actionButton.setText('CHOOSE', PopupUI.actionButtonFont, BUTTON_TEXT_Y);
			case TRIBUTE: actionButton.setText('CHOOSE', PopupUI.actionButtonFont, BUTTON_TEXT_Y);
			case INSPECT: actionButton.hide();
			default: throwAndLogError('Unknown PopupUI reason text ${reason}');
		}
	}

	public function close() {
		backgroundPanel.hide();
		framedItem.hide();
		closeButton.disableActorDrawing();
		actionButton.hide();
		titleTextLine.disable();
		descriptionTextBox.stopDrawing();
		for (statNumber in statNumbers) statNumber.disable();
		for (statDesc in statDescriptors) statDesc.disable();
		for (key in statBackgrounds.keys()) statBackgrounds[key].hide();
		currentlyOpenItem = null;
		currentlyOpenInventory = null;
		currentlyOpenCharacter = null;
		callback = null;
		if (characterIndicator != null) {
			characterIndicator.hide();
		}
		if (onClose != null) {
			onClose();
			onClose = null;
		}
	}

	function actionButtonClick() {
		if (!allowClicks) return;
		if (callback != null) {
			callback(true, if (characterIndicator != null) characterIndicator.currentPlayerCharacterIndex else -1);
			return;
		}
		switch (reason) {
			case LOOT, EQUIP, UNEQUIP, INSPECT, LEARN_SPELL, USE, BUY, SELL, TRIBUTE:
				throwAndLogError('This reason ${reason} should be handled with a callback!!');

		}
	}

	function closeButtonClick() {
		if (showCloseButton == false) return;
		if (!allowClicks) return;
		if (callback != null) {
			callback(false, if (characterIndicator != null) characterIndicator.currentPlayerCharacterIndex else -1);
		}
		GUI.close("PopupUI");
	}

	function getIconSpaceUntilMiddlePanel() return backgroundPanel.imageTop.getHeight() - (ICON_FRAME_SIZE + k.icon.offsetY);



}

// 'PopupUI', [Item, USE/BUY/SELL/LOOT]
class PopupUI extends SimpleUI {

	public static var k = {
		width: 162
	};

	public static var self 								: PopupUI;

	public static var backgroundBitmapTop				: BitmapData;
	public static var backgroundBitmapMiddle			: BitmapData;
	public static var backgroundBitmapBottom			: BitmapData;
	public static var backgroundBitmapTopAlternative	: BitmapData;

	public static var actionButtonFont					: Font;
	public static var flavorFont						: Font;


	
	public var overlay					: ImageX;

	public var popupUIInstance			: PopupUI_Instance;

	public inline function isThisOpen() return popupUIInstance != null && popupUIInstance.backgroundPanel.imageTop.isShown;

	public function new() {
		super('PopupUI');
		backgroundBitmapTop 			= getExternalImage("UI/ItemPopupBackground_top.png");
		backgroundBitmapTopAlternative 	= getExternalImage("UI/ItemPopupBackground_top_alternative.png");
		backgroundBitmapMiddle 			= getExternalImage("UI/ItemPopupBackground_middle.png");
		backgroundBitmapBottom 			= getExternalImage("UI/ItemPopupBackground_bottom.png");
		actionButtonFont				= getFont(BROWN_ON_BROWN_TITLE_FONT);
		flavorFont						= getFont(ITEM_FLAVOR_FONT);
		self = this;
	}

	public override function load() {
		overlay				= new ImageX('UI/BlackScreen.png', 'ItemPopupOverlay');
		overlay.setAlpha(0.5);
		overlay.hide();

		popupUIInstance = new PopupUI_Instance();
	}


	public override function openWith(?options: Dynamic) {
		overlay.show();
		popupUIInstance.openWith(options);
	}

	// Opens a popup with the item
	// Takes: Item, Inventory<Item>, reason, CharacterInTown (optional),
	public override function open(?metadata : Array<Dynamic>) {
		if(metadata == null) trace("ERROR: Opened PopupUI without arguments");
		try {
			final currentlyOpenItem: Item = cast metadata[0];
			final currentlyOpenInventory: Inventory<Item> = cast metadata[1];
			final reason: Int = cast metadata[2];
			var currentlyOpenCharacter: PlayerCharacter = null;
			if (reason == EQUIP || reason == UNEQUIP || reason == LEARN_SPELL) {
				currentlyOpenCharacter = cast metadata[3];
			}
			final callback: Bool -> Void = if (metadata.length > 4) cast metadata[4] else null;
			openWith({
				currentlyOpenItem: currentlyOpenItem,
				currentlyOpenInventory: currentlyOpenInventory,
				reason: reason,
				currentlyOpenCharacter: currentlyOpenCharacter,
				callback: callback
			});
		} catch (e : String){
			trace("ERROR: Opened PopupUI with WRONG arguments; Check again?");
		}
	}
	
	public override function close() {
		if (GUI.isOpen('PopupUI') == false) return;
		overlay.hide();
		popupUIInstance.close();
	}

	public static function newInstance(hasCloseButtonSlot = true) {
		return new PopupUI_Instance(hasCloseButtonSlot);
	}
}


