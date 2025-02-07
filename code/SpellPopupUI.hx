

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
using StringTools;

class SpellPopupUI extends SimpleUI {

	public var k = {
		icon: {
			offsetX:	17,		// Relative to the background image, which is centered
			offsetY:	19
		},
		title: {
			offsetY:	34,
			offsetX:	114		// Relative to the background, and refers to the center of the text
		},
		descBox: {
			offsetYFromCenter: 	22,
			offsetX: 			18,
			width: 				150,
			height: 			100,
			lineSpacing: 		10
		},
		other: {
			actionButtonOffsetYFromBottom: -14
		},
		iconOffsetX 		: 24,	// Relative to the background image, which is centered
		iconOffsetY 		: 24,
		descBoxWidth 		: 200 - 24 * 2,
		descBoxHeight 		: 200,
		itemWidth	 		: 34,
		itemHeight	 		: 34,
		titleOffsetX		: 75,
		titleOffsetY		: 24,
		manaCostOffsetX		: 75,
		manaCostOffsetY		: 42
	}

    public static var self 				: SpellPopupUI;

	public var overlay					: ImageX;
	public var backgroundPanel			: ImageX;
	public var iconFrame	  			: ImageX;
	public var icon			  			: ImageX;

	public var closeButton				: Actor;
	public var actionButton				: SUIButton;

	public var currentlyOpenEntityWithStats: EntityWithStats;
	public var currentlyOpenSpellName   : String;

	public var reason                   : Int;      // VIEW, UNLEARN
	public var followCursor				: Bool = false;
	public var showCloseButton			: Bool = true;
	public var showBlackOverlay			: Bool = true;

	public var titleTextLine			: TextLine;
	public var descriptionTextBox		: TextBox;

	public var manaCostFrame			: ImageX;
	public var cooldownFrame			: ImageX;
	public var manaCostText				: TextLine;
	public var cooldownText				: TextLine;
	public var textIconsData			: Array<{
		image: ImageX,
		xOffset: Float,
		yOffset: Float
	}> = [];

	public var callback					: Bool -> Void;
	public var onClose					: Void -> Void;

	public inline function isThisOpen() return backgroundPanel != null && backgroundPanel.isShown;

	public function new(){
		super('SpellPopupUI');
		self = this;
	}

	public override function load(){
		overlay				= new ImageX('UI/BlackScreen.png', 'ItemPopupOverlay');
		overlay.setAlpha(0.5);
		backgroundPanel	 	= new ImageX('UI/SpellPopupBackground.png', 'ItemPopup');
		iconFrame 	 		= new ImageX('UI/IconFrameLarger.png', "ItemPopup");
		icon		 		= new ImageX('UI/IconFrameLarger.png', "ItemPopup");
		closeButton 		= createActor('ItemPopupCloseButton', 'ItemPopupStatBackgrounds');
		SpecialEffectsFluff.addPopBehaviorToActor(closeButton, 1.0, (_) -> GUI.isOpen('SpellPopupUI'));
		actionButton 		= new SUIButton("ItemPopupActionButton", "ItemPopup");
		titleTextLine		= new TextLine(' ', getFont(BROWN_ON_BROWN_TITLE_FONT), 0, 0);
		descriptionTextBox  = new TextBox(k.descBox.width, k.descBox.height, 0, 0, getFont(BROWN_ON_BROWN_TITLE_FONT));
		descriptionTextBox.centerVertically = true;
		descriptionTextBox.lineSpacing = k.descBox.lineSpacing;
		U.onClick(closeButtonClick, closeButton);
		actionButton.click = actionButtonClick;
		doEvery(25, () -> {
			if (followCursor && isThisOpen()) {
				setXY(getMouseX() + getScreenX() + 12, getMouseY() + getScreenY() - backgroundPanel.getHeight() - 12);
			}
		});
		manaCostFrame		= new ImageX('UI/SpellManaCost.png', 'ItemPopup');
		cooldownFrame		= new ImageX('UI/SpellCooldown.png', 'ItemPopup');
		manaCostText		= new TextLine('',  getFont(SHADED_FONT));
		cooldownText		= new TextLine('',  getFont(SHADED_FONT));
		manaCostText.alignCenter();
		cooldownText.alignCenter();
		onClose = null;
		close();
	}

	public override function close() {
		if (showBlackOverlay)
			overlay.hide();
		backgroundPanel.hide();
		iconFrame.hide();
		icon.hide();
		actionButton.hide();
		titleTextLine.disable();
		descriptionTextBox.stopDrawing();
		closeButton.disableActorDrawing();
		manaCostFrame.hide();
		cooldownFrame.hide();
		manaCostText.disable();
		cooldownText.disable();
		currentlyOpenSpellName = null;
		for (elem in textIconsData) {
			if (elem != null && elem.image != null) {
				elem.image.kill();
			}
		}
		textIconsData = [];
		if (onClose != null) {
			onClose();
		}
	}

	public override function open(?metadata : Array<Dynamic>) trace('ERROR: SpellPopupUI open is deprecated; Use openWith');
	public override function openWith(?options: Dynamic) {
		currentlyOpenSpellName = options.spellName;
		currentlyOpenEntityWithStats = options.entityWithStats;
		reason = options.reason;
		followCursor = options.followCursor != null? options.followCursor : false;
		showCloseButton = options.showCloseButton != null? options.showCloseButton : true;
		callback = options.callback;
		onClose = options.onClose;
		openPopup();
		onOpenWithReason(reason);
	}

	

	function onOpenWithReason(reason) {
		switch (reason) {
			case VIEW:
				actionButton.hide();
			case UNLEARN:
				actionButton.hide();
			default: throw 'Case not handled for open SpellPopupUI!!!';
		}
	}

	function openPopup() {
		function interpolateAtValuesInDescription(originalDescription: String, value: EntityWithStats -> Int -> Int) {
			if (originalDescription.indexOf('@') == -1) {
				return originalDescription;
			}
			final descriptionParts = originalDescription.split('@');
			var finalDescription = '';
			for (i in 0...descriptionParts.length - 1) {	// Ignore the last one
				finalDescription += descriptionParts[i] + (
					if (currentlyOpenEntityWithStats == null) ''
					else value(currentlyOpenEntityWithStats, i) + ' '
				);
			}
			finalDescription += last(descriptionParts);
			return finalDescription;
		}
		function setupDescriptionText() {
			final theSpellTemplate = SpellDatabase.get(currentlyOpenSpellName);
			var desc = interpolateAtValuesInDescription(theSpellTemplate.description, theSpellTemplate.value);

			desc = desc.replace('FIRE', 'FIRE _ ');
			desc = desc.replace('COLD', 'COLD _ ');
			desc = desc.replace('DARK', 'DARK _ ');
			desc = desc.replace('PURE', 'PURE _ ');
			desc = desc.replace('SHOCK', 'SHOCK _ ');

			descriptionTextBox.setText(desc);
		}
		function setupIcons() {
			if (descriptionTextBox == null) {
				throw 'ERROR: Null descriptionTextBox in openPopup!!!';
			}
			textIconsData = [];
			final foundsByLine = allIndexOfAll(descriptionTextBox.lines, ['FIRE', 'COLD', 'DARK', 'PURE', 'SHOCK']);
			if (foundsByLine.length == 0) return;
			final foundsEndFlatWithCoords: Array<{
				lineIndex: Int,
				word: String,
				wordEndIndex: Int,
				xOffset: Float,
				yOffset: Float
			}> = [];
			// Setup the data
			for (foundByLine in foundsByLine) {
				final line = descriptionTextBox.lines[foundByLine.lineIndex];
				for (found in foundByLine.founds) {
					final wordEndIndex = found.index + found.word.length - 1;
					final substringUntilIndex = line.substring(0, wordEndIndex + 1);
					final substringWidth = descriptionTextBox.font.getTextWidth(substringUntilIndex) / Engine.SCALE;

					foundsEndFlatWithCoords.push({
						lineIndex: foundByLine.lineIndex,
						word: found.word,
						wordEndIndex: wordEndIndex,
						xOffset: substringWidth + 2.5,
						yOffset: descriptionTextBox.lineSpacing * foundByLine.lineIndex - descriptionTextBox.getActualHeight() / 2 - 1
					});
				}
			}

			for (elem in foundsEndFlatWithCoords) {
				final image = new ImageX('Icons/Interpolation/${elem.word}.png', 'ItemPopupStatBackgrounds');
				final x = descriptionTextBox.x + elem.xOffset;
				final y = descriptionTextBox.y + elem.yOffset;
				image.setX(x);
				image.setY(y);
				textIconsData.push({
					image: image,
					xOffset: elem.xOffset,
					yOffset: elem.yOffset
				});
			}
		}


		if (showBlackOverlay) {
			overlay.centerOnScreen();
			overlay.show();
		}
		final spell = SpellDatabase.get(currentlyOpenSpellName);
		final iconPath = spell.getIconPath();

		backgroundPanel.show();
		iconFrame.show();
		icon.show();
		icon.changeImage(iconPath);
		descriptionTextBox.startDrawing();
		setupDescriptionText();
		titleTextLine.enable();
		titleTextLine.alignCenter();
		backgroundPanel.centerVertically();
		backgroundPanel.centerHorizontally();

		manaCostFrame.show();
		cooldownFrame.show();
		manaCostText.setText('${spell.manaCost}');
		manaCostText.enable();
		cooldownText.setText('${spell.cooldown}');
		cooldownText.enable();
		
		updatePosition();
		setupIcons();

		titleTextLine.setText(currentlyOpenSpellName);
		actionButton.show();
		if (showCloseButton)
			closeButton.enableActorDrawing();
	}
	public function updatePosition() {
		if (showCloseButton) {
			MiscDatabases.setupCloseButton(closeButton, backgroundPanel);
		}
		actionButton.centerHorizontally();
		actionButton.setBottomFrom(k.other.actionButtonOffsetYFromBottom, backgroundPanel.getYBottom());
		iconFrame.setX(backgroundPanel.getX() + k.icon.offsetX);
		iconFrame.setY(backgroundPanel.getY() + k.icon.offsetY);
		icon.setX(backgroundPanel.getX() + k.icon.offsetX + (ICON_FRAME_SIZE - ICON_SIZE) / 2);
		icon.setY(backgroundPanel.getY() + k.icon.offsetY + (ICON_FRAME_SIZE - ICON_SIZE) / 2);
		titleTextLine.setSceneX(backgroundPanel.getX() + k.title.offsetX);
		titleTextLine.setSceneY(backgroundPanel.getY() + k.title.offsetY);
		final descBoxY = backgroundPanel.getYCenter() + k.descBox.offsetYFromCenter;
		descriptionTextBox.setPosition(backgroundPanel.getX() + k.descBox.offsetX, descBoxY);
		if (textIconsData != null) {
			for (elem in textIconsData) {
				if (elem.image == null) continue;
				elem.image.setX(descriptionTextBox.x + elem.xOffset);
				elem.image.setY(descriptionTextBox.y + elem.yOffset);
			}
		}

		final framesTotalHeight = manaCostFrame.getHeight() + cooldownFrame.getHeight();
		final framesY = backgroundPanel.getY() + (backgroundPanel.getHeight() - framesTotalHeight) / 2;
		manaCostFrame.setX(backgroundPanel.getXRight());
		manaCostFrame.setY(framesY);
		cooldownFrame.setX(backgroundPanel.getXRight());
		cooldownFrame.setY(framesY + manaCostFrame.getHeight());
		final textY = framesY + (manaCostFrame.getHeight() - getFont(SHADED_FONT).getHeight() / Engine.SCALE) / 2;
		manaCostText.setSceneX(manaCostFrame.getXCenter() - 3);
		manaCostText.setSceneY(textY + 1);
		cooldownText.setSceneX(cooldownFrame.getXCenter() - 3);
		cooldownText.setSceneY(textY + manaCostFrame.getHeight() + 1);
	}
	public function setXY(x: Float, y: Float) {
		backgroundPanel.setX(x);
		backgroundPanel.setY(y);
		updatePosition();
	}

	

	function actionButtonClick() {
		if (callback != null) {
			callback(true);
			callback = null;
		}
		GUI.close("SpellPopupUI");
	}

	function closeButtonClick() {
		if (showCloseButton == false) return;
		if (callback != null) {
			callback(false);
		}
		GUI.close("SpellPopupUI");
	}

}
