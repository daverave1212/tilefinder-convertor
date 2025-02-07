
package scripts;

import com.stencyl.graphics.G;
import com.stencyl.graphics.BitmapWrapper;
import com.stencyl.graphics.shaders.InlineShader;
import com.stencyl.graphics.shaders.TintShader;

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
using Lambda;

import scripts.Constants.*;
import scripts.SpecialEffectsFluff.*;

import scripts.NonCombatEvents.startDialogue;
import scripts.NonCombatEvents.alertAndWait;
import scripts.NonCombatEvents.sayAndWait;
import scripts.NonCombatEvents.sayCustomAndWait;
import scripts.NonCombatEvents.hideOptions;
import scripts.NonCombatEvents.showOptions;
import scripts.NonCombatEvents.showCharacterActors;
import scripts.NonCombatEvents.hideCharacterActors;
import scripts.NonCombatEvents.reloadOptions;
import scripts.NonCombatEvents.done;
import scripts.NonCombatEvents.pauseDialogueClicking;
import scripts.NonCombatEvents.resumeDialogueClicking;

import Std.int;
import Math.min;



class NonCombatEventsDatabase {
	
    public static function getRandom(): NonCombatEventDynamic {
        final possibleEvents = events.filter(enc -> enc.appearCondition == null || enc.appearCondition() == true);
        return randomOf(possibleEvents);
    }
    public static function get(nonCombatEventName: String): NonCombatEventDynamic {
        final filteredEncounters = events.filter(enc -> enc.name == nonCombatEventName);
        if (filteredEncounters.length == 0) throwAndLogError('No event named ${nonCombatEventName} found');
        return filteredEncounters[0];
    }

    static var nUseItemTriesDuringEvent: Int = 0;   // Incremented by the use item option
    static var middleActor: Actor;                  // Initialized by setMiddleActor
    static var black: ImageX;

    static var eventSayExtraYOffset: Int = 0;


    public static function onEventStart() {         // Called from NonCombatEvents
        nUseItemTriesDuringEvent = 0;
        slideBackgroundImage = null;
        overlayOverlayActor = null;
        middleActor = null;
        black = null;
    }
    public static function end() {
        doAfter(250, done);
    }
    
    static function getCharacterPoint(charIndex): Point {
        final actor = NonCombatEvents.charactersAtEvent[charIndex];
        final x = actor.getXCenter() + 1;
        final y = actor.getY() - 15;
        return new Point(x, y);
    }
    static function getRandomCharacterPoint() return getCharacterPoint(Player.getRandomCharacterIndex());
    
    static function startDialogueAfter(milliseconds: Int, funcs: Array<Void -> Void>, andThen: Void -> Void) {
        doAfter(milliseconds, () -> {
            startDialogue(funcs, andThen);
        });
    }
    static function giveItem(itemName: String) {
        Player.giveItem(itemName);
        final itemIconPath = ItemsDatabase.get(itemName).imagePath;
        SpecialEffectsFluff.doItemToInventoryAnimation(itemIconPath, getScreenXCenter(), getScreenYCenter() - 30);
    }
    static function consumeItem(item: Item) {
        var itemCoordinates: Position = item.consume(Player.inventory);
        InventoryUI.self.updateItemVisuals(itemCoordinates.i, itemCoordinates.j);
    }
    static function scrollForAllChars(color: String, text: String) {
        final stm =
            if (color == 'green') NonCombatEvents.greenTextManager
            else NonCombatEvents.whiteTextManager;
        final texts = times(text, Player.characters.length);
        NonCombatEvents.scrollTextAllChars(stm, texts, 500);
    }
    static function nothingHappensWithThatItem(?onUseDialogue: Void -> Void, ?on3FailuresDialogue: Void -> Void) {
        nUseItemTriesDuringEvent++;
        startDialogue([
            if (onUseDialogue == null) () -> { sayFromRandomCharacterAndWait('That didn\'t do anything.'); }
            else onUseDialogue
        ], () -> {
            if (nUseItemTriesDuringEvent >= 3) {
                startDialogueAfter(1000, [
                    if (on3FailuresDialogue == null) () -> sayFromRandomCharacterAndWait('It\'s getting late. We should get going.')
                    else on3FailuresDialogue
                ], end);
            } else {
                NonCombatEvents.showOptions();
            }
        });
    }

    static function sayFromRandomCharacterAndWait(message) {
        sayAndWait(message, getRandomCharacterPoint());
    }
    static function sayFromRandomCharacter(message) {
        final point = getRandomCharacterPoint();
        sayBubble(message, point.x, point.y, 2.5);
    }
    static function sayFromCharacter(charIndex: Int, message) {
        final point = getCharacterPoint(charIndex);
        sayBubble(message, point.x, point.y, 2.5);
    }
    static function sayFromCharacterAndWait(charIndex: Int, message) {
        final point = getCharacterPoint(charIndex);
        sayAndWait(message, point);
    }
    static function sayFromEvent(message, durationInSeconds: Float = 2.5) {
        if (durationInSeconds >= 10) trace('WARNING: duration should be in SECONDS for sayFromEvent for message: "${message}"');
        sayBubble(message, middleActor.getXCenter(), middleActor.getYCenter() - 30 + eventSayExtraYOffset, durationInSeconds);
    }
    static function sayFromEventAndWait(message, xOffset: Float = 0, yOffset: Float = 0) {
        final point = new Point(middleActor.getXCenter() + xOffset, middleActor.getYCenter() - 30 + eventSayExtraYOffset + yOffset);
        sayAndWait(message, point);
    }
    static function sayFromStormjrAndWait(text: String) sayFromEventAndWait(text, -60, 17);
    static function sayAtAndWait(message, x: Float, y: Float) {
        final point = new Point(x, y);
        sayAndWait(message, point);
    }
    static function sayFromActorAndWait(actor: Actor, message: String, xOffset: Int = 0, yOffset: Int = 0) {
        final point = new Point(actor.getXCenter() + xOffset, actor.getYCenter() - 30 + eventSayExtraYOffset + yOffset);
        sayAndWait(message, point);
    }
    static function say3FromActorAndWait(actor: Actor, message: String) {
        final point = new Point(actor.getXCenter(), actor.getYCenter() - 15 + eventSayExtraYOffset);
        sayCustomAndWait(message, point, 'Sayer3BackgroundActor');
    }
    static function sayFromActor(actor: Actor, message: String, durationInSeconds: Float = 2.5, ?xOffset: Float = 0, ?yOffset: Float = 0) {
        final point = new Point(actor.getXCenter() + xOffset, actor.getYCenter() - 30 + eventSayExtraYOffset + yOffset);
        sayBubble(message, point.x, point.y, durationInSeconds);
    }
    static function sayFromNatasAndWait(message: String) {
        sayFromActorAndWait(middleActor, message, -2, -15);
    }
    static function sayFromFatherAlmundAndWait(message: String, ?isFlipped = false) {
        sayFromActorAndWait(middleActor, message, if (isFlipped) -18 else 18, 0);
    }
    static function sayFromNanaJoyAndWait(nanaJoy, ?isFlipped = false, sayWhat: String) {
        final xOffset = if (isFlipped) 7 else -7;
        sayFromActorAndWait(nanaJoy, sayWhat, xOffset, 0);
    }
    static function sayFromSandmanAndWait(nanaJoy, sayWhat: String) {
        sayFromActorAndWait(nanaJoy, sayWhat, -6, 0);
    }
    static function sayFromTylAndWait(tyl, sayWhat: String, ?isFlipped = false) {
        sayFromActorAndWait(tyl, sayWhat, if (isFlipped) 104 else -104, -25);
    }
    static function sayFromSpatulaAndWait(spatula, what: String) {
        sayFromActorAndWait(spatula, what, 0, -15);
    }
    static function sayFromSpatulaScaredAndWait(spatula, what: String) {
        sayFromActorAndWait(spatula, what, 8, -20);
    }
    static function sayFromSpatula(spatula, what: String, duration) {
        sayFromActor(spatula, what, duration, 1, -15);
    }
    static function sayFromSpatulaScared(spatula, what: String, duration) {
        sayFromActor(spatula, what, duration, 8, -20);
    }
    static function sayFromKingAndWait(king, what: String) {
        sayFromActorAndWait(king, what, 0, 10);
    }
    static function getCharacter(i: Int) {
        return NonCombatEvents.charactersAtEvent[i];
    }


    static function makeUseItemOption(onItemChosen: Item -> Void): Dynamic {
        return {
            title: 'Use Item',
            description: 'Choose an item to use for this situation.',
            appearCondition: null,
            onChoose: function() {
                NonCombatEvents.state = 'IN_INVENTORY';
                NonCombatEvents.hideOptions();
                function onInventoryClose() {
                    NonCombatEvents.state = 'CHOOSING';
                    NonCombatEvents.showOptions();
                }
                GUI.open('InventoryUI', [Player.inventory, TRIBUTE, null, (itemClicked: Item) -> {
                    GUI.openWith('PopupUI', {
                        item: itemClicked,
                        inventory: Player.inventory,
                        reason: TRIBUTE,
                        callback: (didChoose: Bool, _: Int) -> {
                            GUI.close('PopupUI');
                            GUI.close('InventoryUI');
                            onInventoryClose();
                            if (didChoose) {
                                onItemChosen(itemClicked);
                            }
                        }
                    });
                }, onInventoryClose]);
            }
        }
    }
    static function makeSkipOption() {
        return {
            title: 'Skip',
            description: 'Do nothing.',
            appearCondition: null,
            onChoose: function() {
                hideOptions();
                startDialogue([
                    () -> sayFromRandomCharacterAndWait('Nothing to see here.')
                ], end);
            }
        };
    }
   
    static function setMiddleActor(actorName: String, animationName: String, ?xOffset = 0.0, ?yOffset = 0.0) {
        middleActor = setEventMiddleActor(actorName, animationName, xOffset, NonCombatEvents.k.feetYFromCenter + yOffset);
        return middleActor;
    }
    static function turn(actor: Actor, ?isInstant = false, ?callback: Void -> Void) {
        actor.growTo(-1.5, 1.5, if (isInstant) 0 else 0.25, Easing.expoOut);
        if (isInstant == false && callback != null)
            doAfter(250, callback);
    }
    static function unturn(actor: Actor, ?isInstant = false, ?callback: Void -> Void) {
        actor.growTo(1.5, 1.5, if (isInstant) 0 else 0.25, Easing.expoOut);
        if (isInstant == false && callback != null)
            doAfter(250, callback);
    }
    static function advanceAndSayAndWait(actor: Actor, x: Int, sayWhat: String) {
        actor.moveBy(x, 0, 0.5, Easing.expoOut);
        doAfter(750, () -> {
            sayFromActorAndWait(actor, sayWhat);
        });
    }
    static function doMarcelineTeleportEffect(marceline: Actor, andThen: Void -> Void) {
        final tp = createActor('SpecialEffectActor', 'Particles');
        tp.setAnimation('Marceline Teleport');
        tp.growTo(1.5, 1.5, 0, Easing.linear);
        tp.setXCenter(marceline.getXCenter());
        tp.setYCenter(marceline.getYCenter());
        doAfter(800, andThen);
        doAfter(1150, () -> {
            recycleActor(tp);
        });
    }
    static function doMarcelineHah(marceline: Actor) {
        playAudio('MarcelineHahAudio');
        final offsetY: Float = marceline.getHeight() * 0.15 / 2;
        marceline.growTo(1.5, 1.65, 0.1, Easing.linear);
        marceline.moveTo(marceline.getX(), marceline.getY() - offsetY, 0.1, Easing.linear);
        doAfter(100, () -> {
            marceline.growTo(1.5, 1.5, 0.1, Easing.linear);
            marceline.moveTo(marceline.getX(), marceline.getY() + offsetY, 0.1, Easing.linear);
        });
    }

    static function damageCharacterIrresponsibly(charIndex: Int, amount: Int) {
        NonCombatEvents.pumpTextForChar(charIndex, NonCombatEvents.redFloatingTextManager, amount + '');
        flashRed(NonCombatEvents.charactersAtEvent[charIndex], 100);
        final pc = Player.characters[charIndex];
        pc.damage(amount);
        playAudio(pc.getAudioOnHit());
    }
    static function damageAllCharactersResponsibly(amount: Int, andThen: Void -> Void) {
        for (i in 0...Player.characters.length) {
            damageCharacterIrresponsibly(i, amount);
        }
        if (Player.checkGameOver() == true) {
            Game.gameOver();
            return;
        }
        if (Player.isAnyCharacterDead()) {
            Player.distributeHealthAmongCharacters();
        }
        andThen();

    }
    static function healAll(amount: Int) {
        final healAmounts = Player.characters.map(char -> int(min(amount, char.getMissingHealth())));
        healEach(healAmounts);
    }
    static function healEach(healAmounts: Array<Int>) {
        for (i in 0...Player.characters.length) {
            Player.characters[i].heal(healAmounts[i]);
        }
        final healAmountsStrings = healAmounts.map(number -> number + '');
        NonCombatEvents.scrollTextAllChars(NonCombatEvents.greenTextManager, healAmountsStrings);
    }

    static var overlayOverlayActor: Actor = null;   // Top-most image; used for fading
    static var slideBackgroundImage: ImageX;
    static function fadeOverlayOutBlack(milliseconds: Int = 1000, ?andThen: Void -> Void) {
        overlayOverlayActor = createActor('OverlayActor', 'ColorOverlayLayer');
        overlayOverlayActor.setAnimation('Black Screen');
        centerActorOnScreen(overlayOverlayActor);
        overlayOverlayActor.fadeTo(0, 0, Easing.linear);
        overlayOverlayActor.fadeTo(1, milliseconds / 1000, Easing.linear);
        doAfter(milliseconds, () -> {
            if (andThen != null) andThen();
        });
    }
    static function fadeOverlayOutWhite(milliseconds: Int, ?andThen: Void -> Void) {
        overlayOverlayActor = createActor('OverlayActor', 'ColorOverlayLayer');
        overlayOverlayActor.setAnimation('White Screen');
        centerActorOnScreen(overlayOverlayActor);
        overlayOverlayActor.fadeTo(0, 0, Easing.expoIn);
        overlayOverlayActor.fadeTo(1, milliseconds / 1000, Easing.expoIn);
        doAfter(milliseconds, () -> {
            if (andThen != null) andThen();
        });
    }
    static function fadeOverlayIn(milliseconds: Int, ?andThen: Void -> Void) {
        overlayOverlayActor.fadeTo(0, milliseconds / 1000, Easing.linear);
        doAfter(milliseconds, () -> {
            if (andThen != null) andThen();
        });
    }
    static function fadeOverlayOutAndInWithImage(outMilliseconds: Int = 1000, inMilliseconds: Int = 1000, imagePath: String, ?andThen: Void -> Void) {
        fadeOverlayOutBlack(outMilliseconds, () -> {
            setSlideBackground(imagePath);
            fadeOverlayIn(inMilliseconds, () -> {
                if (andThen != null) andThen();
            });
        });
    }
    static function setSlideBackground(path: String) {
        if (slideBackgroundImage != null) slideBackgroundImage.kill();
        slideBackgroundImage = new ImageX(path, 'SlideBackgroundLayer');
        slideBackgroundImage.centerOnScreen();
    }
    static function hideSlideBackground() {
        if (slideBackgroundImage != null) slideBackgroundImage.kill();
        slideBackgroundImage = null;
    }
    static function setSlideBackgroundBlack() {
        setSlideBackground('Images/Backgrounds/Black.png');
    }
    static function showSlides(slides: Array<Dynamic>, andThen: Void -> Void) {
        final font = getFont(BIG_WHITE_FONT);
        final textLine = new TextLine('set later', font, 0, 0);
        textLine.setSceneX(getScreenXCenter());
        textLine.setSceneY(getScreenYCenter());
        textLine.alignCenter();
        textLine.enable();
        function fadeInAndFadeInText(overTime: Int, andThen: Void -> Void) {
            textLine.fadeOut(overTime);
            fadeOverlayIn(overTime, andThen);
        }
        function fadeOutAndShowText(text: String, overTime: Int, idleTime: Int, andThen: Void -> Void) {  // 2 seconds
            textLine.setText(text);
            textLine.fadeIn(overTime);
            fadeOverlayOutBlack(overTime, () -> {
                doAfter(idleTime, andThen);
            });
        }
        final FADE_OUT_DURATION = 2000;     // To dark
        final DARK_IDLE_DURATION = 2000;    // Plain dark
        final FADE_IN_DURATION = 1000;      // To normal
        final IDLE_DURATION = 2000;         // Plain normal
        function showSlide(slide: Dynamic) {
            fadeOutAndShowText(slide.text, FADE_OUT_DURATION, DARK_IDLE_DURATION, () -> {
                setSlideBackground(slide.path);
                final slideAndGrowTimeSeconds = (FADE_IN_DURATION + IDLE_DURATION + if (slide.isLastSlide == true) 0 else FADE_OUT_DURATION) / 1000;
                slideBackgroundImage.growTo(1.10, 1.10, slideAndGrowTimeSeconds);
                slideBackgroundImage.slideBy(-0.05 * 748, -0.05 * 360, slideAndGrowTimeSeconds);
                fadeInAndFadeInText(FADE_IN_DURATION, () -> {
                    doAfter(IDLE_DURATION, () -> {
                        if (slides.length > 0) showSlide(slides.shift());
                        else {
                            hideSlideBackground();
                            andThen();
                        };
                    });
                });
            });
        }
        showSlide(slides.shift());
    }
    static function showTilePiecesUnlocked(nPieces: Int, andThen: Void -> Void) {
        fadeOverlayOutBlack(1000, () -> {
            doAfter(1000, () -> {
                fadeOverlayIn(0);
                setSlideBackgroundBlack();
                final tile = createActor('CinematicTileActor', 'SlideContentLayer');
                centerActorOnScreen(tile);
                tile.setAnimation('Pieces ${nPieces - 1}');
                tile.fadeTo(0, 0, Easing.linear);
                tile.fadeTo(1, 1, Easing.linear);
                doAfter(1500, () -> {
                    fadeOverlayOutWhite(500, () -> {
                        playAudio('TileRevealAudio');
                        tile.setAnimation('Pieces ${nPieces}');
                        fadeOverlayIn(1000, () -> {
                            doAfter(2000, () -> {
                                fadeOverlayOutBlack(500, () -> {
                                    hideSlideBackground();
                                    recycleActor(tile);
                                    fadeOverlayIn(500, andThen);
                                });
                            });
                        });
                    });
                });
            });
        });
    }
    static function doAfterDialogue(milliseconds: Int, func: Void -> Void) {
        pauseDialogueClicking();
        doAfter(milliseconds, () -> {
            resumeDialogueClicking();
            func();
        });
    }




    public static var events: Array<NonCombatEventDynamic> = [
        {   name: 'Intro',
            appearCondition: () -> false,   // Can not appear normally
            options: [],
            preventCharacterDrawing: true,
            init: function(andThen: Void -> Void) {
                playMusic('DarkTensionMusic');
                NonCombatEvents.setBackground('Images/Backgrounds/Road.png', 0, -35);
                final marceline = setMiddleActor('EventActor', 'Marceline');
                final guard1 : Actor = setMiddleActor('UnitActor', 'Patrolling Guard Flipped');
                guard1.setX(marceline.getX() - guard1.getWidth());
                guard1.setY(guard1.getY() + 15);
                final guard2 : Actor = setMiddleActor('UnitActor', 'Patrolling Guard');
                guard2.setX(marceline.getX() + marceline.getWidth());
                guard2.setY(guard2.getY() + 15);


                var player : Actor = setMiddleActor('UnitActor', 'Knight');
                player.setX(getScreenX() - player.getWidth());
                var guard3 : Actor = setMiddleActor('UnitActor', 'Patrolling Guard');
                var guard4 : Actor = setMiddleActor('UnitActor', 'Patrolling Guard');
                guard3.setX(getScreenX() + getScreenWidth() + 100); guard3.setY(25);
                guard4.setX(getScreenX() + getScreenWidth() + 100); guard4.setY(150);

                function sayFromKnightAndWait(message) {
                    sayFromActorAndWait(player, message, 2, -15);
                }

                startDialogueAfter(1000, [
                    () -> sayFromActorAndWait(guard1, 'Finally, we caught you!'),
                    () -> sayFromActorAndWait(guard2, 'You will pay for your evil magic, witch!'),
                    () -> {
                        turn(marceline);
                        doAfterDialogue(500, () -> {
                            unturn(marceline);
                        });
                        doAfterDialogue(500, () -> {
                            sayFromActorAndWait(marceline, 'Fools!');
                            doMarcelineHah(marceline);
                        });
                    },
                    () -> sayFromActorAndWait(marceline, 'I will raise an army of undead!'),
                    () -> sayFromActorAndWait(marceline, 'And this whole kingdom will be mine!'),
                    () -> {
                        final sword1 = createActor('OtherParticles', 'Particles');
                        sword1.setAnimation('Spectral Sword');
                        sword1.growTo(1.5, 1.5, 0);
                        final sword2 = createActor('OtherParticles', 'Particles');
                        sword2.setAnimation('Spectral Sword');
                        sword2.growTo(1.5, 1.5, 0);
                        final guard1FeetY = guard1.getY() + guard1.getHeight();
                        final guard2FeetY = guard2.getY() + guard2.getHeight();
                        final guard1X = guard1.getX() + 20;
                        final guard2X = guard2.getX() + 20;
                        SpellDatabase.doSwordBarrageVisuals(sword1, guard1.getXCenter(), guard1.getY() + 15);
                        SpellDatabase.doSwordBarrageVisuals(sword2, guard2.getXCenter(), guard2.getY() + 15);
                        playAudio('SwordBarrageAudio');
                        doAfterDialogue(150, () -> {
                            shakeScreenShort();
                            SpecialEffectsFluff.doFlinchAnimation(guard1);
                            SpecialEffectsFluff.doFlinchAnimation(guard2);
                            doAfterDialogue(850, () -> {
                                Effects.playOnlyParticleAt(guard1.getXCenter(), guard1.getYCenter(), 'Smoke');
                                Effects.playOnlyParticleAt(guard2.getXCenter(), guard2.getYCenter(), 'Smoke');
                                recycleActor(guard1);
                                recycleActor(guard2);
                                final corpse1 = setMiddleActor('UnitActor', 'Guard Dead');
                                corpse1.setX(guard1X);
                                corpse1.setY(guard1FeetY - corpse1.getHeight());
                                corpse1.growTo(-1.5, 1.5, 0);
                                final corpse2 = setMiddleActor('UnitActor', 'Guard Dead');
                                corpse2.setX(guard2X);
                                corpse2.setY(guard2FeetY - corpse2.getHeight());
                                guard3.moveToTop();
                                guard4.moveToTop();
                            });
                        });
                    },
                    () -> {
                        player.moveTo(guard1.getX() - player.getWidth(), player.getY(), 0.5, Easing.expoOut);
                        doAfterDialogue(750, () -> {
                            sayFromKnightAndWait('Hey! What\'s going on?');
                        }); 
                    },
                    () -> sayFromActorAndWait(marceline, '...?'),
                    () -> {
                        pauseDialogueClicking();
                        doMarcelineTeleportEffect(marceline, () -> {
                            player.moveTo(marceline.getX(), player.getY(), 0.5, Easing.expoOut);
                            marceline.growTo(0, 1.5, 0.35, Easing.expoOut);
                            doAfter(350, () -> {
                                recycleActor(marceline);
                                resumeDialogueClicking();
                            });
                        });
                    },
                    () -> sayFromKnightAndWait( 'Dammit! She escaped!'),
                    () -> {
                        guard3.moveTo(getScreenX() + getScreenWidth() - 125, guard3.getY(), 0.75, Easing.expoOut);
                        guard4.moveTo(getScreenX() + getScreenWidth() - 155, guard4.getY(), 0.75, Easing.expoOut);
                        doAfterDialogue(1000, () -> {
                            sayFromKnightAndWait( 'They are dead...');
                        });
                    },
                    () -> sayFromActorAndWait(guard4, 'What have you done?!'),
                    () -> sayFromActorAndWait(guard4, 'You are under arrest, scum!'),
                    () -> {
                        player.moveBy(15, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> {
                            sayFromKnightAndWait('No! You are making a mistake!');
                        });
                    },
                    () -> sayFromActorAndWait(guard4, 'Get him!!')
                ], end);
            }
        },
        {   name: 'King Intro',
            appearCondition: () -> false,   // Can not appear normally
            init: function(andThen: Void -> Void) {
                
                Player.progression.didKingIntro = true;
                setSlideBackground('Images/Backgrounds/Black.png');
                playMusic('TranquilMusic');
                var king: Actor = null;
                
                doSequence([
                    { time: 1500, func: () -> {
                        king = createActor('UnitActor', 'SlideContentLayer');
                        king.growTo(1.5, 1.5, 0, Easing.linear);
                        centerActorOnScreen(king);
                        king.setAnimation('King Erio');
                        king.setFilter([createBrightnessFilter(100)]);
                        king.fadeTo(0, 0, Easing.linear);
                        king.fadeTo(1, 1, Easing.linear);   // Fade in over 1 second
                    }},
                    { time: 4000, func: () -> {
                        fadeOverlayOutWhite(750);
                    }},
                    { time: 1550, func: () -> {
                        king.clearFilters();
                        fadeOverlayIn(2000);
                    }},
                    { time: 2000, func: () -> {
                        sayBubble('I\'ve been expecting you, adventurers.', king.getXCenter(), king.getY() + 25, 2.5);
                    }},
                    { time: 3000, func: () -> {
                        fadeOverlayOutBlack(3000);
                    }},
                    { time: 3000, func: () -> {}}
                ], () -> {
                    hideSlideBackground();
                    NonCombatEvents.setBackground('Images/Backgrounds/Castle.png', 0, -35);
                    fadeOverlayIn(500);
                    recycleActor(king);
                    setMiddleActor('EventActor', 'King', 80, 0);
                    startDialogueAfter(1000, [
                        () -> sayFromEventAndWait('So, we finally meet... murderers...'),
                        () -> {
                            final char = NonCombatEvents.charactersAtEvent[0];
                            char.moveBy(25, 0, 0.3, Easing.expoOut);
                            doAfterDialogue(300, () -> {
                                sayFromCharacterAndWait(0, 'It was not me who killed those guards!');
                            });
                        },
                        () -> {
                            doAfterDialogue(1000, () -> {
                                middleActor.growTo(-1.5, 1.5, 0.3, Easing.expoOut);
                                doAfterDialogue(1000, () -> {
                                    sayFromEventAndWait('I know...');
                                });
                            });
                        },
                        () -> sayFromEventAndWait('It was my daughter...'),
                        () -> sayFromRandomCharacterAndWait('What?!'),
                        () -> {
                            sayFromEventAndWait('I know you came here to help the kingdom...');
                        },
                        () -> {
                            sayFromEventAndWait('...so listen closely.');
                        },
                        () -> {
                            pauseDialogueClicking();
                            

                            function playSlideshow(andThen: Void -> Void) {

                                doAfter(2000, () -> {   // To sync with showSlide
                                    middleActor.disableActorDrawing();
                                    hideCharacterActors();
                                    createDarknessInScene(-25);
                                });
                                showSlides([
                                    { text: 'One day, in the castle...', path: 'Images/Backgrounds/Cutscene/CoverArtCastleOnly.png' },
                                    { text: 'We found a loose floor tile', path: 'Images/Backgrounds/Cutscene/CastleLooseTile.png' },
                                    { text: 'We took it out...', path: 'Images/Backgrounds/Cutscene/CastleTileOut.png' },
                                    { text: 'We were unprepared', path: 'Images/Backgrounds/Cutscene/King.png', isLastSlide: true }
                                ], () -> {
                                    setSlideBackground('Images/Backgrounds/Cutscene/KingWow.png');
                                    slideBackgroundImage.growTo(1.10, 1.10, 0);                  // Grow it to the correct size first
                                    slideBackgroundImage.slideBy(-0.05 * 748, -0.05 * 360, 0);
                                    doAfter(10, () -> {
                                        slideBackgroundImage.growTo(1.20, 1.20, 1 + 2);          // Start expanding ('continue' the expansion from the previous image)
                                        slideBackgroundImage.slideBy(-0.05 * 748, -0.05 * 360, 1 + 2);
                                    });
                                    doAfter(2000, () -> {
                                        fadeOverlayOutBlack(1000, () -> {
                                            hideSlideBackground();
                                            middleActor.enableActorDrawing();
                                            showCharacterActors();
                                            removeDarknessFromScene();
                                            andThen();
                                        });
                                    });
                                });
                            }

                            // Play the cool slideshow explaining the floor tile amd how the horrors happened
                            playSlideshow(() -> {
                                NonCombatEvents.setBackground('Images/Backgrounds/Castle.png');
                                fadeOverlayIn(500, () -> {
                                    doAfter(250, () -> {
                                        sayFromEventAndWait('The horrors that came from beneath the tile...');
                                    });
                                    resumeDialogueClicking();
                                });
                            });
                        },
                        () -> sayFromEventAndWait('They spread, and corrupted the whole kingdom.'),
                        () -> sayFromRandomCharacterAndWait('So what do we do?'),
                        () -> {
                            doAfterDialogue(1000, () -> {
                                middleActor.growTo(1.5, 1.5, 0.3, Easing.expoOut);
                                doAfterDialogue(500, () -> {
                                    sayFromEventAndWait('The tile was shattered into 4 pieces...');
                                });
                            });
                        },
                        () -> {
                            var tile: Actor;
                            pauseDialogueClicking();
                            doSequence([
                                { time: 0, func: () -> fadeOverlayOutWhite(750) },                  // Fade out white
                                { time: 750, func: () -> {                                          // After that, make background black
                                    setSlideBackgroundBlack();
                                    tile = createActor('CinematicTileActor', 'SlideContentLayer');
                                    centerActorOnScreen(tile);
                                    fadeOverlayIn(1000);                                            // Start fading in
                                }},
                                { time: 1000, func: () -> {}},                                      // After fading in...
                                { time: 2000, func: () -> {                                         // Wait 2 more seconds
                                    startShakingScreen(0.01, 2);                                    // Then start shaking screen and change animation
                                    tile.setAnimation('Chipped');
                                }},
                                { time: 1500, func: () -> fadeOverlayOutWhite(500) },               // Fade in white again as if it were an explosion
                                { time: 500, func: () -> {
                                    tile.setAnimation('Shattered');
                                    tile.growTo(1.2, 1.2, 1, Easing.expoOut);
                                    fadeOverlayIn(1500);                                            // Then slowly reveal the shattered tile
                                }},
                                { time: 4000, func: () -> {                                         // Do nothing for 4 seconds
                                    fadeOverlayOutBlack(500);                                       // Then fade out black
                                }},
                                { time: 1000, func: () -> {                                         // And wait 0.500 more seconds..
                                    hideSlideBackground();
                                    recycleActor(tile);
                                    fadeOverlayIn(500);
                                }},
                                { time: 500, func: () -> {}},                                       // After these 500 more milliseconds, all should be back to normal
                                { time: 1500, func: () -> {}}                                       // And wait 1.5 more seconds for cinematic effect suspense
                            ], () -> {
                                resumeDialogueClicking();
                                sayFromEventAndWait('You must find all 4 tile pieces...');
                            });                           
                        },
                        () -> sayFromEventAndWait('...assemble them, then put the tile back in the castle floor.'),
                        () -> {
                            doAfterDialogue(1000, () -> {
                                startShakingScreen(0.02, 1);
                                doAfterDialogue(1000, () -> {
                                    sayFromRandomCharacterAndWait('What was that!?');
                                });
                            });
                        },
                        () -> sayFromEventAndWait('You must hurry!'),
                        () -> sayFromEventAndWait('Seek out Stormjr, the Water Dragon, on the shore.'),
                        () -> sayFromEventAndWait('He will answer any questions you have.'),
                        () -> {
                            king.moveBy(-30, 0, 0.2, Easing.expoOut);
                            doAfterDialogue(300, () -> {
                                sayFromEventAndWait('Go now!');
                            });
                        },
                        () -> sayFromEventAndWait('We shall meet again.')
                    ], () -> {
                        fadeOverlayOutBlack(1000);
                        doAfter(1000, () -> {
                            end();
                        });
                    });
                });
            },
            options: []
        },
        {   name: 'Captain Stashton and Marceline',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                playMusic('PeacefulEncounterMusic');
                NonCombatEvents.setBackground('Images/Backgrounds/Ship.png', 0, -35);
                final marceline = setMiddleActor('EventActor', 'Marceline');
                final stashton  = setMiddleActor('EventActor', 'Captain Stashton');
                stashton.growTo(-1.5, 1.5, 0, Easing.linear);
                stashton.setX(stashton.getX() + 60);
                stashton.setY(stashton.getY() - 2);
                marceline.setX(stashton.getX() + stashton.getWidth() + 20);
                marceline.setY(marceline.getY() + 2);
                final characterXBackups = NonCombatEvents.charactersAtEvent.map(char -> char.getX() - 30);
                for (char in NonCombatEvents.charactersAtEvent) {
                    char.setX(getScreenX() - char.getWidth() - 100);      // Send them out of screen
                }
                startDialogueAfter(1000, [
                    () -> sayFromActorAndWait(marceline, 'For the last time...', 0, 10),
                    () -> sayFromActorAndWait(marceline, 'I am NOT your wife!!', 0, 10),
                    () -> sayFromActorAndWait(stashton, 'Yarrghh... ye are not me wife YET, lassy!', 6),
                    () -> {
                        doAfterDialogue(1000, () -> {
                            for (i in 0...NonCombatEvents.charactersAtEvent.length) {   // Slide them back into the screen
                                final char = NonCombatEvents.charactersAtEvent[i];
                                char.moveTo(characterXBackups[i], char.getY(), 0.5, Easing.expoOut);
                            }
                            doAfterDialogue(1500, () -> {
                                sayFromRandomCharacterAndWait('Hey! I know you!');
                            });
                        });
                    },
                    () -> {
                        stashton.growTo(1.5, 1.5, 0.3, Easing.expoOut);
                        doAfterDialogue(500, () -> {
                            sayFromActorAndWait(marceline, '?...', 0, 10);
                        });
                    },
                    () -> {
                        sayFromActorAndWait(marceline, 'You again?!', 0, 10);
                    },
                    () -> {
                        Effects.playEffectAt(marceline.getXCenter(), marceline.getYCenter() + 30, 'Marceline Teleport', 1450);
                        doAfter(900, () -> {
                            recycleActor(marceline);
                        });
                    },
                    () -> sayFromRandomCharacterAndWait('She\'s the one who killed those guards!'),
                    () -> sayFromActorAndWait(stashton, 'Well, well, well...', -6),
                    () -> sayFromActorAndWait(stashton, 'Who do we have hereghhh...', -6),
                    () -> sayFromActorAndWait(stashton, 'A bunch of eavesdroppers, are ye?', -6),
                    () -> sayFromRandomCharacterAndWait('Who the hell are you?! Some sort of pirate?'),
                    () -> {
                        doAfterDialogue(1000, () -> {
                            sayFromActorAndWait(stashton, '...', -6);
                        });
                    },
                    () -> sayFromActorAndWait(stashton, 'That be Captain Stashton for ye!', -6),
                    () -> {
                        Effects.playOnlyParticleAt(stashton.getXCenter() + 6, stashton.getYCenter() + 6, 'Charm');
                        doAfterDialogue(1000, () -> {
                            sayFromActorAndWait(stashton, 'And that was me sweet wifey...', -6);
                        });
                    },
                    () -> sayFromCharacterAndWait(0, 'But isn\'t she like...'),
                    () -> sayFromCharacterAndWait(0, 'Evil?'),
                    () -> sayFromActorAndWait(stashton, '...', -6),
                    () -> {
                        Effects.playOnlyParticleAt(stashton.getXCenter() + 6, stashton.getYCenter() + 6, 'Charm');
                        doAfterDialogue(1000, () -> {
                            sayFromActorAndWait(stashton, 'She be what every man wishes in his life.', -6);
                        });
                    },
                    () -> sayFromActorAndWait(stashton, 'A big bossomed goth girlfriend... arrr...', -6),
                    () -> {
                        stashton.setAnimation('Captain Stashton Gun');
                        stashton.setX(stashton.getX() - 16 * 1.5);
                        sayFromActorAndWait(stashton, "Can't blame ye for wanting her.", 3);
                    },
                    () -> sayFromActorAndWait(stashton, "But only one man can have 'er.", 3),
                    () -> sayFromActorAndWait(stashton, "ME!!!", 3)
                ], () -> {
                    doAfter(500, () -> {
                        Battlefield.goToBattle('Captain Stashton Partial');
                    });
                });
            }
        },
        {   name: 'Stormjr Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                playMusic('PeacefulEncounterMusic');
                NonCombatEvents.setBackground('Images/Backgrounds/Beach.png', 0, -55);
                setMiddleActor('UnitActor', 'Stormjr', 120, 35);
                for (actor in NonCombatEvents.charactersAtEvent) {
                    actor.setY(actor.getY() + 10);
                }
                startDialogueAfter(1000, [
                    () -> sayFromStormjrAndWait('My defeat was imminent, and I thank you for it.'),
                    () -> sayFromStormjrAndWait('However, your victory is only temporary.'),
                    () -> sayFromStormjrAndWait('The vampire lord, count Spatula holds our souls hostage.'),
                    () -> {
                        pauseDialogueClicking();
                        showSlides([
                            { text: '', path: 'Images/Backgrounds/Cutscene/CoverArtCastleOnly.png' },
                            { text: '', path: 'Images/Backgrounds/Cutscene/CountSpatulaWhite.png' },
                            { text: '', path: 'Images/Backgrounds/Black.png', isLastSlide: true }
                        ], () -> {
                            fadeOverlayOutBlack(0, () -> {
                                fadeOverlayIn(500, () -> {
                                    sayFromStormjrAndWait('Next time we meet, you will have to defeat me again.');
                                    resumeDialogueClicking();
                                });
                            });
                        });
                    },
                    () -> sayFromStormjrAndWait('This cycle will continue until count Spatula is slain.'),
                    () -> sayFromStormjrAndWait('Deep within the castle...'),
                    () -> sayFromStormjrAndWait('That is where you will find him.'),
                    () -> {
                        doAfterDialogue(1500, () -> {
                            sayFromStormjrAndWait('Now then...');
                        });
                    },
                    () -> sayFromStormjrAndWait('Take the Tile Shard!'),
                    () -> {
                        pauseDialogueClicking();
                        showTilePiecesUnlocked(1, () -> {
                            resumeDialogueClicking();
                        });
                    },
                    () -> sayFromStormjrAndWait('Now, let me to die.'),
                    () -> sayFromStormjrAndWait('I shall return.')
                ], end);
            }
        },
        {   name: 'Stormjr 3',
            appearCondition: function() return false,
            options: [
                {   title: 'Your Brother',
                    appearCondition: () -> Player.progression.didStormjrAskWhoIsYourBrother == false,
                    description: 'Who is your brother, Stormjr?',
                    onChoose: function() {
                        hideOptions();
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('Who is your brother, Stormjr?'),
                            () -> doAfterDialogue(500, () -> {
                                sayFromStormjrAndWait('Poof...');
                            }),
                            () -> sayFromStormjrAndWait('It is Tyl, the Tile Demon.'),
                            () -> sayFromRandomCharacterAndWait('What!?'),
                            () -> sayFromStormjrAndWait('As I am the water dragon...'),
                            () -> sayFromStormjrAndWait('...he was the fire dragon.'),
                            () -> sayFromStormjrAndWait('But his affairs with evil magicks and the lord of Hell...'),
                            () -> sayFromStormjrAndWait('They turned him evil.'),
                            () -> sayFromStormjrAndWait('He is now but an undead husk.'),
                            () -> sayFromStormjrAndWait('Body of a skeleton.'),
                            () -> sayFromStormjrAndWait('Mind of a demon.')
                        ], () -> {
                            Player.progression.didStormjrAskWhoIsYourBrother = true;
                            reloadOptions();
                        });
                    }
                },
                {   title: 'Tyl',
                    appearCondition: () -> Player.progression.didStormjrAskWhoIsYourBrother && Player.progression.didStormjrAskHowDoWeDefeatTyl == false,
                    description: 'How do we defeat Tyl?',
                    onChoose: function() {
                        hideOptions();
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('How do we defeat your brother?'),
                            () -> doAfterDialogue(500, () -> {
                                sayFromStormjrAndWait('Poof...');
                            }),
                            () -> sayFromStormjrAndWait('He might not be manifested into this world yet.'),
                            () -> sayFromStormjrAndWait('Assembling the Tile should summon him here.'),
                            () -> sayFromStormjrAndWait('He bleeds like any other being.'),
                            () -> sayFromRandomCharacterAndWait('Is that a good idea? To summon him?'),
                            () -> sayFromStormjrAndWait('I refrain from answering that.'),
                            () -> sayFromStormjrAndWait('It is but your choice.')
                        ], () -> {
                            Player.progression.didStormjrAskHowDoWeDefeatTyl = true;
                            reloadOptions();
                        });
                    }
                },
                {   title: 'Lord of Hell',
                    appearCondition: () -> Player.progression.didStormjrAskHowDoWeDefeatTyl && Player.progression.didStormjrAskWhoIsLordOfHell == false,
                    description: 'Who is the lord of Hell?',
                    onChoose: function() {
                        hideOptions();
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('Who is this lord of Hell?'),
                            () -> doAfterDialogue(500, () -> {
                                sayFromStormjrAndWait('Poof...');
                            }),
                            () -> sayFromStormjrAndWait('His name is Natas.'),
                            () -> sayFromRandomCharacterAndWait('Ah, kind of like Satan but backwards.'),
                            () -> sayFromStormjrAndWait('Although Hell is his home, he roams these lands.'),
                            () -> sayFromStormjrAndWait('Usually takes his dogs for a walk at night.'),
                            () -> sayFromRandomCharacterAndWait('He just... walks around the kingdom?'),
                            () -> sayFromStormjrAndWait('Yes.'),
                            () -> sayFromStormjrAndWait('He loves a nice sunset on the beach.'),
                            () -> sayFromRandomCharacterAndWait('Won\'t he kill us if he sees us?'),
                            () -> sayFromStormjrAndWait("I doubt it. He's not that bad."),
                            () -> sayFromStormjrAndWait('My brother is way worse, believe me, mortals.')
                        ], () -> {
                            Player.progression.didStormjrAskWhoIsLordOfHell = true;
                            reloadOptions();
                        });
                    }
                },
                {   title: 'Goodbye',
                    appearCondition: () -> Player.progression.didStormjrAskWhoIsLordOfHell,
                    description: 'Leave.',
                    onChoose: function() {
                        hideOptions();
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('Thank you, Stormjr.'),
                            () -> sayFromStormjrAndWait('We shall meet again, mortals.'),
                            () -> sayFromStormjrAndWait('But I fear that next time I will not have the power to abstain.'),
                            () -> sayFromRandomCharacterAndWait('Fare well.')
                        ], () -> {
                            Player.progression.didStormjr3Dialogue = true;
                            end();
                        });
                    }
                },
            ],
            init: function(andThen: Void -> Void) {
                playMusic('PeacefulEncounterMusic');
                NonCombatEvents.setBackground('Images/Backgrounds/Beach.png', 0, -55);
                setMiddleActor('UnitActor', 'Stormjr', 120, 35);
                startDialogueAfter(1000, [
                    () -> sayFromStormjrAndWait('I am done fighting, heroes!'),
                    () -> sayFromStormjrAndWait('I tire of all this chaos.'),
                    () -> sayFromRandomCharacterAndWait('You will not fight us?'),
                    () -> sayFromStormjrAndWait('No, I will not.'),
                    () -> sayFromStormjrAndWait('I will resist this corruption!'),
                    () -> sayFromStormjrAndWait('You are free to go!'),
                    () -> sayFromRandomCharacterAndWait('Hold up!'),
                ], andThen);
            }
        },
        {   name: 'Marceline Meeting',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                playMusic('PeacefulEncounterMusic');
                NonCombatEvents.setBackground('Images/Backgrounds/Cave.png', 0, -35);
                final marceline = setMiddleActor('EventActor', 'Marceline');
                marceline.setX(marceline.getX() + 60);
                final marcelineY = marceline.getY();
                startDialogueAfter(1000, [
                    () -> sayFromActorAndWait(marceline, 'You...'),
                    () -> sayFromActorAndWait(marceline, 'You are after the Tile pieces.'),
                    () -> {
                        final hero = NonCombatEvents.charactersAtEvent[0];
                        hero.moveTo(hero.getX() + 25, hero.getY(), 0.5, Easing.expoOut);
                        doAfterDialogue(400, () -> {
                            sayFromActorAndWait(hero, 'You\'re the murderer!');
                        });
                    },
                    () -> {
                        marceline.growTo(1.5, 1.35, 0.25, Easing.expoOut);
                        marceline.moveTo(marceline.getX(), marceline.getY() + (0.15/2) * marceline.getHeight(), 0.25, Easing.expoOut);
                        sayFromActorAndWait(marceline, 'You still care about it?');
                    },
                    () -> sayFromActorAndWait(marceline, 'Don\'t you see the world...'),
                    () -> {
                        marceline.growTo(1.5, 1.5, 0.25, Easing.expoOut);
                        marceline.moveTo(marceline.getX(), marcelineY, 0.25, Easing.expoOut);
                        sayFromActorAndWait(marceline, '...IS ENDING!?');
                    },
                    () -> sayFromRandomCharacterAndWait('Hmm...'),
                    () -> sayFromActorAndWait(marceline, 'Listen,'),
                    () -> sayFromActorAndWait(marceline, 'I will do ANYTHING to destroy this cursed kingdom.'),
                    () -> sayFromRandomCharacterAndWait('That sounds quite evil.'),
                    () -> sayFromActorAndWait(marceline, 'My father sold me as a wife to the pirate king, Captain Stashton.'),
                    () -> sayFromRandomCharacterAndWait('Why would he do that!?'),
                    () -> {
                        marceline.growTo(-1.5, 1.5, 0.25, Easing.expoOut);
                        sayFromActorAndWait(marceline, 'Do me a favor...');
                    },
                    () -> sayFromActorAndWait(marceline, 'Kill Captain Stashton, and I will tell you everything.'),
                    () -> sayFromRandomCharacterAndWait('How can we catch him?'),
                    () -> sayFromActorAndWait(marceline, 'The next time you visit the beaches...'),
                    () -> sayFromActorAndWait(marceline, '...the path to him will be revealed to you.'),
                    () -> {
                        sayFromRandomCharacterAndWait('But-');
                        final tp = createActor('SpecialEffectActor', 'Particles');
                        tp.setAnimation('Marceline Teleport');
                        tp.growTo(1.5, 1.5, 0, Easing.linear);
                        tp.setXCenter(marceline.getXCenter());
                        tp.setYCenter(marceline.getYCenter());
                        doAfter(800, () -> {
                            marceline.growTo(0, 1.5, 0.35, Easing.expoOut);
                        });
                        doAfter(1150, () -> {
                            recycleActor(marceline);
                            recycleActor(tp);
                        });
                    },
                    () -> sayFromRandomCharacterAndWait('Guess we\'ll have to return later.'),
                    () -> sayFromRandomCharacterAndWait('What is this, a roguelike?'),
                    () -> sayFromRandomCharacterAndWait('Come on. Let\'s find that vampire lord, Spatula, first.'),
                ], () -> {
                    Player.progression.didMarcelineEncounter = true;
                    end();
                });
            }
        },
        {   name: 'Spatula 1 Before',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                NonCombatEvents.setBackground('Images/Backgrounds/Church.png', 0, -35);
                createDarknessInScene(-25);
                final spatula = setMiddleActor('EventActor', 'Count Spatula');
                final spatulaX = spatula.getX() + 60;
                spatula.setX(getScreenX() + getScreenWidth());
                startDialogueAfter(1000, [
                    () -> sayFromRandomCharacterAndWait('We have arrived.'),
                    () -> sayFromRandomCharacterAndWait('Show yourself!'),
                    () -> {
                        spatula.moveTo(spatulaX, spatula.getY(), 8, Easing.linear);
                        doAfterDialogue(8500, () -> {
                            sayFromSpatulaAndWait(spatula, 'I have been exthpecting you, adventurers...');
                        });
                    },
                    () -> sayFromRandomCharacterAndWait('We have come for you, unholy monster!'),
                    () -> sayFromRandomCharacterAndWait('Prepare to die!'),
                    () -> {
                        doAfterDialogue(1000, () -> {
                            spatula.setAnimation('Count Spatula Defeated');
                            sayFromSpatulaAndWait(spatula,  'Unholy? Ah, a church person I see...');
                        });
                    },
                    () -> sayFromSpatulaAndWait(spatula, 'Too bad. The whole church serves Marceline now!'),
                    () -> sayFromSpatulaAndWait(spatula, 'I... I serve Marceline...'),
                    () -> {
                        doAfterDialogue(500, () -> {
                            spatula.setAnimation('Count Spatula');
                            sayFromSpatulaAndWait(spatula, 'I think...');
                        });
                    },
                    () -> sayFromRandomCharacterAndWait("You don't even know who you serve?"),
                    () -> {
                        spatula.setAnimation('Count Spatula Confused');
                        sayFromSpatulaAndWait(spatula, 'NO NO! I serve Marceline! I promise!');
                    },
                    () -> sayFromSpatulaAndWait(spatula, 'But... I don\'t remember the rest...'),
                    () -> sayFromSpatulaAndWait(spatula, 'I was brought here by an ancient demon...'),
                    () -> {
                        turn(spatula);
                        spatula.setAnimation('Count Spatula');
                        sayFromSpatulaAndWait(spatula, 'But... Marceline offered me such tremendous powers...');
                    },
                    () -> {
                        getCharacter(0).moveBy(20, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> {
                            sayFromCharacterAndWait(0, "Ancient demon?!");
                        });
                    },
                    () -> {
                        unturn(spatula);
                        spatula.moveBy(-25, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> {
                            sayFromSpatulaAndWait(spatula, 'Enough talk!!');
                        });
                    },
                    () -> sayFromSpatulaAndWait(spatula, 'Now, I shall ecthecute you!!!')
                ], () -> {
                    Battlefield.goToBattle('Count Spatula');
                });
            }
        },
        {   name: 'Spatula 1 Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                NonCombatEvents.setBackground('Images/Backgrounds/Church.png', 0, -35);
                createDarknessInScene(-25);
                final spatula = setMiddleActor('EventActor', 'Count Spatula Scared');
                final king = setMiddleActor('EventActor', 'King Crouched');
                king.setX(getScreenXRight());
            
                startDialogueAfter(1000, [
                    () -> sayFromRandomCharacterAndWait('You are done for, Count Spatula!'),
                    () -> sayFromRandomCharacterAndWait('Now, who is that demon you were talking about?'),
                    () -> {
                        spatula.setAnimation('Count Spatula');
                        sayFromSpatulaAndWait(spatula, 'It is Tyl, the Tile Demon!');
                    },
                    () -> sayFromRandomCharacterAndWait('Tile demon?'),
                    () -> {
                        pauseDialogueClicking();
                        sayFromSpatula(spatula, 'Yes...', 2);
                        doAfter(2250, () -> {
                            spatula.setAnimation('Count Spatula Defeated');
                            sayFromSpatula(spatula, 'But you are too late!', 2);
                        });
                        doAfter(4500, () -> {
                            king.moveTo(spatula.getX() + 50, king.getY(), 8, Easing.linear);
                            sayFromSpatula(spatula, 'No matter how many times you kill me, I shall rise again!', 4);
                        });
                        doAfter(8500, () -> {
                            sayFromSpatula(spatula, 'For I am Count Spatula, lord of vampires and undeath!', 3);
                        });
                        doAfter(11500, () -> {
                            sayFromSpatula(spatula, 'And I have all the power to acth-', 2);
                        });
                        doAfter(13500, () -> {
                            Unit.jotActor(king, LEFT);
                            flashWhite(spatula, 100);
                            playAudio('HitAudio');
                            final spX = spatula.getX(), spY = spatula.getY();
                            doAfter(100, () -> {
                                playAudio('VampireDeathAudio');
                                SpecialEffectsFluff.doFlinchAnimation(spatula, () -> {
                                    Effects.playOnlyParticleAt(spatula.getXCenter(), spatula.getYCenter(), 'Smoke');
                                    recycleActor(spatula);
                                    playAudio('BatDeathAudio');
                                    final bats: Array<Actor> = [];
                                    for (i in 0...5) {
                                        final bat = createActor('UnitActor', 'CharactersLayer');
                                        bat.setAnimation('Bat');
                                        bat.growTo(1.5, 1.5, 0, Easing.linear);
                                        bat.setX(spX); bat.setY(spY);
                                        final moveY = if (i % 2 == 0) getScreenY() - 50 else (getScreenYBottom() + 50);
                                        final moveX = randomIntBetween(int(getScreenX()), int(getScreenXRight()));
                                        bat.moveTo(moveX, moveY, 1.5, Easing.linear);
                                    }
                                });
                            });
                        });
                        doAfter(15000, () -> {
                            king.setAnimation('King');
                            king.setY(getScreenYCenter() - king.getHeight() * 1.25 + NonCombatEvents.k.feetYFromCenter);
                            sayFromActorAndWait(king, 'So, the church is corrupted as well.');
                            resumeDialogueClicking();
                        });
                    },
                    () -> sayFromActorAndWait(king, 'And this demon, Tyl, is at the core of it...'),
                    () -> sayFromRandomCharacterAndWait('What about your daughter, Marceline?'),
                    () -> {
                        turn(king);
                        sayFromActorAndWait(king, 'Poor Marceline...');
                    },
                    () -> sayFromActorAndWait(king, 'The ancient corruption got to her early on...'),
                    () -> sayFromRandomCharacterAndWait('You sold her to the pirate king!'),
                    () -> {
                        doAfterDialogue(2000, () -> {
                            sayFromActorAndWait(king, 'Yes.');
                        });
                    },
                    () -> sayFromActorAndWait(king, 'I am ashamed of this.'),
                    () -> sayFromActorAndWait(king, 'I only wanted to protect her.'),
                    () -> sayFromActorAndWait(king, 'She was not safe inside the castle walls.'),
                    () -> {
                        doAfterDialogue(2000, () -> {
                            unturn(king);
                            sayFromActorAndWait(king, 'Listen, adventurers.');
                        });
                    },
                    () -> sayFromActorAndWait(king, 'The high priest, Father Almund must be destroyed.'),
                    () -> sayFromActorAndWait(king, 'He is the head of the corrupted church.'),
                    () -> sayFromActorAndWait(king, 'Without him, the church\'s corruption will surely recede.'),
                    () -> sayFromActorAndWait(king, 'Find him in the villages.'),
                    () -> sayFromActorAndWait(king, 'But beware! His children protect him.'),
                    () -> sayFromActorAndWait(king, 'And they are vile, foul, wicked...'),
                    () -> sayFromActorAndWait(king, 'Show them no mercy!'),
                    () -> {
                        doAfterDialogue(2000, () -> {
                            king.moveBy(-15, 0, 0.25, Easing.expoOut);
                            doAfterDialogue(200, () -> {
                                sayFromActorAndWait(king, 'Go now!');
                            });
                        });
                    },
                    () -> sayFromActorAndWait(king, 'Worry not. We will meet again, I am sure.'),
                ], end);
            }
        },

        {   name: 'Blessed Children Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                NonCombatEvents.setBackground('Images/Backgrounds/Church.png', 0, -15);
                final king = setMiddleActor('UnitActor', 'King Erio', 90, 0);
                startDialogueAfter(1000, [
                    () -> sayFromEventAndWait('Hmm.'),
                    () -> sayFromEventAndWait('It seems Father Almund has another Tile Shard.'),
                    () -> {
                        doAfterDialogue(500, () -> {
                            turn(king);
                        });
                        doAfterDialogue(1750, () -> {
                            unturn(king);
                            sayFromEventAndWait('Heroes,');
                        });
                    },
                    () -> sayFromEventAndWait('There is an ancient ritual to reveal Father Almund.'),
                    () -> sayFromEventAndWait('But you will need to defeat Count Spatula again.'),
                    () -> sayFromRandomCharacterAndWait('Again?'),
                    () -> sayFromRandomCharacterAndWait('But we already killed him once!'),
                    () -> {
                        doAfterDialogue(500, () -> {
                            turn(king);
                        });
                        doAfterDialogue(1000, () -> {
                            sayFromEventAndWait('No...');
                        });
                    },
                    () -> sayFromEventAndWait('He can not just die.'),
                    () -> sayFromEventAndWait('No matter how many times you kill him, he will be revived by Marceline.'),
                    () -> sayFromRandomCharacterAndWait('What!?'),
                    () -> {
                        doAfterDialogue(500, () -> {
                            unturn(king);
                            sayFromEventAndWait('We need his ashes.');
                        });
                    },
                    () -> sayFromEventAndWait('When we get his ashes, we can do the ritual and reveal Almund.'),
                    () -> sayFromRandomCharacterAndWait('We better get to it, then.'),
                    () -> sayFromEventAndWait('Let us meet again, after your task is complete.'),
                    () -> {
                        turn(king);
                        king.moveBy(50, 0, 2, Easing.linear);
                        doAfterDialogue(2000, () -> {
                            sayFromEventAndWait('Oh! One more thing!');
                        });
                    },
                    () -> sayFromEventAndWait('Count Spatula will be stronger this time.'),
                    () -> {
                        unturn(king);
                        sayFromEventAndWait('Expect heavy resistance.');
                    },
                    () -> sayFromRandomCharacterAndWait('We will get this over with.')
                ], end);
            }
        },
        {   name: 'Captain Stashton Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                NonCombatEvents.setBackground('Images/Backgrounds/Ship.png', 0, -35);
                for (c in NonCombatEvents.charactersAtEvent) {
                    c.setX(c.getX() + 35);
                }
                final stashton  = setMiddleActor('EventActor', 'Captain Stashton', 60, 0);
                startDialogueAfter(1000, [
                    () -> sayFromActorAndWait(stashton, 'Yahaharghh...', -6),
                    () -> sayFromActorAndWait(stashton, 'This was not the end of me!', -6),
                    () -> sayFromActorAndWait(stashton, 'Have me Tile Shard, but leave sweet Marceline alone!', -6),
                    () -> sayFromRandomCharacterAndWait('She is corrupetd by the eldritch powers from the castle!'),
                    () -> sayFromRandomCharacterAndWait('She is a threat to the whole kingdom!'),
                    () -> sayFromActorAndWait(stashton, 'Aye!', -6),
                    () -> sayFromActorAndWait(stashton, 'She be a strong woman...', -6),
                    () -> sayFromActorAndWait(stashton, 'So strong...', -6),
                    () -> sayFromActorAndWait(stashton, '...she broke that Tile into 4 pieces!', -6),
                    () -> sayFromRandomCharacterAndWait('What!?'),
                    () -> sayFromRandomCharacterAndWait('She is the one who broke the Tile?!'),
                    () -> sayFromActorAndWait(stashton, 'Yes! What a strong woman, am I right?', -6),
                    () -> sayFromRandomCharacterAndWait('But why!?'),
                    () -> sayFromRandomCharacterAndWait('By breaking the Tile, she let loose all the evil underneath it!'),
                    () -> sayFromActorAndWait(stashton, 'As mysterious as she is strong...', -6),
                    () -> {
                        pauseDialogueClicking();
                        showTilePiecesUnlocked(2, () -> {
                            sayFromActor(stashton, 'Adios!', 2);
                            final anchor = setMiddleActor('UnitActor', 'Anchor');
                            anchor.setXCenter(stashton.getXCenter());
                            anchor.setY(getScreenY() - anchor.getHeight());
                            final chainXOrigin = anchor.getXCenter() + 33;
                            final chainYOrigin = anchor.getY() - 50;
                            final chain = createActor('LightningEffectActor', 'CharactersLayer');
                            chain.setAnimation('AnchorChainLarge');
                            doEvery(20, () -> {
                                stretchActorBetweenPoints(chain, chainXOrigin, chainYOrigin, anchor.getXCenter() + 33, anchor.getY() + -22);
                            });
                            anchor.moveTo(anchor.getX(), stashton.getY() + stashton.getHeight() * 0.66, 0.5, Easing.expoOut);
                            doAfterDialogue(500, () -> {
                                shakeScreenShort();
                                doAfterDialogue(500, () -> {
                                    anchor.moveTo(anchor.getX(), chainYOrigin, 0.5, Easing.quadIn);
                                    stashton.moveTo(stashton.getX(), chainYOrigin, 0.5, Easing.quadIn);
                                    doAfterDialogue(500, () -> {
                                        sayFromRandomCharacterAndWait('Nice.');
                                    });
                                });
                            });
                        });
                    }
                ], end);
            }
        },
        {   name: 'Marceline Meeting 2',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                NonCombatEvents.setBackground('Images/Backgrounds/Cave.png', 0, -35);
                final marceline = setMiddleActor('EventActor', 'Marceline');
                marceline.setX(marceline.getX() + 60);
                final marcelineY = marceline.getY();
                startDialogueAfter(1000, [
                    () -> sayFromActorAndWait(marceline, 'Hi.'),
                    () -> sayFromRandomCharacterAndWait('You again?'),
                    () -> sayFromActorAndWait(marceline, 'Thanks for kicking that jerk\'s butt.'),
                    () -> sayFromActorAndWait(marceline, 'Now, then...'),
                    () -> {
                        turn(marceline);
                        marceline.moveBy(25, 0, 0.35, Easing.expoOut);
                        doAfterDialogue(350, () -> {
                            sayFromActorAndWait(marceline, "I'll get back to destroying my father's kingdom.");
                        });
                    },
                    () -> {
                        getCharacter(0).moveBy(15, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> {
                            sayFromCharacterAndWait(0, 'Wait!');
                        });
                    },
                    () -> sayFromCharacterAndWait(0, 'You promised to tell us:'),
                    () -> sayFromCharacterAndWait(0, 'Why are you doing this?'),
                    () -> {
                        doAfterDialogue(1000, () -> {
                            unturn(marceline);
                            sayFromActorAndWait(marceline, "Alright.");
                        });
                    },
                    () -> {
                        function playSlideshow(andThen: Void -> Void) {
                            doAfterDialogue(2000, () -> {   // To sync with showSlide
                                middleActor.disableActorDrawing();
                                hideCharacterActors();
                                createDarknessInScene(-25);
                            });
                            showSlides([
                                { text: 'Hundreds of years ago', path: 'Images/Backgrounds/Cutscene/MarcelineExplainHistory/1HundredsOfYearsAgo.png' },
                                { text: 'My ancestors made a pact...', path: 'Images/Backgrounds/Cutscene/MarcelineExplainHistory/2AncestorsMadePact.png' },
                                { text: '... with Tyl, the Tile Demon', path: 'Images/Backgrounds/Cutscene/MarcelineExplainHistory/3Tyl.png' },
                                { text: 'Thus, the kingdom arose', path: 'Images/Backgrounds/Cutscene/MarcelineExplainHistory/4TimeHasCome.png', isLastSlide: true },
                            ], () -> {
                                fadeOverlayOutBlack(0, () -> {
                                    hideSlideBackground();
                                    middleActor.enableActorDrawing();
                                    showCharacterActors();
                                    removeDarknessFromScene();
                                    fadeOverlayIn(1000, () -> {
                                        andThen();
                                    });
                                });
                            });
                        }
                        
                        pauseDialogueClicking();
                        playSlideshow(() -> {
                            U.showInterstitialAndLoadNext();
                            resumeDialogueClicking();
                            sayFromActorAndWait(marceline, "And now the time has come to pay the price.");
                        });
                    },
                    () -> sayFromActorAndWait(marceline, 'Tyl, the Tile Demon wants to redeem the kingdom.'),
                    () -> sayFromActorAndWait(marceline, "That's the reason for all the corruption."),
                    () -> sayFromActorAndWait(marceline, "That's why the vegetables are turning evil."),
                    () -> sayFromActorAndWait(marceline, "That's why the church has turned to sin."),
                    () -> sayFromRandomCharacterAndWait("So when the King excavated the Tile..."),
                    () -> sayFromRandomCharacterAndWait("The corruption came to get the kingdom."),
                    () -> sayFromActorAndWait(marceline, "Exactly."),
                    () -> {
                        turn(marceline);
                        sayFromActorAndWait(marceline, "It was inevitable.");
                    },
                    () -> sayFromActorAndWait(marceline, "I broke the Tile into 4 pieces and made use of all the chaos."),
                    () -> sayFromActorAndWait(marceline, "To destroy the kingdom."),
                    () -> sayFromActorAndWait(marceline, "And with the power of a Tile Shard, I can do it."),
                    () -> sayFromRandomCharacterAndWait("What happens if we assemble the 4 pieces and put the Tile back?"),
                    () -> sayFromActorAndWait(marceline, "If you put the Tile back where it was..."),
                    () -> sayFromActorAndWait(marceline, "You will stop the corruption."),
                    () -> sayFromRandomCharacterAndWait("Perfect!"),
                    () -> {
                        unturn(marceline);
                        sayFromActorAndWait(marceline, "NO!!!");
                    },
                    () -> sayFromActorAndWait(marceline, "It will only be a matter of time-"),
                    () -> sayFromActorAndWait(marceline, "-until someone else finds it."),
                    () -> sayFromActorAndWait(marceline, "And this chaos will return!"),
                    
                    () -> {
                        marceline.moveBy(-25, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(750, () -> {
                            sayFromActorAndWait(marceline, "One day in the future-");
                        });
                    },
                    () -> sayFromActorAndWait(marceline, "-someone will find the Tile again."),
                    () -> sayFromActorAndWait(marceline, "And the corruption will emerge once more."),
                    () -> sayFromActorAndWait(marceline, "Everything we fought for will be in vain."),
                    
                    () -> sayFromActorAndWait(marceline, "Do you understand now??"),
                    () -> sayFromActorAndWait(marceline, "The only solution is to destroy the kingdom!"),
                    () -> sayFromActorAndWait(marceline, "And end this Pact once and for all!"),
                    () -> sayFromRandomCharacterAndWait("So you want to destroy the kingdom so the demon can't have it?"),
                    () -> sayFromActorAndWait(marceline, "Exactly!"),
                    () -> {
                        getCharacter(0).moveBy(15, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> {
                            sayFromCharacterAndWait(0, "There must be another way!");
                        });
                    },
                    () -> {
                        marceline.moveBy(-25, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(750, () -> {
                            sayFromActorAndWait(marceline, "There is no other way!!");
                        });
                    },
                    () -> sayFromActorAndWait(marceline, "This kingdom is a ticking time bomb!"),
                    () -> sayFromRandomCharacterAndWait("There is a way..."),
                    () -> sayFromRandomCharacterAndWait("Let us destroy Tyl, the Tile Demon..."),
                    () -> sayFromRandomCharacterAndWait("...together!!!"),
                    () -> sayFromActorAndWait(marceline, "Then you're a bunch of fools!"),
                    () -> sayFromActorAndWait(marceline, "And I have wasted my time here."),
                    () -> {
                        sayFromRandomCharacterAndWait('But-');
                        doMarcelineTeleportEffect(marceline, () -> {
                            marceline.growTo(0, 1.5, 0.35, Easing.expoOut);
                            doAfter(350, () -> {
                                recycleActor(marceline);
                            });
                        });
                    },
                    () -> sayFromRandomCharacterAndWait("Dammit, she left again!"),
                    () -> sayFromRandomCharacterAndWait("Come, let's find Count Spatula."),
                    () -> sayFromRandomCharacterAndWait("We'll leave Marceline for later.")
                ], () -> {
                    Player.progression.didMarcelineEncounter2 = true;
                    end();
                });
            }
        },
        {   name: 'Spatula 2 Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                NonCombatEvents.setBackground('Images/Backgrounds/Church.png', 0, -35);
                createDarknessInScene(-25);
                var spatula = setMiddleActor('EventActor', 'Count Spatula Scared', 35, 0);
                final king = setMiddleActor('EventActor', 'King');
                king.setX(getScreenXRight());
                startDialogueAfter(1000, [
                    () -> sayFromRandomCharacterAndWait('You are done for, Count Spatula!'),
                    () -> sayFromSpatulaScaredAndWait(spatula, 'Noo...'),
                    () -> sayFromSpatulaScaredAndWait(spatula, 'My powers weaken...'),
                    () -> sayFromRandomCharacterAndWait('Let go of the monsters\' souls!'),
                    () -> sayFromSpatulaScaredAndWait(spatula, 'I want to... but...'),
                    () -> sayFromSpatulaScaredAndWait(spatula, 'But I can\'t...'),
                    () -> {
                        getCharacter(0).moveBy(15, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> sayFromCharacterAndWait(0, 'Do it!! Free dragon Stormjr\'s soul!'));
                    },
                    () -> {
                        spatula.moveBy(10, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> {
                            sayFromSpatulaScaredAndWait(spatula, 'Ok! Ok!');
                        });
                    },
                    () -> sayFromSpatulaScaredAndWait(spatula, 'In the name of Marceline...'),
                    () -> sayFromSpatulaScaredAndWait(spatula, 'I abandon my control over Stormjr\'s soul...'),
                    () -> sayFromRandomCharacterAndWait('Yes!'),
                    () -> {
                        spatula.setAnimation('Count Spatula Defeated');
                        sayFromSpatulaScaredAndWait(spatula, 'And I forward it to Tyl, the Tile Demon!');
                    },
                    () -> sayFromRandomCharacterAndWait('OH, COME ON!!'),
                    () -> {
                        pauseDialogueClicking();
                        sayFromSpatulaScared(spatula, 'But you have not seen the end of me, adventurers!', 3);
                        doAfter(3500, () -> {
                            spatula.moveBy(25, 0, 0.5, Easing.expoOut);
                            doAfter(500, () -> {
                                sayFromSpatulaScared(spatula, 'For I am Count Spatula, lord of blood and eternal hunger!', 3);
                            });
                        });
                        doAfter(7500, () -> {
                            king.moveTo(spatula.getX() + 50, king.getY(), 4, Easing.linear);
                            sayFromSpatulaScared(spatula, 'No matter how many times you kill me, I shall rise again!', 4);
                        });
                        
                        doAfter(11500, () -> {
                            sayFromSpatulaScared(spatula, 'I shall raise from the dead and-', 2);
                        });
                        doAfter(12500, () -> {
                            Unit.jotActor(king, LEFT);
                            Effects.sendArcMissileCustomAndThen({
                                actorName: 'MissileActor',
                                missileName: 'Giant Spoon',
                                from: new Point(king.getXCenter(), king.getYCenter()),
                                to: new Point(spatula.getXCenter(), spatula.getYCenter()),
                                speed: Effects.SLOW,
                                onActorCreated: spoon -> spoon.growTo(1.5, 1.5, 0, Easing.linear),
                                andThen: () -> {
                                    flashWhite(spatula, 100);
                                    playAudio('HitAudio');
                                    final spX = spatula.getX(), spY = spatula.getY();
                                    doAfter(100, () -> {
                                        playAudio('VampireDeathAudio');
                                        SpecialEffectsFluff.doFlinchAnimation(spatula, () -> {
                                            Effects.playOnlyParticleAt(spatula.getXCenter(), spatula.getYCenter(), 'Smoke');
                                            recycleActor(spatula);
                                            playAudio('BatDeathAudio');
                                            final bats: Array<Actor> = [];
                                            for (i in 0...5) {
                                                final bat = createActor('UnitActor', 'CharactersLayer');
                                                bat.setAnimation('Bat');
                                                bat.growTo(1.5, 1.5, 0, Easing.linear);
                                                bat.setX(spX); bat.setY(spY);
                                                final moveY = if (i % 2 == 0) getScreenY() - 50 else (getScreenYBottom() + 50);
                                                final moveX = randomIntBetween(int(getScreenX()), int(getScreenXRight()));
                                                bat.moveTo(moveX, moveY, 1.5, Easing.linear);
                                            }
                                            doAfter(1500, () -> {
                                                king.moveBy(-50, 0, 0.5, Easing.expoOut);
                                                doAfter(500, () -> {
                                                    sayFromKingAndWait(king, 'Good work, adventurers!');
                                                    resumeDialogueClicking();
                                                });
                                            });
                                        });
                                    });
                                }
                            });
                        });
                    },
                    () -> sayFromKingAndWait(king, 'Now, we have the ashes necessary to reveal Father Almund.'),
                    () -> sayFromRandomCharacterAndWait('Hold up.'),
                    () -> sayFromRandomCharacterAndWait('Tyl, the Tile Demon is the master of it all!'),
                    () -> sayFromKingAndWait(king, 'It seems so...'),
                    () -> sayFromRandomCharacterAndWait('And you lied to us about the Tile.'),
                    () -> sayFromRandomCharacterAndWait('It was actually Marceline who broke the tile...'),
                    () -> sayFromRandomCharacterAndWait('...to keep you away from putting it back...'),
                    () -> sayFromRandomCharacterAndWait('...and postponing the evil.'),
                    () -> {
                        king.moveBy(15, 0, 0.25, Easing.expoOut);
                        turn(king);
                        doAfterDialogue(2000, () -> {
                            sayFromKingAndWait(king, 'Yes. I know.');
                        });
                    },
                    () -> sayFromKingAndWait(king, 'I feared you would not understand.'),
                    () -> sayFromKingAndWait(king, 'But you have to believe me.'),
                    () -> {
                        king.moveBy(15, 0, 0.25, Easing.expoOut);
                        unturn(king);
                        doAfterDialogue(250, () -> {
                            sayFromKingAndWait(king, 'It was for her good, and the good of the kingdom.');
                        });
                    },
                    () -> sayFromKingAndWait(king, 'Either we assemble the tile and seal the evil temporarily...'),
                    () -> sayFromKingAndWait(king, '...or we destroy the kingdom, so Tyl can\'t have it.'),
                    () -> {
                        king.moveBy(-25, 0, 0.5, Easing.expoOut);
                        unturn(king);
                        doAfterDialogue(500, () -> {
                            sayFromKingAndWait(king, 'If you were the king, what would you choose?');
                        });
                    },
                    () -> sayFromRandomCharacterAndWait('...'),
                    () -> sayFromKingAndWait(king, 'I thought so.'),
                    () -> {
                        king.moveBy(25, 0, 0.5, Easing.quadOut);
                        doAfterDialogue(500, () -> {
                            sayFromKingAndWait(king, 'Alright then.');
                        });
                    },
                    () -> sayFromKingAndWait(king, 'We have 2 Tile Shards.'),
                    () -> sayFromKingAndWait(king, 'Only 2 remain to be found.'),
                    () -> sayFromKingAndWait(king, 'Father Almund has one...'),
                    () -> sayFromKingAndWait(king, 'And Marceline has the last one.'),
                    () -> sayFromKingAndWait(king, 'Go back to the villages.'),
                    () -> {
                        king.moveBy(35, 0, 0.5, Easing.quadOut);
                        turn(king);
                        doAfterDialogue(500, () -> {
                            sayFromKingAndWait(king, 'I will perform the ritual offscreen...');
                        });
                    },
                    () -> sayFromKingAndWait(king, '...and the path to Almund will be revealed.'),
                    () -> sayFromKingAndWait(king, 'But I feel we will have to make a grave choice soon...')
                ], end);
            }
        },

        {   name: 'Father Almund Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                playMusic('TranquilMusic');
                NonCombatEvents.setBackground('Images/Backgrounds/Church.png', 0, -35);
                var almund = setMiddleActor('UnitActor', 'Father Almund', 50, 0);
                startDialogueAfter(1000, [
                    () -> sayFromRandomCharacterAndWait('It is over, Father.'),
                    () -> sayFromRandomCharacterAndWait('Give us the Tile Shard and we shall be on our way.'),
                    () -> {
                        turn(almund);
                        sayFromFatherAlmundAndWait('Oh, my Lord and Savior...', true);
                    },
                    () -> sayFromRandomCharacterAndWait('There he goes again...'),
                    () -> sayFromFatherAlmundAndWait('My knees weaken...', true),
                    () -> sayFromFatherAlmundAndWait('My arms grow heavy...', true),
                    () -> {
                        unturn(almund);
                    },
                    () -> sayFromFatherAlmundAndWait('I feel... something coming from my inside...'),
                    () -> sayFromFatherAlmundAndWait('An evil waiting to break loose...'),
                    () -> {
                        pauseDialogueClicking();
                        sayFromActor(almund, 'BLEAPGH!', 2, 18);
                        Unit.jotActor(almund, LEFT);
                        final from = new Point(almund.getXCenter(), almund.getYCenter());
                        final to = new Point(almund.getX() - 30, almund.getY() + almund.getHeight());
                        Effects.playOnlyParticleAt(from.x, from.y, 'Vomit');
                        Effects.sendArcMissileCustomAndThen({
                            from: from, to: to,
                            actorName: 'MissileActor',
                            missileName: 'Tile Shard',
                            speed: Effects.MEDIUM,
                            onActorCreated: function(t: Actor) t.growTo(1.5, 1.5),
                            andThen: function() {
                                final tileShard = createActor('MissileActor', 'CharactersLayer');
                                tileShard.setAnimation('Tile Shard');
                                tileShard.setX(to.x);
                                tileShard.setY(to.y);
                                sayFromRandomCharacterAndWait('Eww!');
                                resumeDialogueClicking();
                            }
                        });
                    },
                    () -> sayFromRandomCharacterAndWait('You had swallowed that?'),
                    () -> sayFromFatherAlmundAndWait('Oh...'),
                    () -> {
                        turn(almund);
                        doAfterDialogue(1000, () -> {
                            unturn(almund);
                            doAfterDialogue(1000, () -> {
                                sayFromFatherAlmundAndWait('Who are you?');
                            });
                        });
                    },
                    () -> sayFromRandomCharacterAndWait('We have come for the Tile Shard, Father.'),
                    () -> sayFromFatherAlmundAndWait('Oh, forgive me.'),
                    () -> sayFromFatherAlmundAndWait('You can have it now.'),
                    () -> {
                        pauseDialogueClicking();
                        showTilePiecesUnlocked(3, () -> {
                            resumeDialogueClicking();
                        });
                    },
                    () -> sayFromFatherAlmundAndWait('I know you might have questions...'),
                    () -> sayFromFatherAlmundAndWait('...I shall try to answer.'),
                    () -> sayFromRandomCharacterAndWait('Do you control the church?'),
                    () -> sayFromFatherAlmundAndWait('Now, that\'s a good question!'),
                    () -> {
                        turn(almund);
                        doAfterDialogue(1000, () -> {
                            sayFromFatherAlmundAndWait('Do I control the church?', true);
                        });
                    },
                    () -> sayFromRandomCharacterAndWait('...'),
                    () -> {
                        unturn(almund);
                        doAfterDialogue(1000, () -> {
                            sayFromFatherAlmundAndWait('I sure do.');
                        });
                    },
                    () -> sayFromRandomCharacterAndWait('So will you stop the commonfolk from hunting us?'),
                    () -> sayFromFatherAlmundAndWait('Sure, I could do that.'),
                    () -> sayFromRandomCharacterAndWait('Perfect!'),
                    () -> sayFromFatherAlmundAndWait('I will talk to the peasants on the outskirts.'),
                    () -> sayFromFatherAlmundAndWait('I can convince some of them.'),
                    () -> sayFromFatherAlmundAndWait('But I can not stop their passion.'),
                    () -> sayFromFatherAlmundAndWait('They do what their heart tells them.'),
                    () -> sayFromRandomCharacterAndWait('Thank you, Father.'),
                    () -> sayFromRandomCharacterAndWait('We will be on our way.'),
                    () -> sayFromFatherAlmundAndWait('Take care, strangers!'),
                    () -> sayFromRandomCharacterAndWait('Only 1 Tile Shard left to find...')
                ], end);
            }
        },
        {   name: 'King Plead Meeting',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                playMusic('PeacefulEncounterMusic');
                NonCombatEvents.setBackground('Images/Backgrounds/Cutscene/CastleWithWindow.png', 0, 0);
                NonCombatEvents.backgroundImage.setY(getScreenY());
                final king = setMiddleActor('EventActor', 'King');
                turn(king);
                final tylSayX = getScreenXCenter() + 125;
                final tylSayY = getScreenY() + 72;
                final tyl = createActor('UnitActor', 'UnderBackgroundLayer');
                tyl.setAnimation('Tyl');
                tyl.growTo(1.5, 1.5, 0);
                tyl.setFilter([createTintFilter(Utils.getColorRGB(0, 0, 0), 1)]);   // Make him completely black
                tyl.setX(tylSayX);
                tyl.setY(tylSayY);
                final originalCharacterPositions = NonCombatEvents.charactersAtEvent.map(c -> new Point(c.getX(), c.getY()));
                for (c in NonCombatEvents.charactersAtEvent) c.setX(c.getX() - getScreenWidth() / 2);
                startDialogueAfter(1000, [
                    () -> sayAtAndWait('All your kingdom is belong to us.', tylSayX, tylSayY),
                    () -> sayFromActorAndWait(king, 'Begone, fiend!'),
                    () -> sayAtAndWait('Your fate is sealed.', tylSayX, tylSayY),
                    () -> {
                        tyl.moveBy(100, 0, 3, Easing.expoIn);
                    },
                    () -> {
                        for (i in 0...originalCharacterPositions.length) {
                            NonCombatEvents.charactersAtEvent[i].moveTo(originalCharacterPositions[i].x, originalCharacterPositions[i].y, 1, Easing.expoOut);
                        }
                        doAfterDialogue(1500, () -> {
                            unturn(king);
                            king.moveBy(35, 0, 0.5, Easing.expoOut);
                            doAfterDialogue(500, () -> {
                                sayFromActorAndWait(king, "Heroes...");
                            });
                        });
                    },
                    () -> sayFromRandomCharacterAndWait('What was that?'),
                    () -> sayFromActorAndWait(king, "The presence of Tyl, the Tile Demon, is becoming stronger."),
                    () -> sayFromActorAndWait(king, "We must move quickly, heroes!"),
                    () -> sayFromActorAndWait(king, "Have you defeated Almund and got his Tile Shard?"),
                    () -> sayFromRandomCharacterAndWait('We have.'),
                    () -> sayFromActorAndWait(king, "Then we got 3. Only 1 more to go..."),
                    () -> {
                        turn(king);
                        doAfterDialogue(1500, () -> {
                            sayFromActorAndWait(king, "Heroes...");
                        });
                    },
                    () -> {
                        doAfterDialogue(500, () -> {
                            sayFromActorAndWait(king, "I will ask you the impossible for a father.");
                        });
                    },
                    () -> {
                        unturn(king);
                        doAfterDialogue(500, () -> {
                            sayFromActorAndWait(king, "You must defeat my daughter, Marceline.");
                        });
                    },
                    () -> sayFromActorAndWait(king, 'And take the final Tile Shard from her.'),
                    () -> sayFromRandomCharacterAndWait('Are you sure, king Erio?'),
                    () -> {
                        turn(king);
                        doAfterDialogue(1500, () -> {
                            sayFromActorAndWait(king, "I am.");
                        });
                    },
                    () -> sayFromActorAndWait(king, 'What must be done, must be done.'),
                    () -> {
                        U.showInterstitialAndLoadNext();
                        unturn(king);
                        sayFromActorAndWait(king, 'Show mercy.');
                    },
                    () -> sayFromActorAndWait(king, 'May the odds be in your favor.')
                ], () -> {
                    Player.progression.didKingPleadEncounter = true;
                    end();
                });
            }
        },
        {   name: 'King or Marceline Battle',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                setSlideBackground('Images/Backgrounds/Black.png');
                trace('Initing..');
                doAfter(1000, () -> {
                    trace('Eh?');
                    if (Player.progression.sidedWith == 'Marceline') {
                        trace('To battle!');
                        Battlefield.goToBattle('King Erio');
                    } else {
                        trace('To battle eee!');
                        Battlefield.goToBattle('Marceline');
                    }
                });
            }

        },
        {   name: 'King vs Marceline',
            appearCondition: function() return false,
            options: [
                {   title: 'The King',
                    description: 'Side with King Erio. You will try to defeat Marceline, take her final Tile Shard and seal the corruption beneath the castle.',
                    onChoose: function() {
                        final king: Actor = NonCombatEvents.data.king;
                        final marceline: Actor = NonCombatEvents.data.marceline;
                        hideOptions();
                        startDialogue([
                            () -> sayFromActorAndWait(king, 'It is done then, heroes.'),
                            () -> sayFromActorAndWait(king, 'Will you help me, heroes?'),
                            () -> sayFromRandomCharacterAndWait('We will help you, King Erio.'),
                            () -> sayFromActorAndWait(marceline, "Fools!"),
                            () -> sayFromActorAndWait(marceline, "Your lives are over!"),
                            () -> {
                                sayFromRandomCharacterAndWait('But-');
                                final tp = createActor('SpecialEffectActor', 'Particles');
                                tp.setAnimation('Marceline Teleport');
                                tp.growTo(1.5, 1.5, 0, Easing.linear);
                                tp.setXCenter(marceline.getXCenter());
                                tp.setYCenter(marceline.getYCenter());
                                doAfter(800, () -> {
                                    marceline.growTo(0, 1.5, 0.35, Easing.expoOut);
                                });
                                doAfter(1150, () -> {
                                    recycleActor(marceline);
                                    recycleActor(tp);
                                });
                            },
                            () -> {
                                U.showInterstitialAndLoadNext();
                                turn(king);
                                sayFromActorAndWait(king, 'Find her, heroes.');
                            },
                            () -> sayFromActorAndWait(king, 'And put an end to this madness.'),
                        ], () -> {
                            Player.progression.sidedWith = 'King';
                            end();
                        });
                    }
                },
                {   title: 'Marceline',
                    description: 'Side with Marceline. You will try to defeat King Erio and use the power of the Tile to destroy the kingdom, so Tyl can\'t have it.',
                    onChoose: function() {
                        final king: Actor = NonCombatEvents.data.king;
                        final marceline: Actor = NonCombatEvents.data.marceline;
                        hideOptions();
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('We will help you, Marceline.'),
                            () -> sayFromActorAndWait(marceline, "Yes!"),
                            () -> sayFromActorAndWait(marceline, "It is over, father!"),
                            () -> sayFromActorAndWait(marceline, "I shall prepare for your demise!"),
                            () -> {
                                sayFromRandomCharacterAndWait('But-');
                                final tp = createActor('SpecialEffectActor', 'Particles');
                                tp.setAnimation('Marceline Teleport');
                                tp.growTo(1.5, 1.5, 0, Easing.linear);
                                tp.setXCenter(marceline.getXCenter());
                                tp.setYCenter(marceline.getYCenter());
                                doAfter(800, () -> {
                                    marceline.growTo(0, 1.5, 0.35, Easing.expoOut);
                                });
                                doAfter(1150, () -> {
                                    recycleActor(marceline);
                                    recycleActor(tp);
                                });
                            },
                            () -> sayFromActorAndWait(king, 'I suppose your mind is already made.'),
                            () -> {
                                turn(king);
                                sayFromActorAndWait(king, 'Very well.');
                            },
                            () -> {
                                king.moveBy(35, 0, 2);
                                doAfterDialogue(2500, () -> {
                                    sayFromActorAndWait(king, 'I shall be at the castle. Waiting.');
                                });
                            },
                            () -> {
                                U.showInterstitialAndLoadNext();
                                sayFromActorAndWait(king, "Do what must be done.");
                            },
                        ], () -> {
                            king.moveBy(35, 0, 2);
                            Player.progression.sidedWith = 'Marceline';
                            end();
                        });
                    }
                },
            ],
            init: function(andThen: Void -> Void) {
                playMusic('PeacefulEncounterMusic');
                NonCombatEvents.setBackground('Images/Backgrounds/Cave.png', 0, -35);
                final king  = setMiddleActor('EventActor', 'King', 35);
                final marceline = setMiddleActor('EventActor', 'Marceline', 100);
                turn(king);
                NonCombatEvents.data = { marceline: marceline, king: king };

                startDialogueAfter(1000, [
                    () -> sayFromActorAndWait(marceline, 'Stop this nonsense!'),
                    () -> sayFromActorAndWait(marceline, "Can't you see!?"),
                    () -> sayFromActorAndWait(marceline, "You can't postpone this forever!"),
                    () -> sayFromActorAndWait(king, 'Marceline, my daughter...'),
                    () -> sayFromActorAndWait(marceline, "Spare me, father!"),
                    () -> sayFromActorAndWait(king, 'Please, just hand in the Tile Shard...'),
                    () -> sayFromActorAndWait(king, '...and we can live happily for the rest of our lives!'),
                    () -> {
                        marceline.moveBy(-10, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> {
                            sayFromActorAndWait(marceline, 'And what of the next king?');
                        });
                    },
                    () -> sayFromActorAndWait(marceline, "The future of your kingdom is doomed, father!"),
                    () -> {
                        doAfterDialogue(1000, () -> {
                            unturn(king);
                            doAfterDialogue(500, () -> {
                                sayFromActorAndWait(king, 'Heroes...');
                            });
                        });
                    },
                    () -> sayFromActorAndWait(marceline, "Adventurers..."),
                    () -> sayFromActorAndWait(king, 'I suppose it is your choice, heroes.'),
                    () -> sayFromActorAndWait(king, 'Help me assemble the Tile-'),
                    () -> sayFromActorAndWait(king, '-and seal Tyl back beneath the castle.'),
                    () -> sayFromActorAndWait(marceline, "No!"),
                    () -> sayFromActorAndWait(marceline, "Help ME destroy the kingdom so Tyl can\'t have it!")
                ], () -> {
                    andThen();
                });
            }
        },
        {   name: 'Marceline Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                playMusic('PeacefulEncounterMusic');
                NonCombatEvents.setBackground('Images/Backgrounds/Cutscene/CastleWithHole.png', 0, 0);
                final king = setMiddleActor('EventActor', 'King');
                turn(king, true);
                final marceline = setMiddleActor('EventActor', 'Marceline Defeated', 80);
                final tyl = setMiddleActor('UnitActor', 'Tyl', 15, 45);
                tyl.disableActorDrawing();
                startDialogueAfter(1000, [
                    () -> sayFromActorAndWait(king, 'It is over, Marceline.'),
                    () -> sayFromActorAndWait(king, 'The Tile Shard is ours.'),
                    () -> {
                        pauseDialogueClicking();
                        doAfterDialogue(1000, () -> {
                            marceline.disableActorDrawing();
                            king.setX(king.getX() + 55);
                            unturn(king, true);
                        });
                        showTilePiecesUnlocked(4, () -> {
                            resumeDialogueClicking();
                        });
                    },
                    () -> sayFromActorAndWait(king, 'We did it heroes!'),
                    () -> sayFromActorAndWait(king, 'The Tile is complete!'),
                    () -> sayFromRandomCharacterAndWait("That's it! We won!"),
                    () -> sayFromRandomCharacterAndWait("Quickly! Put the Tile over that hole!"),
                    () -> {
                        doAfterDialogue(1000, () -> {
                            turn(king);
                            doAfterDialogue(1000, () -> {
                                sayFromActorAndWait(king, 'I...');
                            });
                        });
                    },
                    () -> {
                        unturn(king);
                        doAfterDialogue(250, () -> {
                            sayFromActorAndWait(king, "I am afraid I can't do that, heroes.");
                        });
                    },
                    () -> sayFromRandomCharacterAndWait("What!?"),
                    () -> sayFromActorAndWait(king, "Tyl!!!"),
                    () -> sayFromActorAndWait(king, "I summon thee!"),
                    () -> sayFromActorAndWait(king, "Show yourself!!!"),
                    () -> {
                        fadeOverlayOutWhite(500, () -> {
                            for (c in NonCombatEvents.charactersAtEvent) c.setX(c.getX() - 25);
                            king.setX(king.getX() + 105);
                            king.setY(king.getY() + 15);
                            tyl.enableActorDrawing();
                            tyl.bringToFront();
                            king.moveToTop();
                            fadeOverlayIn(1000, () -> {
                                sayFromTylAndWait(tyl, "I am summoned.");
                            });
                        });
                    },
                    () -> sayFromActorAndWait(king, "As I promised, here is the Tile."),
                    () -> {
                        turn(tyl, () -> {
                            tyl.setAnimation('Tyl Reverse');
                            tyl.growTo(1.5, 1.5, 0);
                        });
                        sayFromTylAndWait(tyl, "Good.", true);
                    },
                    () -> sayFromRandomCharacterAndWait("What!?"),
                    () -> sayFromActorAndWait(king, "Now, your end of the bargain."),
                    () -> sayFromActorAndWait(king, "You will make me regent King of this kingdom..."),
                    () -> sayFromActorAndWait(king, "...for eternity."),
                    () -> {
                        doAfterDialogue(1000, () -> {
                            sayFromTylAndWait(tyl, "No.", true);
                        });
                    },
                    () -> sayFromTylAndWait(tyl, "You're a terrible father, King Erio.", true),
                    () -> sayFromTylAndWait(tyl, "You're an even worse king.", true),
                    () -> sayFromActorAndWait(king, "But... we had an agreement..."),
                    () -> sayFromTylAndWait(tyl, "Fool.", true),
                    () -> sayFromTylAndWait(tyl, 'This kingdom is mine.', true),
                    () -> sayFromTylAndWait(tyl, 'MINE!', true),
                    () -> {
                        final tylPoint = new Point(tyl.getXCenter(), tyl.getYCenter());
                        final kingPoint = new Point(king.getXCenter(), king.getYCenter());
                        final c1Point = new Point(getCharacter(0).getXCenter(), getCharacter(0).getYCenter());
                        final c2Point = new Point(getCharacter(1).getXCenter(), getCharacter(1).getYCenter());
                        
                        Effects.sendMissileAndThen(tylPoint, c1Point, 'Crystal Shot', Effects.MEDIUM, () -> {
                            doExplosionEffect(c1Point.x, c1Point.y);
                        });
                        Effects.sendMissileAndThen(tylPoint, c2Point, 'Crystal Shot', Effects.MEDIUM, () -> {
                            doExplosionEffect(c2Point.x, c2Point.y);
                        });
                        Effects.sendMissileAndThen(tylPoint, kingPoint, 'Crystal Shot', Effects.MEDIUM, () -> {
                            doExplosionEffect(kingPoint.x, kingPoint.y);
                            fadeOverlayOutWhite(500, end);
                        });
                    }
                ], end);
            }
        },
        {   name: 'King Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                playMusic('PeacefulEncounterMusic');
                NonCombatEvents.setBackground('Images/Backgrounds/Castle.png', 0, 0);
                final king = setMiddleActor('EventActor', 'King', 80);
                final marceline = setMiddleActor('EventActor', 'Marceline');
                final tyl = setMiddleActor('UnitActor', 'Tyl', 0, 45);
                marceline.setX(getCharacter(0).getX() + getCharacter(0).getWidth());
                turn(marceline);
                marceline.disableActorDrawing();
                tyl.disableActorDrawing();
                startDialogueAfter(1000, [
                    () -> sayFromActorAndWait(king, 'Enough!'),
                    () -> sayFromActorAndWait(king, 'I surrender!'),
                    () -> {
                        sayFromRandomCharacterAndWait('It is ov-');
                        final tp = createActor('SpecialEffectActor', 'Particles');
                        tp.setAnimation('Marceline Teleport');
                        tp.growTo(1.5, 1.5, 0, Easing.linear);
                        tp.setXCenter(marceline.getXCenter());
                        tp.setYCenter(marceline.getYCenter());
                        doAfter(900, () -> {
                            marceline.enableActorDrawing();
                        });
                        doAfter(1150, () -> {
                            recycleActor(tp);
                        });
                    },
                    () -> sayFromActorAndWait(marceline, 'It is over, father!'),
                    () -> sayFromActorAndWait(king, 'Take what you want, and leave!'),
                    () -> sayFromActorAndWait(king, 'I hereby forfeit this kingdom!'),
                    () -> sayFromActorAndWait(king, 'Done, ok!?'),
                    () -> sayFromActorAndWait(king, 'Do what you want with it!!'),
                    () -> {
                        pauseDialogueClicking();
                        unturn(marceline);
                        doAfter(500, () -> {
                            turn(marceline);
                        });
                        doAfter(1000, () -> {
                            unturn(marceline);
                        });
                        doAfter(500, () -> {
                            turn(marceline);
                        });
                        doAfter(500, () -> {
                            sayFromActorAndWait(marceline, 'Yes!!');
                            resumeDialogueClicking();
                        });
                    },
                    () -> sayFromActorAndWait(marceline, 'We did it, adventurers!'),
                    () -> sayFromActorAndWait(marceline, 'Now...'),
                    () -> sayFromActorAndWait(marceline, 'We can use the power of the Tile...'),
                    () -> sayFromActorAndWait(marceline, '...to blow up the kingdom!!!'),
                    () -> {
                        pauseDialogueClicking();
                        doAfter(1000, () -> {
                            king.disableActorDrawing();
                        });
                        showTilePiecesUnlocked(4, () -> {
                            resumeDialogueClicking();
                        });
                    },
                    () -> sayFromActorAndWait(marceline, 'I will activate the Tile!'),
                    () -> {
                        pauseDialogueClicking();
                        sayFromActor(marceline, 'Brace yourselves!!', 2);
                        startShakingScreen(0.01, 4);
                        doAfter(3000, () -> {
                            sayFromActor(marceline, 'Yes!!', 2);
                        });
                        doAfter(6000, () -> {
                            turn(marceline);
                            doAfter(750, () -> {
                                unturn(marceline);
                            });
                            doAfter(1500, () -> {
                                sayFromActorAndWait(marceline, 'Wh-what happened?');
                                resumeDialogueClicking();
                            });
                        });
                    },
                    () -> sayFromActorAndWait(marceline, "It's not working..."),
                    () -> {
                        marceline.moveBy(20, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> {
                            sayFromActorAndWait(marceline, "WHY IS IT NOT WORKING!?");
                        });
                    },
                    () -> sayAtAndWait('Fools.', getScreenXCenter(), getScreenYCenter() - 35),
                    () -> {
                        sayFromRandomCharacterAndWait('What was that?');
                        turn(getCharacter(1));
                    },
                    () -> {
                        fadeOverlayOutWhite(1000, () -> {
                            tyl.enableActorDrawing();
                            for (c in NonCombatEvents.charactersAtEvent) {
                                c.setX(c.getX() - 55);
                            }
                            unturn(getCharacter(1));
                            marceline.setX(marceline.getX() + 105);
                            marceline.setY(marceline.getY() + 15);
                            marceline.moveToTop();
                            fadeOverlayIn(2000, () -> {
                                sayFromTylAndWait(tyl, 'I thank you, foolish girl.');
                            });
                        });
                    },
                    () -> sayFromTylAndWait(tyl, 'You gave me enough time to awaken.'),
                    () -> sayFromTylAndWait(tyl, 'And by assembling the tile...'),
                    () -> sayFromTylAndWait(tyl, 'You have summoned me into this world.'),
                    () -> sayFromActorAndWait(marceline, 'What!?'),
                    () -> sayFromTylAndWait(tyl, 'This kingdom is mine.'),
                    () -> sayFromTylAndWait(tyl, 'MINE!'),
                    () -> {
                        final tylPoint = new Point(tyl.getXCenter(), tyl.getYCenter());
                        final marcelinePoint = new Point(marceline.getXCenter(), marceline.getYCenter());
                        final c1Point = new Point(getCharacter(0).getXCenter(), getCharacter(0).getYCenter());
                        final c2Point = new Point(getCharacter(1).getXCenter(), getCharacter(1).getYCenter());
                        
                        Effects.sendMissileAndThen(tylPoint, c1Point, 'Crystal Shot', Effects.MEDIUM, () -> {
                            doExplosionEffect(c1Point.x, c1Point.y);
                        });
                        Effects.sendMissileAndThen(tylPoint, c2Point, 'Crystal Shot', Effects.MEDIUM, () -> {
                            doExplosionEffect(c2Point.x, c2Point.y);
                        });
                        Effects.sendMissileAndThen(tylPoint, marcelinePoint, 'Crystal Shot', Effects.MEDIUM, () -> {
                            doExplosionEffect(marcelinePoint.x, marcelinePoint.y);
                            fadeOverlayOutWhite(500, end);
                        });
                    }
                    

                ], end);
            }
        },

        {   name: 'King Meeting Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                NonCombatEvents.setBackground('Images/Backgrounds/Forest.png', 0, 45);
                final king = setMiddleActor('EventActor', 'King', 24, 5);
                turn(king, true);
                startDialogueAfter(1000, [
                    () -> sayFromRandomCharacterAndWait('Sire...'),
                    () -> sayFromActorAndWait(king, "Don't look at me, heroes!"),
                    () -> sayFromActorAndWait(king, "I am filled with shame and guilt!"),
                    () -> sayFromRandomCharacterAndWait('Our job is not done, King Erio.'),
                    () -> sayFromActorAndWait(king, "King!?"),
                    () -> {
                        unturn(king, () -> {
                            sayFromActorAndWait(king, "I am no king!");
                        });
                    },
                    () -> sayFromActorAndWait(king, "And without my crown..."),
                    () -> {
                        turn(king);
                        sayFromActorAndWait(king, "I am nothing.");
                    },
                    () -> sayFromRandomCharacterAndWait('You can still be the father you never were.'),
                    () -> {
                        sayFromActor(king, "*sigh*", 2);
                        doAfterDialogue(2500, () -> {
                            unturn(king);
                            sayFromActorAndWait(king, "Heroes...");
                        });
                    },
                    () -> sayFromActorAndWait(king, "Defeat Tyl."),
                    () -> sayFromActorAndWait(king, "Avenge me."),
                    () -> {
                        king.moveBy(-15, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> sayFromActorAndWait(king, "Avenge the kingdom!"));
                    },
                    () -> {
                        king.moveBy(-15, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> sayFromActorAndWait(king, "Put an end to this, once and for all!"));
                    },
                    () -> sayFromRandomCharacterAndWait('We will.'),
                    () -> sayFromRandomCharacterAndWait('We have to go now.'),
                    () -> sayFromActorAndWait(king, "Wait!"),
                    () -> {
                        doItemToInventoryAnimation('Icons/KingSeal.png', king.getXCenter(), king.getYCenter());
                        sayFromActorAndWait(king, "Take this Seal!");
                    },
                    () -> sayFromActorAndWait(king, "It will grant you access to the Tile room."),
                    () -> sayFromActorAndWait(king, "That is likely where Tyl is hiding."),
                    () -> {
                        U.showInterstitialAndLoadNext();
                        turn(king, () -> {
                            sayFromActorAndWait(king, "Good luck, heroes.");
                        });
                    },
                ], () -> {
                    Player.progression.didKingDefeatedEncounter = true;
                    end();
                });
            }
        },
        {   name: 'Marceline Meeting Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                NonCombatEvents.setBackground('Images/Backgrounds/Cave.png', 0, 0);
                final marceline = setMiddleActor('EventActor', 'Marceline Defeated', 80);
                turn(marceline, true);
                final target = setMiddleActor('EventActor', 'Effigy', 150);
                pauseDialogueClicking();
                doAfter(1000, () -> {
                    Unit.jotActor(marceline, RIGHT);
                    playAudio('HitAudio');
                    flashWhite(target, 100);
                });
                doAfter(2000, () -> {
                    Unit.jotActor(marceline, RIGHT);
                    playAudio('HitAudio');
                    flashWhite(target, 100);
                });
                doAfter(3500, () -> {
                    Unit.jotActor(marceline, RIGHT);
                    playAudio('HitAudio');
                    flashWhite(target, 100);
                });
                doAfter(5000, () -> {
                    turn(marceline);
                    resumeDialogueClicking();
                });
                startDialogueAfter(6000, [
                    () -> sayFromActorAndWait(marceline, 'What do you want?'),
                    () -> sayFromActorAndWait(marceline, 'Everything has failed.'),
                    () -> {
                        unturn(marceline, () -> {
                            sayFromActorAndWait(marceline, 'It is over.');
                        });
                    },
                    () -> sayFromRandomCharacterAndWait('There is still a chance.'),
                    () -> {
                        getCharacter(0).moveBy(10, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> {
                            sayFromCharacterAndWait(0, "We will defeat Tyl, with or without your help.");
                        });
                    },
                    () -> {
                        turn(marceline, () -> {
                            doAfterDialogue(1500, () -> {
                                sayFromActorAndWait(marceline, 'I called you fools for wanting that before.');
                            });
                        });
                    },
                    () -> sayFromActorAndWait(marceline, 'But I was the foolish one all along.'),
                    () -> {
                        doAfterDialogue(1000, () -> {
                            unturn(marceline, () -> {
                                sayFromActorAndWait(marceline, 'Have this.');
                                doItemToInventoryAnimation('Icons/MarcelineRevival.png', marceline.getXCenter(), marceline.getYCenter());
                            });
                        });
                    },
                    () -> sayFromActorAndWait(marceline, "It will give you a random spell every run."),
                    () -> sayFromActorAndWait(marceline, "I don't need it anymore."),
                    () -> sayFromActorAndWait(marceline, "It shall serve you better."),
                    () -> {
                        U.showInterstitialAndLoadNext();
                        marceline.moveBy(-15, 0, 0.25, Easing.expoOut);
                        doAfterDialogue(250, () -> {
                            sayFromActorAndWait(marceline, "Go now!");
                        });
                    },
                    () -> sayFromActorAndWait(marceline, "Succeed where I have failed."),
                    () -> sayFromActorAndWait(marceline, "Good luck."),
                    () -> {
                        sayFromRandomCharacterAndWait('Tha-');
                        final tp = createActor('SpecialEffectActor', 'Particles');
                        tp.setAnimation('Marceline Teleport');
                        tp.growTo(1.5, 1.5, 0, Easing.linear);
                        tp.setXCenter(marceline.getXCenter());
                        tp.setYCenter(marceline.getYCenter());
                        doAfter(800, () -> {
                            marceline.growTo(0, 1.5, 0.35, Easing.expoOut);
                        });
                        doAfter(1150, () -> {
                            recycleActor(marceline);
                            recycleActor(tp);
                        });
                    },
                    () -> sayFromRandomCharacterAndWait("..."),
                    () -> sayFromRandomCharacterAndWait("Let's go.")
                ], () -> {
                    Player.progression.didMarcelineDefeatedEncounter = true;
                    end();
                });
            }
        },
        {   name: 'Tyl Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                playMusic('DarkTensionMusic');
                for (c in NonCombatEvents.charactersAtEvent) {
                    c.setX(c.getX() - 40);
                }
                NonCombatEvents.setBackground('Images/Backgrounds/Cutscene/CastleWithHole.png', 0, 0);
                final king = setMiddleActor('EventActor', 'King', -15);
                final marceline = setMiddleActor('EventActor', 'Marceline', -55, 15);
                turn(marceline, true);
                final tyl = setMiddleActor('UnitActor', 'Tyl', 12, 30);
                king.disableActorDrawing();
                marceline.disableActorDrawing();
                final button = new SUIButton('GenericMenuButtonActor', 'UI');
                button.setText('FINISH HIM', getFont(BROWN_ON_BROWN_TITLE_FONT), BUTTON_TEXT_Y);
                button.setSceneXCenter(getScreenXCenter());
                button.setBottom(45);
                button.hide();
                final willard = setMiddleActor('ShopkeepActor', 'Merchant Walking');
                willard.disableActorDrawing();
                final documents = setMiddleActor('EventActor', 'Documents', 0, 15);
                documents.disableActorDrawing();
                function sayTylAndWait(sayWhat) {
                    sayFromActorAndWait(tyl, sayWhat, -30, -15);
                }
                final holeCenterX = getScreenXCenter() - 90;
                final holeCenterY = getScreenYCenter() + 75;
                startDialogueAfter(1000, [
                    () -> sayTylAndWait('What is this!?'),
                    () -> sayTylAndWait('What are these powers!?'),
                    if (Player.progression.defeatedNatas) (() -> sayTylAndWait('Did Natas help you out!?')) else null,
                    () -> advanceAndSayAndWait(getCharacter(0), 20, 'They are your doing, Tyl!'),
                    () -> sayFromRandomCharacterAndWait('All this venturing through the kingdom has trained us...'),
                    () -> sayFromRandomCharacterAndWait('...for our final opponent:'),
                    () -> sayFromRandomCharacterAndWait('You!'),
                    () -> sayTylAndWait('Nooo!!!'),
                    () -> sayTylAndWait('This cannot be!!!'),
                    () -> {
                        sayFromRandomCharacterAndWait('It su-');
                        doMarcelineTeleportEffect(marceline, () -> {
                            marceline.enableActorDrawing();
                        });
                    },
                    () -> sayFromActorAndWait(marceline, 'It sure can be, Tyl!'),
                    () -> {
                        final sword = createActor('UnitActor', 'ParticlesLayer');
                        sword.setAnimation('Spectral Sword');
                        sword.growTo(1.5, 1.5, 0);
                        final swordLandingY = tyl.getY() + tyl.getHeight() - sword.getHeight();
                        sword.setXCenter(tyl.getXCenter());
                        sword.setY(swordLandingY - 40);
                        sword.moveTo(sword.getX(), swordLandingY, 0.35, Easing.expoIn);
                        doAfter(350, () -> {
                            shakeScreenShort();
                            Effects.playOnlyParticleAt(sword.getXCenter(), sword.getY() + sword.getHeight(), 'Smoke');
                            playAudio('HitAudio');
                            sayTylAndWait('Gaaah!');
                            recycleActor(sword);
                            flashWhite(tyl, 100);
                        });
                    },
                    () -> {
                        king.enableActorDrawing();
                        king.setAnimation('King Crouched');
                        king.setX(getScreenX() + getScreenWidth());
                        king.moveTo(tyl.getX() + tyl.getWidth() - 35, king.getY(), 6, Easing.linear);
                        doAfterDialogue(500, () -> {
                            sayTylAndWait('How did you even get here!?');
                        });
                    },
                    () -> sayTylAndWait('Is this...'),
                    () -> sayTylAndWait('Is this the end?'),
                    () -> {
                        button.show();
                        sayFromRandomCharacterAndWait('It is.');
                    },
                    () -> {
                        button.hide();
                        Unit.jotActor(king, LEFT);
                        Effects.sendArcMissileCustomAndThen({
                            from: getActorCenterPoint(king),
                            to: getActorCenterPoint(tyl),
                            actorName: 'UnitActor',
                            missileName: 'Giant Cheerio',
                            speed: Effects.MEDIUM,
                            onActorCreated: function(cheerio: Actor) {
                                cheerio.growTo(0.5, 0.5, 0);
                                doAfter(10, () -> {
                                    cheerio.growTo(1.5, 1.5, 0.25, Easing.linear);
                                });
                            },
                            andThen: function() {
                                pauseDialogueClicking();
                                king.setAnimation('King');
                                doExplosionEffect(tyl.getXCenter(), tyl.getYCenter());
                                sayTylAndWait('Nnnooooooooo!!!');

                                function doPieceAnimation(piece: Actor) {
                                    final x = randomIntBetween(int(tyl.getX() + tyl.getWidth() / 3), int(tyl.getX() + tyl.getWidth() * (2/3)));
                                    final y = randomIntBetween(int(tyl.getY() + tyl.getHeight() / 3), int(tyl.getY() + tyl.getHeight() * (2/3)));
                                    final a = randomIntBetween(0, 360);
                                    piece.setX(x); piece.setY(y); piece.setAngle(a * Utils.RAD);
                                    
                                    final distanceToTravel = 45;
                                    final finalX = x + Math.sin(a) * distanceToTravel;
                                    final finalY = y + Math.cos(a) * distanceToTravel;
                                    piece.moveTo(finalX, finalY, 1, Easing.expoOut);

                                    doAfter(1000, () -> {
                                        piece.moveTo(holeCenterX, holeCenterY, 1, Easing.expoOut);
                                    });
                                    doAfter(2000, () -> {
                                        recycleActor(piece);
                                    });

                                }

                                final head = setMiddleActor('TylPieceActor', 'Head');
                                doPieceAnimation(head);
                                for (i in 0...10) {
                                    final piece = setMiddleActor('TylPieceActor', 'Vertebra');
                                    doPieceAnimation(piece);
                                }
                                recycleActor(tyl);
                                doAfter(2000, () -> {
                                    Effects.playOnlyParticleAt(holeCenterX, holeCenterY, 'Smoke');
                                    resumeDialogueClicking();
                                });
                            }
                        });
                    },
                    () -> {
                        stopMusic();
                        Effects.sendArcMissileCustomAndThen({
                            from: getActorCenterPoint(king),
                            to: new Point(getScreenXCenter() - 160, getScreenYCenter() + 40),
                            actorName: 'CinematicTileActor',
                            missileName: 'Normal',
                            speed: Effects.MEDIUM,
                            onActorCreated: function(a: Actor) { a.growTo(1.5, 1.5, 0); },
                            andThen: function() {
                                Effects.playOnlyParticleAt(holeCenterX, holeCenterY, 'Smoke');
                                NonCombatEvents.setBackground('Images/Backgrounds/Cutscene/CastleNoCarpet.png', 0, 0);                                
                            }
                        });
                        sayFromActorAndWait(king, 'And stay there!');
                    },
                    () -> {
                        playMusic('AdventureMusic');
                        pauseDialogueClicking();
                        fadeOverlayOutBlack(2000, () -> {
                            king.setX(getScreenXCenter() + 80);
                            unturn(marceline, true);
                            marceline.setX(getScreenXCenter() + 20);
                            doAfter(1000, () -> {
                                fadeOverlayIn(1000, () -> {
                                    resumeDialogueClicking();
                                    sayFromActorAndWait(king, 'Well, heroes...');
                                });
                            });
                        });
                    },
                    () -> sayFromActorAndWait(king, 'You saved the kingdom.'),
                    () -> sayFromActorAndWait(marceline, "And he would have gotten away with it..."),
                    () -> sayFromActorAndWait(marceline, "...if it weren't for you, meddling adventurers."),
                    () -> sayFromActorAndWait(marceline, "I..."),
                    () -> sayFromActorAndWait(marceline, "I thank you for that."),
                    () -> sayFromActorAndWait(king, "It's the first time she ever said 'Thank you'!"),
                    () -> sayFromActorAndWait(king, "That's my daughter!"),
                    () -> {
                        turn(marceline, () -> sayFromActorAndWait(marceline, "..."));
                    },
                    () -> {
                        unturn(marceline);
                        sayFromRandomCharacterAndWait('It was our duty, Marceline.');
                    },
                    () -> sayFromRandomCharacterAndWait('It had to be done.'),
                    () -> {
                        pauseDialogueClicking();
                        doAfter(500, () -> {
                            turn(king);
                            doAfter(1000, () -> {
                                sayFromActorAndWait(king, "As for me...");
                                doAfter(1000, () -> {
                                    turn(marceline);
                                    resumeDialogueClicking();
                                });
                            });
                        });
                    },
                    () -> sayFromActorAndWait(king, "I am unfit to rule."),
                    () -> {
                        unturn(marceline);
                        sayFromRandomCharacterAndWait('But then...');
                    },
                    () -> sayFromRandomCharacterAndWait("Who's gonna be king?"),
                    () -> {
                        fadeOverlayOutBlack(3000, () -> {
                            NonCombatEvents.setBackground('Images/Backgrounds/Road.png', 0, 0);
                            willard.enableActorDrawing();
                            willard.setX(getScreenX() + getScreenWidth());
                            willard.moveTo(getScreenXCenter(), willard.getY(), 6, Easing.linear);
                            recycleActor(king);
                            recycleActor(marceline);
                            recycleActor(getCharacter(0));
                            recycleActor(getCharacter(1));
                            documents.enableActorDrawing();
                            fadeOverlayIn(6000, () -> {
                                willard.setAnimation('Merchant Standing');
                                doAfterDialogue(1000, () -> {
                                    sayFromActorAndWait(willard, 'Oh!');
                                });
                            });
                        });
                    },
                    () -> sayFromActorAndWait(willard, 'What is this?'),
                    () -> sayFromActorAndWait(willard, 'My, oh, my!'),
                    () -> sayFromActorAndWait(willard, 'Some Kingdom Ownership Documents!!'),
                    () -> {
                        pauseDialogueClicking();
                        doAfter(500, () -> {
                            turn(willard);
                            doAfter(1000, () -> {
                                unturn(willard);
                                doAfter(2500, () -> {
                                    documents.moveTo(willard.getXCenter(), willard.getYCenter(), 0.25, Easing.expoOut);
                                    sayFromActor(willard, 'Finders keepers!', 3);
                                    doAfter(250, () -> {
                                        recycleActor(documents);
                                    });
                                    doAfter(3000, () -> {
                                        willard.setAnimation('Merchant Walking');
                                        willard.moveTo(getScreenX(), willard.getY(), 5, Easing.linear);
                                    });
                                    doAfter(4000, () -> {
                                        fadeOverlayOutBlack(2500, () -> {
                                            end();
                                        });
                                    });
                                });
                            });
                        });
                    }

                ], () -> {});
            }
        },
     
        



        {   name: 'Pentagram',
            init: function(andThen: Void -> Void) {
                setMiddleActor('EventActor', 'Pentagram', 0, 20);
                createDarknessInScene(-25);
                startDialogue([
                    () -> { alertAndWait('You come across a pentagram written in blood.'); },
                    () -> { sayAndWait('Wicked...', getRandomCharacterPoint()); }
                ], andThen);
            },
            options: [
                {   title: 'Extinguish',
                    appearCondition: null,
                    description: 'Put out the light of the candle in the center. Who knows what horrors might happen...',
                    onChoose: function() {
                        healAll(3);
                        hideOptions();
                        startDialogue([
                            () -> { alertAndWait('You extinguish the candle and feel slightly better. The magic fades away from this place...'); }
                        ], end);
                    }
                },
                makeUseItemOption(itemChosen -> {
                    hideOptions();

                    if (itemChosen.hasTag(CLOTH)) {
                        itemChosen.reduceQuality();
                        scrollForAllChars('white', '+4 Mana');
                        doAfter(500, () -> {
                            scrollForAllChars('white', '+4 Initiative');
                            doAfter(1000, () -> {
                                startDialogue([
                                    () -> { alertAndWait('You wipe the pentagram with the ${itemChosen.name}. The item weakens, but the evil of this place fades and you feel stronger!'); },
                                    () -> { sayFromRandomCharacterAndWait('${itemChosen.name} is a great towel!'); }
                                ], end);
                            });
                        });
                    } else if (itemChosen.hasTag(LIQUID)) {
                        giveItem('Blood Mixture');
                        doAfter(500, () -> {
                            startDialogue([
                                () -> { sayFromRandomCharacterAndWait('Smells salty!'); },
                                () -> { alertAndWait('You scrape some blood into the ${itemChosen.name}. You shake it thoroughly, and you create a Blood Mixture!'); }                                
                            ], end);
                        });
                    } else if (itemChosen.name == 'Tooth of Insomnia') {
                        Player.progression.isVampireWeakened = true;
                        fadeOverlayOutBlack(1000, () -> {
                            final coverArt = new ImageX('Images/Backgrounds/CoverArtLarge.png', 'CoverArtLayer');
                            coverArt.setX(getScreenX());
                            coverArt.setY(getScreenY());
                            doAfter(1000, () -> {
                                fadeOverlayIn(1000);
                                final castleXCenter = 222;
                                final castleYBottom = 248;
                                var lightning = createActor('SpecialEffectActor', 'OverlayEffectsLayer');
                                lightning.setAnimation('Lightning Strike');
                                setXCenter(lightning, castleXCenter);
                                setYBottom(lightning, castleYBottom);
                                doAfter(2000, () -> {
                                    fadeOverlayOutBlack(1000, end);
                                });
                            });
                        });
                    } else {
                        nothingHappensWithThatItem();
                    }
                }),
                makeSkipOption()
            ]
        },
        {   name: 'Sandman Defeated',
            appearCondition: function() return false,
            init: function(andThen: Void -> Void) {
                final darkness = new ImageX('Images/Other/SomniumDarkness.png', 'DarknessLayer');
                darkness.centerOnScreen();
                NonCombatEvents.setBackground('Images/Backgrounds/Somnium.png', 0, -55);
                final sandman = setMiddleActor('UnitActor', 'Sandman No Moon', 90, 0);
                startDialogueAfter(1000, [
                    () -> sayFromSandmanAndWait(sandman, 'Fine! Fine!'),
                    () -> sayFromSandmanAndWait(sandman, 'I yield!! I yield!!'),
                    () -> sayFromRandomCharacterAndWait('Good! Now spill it!'),
                ], andThen);
            },
            options: [
                {   title: 'Nana Joy',
                    description: 'Why did you banish her?',
                    onChoose: function() {
                        hideOptions();
                        final sandman = middleActor;
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('Sandman, why did you banish Nana Joy from here?'),
                            () -> sayFromSandmanAndWait(sandman, 'Ah, that.'),
                            () -> sayFromSandmanAndWait(sandman, 'She cheated on me with the King.'),
                            () -> sayFromRandomCharacterAndWait('What!?'),
                            () -> {
                                turn(sandman);
                                doAfterDialogue(1000, () -> {
                                    sayFromSandmanAndWait(sandman, 'She is a lusty woman, I tell you that.');
                                });
                            },
                            () -> sayFromSandmanAndWait(sandman, 'The King is tall, handsome, powerful...'),
                            () -> sayFromSandmanAndWait(sandman, 'And likely a much better father than me...'),
                            () -> {
                                sayFromRandomCharacterAndWait('I kind of doubt that, but I get it.');
                                unturn(sandman);
                            }
                        ], () -> { reloadOptions(); });
                    }
                },
                {   title: 'Your Daughter',
                    description: 'Where is she?',
                    onChoose: function() {
                        hideOptions();
                        final sandman = middleActor;
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('We need to check on your daughter.'),
                            () -> {
                                turn(sandman);
                                doAfterDialogue(1000, () -> {
                                    sayFromActorAndWait(sandman, 'Oh, the shame...', 6, 0);
                                });
                            },
                            () -> sayFromActorAndWait(sandman, 'To this day I regret marrying her to him...', 6, 0),
                            () -> sayFromActorAndWait(sandman, 'He was not like he seemed.', 6, 0),
                            () -> sayFromActorAndWait(sandman, 'Charming, but with an awful soul...', 6, 0),
                            () -> sayFromRandomCharacterAndWait('Who is he.'),
                            () -> sayFromActorAndWait(sandman, 'Just some prick who smells like coal.', 6, 0),
                            () -> sayFromRandomCharacterAndWait('Where is your daughter?'),
                            () -> {
                                unturn(sandman);
                                doAfterDialogue(500, () -> {
                                    sayFromSandmanAndWait(sandman, 'Take the tunnel.');
                                });
                            },
                            () -> sayFromSandmanAndWait(sandman, 'It will lead you straight to her bedroom.'),
                            () -> sayFromSandmanAndWait(sandman, 'Please don\'t tell Nana Joy...'),
                            () -> sayFromRandomCharacterAndWait('We shall see.'),
                        ], () -> { reloadOptions(); });
                    }
                },
                {   title: 'Check Daughter',
                    description: 'Take the tunnel to her bedroom.',
                    onChoose: function() {
                        hideOptions();
                        final sandman = middleActor;
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('Time to go, Sandman.'),
                            () -> sayFromSandmanAndWait(sandman, 'I just hope you can forgive me for what you will find.'),
                            () -> sayFromSandmanAndWait(sandman, 'And Nana Joy can live with herself as well.'),
                            () -> {
                                pauseDialogueClicking();
                                fadeOverlayOutBlack(2000, () -> {
                                    recycleActor(sandman);
                                    NonCombatEvents.setBackground('Images/Backgrounds/Catacombs.png', 0, 0);
                                    createDarknessInScene(-25);
                                    final corpse = setMiddleActor('EventActor', 'Cellar Corpse', 35, 0);
                                    doAfter(1500, () -> {
                                        fadeOverlayIn(1500, () -> {
                                            doAfter(1000, () -> {
                                                resumeDialogueClicking();
                                                sayFromRandomCharacterAndWait('Oh no...');
                                            });
                                        });
                                    });
                                });
                            },
                            () -> sayFromRandomCharacterAndWait('Isn\'t this the blacksmith\'s cellar?'),
                            () -> sayFromRandomCharacterAndWait("Let's just... get out of here."),
                        ], () -> {
                            end();
                        });
                    }
                },
            ]
            
        },
        {   name: 'Nana Joy Meeting',
            appearCondition: function() return false,
            options: [
                {   title: 'Your Daughter',
                    description: 'Who is your daughter?',
                    onChoose: function() {
                        hideOptions();
                        final nanaJoy = middleActor;
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('Who is your daughter?'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'She is the daughter of me and my ex-husband:'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'The Sandman.'),
                            () -> sayFromRandomCharacterAndWait('The Sandman?'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'We and our daughter used to live in the Somnium.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'Until we married her to a charming young mortal.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'Together, we created a tunnel from the Somnium to his home.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'There is now a permanent link between the Somnium and this kingdom.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'I just need you to do a wellfare check on her.'),
                            () -> sayFromRandomCharacterAndWait('Why can\'t you do it?'),
                            () -> {
                                turn(nanaJoy);
                                doAfterDialogue(500, () -> {
                                    sayFromNanaJoyAndWait(nanaJoy, 'I was banished from the Somnium...');
                                });
                            },
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'For reasons I can not disclose.'),
                            () -> sayFromRandomCharacterAndWait('I see where this is going.'),
                            () -> {
                                unturn(nanaJoy);
                                doAfterDialogue(500, () -> {
                                    sayFromNanaJoyAndWait(nanaJoy, 'Please...');
                                });
                            },
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'Travel to the Somnium, find the tunnel and check on my daughter.'),
                            () -> sayFromRandomCharacterAndWait('If the tunnel ends in the charming mortal\'s house...'),
                            () -> sayFromRandomCharacterAndWait('Can\'t we just go there?'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'I have no idea where it is.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'The only 100% sure way to find it is through the Somnium.'),
                        ], () -> { reloadOptions(); });
                    }
                },
                {   title: 'The Somnium',
                    description: 'What is the Somnium?',
                    onChoose: function() {
                        hideOptions();
                        final nanaJoy = middleActor;
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('What is this Somnium place?'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'It is a realm of the dreams, void and stars.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'It is where I used to live before I was banished.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'In the Somnium, you will find the tunnel to my daughter.'),
                            () -> sayFromRandomCharacterAndWait('How do we get there?'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'I will gladly sell you a Tooth of Insomnia.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'On your journeys, you can buy the Tooth of Insomnia...'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, '...and use it to travel to the Somnium.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'Though, I am not sure how it works.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'You will have to figure out how to use it.'),
                        ], () -> { reloadOptions(); });
                    }
                },
                {   title: 'Accept',
                    description: 'You can count on us!',
                    onChoose: function() {
                        hideOptions();
                        final nanaJoy = middleActor;
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('We will try to check on your daughter!'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'Oh, thank you, brave heroes!!'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'Find me any time throughout the kingdom.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'I will sell you a Tooth of Insomnia.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'If you can discover how it works...'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, '...it will transport you to the Somnium.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'Oh, one last thing!'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'Stay near candles! Darkness is dangerous.'),
                            () -> sayFromNanaJoyAndWait(nanaJoy, 'Good luck!'),
                        ], () -> {
                            Player.progression.didNanaJoyMeeting = true;
                            end();
                        });
                    }
                },
            ],
            init: function(andThen: Void -> Void) {
                final nanaJoy = setMiddleActor('ShopkeepActor', 'NanaJoy', 90, 20);
                startDialogueAfter(1000, [
                    () -> sayFromNanaJoyAndWait(nanaJoy, 'Heroes...'),
                    () -> sayFromRandomCharacterAndWait('Nana Joy?'),
                    () -> sayFromRandomCharacterAndWait('What are you doing here?'),
                    () -> sayFromNanaJoyAndWait(nanaJoy, 'Heroes, I need your help.'),
                    () -> sayFromRandomCharacterAndWait('What\'s up?'),
                    () -> {
                        turn(nanaJoy);
                        doAfterDialogue(1500, () -> {
                            sayFromNanaJoyAndWait(nanaJoy, 'I harbor dark secrets, heroes...');
                        });
                    },
                    () -> sayFromNanaJoyAndWait(nanaJoy, 'And an even darker past I am ashamed of.'),
                    () -> {
                        unturn(nanaJoy, () -> {
                            sayFromNanaJoyAndWait(nanaJoy, 'You must travel to the Somnium to check on my daughter.');
                        });
                    }
                ], () -> {
                    U.showInterstitialAndLoadNext();
                    andThen();
                });
            }
        },
        {   name: 'Nana Joy After',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                final nanaJoy = setMiddleActor('ShopkeepActor', 'NanaJoy', 90, 20);
                startDialogueAfter(1000, [
                    () -> sayFromNanaJoyAndWait(nanaJoy, 'HELLO, HEROES.'),
                    () -> sayFromRandomCharacterAndWait('Nana Joy...'),
                    () -> sayFromRandomCharacterAndWait('You need to know that-'),
                    () -> sayFromNanaJoyAndWait(nanaJoy, 'WHAT A LOVELY DAY.'),
                    () -> sayFromRandomCharacterAndWait('Yeah, your daughter-'),
                    () -> sayFromNanaJoyAndWait(nanaJoy, 'IT SURE IS NICE OUTSIDE TODAY.'),
                    () -> sayFromRandomCharacterAndWait('Uhm... are you ok, Nana Joy?'),
                    () -> sayFromNanaJoyAndWait(nanaJoy, "OF COURSE, HONEY. DO I LOOK NOT OK, DEAR?"),
                    () -> sayFromRandomCharacterAndWait('Sure...'),
                    () -> sayFromNanaJoyAndWait(nanaJoy, "I HAVE NEW ITEMS."),
                    () -> sayFromNanaJoyAndWait(nanaJoy, "TOMES."),
                    () -> sayFromNanaJoyAndWait(nanaJoy, "COME BUY WHEN YOU HAVE TIME, SWEETIE."),
                    () -> sayFromRandomCharacterAndWait('Yeah, I think we should go...'),
                    () -> sayFromRandomCharacterAndWait("I'm getting kind of creeped out..."),
                    () -> sayFromNanaJoyAndWait(nanaJoy, "PLEASE COME AGAIN, HEROES!!")
                ], () -> {
                    Player.progression.didNanaJoyAfterDialogue = true;
                    end();
                });
            }
        },
        {   name: 'Hell Portal',
            appearCondition: () -> Player.progression.didNatasClarificationDialogue,
            init: function(andThen: Void -> Void) {
                setMiddleActor('EventActor', 'Hell Portal', 42, 30);
                // createDarknessInScene(-25);
                startDialogue([
                    () -> sayFromRandomCharacterAndWait('Wow, a portal!'),
                    () -> sayFromRandomCharacterAndWait('That\'s a really oversized skull.'),
                ], andThen);
            },
            options: [
                {   title: 'Step Inside',
                    appearCondition: null,
                    description: 'Step inside the portal. What could go wrong?',
                    onChoose: function() {
                        hideOptions();
                        startDialogue([
                            () -> {
                                final delayToDrop = 930;    // Milliseconds
                                NonCombatEvents.pauseDialogueClicking();
                                playAudio('HorrorAfAudio');
                                startShakingScreen(0.01, 5.93);
                                doAfter(delayToDrop, () -> {
                                    new TintShader(Utils.getColorRGB(255, 0, 140), 0.5)
                                        .combine(new InlineShader(CoolShaders.WAVES))
                                        .enable();
                                    startShakingScreen(0.07, 3);
                                    fadeOverlayOutBlack(1500, () -> {
                                        stopShakingScreen();
                                        engine.clearShaders();
                                        MessageScreen.showInterstitialAdOnNextMessageScreen();
                                        Player.startNewJourney(2);
                                    });
                                });
                            }
                        ], () -> {});   // No end here, cause end() is called in the function above
                    }
                },
                makeSkipOption()
            ]
        },
        {   name: 'Dark Cellar',
            appearCondition: () -> Player.progression.isCellarKeyFound && Player.progression.hasStartingGear == false,
            init: function(andThen: Void -> Void) {
                NonCombatEvents.setBackground('Images/Backgrounds/Catacombs.png', 0, 0);
                createDarknessInScene(-25);
                setMiddleActor('EventActor', 'Blacksmith Tools');
                setMiddleActor('EventActor', 'Cellar Corpse', 35, 25);
                andThen();
            },
            options: [
                {   title: 'Take',
                    appearCondition: null,
                    description: 'You found Blacksmithing Tools! Hooray!',
                    onChoose: function() {
                        NonCombatEvents.hideOptions();
                        Game.setAchievement('HAS_STARTING_GEAR');
                        Player.progression.hasStartingGear = true;
                        startDialogue([
                            () -> { sayFromRandomCharacterAndWait('Let\'s take it and not ask any questions.'); },
                            () -> { sayFromRandomCharacterAndWait('Sweet free gear at the start of every run!'); }
                        ], () -> {
                            Player.progression.hasStartingGear = true;
                            end();
                        });
                    }
                }
            ]
        },
        {   name: 'Golden Shrine',
            init: function(andThen: Void -> Void) {
                setMiddleActor('EventActor', 'Golden Shrine', 35, 15);
                startDialogue([
                    () -> { alertAndWait('A sparkle catches your eye - you see a pedestal with a statuette made of gold!'); },
                    () -> { alertAndWait('However, it will not let you leave empty handed!'); }
                ], andThen);
            },
            options: [
                {   title: 'Steal It',
                    appearCondition: null,
                    description: 'Steal the statuette. Hopefully it is not cursed.',
                    onChoose: function() {
                        hideOptions();
                        Player.giveGold(50);
                        for (char in Player.characters) {
                            char.stats.crit -= 10;
                        };
                        scrollForAllChars('white', '-10% Crit');
                        startDialogueAfter(1000, [
                            () -> alertAndWait('As you put your hands on the statuette, your joints weaken, and the golden statuette transforms into a pouch of 50 gold coins!'),
                            () -> { sayAndWait('I feel weakened...', getRandomCharacterPoint()); },
                            () -> { sayAndWait('At least we got gold!', getRandomCharacterPoint()); }
                        ], end);
                    }
                },
                {   title: 'Pay Tribute',
                    appearCondition: null,
                    description: 'Leave a tribute of 25 gold near the statuette. Surely the statuette likes gold.',
                    onChoose: function() {
                        if (Player.gold < 25) {
                            sayFromRandomCharacter('We don\'t have enough gold!');
                            return;
                        }
                        
                        final allPlayerItems = Player.getAllInventoryItems().concat(Player.getAllEquippedItems());
                        final allPlayerGear = allPlayerItems.filter(item -> item.type == 'GEAR');
                        if (allPlayerGear.length == 0) {
                            sayFromRandomCharacter('Our tribute was not accepted...');
                            return;
                        }

                        var bestGearItem: Item = allPlayerGear[0];
                        for (item in allPlayerGear) {
                            if (item.level > bestGearItem.level && item.stats != null && item.getNumberOfNonZeroStats() > 0) {
                                bestGearItem = item;
                            }
                        }
                        var characterWithItem = Player.getCharacterWithItem(bestGearItem);
                        hideOptions();
                        Player.gold -= 25;
                        if (characterWithItem != null) characterWithItem.subtractItemStats(bestGearItem);
                        bestGearItem.improveQuality();
                        if (characterWithItem != null) characterWithItem.addItemStats(bestGearItem);
                        startDialogueAfter(1000, [
                            () -> alertAndWait('The statuette accepts your offer, and upgrades your ${bestGearItem.name}, your best gear item!'),
                            () -> { sayAndWait('Thank you, mystical statuette!', getRandomCharacterPoint()); },
                            () -> sayFromEventAndWait('No problem, homie.', 3, -30)
                        ], () -> {
                            end();
                        });
                    }
                },
                makeUseItemOption(item -> {
                    hideOptions();
                    consumeItem(item);
                    Player.giveGold(int(item.price * 1.5));
                    startDialogueAfter(500, [
                        () -> alertAndWait('The ${item.name} transforms into golden coins in your hands, and you get more than its weight in gold!'),
                        () -> { sayAndWait('We struck gold!', getRandomCharacterPoint()); }
                    ], end);
                })
            ]
        },
        {   name: 'Effigy',
            init: function(andThen: Void -> Void) {
                setMiddleActor('EventActor', 'Effigy', 30, 6);
                startDialogue([
                    () -> { alertAndWait('An eldritch effigy lies in front of you...'); },
                    () -> { sayAndWait('Who made this?', getRandomCharacterPoint()); }
                ], andThen);
            },
            options: [
                {   title: 'Break',
                    appearCondition: null,
                    description: 'Break the effigy. Perhaps you can scavenge some materials...',
                    onChoose: function() {
                        final possibleItems = [
                            'Regular Goat Horn',
                            'Branch of Lore',
                            'Candle',
                            'Planks',
                            'Bone'
                        ];
                        final itemChosen: String = randomOf(possibleItems);
                        giveItem(itemChosen);
                        hideOptions();
                        doAfter(1000, () -> {
                            startDialogue([
                                () -> { alertAndWait('You break the effigy and salvage an item.'); },
                                () -> { sayFromRandomCharacterAndWait('Better than nothing.'); }
                            ], end);
                        });
                    }
                },
                makeUseItemOption((item: Item) -> {
                    if (item.type == 'SPELL') {
                        Player.removeItem(item);
                        final givenItem = ItemsDatabase.getRandomItem({
                            type: 'SPELL',
                            usableTome: true
                        });
                        giveItem(givenItem.name);
                        startDialogueAfter(1000, [
                            () -> { alertAndWait('The power of the Effigy transforms your ${item.name} into ${givenItem.name}!'); },
                            () -> { sayFromRandomCharacterAndWait('Books are great!'); }
                        ], end);
                    } else if (['Bone', 'Heart', 'Toilet Paper', 'Soft Fur', 'Candle'].indexOf(item.name) != -1) {
                        Player.removeItem(item);
                        Player.addMercenary('Effigy');
                        startDialogueAfter(500, [
                            () -> { alertAndWait('You decorate the Effigy with the ${item.name} and it comes to life!'); },
                            () -> { alertAndWait('The Effigy joins you in your journeys!'); },
                            () -> { sayFromRandomCharacterAndWait('*gulp*'); }
                        ], end);
                    } else if (item.name == 'Flowers') {
                        Player.removeItem(item);
                        final fiftyPercentHPs = Player.characters.map(char -> int(char.stats.health * 0.5));
                        healEach(fiftyPercentHPs);
                        doAfter(1000, () -> {
                            scrollForAllChars('white', '+2 Mana');
                            startDialogueAfter(1000, [
                                () -> { alertAndWait('The flowers cleanse the Effigy and bless you with a lot of Health and extra maximum mana!'); },
                                () -> { sayFromRandomCharacterAndWait('I feel so pure!'); }
                            ], end);
                        });
                    } else {
                        nothingHappensWithThatItem();
                    }
                }),
                makeSkipOption()
            ]
        },
        {   name: 'Lecture Table',
            init: function(andThen: Void -> Void) {
                final table = setMiddleActor('EventActor', 'Lecture Table');
                table.setX(table.getX() + 21);
                table.setY(table.getY() + 9);
                startDialogue([
                    () -> alertAndWait('The smell of old paper, candles and ink enchants you while approaching...'),
                    () -> alertAndWait('Before you stands a well prepared lecture table, everything readied as if someone put it there for you specifically.')
                ], andThen);
            },
            options: [
                {   title: 'Bind Passive',
                    appearCondition: null,
                    description: 'Permanently secure one of your Passive Spells. This persists through all future runs.',
                    onChoose: function() {
                        hideOptions();
                        
                        final allCurrentPassives: Array<{char: String, spell: String}> =
                            Player.characters[0].getPassiveBindableSpellNames().map(s -> {char: Player.characters[0].getClassName(), spell: s})
                            .concat(
                                if (Player.characters.length > 1) Player.characters[1].getPassiveSpellNames().map(s -> {char: Player.characters[1].getClassName(), spell: s})
                                else []
                            );
                        
                        function isPassiveAlreadyKnown(cs: {char: String, spell: String}) return Player.progression.lectureTablePassives.filter(lcs -> lcs.char == cs.char && lcs.spell == cs.spell).length > 0;
                        final allBindablePassives = allCurrentPassives.filter(cs -> isPassiveAlreadyKnown(cs) == false);

                        if (allBindablePassives.length == 0) {
                            sayFromRandomCharacter('We have no bindable passives!');
                            showOptions();
                            return;
                        }

                        shuffle(allBindablePassives);
                        final chosenPassives = if (allBindablePassives.length <= 3) allBindablePassives else allBindablePassives.slice(0, 3);
                        final items = chosenPassives.map(cs -> ItemsDatabase.getTomeNameFromSpellName(cs.spell));

                        AfterCombat.goToAfterCombat(0, {
                            preventItemLoot: true,
                            specificLoot: items
                        }, (itemChosen: Item) -> {
                            Game.setAchievement('MADE_PASSIVE_PERMANENT');
                            final spellName = ItemsDatabase.getSpellNameFromItemName(itemChosen.name);
                            final whichItemIndex = itemChosen.customData.index;   // A custom data sent from AfterCombat
                            final charName = chosenPassives[whichItemIndex].char;
                            Player.progression.lectureTablePassives.push({char: charName, spell: spellName});
                            end();
                        });
                    }
                },
                makeSkipOption()
            ]
        },
        {   name: 'Grave of a Fallen Hero',
            init: function(andThen: Void -> Void) {
                setMiddleActor('EventActor', 'Grave of a Fallen Hero', 20, 20);
                startDialogue([
                    () -> alertAndWait('As you approach, a feeling of sadness in the air engulfs you...'),
                    () -> alertAndWait('The grave of a fallen hero stands enduring in front of you.')
                ], andThen);
            },
            options: [
                {   title: 'Take Its Flowers',
                    appearCondition: null,
                    description: 'A bouquet rests on top of the hero\'s grave. Take it...',
                    onChoose: function() {
                        hideOptions();
                        for (pc in Player.characters) {
                            pc.stats.initiative -= 2;
                        }
                        scrollForAllChars('white', '-2 Initiative');
                        startDialogueAfter(750, [
                            () -> sayFromRandomCharacterAndWait('I feel bad for stealing this...'),
                            () -> sayFromRandomCharacterAndWait('At least we have flowers now!')
                        ], end);
                    }
                },
                makeUseItemOption(item -> {
                    hideOptions();
                    if (item.hasTag(UNHOLY)) {
                        doAfter(1000, () -> {
                            startShakingScreen(0.01, 2);
                            startDialogue([
                                () -> sayFromEventAndWait('BLASPHEMY!!'),
                                () -> sayFromRandomCharacterAndWait('Uh oh...')
                            ], () -> {
                                Battlefield.goToBattle('Fallen Hero');
                            });
                        });
                    } else if (item.hasTag(WEAPON) || item.hasTag(ARMOR)) {
                        startDialogue([
                            () -> alertAndWait('The grave kindly accepts your offer, ${item.name}'),
                            () -> {
                                giveItem(ItemsDatabase.getTomeNameFromSpellName('Hero Health'));
                                sayFromRandomCharacterAndWait('I feel like I can conquer the world!');
                            }
                        ], end);
                    } else if (item.type == 'CONSUMABLE') {
                        scrollForAllChars('white', '+1 Mana Regeneration');
                        doAfter(500, () -> {
                            scrollForAllChars('white', '+2 Mana');
                        });
                        startDialogue([
                            () -> alertAndWait('The shrine accepts your tribute of ${item.name} as charity.'),
                            () -> alertAndWait('The fallen hero\'s spirit blesses you with extra endurance!'),
                            () -> sayFromRandomCharacter('Thank you, warrior of the past.'),
                            () -> sayFromRandomCharacter('We will not forget this.')
                        ], end);
                    } else if (item.name == 'Flowers') {
                        Game.setAchievement('IS_FALLEN_HERO_REUNITED');
                        Player.progression.isFallenHeroReunited = true;
                        startDialogueAfter(500, [
                            () -> alertAndWait('A faint whisper can be heard coming from the shrine...'),
                            () -> sayFromEventAndWait('...my old comrade\'s flowers...'),
                            () -> sayFromEventAndWait('...I missed him so much...'),
                            () -> sayFromEventAndWait('...thank you, heroes...'),
                            () -> sayFromEventAndWait('...I can now be in peace...')
                        ], () -> {
                            startDialogueAfter(1000, [
                                () -> alertAndWait('Fallen Hero permanent bonuses unlocked!')
                            ], end);
                        });
                    } else {
                        nothingHappensWithThatItem();
                    }
                }),
                makeSkipOption()
            ]
        },
        {   name: 'Locked Chest',
            init: function(andThen: Void -> Void) {
                middleActor = setMiddleActor('EventActor', 'Locked Chest', 30, 9);
                startDialogue([
                    () -> alertAndWait('You come across a chest, right in the middle of the room.'),
                    () -> {
                        final randomQuote: String = randomOf([
                            'Careful! It might be trapped!',
                            'Careful! It might be trapped!',
                            'It might be a mimick...'
                        ]);
                        sayFromRandomCharacterAndWait(randomQuote);
                    }
                ], andThen);
            },
            options: [
                {   title: 'Pick Lock',
                    appearCondition: null,
                    description: 'Try to pick the lock. Be careful, though!',
                    onChoose: function() {
                        hideOptions();
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('Ok, let\'s try...')
                        ], () -> {
                            doAfter(500, () -> {    // Delay required to prevent click-through
                                function onLockSuccess() {
                                    U.showInterstitialAndLoadNext();
                                    LockedChestEvent.hide(() -> {
                                        startDialogue([
                                            () -> sayFromRandomCharacterAndWait('We did it!')
                                        ], () -> {
                                            final level = if (Battlefield.lastBattlefieldEncounter != null) Battlefield.lastBattlefieldEncounter.level else 2;
                                            AfterCombat.goToAfterCombat(level, {}, (item) -> {
                                                end();
                                            });
                                        });
                                    });
                                }
                                function onLockCancel() {
                                    LockedChestEvent.hide(() -> {
                                        sayFromRandomCharacter('Hold up...');
                                        NonCombatEvents.showOptions();
                                    });
                                }
                                function onLockFail(pcIndex: Int) {
                                    damageCharacterIrresponsibly(pcIndex, 2);
                                    for (pc in Player.characters) {
                                        trace(pc.health);
                                    }
                                    if (Player.isAnyCharacterDead()) {
                                        Player.distributeHealthAmongCharacters();
                                        LockedChestEvent.hide(() -> {
                                            startDialogue([
                                                () -> sayFromRandomCharacterAndWait('We took too much damage...'),
                                                () -> {
                                                    U.showInterstitialAndLoadNext();
                                                    sayFromRandomCharacterAndWait('We should move on...');
                                                }
                                            ], () -> {
                                                end();
                                            });
                                        });
                                    }
                                }
                                LockedChestEvent.showAndStartNewLockPick({
                                    onSuccess: onLockSuccess,
                                    onCancel: onLockCancel,
                                    onFailure: onLockFail
                                });
                            });
                        });
                    }
                },
                makeSkipOption()
            ]
        },
        {   name: 'Fungus Overgrowth',
            init: function(andThen: Void -> Void) {
                final midActor = setMiddleActor('EventActor', 'Fungus Overgrowth', 85, 90);
                startDialogue([
                    () -> alertAndWait('Your way ahead is blocked by (mildly toxic) mushrooms.'),
                    () -> sayFromRandomCharacterAndWait('What do we do?')
                ], andThen);
            },
            options: [
                {   title: 'Destroy By Hand',
                    appearCondition: null,
                    description: 'It\'s going to be a slow and exhausting process.',
                    onChoose: function() {
                        for (pc in Player.characters) {
                            pc.stats.mana -= 1;
                        }
                        hideOptions();
                        fadeOverlayOutBlack(1000, () -> {
                            startDialogue([
                                () -> alertAndWait('You clear the path with tooth and nail...'),
                                () -> alertAndWait('Fatigue overcomes you, and everyone loses 1 maximum mana.')
                            ], end);
                        });
                    }
                },
                {   title: 'Burn',
                    appearCondition: null,
                    description: 'Set fire to the whole overgrowth. WARNING: Fire hazard!',
                    onChoose: function() {
                        hideOptions();
                        startDialogueAfter(750, [
                            () -> sayFromRandomCharacterAndWait('Okay... Ready?')
                        ], () -> {
                            doAfter(1000, () -> {
                                startShakingScreen(0.05, 2);
                                doEveryUntil(200, 2000, () -> {
                                    final explosionX = getScreenXCenter() + randomIntBetween(-70, 70);
                                    final explosionY = getScreenYCenter() + randomIntBetween(-60, 60);
                                    SpecialEffectsFluff.doExplosionEffect(explosionX, explosionY);
                                });
                                doAfter(1000, () -> {
                                    fadeOverlayOutBlack();
                                });
                                doAfter(2000, () -> {
                                    U.showInterstitialAndLoadNext();
                                    startDialogue([
                                        () -> alertAndWait('You burn the shroomery, but fire burns you for 4 damage.'),
                                        () -> sayFromRandomCharacterAndWait(':<')
                                    ], () -> {
                                        for (chr in Player.characters) {
                                            chr.damage(4);
                                        }
                                        if (Player.checkGameOver() == true) {
                                            Game.gameOver();
                                            return;
                                        }
                                        if (Player.isAnyCharacterDead()) {
                                            Player.distributeHealthAmongCharacters();
                                        }
                                        end();
                                    });
                                });
                            });
                        });
                    }
                },
                makeUseItemOption(item -> {
                    final itemMapping = [
                        'Moldy Bread' => 'Penicillin Bread',
                        'Sandwich' => 'Moldy Sandwich',
                        'Cheese' => 'Blue Cheese'
                    ];
                    if (itemMapping.exists(item.name)) {
                        hideOptions();
                        final item = ItemsDatabase.get(itemMapping[item.name]);
                        Player.giveItem(item);
                        SpecialEffectsFluff.doItemToInventoryAnimation(item.imagePath, getScreenXCenter(), getScreenYCenter());
                        doAfter(1000, () -> {
                            end();
                        });
                    } else if (item.name == 'Candle') {
                        sayFromRandomCharacter('That would just burn everything.');
                    } else if (item.hasTag(WEAPON)) {
                        hideOptions();
                        startDialogueAfter(500, [
                            () -> sayFromRandomCharacterAndWait('That will help us clear the shroomery!'),
                        ], () -> {
                            fadeOverlayOutBlack(1000, () -> {
                                startDialogueAfter(1000, [
                                    () -> alertAndWait('You successfully cleared the shrooms, but the ${item.name} has slightly degraded.')
                                ], end);
                            });
                        });
                    } else {
                        nothingHappensWithThatItem();
                    }
                })
            ]
        },
        {   name: 'Travelling Alchemist',
            init: function(andThen: Void -> Void) {
                eventSayExtraYOffset = 0;
                final house = setMiddleActor('EventActor', 'Alchemist House', 140, 10);
                final merchant = setMiddleActor('ShopkeepActor', 'Merchant', 0, -5);
                merchant.setXCenter(house.getX() + 80);
                house.moveToTop();
                playAudio('ShopDoorBellAudio');
                doAfter(700, () -> {
                    playAudio('MerchantHelloAudio');
                    startDialogueAfter(500, [
                        () -> sayFromEventAndWait('Oh hello there!', 0, 9),
                        () -> sayFromEventAndWait('I am also an alchemist!', 0, 9),
                        () -> sayFromEventAndWait('Feel free to give me an ingredient...', 0, 9),
                        () -> sayFromEventAndWait('...and I will try to make something good from it!', 0, 9)
                    ], andThen);
                });
            },
            options: [
                {   title: 'Free Potion',
                    description: 'An offer only for you: I give you this Unknown Potion, for FREE! It\'s not acid, I promise!',
                    appearCondition: null,
                    onChoose: function() {
                        hideOptions();
                        giveItem('Unknown Potion');
                        startDialogue([
                            () -> sayFromEventAndWait('Great!', 0, 9),
                            () -> sayFromEventAndWait('I also gave it to my dog.', 0, 9),
                            () -> sayFromEventAndWait('He\'s a bird now.', 0, 9),
                            () -> sayFromEventAndWait('Anyway, thanks for trying it out!', 0, 9),
                        ], end);
                    }
                },
                makeUseItemOption(item -> {
                    function sayFailDialogueAndWait() sayFromEventAndWait('Ok, folks. Enough for today! Good luck and all!', 0, 9);
                    if (item.hasTag(UNHOLY)) {
                        consumeItem(item);
                        giveItem(ItemsDatabase.getTomeNameFromSpellName('Unholy Revival'));
                        sayFromEvent('Oh, remember to drink that ASAP!');
                    } else if (item.hasTag(ORE)) {
                        consumeItem(item);
                        giveItem('Potion of Armor');
                        sayFromEvent('That one is metal!');
                        doAfter(3000, () -> {
                            sayFromEvent('Pun intended.', 500);
                        });
                    } else if (item.hasTag(PLANT)) {
                        consumeItem(item);
                        giveItem('Potion of Healing');
                        sayFromEvent('Cures your wounds. Does not cure your depression.');
                    } else if (item.type == 'CONSUMABLE') {
                        if (item.hasTag(SPECIAL_ITEM)) {
                            nothingHappensWithThatItem(
                                () -> sayFromEvent('No. Not this. Something else.'),
                                sayFailDialogueAndWait);
                        } else {
                            consumeItem(item);
                            sayFromEvent('A consumable for a consumable. Good trade!');
                            final tradeItem = ItemsDatabase.getRandomItem({
                                type: 'CONSUMABLE',
                                level: item.level,
                                maxRarity: RARE,
                                excludeTags: [SPECIAL_ITEM]
                            });
                            giveItem(tradeItem.name);
                        }
                    } else {
                        nothingHappensWithThatItem(
                            () -> sayFromEvent('Do I look like I can put that in a bottle?'),
                            sayFailDialogueAndWait);
                    }
                }),
                makeSkipOption()
            ]
        },
        {   name: 'Natas Defeated',
            appearCondition: function() return false,
            options: [],
            init: function(andThen: Void -> Void) {
                function sayFromNatasAndWait(message: String) {
                    sayFromActorAndWait(middleActor, message, 0, -15);
                }
                NonCombatEvents.setBackground('Images/Backgrounds/CaveNatas.png', 0, -55);
                setMiddleActor('UnitActor', 'Natas', 120, 35);
                startDialogueAfter(1000, [
                    () -> sayFromNatasAndWait('Fine, fine!! I\'ll talk!!'),
                    () -> sayFromNatasAndWait('Look, Here\'s the story about Tyl.'),
                    () -> sayFromNatasAndWait('He traded me Stormjr\' soul for his powers.'),
                    () -> sayFromRandomCharacterAndWait('He just... took Stormjr\'s soul?'),
                    () -> sayFromNatasAndWait('Yeah. He stole it while he was sleeping.'),
                    () -> sayFromRandomCharacterAndWait('Oh, of course...'),
                    () -> {
                        middleActor.setAnimation('Natas Pissed');
                        sayFromNatasAndWait('Tyl is an imbecile.');
                    },
                    () -> sayFromNatasAndWait('I told him he won\'t be able to keep the kingdom for long.'),
                    () -> sayFromNatasAndWait('The kingdom belongs to the true heir.'),
                    () -> sayFromNatasAndWait('In the end, we shall have the true king.'),
                    () -> sayFromRandomCharacterAndWait('Who is the true heir?'),
                    () -> {
                        middleActor.setAnimation('Natas');
                        sayFromNatasAndWait('Willard.');
                    },
                    () -> sayFromRandomCharacterAndWait('The merchant??'),
                    () -> sayFromNatasAndWait('Yep.'),
                    () -> sayFromRandomCharacterAndWait('Willard the Merchant is the true king???'),
                    () -> sayFromNatasAndWait('It\'s what the prophecies said, anyway.'),
                    () -> {
                        middleActor.setAnimation('Natas Pissed');
                        sayFromNatasAndWait('Now, get out of my house!');
                    },
                    () -> sayFromNatasAndWait('Here, have my blessing.'),
                    () -> sayFromNatasAndWait('Done.'),
                    () -> sayFromNatasAndWait('Go home.'),
                    () -> sayFromNatasAndWait('And never come back.')
                ], end);
            }
        },
        {   name: 'Natas',
            init: function(andThen: Void -> Void) {
                middleActor = setMiddleActor('EventActor', 'Natas', 65, 15);
                startDialogueAfter(1750, [
                    () -> sayFromActorAndWait(middleActor, 'Hello, children.', -5, -15),
                    () -> sayFromRandomCharacterAndWait('Children?'),
                    () -> sayFromActorAndWait(middleActor, 'May I interest you in a deal?', -5, -15),
                    () -> sayFromRandomCharacterAndWait('What kind of deal?'),
                    () -> {
                        NonCombatEvents.pauseDialogueClicking();
                        doAfter(1000, () -> {
                            middleActor.setAnimation('Natas Smirk');
                            doAfter(1000, () -> {
                                sayFromActorAndWait(middleActor, 'Your soul!!!', -5, -15);
                                NonCombatEvents.resumeDialogueClicking();
                            });
                        });
                    },
                    () -> {
                        middleActor.setAnimation('Natas');
                        sayFromActorAndWait(middleActor, 'Just kidding. Let\'s talk.', -5, -15);
                    }
                ], andThen);
            },
            options: [
                {   title: 'About Tyl...',
                    description: 'You helped Tyl to conquer this lands.',
                    appearCondition: () -> Player.progression.didStormjr3Dialogue && Player.progression.didNatasClarificationDialogue == false,
                    onChoose: function() {
                        hideOptions();
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('Natas, did you help Tyl with his plans?'),
                            () -> sayFromNatasAndWait('Sure did.'),
                            () -> sayFromRandomCharacterAndWait('What did you do?'),
                            () -> sayFromNatasAndWait('Well, what are devils known for?'),
                            () -> sayFromRandomCharacterAndWait('Evilness?'),
                            () -> {
                                middleActor.setAnimation('Natas Pissed');
                                sayFromRandomCharacterAndWait('Fire!');
                            },
                            () -> sayFromRandomCharacterAndWait('Horns?'),
                            () -> sayFromNatasAndWait('No.'),
                            () -> {
                                middleActor.setAnimation('Natas');
                                sayFromNatasAndWait('We made a pact.');
                            },
                            () -> sayFromRandomCharacterAndWait('What pact?'),
                            () -> {
                                middleActor.setAnimation('Natas Smirk');
                                sayFromNatasAndWait('Well, woudn\'t you like to know?');
                            },
                            () -> sayFromRandomCharacterAndWait('Will you tell us?'),
                            () -> sayFromNatasAndWait('Nope.'),
                            () -> {
                                middleActor.setAnimation('Natas');
                                sayFromNatasAndWait('But maybe I\'ll invite you to my place and we can discuss there.');
                            },
                            () -> sayFromRandomCharacterAndWait('Where do you live?'),
                            () -> sayFromNatasAndWait('Hell.'),
                            () -> sayFromRandomCharacterAndWait('Perfect. See you there.'),
                            () -> {
                                middleActor.setAnimation('Natas Pissed');
                                sayFromNatasAndWait( 'Wha-');
                            },
                            () -> sayFromNatasAndWait('No, don\'t just come to my home uninvited.'),
                            () -> sayFromNatasAndWait('I repeat:'),
                            () -> sayFromNatasAndWait('Do NOT come to my home uninvited.'),
                            () -> sayFromRandomCharacterAndWait('Got it.'),
                            () -> {
                                middleActor.setAnimation('Natas');
                                sayFromNatasAndWait('Good.');
                            },
                            () -> sayFromNatasAndWait('Anything else I can help you with?')
                        ], () -> {
                            Player.progression.didNatasClarificationDialogue = true;
                            reloadOptions();
                        });
                    }
                },
                {   title: 'Ask...',
                    description: 'What do you want and what do we get?',
                    appearCondition: () ->
                        if (Player.progression.didStormjr3Dialogue && Player.progression.didNatasClarificationDialogue == false) false
                        else Player.progression.didTalkToNatasOnce == false,
                    onChoose: function() {
                        Player.progression.didTalkToNatasOnce = true;
                        hideOptions();
                        startDialogue([
                            () -> sayFromRandomCharacterAndWait('So, how does it work?'),
                            () -> sayFromNatasAndWait('It\'s simple,'),
                            () -> sayFromNatasAndWait('You give me all you have now and start from the beginning...'),
                            () -> sayFromNatasAndWait('...and next run, you will have TREMENDOUS powers.')
                        ], () -> { reloadOptions(); });
                    }
                },
                {   title: 'Give your all...',
                    description: '... to me, I\'ll give my all to you! (well, just some of my parts)',
                    appearCondition: () ->
                        if (Player.progression.didStormjr3Dialogue && Player.progression.didNatasClarificationDialogue == false) false
                        else Player.progression.didTalkToNatasOnce,
                    onChoose: function() {
                        hideOptions();
                        Game.setAchievement('ACCEPTED_NATAS_OFFER_ONCE');
                        middleActor.setAnimation('Natas Smirk');
                        startDialogueAfter(1000, [
                            () -> sayFromNatasAndWait('Consider it done.'),
                            () -> {
                                final delayToDrop = 930;    // Milliseconds
                                NonCombatEvents.pauseDialogueClicking();
                                playAudio('HorrorAfAudio');
                                startShakingScreen(0.01, 5.93);
                                doAfter(delayToDrop, () -> {
                                    final natasHead = createActor('Natas Head Flashing', 'NatasLayer');
                                    centerActorOnScreen(natasHead);
                                    natasHead.growTo(3, 3, 5, Easing.linear);
                                    new TintShader(Utils.getColorRGB(255, 0, 140), 0.5)
                                        .combine(new InlineShader(CoolShaders.WAVES))
                                        .enable();
                                    startShakingScreen(0.07, 3);
                                    doAfter(5000, () -> {
                                        stopShakingScreen();
                                        recycleActor(natasHead);
                                        engine.clearShaders();
                                        final darkness = new ImageX('Images/Backgrounds/Black.png', 'BlackOverlayLayer');
                                        darkness.centerOnScreen();
                                        doAfter(1500, () -> {
                                            NonCombatEvents.resumeDialogueClicking();
                                            sayFromNatasAndWait('Done! Enjoy!');
                                        });
                                    });
                                });
                            }
                        ], () -> {
                            Player.progression.hasNatasBuff = true;
                            Player.startNewRun();
                        });
                    }
                },
                makeUseItemOption(item -> {
                    hideOptions();
                    if (item.name == 'Flowers') {
                        consumeItem(item);
                        startDialogueAfter(1000, [
                            () -> sayFromNatasAndWait('Where did you get this from?'),
                            () -> {
                                middleActor.setAnimation('Natas Smirk');
                                sayFromNatasAndWait('Don\'t tell me you took it from a grave...');
                            },
                            () -> sayFromNatasAndWait('You are pathetic.'),
                            () -> {
                                middleActor.setAnimation('Natas');
                                sayFromNatasAndWait('Fine. I will give each of you one of my blessings');
                                if (Player.characters.length == 2) {
                                    Player.characters[0].equipSpell('Fiery Presence');
                                    Player.characters[0].equipSpell('Soul Drain');
                                    Player.characters[1].equipSpell('Fiery Presence');
                                    Player.characters[1].equipSpell('Soul Drain');
                                } else {
                                    Player.characters[0].equipSpell('Fiery Presence');
                                    Player.characters[0].equipSpell('Soul Drain');
                                }
                            },
                            () -> sayFromNatasAndWait('Now begone. I feel insulted...')
                        ], end);
                    } else if (item.name == 'Tooth of Insomnia') {
                        consumeItem(item);
                        startDialogue([
                            () -> sayFromNatasAndWait('Damn son, where\'d you find this!?'),
                            () -> sayFromNatasAndWait('I will pay you good money for it!'),
                        ], () -> {
                            Player.giveGold(400);
                            end();
                        });
                    } else {
                        nothingHappensWithThatItem(
                            () -> sayFromNatasAndWait('What do you think I am, some kind of merchant?'),
                            () -> sayFromNatasAndWait('Stop trying to sell me things! Begone!')
                        );
                    }
                }),
                makeSkipOption()
            ]
        },
        {   name: 'Pirates',
            init: function(andThen: Void -> Void) {
                pirates_peasant = setMiddleActor('EventActor', 'Pirate Peasant', 30, 0);
                pirates_crewmate = setMiddleActor('EventActor', 'Crewmate');
                pirates_crewmate.setX(pirates_peasant.getX() + 85);
                pirates_canon = setMiddleActor('EventActor', 'Canon');
                pirates_canon.setX(pirates_crewmate.getX() - pirates_canon.getWidth() * 0.75);
                pirates_canon.moveToTop();
                pirates_canon.setY(pirates_canon.getY() + 5);
                middleActor = pirates_peasant;
                startDialogueAfter(1000, [
                    () -> sayFromEventAndWait('Avast!!'),
                    () -> sayFromRandomCharacterAndWait('Pirates! Prepare yourselves!'),
                    () -> sayFromEventAndWait('Hold yer horses, matey!'),
                    () -> sayFromEventAndWait('We are just traderrrrs.'),
                    () -> sayFromEventAndWait('Aye! Give us some gold or an item...'),
                    () -> sayFromEventAndWait('...and we will give you something equal in returrrn.')
                ], andThen);
            },
            options: [
                {   title: 'Give Gold',
                    description: 'Give the pirates 50 gold.',
                    appearCondition: null,
                    onChoose: function() {
                        if (Player.gold < 50) {
                            sayFromEvent('Yer pockets be a little empty, matey...');
                            return;
                        }
                        hideOptions();
                        Player.gold -= 50;
                        Player.progression.piratesGoldStored += 50;
                        giveItem('Fish Tail');
                        finishPirateGiveGoldOrItemWithDialogue();
                    }
                },
                makeUseItemOption(item -> {
                    hideOptions();
                    consumeItem(item);
                    finishPirateGiveGoldOrItemWithDialogue();
                }),
                {   title: 'Attack them',
                    description: 'Attack the pirates! Take all their stuff!',
                    appearCondition: null,
                    onChoose: function() {
                        hideOptions();
                        startDialogueAfter(1000, [
                            () -> sayFromRandomCharacterAndWait('Your days of plundering are over!'),
                            () -> sayFromRandomCharacterAndWait('Face us in battle!'),
                            () -> sayFromEventAndWait('So be it! Cleave \'em to the brisket!')
                        ], () -> {
                            Battlefield.goToBattle('Pirates');
                        });
                    }
                }
            ]

        },
        {   name: 'Dead Adventurers',
            init: function(andThen: Void -> Void) {
                middleActor = setMiddleActor('EventActor', 'Dead Adventurers');
                middleActor.setX(middleActor.getX() + 15);
                middleActor.setY(middleActor.getY() + 15);
                startDialogueAfter(500, [
                    () -> alertAndWait('The stench of a group of dead adventurers penetrates your nose, making you question your choice to adventure in these lands.'),
                    () -> sayFromRandomCharacterAndWait('Hmm...')
                ], andThen);
            },
            options: [
                {   title: 'Search',
                    description: 'Search the bodies. Maybe you can find something useful',
                    appearCondition: null,
                    onChoose: function() {
                        hideOptions();
                        final level = Player.getLevel();
                        final goldAmount = int(randomInt(5, 10) * (level * 0.75));
                        final consumable = ItemsDatabase.getRandomItem({
                            type: 'CONSUMABLE',
                            level: level,
                            maxRarity: COMMON,
                            excludeTags: [SPECIAL_ITEM]
                        });
                        final gear = ItemsDatabase.getRandomItem({
                            type: 'GEAR',
                            level: level,
                            maxRarity: COMMON,
                            excludeTags: [SPECIAL_ITEM]
                        });
                        final tome = ItemsDatabase.getRandomItem({
                            usableTome: true,
                            type: 'SPELL',
                            maxLevel: level,
                            excludeTags: [SPECIAL_ITEM]
                        });
                        Player.giveGold(goldAmount);
                        final items = [consumable, gear, tome];
                        items.remove(items[randomIntBetween(0, 2)]);
                        for (item in items) {
                            doAfter(randomInt(100, 750), () -> {
                                SpecialEffectsFluff.doItemToInventoryAnimation(item.imagePath, middleActor.getXCenter(), middleActor.getYCenter());
                                Player.giveItem(item);
                            });
                        }
                        if (percentChance(50)) {
                            final sickCharIndex = Player.getRandomCharacterIndex();
                            Player.characters[sickCharIndex].equipSpell('Tuberculosis');
                            final actor = NonCombatEvents.charactersAtEvent[sickCharIndex];
                            Effects.playOnlyParticleAt(actor.getXCenter(), actor.getYCenter(), 'Tuberculosis');
                            sayFromCharacter(sickCharIndex, 'I don\'t feel so good...');
                        }
                        doAfter(2000, end);
                    }
                },
                makeSkipOption()
            ]
        } 
    ];


    // Event specific data
    static var pirates_crewmate: Actor;
    static var pirates_peasant: Actor;
    static var pirates_canon: Actor;
    static function finishPirateGiveGoldOrItemWithDialogue() {
        startDialogueAfter(1000, [
            () -> sayFromEventAndWait('Thanks, me harties!'),
            () -> sayFromEventAndWait('Enjoy yer item!'),
            () -> sayFromEventAndWait('So long, suckers!! Yahahargghh!')
        ], () -> {
            final crewmateOffsetX = pirates_crewmate.getX() - pirates_peasant.getX();
            final canonOffsetX = pirates_canon.getX() - pirates_peasant.getX();
            pirates_peasant.moveTo(getScreenXRight() + 100, pirates_peasant.getY(), 0.5, Easing.expoOut);
            pirates_crewmate.moveTo(getScreenXRight() + 100 + crewmateOffsetX, pirates_crewmate.getY(), 0.5, Easing.expoOut);
            pirates_canon.moveTo(getScreenXRight() + 100 + canonOffsetX, pirates_canon.getY(), 0.5, Easing.expoOut);
            startDialogueAfter(1000, [
                () -> sayFromRandomCharacterAndWait('HEY!'),
                () -> sayFromRandomCharacterAndWait('They took our stuff!'),
                () -> sayFromRandomCharacterAndWait('We\'ll get them next time...')
            ], end);
        });
    }
    
}



class LockedChestEvent {

    public static var k = {
        protrusionWidth: 22,
        centerXOffset: 80,
        centerYOffset: 133
    }

    public static var characterIndicator: CurrentCharacterIndicatorUIComponent;
    public static var lockActor: Actor;
    public static var pickActor: Actor;
    public static var isPickingLock = false;

    static var rotationDirection = 1;

    public static var currentNSolvedLocks = 0;
    public static var currentRotationSpeed = 2.0;
    public static var correctIntervals: Array<Array<Int>>;

    static var onSuccess: Void -> Void;
    static var onCancel: Void -> Void;
    static var onFailure: Int -> Void;

    public static function hide(andThen: Void -> Void) {
        isPickingLock = false;
        characterIndicator.hide();
        pickActor.disableActorDrawing();
        doAfter(1500, () -> {
            lockActor.disableActorDrawing();
            andThen();
        });
    }
    public static function showAndStartNewLockPick(callbacks: {
        onSuccess: Void -> Void,
        onCancel: Void -> Void,
        onFailure: Int -> Void
    }) {
        onSuccess = callbacks.onSuccess;
        onCancel = callbacks.onCancel;
        onFailure = callbacks.onFailure;

        isPickingLock = true;

        lockActor = createActor('LockActor', 'LockLayer');
        lockActor.setAnimation('Lock0');
        centerActorOnScreen(lockActor);
        lockActor.setX(lockActor.getX() + k.protrusionWidth / 2);

        characterIndicator = new CurrentCharacterIndicatorUIComponent();
        characterIndicator.open(lockActor.getY() + 115, lockActor.getX(), () -> isPickingLock);

        pickActor = createActor('LockPickActor', 'LockPickLayer');

        final pickPointX = lockActor.getX() + k.centerXOffset;
        final pickPointY = lockActor.getY() + k.centerYOffset;

        function isInCorrectInterval() {
            final degrees = Math.abs(pickActor.getAngle() * Utils.DEG) % 360;
            for (interval in correctIntervals) {
                // trace('Checking $degrees against interval ${interval.toString()}: ${degrees >= interval[0] && degrees <= interval[0]}');
                if (degrees >= interval[0] && degrees <= interval[1]) {
                    return true;
                }
            }
            return false;
        }
        function startNewLockPick() {
            pickActor.rotate(0);
            rotationDirection = if (currentRotationSpeed < 0) 1 else -1;
            final randomAngle = randomInt(0, 329);
            correctIntervals = [
                [randomAngle, randomAngle + randomInt(20, 40)]
            ];
        }

        doEvery(16, () -> {
            currentRotationSpeed = randomInt(30, 60) / 10 * rotationDirection;
            rotateActorCCWAroundPointFacingPoint({
                actor: pickActor,
                x: pickPointX,
                y: pickPointY,
                degrees: currentRotationSpeed
            });
            if (isInCorrectInterval()) {
                pickActor.setAnimation('Green');
            } else {
                pickActor.setAnimation('Normal');
            }
        });
        onClick(() -> {
            if (isPickingLock == false) return;
            if (isInCorrectInterval()) {
                currentNSolvedLocks += 1;
                lockActor.setAnimation('Lock${currentNSolvedLocks}');
                if (currentNSolvedLocks == 3) {
                    playAudio('LockSuccessAudio');
                    onSuccess();
                } else {
                    playAudio('LockOkAudio');
                    startNewLockPick();
                }
            } else {
                startShakingScreen(0.1, 0.2);
                playAudio('LockErrorAudio');
                startNewLockPick();
                onFailure(characterIndicator.currentPlayerCharacterIndex);
            }
        }, lockActor);

        startNewLockPick();
    }

    

}