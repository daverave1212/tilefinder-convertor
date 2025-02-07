

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


import scripts.Constants.*;
import U.*;
using U;


//     'InventoryUI', [Inventory, USE/BUY/SELL/EQUIP]
class InventoryItemContainer {

	public static var iconFrameBitmap: BitmapData;	// Initialized in InventoryUI
	public static var priceFrameBitmap: BitmapData;	// Initialized in InventoryUI
	public static var k = {
		priceFrameWidth		: 24,
		priceFrameHeight	: 14,
		priceDigitWidth		: 7,
		itemOffsetInFrame	: (ICON_FRAME_SIZE - ICON_SIZE) / 2,
		priceFrameOffset	: -2
	}

	public var frame: ImageX;
	public var icon: ImageX;
	public var priceFrame: ImageX;
	public var itemContained: Item;

	var isGrayedOut = false;

	public function destroy() {
		frame.kill();
		if (priceFrame != null) priceFrame.kill();
		if (icon != null) icon.kill();
		return this;
	}

	function create(options: { x: Float, y: Float, imagePath: String, hasPrice: Bool, isGrayedOut: Bool }) {
		frame = new ImageX(iconFrameBitmap, "Inventory");
		frame.show();
		frame.setX(options.x);
		frame.setY(options.y);

		if (icon != null) {
			icon.kill();
		}
		if (options.imagePath != null) {
			if (icon == null)
				icon = new ImageX(options.imagePath, 'Inventory');
			else
				icon.changeImage(options.imagePath);
			icon.setX(options.x + k.itemOffsetInFrame);
			icon.setY(options.y + k.itemOffsetInFrame);
			if (options.isGrayedOut) {
				icon.grayOut();
				isGrayedOut = options.isGrayedOut;
			}
			if (options.hasPrice) {
				priceFrame = new ImageX(priceFrameBitmap, 'Inventory');
				priceFrame.show();
				priceFrame.setX(options.x + k.priceFrameOffset);
				priceFrame.setY(options.y + k.priceFrameOffset);
			}
		}
	}
	public function update(options: { imagePath: String }) {
		var oldX = frame.getX();
		var oldY = frame.getY();
		var oldHasPrice = priceFrame != null;
		destroy();
		create({ x: oldX, y: oldY, imagePath: options.imagePath, hasPrice: oldHasPrice, isGrayedOut: this.isGrayedOut });
	}

	public function new(options: { x: Float, y: Float, imagePath: String, hasPrice: Bool, isGrayedOut: Bool }) {
		create(options);
	}

	public function onDrawDrawPrice(price: Int, g: G) {	// This will ONLY be called inside a draw function
		if (priceFrame == null) return;
		g.setFont(getFont(PRICE_FONT_ID));
		var priceX = frame.getXScreen();
		var priceY = frame.getYScreen() - 1;
		if (price < 10) priceX += Std.int((k.priceFrameWidth - k.priceDigitWidth) / 2);
		else if (price < 100) priceX += Std.int((k.priceFrameWidth - k.priceDigitWidth * 2) / 2);
		else if (price < 1000) priceX += Std.int((k.priceFrameWidth - k.priceDigitWidth * 3) / 2) + 1;
		g.drawString('' + price, priceX, priceY);
	}
}

class InventoryUI extends SimpleUI
{
	
	public static var k = {
		x		 			: 40,
		y		 			: 35,
		height		 		: 250,
		width		 		: 400,
		itemSize	 		: 32,
		frameSize			: 40,
		itemSpacingH 		: 5,
		itemSpacingV 		: 6,
		iconsOffsetY		: 0,

		playerGoldFrameX: 12,
		playerGoldFrameY: 24,

		iconsTotalWidth		: -1,	// Set on load
		iconsTotalHeight	: -1,	// Set on load
		itemsStartX			: -1,	// Set on load
		itemsStartY			: -1	// Set on load
	}
	
	public var overlay					: ImageX;
	public var backgroundBitmap 		: BitmapData;
	public var inventoryBackground 		: ImageX;
	public var closeButton				: Actor;

	public var icons					: Matrix<InventoryItemContainer>;
	public var playerGoldFrame			: ImageX;
	public var playerGoldTextLine		: TextLine;

	public var currentlyOpenInventory 	: Inventory<Item>;	// Item currently in popup
	public var currentScope				: Int;
	public var priceFont				: Font;
	public var currentlyOpenCharacter	: PlayerCharacter;	// Only exists if the given scope was EQUIP

	public var onItemClick: Item -> Void;
	public var onClose: Void -> Void;

	public static var self : InventoryUI;

	inline function isThisOpen() return currentlyOpenInventory != null;

	public function new() {
		super("InventoryUI");
		backgroundBitmap							= getExternalImage("UI/InventoryBackground.png");
		InventoryItemContainer.iconFrameBitmap		= getExternalImage("UI/IconFrameLarger.png");
		InventoryItemContainer.priceFrameBitmap		= getExternalImage("UI/PriceFrame.png");
		priceFont									= getFont(PRICE_FONT_ID);
		self = this;
	}
	
	public override function load() {
		onItemClick = null;
		onClose = null;
		overlay = new ImageX('UI/BlackScreen.png', 'Underlay');
		overlay.setAlpha(0.5);
		overlay.hide();
		closeButton = createActor('ItemPopupCloseButton', 'InventoryCloseButton');
		onClick(() -> {
			if (GUI.isOpen('PopupUI') || !GUI.isOpen('InventoryUI'))
				return;
			GUI.close('InventoryUI');
		}, closeButton);
		SpecialEffectsFluff.addPopBehaviorToActor(closeButton, (_) -> GUI.isOpen('InventoryUI'));	// Only if it's open
		closeButton.disableActorDrawing();
		onClick(click);
		onDraw(drawPriceFrame);
		playerGoldFrame = new ImageX(InventoryItemContainer.priceFrameBitmap, 'Inventory');
		playerGoldFrame.hide();
		playerGoldTextLine = new TextLine('', getFont(PRICE_FONT_ID), 0, 0);
		playerGoldTextLine.alignCenter();
	}

	function setupIcons() {
		icons = new Matrix(currentlyOpenInventory.nRows, currentlyOpenInventory.nCols);
		for (r in 0...currentlyOpenInventory.nRows) {
			for (c in 0...currentlyOpenInventory.nCols) {
				var item = currentlyOpenInventory.get(r, c);
				icons.set(r, c, new InventoryItemContainer({
					imagePath: if (item != null) item.imagePath else null,
					x: getIconX(c),
					y: getIconY(r),
					hasPrice: shouldDrawPriceForScope(currentScope),
					isGrayedOut: shouldItemBeGrayedOut(item)
				}));
			}
		}
	}
	function setupInventory() {
		k.iconsTotalWidth  = k.frameSize * currentlyOpenInventory.nCols + k.itemSpacingH * (currentlyOpenInventory.nCols - 1);
		k.iconsTotalHeight = k.frameSize * currentlyOpenInventory.nRows + k.itemSpacingV * (currentlyOpenInventory.nRows - 1);
		k.itemsStartX = Math.floor((getScreenWidth() - k.iconsTotalWidth) / 2);
		k.itemsStartY = Math.floor((getScreenHeight() - k.iconsTotalHeight) / 2) + k.iconsOffsetY;
		function openInventory(){
			
		}
		overlay.show();
		overlay.centerOnScreen();
		inventoryBackground = new ImageX(backgroundBitmap, "Inventory");
		inventoryBackground.centerOnScreen();
		setupIcons();
		MiscDatabases.setupCloseButton(closeButton, inventoryBackground);
		// closeButton.enableActorDrawing();
		// closeButton.growTo(1, 1, 0);
		// closeButton.setX(inventoryBackground.getX() + inventoryBackground.getWidth() - closeButton.getWidth() + 8);
		// closeButton.setY(inventoryBackground.getY());
		playerGoldFrame.show();
		playerGoldFrame.setX(inventoryBackground.getX() + k.playerGoldFrameX);
		playerGoldFrame.setY(inventoryBackground.getY() + inventoryBackground.getHeight() - k.playerGoldFrameY);
		playerGoldTextLine.enable();
		playerGoldTextLine.setText(Player.gold + '');
		playerGoldTextLine.setSceneX(playerGoldFrame.getX() + playerGoldFrame.getWidth() / 2);
		playerGoldTextLine.setSceneY(playerGoldFrame.getY() + 1);
	}
	public override function openWith(?options: Dynamic) {
		if (options.reason == null && options.scope == null) trace('WARNING: Scope (or reason) not given for InventoryUI openWith');
		currentlyOpenInventory = options.inventory;
		currentScope = if (options.scope != null) options.scope else options.reason;
		currentlyOpenCharacter = options.character;
		onItemClick = options.onItemClick;
		onClose = options.onClose;
		setupInventory();
	}

	// Open with an Array of Dynamic, containing the inventory and the scope
	// E.g. GUI.open("InventoryUI", [Player.inventory, USE, currentlyOpenCharacter, ])
	public override function open(?metadata : Array<Dynamic>) {
		function setupMetadata() {
			var args : Array<Dynamic> = cast metadata;
			if (args == null) 	 throwAndLogError("ERROR: Opening inventory with null metadata. You must open it as ...open('InventoryUI', [Player.inventory, USE]");
			if (args.length < 2) throwAndLogError("ERROR: Opening inventory with less than 2 arguments");
			currentlyOpenInventory = cast args[0];
			currentScope = cast args[1];
			if (currentScope == EQUIP || currentScope == LEARN_SPELL) {
				if (args.length < 3) throw 'ERROR: currentlyOpenCharacter not given when opening InventoryUI with scope ${currentScope}';
				currentlyOpenCharacter = cast args[2];
			}
			onItemClick = if (metadata.length > 3) metadata[3] else null;
			onClose = if (metadata.length > 4) metadata[4] else null;
		}
		setupMetadata();
		setupInventory();
	}

	public function refresh() {
		icons.forEach(iconContainer -> iconContainer.destroy());
		setupIcons();
		playerGoldTextLine.setText(Player.gold + '');
	}
	public override function close() {
		if (!GUI.isOpen('InventoryUI')) {
			trace('InventoryUI not open. Nothing to close.');
			return;
		}
		currentlyOpenInventory = null;
		currentlyOpenCharacter = null;
		onItemClick = null;
		inventoryBackground.kill();
		icons.forEach(iconContainer -> iconContainer.destroy());
		overlay.hide();
		closeButton.disableActorDrawing();
		playerGoldFrame.hide();
		playerGoldTextLine.disable();
		if (onClose != null) {
			onClose();
			onClose = null;
		}
	}
	
	function click() {
		if( GUI.isOpen("PopupUI") || !GUI.isOpen("InventoryUI") ) return;
		var coords = getClickedItemByMouseCoordinates();
		if (coords == null) return;
		var itemClicked = currentlyOpenInventory.get(coords.y, coords.x);
		if (itemClicked == null) return;
		if (onItemClick != null) {
			onItemClick(itemClicked);
			return;
		}
		throwAndLogError('This case ${currentScope} should be handled with an onItemClick!');
	}

	public function updateItemVisuals(i, j) {			// Called from PopupUI
		if (!GUI.isOpen('InventoryUI')) return;
		var item = currentlyOpenInventory.get(i, j);
		icons.get(i, j).update({ imagePath: if (item != null) item.imagePath else null });
	}

	inline function getIconX(c : Int) return k.itemsStartX + c * k.itemSpacingH + c * k.frameSize + getScreenX();
	inline function getIconY(r : Int) return k.itemsStartY + r * k.itemSpacingV + r * k.frameSize + getScreenY();
	function getIconCol(x : Float) : Int {
		if (x < k.itemsStartX || x > k.itemsStartX + k.iconsTotalWidth) return -1;
		var startX = x - k.itemsStartX;
		return Math.floor(startX / (k.frameSize + k.itemSpacingH));
	}
	function getIconRow(y : Float) : Int {
		if (y < k.itemsStartY || y > k.itemsStartY + k.iconsTotalHeight) return -1;
		var startY = y - k.itemsStartY;
		return Math.floor(startY / (k.frameSize + k.itemSpacingV));
	}


	static function shouldDrawPriceForScope(scope: Int) {
		if (scope == USE || scope == EQUIP) return false;
		return true;
	}
	function shouldItemBeGrayedOut(item: Item) {
		if (item == null) return false;
		if (currentScope == EQUIP) {
			if (item.type != 'GEAR') return true;
			if (item.type == 'GEAR' && currentlyOpenCharacter.hasItem(item.name)) return true;
		}
		if (currentScope == USE) {
			if (item.type != 'CONSUMABLE') return true;
			else if (item.effect.isCombatOnly && getCurrentSceneName() != 'BattlefieldScene') return true;
			else if (item.effect.isNonCombatOnly && getCurrentSceneName() == 'BattlefieldScene') return true;
		}
		if (currentScope == LEARN_SPELL && item.type != 'SPELL') return true;
		if (currentScope == LEARN_SPELL) {
			if (item.type != 'SPELL') return true;
			final spellName = ItemsDatabase.getSpellNameFromItemName(item.name);
			if (currentlyOpenCharacter.hasSpell(spellName)) return true;
		}
		return false;
	}

	private function drawPriceFrame(g : G) {
		if (isThisOpen() == false) return;
		if (!!!shouldDrawPriceForScope(currentScope)) return;
		if (GUI.isOpen('PopupUI')) {
			return;
		}
		for (r in 0...currentlyOpenInventory.nRows) {
			for (c in 0...currentlyOpenInventory.nCols) {				
				var thisItem = currentlyOpenInventory.get(r, c);
				if (thisItem == null) continue;
				var displayedPrice: Int = thisItem.price;
				if (currentScope == SELL || currentScope == LOOT)
					displayedPrice = thisItem.getSellPrice();
				if (icons.get(r, c) == null) return;				// This can happen when this function gets called before open finishes
				icons.get(r, c).onDrawDrawPrice(displayedPrice, g);
			}
		}
	}

	
	
	private function getClickedItemByMouseCoordinates() : Vector2Int{
		var mouseXScreen = getMouseX();
		var mouseYScreen = getMouseY();
		var atWhichX = getIconCol(mouseXScreen);
		var atWhichY = getIconRow(mouseYScreen);
		if (atWhichX == -1 || atWhichY == -1) return null;
		return new Vector2Int(atWhichX, atWhichY);
	}
	
	
	
}




