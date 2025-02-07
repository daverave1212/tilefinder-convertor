
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
import scripts.SpecialEffectsFluff.sayBubble;
import Std.int;

class Cutscene {

    private static function sayForActor(actor : Actor, what : String, duration : Float = 2) sayBubble(what, actor.getXCenter(), actor.getYCenter() - 20, duration);

    static var functionBeingCalledForCutscene: (Void -> Void) -> Void;
    static var callback: Void -> Void;

    public static function start() {
        functionBeingCalledForCutscene(callback);
    }

    public static function goToCutsceneForKingMeet(andThen: Void -> Void) {
        // functionBeingCalledForCutscene = playKingMeetCutsceneAndThen;
        // callback = andThen;
        // U.changeScene('KingMeetCutsceneScene');
    }

    static function playKingMeetCutsceneAndThen(?andThen: Void -> Void) {
        trace('Playing king meet cutscene');
        playMusic('TranquilMusic');
        var background = new ImageX('Images/Backgrounds/Black.png', 'Background');
        background.centerOnScreen();
        var king: Actor = null;
        var overlayActor: Actor = null;
        var player1: Actor = null;
        var player2: Actor = null;
        final sequence = doSequence([
            { time: 1500, func: () -> {
                king = createActor('UnitActor', 'Units');
                king.growTo(1.5, 1.5, 0, Easing.linear);
                centerActorOnScreen(king);
                king.setAnimation('King Erio');
                king.setFilter([createBrightnessFilter(100)]);
                king.fadeTo(0, 0, Easing.linear);
                king.fadeTo(1, 1, Easing.linear);   // Fade in over 1 second
            }},
            { time: 4000, func: () -> {
                overlayActor = createActor('OverlayActor', 'OverlayLayer');
                overlayActor.setAnimation('White Screen');
                centerActorOnScreen(overlayActor);
                overlayActor.fadeTo(0, 0, Easing.expoIn);
                overlayActor.fadeTo(1, 0.75, Easing.expoIn);
            }},
            { time: 1550, func: () -> {
                king.clearFilters();
                overlayActor.fadeTo(0, 2, Easing.linear);
            }},
            { time: 2000, func: () -> {
                sayBubble('I\'ve been expecting you, adventurers.', king.getXCenter(), king.getY() + 25, 2.5);
            }},
            { time: 3000, func: () -> {
                overlayActor.setAnimation('Black Screen');
                overlayActor.fadeTo(1, 3, Easing.linear);
            }},
            { time: 5000, func: () -> {
                background.changeImage('Images/Backgrounds/CharacterSelectBackground.png');
                king.growTo(1, 1, 0, Easing.linear);
                centerActorOnScreen(king); king.setX(370);
                player1 = createActor('UnitActor', 'Units');
                player2 = createActor('UnitActor', 'Units');
                player1.setAnimation(Player.characters[0].getClassName());
                player2.setAnimation(Player.characters[1].getClassName());
                player1.setX(20); player1.setY(30);
                player2.setX(25); player2.setY(155);
                overlayActor.fadeTo(0, 0.75, Easing.expoOut);
            }},
            { time: 1000, func: () -> {
                sayForActor(king, 'So... I heard about you, "murderer"...', 1.75);
            }},
            { time: 2000, func: () -> {
                player1.moveBy(50, 35, 0.5, Easing.expoIn);
            }},
            { time: 500, func: () -> {
                sayForActor(player1, 'It was not me who killed those guards!', 3);
            }},
            { time: 4500, func: () -> { flipActorHorizontally(king); }},
            { time: 1250, func: () -> {
                sayForActor(king, 'I know...', 1.5);
            }},
            { time: 3000, func: () -> { sayForActor(king, 'It was my daughter who killed them.', 2.25); }},
            { time: 2000, func: () -> { sayForActor(player2, 'What?!', 1); }},
            { time: 1000, func: () -> {
                unflipActorHorizontally(king);
                sayForActor(king, 'There is little time, so listen closely.', 2);
            }},
            { time: 2250, func: () -> { sayForActor(king, 'We are all in grave danger.', 2); }},
            { time: 2250, func: () -> { sayForActor(king, 'You must find and defeat Father Almund.', 2); }},
            { time: 2250, func: () -> { sayForActor(king, 'He and his bishops have turned against me...', 2); }},
            { time: 2000, func: () -> { sayForActor(king, '...and he is likely after your lives, as well.', 2); }},
            { time: 2250, func: () -> {
                sayForActor(player1, 'But what does Marceline want?', 2);
            }},
            { time: 1000, func: () -> {
                sayForActor(king, 'There is no time!', 1);
            }},
            { time: 1000, func: () -> {
                sayForActor(king, 'You must go, quickly!', 1);
            }},
            { time: 2000, func: () -> {
                sayForActor(king, 'Seek out the churches on the outskirts of the town.', 2);
            }},
            { time: 2000, func: () -> {
                sayForActor(king, 'But beware! The roads are treacherous and filled with monsters and bandits...', 2.5);
            }},
            { time: 3000, func: () -> {
                king.moveBy(-20, 0, 0.25, Easing.expoIn);
                sayForActor(king, 'Go now!', 1);
            }},
            { time: 2000, func: () -> {
                sayForActor(king, 'We will meet again then the time is right.', 2);
            }},
            { time: 2000, func: () -> {
                sayForActor(king, 'The whole kingdom depends on you...', 2);
            }},
            { time: 2500, func: () -> {
                flipActorHorizontally(player1);
                flipActorHorizontally(player2);
            }},
            { time: 500, func: () -> {
                player1.moveBy(-200, 0, 1, Easing.expoIn);
                player2.moveBy(-200, 0, 1, Easing.expoIn);
            }},
            { time: 1750, func: () -> {
                sayForActor(king, 'If only I had been a good enough father...', 2);
            }},
            { time: 1000, func: () -> {
                overlayActor.fadeTo(1, 1, Easing.linear);
            }}
        ], andThen);

        onEscapeKeyPress(() -> {
            sequence.stop();
            if (andThen != null) andThen();
        });

    }

}

