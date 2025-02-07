
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


class Intro
{

    public static var marceline : Actor;
    public static var guard1 : Actor;
    public static var guard2 : Actor;
    public static var player : Actor;
    public static var guard3 : Actor;
    public static var guard4 : Actor;

    public static var skip = false;
    public static var andThen: Void -> Void;
    
    public static function start() {
        if (andThen == null) throwAndLogError('No andThen function present in Intro. Use the goToIntroCinematicAndThen function to go here.');
        engine.moveCamera(getSceneWidth() / 2, 0);
        var backgroundImage = new ImageX('Images/Backgrounds/Road.png', 'Background');
        backgroundImage.centerOnScreen();
        
        marceline = createActor('UnitActor', 'Characters');
        marceline.setAnimation('Marceline');
        marceline.setX(325); marceline.setY(95);

        guard1 = createActor('UnitActor', 'Characters');
        guard1.setAnimation('Guard');
        guard1.growTo(-1, 1, 0, Easing.linear);
        guard1.setX(250); guard1.setY(115);

        guard2 = createActor('UnitActor', 'Characters');
        guard2.setAnimation('Guard');
        guard2.setX(390); guard2.setY(120);

        onEscapeKeyPress(() -> {
            skipIntro();
        });

        doAfter(1000, () -> {
            if (skip) { 
                andThen();
            } else {
                startDialogue();
            }
        });
    }

    public static function goToIntroCinematicAndThen(andThen: Void -> Void) {
        Intro.andThen = andThen;
        changeScene('IntroScene');
    }

    static function sayForActor(actor : Actor, what : String, duration : Float = 2) sayBubble(what, actor.getXCenter(), actor.getYCenter() - 20, duration);

    static var events = [
        {
            action: () -> sayForActor(guard1, 'Finally! We caught you!', 2),
            duration: 2500
        },
        {
            action: () -> sayForActor(guard2, 'You will pay for your evil magic, witch!', 3),
            duration: 3500
        },
        {
            action: () -> marceline.growTo(-1, 1, 0.3, Easing.expoOut),
            duration: 1000
        },
        {
            action: () -> marceline.growTo(1, 1, 0.3, Easing.expoOut),
            duration: 1000
        },
        {
            action: () -> {
                sayForActor(marceline, 'Fools!', 1);
                doMarcelineHah(marceline);
            },
            duration: 1500
        },
        {
            action: () -> sayForActor(marceline, 'I will raise an army of undead!', 2.5),
            duration: 3000
        },
        {
            action: () -> sayForActor(marceline, 'And this whole kingdom will be mine!', 2.5),
            duration: 4000
        },
        {
            action: () -> {
                playAudio('ExplosionAudio');
                var explosion1 = createActor('IntroExplosionActor', 'Particles');
                explosion1.setX(guard1.getX()); explosion1.setY(guard1.getY());
                guard1.spinBy(-90, 0.3, Easing.expoIn);
                var explosion2 = createActor('IntroExplosionActor', 'Particles');
                explosion2.setX(guard2.getX()); explosion2.setY(guard2.getY());
                guard2.spinBy(90, 0.3, Easing.expoIn);
                startShakingScreen(0.1, 0.3);
                doAfter(300, () -> {
                    recycleActor(explosion1);
                    recycleActor(explosion2);
                    guard1.currAnimation.setFrameDuration(1, 10000);
                    guard2.currAnimation.setFrameDuration(1, 10000);
                    guard1.setCurrentFrame(1);
                    guard2.setCurrentFrame(1);
                });

            },
            duration: 2000
        },
        {
            action: () -> {
                player = createActor('UnitActor', 'Characters');
                player.setAnimation('Knight');
                player.setX(getScreenX() - 100); player.setY(marceline.getY());
                player.moveTo(getScreenX() + 50, player.getY(), 1, Easing.expoOut);
            },
            duration: 2000
        },
        {
            action: () -> sayForActor(player, 'Hey! What\'s going on?', 1),
            duration: 1500
        },
        {
            action: () -> sayForActor(marceline, '...?', 1),
            duration: 1000
        },
        {
            action: () -> {
                player.moveTo(marceline.getX(), marceline.getY(), 0.5, Easing.expoIn);
                var teleportParticles = createActor('IntroMarcelineTeleportActor', 'Particles');
                teleportParticles.setX(marceline.getX());
                teleportParticles.setY(marceline.getY());
                teleportParticles.growTo(1.25, 1, 1, Easing.expoIn);
                doAfter(1000, () -> teleportParticles.growTo(0, 1, 0.25, Easing.expoOut));
                recycleActor(marceline);
            },
            duration: 2000
        },
        {
            action: () -> sayForActor(player, 'Dammit! She escaped!'),
            duration: 1500
        },
        {
            action: () -> {
                guard3 = createActor('UnitActor', 'Characters');
                guard3.setAnimation('Patrolling Guard');
                guard4 = createActor('UnitActor', 'Characters');
                guard4.setAnimation('Patrolling Guard');
                guard3.setX(getScreenX() + getScreenWidth() + 100); guard3.setY(25);
                guard4.setX(getScreenX() + getScreenWidth() + 100); guard4.setY(150);
                guard3.moveTo(getScreenX() + getScreenWidth() - 125, guard3.getY(), 0.5, Easing.expoIn);
                guard4.moveTo(getScreenX() + getScreenWidth() - 155, guard4.getY(), 0.5, Easing.expoIn);
            },
            duration: 2000
        },
        {
            action: () -> sayForActor(player, 'They are dead...'),
            duration: 1500
        },
        {
            action: () -> sayForActor(guard3, 'What have you done?!'),
            duration: 1500
        },
        {
            action: () -> sayForActor(guard4, 'You are under arrest, scum!'),
            duration: 3000
        },
        {
            action: () -> sayForActor(player, 'No! You are making a mistake!'),
            duration: 1500
        },
        {
            action: () -> sayForActor(guard3, 'Get him!'),
            duration: 500
        },
        {
            action: () -> {
                andThen();
            },
            duration: 0
        }
    ];

    public static function skipIntro() {
        skip = true;
        andThen();
    }

    static function startDialogue() {
        var eventCounter = -1;
        
        
        function doNextDialogue() {
            if (skip) return;
            eventCounter++;
            if (eventCounter >= events.length) return;
            events[eventCounter].action();
            // doAfter(events[eventCounter].duration * Constants._cinematicTurboSpeedModifier, () -> {
            //     doNextDialogue();
            // });
        }
        doAfter(1000, () -> doNextDialogue());
    }


    static function doMarcelineHah(marceline: Actor) {
        playAudio('MarcelineHahAudio');
        final offsetY: Float = marceline.getHeight() * 0.1 / 2;
        marceline.growTo(1, 1.1, 0.1, Easing.linear);
        marceline.moveTo(marceline.getX(), marceline.getY() - offsetY, 0.1, Easing.linear);
        doAfter(100, () -> {
            marceline.growTo(1, 1, 0.1, Easing.linear);
            marceline.moveTo(marceline.getX(), marceline.getY() + offsetY, 0.1, Easing.linear);
        });
    }

}