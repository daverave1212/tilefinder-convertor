

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

// 'PopupUI', [Item, USE/BUY/SELL/LOOT]

class CurrentCharacterIndicatorUIComponent {

	public var currentPlayerCharacterIndex  : Int = -1;
	public var characterIndicatorBackground : Actor;
	public var characterIndicatorIcon		: ImageX;
    public var currentlyOpenReason          : Int;
    
    public var allowClicksOnlyIf            : Void -> Bool;

	public function isOpen() {
		return
			(currentPlayerCharacterIndex != -1) &&
			(characterIndicatorBackground != null && characterIndicatorBackground.isAnimationPlaying()) &&
			(characterIndicatorIcon != null);
	}

	public function new() {
		characterIndicatorBackground = createActor('PopupCharacterIndicatorActor', 'ItemPopup');
		onClick(() -> { characterIndicatorClick(); }, characterIndicatorBackground);
	}

	public function open(y: Float, rightX: Float, ?allowClicksOnlyIf: Void -> Bool) {
		characterIndicatorBackground.enableActorDrawing();
		currentPlayerCharacterIndex = 0;
		final currentPlayerCharacter = Player.characters[currentPlayerCharacterIndex];
		characterIndicatorIcon = new ImageX('Icons/${currentPlayerCharacter.getClassName()}.png', 'ItemPopup');

		final width = characterIndicatorBackground.getWidth();
		characterIndicatorBackground.setX(rightX - width);
		characterIndicatorBackground.setY(y);
		characterIndicatorIcon.setX(rightX - width + 13);
		characterIndicatorIcon.setY(y + 13);
		trace('Opened at ${y}, ${rightX}');
	}
	public function hide() {
		characterIndicatorBackground.disableActorDrawing();
		if (characterIndicatorIcon != null) {
			characterIndicatorIcon.kill();
			characterIndicatorIcon = null;
		}
	}

	function characterIndicatorClick() {
		if (isOpen() == false) return;
        if (allowClicksOnlyIf != null && allowClicksOnlyIf() == false)
            return;
		playAudio('UIGenericClickAudio');
		currentPlayerCharacterIndex++;
		if (currentPlayerCharacterIndex >= Player.characters.length) {
			currentPlayerCharacterIndex = 0;
		}
		final currentPlayerCharacter = Player.characters[currentPlayerCharacterIndex];
		characterIndicatorIcon.changeImage('Icons/${currentPlayerCharacter.getClassName()}.png');
	}
}