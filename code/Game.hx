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

import com.stencyl.Config;
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

#if sys
import sys.io.File;
#end

import com.stencyl.utils.motion.*;

import scripts.Constants.*;
import U.*;
import scripts.BattlefieldEncounterDatabase.getRandomEncounterOfLevel;
import scripts.BattlefieldEncounterDatabase.getRandomEncounterOfLevelWithFlag;
import scripts.BattlefieldEncounterDatabase.getRandomEncounterWithFlag;
import scripts.BattlefieldEncounterDatabase.getRandomEncounterOfLevelWithoutFlag;
import scripts.GameMapGenerator.getRandomNodeInPath;
import scripts.GameMapGenerator.getAllPathsFromNode;
import scripts.GameMapGenerator.pathContainsShop;

using StringTools;


class Game
{

    // public static var isMobile = 
    //     #if java
    //     true
    //     #else
    //     false
    //     #end
    // ;
    public static var isMobile = #if android true #else false #end;
    public static var isDebugMode = isMobile;           // If true, it will display a DebugButtonActor every scene (a placed actor on each scene)
    public static var isFullGame = true;
    public static var fakeLoadingScreenTime = 0.03; // Used in MainScene
    public static var currentLogPath: String = null;

    // Settings
    @:keepSub public static var savedSettings = {
        resolutionOptionIndex: 0,
        windowedScale: 
            #if android
            4
            #else
            2
            #end
        ,
        startInFullScreen: 
            #if android
            true
            #else
            false
            #end
        ,
        masterVolume: U.defaultEffectVolume,
        musicVolume: U.defaultMusicVolume,
        autoEndTurn: true,
        autoEquipSpells: true
    }
    public static function setSettings(newSettings: Dynamic) {
        if (newSettings == null) return;
        savedSettings.resolutionOptionIndex = nullOr(newSettings.resolutionOptionIndex, 0);
        savedSettings.windowedScale = nullOr(newSettings.windowedScale, 2);
        if (isMobile) {
            savedSettings.startInFullScreen = true;
        } else {
            savedSettings.startInFullScreen = nullOr(newSettings.startInFullScreen, false);
        }
        savedSettings.masterVolume = nullOr(newSettings.masterVolume, U.defaultEffectVolume);
        savedSettings.musicVolume = nullOr(newSettings.musicVolume, U.defaultMusicVolume);
        savedSettings.autoEndTurn = nullOr(newSettings.autoEndTurn,true);
        savedSettings.autoEquipSpells = nullOr(newSettings.autoEquipSpells,true);
    }
    public static function applySavedSettingsAndThen(andThen: Void -> Void) {   // Assumes the savedSettings object is already loaded
        trace('Applying settings - gameScale = ${savedSettings.windowedScale}');
        Config.gameScale = savedSettings.windowedScale;
        U.setMusicVolume(savedSettings.musicVolume);
        U.setEffectVolume(savedSettings.masterVolume);
        SettingsUI.setResolution(savedSettings.resolutionOptionIndex, () -> {
            trace('Setting fullscreen: ${savedSettings.startInFullScreen}');
            SettingsUI.setFullScreenAndUpdateResolution(savedSettings.startInFullScreen, () -> {
                trace('Finalized as: ${haxe.Json.stringify(savedSettings)}');
                andThen();
            });
        });
    }
    public static function loadGameLicense() {    // If this returns true, then its the full version of the game
        final text = U.readFile('license.cfg').trim();
        if (text == 'true') isFullGame = true;
        else isFullGame = false;
    }

    // Game Control
	public static function newGame(willDisplayAd = false) {
        if (Player.progression.tutorialIsDone) {
            Player.startNewRun(willDisplayAd);
        } else {
            Player.startTutorialRun();
        }
    }
    public static function gameOver() {
        GameMap.clear();
        setGameAttribute('IsInRun', 'NO');
        MessageScreen.showInterstitialAdOnNextMessageScreen();
        MessageScreen.goToMessageScreenRedAndThen(MiscDatabases.getRandomGameOverMessage(), () -> {
            Player.init();
            save(() -> {
                U.changeScene('MenuScene');
            });
        });
    }    
    public static function setAchievement(achievementName: String) {
        trace('Setting achievement ${achievementName}');
        #if sys
        try {
            final systemName = Sys.systemName().toLowerCase();
            q('G: Got system name as: ${systemName}');
            if (systemName.indexOf('win') == -1) {
                q('  G: Not windows; skipping');
                return;    // Only Windows
            }
            q('G: Activating achievement ${achievementName}');
            U.createFileWithContent('TilefinderSetAchievement.txt', achievementName);
        } catch (e: Any) {
            q('ERROR: Failed to launch achievement');
            trace(e);
            q('${e}');
        }
        #else
            q('G: Skipping achievement. Not in a SYS system.');
        #end
    }
    public static function closeAchievementTriggerer() {
        setAchievement('EXIT');
    }

    // Save/load
    public static function continueAfterLoad() {
        GameMap.goToMapSceneAfterLoad();
    }
    public static function save(andThen: Void -> Void) {
        try {
            final playerObjectJSON: String = haxe.Json.stringify(Player.toDynamic());
            final mapObjectJSON: String = haxe.Json.stringify(GameMap.toDynamic());
            final settingsObjectJSON: String = haxe.Json.stringify(savedSettings);
            setGameAttribute('SaveExists', 'YES');              // Will be 'NO' if save was deleted with clearSave
            setGameAttribute('SaveVersion', Player.saveVersion);
            
            setGameAttribute('PlayerJSON', playerObjectJSON);
            setGameAttribute('SettingsJSON', settingsObjectJSON);
            setGameAttribute('IsInRun', if (GameMap.isMapGenerated()) 'YES' else 'NO');
            setGameAttribute('MapJSON', mapObjectJSON);
            saveGame('mySave', function(success: Bool) {
                if (success) q('@ @ Save successful');
                else {
                    q('@ @ Game could not be saved.');
                    throwAndLogError('Error saving the game!');
                }
                if (andThen != null) andThen();
            });
        } catch (e: Any) {
            q('ERROR saving the game: ${e}');
        }
    }
    public static function load(andThen: Bool -> Void) {
        function getJSONGameAttributeOr(name: String, or: Dynamic) {
            final stringJSON = getStringGameAttributeOr(name, null);
            var obj: Dynamic;
            if (stringJSON == null) return or;
            try {
                obj = haxe.Json.parse(stringJSON);
            } catch (e: Any) {
                return or;
            }
            return obj;
        }
        q('@ Loading game...');
        loadGame("mySave", function(success: Bool): Void {
            if (success == false) {
                q('WARNING: Failed to load game!');
                andThen(false);
                return;
            }
            if (getStringGameAttributeOr('SaveExists', 'NO') != 'YES') {
                q('@ Save does not exist.');
                andThen(false);
                return;
            }
            final saveVersion = getStringGameAttributeOr('SaveVersion', 'a-super-old-version'); // If no version is found and save exist, it must be a really old save
            if (saveVersion != Player.saveVersion) {
                q('NOTE: Save version ${saveVersion} different from the game save version ${Player.saveVersion}');
                andThen(false);
                return;
            }
            final playerObjectDynamic   = getJSONGameAttributeOr('PlayerJSON', Player.toDynamic());
            final settingsObjectDynamic = getJSONGameAttributeOr('SettingsJSON', savedSettings);
            Player.loadFromDynamic(playerObjectDynamic);
            Player.curateProgression(); // Used to 'normalize' the progression and fix any bugs or version related problems
            setSettings(settingsObjectDynamic);
            try {
                q('@ Loaded settings: ${haxe.Json.stringify(settingsObjectDynamic)}');
                q('@ Loaded player: ${haxe.Json.stringify(playerObjectDynamic)}');
            } catch (e: Any) {
                q('ERROR: Failed to stringify Player or Settings');
            }
            
            if (getStringGameAttributeOr('IsInRun', 'NO') == 'YES') {
                final mapObjectDynamic = getJSONGameAttributeOr('MapJSON', GameMap.toDynamic());
                GameMap.loadFromDynamic(mapObjectDynamic);
            }
            andThen(true);
        });
    }
    public static function clearSave(andThen: Void -> Void) {
        Player.resetProgression();
        setGameAttribute('IsInRun', 'NO');
        setGameAttribute('SaveExists', 'NO');
        saveGame('mySave', function(success: Bool) {
            if (success) trace('Save successful');
            else throwAndLogError('Error saving the game!');
            if (andThen != null) andThen();
        });
    }
    public static function createNewLogFile() {
        #if sys
        try {
            final timestamp = U.getTimestampString();
            final fileName = timestamp + '.txt';
            final filePath = 'assets/data/Logs/' + fileName;

            File.saveContent(filePath, 'New Log File: ${timestamp}\n');
            currentLogPath = filePath;
        } catch (e: Any) {
            trace('ERORR: Failed to create log file.');
            trace(e);
        }
        #end
    }
    public static function q(message: String) {
        trace(message);
        #if sys
        if (currentLogPath == null) return;
        try {
            final file = File.append(currentLogPath, false);
            file.writeString(message + '\n');
            file.close();
        } catch (e: Any) {
            trace('ERORR: Failed to write to log file.');
            trace(e);
        }
        #end
    }


    // Used in MainScene to reset save before loading
    public static function shouldResetSaveBeforeLoadAndThen(shouldResetSave: Bool, andThen: Void -> Void) {
        if (shouldResetSave) {
            clearSave(() -> {
                andThen();
            });
        } else {
            andThen();
        }
    }


    // Testing
    public static function mockGoToBattle(battleName: String) {
        // final andrew = Player.characters[0];
        // andrew.equipSpell('Dig');
        // andrew.equipSpell('Dark Lance');
        // andrew.addExperience(4);
        // andrew.equippedItems[0] = ItemsDatabase.get('Bit of Coal');
        // andrew.stats.speed += 6;
        // andrew.stats.dodge += 15;
        // andrew.stats.damage += 15;
        // Player.giveItem('Spell: Haymaker');
        // Player.giveItem('Spell: Intimidation');
        // var rook: PlayerCharacter;
        // if (Player.characters.length == 1) {
        //     rook = Player.addCharacter('Rook', 'Ranger');
        // } else {
        //     rook = Player.characters[1];
        // }
        // rook.equipSpell('Flare Shot');
        // rook.equipSpell('Disorient');
        // rook.equipSpell('Bear Trap');
        // rook.equipSpell('Fox Attack');
        // rook.equipSpell('Fox Companion');
        Battlefield.goToBattle(battleName);
    }
    public static function mockGoToShop() {
        if (Player.characters == null || Player.characters.length == 0) {
            Player.addCharacter('Hero', 'Knight');
        }
        Player.gold += 500;
        final mapNode = new MapNode('MERCHANT', {});
        mapNode.level = 1;
        Shop.goToShop(mapNode, () -> {});
    }
    public static function mockGoToBlacksmith() {
        if (Player.characters == null || Player.characters.length == 0) {
            Player.addCharacter('Hero', 'Knight');
        }
        Player.gold += 500;
        final mapNode = new MapNode('BLACKSMITH', {});
        mapNode.level = 1;
        Shop.goToShop(mapNode, () -> {});
    }
    public static function mockGoToNanaJoy() {
        if (Player.characters == null || Player.characters.length == 0) {
            Player.addCharacter('Hero', 'Knight');
        }
        Player.gold += 500;
        final mapNode = new MapNode('NANA_JOY', {});
        mapNode.level = 1;
        Shop.goToShop(mapNode, () -> {});
    }
    public static function mockGoToChapterSelect() {
        changeScene('UnlockableSelectScene');
    }
    public static function mockGoToMap() {
        // Player.startNewChapter(0);
        Player.giveItem('Cheese');
        GameMap.goToMapSceneAndGenerate(Chapters.chapters[1].journeys[2]);
    }
    public static function mockGoToAfteCombat(?options: Dynamic) {
        AfterCombat.goToAfterCombat(1, options, (item) -> { trace('Done'); });
    }
    public static function mockGoToCampfire() {
        Campfire.goToCampfire(() -> {});
    }
    public static function mockGoToNonCombatEvents(eventName: String) {
        NonCombatEvents.goToNonCombatEvents(eventName, () -> { trace('Done'); });
    }

    public static function testGame() {
        enableTurbo();
        Player.characters = [];
        U.defaultMusicVolume = 0;
        var andrew = Player.addCharacter('Andrew', 'Knight');
        var rook = Player.addCharacter('Rook', 'Ranger');
        Player.giveItem('Bit of Coal');
        Player.giveItem('Moldy Bread');
        // andrew.equipSpell('Long Reach');
        // andrew.equipSpell('Storm Spear');
        // andrew.equipSpell('ANCHORRR');
        // andrew.equipSpell('Implosion');
        // rook.equipSpell('Cobra Shot');
        // rook.equipSpell('Steady Shooting');
        // rook.equipSpell('Bola Shot');
        // rook.equipSpell('Crystal Arrow');
        // andrew.equipSpell('Unholy Revival');
        // andrew.equipSpell('Soul Drain');
        // andrew.equipItemStandalone(ItemsDatabase.get('Jade'));
        // andrew.equipItemStandalone(ItemsDatabase.get('Sword of 1000 Whats'));
        // Player.addCharacter('Rook', 'Ranger');
        // Player.addMercenary('Effigy');

        // mockGoToNonCombatEvents('Tyl Defeated');
        mockGoToMap();
        // mockGoToBattle('Test');
        // mockGoToAfteCombat({
        //     specificLoot: ['Torch', "Rodan's Ring", 'Mirror of Ice']
        // });
        // mockGoToShop();
        // mockGoToCampfire();
        // changeScene('UnlockableSelectScene');
        // changeScene('MyTestScene');
    }
    public static function enableTurbo() {
        Player.isTurboModeEnabled = true;
        Unit.k.slideToTileTime = 0.1;
        U.defaultMusicVolume = 0;
        U.defaultChangeSceneFadeTime = 0.05;
        Battlefield.halfASecond = 50;
        Battlefield.quarterSecond = 50;
        Unit.k.oneMoment = 50;
        Effects.SLOW = 2000;
        Effects.MEDIUM = 3000;
        Effects.FAST = 5000;
        MessageScreen.k.initialPauseDuration = 50;
        MessageScreen.k.fadeInDuration = 50;
        MessageScreen.k.pauseDuration = 50;
        MessageScreen.k.fadeOutDuration = 50;
    }
    public static function disableTurbo() {
        Player.isTurboModeEnabled = false;
        U.defaultChangeSceneFadeTime = 0.5;
        Battlefield.halfASecond = 500;
        Effects.SLOW = 100;
        Effects.MEDIUM = 250;
        Effects.FAST = 500;
    }
    public static function willSkipLoadSaveAreYouSure() {
        var areYouSure = 'definitely not';
        try {
            areYouSure = readFile('dont-load-save.areyousure');
        } catch (e: Any) {
            return false;
        }
        if (areYouSure == 'YES I AM SURE') {
            return true;
        }
        return false;
    }


}

