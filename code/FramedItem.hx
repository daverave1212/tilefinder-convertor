

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

class FramedItem extends Positionable {

    public var frame:   Actor;
    public var icon:    ImageX;
    public var click:   Void -> Void;
    public var clickWhenDisabled:   Void -> Void;
    public var release: Void -> Void;
    public var imagePath: String;

    public var isEnabled = true;
    var usedLayer: String = 'ERROR: No layer';
    var scale = 1.0;

    public function new(imgPath: String, layer: String, x: Float, y: Float, ?frameAnimation: String, ?scale: Float = 1) {
        usedLayer = layer;
        this.scale = scale;
        frame = createActor('GeneralButtonActor', layer);
        if (frameAnimation != null) frame.setAnimation(frameAnimation);
        frame.setX(x);
        frame.setY(y);
        frame.growTo(scale, scale, 0);  // TO TEST THIS.
        imagePath = imgPath;
        setIcon(imagePath);
        onClick(() -> {
            if (frame == null) return;
            if (isEnabled == false) {
                if (clickWhenDisabled != null) clickWhenDisabled();
                return;
            }
            if (isShown()) {
                playAudio('UIGenericClickAudio');
                if (click != null) {
                    click();
                }
            }
        }, frame);
        onRelease(() -> {
            if (frame == null) return;
            if (isEnabled == false) return;
            if (release != null) release();
        }, frame);
    }
    
    public function kill() {
        if (hasGlow()) {
            stopGlowing();
        }
        if (hasTimer()) {
            hideTimer();
        }
        if (hasMana()) {
            hideMana();
        }
        icon = null;
        if (frame != null) recycleActor(frame);
    }

    public function show() {
        if (frame == null) return;
        frame.enableActorDrawing();
        if (icon == null) return;
        icon.show();
    }
    public function hide() {
        if (hasGlow()) {
            stopGlowing();
        }
        if (hasTimer()) {
            hideTimer();
        }
        if (hasMana()) {
            hideMana();
        }
        if (hasKey()) {
            hideKey();
        }
        if (frame == null) return;
        frame.disableActorDrawing();
        if (icon == null) return;
        icon.hide();
    }
    public function isShown() return frame.isAnimationPlaying();

    public override function setX(newX: Float) frame.setX(newX);
    public override function setY(newY: Float) frame.setY(newY);
    public override function getX(): Float return frame.getX();
    public override function getY(): Float return frame.getY();
    public override function getWidth() return ICON_FRAME_SIZE;
    public override function getHeight() return ICON_FRAME_SIZE;

    public function setFrameAnimation(a: String) {
        if (frame == null) return;
        final shouldDisplayIcon = icon != null && imagePath != null;
        if (shouldDisplayIcon)
            icon.kill();
        frame.setAnimation(a);
        if (shouldDisplayIcon) {
            setIcon(imagePath);
        }
    }

    private function setupIcon(imgPath: String, framePadding: Float, defaultIcon: String) {
        if (frame == null) throwAndLogError('Frame is null; can not set icon!');
        if (isShown() == false) throwAndLogError('FramedItem is hidden; can not set icon!');
        imagePath = imgPath;
        if (icon != null) {
            icon.kill();
        }
        if (imagePath == null) {
            icon = null;
            return;
        }
        if (ImageX.imageExists(imagePath)) {
            icon = new ImageX(imagePath, frame, framePadding, framePadding);
        } else {
            icon = new ImageX(defaultIcon, frame, framePadding, framePadding);
        }
        icon.attachToActor(frame, framePadding, framePadding);
        if (isShown() == false) {
            icon.hide();
        }
    }
    public function setIcon(imgPath: String) {
        final framePadding = (ICON_FRAME_SIZE - ICON_SIZE) * scale / 2 + if (scale == 1.5) -1 else 0;
        setupIcon(imgPath, framePadding, 'Icons/NotFound.png');
    }

    public function disableAndMarkAsGrayed() {
        isEnabled = false;
        if (icon == null) return;
        icon.grayOut();
        icon.setAlpha(0.5);
    }
    public function enableAndUnmarkAsGrayed() {
        isEnabled = true;
        if (icon == null) return;
        icon.removeAllEffects();
        icon.setAlpha(1);
    }

    public function anchorToScreen() {
        frame.anchorToScreen();
    }
    public function enablePopAnimation() {
        function onlyIfIsEnabled(event: String) {
            return if (isEnabled) true else false;
        }
        SpecialEffectsFluff.addPopBehaviorToActor(frame, scale, onlyIfIsEnabled);
    }

    public function addFrameAttachment(i: ImageX) {
        final offset = - 8 * scale - (if (scale == 1) 1 else 0);
        // final offset = ((ICON_FRAME_SIZE - 128) / 2) * scale + scale;
        i.attachToActor(frame, offset, offset);
    }


    // Glow
    function hasGlow() return glow1 != null;
    var glow1: ImageX;
    var glow2: ImageX;
    var isGlowStarted = false;
    var lastGlowRarity = -1;
    public function startGlowingByRarity(rarity: Int) {
        lastGlowRarity = rarity;
        glow1 = getRarityImageGlow1(rarity);
        if (glow1 == null) return;
        glow2 = getRarityImageGlow2(rarity);
        glow1.fadeTo(0.25, 0);
        addFrameAttachment(glow1);
        addFrameAttachment(glow2);
        glow1.growTo(0.25, 0.25, 0);
        glow2.growTo(0.25, 0.25, 0);
        glow1.fadeTo(0.9, 1);
        glow2.fadeTo(0.25, 1);
        if (isGlowStarted == false) {
            doEvery(2000, function() {
                if (hasGlow() == false) return;
                glow1.fadeTo(0.25, 1);
                glow2.fadeTo(0.9, 1);
                doAfter(1000, function() {
                    if (hasGlow() == false) return;
                    glow1.fadeTo(0.9, 1);
                    glow2.fadeTo(0.25, 1);
                });
            });
        }
        isGlowStarted = true;
    }
    public function stopGlowing() {
        if (hasGlow()) {
            glow1.kill();
            glow2.kill();
            glow1 = null;
            glow2 = null;
        }
    }
	

    // Timer
    var timerFrame: Actor;
    var timerTextImage: ImageX;
    public function hasTimer() return timerFrame != null;
    public function showTimer(text: String, showTick: Bool) {
        if (timerTextImage != null) {
            timerTextImage.kill();
        }
        if (timerFrame != null) {
            recycleActor(timerFrame);
        }
        timerFrame = createActor('SpellTimerFrameActor', 'UIOverlay');
        timerFrame.setX(frame.getX() + frame.getWidth() - timerFrame.getWidth() + 2);
        timerFrame.setY(frame.getY() + frame.getHeight() - timerFrame.getHeight() + 2);
        timerFrame.setAnimation('Ticking');
        if (showTick) {
            timerFrame.setAnimation('Ticking');
        } else {
            timerFrame.setAnimation('Normal');
        }
        timerTextImage = createTextToImageX(text, getFont(SHADED_FONT));
        timerTextImage.attachToActor(
            timerFrame,
            (timerFrame.getWidth() - timerTextImage.getWidth()) / 2,
            (timerFrame.getHeight() - timerTextImage.getHeight()) / 2 + 2
        );
    }
    public function hideTimer() {
        if (timerTextImage != null) {
            timerTextImage.kill();
        }
        if (timerFrame != null) {
            recycleActor(timerFrame);
        }
        timerTextImage = null;
        timerFrame = null;
    }

    // Mana
    var manaFrame: ImageX;
    var manaTextImage: ImageX;
    public function hasMana() return manaFrame != null;
    public function showMana(text: String) {
        if (manaTextImage != null) {
            manaTextImage.kill();
        }
        if (manaFrame != null) {
            manaFrame.kill();
        }
        manaFrame = new ImageX('UI/SpellManaFrame.png', 'UIOverlay');
        manaFrame.attachToActor(frame, -2, -2);
        manaTextImage = createTextToImageX(text, getFont(SHADED_FONT));
        manaTextImage.attachToActor(
            frame,
            (manaFrame.getWidth() - manaTextImage.getWidth()) / 2 + 1 - 3,
            (manaFrame.getHeight() - manaTextImage.getHeight()) / 2 + 2 - 2
        );
    }
    public function hideMana() {
        if (manaTextImage != null) {
            manaTextImage.kill();
        }
        if (manaFrame != null) {
            manaFrame.kill();
        }
        manaTextImage = null;
        manaFrame = null;
    }


    // Key
    var keyFrame: ImageX;
    var keyTextImage: ImageX;
    public function hasKey() return keyFrame != null;
    public function showKey(text: String) {
        if (Game.isMobile) return;
        FramedItem.doShowKeyFunctionality({
            keyFrame: keyFrame,
            keyTextImage: keyTextImage,
            frame: frame,
            text: text,
            setKeyFrame: (newValue) -> keyFrame = newValue,
            setKeyTextImage: (newValue) -> keyTextImage = newValue
        });
    }
    public function hideKey() {
        if (Game.isMobile) return;
        FramedItem.doHideKeyFunctionality({
            keyFrame: keyFrame,
            keyTextImage: keyTextImage,
            setKeyFrame: (newValue) -> keyFrame = newValue,
            setKeyTextImage: (newValue) -> keyTextImage = newValue
        });
    }


    // For generic purposes
    public static function doShowKeyFunctionality(options: {
        keyFrame: ImageX,
        keyTextImage: ImageX,
        frame: Actor,
        text: String,
        setKeyFrame: ImageX -> Void,
        setKeyTextImage: ImageX -> Void
    }) {
        if (Game.isMobile) return;
        if (options.keyTextImage != null) {
            options.keyTextImage.kill();
        }
        if (options.keyFrame != null) {
            options.keyFrame.kill();
        }
        final newKeyFrame = new ImageX('UI/KeyFrame.png', 'UIOverlay'); 
        options.setKeyFrame(newKeyFrame);
        newKeyFrame.attachToActor(
            options.frame,
            options.frame.getWidth() / 2 - newKeyFrame.getWidth() / 2,
            options.frame.getHeight() / 2 - newKeyFrame.getHeight() / 2
        );
        final newKeyTextImage = createTextToImageX(options.text, getFont(SHADED_FONT));
        options.setKeyTextImage(newKeyTextImage);
        newKeyTextImage.attachToActor(
            options.frame,
            options.frame.getWidth() / 2 - newKeyTextImage.getWidth() / 2 + 0.5,
            options.frame.getHeight() / 2 - newKeyTextImage.getHeight() / 2
        );
    }
    public static function doHideKeyFunctionality(options: {
        keyFrame: ImageX,
        keyTextImage: ImageX,
        setKeyFrame: ImageX -> Void,
        setKeyTextImage: ImageX -> Void
    }) {
        if (Game.isMobile) return;
        if (options.keyTextImage != null) {
            options.keyTextImage.kill();
        }
        if (options.keyFrame != null) {
            options.keyFrame.kill();
        }
        options.setKeyFrame(null);
        options.setKeyTextImage(null);
    }
}