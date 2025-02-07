


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
import U.doAfter;
using U;

import scripts.Constants.*;
import scripts.SpecialEffectsFluff.sayAlert;
import scripts.SpecialEffectsFluff.sayBubble;
import Std.int;

class FakeLoadingScreen
{

    static var callback: Void -> Void;

    public static function start() {
        engine.moveCamera(getSceneWidth() / 2, getSceneHeight() / 2);
        final hints = [
            'If you use an INFECTED ability, you will take damage!',
            "You can't equip the same item or spell twice on the same character.",
            "Enemies signal before casting a ROOT spell! Look for the icon on them!",
            "When targeted directly by a Highwayman, hide behind an obstacle!",
            "Defeating a boss unlocks extra encounters and items on future runs!",
            "ANIMALS include slimes, beholders, spiders, insects and dragons. ",
            "Hold Q to inspect units and traps.",
            "Actually waiting 99 turns for a 99 cooldown spell is cheating!",
            "Some enemies surrender when they are alone, and drop to 1 HP.",
            "If a character dies (but not both), it revives with 20% max HP."
        ];
        final hint: String = randomOf(hints);
        final font = getFont(FAKE_LOADING_SCREEN_FONT);
        final textLine = new TextLine(hint, font);
        textLine.setSceneX(getScreenX() + getScreenWidth() / 2);
        textLine.setSceneY(getScreenY() + getScreenHeight() - font.getHeight() / Engine.SCALE - 15);
        textLine.alignCenter();
        textLine.setText(hint);
        textLine.enable();
        final delay = 2000 + int(hint.length / 2 * 100);
        doAfter(delay, () -> {
            callback();
        });
    }

    public static function goToFakeLoadingScreenAndThen(andThen: Void -> Void) {
        callback = andThen;
        changeScene('FakeLoadingScreenScene');
    }

}