
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



class UIRange extends Positionable
{
	
    public static var k = {
        padding: 3,
        descriptorBGOffsetX: 5,
        descriptorBGOffsetY: 3,
        valueTextBGOffsetX: 122
    }

    public var minValue: Int;
    public var maxValue: Int;
    public var value: Int;
    public var step: Int;

    public var onUpdate: Int -> Int -> String;

    public var background: ImageX;
    public var leftArrow: Actor;
    public var rightArrow: Actor;

    public var descriptor: TextLine;
    public var valueText: TextLine;

    public var isEnabled = true;

    public function new(options: {
        description: String,
        x: Float,
        y: Float,
        minValue: Int,
        maxValue: Int,
        value: Int,
        step: Int,
        onUpdate: Int -> Int -> String     // newValue -> new valueText
    }) {
        minValue = options.minValue;
        maxValue = options.maxValue;
        value = options.value;
        step = options.step;
        onUpdate = options.onUpdate;

        leftArrow = createActor('ArrowActor', 'MenuComponentsLayer');
        leftArrow.setAnimation('RangeArrowLeft');
        rightArrow = createActor('ArrowActor', 'MenuComponentsLayer');
        rightArrow.setAnimation('RangeArrowRight');
        background = new ImageX('UI/MenuOptionBackground.png', 'MenuComponentsLayer');
        descriptor = new TextLine(options.description, getFont(BROWN_ON_BROWN_TITLE_FONT));
        valueText  = new TextLine('', getFont(STAT_NUMBER_FONT));
        valueText.alignLeft();

        setX(options.x);
        setY(options.y);

        onRelease(() -> {
            if (!isEnabled) return;
            playAudio('UIGenericClickAudio');
            final oldValue = value;
            value = int(max(minValue, value - step));
            valueText.setText(onUpdate(oldValue, value));
        }, leftArrow);
        onRelease(() -> {
            if (!isEnabled) return;
            playAudio('UIGenericClickAudio');
            final oldValue = value;
            value = int(min(maxValue, value + step));
            valueText.setText(onUpdate(oldValue, value));
        }, rightArrow);

        valueText.setText(onUpdate(options.value, options.value));
    }

    public override function getX() return leftArrow.getX();
    public override function getY() return leftArrow.getY();
    public override function setX(x: Float) {
        x += 1; // For alignment
        leftArrow.setX(x);
        background.setX(x + leftArrow.getWidth() + k.padding);
        rightArrow.setX(background.getX() + background.getWidth() + k.padding);
        descriptor.setSceneX(background.getX() + k.descriptorBGOffsetX);
        valueText.setSceneX(background.getX() + k.valueTextBGOffsetX);

    }
    public override function setY(y: Float) {
        leftArrow.setY(y + 1);
        background.setY(y);
        rightArrow.setY(y + 1);
        descriptor.setSceneY(background.getY() + k.descriptorBGOffsetY);
        valueText.setSceneY(background.getY() + k.descriptorBGOffsetY - 1);
    }
    public function hide() {
        leftArrow.disableActorDrawing();
        rightArrow.disableActorDrawing();
        background.hide();
        descriptor.disable();
        valueText.disable();
        isEnabled = false;
    }
    public function show() {
        leftArrow.enableActorDrawing();
        rightArrow.enableActorDrawing();
        background.show();
        descriptor.enable();
        valueText.enable();
        isEnabled = true;
    }

    public override function getWidth() return leftArrow.getWidth() + k.padding + background.getWidth() + k.padding + rightArrow.getWidth();
    public override function getHeight() return leftArrow.getHeight();

    public function disable() {
        isEnabled = false;
		leftArrow.setFilter([createSaturationFilter(0)]);
		rightArrow.setFilter([createSaturationFilter(0)]);
    }
    public function enable() {
        isEnabled = true;
		leftArrow.clearFilters();
		rightArrow.clearFilters();
    }

}