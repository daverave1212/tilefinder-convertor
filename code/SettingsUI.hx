

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

import Std.int;

using U;


class SettingsUI extends SimpleUI
{

    public static var self: SettingsUI;

    public var background: ImageX;


    public var musicRange: UIRange;
    public var audioRange: UIRange;
    public var resolutionRange: UIRange;
    public var closeButton: Actor;
    public var onCloseClick: Void -> Void;
    
    public var endTurnCheckbox: UICheckbox;
    public var equipSpellsCheckbox: UICheckbox;
    public var fullScreenCheckbox: UICheckbox;

    public var exitButton: SUIButton;
    public var menuButton: SButton;

    public function new() {
        super("SettingsUI");
		self = this;
    }

    public static function setResolution(resolutionOptionIndex: Int, ?andThen: Void -> Void) {
        final pickedResolution = MiscDatabases.resolutionOptions[resolutionOptionIndex];
        trace('Setting resolution to ${resolutionOptionIndex}, ${pickedResolution.name}');
        final wasInFullScreen = engine.isInFullScreen();
        if (wasInFullScreen) {
            trace('Disabling full screen...');
            engine.setFullScreen(false);
        }

        doAfter(350, () -> {
            Config.stageWidth  = pickedResolution.w;
            Config.stageHeight = pickedResolution.h;
            Config.scaleMode   = pickedResolution.scale;
            engine.reloadScreen();

            function reloadScene() {
                switch (getCurrentSceneName()) {
                    case 'MapScene': GameMap.reload();
                    case 'ResolutionSelectScene': ResolutionSelect.goToResolutionSelect(false);
                }
            }
            if (wasInFullScreen) {
                doAfter(350, () -> {
                    engine.setFullScreen(true);
                    doAfter(350, () -> {
                        if (andThen != null) andThen();
                        else reloadScene();
                    });
                });
            } else {
                doAfter(350, () -> {
                    if (andThen != null) andThen();
                    else reloadScene();
                });
            }
        });
    }
    public static function setFullScreenAndUpdateResolution(bool: Bool, ?andThen: Void -> Void) {
        if (bool == false) {
            if (Game.isMobile == false) {
                engine.setFullScreen(false);
            }
            Config.scaleMode = ScaleMode.NO_SCALING;
            engine.reloadScreen();
            if (andThen != null) andThen();
        } else {
            if (Game.isMobile == false) {
                trace('Enabling full screen.');
                engine.setFullScreen(true);
                trace('Done, the game should now be in full screen.');
            }
            setResolution(Game.savedSettings.resolutionOptionIndex, andThen);
        }
    }
    public override function load() {
        background = new ImageX('UI/SettingsBackground.png', 'MenuPanelLayer');
        closeButton = createActor('ItemPopupCloseButton', 'MenuComponentsLayer');
        SpecialEffectsFluff.addPopBehaviorToActor(closeButton, (_) -> GUI.isOpen('SettingsUI'));	// Only if it's open
        onClick(() -> {
            trace('Clicked on close;');
            if (!GUI.isOpen('SettingsUI')) {
                trace('Not open. Returning');
                return;
            }
			if (onCloseClick != null) onCloseClick();
		}, closeButton);
        musicRange = new UIRange({
            description: 'Music',
            x: 0, y: 0,
            minValue: 0, maxValue: 100, value: int(Game.savedSettings.musicVolume * 100), step: 10,
            onUpdate: (oldValue: Int, newValue: Int) -> {
                Game.savedSettings.musicVolume = newValue / 100;
                U.setMusicVolume(newValue / 100);
                return newValue + "%";
            }
        });
        audioRange = new UIRange({
            description: 'Master Volume',
            x: 0, y: 0,
            minValue: 0, maxValue: 100, value: int(Game.savedSettings.masterVolume * 100), step: 10,
            onUpdate: (oldValue: Int, newValue: Int) -> {
                Game.savedSettings.masterVolume = newValue / 100;
                U.setEffectVolume(newValue / 100);
                return newValue + "%";
            }
        });
        resolutionRange = new UIRange({
            description: 'Resolution',
            x: 0, y: 0,
            minValue: 0,
            maxValue: MiscDatabases.resolutionOptions.length - 1,
            value: Game.savedSettings.resolutionOptionIndex,
            step: 1,
            onUpdate: (oldValue: Int, newValue: Int) -> {
                final pickedResolution = MiscDatabases.resolutionOptions[newValue];
                Game.savedSettings.resolutionOptionIndex = newValue;
                if (oldValue == newValue) return pickedResolution.name;
                setResolution(newValue);
                return pickedResolution.name;
            }
        });
        endTurnCheckbox = new UICheckbox({
            description: 'Auto-End Turn',
            x: 0, y: 0,
            value: Game.savedSettings.autoEndTurn,
            onUpdate: (newValue: Bool) -> {
                Game.savedSettings.autoEndTurn = newValue;
            }
        });
        equipSpellsCheckbox = new UICheckbox({
            description: 'Auto-Equip Spells',
            x: 0, y: 0,
            value: Game.savedSettings.autoEquipSpells,
            onUpdate: (newValue: Bool) -> {
                Game.savedSettings.autoEquipSpells = newValue;
            }
        });
        fullScreenCheckbox = new UICheckbox({
            description: 'Full Screen',
            x: 0, y: 0,
            value: engine.isInFullScreen(),
            onUpdate: (newValue: Bool) -> {
                if (Game.isMobile == false) {
                    setFullScreenAndUpdateResolution(newValue);
                }
            }
        });
        menuButton = new SButton('ItemPopupActionButton', 'UI', 'Give Up');
        menuButton.click = function() {
            GameMap.clear();
            Player.reset();
            changeScene('MenuScene');
            stopMusic();
        }
        exitButton = new SButton('ItemPopupActionButton', 'UI', 'Exit');
        exitButton.click = function() {
            changeScene('MenuScene');
        }
        close();
    }

    

    public override function open(?metadata: Array<Dynamic>) {
        function alignCheckboxWithRange(cb: UICheckbox, range: UIRange) {
            cb.setX(range.getX() - 1);
            cb.setDescriptionX(range.background.getX());
        }
        background.show();
        musicRange.show();
        audioRange.show();
        endTurnCheckbox.show();
        equipSpellsCheckbox.show();
        resolutionRange.show();
        if (Game.isMobile == false) {
            fullScreenCheckbox.show();
        }
        exitButton.show();
        menuButton.show();

        final baseYOffset = 25;
        background.centerOnScreen();
        MiscDatabases.setupCloseButton(closeButton, background);
        // closeButton.enableActorDrawing();
        // closeButton.growTo(1, 1, 0);
		// closeButton.setX(background.getX() + background.getWidth() - closeButton.getWidth() + 8);
		// closeButton.setY(background.getY() - 8);

        musicRange.centerHorizontally(); musicRange.setY(background.getY() + baseYOffset);
        audioRange.centerHorizontally(); audioRange.setY(background.getY() + baseYOffset + 20);
        endTurnCheckbox.setY(background.getY() + baseYOffset + 40);
        alignCheckboxWithRange(endTurnCheckbox, musicRange);
        equipSpellsCheckbox.setY(background.getY() + baseYOffset + 60);
        alignCheckboxWithRange(equipSpellsCheckbox, musicRange);

        

        resolutionRange.centerHorizontally(); resolutionRange.setY(background.getY() + baseYOffset + 105);
        if (Game.isMobile == false) {
            fullScreenCheckbox.setY(background.getY() + baseYOffset + 125);
            alignCheckboxWithRange(fullScreenCheckbox, resolutionRange);
        }
        exitButton.setLeftFrom(20, getScreenWidth() / 2);
        exitButton.setSceneY(background.getYBottom() - exitButton.getHeight() - 12);
        trace(exitButton.getX());
        trace(exitButton.getY());
        menuButton.setRightFrom(20, getScreenWidth() / 2);
        menuButton.setSceneY(background.getYBottom() - menuButton.getHeight() - 12);
        trace(menuButton.getX());
        trace(menuButton.getY());
    }
    public override function openWith(?options: Dynamic) {
        this.open();
        onCloseClick = options.onCloseClick;
        if (options == null) {
            trace('Null options.');
            return;
        }
        trace('Opened SettingsUI with options: ${haxe.Json.stringify(options)}');
        if (options.isResolutionGrayed == true) {
            trace('Disabling resolution range');
            resolutionRange.disable();
        }
        if (options.isFullScreenGrayed == true) {
            trace('Disabling full screen czechbox');
            if (Game.isMobile == false) {
                fullScreenCheckbox.disable();
            }
        }
    }
    

    public override function close() {
        background.hide();
        closeButton.disableActorDrawing();
        musicRange.hide();
        audioRange.hide();
        endTurnCheckbox.hide();
        equipSpellsCheckbox.hide();
        resolutionRange.hide();
        fullScreenCheckbox.hide();
        exitButton.hide();
        menuButton.hide();
    }

}
