
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
import scripts.SpecialEffectsFluff.*;
import scripts.Game.q;

import Std.int;
import Math.min;


class NonCombatEvents
{

    public static var k = {
        feetYFromCenter: 30,
        backgroundImageExtraYOffset: 85,
        alertOffsetYToItsBottom: 130
    }

    public static var charactersAtEvent: Array<Actor> = [];
    public static var currentEvent: NonCombatEventDynamic;
    public static var state = 'CHOOSING';       // IN_INVENTORY
    public static var optionObjects: Array<NonCombatEventOption>;

    public static var backgroundImage: ImageX;

    public static var greenTextManager:         ScrollingTextManager;
    public static var whiteTextManager:         ScrollingTextManager;
    public static var redFloatingTextManager:   FloatingTextManager;

    public static var lastTriggeredSay: SayerReturnObject;      // Used for dialogue by NonCombatEventsDatabase

    public static var effectParticleSpawner: ParticleSpawner;

    public static var callback: Void -> Void;
    public static var data: Dynamic;

    public static function goToNonCombatEvents(?eventName: String, ?event: NonCombatEventDynamic, andThen: Void -> Void) {
        q('E: Going to non combat event: ${eventName} or ${if (event != null) event.name else "eventName"}');
        try {
            if (eventName == null && event == null) throwAndLogError('Null eventName and event given to goToNonCombatEvents');
            if (eventName != null)
                currentEvent = NonCombatEventsDatabase.get(eventName);
            else
                currentEvent = event;
            
            callback = if (andThen != null) andThen else null;
            changeScene('NonCombatEventsScene');
        } catch (e: Any) {
            q('ERROR: Exception in goToNonCombatEvents: ${e}');
        }
    }

    public static function setBackground(imagePath, ?xOffset = 0.0, ?yOffset = 0.0) {
        imagePath = extrapolatePNGPathWithBasePath(imagePath, 'Images/Backgrounds');
        try {
            if (backgroundImage != null)
                backgroundImage.kill();
            backgroundImage = setupEventBackgroundImage(imagePath, k.backgroundImageExtraYOffset + yOffset);
            trace('N: Set background Y = ${backgroundImage.getY()} from ${k.backgroundImageExtraYOffset} + ${yOffset}');
            backgroundImage.addX(xOffset);
        } catch (e: Any) {
            q('ERROR: Exception when setting background: ${e}');
        }
    }


    public static function start() {
        function setupEnvironment() {
            trace('Setting up environment with sea at y=${backgroundImage.getY()}');
            final background = SpecialEffectsFluff.getNonCombatBackgroundName();
            SpecialEffectsFluff.tryStartSpawningNonCombatSea({
                background: background,
                setBackground: (newBG) -> setBackground(newBG),
                x: backgroundImage.getX(),
                getBackgroundY: () -> {
                    final backgroundHeight = backgroundImage.getHeight();
                    final y = backgroundImage.getYCenter() - backgroundHeight / 2;
                    return y;
                }
            });
            SpecialEffectsFluff.tryStartSpawningLeaves(background);
            SpecialEffectsFluff.tryStartSpawningStalagmites(background);
            SpecialEffectsFluff.tryStartSpawningMist(background);
        }
        GUI.load('InventoryUI');
        GUI.load('PopupUI');
        centerCameraInScene();
        final backgroundImagePath = if (Battlefield.lastBattlefieldEncounter != null) Battlefield.lastBattlefieldEncounter.waves[0].getBackgroundImagePath() else 'Images/Backgrounds/Forest.png';
        backgroundImage = setupEventBackgroundImage(backgroundImagePath, k.backgroundImageExtraYOffset);
        charactersAtEvent = setupCharactersAtEvent(k.feetYFromCenter);
        if (currentEvent.preventCharacterDrawing == true)
            for (c in charactersAtEvent) {
                c.disableActorDrawing();
            }

        greenTextManager       = new ScrollingTextManager(getFont(SHADED_FONT_BIG_GREEN));
        whiteTextManager       = new ScrollingTextManager(getFont(SHADED_FONT_BIG));
        redFloatingTextManager = new FloatingTextManager(getFont(COMBAT_TEXT_FONT), -0.4);
        effectParticleSpawner  = new ParticleSpawner(0, 0);

        setupEnvironment();

        NonCombatEventsDatabase.onEventStart();

        U.setupMobileAdDebugMessages(function(msg) { Log.go(msg); });
        
        currentEvent.init(() -> {
            optionObjects = [];
            reloadOptions();
        });

    }

    public static function reloadOptions() {
        if (optionObjects != null) {
            for (option in optionObjects) {
                option.kill();
            }
        }
        optionObjects = [];
        final validOptions = currentEvent.options.filter(o -> o.appearCondition == null || o.appearCondition() == true);
        for (i in 0...validOptions.length) {
            final option = validOptions[i];
            final nceo = new NonCombatEventOption(option, i, validOptions.length);
            optionObjects.push(nceo);
        }
    }
    public static function hideOptions() {
        for (option in optionObjects)
            option.hide();
    }
    public static function showOptions() {
        for (option in optionObjects) {
            option.show();
        }
    }
    public static function showCharacterActors() {
        for (char in charactersAtEvent) {
            char.enableActorDrawing();
        }
    }
    public static function hideCharacterActors() {
        for (char in charactersAtEvent) {
            char.disableActorDrawing();
        }
    }

    static function getCharacterTextPoint(characterAtEventIndex: Int) {
        final x = charactersAtEvent[characterAtEventIndex].getXCenter() - getScreenX();
        final y = charactersAtEvent[characterAtEventIndex].getYCenter() - getScreenY() - 10;
        return new Point(x, y);
    }
    public static function pumpTextForChar(charIndex: Int, textPumper: FloatingTextManager, text: String) {
        final point = getCharacterTextPoint(charIndex);
        textPumper.pump(text, point.x, point.y);
    }
    public static function pumpTextAllChars(textPumper: FloatingTextManager, texts: Array<String>, delayInMilliseconds = 0) {
        for (i in 0...Player.characters.length) {
            doAfter(delayInMilliseconds, () -> {
                if (getCurrentSceneName() != 'NonCombatEventsScene') return;
                pumpTextForChar(i, textPumper, texts[i]);
            });
        }
    }
    public static function scrollTextAllChars(textScroller: ScrollingTextManager, texts: Array<String>, delayInMilliseconds = 0) {
        for (i in 0...Player.characters.length) {
            final x = charactersAtEvent[i].getXCenter() - getScreenX();
            final y = charactersAtEvent[i].getYCenter() - getScreenY() - 10;
            doAfter(delayInMilliseconds, () -> {
                if (getCurrentSceneName() != 'NonCombatEventsScene') return;
                textScroller.pump(texts[i], x, y);
            });
        }
    }

    static var preventDialogueClicking = false;
    public static function pauseDialogueClicking() preventDialogueClicking = true;
    public static function resumeDialogueClicking() preventDialogueClicking = false;
    public static function startDialogue(funcs: Array<Void -> Void>, andThen: Void -> Void) {
        preventDialogueClicking = false;
        var currentFuncIndex = 0;
        var doneAll = false;
        funcs = funcs.filter(func -> func != null);
        function goNext() {
            if (lastTriggeredSay != null && currentFuncIndex > 0) {
                Sayer.remove(lastTriggeredSay);
            }
            funcs[currentFuncIndex]();
            currentFuncIndex++;
        }
        onClick(() -> {
            if (doneAll) return;
            if (preventDialogueClicking) return;
            if (currentFuncIndex < funcs.length) {
                goNext();
            } else {
                doneAll = true;
                if (lastTriggeredSay != null && currentFuncIndex > 0) {
                    Sayer.remove(lastTriggeredSay);
                }
                andThen();
            }
        });
        goNext();
    }

    public static function alertAndWait(message) {
        lastTriggeredSay = sayAlert(message, getScreenXCenter(), getScreenY() + k.alertOffsetYToItsBottom, -1);
    }
    public static function sayAndWait(message, point: Point) {
        lastTriggeredSay = sayBubble(message, point.x, point.y, -1);
    }
    public static function sayCustomAndWait(message, point: Point, actorName) {
        lastTriggeredSay = sayCustomBubble(message, point.x, point.y, -1, actorName);
    }

    public static function done() {
        if (Player.areAllPlayerCharactersDead()) {
            Game.gameOver();
            return;
        }
        if (callback != null)
            callback();
    }
}

class NonCombatEventOption {
    public static var k = {
        optionBottom: 16,
        optionPadding: 12,
        descriptionOffsetY: 63
    };
    var background: ImageX;
    var button: SButton;
    var titleTextLine: TextLine;
    var descriptionTextBox: TextBox;
    public function new(eventOption: Dynamic, index: Int, nOptions: Int) {
        function setupBackground() {
            background = new ImageX('UI/EventOptionBackground.png', 'OptionsLayer');
            final totalWidth = nOptions * background.getWidth() + (nOptions - 1) * k.optionPadding;
            final startX = getScreenX() + (getScreenWidth() - totalWidth) / 2;
            final x = startX + index * (background.getWidth() + k.optionPadding);
            final y = getScreenYBottom() - background.getHeight() - k.optionBottom;
            background.setXY(x, y);
        }
        function setupButton() {
            button = new SButton('ItemPopupActionButton', 'OptionsLayer', 'CHOOSE');
            button.setSceneXCenter(background.getXCenter());
            button.setSceneYCenter(background.getYBottom());
            button.setText('CHOOSE', getFont(BROWN_ON_BROWN_TITLE_FONT), BUTTON_TEXT_Y);
            button.click = eventOption.onChoose;
        }
        function setupTexts() {
            titleTextLine = new TextLine('', getFont(BROWN_ON_BROWN_TITLE_FONT));
            final titleX = background.getXCenter();
            final titleY = background.getY() + 14;
            titleTextLine.setSceneX(titleX); titleTextLine.setSceneY(titleY);
            titleTextLine.enable();
            titleTextLine.alignCenter();
            titleTextLine.setText(eventOption.title);
            descriptionTextBox = new TextBox(110, 45, background.getXCenter(), background.getY() + k.descriptionOffsetY, getFont(BROWN_ON_BROWN_TITLE_FONT));
            descriptionTextBox.lineSpacing = 10;
            descriptionTextBox.setText(eventOption.description);
            descriptionTextBox.centerHorizontally = true;
            descriptionTextBox.centerVertically = true;
            descriptionTextBox.startDrawing();
        }
        setupBackground();
        setupButton();
        setupTexts();
    }
    public function hide() {
        background.hide();
        button.hide();
        titleTextLine.disable();
        descriptionTextBox.stopDrawing();
    }
    public function show() {
        background.show();
        button.show();
        titleTextLine.enable();
        descriptionTextBox.startDrawing();
    }
    public function kill() {
        if (background != null) background.kill();
        if (button != null) button.kill();
        titleTextLine.disable();
        descriptionTextBox.stopDrawing();
    }
}