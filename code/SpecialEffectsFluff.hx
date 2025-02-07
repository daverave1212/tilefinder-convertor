
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
import Std.*;

import scripts.Constants.*;


// This script exists for extra visual fluff for SpecialEffectActor and SlashActor
// Some of their opacity/other things are hardcoded here based on their animation name
class SpecialEffectsFluff {

    public static var k = {
        anchorWidth: 25
    }


    // Missile, Effect, Slash
    public static function doEvery50Miliseconds(actor : Actor) {
        var animation = actor.getAnimation();
        switch (animation) {
            case 'Hit', 'SlashForward', 'SlashForwardBig', 'Thrust':
                actor.alpha = actor.alpha - 0.04;
            case 'Anchor':
                if (anchor_chainActor == null || anchor_origin == null) {
                    return;
                }
                final angle = angleBetweenPoints(actor.getXCenter(), actor.getYCenter(), anchor_origin.x, anchor_origin.y);
                final width = distanceBetweenPoints(actor.getXCenter(), actor.getYCenter(), anchor_origin.x, anchor_origin.y);
                final middlePoint = getMiddlePoint(actor.getXCenter(), actor.getYCenter(), anchor_origin.x, anchor_origin.y);
                final xScale = width / k.anchorWidth;
                anchor_chainActor.setXCenter(middlePoint.x);
                anchor_chainActor.setYCenter(middlePoint.y);
                anchor_chainActor.setAngle(Utils.RAD * angle);
                anchor_chainActor.growTo(xScale, 1, 0.04, Easing.linear);

        }
    }

    // Effect, Slash, Attachment
	public static function do100MilisecondsAfterEffectActorCreated(actor : Actor) {
        function doHardcodedEffectFluff(actor : Actor) {
            function rotateThrust() {
                final areRelativelyEqual = (a: Float, b: Float) -> Math.abs(a - b) <= 20;
                final fromX: Float = cast actor.getActorValue('fromX');
                final fromY: Float = cast actor.getActorValue('fromY');
                final toX: Float   = cast actor.getActorValue('toX');
                final toY: Float   = cast actor.getActorValue('toY');
                final from = new Point(fromX, fromY);
                final to   = new Point(toX, toY);
                final setAngle = (ang) -> actor.setAngle(Utils.RAD * ang);
                if (areRelativelyEqual(from.x, to.x)) { // Maybe vertical...
                    if (areRelativelyEqual(from.y, to.y)) { // Do nothing
                        return;
                    } else if (to.y < from.y) { // Oriented up
                        setAngle(270);
                    } else if (to.y > from.y) { // Oriented down
                        setAngle(90);
                    }
                } else if (areRelativelyEqual(from.y, to.y)) {
                    if (from.x < to.x) {
                        setAngle(0);
                    } else if (from.x > to.x) {
                        setAngle(180);
                    }
                } else {
                    if (to.y < from.y && to.x > from.x) {           // Up-right
                        setAngle(315);
                    } else if (to.y > from.y && to.x > from.x) {    // Down-right
                        setAngle(45);
                    } else if (to.y > from.y && to.x < from.x) {    // Down-left
                        setAngle(135);
                    } else if (to.y < from.y && to.x < from.x) {    // Up-left
                        setAngle(225);
                    }
                }
            }
            var animation = actor.getAnimation();
            switch (animation) {
                case 'Hit':
                    var angle = randomInt(-25, 25);
                    actor.setAngle(Utils.RAD * angle);
                case 'SlashForwardBig':
                    var isFlippedHorizontally : Bool = actor.getActorValue('isFlippedHorizontally') == true;
                    if (isFlippedHorizontally)
                        actor.growTo(-1.5, 1.5, 0, Easing.linear);
                    else
                        actor.growTo(1.5, 1.5, 0, Easing.linear);
                case 'Thrust':
                    rotateThrust();
                case 'Block', 'Big Block':
                    actor.setY(actor.getY() - 30);
                    actor.growTo(1.3, 0.7, 0.5, Easing.expoOut);
                    doAfter(500, () -> {
                        actor.growTo(0, 1.25, 1, Easing.expoIn);
                    });
                case "Crow's Blessing", 'Skull':
                    actor.growTo(0, 0, 0, Easing.linear);
                    actor.moveTo(actor.getX(), actor.getY() - 20, 0.75, Easing.expoOut);
                    actor.growTo(1.3, 1.3, 0.75, Easing.expoOut);
                    doAfter(750, () -> {
                        actor.growTo(0, 0, 0.5, Easing.expoIn);
                        actor.moveTo(actor.getX(), actor.getY() - 20, 0.5, Easing.expoIn);
                    });
                case 'Damned Aura Cast':
                    actor.setY(actor.getY() + 15);
                    actor.growTo(0.5, 0.5, 0, Easing.linear);
                    actor.growTo(1.7, 1.7, 1.25, Easing.expoOut);
                    actor.fadeTo(0, 1.25, Easing.expoOut);
                case 'Silence', 'Time Warp':
                    actor.growTo(1.7, 1.7, 1.25, Easing.expoOut);
                    actor.fadeTo(0, 1.25, Easing.expoOut);
                case 'Circular Fire':
                    actor.growTo(1.5, 1.5, 0.5, Easing.linear);
                    actor.fadeTo(0, 0.9, Easing.expoIn);
                case 'Unholy Revival':
                    actor.growTo(2, 2, 0, Easing.linear);
                case 'Condemnation':
                    actor.growTo(1.5, 1.5, 0, Easing.linear);
                case 'Smite':
                    actor.growTo(2, 2, 1.5, Easing.linear);
                    actor.fadeTo(0, 1.5, Easing.linear);
                case 'Freeze':
                    doAfter(375, () -> {
                        actor.fadeTo(0, 0.5, Easing.expoIn);
                    });
                case 'Chomp':
                    actor.growTo(0.5, 0.5, 0, Easing.linear);
                    doAfter(10, () -> {
                        actor.growTo(1, 1, 0.25, Easing.expoOut);
                    });
                    doAfter(550, () -> {
                        actor.growTo(1.5, 1.5, 0.5, Easing.linear);
                        actor.fadeTo(0, 0.5, Easing.linear);
                    });
                case 'Stunned', 'Silenced', 'Rooted', 'Has Net', 'Fearful':
                    var isFading = true;
                    doEvery(500, function(): Void {
                        if (actor == null) return;
                        if (isFading) {
                            actor.fadeTo(0, 0.5, Easing.linear);
                        } else {
                            actor.fadeTo(1, 0.5, Easing.linear);
                        }
                        isFading = !isFading;
                    }, actor);
                case 'Spike Rush':
                    actor.setY(actor.getY() - 5);
            }
        }
        function doBattlefieldParticles(actor : Actor) {
            var animation = actor.getAnimation();
            var particle = EffectParticleDatabase.get(animation);
            Battlefield.effectParticleSpawner.setFromDynamic(particle);
            Battlefield.effectParticleSpawner.setX(actor.getXCenter());
            Battlefield.effectParticleSpawner.setY(actor.getYCenter());
            var myDirection : String = actor.getActorValue('direction');
            switch (myDirection) {
                case 'right', 'no-direction', null:   Battlefield.effectParticleSpawner.direction += 0;
                case 'up':
                    Battlefield.effectParticleSpawner.direction = 90;
                case 'left':
                    Battlefield.effectParticleSpawner.direction = 180 - Battlefield.effectParticleSpawner.direction;
                case 'down':
                    Battlefield.effectParticleSpawner.direction = 270;
                default:
                    throwAndLogError('ERROR: No case for direction $myDirection');
            }
            if (Battlefield.effectParticleSpawner == null || getCurrentSceneName() != 'BattlefieldScene') {
                throwAndLogError('ERROR in doParticles: Battlefield.effectParticleSpawner is null or not in BattlefieldScene');
                return;
            }
            Battlefield.effectParticleSpawner.burst(15);
        }
        function doNonCombatEventsParticles(actor: Actor) {
            var animation = actor.getAnimation();
            var particle = EffectParticleDatabase.get(animation);
            NonCombatEvents.effectParticleSpawner.setFromDynamic(particle);
            NonCombatEvents.effectParticleSpawner.setX(actor.getXCenter());
            NonCombatEvents.effectParticleSpawner.setY(actor.getYCenter());
            NonCombatEvents.effectParticleSpawner.burst(15);
        }
        doHardcodedEffectFluff(actor);
        if (EffectParticleDatabase.exists(actor.getAnimation())) {
            if (getCurrentSceneName() == 'NonCombatEventsScene') {
                doNonCombatEventsParticles(actor);
            } else if (getCurrentSceneName() == 'BattlefieldScene') {
                doBattlefieldParticles(actor);
            }
        }
    }


    static var anchor_chainActor: Actor;
    static var anchor_origin: Point;            // These variables are only used for the Anchor missile
    // Missile
    public static function do100MilisecondsAfterMissileActorCreated(actor: Actor) {
        var animation = actor.getAnimation();
        switch (animation) {
            case 'Molotov', 'Rock', 'Disorient':
                actor.spinBy(2160, 2.25, Easing.linear);
            case 'Anchor':
                anchor_chainActor = createActor('LightningEffectActor', 'Particles');
                anchor_chainActor.setAnimation('AnchorChain');
                anchor_origin = new Point(actor.getXCenter(), actor.getYCenter());
                anchor_chainActor.setX(anchor_origin.x);
                anchor_chainActor.setY(anchor_origin.y);
            case 'Tidal Wave', 'Fire Ball':
                final isFlipped: Bool = cast actor.getActorValue('isFlipped');
                if (isFlipped == true) {    // To make sure it's not null
                    actor.growTo(-2, 2, 2.25, Easing.linear);
                } else {
                    actor.growTo(2, 2, 2.25, Easing.linear);
                }
            case 'Spear':
                final isFlipped: Bool = cast actor.getActorValue('isFlipped');
                actor.setAngle(-120 * Utils.RAD);
                actor.spinBy(-120, 1, Easing.linear);
            case 'Giant Spoon':
                actor.setAngle(randomIntBetween(0, 180) * Utils.RAD);
                actor.spinBy(270, 2, Easing.linear);

        }
    }
    public static function doWhenMissileActorDies(actor: Actor) {
        switch (actor.getAnimation()) {
            case 'Anchor':
                if (anchor_chainActor != null) {
                    recycleActor(anchor_chainActor);
                }
                anchor_origin = null;
        }
    }


    // Other
    public static function doExplosionEffect(x: Float, y: Float, animationName: String = 'Explosion'): Actor {
        final point = new Point(x, y);
        playAudio('ExplosionAudio');
        return Effects.playParticleAndThen(point, point, animationName, 800);
    }

    public static function doPortalAnimation(actor: Actor) {
        actor.growTo(0, 0, 0, Easing.linear);
        doAfter(10, () -> {
            actor.growTo(1.15, 0.85, 0.95, Easing.quadOut);
        });
        var isWidening = false;
        doEvery(950, () -> {
            if (isWidening) {
                actor.growTo(1.15, 0.85, 0.95, Easing.quadOut);
                isWidening = false;
            } else {
                actor.growTo(0.85, 1.15, 0.95, Easing.quadOut);
                isWidening = true;
            }
        });
    }
    public static function doChestJumpAnimation(actor: Actor) {
        function moveByAndThen(x, y, time, easing, ?andThen) {
            actor.moveBy(x, y, time, easing);
            if (andThen != null) doAfter(time * 1000, andThen);
        }
        function spinByAndThen(degrees, time, easing, ?andThen) {
            actor.spinBy(degrees, time, easing);
            if (andThen != null) doAfter(time * 1000, andThen);
        }
        final bigJumpTime = 0.2;    // Seconds
        final smallJumpTime = bigJumpTime / 2;
        final xMove = 10;
        final yMove = -15;
        final yMoveSmall = int(yMove / 2);
        final spinDegrees = 15;
        final actorPoint = new Point(actor.getXCenter(), actor.getY() + actor.getHeight() - 28);
        Effects.playParticleAndThen(actorPoint, actorPoint, 'Chest Particles', 150, () -> {});
        function doBigJump(andThen) {
            spinByAndThen(spinDegrees, bigJumpTime * 0.75, Easing.quadOut, () -> {
                spinByAndThen(-spinDegrees * 0.75, bigJumpTime * 0.75, Easing.linear);
            });
            moveByAndThen(xMove, yMove, bigJumpTime, Easing.quadOut, () -> {
                moveByAndThen(0, -yMove, bigJumpTime, Easing.linear, () -> {
                    andThen();
                });
            });
        }
        function doSmallJump() {
            Effects.playParticleAndThen(actorPoint, actorPoint, 'Chest Particles', 150);
            spinByAndThen(-spinDegrees * 0.75, bigJumpTime * 0.75, Easing.quadOut, () -> {
                spinByAndThen(spinDegrees * 0.5, bigJumpTime * 0.75, Easing.linear);
            });
            moveByAndThen(-xMove, yMoveSmall, bigJumpTime, Easing.quadOut, () -> {
                moveByAndThen(0, -yMoveSmall, bigJumpTime, Easing.quadIn);
            });
        }

        doBigJump(() -> doSmallJump());
    }
    public static function doChestDisappearAnimation(chest: Actor, andThen: Void -> Void) {
        var portal = createActor('ChestPortalActor', chest.getLayerName());
        chest.moveToTop();
        var portalCenterPos = new Point(chest.getXCenter() + 25, chest.getYCenter() - 25);
        portal.setXCenter(portalCenterPos.x);
        portal.setYCenter(portalCenterPos.y);
        Effects.playParticleAndThen(portalCenterPos, portalCenterPos, 'Chest Particles', 150);
        doAfter(1000, () -> {
            Effects.playParticleAndThen(portalCenterPos, portalCenterPos, 'Chest Particles', 150);
            chest.spinBy(1080, 2, Easing.quadIn);
            chest.moveTo(portal.getX(), portal.getY(), 2, Easing.linear);
            chest.growTo(0, 0, 2, Easing.quadIn);
            doAfter(2000, () -> {
                Effects.playParticleAndThen(portalCenterPos, portalCenterPos, 'Chest Particles', 150);
                portal.setActorValue('isPlayingAnimation', false);
                portal.growTo(0, 1, 0.5, Easing.quadIn);
                doAfter(500, () -> {
                    Effects.playParticleAndThen(portalCenterPos, portalCenterPos, 'Chest Particles', 150);
                    recycleActor(portal);
                    andThen();
                });
            });
        });
    }
    public static function doItemToInventoryAnimation(iconPath: String, x: Float, y: Float, ?isOnBackground = true) {
        final image = new ImageX(iconPath);
        final background = createActor('GeneralButtonActor', 'UI');
        if (isOnBackground == false) {
            background.setAnimation('Invisible');
        }
        final padding = (ICON_FRAME_SIZE - image.getWidth()) / 2;
        image.attachToActor(background, padding, padding);
        background.setX(x); background.setY(y);
        final finalX = getScreenX() + getScreenWidth() - ICON_FRAME_SIZE - 12;
        final finalY = getScreenY() + getScreenHeight() - ICON_FRAME_SIZE - 12;
        background.moveTo(x, y - 20, 1, Easing.expoOut);
        doAfter(800, () -> {
            background.moveTo(finalX, finalY, 1, Easing.expoOut);
            doAfter(1000, () -> {
                image.kill();
                recycleActor(background);
            });
        });
        return background;
    }
    public static function doChainEffectBetweenUnits(animationName: String, duration: Int, fromUnit: Unit, toUnit: Unit) {
        final chain = createActor('SpecialEffectActor', 'Particles');
        chain.setAnimation(animationName);
        final from = fromUnit.tileOn.getCenterPointForMissile();
        final to = toUnit.tileOn.getCenterPointForMissile();
        stretchActorBetweenPoints(chain, from.x, from.y, to.x, to.y);
        doAfterSafe(duration, () -> {
            recycleActor(chain);
        });
    }
    public static function doFlinchAnimation(actor: Actor, ?andThen: Void -> Void = null) {
		slideActorX(actor, actor.getX(), actor.getX() + 20, 600);
		slideActorYCubic(actor, actor.getY(), actor.getY() - 20, 350);
		actor.spinBy(95, 0.6, Easing.quadOut);
		doAfter(350, () -> {
			slideActorYCubic(actor, actor.getY(), actor.getY() + 55, 350, true);
			doAfter(550, () -> {
				final actorCenter = new Point(actor.getXCenter() - 20, actor.getYCenter());
                if (getCurrentSceneName() == 'BattlefieldScene')
				    Effects.playParticleAndThen(actorCenter, actorCenter, 'Smoke', 150, () -> {});
				if (andThen != null) andThen();
			});
		});
	}
    public static function doActorDropInAnimation(actor: Actor, ?andThen: Void -> Void) {
        final originalY = actor.getY();
        final originalHeight = actor.getHeight();
        actor.growTo(0.8, 1.2, 0, Easing.linear);
        actor.setY(originalY - originalHeight * 0.1);
        trace('Dropping in...');
        doAfter(10, () -> {
            actor.growTo(1.2, 0.8, 0.35, Easing.expoOut);
            actor.moveTo(actor.getX(), originalY + originalHeight * 0.1, 0.35, Easing.expoOut);
            doAfter(350, () -> {
                actor.growTo(1, 1, 0.25, Easing.linear);
                actor.moveTo(actor.getX(), originalY, 0.25, Easing.linear);
                doAfter(250, () -> {
                    if (andThen != null) andThen();
                });
            });
        });
    }

    public static function popOutActor(actor: Actor, originalSize: Float = 1.15) { actor.growTo(originalSize * 1.15, originalSize * 1.15, 0.45, Easing.expoOut); }
    public static function popBackInActor(actor: Actor, originalSize: Float = 1.0) { actor.growTo(originalSize, originalSize, 0.15, Easing.linear); }
    public static function popClickActor(actor: Actor, originalSize: Float = 1.0) {
        actor.growTo(originalSize * 0.8, originalSize * 0.8, 0.10, Easing.linear);
        doAfter(100, () -> {
            actor.growTo(originalSize, originalSize, 0.10, Easing.linear);
        });
    }
    public static function addPopBehaviorToActor(actor: Actor, ?originalSize: Float = 1.0, ?condition: String -> Bool) {
        if (Game.isMobile == false) {
            onEnter(() -> {
                if ((condition == null) || (condition != null && condition('enter')))
                    popOutActor(actor, originalSize);
            }, actor);
            onExit(() -> {
                if ((condition == null) || (condition != null && condition('exit')))
                    popBackInActor(actor, originalSize);
            }, actor);
        }
        onClick(() -> {
            if ((condition == null) || (condition != null && condition('click')))
                popClickActor(actor, originalSize);
        }, actor);
    }
    public static function setupPopBehaviorForSUIButtons() {    // Called in MainScene
        SUIButton.onCreate = function onButtonCreate(button) {
            function onlyIfButtonEnabled(_: String): Bool { return button.isEnabled; }
            SpecialEffectsFluff.addPopBehaviorToActor(button.actor, onlyIfButtonEnabled);
        }
    }

    public static function setupSayerAudio() {
        Sayer.onSay = function(textBox: TextBox) {
            playAudio('SayerPopAudio', MISC_CHANNEL);
            if (textBox.nLines == 1)
                playAudio('SayerScribbleShortAudio', MISC_CHANNEL);
            else if (textBox.nLines == 2)
                playAudio('SayerScribbleMediumAudio', MISC_CHANNEL);
            else
                playAudio('SayerScribbleLongAudio', MISC_CHANNEL);
        }
    }
    public static function sayBubble(sayWhat: String, sayX: Float, sayY: Float, seconds: Float) {
        return Sayer.say(sayWhat, sayX, sayY, seconds, 'SayerBackgroundActor', { extraTextOffsetY: -4 });
    }
    public static function sayCustomBubble(sayWhat: String, sayX: Float, sayY: Float, seconds: Float, actorName: String) {
        return Sayer.say(sayWhat, sayX, sayY, seconds, actorName, { extraTextOffsetY: -4 });
    }
    public static function sayAlert(sayWhat: String, sayX: Float, sayY: Float, seconds: Float) {
        return Sayer.say(sayWhat, sayX, sayY, seconds, 'HintBackgroundActor', { extraTextOffsetY: -2, extraSidePadding: 3 });
    }

    public static function sheenActor(actor: Actor) {
        final currentScene = getCurrentSceneName();
        var xOffset = -10;
        var yOffset = -10;
        var imageToDraw: BitmapWrapper;
        var sheenBitmapDataSmall = resizeImage(getExternalImage('Images/Particles/Sheen/SheenSmall.png'), 1*Engine.SCALE, 1*Engine.SCALE, false);
        var sheenBitmapDataBig   = resizeImage(getExternalImage('Images/Particles/Sheen/SheenBig.png'), 1*Engine.SCALE, 1*Engine.SCALE, false);

        // Get a fully white version of the actor frame
        // Get a normal version of the actor frame, and use a black sheen png to cut a hole in it
        // Put the cut one over the white one.
        function redrawDownRighter(currentTime: Int) {
            if (actor == null || actor.isAnimationPlaying() == false) return;
            xOffset += 3;
            yOffset += 3;
            if (imageToDraw != null)
                removeImage(imageToDraw);
            var actorFrameBitmapData = getImageForActor(actor).clone();
            actor.setFilter([createBrightnessFilter(100)]);
            var actorFrameWhite = getImageForActor(actor).clone();
            actor.clearFilters();
            final sheenBMDUsed = if (currentTime == 360) sheenBitmapDataBig else sheenBitmapDataSmall;
            clearImageUsingMask(actorFrameBitmapData, sheenBMDUsed, xOffset, xOffset);
            drawImageOnImage(actorFrameBitmapData, actorFrameWhite, 0, 0, BlendMode.NORMAL);
            imageToDraw = new BitmapWrapper(new Bitmap(actorFrameWhite));
            attachImageToActor(imageToDraw, actor, 0, 0, 1);
        }

        // OR: Draw the actor over the black normal sheen with retain
        // Make it fully white
        // Draw it over another actor frame

        doEveryUntil(60, 1000, (currentTime: Int) -> {
            if (getCurrentSceneName() != currentScene) return;
            redrawDownRighter(currentTime);
        });

    }
    public static function indicateWithArrows(x: Float, y: Float, isFlipped: Bool = false) {
        final offsetX = 0;
        final offsetY = -42;
        var lastCreatedIndicator = createActor('ArrowsIndicatorActor', 'UI');
        lastCreatedIndicator.setX(x + offsetX);
        lastCreatedIndicator.setY(y + offsetY);
        lastCreatedIndicator.growTo(0, 0, 0, Easing.linear);
        lastCreatedIndicator.growTo(if (isFlipped) -1 else 1, 1, 0.25, Easing.expoOut);
        return lastCreatedIndicator;
    }
    public static function removeIndicator(indicator: Actor) {
        recycleActor(indicator);
    }
    
    static var latestDarkness: Actor;
    static var latestDarknessSceneName: String;
    public static function createDarknessInScene(yOffset: Float = 0) {
        // final darkness = createActor('CampfireDarknessActor', 'DarknessLayer');
        // darkness.currAnimation.setFrameDuration(0, 10000);
        // darkness.fadeTo(0.8, 0, Easing.linear);
        latestDarkness = createActor('GenericDarknessActor', 'DarknessLayer');
        centerActorOnScreen(latestDarkness);
        latestDarkness.setY(latestDarkness.getY() + yOffset);
        latestDarknessSceneName = getCurrentSceneName();
        function scaleDarkness(oldScale: Float) {
            if (getCurrentSceneName() != latestDarknessSceneName) return;
            if (latestDarkness == null) return;
            final overMiliseconds = 150;
            final newScale =
                if (oldScale > 1.050) (randomIntBetween(1000, 1050) / 1000)
                else (randomIntBetween(1050, 1100) / 1000);
                latestDarkness.growTo(newScale, newScale, overMiliseconds/1000, Easing.linear);
            doAfter(overMiliseconds, () -> {
                scaleDarkness(newScale);
            });
        }
        scaleDarkness(1);
    }
    public static function removeDarknessFromScene() {
        if (latestDarkness == null) return;
        if (latestDarknessSceneName != getCurrentSceneName()) return;
        recycleActor(latestDarkness);
        latestDarkness = null;
    }
    public static function setupEventBackgroundImage(path, yOffset) {
        path = extrapolatePNGPathWithBasePath(path, 'Images/Backgrounds');
        final backgroundImageName = path;
        final backgroundImage = new ImageX(backgroundImageName, 'Background');
        backgroundImage.setWidthScale(backgroundImage.getWidthScale() * 1.5);
        backgroundImage.setHeightScale(backgroundImage.getHeightScale() * 1.5);
        backgroundImage.centerOnScreen();
        trace('Centered BG on screen at y = ${backgroundImage.getY()}');
        backgroundImage.setY(backgroundImage.getY() + yOffset);
        trace('Set BG image Y to ${backgroundImage.getY()} because added offset ${yOffset}');
        return backgroundImage;
    }
    public static function setupCharactersAtEvent(feetYFromCenter: Float) {
        final charactersAtEvent: Array<Actor> = [];
        if (Player.characters == null || Player.characters.length == 0)
            return charactersAtEvent;
        final character1 = createActor('UnitActor', 'CharactersLayer');
        character1.setAnimation(Player.characters[0].getClassName());
        character1.growTo(1.5, 1.5, 0, Easing.linear);
        character1.setY(getScreenYCenter() - character1.getHeight() * 1.25 + feetYFromCenter);
        character1.setXCenter(getScreenXCenter() - 85);
        charactersAtEvent.push(character1);
        if (Player.characters.length > 1) {
            final character2 = createActor('UnitActor', 'CharactersLayer');
            character2.setAnimation(Player.characters[1].getClassName());
            character2.growTo(1.5, 1.5, 0, Easing.linear);
            character2.setY(getScreenYCenter() - character2.getHeight() * 1.25 + feetYFromCenter + 10);
            character2.setXCenter(character1.getX() - 15);
            charactersAtEvent.push(character2);
        }
        return charactersAtEvent;
    }
    public static function setEventMiddleActor(actorName: String, animationName: String, ?xOffset = 0.0, ?yOffset = 0.0) {
        final middleActor = createActor(actorName, 'EnvironmentLayer');
        middleActor.setAnimation(animationName);
        middleActor.growTo(1.5, 1.5, 0, Easing.linear);
        centerActorOnScreen(middleActor);
        middleActor.setY(getScreenYCenter() - middleActor.getHeight() * 1.25 + yOffset);
        middleActor.setX(middleActor.getX() + xOffset);
        return middleActor;
    }

    public static function shakeScreenShort() {
		startShakingScreen(0.01, 0.25);
	}
    

    // Backgrounds
    public static function getNonCombatBackgroundName() {
        if (Player.getCurrentChapter() != null && Player.progression.currentJourneyIndex != -1) {
            final journey = Player.getCurrentJourneyInCurrentChapter();
            if (journey.defaultNodeAnimation != null)
                return journey.defaultNodeAnimation;
        }
        if (Battlefield.lastBattlefieldEncounter != null)
            return Battlefield.lastBattlefieldEncounter.waves[0].background;
        return 'Forest';
    }
    public static function tryStartSpawningNonCombatSea(options: {
        background: String,
        setBackground: String -> Void,
        x: Float,
        getBackgroundY: Void -> Float
    }) {
        if (['Ship', 'Beach'].indexOf(options.background) == -1) return;
        var seaLayer: String = 'BackgroundUnderlay';
        if (options.background == 'Beach') {
            options.setBackground('BeachNoSea');
        } else if (options.background == 'Ship') {
            trace('Background is Ship');
            options.setBackground('ShipNoSea');
        }
        trace('  Set seaLayer to ${seaLayer}');
        final sea = createActor('SeaBackgroundActor', seaLayer);
        sea.setX(options.x);
        sea.setY(options.getBackgroundY() + sea.getHeight() * 0.25);
        trace('  S: Set sea Y to ${options.getBackgroundY()}');
        sea.growTo(1.5, 1.5, 0, Easing.quadInOut);
        sea.growTo(1.6, 1.5, 5, Easing.quadInOut);
        doEvery(6000, () -> {
            sea.growTo(1.5, 1.5, 3, Easing.quadInOut);
            doAfter(3000, () -> {
                sea.growTo(1.6, 1.5, 3, Easing.quadInOut);
            });
        });
    }
    public static function tryStartSpawningBattlefieldSea(encounter: BattlefieldEncounter) {
        final wave = encounter.waves[0];
        if (['Ship', 'Beach'].indexOf(wave.background) == -1) return;
        trace('Yep');
        var seaLayer: String = 'BackgroundUnderlay';
        if (wave.background == 'Beach') {
            Battlefield.setBackground('BeachNoSea');
        } else if (wave.background == 'Ship') {
            trace('Background is Ship');
            Battlefield.setBackground('ShipNoSea');
            trace('Set BG to No sea');
        } else {
            trace('Huh. Nothing');
        }
        trace('Set seaLayer to ${seaLayer}');
        final sea = createActor('SeaBackgroundActor', seaLayer);
        sea.setX(Battlefield.backgroundImage.getX());
        sea.setY(Battlefield.backgroundImage.getY());
        sea.growTo(1.05, 1, 3, Easing.quadInOut);
        doEvery(6000, () -> {
            sea.growTo(1, 1, 3, Easing.quadInOut);
            doAfter(3000, () -> {
                sea.growTo(1.05, 1, 3, Easing.quadInOut);
            });
        });
    }
    public static function tryStartSpawningLeaves(background: String) {
        if (['Forest', 'Road'].indexOf(background) == -1) return;
        var timeSinceLastLeaf = 5000;
        doEvery(1000, () -> {
            timeSinceLastLeaf += 1000;
            if (timeSinceLastLeaf < 5000) return;
            if (percentChance(33) == false) return;
            timeSinceLastLeaf = 0;
            final leaf = createActor('LeafParticleActor', 'Particles');  // It's all setup from the actor
        });
    }
    public static function tryStartSpawningStalagmites(background: String) {
        if (['Cave', 'Hell'].indexOf(background) == -1) return;
        var timeSinceLastRock = 5000;
        doEvery(1000, () -> {
            timeSinceLastRock += 1000;
            if (timeSinceLastRock < 5000) return;
            if (percentChance(33) == false) return;
            timeSinceLastRock = 0;
            final leaf = createActor('StalagmitePieceActor', 'Particles');  // It's all setup from the actor
        });
    }
    public static function tryStartSpawningMist(background: String) {
        if (background != 'Graveyard') return;
        var timeSinceLastCloud = 5000;
        doEvery(1000, () -> {
            timeSinceLastCloud += 1000;
            if (timeSinceLastCloud < 5000) return;
            if (percentChance(33) == false) return;
            timeSinceLastCloud = 0;
            final leaf = createActor('DarkMistActor', 'Particles');  // It's all setup from the actor
        });
    }


}
