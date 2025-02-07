
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
import Std.int;

class MessageScreen
{

    public static var k = {
        initialPauseDuration: 500,
        fadeInDuration: 750,
        pauseDuration: 1500,
        fadeOutDuration: 750
    }

    static var textBeingShown: String;
    static var fontBeingUsed: Font;
    static var andThenFunction: Void -> Void;

    static var givenOptions: Dynamic = {};

    static var textBox: TextBox;
    static var currentOpacity: Float = 1.0;

    static var willShowInterstitialAd = false;
    static var didInterstialWork = false;

    public static function start() {
        if (Game.isMobile && willShowInterstitialAd) {
            Log.go("Going with ad...");
            U.setupMobileAdDebugMessages(function(msg) { Log.go(msg); });
            willShowInterstitialAd = false;
            U.showInterstitialAd();
            U.loadInterstitialAd();
            didInterstialWork = false;              // Will be set to true by the onInterstitialShown if it works
            doAfter(1500, () -> {
                if (didInterstialWork == false) {   // If it didn't work, just continue
                    doActualStart();
                }
            });
        } else {
            Log.go("Not on mobile or not show interstitial.");
            willShowInterstitialAd = false;
            didInterstialWork = false;
            doActualStart();
        }
    }
    public static function doActualStart() {
        if (textBeingShown == null || fontBeingUsed == null) throwAndLogError('Go to message screen with the function, not simply by changing scene!');
        final initialPauseDuration  : Int = nullOr(givenOptions.initialPauseDuration, k.initialPauseDuration);
        final fadeInDuration        : Int = nullOr(givenOptions.fadeInDuration, k.fadeInDuration);
        final pauseDuration         : Int = nullOr(givenOptions.pauseDuration, k.pauseDuration);
        final fadeOutDuration       : Int = nullOr(givenOptions.fadeOutDuration, k.fadeOutDuration);
        givenOptions = {};
        currentOpacity = 0;
        var isSkipped = false;
        doAfter(initialPauseDuration, function() {
            if (isSkipped) return;
            doEveryUntil(50, fadeInDuration, function(_) {            // Increase opacity for 1 second
                if (isSkipped) return;
                currentOpacity += 1 / (fadeInDuration / 50);
            });
            doAfter(fadeInDuration + pauseDuration, function() {      // Keep opacity for 2 more seconds
                if (isSkipped) return;
                doEveryUntil(50, fadeOutDuration, function(_) {       // Decrease opacity for 3.5 seconds
                    if (isSkipped) return;
                    currentOpacity -= 1 / (fadeOutDuration / 50);
                });
                doAfter(fadeOutDuration, function() {
                    if (isSkipped) return;
                    if (andThenFunction != null) {
                        andThenFunction();                      // And then...
                    }
                });
            });
        });
        U.onDraw((g) -> draw(g));
        onClick(() -> {
            isSkipped = true;
            var finishedFading = false;
            doEvery(25, () -> {
                if (finishedFading) return;
                currentOpacity -= 1 / (fadeOutDuration / 25);
                if (currentOpacity <= 0) {
                    finishedFading = true;
                    if (andThenFunction != null)
                        andThenFunction();
                }
            });
        });
    }
    
    public static function showInterstitialAdOnNextMessageScreen() {
        if (Game.isMobile == false) return;
        willShowInterstitialAd = true;
    }
    public static function onInterstitialShown() {
        didInterstialWork = true;                   // Marks it as true for the start function to continue
    }
    public static function onInterstitialClosed() {
        doActualStart();
    }

    static function draw(g: G) {
        g.alpha = currentOpacity;
        g.setFont(fontBeingUsed);
        final textWidth = fontBeingUsed.getTextWidth(textBeingShown) / Engine.SCALE;
        final textX = (getScreenWidth() - textWidth) / 2;
        final textY = (getScreenHeight() - fontBeingUsed.getHeight() / Engine.SCALE) / 2;
        g.drawString(textBeingShown, textX, textY);
    }

    public static function goToMessageScreenRedAndThen(text: String, andThen: Void -> Void) {
        goToMessageScreenAndThen(text, getFont(GAME_OVER_FONT), null, andThen);
    }
    public static function goToMessageScreenWhiteAndThen(text: String, andThen: Void -> Void) {
        goToMessageScreenAndThen(text, getFont(BIG_WHITE_FONT), null, andThen);
    }
    public static function goToMessageScreenOptionsAndThen(text: String, options: Dynamic, andThen: Void -> Void) {
        final fontUsed = if (options.color == 'RED') getFont(GAME_OVER_FONT) else getFont(BIG_WHITE_FONT);
        goToMessageScreenAndThen(text, fontUsed, options, andThen);
    }

    static function goToMessageScreenAndThen(text: String, font: Font, ?options: Dynamic, andThen: Void -> Void) {
        textBeingShown = text;
        fontBeingUsed = font;
        andThenFunction = andThen;
        givenOptions = nullOr(options, {});
        changeScene('MessageScreenScene');
    }



}