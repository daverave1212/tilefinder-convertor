

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

class Popup_BuffBox {
	
	public var background: ImageX;
	public var textLine: TextLine;
	public var icon: ImageX;
	public var isDead = false;

	public function new(buff: Buff) {
		background = new ImageX(MonsterPopupUI.buffBackgroundBMP, 'ItemPopup');
		icon = new ImageX('Icons/Buffs/${buff.name}.png', 'ItemPopup');
		textLine = new TextLine(buff.name + ' (${buff.remainingDuration})', getFont(BROWN_ON_BROWN_TITLE_FONT));
	}
	public function setXY(x: Float, y: Float) {
		if (isDead) return;
		background.setX(x); background.setY(y);
		final iconPadding = (background.getHeight() - icon.getHeight()) / 2;
		icon.setX(x + iconPadding); icon.setY(y + iconPadding);
		textLine.setSceneX(icon.getX() + icon.getWidth() + iconPadding);
		textLine.setSceneY(y + 1);
	}
	public function kill() {
		isDead = true;
		background.kill();
		icon.kill();
		textLine.disable();
	}
}

class MonsterPopupUI {
	
	public static var buffBackgroundBMP: BitmapData;

	public var backgroundPanel : PanelVerticable;
	public var titleTextLine : TextLine;
	public var descriptionTextBox : TextBox;
	public var isShown = true;
	public var buffBoxes: Array<Popup_BuffBox>;
	
	public function new() {
		// backgroundPanel = new ImageX('UI/MonsterPopupBackground.png', 'ItemPopup');
		backgroundPanel = new PanelVerticable(
			getExternalImage('UI/MonsterPopupBackgroundTop.png'),
			getExternalImage('UI/MonsterPopupBackgroundMiddle.png'),
			getExternalImage('UI/MonsterPopupBackgroundBottom.png'),
			'ItemPopup'
		);
		titleTextLine = new TextLine(' ', getFont(BROWN_ON_BROWN_TITLE_FONT), 0, 0);
		titleTextLine.alignCenter();
		descriptionTextBox = new TextBox(104, 50, 0, 0, PopupUI.flavorFont);
		descriptionTextBox.centerHorizontally = true;
		descriptionTextBox.centerVertically = true;
		descriptionTextBox.lineSpacing = 8;

		buffBackgroundBMP = getExternalImage('UI/StatBackgrounds/Any.png');
		buffBoxes = [];
	}

	public function open(options: {
		name: String,
		description: String,
		initialX: Float,						// Initial x, at least
		initialY: Float,
		?buffs: Array<Buff>
	}) {
		trace('Opening with options: ${options.name}, ${options.description}, ${options.initialX}, ${options.initialY}');
		if (isShown) {
			close();
		}
		titleTextLine.enable();
		titleTextLine.setText(options.name);
		descriptionTextBox.startDrawing();
		descriptionTextBox.setText(options.description);
		final totalHeight = int(descriptionTextBox.nLines * descriptionTextBox.lineSpacing);
		backgroundPanel.show();
		backgroundPanel.setMiddleHeight(totalHeight);
		isShown = true;

		// Setup buffs
		buffBoxes = [];
		if (options.buffs != null) {
			buffBoxes = options.buffs.map(buff -> new Popup_BuffBox(buff));
		}

		setXY(options.initialX, options.initialY);
	}

	public function close() {
		if (isShown == false) return;
		backgroundPanel.hide();
		titleTextLine.disable();
		descriptionTextBox.stopDrawing();
		for (buffBox in buffBoxes) buffBox.kill();
		isShown = false;
	}

	public function setXY(x: Float, y: Float) {
		if (isShown == false) return;
		backgroundPanel.setX(x);
		backgroundPanel.setY(y);
		titleTextLine.setSceneX(backgroundPanel.getXCenter());
		titleTextLine.setSceneY(backgroundPanel.getY() + 17);
		descriptionTextBox.setPosition(backgroundPanel.getXCenter(), backgroundPanel.imageMiddle.getYCenter());

		if (buffBoxes == null || buffBoxes.length == 0) return;
		final buffPaddingHori = 2;
		final buffPaddingVert = 2;
		final buffHeight = buffBoxes[0].background.getHeight();
		final buffWidth = buffBoxes[0].background.getWidth();
		final totalHeight = (buffBoxes.length * buffHeight) + (buffBoxes.length - 1) * buffPaddingVert;
		// final buffsY = (getHeight() - totalHeight) / 2;
		final buffsY = y + 4;
		final buffsX =
			if (x < getScreenXCenter())
				backgroundPanel.getX() + backgroundPanel.getWidth() + buffPaddingHori
			else
				(backgroundPanel.getX() - buffPaddingHori - buffWidth);
		for (i in 0...buffBoxes.length) {
			final buffBox = buffBoxes[i];
			buffBox.setXY(buffsX, buffsY + i * (buffHeight + buffPaddingVert));
		}
	}

	public inline function getHeight() return backgroundPanel.getHeight();
	public inline function getWidth() return backgroundPanel.getWidth();
}