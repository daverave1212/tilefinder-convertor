
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
import scripts.Constants.*;

import Std.int;
import Math.min;
import Math.max;

using U;

class UICheckbox extends Positionable {

    public static var k = {
        padding: 2,
        descriptorBGOffsetX: 5,
        descriptorBGOffsetY: 3
    }

    public var checkboxActor: Actor;
    public var isTicked = false;
    
    public var isEnabled = true;

    public var onUpdate: Bool -> Void;

    public var background: ImageX;
    public var descriptor: TextLine;

    public function new(options: {
        description: String,
        x: Float,
        y: Float,
        value: Bool,
        onUpdate: Bool -> Void      // newValue -> Void
    }) {
        isTicked = options.value;
        onUpdate = options.onUpdate;

        checkboxActor = createActor('CheckboxActor', 'MenuComponentsLayer');
        background = new ImageX('UI/MenuOptionBackground.png', 'MenuComponentsLayer');
        descriptor = new TextLine(options.description, getFont(BROWN_ON_BROWN_TITLE_FONT));

        setX(options.x);
        setY(options.y);

        onRelease(() -> {
            if (checkboxActor == null || checkboxActor.isAnimationPlaying() == false) return;
            if (isEnabled == false) return;
            playAudio('UIGenericClickAudio');
            isTicked = !isTicked;
            checkboxActor.setAnimation(if (isTicked) 'Checked' else 'Unchecked');
            onUpdate(isTicked);
        }, checkboxActor);

        checkboxActor.setAnimation(if (isTicked) 'Checked' else 'Unchecked');
    }

    public override function setX(x: Float) {
        checkboxActor.setX(x);
        background.setX(x + checkboxActor.getWidth() + k.padding);
        descriptor.setSceneX(background.getX() + k.descriptorBGOffsetX);
    }
    public override function setY(y: Float) {
        checkboxActor.setY(y);
        background.setY(y);
        descriptor.setSceneY(background.getY() + k.descriptorBGOffsetY);
    }
    public function setDescriptionX(x: Float) {
        background.setX(x);
        descriptor.setSceneX(background.getX() + k.descriptorBGOffsetX);
    }
    public override function getWidth() return checkboxActor.getWidth() + k.padding + background.getWidth();
    public override function getHeight() return checkboxActor.getHeight();

    public function hide() {
        checkboxActor.disableActorDrawing();
        background.hide();
        descriptor.disable();
    }
    public function show() {
        checkboxActor.enableActorDrawing();
        background.show();
        descriptor.enable();
    }
    public function disable() {
        checkboxActor.setFilter([createSaturationFilter(0)]);
        isEnabled = false;
    }
    public function enable() {
        checkboxActor.clearFilters();
        isEnabled = true;
    }

}
