

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
using U;

import scripts.Constants.*;

class SButton extends SUIButton
{
	public function new(actorTypeName: String, layer: String, text: String) {
        // trace('Creating new SButton with text = ${text}');
        super(actorTypeName, layer, null, { enablePopAnimations: false });
        setText(text, getFont(BROWN_ON_BROWN_TITLE_FONT), BUTTON_TEXT_Y);
        if (Game.isMobile) {
            setupHoverAndClickAnimations({                                  // Same as non-mobile, but without hover animation
                click: { animationName: 'Click', textOffsetYChange: 4 }
            });
        } else {
            setupHoverAndClickAnimations({                                  // Same as mobile, but with the hover animation too
                hover: { animationName: 'Hover', textOffsetYChange: 1 },
                click: { animationName: 'Click', textOffsetYChange: 4 }
            });
        }
        
    }
    public override function hide() {
        if (isShown == false) return;
        isShown = false;
        textImage.kill();
        actor.disableActorDrawing();
        disable();
    }
    public override function show() {
        if (isShown) return;
        isShown = true;
        if (textImage != null) {
            textImage.kill();
        }
        actor.enableActorDrawing();
        setText(text, getFont(BROWN_ON_BROWN_TITLE_FONT), BUTTON_TEXT_Y);
        enable();
    }
}