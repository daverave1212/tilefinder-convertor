

package scripts;

import com.stencyl.Config;
import com.stencyl.graphics.G;
import com.stencyl.graphics.BitmapWrapper;
import com.stencyl.graphics.ScaleMode;

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


import scripts.Constants.*;
import U.*;
using U;



class ResolutionSelect
{

    static var resolutionRange: UIRange;
    static var windowedScaleRange: UIRange;
    static var scaleRange: UIRange;
    static var fullScreenCheckbox: UICheckbox;
    static var okButton: SButton;

    public static function goToResolutionSelect(firstTime: Bool) {
        U.changeScene('ResolutionSelectScene');
    }

    public static function start() {
        engine.moveCamera(getSceneWidth() / 2, getSceneHeight() / 2);

        resolutionRange = new UIRange({
            description: 'Resolution',
            x: 0,
            y: 0,
            minValue: 0,
            maxValue: MiscDatabases.resolutionOptions.length - 1,
            value: Game.savedSettings.resolutionOptionIndex,
            step: 1,
            onUpdate: (oldValue: Int, newValue: Int) -> {
                final pickedResolution = MiscDatabases.resolutionOptions[newValue];
                Game.savedSettings.resolutionOptionIndex = newValue;
                if (oldValue == newValue) return pickedResolution.name;
                SettingsUI.setResolution(newValue);
                return pickedResolution.name;
            }
        });

        resolutionRange.centerOnScreen();
        resolutionRange.setY(resolutionRange.getY() - 10);

        if (Game.isMobile == false) {
            windowedScaleRange = new UIRange({
                description: 'Windowed Scale',
                x: 0, y: 0,
                minValue: 1,
                maxValue: 4,
                value: Game.savedSettings.windowedScale,
                step: 1,
                onUpdate: function(oldValue: Int, newValue: Int) {
                    trace('>>>> UPDATING SCALE to ${newValue}');
                    Game.savedSettings.windowedScale = newValue;
                    Config.gameScale = newValue;
                    engine.reloadScreen();
                    return '${newValue}';
                }
            });
            fullScreenCheckbox = new UICheckbox({
                description: 'Full Screen (beta)',
                x: 0, y: 0,
                value: engine.isInFullScreen(),
                onUpdate: (newValue: Bool) -> {
                    Game.savedSettings.startInFullScreen = newValue;
                    if (engine.isInFullScreen()) {
                        engine.setFullScreen(false);
                        Config.scaleMode = ScaleMode.NO_SCALING;
                        engine.reloadScreen();
                    } else {
                        engine.setFullScreen(true);
                        SettingsUI.setResolution(Game.savedSettings.resolutionOptionIndex);
                    }
                }
            });

            windowedScaleRange.setX(getScreenXCenter() - resolutionRange.getWidth() / 2);
            windowedScaleRange.setY(resolutionRange.getY() + 23);
            fullScreenCheckbox.setX(getScreenXCenter() - windowedScaleRange.getWidth() / 2);
            fullScreenCheckbox.setY(windowedScaleRange.getY() + 23);
        }


        okButton = new SButton('GenericMenuButtonActor', 'UI', 'OK');
        okButton.centerHorizontally();
        okButton.setBottom(12);
        okButton.click = function() {
            onOkClick();
        }


        // Setup corners
        final upLeft = new ImageX('UI/ResolutionCorners/UpLeft.png', 'UI');
        upLeft.setX(getScreenX());
        upLeft.setY(getScreenY());
        final upRight = new ImageX('UI/ResolutionCorners/UpRight.png', 'UI');
        upRight.setX(getScreenX() + getScreenWidth() - upRight.getWidth());
        upRight.setY(getScreenY());
        final downRight = new ImageX('UI/ResolutionCorners/DownRight.png', 'UI');
        downRight.setX(getScreenX() + getScreenWidth() - downRight.getWidth());
        downRight.setY(getScreenY() + getScreenHeight() - downRight.getHeight());
        final downLeft = new ImageX('UI/ResolutionCorners/DownLeft.png', 'UI');
        downLeft.setX(getScreenX());
        downLeft.setY(getScreenY() + getScreenHeight() - downLeft.getHeight());
    }


    public static function onOkClick() {
        Game.save(() -> {
            changeScene('MenuScene');
        });
    }

}