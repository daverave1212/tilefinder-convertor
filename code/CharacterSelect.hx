
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
import Std.int;


class CharacterSelect
{

    public static var k = {
        classButtonsPadding: 12,
        classButtonSize: 34
    }

    public static var startButton : SButton;
    public static var character : Actor;

    static var callback: Void -> Void;


    public static function goToCharacterSelect(andThen: Void -> Void) {
        callback = andThen;
        U.changeScene('CharacterSelectScene');
    }

    public static function start() {
        if (callback == null) throwAndLogError('Go to CharacterSelect with goToCharacterSelect, not by changing scene!');
        engine.moveCamera(getSceneWidth() / 2, 0);
        SpecialEffectsFluff.setupEventBackgroundImage('Images/Backgrounds/CharacterSelectBackground.png', 15);
        
        startButton = new SButton('ItemPopupActionButton', 'UI', 'Go');
        startButton.centerHorizontally();
        startButton.setX(startButton.getX() + 1);
        startButton.setBottom(20);
        var clickedOnce = false;
        startButton.click = () -> {
            if (clickedOnce) return;
            clickedOnce = true;
            onClickOnStart();
        }

        character = createActor('UnitActor', 'Character');
        character.setAnimation('Knight');
        centerActorOnScreen(character);
        character.setY(character.getY() - 20);
        character.growTo(1.5, 1.5, 0);

        var availableClasses = ['Knight', 'Ranger', 'Mage'];
        var buttonsTotalWidth = availableClasses.length * k.classButtonSize + (availableClasses.length - 1) * k.classButtonsPadding;
        var buttonsStartLeft = getScreenWidth() / 2 - buttonsTotalWidth / 2;
        for (i in 0...availableClasses.length) {
            var className = availableClasses[i];
            var button = new FramedItem('Icons/${className}Select.png', 'UI', 0, 0);
            button.setX(getScreenX() + buttonsStartLeft + i * k.classButtonSize + i * k.classButtonsPadding);
            button.setY(getScreenYBottom() - button.getHeight() - 60);
            button.enablePopAnimation();
            button.click = () -> onClickOnClassButton(className);
            trace('Created button at ${button.getX()}, ${button.getY()}');

            if (className == 'Ranger' && Player.progression.isRangerUnlocked == false)
                button.disableAndMarkAsGrayed();
            if (className == 'Mage' && Player.progression.isMageUnlocked == false)
                button.disableAndMarkAsGrayed();

        }
        if (Player.isTurboModeEnabled) {
            doAfter(250, () -> {
                onClickOnStart();
            });
        }
    }

    private static function onClickOnClassButton(className) {
        character.setAnimation(className);
        character.growTo(1.5, 1.5, 0);
    }

    private static function onClickOnStart() {
        Game.q('C: Selecting class...');
        final selectedClass = character.getAnimation();
        final name =
            if (selectedClass == 'Knight') 'Andrew'
            else if (selectedClass == 'Ranger') 'Rook'
            else 'Zaina';
        final playerChar = Player.addCharacter(name, selectedClass);
        Game.q('C: Created character ${selectedClass}...');
        if (Player.progression.hasStartingGear) {
            for (itemName in MiscDatabases.startingGear[selectedClass]) {
                final item = ItemsDatabase.get(itemName);
                playerChar.equipItemStandalone(item);
            }
        }
        Game.q('C: Successfully setup character.');
        GameMap.preventMusicStart();
        Game.q('C: Callback...');
        callback();
    }
}