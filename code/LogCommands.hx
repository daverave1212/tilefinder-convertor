
package scripts;
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

import com.stencyl.Config;
import com.stencyl.Engine;
import com.stencyl.Input;
import com.stencyl.Key;
import com.stencyl.utils.motion.*;
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
import box2D.collision.shapes.B2Shape;

import com.stencyl.graphics.shaders.BasicShader;
import com.stencyl.graphics.shaders.GrayscaleShader;
import com.stencyl.graphics.shaders.SepiaShader;
import com.stencyl.graphics.shaders.InvertShader;
import com.stencyl.graphics.shaders.GrainShader;
import com.stencyl.graphics.shaders.ExternalShader;
import com.stencyl.graphics.shaders.InlineShader;
import com.stencyl.graphics.shaders.BlurShader;
import com.stencyl.graphics.shaders.SharpenShader;
import com.stencyl.graphics.shaders.ScanlineShader;
import com.stencyl.graphics.shaders.CSBShader;
import com.stencyl.graphics.shaders.HueShader;
import com.stencyl.graphics.shaders.TintShader;
import com.stencyl.graphics.shaders.BloomShader;



import scripts.Constants.*;
import Std.int;
import Std.parseInt;
import Std.parseFloat;
import U.*;
using U;

typedef Args = Array<String>;

class LogCommands
{

    public static var markers: Array<Actor> = [];   // Used for the mark function

	public static var commands: Map<String, (Args -> String)> = [
        'r' => function(args : Args) {
            var commandIndex = 1;
            if (args.length == 1) commandIndex = Std.parseInt(args[0]);
            var command = Log.commandOnlyHistory[Log.commandOnlyHistory.length - 1 - (commandIndex - 1)];
            Log.runCommand(command);
            return 'Ok.';
        },



        // Getters and information
        'getScreenX' => (_) -> '${getScreenX()}',
        'getScreenY' => (_) -> '${getScreenY()}',
        'setScreenX' => function(args: Args) {
            final x: Int = parseInt(args[0]);
            engine.moveCamera(x + getScreenWidth() / 2, getScreenYCenter());
            return x + '';
        },
        'setScreenY' => function(args: Args) {
            final y: Int = parseInt(args[0]);
            engine.moveCamera(getScreenXCenter(), y + getScreenHeight() / 2);
            return y + '';
        },
        'getScreenWidth' => (_) -> '${getScreenWidth()}',
        'getScreenHeight' => (_) -> '${getScreenHeight()}',
        'getSceneWidth' => (_) -> '${getSceneWidth()}',
        'getSceneHeight' => (_) -> '${getSceneHeight()}',
        'getNHeroes' => (_) -> '${Player.characters.length}',
        'getMouseX' => function(_ : Args) return '' + getMouseX(),
        'getMouseY' => function(_ : Args) return '' + getMouseY(),
        'Player.info' => function(args: Args) {
            Log.go('Gold: ${Player.gold}; ');
            Log.go('Items: ${Player.inventory.filterToArray(a -> a != null).length}');
            Log.go('Chars: ${Player.characters.map(chr -> chr.characterClass.name)}');
            return 'Ye?';
        },
        'monsterInfo' => function(args: Args) {
            final name: String = args[0];
            final units = Battlefield.unitsOnBattlefield.filter(u -> u.name.toLowerCase().indexOf(name.toLowerCase()) != -1);
            if (units.length == 0) return 'No unit named ${name} found.';
            if (args.length < 3) return 'Use example: "monsterInfo Peasant 1 spells"';
            final index = parseInt(args[1]);
            final unit = units[index];
            final infoType = args[2];
            return unit.getInfo(infoType);
        },

        // UI
        'GUI.isOpen' => function(args : Args) {
            var uiName : String = cast args[0];
            return '' + GUI.isOpen(uiName);
        },
        'GUI.openUIs' => function(_: Args) {
            return GUI.openUIs.map(ui -> ui.name).join(', ');
        },
        'PopupUI.self.backgroundPanel.setHeight' => function(args: Args) {
            var newHeight = parseInt(args[0]);
            PopupUI.self.popupUIInstance.backgroundPanel.setHeight(newHeight);
            return '' + newHeight;
        },
        'PopupUI.self.backgroundPanel.setMiddleHeight' => function(args: Args) {
            var newMiddleHeight = parseInt(args[0]);
            PopupUI.self.popupUIInstance.backgroundPanel.setMiddleHeight(newMiddleHeight);
            return '' + newMiddleHeight;
        },
        'closeInventory' => function(_ : Args){
            GUI.close('InventoryUI');
            return 'Ok';
        },

        // Battlefield specific commands
        'nt' => function(_: Args) {
            Battlefield.nextTurn();
            return 'Ok';
        },
        'Battlefield.nextTurn' => function(_ : Args) {
            Battlefield.nextTurn();
            return 'Ok';
        },
        'Battlefield.killGoblin' => function(_: Args) {
            findSimilarUnit('Goblin').kill();
            return 'TREMBLE, MORTALS!';
        },
        'Battlefield.spawnTrap' => function(args: Args) {
            final trapName = args[0];
            final i: Int = parseInt(args[1]);
            final j: Int = parseInt(args[2]);
            final didSpawn: Bool = Battlefield.spawnTrap(trapName, i, j) != null;
            if (didSpawn) return 'Ok';
            else return 'Failed to spawn trap.';
        },
        'Battlefield.spawnEnemy' => function(args: Args) {
            final unitName: String = args[0];
            final i: Int = parseInt(args[1]);
            final j: Int = parseInt(args[2]);
            Battlefield.spawnUnit(unitName, i, j, ENEMY);
            return 'Ok';
        },
        'Battlefield.spawnUnit' => function(args: Args) {
            final unitName: String = args[0];
            final i: Int = parseInt(args[1]);
            final j: Int = parseInt(args[2]);
            final owner =
                if (args[3] == 'NEUTRAL') NEUTRAL
                else if (args[3] == 'ENEMY') ENEMY
                else PLAYER;
            Battlefield.spawnUnit(unitName, i, j, owner);
            return 'Ok';
        },
        'Battlefield.setBackground' => function(args: Args) {
            var path: String = args[0];
            if (path.indexOf('Images/Backgrounds/') == -1)
                path += 'Images/Backgrounds/';
            if (path.indexOf('.png') == -1)
                path += '.png';
            Battlefield.backgroundImage.kill();
            Battlefield.backgroundImage = new ImageX(path, 'Background');
		    Battlefield.backgroundImage.centerOnScreen();
            return path;
        },
        'teleport' => function(args: Args) {
            final unitName: String = args[0];
            final i: Int = parseInt(args[1]);
            final j: Int = parseInt(args[2]);
            Battlefield.getUnitByName(unitName).putOnTile(Battlefield.getTile(i, j));
            return 'Ok';
        },
        'win' => function(args : Args) {
            Battlefield.endCombat(true);
            return 'Combat won.';
        },
        'lose' => function(args: Args) {
            Battlefield.endCombat(false);
            return 'Combat lost.';
        },
        'fwin' => function(args: Args) {
            U.defaultChangeSceneFadeTime = 0.05;
            Battlefield.endCombat(true, { autochooseItemForTesting: true });
            return 'Combat won fast';
        },
        'winAll' => function(args: Args) {
            Battlefield.currentWaveIndex = Battlefield.currentBattlefieldEncounter.waves.length - 1;
            Battlefield.endCombat(true);
            return 'Encounter won';
        },     
        'damage' => function(args: Args) {
            if (args.length == 0) return 'Which unit? (its name)';
            final unit = findSimilarUnit(args[0]);
            final amount = if (args.length < 2) 5 else parseInt(args[1]);
            if (unit == null) return 'No unit like ${args[0]} found';
            unit.damage(amount);
            return 'Ok.';
        },
        'damagePlayerCharacter' => function(args: Args) {
            Player.getCharacter(args[0]).health -= parseInt(args[1]);
            return "Ok.";
        },
        'say' => function(args : Args) {
            var unitName : String = if (args.length >= 1) args[0] else 'any';
            var text : String = if (args.length == 2) args[1] else 'Lorem ipsum dolor sit amet, sumus sumus!';
            var unit : Unit;
            if (unitName == 'any') {
                unit = Battlefield.unitsOnBattlefield[randomInt(0, Battlefield.unitsOnBattlefield.length - 1)];
            } else {
                unit = findSimilarUnit(unitName);
                if (unit == null) {
                    return 'Unit like ${unitName} not found.';
                }
            }
            unit.say(text, 2);
            return 'Ok.';
        },
        'fillMana' => function(_: Args) {
            if (getCurrentSceneName() != 'BattlefieldScene')
                return 'Can only do this in combat';
            for (unit in Battlefield.getAllAlivePlayerUnits()) {
                unit.mana = unit.stats.mana;
            }
            return 'Done';
        },
        'killAll' => function(args: Args) {
            if (getCurrentSceneName() != 'BattlefieldScene')
                return 'Can only do this in combat';
            var nKilled = 0;
            if (args.length == 0) {
                for (unit in Battlefield.getAllAliveEnemyUnits()) {
                    unit.damage(420, PURE);
                    nKilled++;
                }
            } else {
                final unitName = args[0];
                for (unit in Battlefield.getAllAliveEnemyUnits()) {
                    if (unit.name == unitName) {
                        unit.damage(420, PURE);
                        nKilled++;
                    }
                }
            }
            return if (nKilled > 0) 'That was a massacre.' else 'No.';
        },
        'currentUnitPosition' => function(_: Args) {
            final currentUnit = Battlefield.getCurrentlyActiveUnit();
            return '${currentUnit.getI()}, ${currentUnit.getJ()}';
        },
        'putOnTile' => function(args: Args) {
            final unitName = args[0];
            final i = parseInt(args[1]);
            final j = parseInt(args[2]);
            final unit = findSimilarUnit(unitName);
            if (unit == null) return 'Unit ${unitName} not found';
            unit.putOnTile(Battlefield.getTile(i, j));
            return 'Ok';
        },
        'heal' => function(args: Args) {
            final unitName = args[0];
            final amount = parseInt(args[1]);
            findSimilarUnit(unitName).heal(amount);
            return 'Ok';
        },
        'god' => function(_: Args) {
            for (unit in Battlefield.getAllAlivePlayerUnits()) {
                unit.stats.health += 100;
                unit.heal(999);
                unit.stats.damage += unit.stats.damage;
            }
            return 'God mode activated.';
        },

        // Game commands
        'mskip' => function(args: Args) {
            final nNodes = if (args.length == 0) 1 else Std.parseInt(args[0]);
            GameMap.skipNodes(nNodes);
            return 'Ok';
        },
        'GameMap.skip' => function(args: Args) {
            final nNodes = if (args.length == 0) 1 else Std.parseInt(args[0]);
            GameMap.skipNodes(nNodes);
            return 'Ok';
        },
        'GameMap.skipAll' => function(_: Args) {
            GameMap.skipNodes(99);
            return 'Ok';
        },
        'map' => function(_: Args) {
            GameMap.goToMapSceneAndContinue();
            return 'Ok';
        },
        'GameMap.goToMapSceneAndContinue' => function(_: Args) {
            GameMap.goToMapSceneAndContinue();
            return 'Ok';
        },
        'GameMap.resetMap' => function(_: Args) {
            Player.progression.currentJourneyIndex --;
            Player.startNextJourneyInThisChapter();
            return 'Ok';
        }, 
        'rj' => function(_: Args) {
            GameMap.goToMapSceneAndGenerate(Chapters.chapters[1].journeys[Player.progression.currentJourneyIndex]);
            return 'Restarting journey.';
        },
        'Game.restartJourney' => function(_: Args) {
		    GameMap.goToMapSceneAndGenerate(Chapters.chapters[1].journeys[Player.progression.currentJourneyIndex]);
            return 'Restarting journey.';
        },
        'nj' => function(args: Args) {
            final journeyIndex = if (args.length == 0) 0 else parseInt(args[0]);
            Player.startNewJourney(journeyIndex);
            return 'Ok';
        },
        'Game.newJourney' => function(args: Args) {
            final journeyIndex = if (args.length == 0) 0 else parseInt(args[0]);
            Player.startNewJourney(journeyIndex);
            return 'Ok';
        },
        'Game.fastNewGame' => function(args: Args) {
            Player._disableMessagesIntro = true;
            Player.startNewRun();
            return 'Ok';
        },
        'ng' => function(args: Args) {
            Player.startNewRun();
            return 'Ok';
        },
        'Game.newGame' => function(args: Args) {
            Player.startNewRun();
            return 'Ok';
        },
        'changeResolution' => function(args: Args) {
            ResolutionSelect.goToResolutionSelect(false);
            return 'Ok';
        },
        'getWindowedScale' => function(args: Args) {
            return '${Game.savedSettings.windowedScale}';
        },
        'skipTutorial' => function(args: Args) {
            Player.progression.tutorialDidClickOnMove = true;
            Player.progression.tutorialDidMoveOnce = true;
            Player.progression.tutorialDidClickOnAttack = true;
            Player.progression.tutorialDidAttackOnce = true;
            Player.progression.tutorialDidEndTurn = true;
            Player.progression.tutorialIsDone = true;
            Player.progression.tutorialDidUnlockableSelect = true;
            Player.progression.tutorialDidShopTutorial = true;
            return 'Set all tutorial Player.progression = true';
        },
        'tutorial' => function(args: Args) {
            Player.startTutorialRun();
            return 'Ok';
        },
        'Player.startTutorialRun' => function(args: Args) {
            Player.startTutorialRun();
            return 'Ok';
        },
        'Game.endJourney' => function(_: Args) {
            var lastAccessedNodeToBe = GameMap.getOnlyRootNode();
            while (!lastAccessedNodeToBe.isLastNode()) {
                lastAccessedNodeToBe = lastAccessedNodeToBe.getRandomNextNode();
            }
            GameMap.lastAccessedNode = lastAccessedNodeToBe;
            Player.continueJourney();
            return 'As you wish, my lord';
        },
        'continueJourney' => function(_: Args) {
            Player.continueJourney();
            return 'Ok';
        },
        'skipIntro' => function(_) {
            Intro.skipIntro();
            return 'Skipping intro.';
        },
        'CharacterSelect.setClass' => function(args: Args) {
            var animationName = args[0];
            CharacterSelect.character.setAnimation(animationName);
            return 'Changed.';
        },
        'setJourneyIndex' => function(args: Args) {
            Player.progression.currentJourneyIndex = Std.parseInt(args[0]);
            return '${Player.progression.currentJourneyIndex}';
        },
        'giveItem' => function(args : Args){
            var itemName = args[0];
            var itemId = Std.parseInt(itemName);
            var item : Item = if (itemId == null) ItemsDatabase.get(itemName) else ItemsDatabase.get(itemId);
            if (item == null) {
                return 'Item not found';
            } else {
                Player.giveItem(item);
                return 'Added ${item.name}';
            }
        },
        'getGold' => function(_ : Args) { return '' + Player.gold; },
        'giveGold' => function(args : Args){
            if(args.length == 0) Player.gold += 500;
            else {
                var amount : String = args[0];
                var value : Int = Std.parseInt(amount);
                Player.gold += value;
            }
            return 'Added gold.';
        },
        'equipItem' => function(args : Args) {
            if (args.length < 2) return 'Use equipItem 0 Quackmaster';
            final charIndex = parseInt(args[0]);
            final itemName = args[1];
            Player.characters[charIndex].equipItemStandalone(ItemsDatabase.get(itemName));
            return 'Ok';
        },
        'unequipItem' => function(args : Args) {
            if (!GUI.isOpen('CharacterUI')) return 'CharacterUI not open';
            var itemPos = Std.parseInt(args[0]);
            var character = CharacterUI.self.currentlyOpenCharacter;
            if (character.equippedItems[itemPos] == null) return 'No item at given position.';
            var didWork = character.unequipItemToInventory(itemPos, Player.inventory);
            if (!didWork) return 'Failed to unequip.';
            CharacterUI.self.reopen();
            return 'Ok.';
        },
        'equipSpell' => function(args: Args) {
            if (args.length < 2) return 'Use equipSpell charIndex spellName';
            final charIndex: Int = parseInt(args[0]);
            final spellName: String = args[1];
            Player.characters[charIndex].equipSpell(spellName);
            return spellName;
        },
        'unequipSpell' => function(args: Args) {
            final charIndex: Int = parseInt(args[0]);
            final spellName: String = args[1];
            Player.characters[charIndex].unequipSpell(spellName);
            return spellName;
        },
        'setCharStat' => function(args: Args) {
            if (args.length < 3) return 'Use setCharStat Knight damage 3';
            final char = Player.getCharacter(args[0]);
            if (char == null) return 'Character not found.';
            final stat = args[1];
            final value = parseInt(args[2]);
            char.stats.set(stat, value);
            return 'Ok';
        },
        'setPiratesGoldStored' => function(args: Args) {
            Player.progression.piratesGoldStored = parseInt(args[0]);
            return 'Ok';
        },
        'addPiratesItemStored' => function(args: Args) {
            Player.progression.piratesItemsStored.push(args[0]);
            return 'Ok';
        },
        'clearPiratesItemsStored' => function(_: Args) {
            Player.progression.piratesItemsStored = [];
            return 'Ok';
        },

        // Engine commands
        'musicOff' => function(_: Args) {
            U.defaultMusicVolume = 0;
            setVolumeForChannel(0, MUSIC_CHANNEL);
            return 'Music turned off';
        },        
        'musicVolume' => function(_: Args) {
            return '${U.defaultMusicVolume}';
        },
        'setMusicVolume' => function(args: Args) {
            final value: Float = parseFloat(args[0]);
            U.defaultMusicVolume = value;
            return '${value}';
        },
        'playAudio' => function(args: Args) {
            U.playAudio(args[0]);
            return 'Ok';
        },
        'save' => function(_: Args) {
            Game.save(() -> {});
            return 'Player saved';
        },
        'clearSave' => function(_: Args) {
            Game.clearSave(() -> {});
            return 'Ok';
        },
        'fullScreenOn' => function(_: Args) {
            engine.setFullScreen(true);
            return 'Ok';
        },
        'fullScreenOff' => function(_: Args) {
            engine.setFullScreen(false);
            return 'Ok';
        },
        'isFullScreen' => function(_: Args) {
            return '${engine.isInFullScreen()}';
        },
        'gameScale' => function(args: Args) {
            // Game heights: 
            final gScale: Int = parseInt(args[0]);
            Config.gameScale = gScale;
            engine.reloadScreen();
            return 'Ok';
        },
        'Engine.SCALE' => function(_: Args) {
            return Engine.SCALE + '';
        },
        'reloadScene' => function(_: Args) {
            U.changeScene(getCurrentSceneName());
            return 'Reloading "${getCurrentSceneName()}"';
        },
        'changeScene' => function(args: Args) {
            U.changeScene(args[0]);
            return 'Switching to ${args[0]}';
        },

        // Scene transitions
        'mockGoToBattle' => function(args: Args): String {
            if (Player.characters.length == 0) {
                final ch1 = Player.addCharacter('Hero', 'Knight');
            }
            Log.runCommand('musicOff');
            final battleName: String = if (args.length == 0) 'Peas' else args[0];
            Game.mockGoToBattle(battleName);
            return 'Ok';
        },
        'shop' => function(_: Args) {
            Game.mockGoToShop();
            return 'Ok';
        },
        'mockGoToShop' => function(_: Args) {
            Game.mockGoToShop();
            return 'Ok';
        },
        'mockGoToBlacksmith' => function(_: Args) {
            Game.mockGoToBlacksmith();
            return 'Ok';
        },
        'mockGoToNanaJoy' => function(_: Args) {
            Game.mockGoToNanaJoy();
            return 'Ok';
        },
        'mockGoToChapterSelect' => function(_: Args) {
            Game.mockGoToChapterSelect();
            return 'Ok';
        },
        'mockGoToMap' => function(_: Args) {
            Game.mockGoToMap();
            return 'Ok';
        },
        'at' => function(_: Args) {
            Game.mockGoToAfteCombat();
            return 'Ok';
        },
        'mockGoToAfterCombat' => function(_: Args) {
            Game.mockGoToAfteCombat();
            return 'Ok';
        },
        'mockGoToCampfire' => function(_: Args) {
            Game.mockGoToCampfire();
            return 'Ok';
        },
        'goToNonCombatEvents' => function(args: Args) {
            Game.mockGoToNonCombatEvents(args[0]);
            return 'Ok';
        },
        'goToAfterCombat' => function(args: Args) {
            for (arg in args) {
                if (ItemsDatabase.itemExists(arg) == false) {
                    return 'Item "${arg}" not found.';
                }
            }
            final options = {
                specificLoot: args
            };
            AfterCombat.goToAfterCombat(1, options, (item) -> {});
            return 'Ok';
        },
        'menu' => function(_: Args) {
            U.changeScene('MenuScene');
            return 'Ok';
        },
        'battle' => function(args: Args) {
            var encounterName: String = if (args.length == 0) 'Peas' else args[0];
            if (encounterName == 'random') {
                final randomEncounter = BattlefieldEncounterDatabase.getRandomEncounterOfLevel(randomIntBetween(1, 5));
                encounterName = randomEncounter.name;
            }
            var wave: Int = 0;
            if (args.length == 2) {
                wave = Std.parseInt(args[1]);
            }
            if (getCurrentSceneName() == 'IntroScene') {
                Intro.skip = true;
            }
            Sayer.reset();
            if (BattlefieldEncounterDatabase.exists(encounterName) == false) {
                return 'That encounter does not exist.';
            }
            Battlefield.goToBattle(encounterName, wave);
            return 'Let\'s fight!';
        },
        
        // Non Combat Events
        'NonCombatEvents.setBackground' => function(args: Args) {
            final bgName: String = args[0];
            final path = 'Images/Backgrounds/${bgName}.png';
            NonCombatEvents.setBackground(path);
            return 'Ok';
        },

        // Testing
        'disableIntroMessages' => function(_: Args) {
            Player._disableMessagesIntro = true;
            return 'Ok';
        },
        'enableTurbo' => function(_: Args) {
            Game.enableTurbo();
            return 'Turbo mode enabled.';
        },
        'disableTurbo' => function(_: Args) {
            Game.disableTurbo();
            return 'Turbo mode disabled';
        },
        'Player.resetProgression' => function(_: Args) {
            Player.resetProgression();
            return 'Ok';
        },
        'Player.setProgressionValue' => function(args: Args) {
            final key: String = args[0];
            final value: String = args[1];
            try {
                U.setObjectFieldSmart(Player.progression, key, value);
                return 'Ok';
            } catch (e: String) {
                return e;
            }
            return 'Unknown error.';
        },
        'spv' => function(args: Args) {
            final key: String = args[0];
            final value: String = args[1];
            try {
                U.setObjectFieldSmart(Player.progression, key, value);
                return 'Ok';
            } catch (e: String) {
                return e;
            }
            return 'Unknown error.';
        },
        'Player.resetNanaJoyProgression' => function(args: Args) {
            Player.progression.didNanaJoyMeeting = false;
            Player.progression.defeatedSandman = false;
            Player.progression.didNanaJoyAfterDialogue = false;
            return 'Ok';
        },
        'Player.getProgressionValue' => function(args: Args) {
            return haxe.Json.stringify(Reflect.field(Player.progression, args[0].toString()));
        },
        'Game.getSettingsValue' => function(args: Args) {
            return haxe.Json.stringify(Reflect.field(Game.savedSettings, args[0].toString()));
        },
        'testExpoY' => function(args: Args) {
            var from = new Point(parseInt(args[0]), parseInt(args[1]));
            var to = new Point(parseInt(args[2]), parseInt(args[3]));
            Effects.sendArcMissileAndThen(from, to, 'Frost Bolt', Effects.MEDIUM, () -> {});
            return 'Ok';
        },
        'mark' => function(args: Args) {
            final x = parseInt(args[0]);
            final y = parseInt(args[1]);
            final marker = createRecycledActor(getActorTypeByName('TestRectMarker'), x, y, Script.FRONT);
            marker.setAnimation('Marker');
            return 'Ok';
        },
        'getNode' => function(args: Args) {
            final tierIndex = parseInt(args[0]);
            final nodeIndexInTier = parseInt(args[1]);
            final node = GameMap.nodesByTier[tierIndex][nodeIndexInTier];
            return '${node.type} ${node.state} level=${node.level} anim=${node.icon.getAnimation()}';
        },
        'swapChars' => function(args: Args) {
            Player.characters = [];
            Player.reset();
            if (args.length == 0)
                args = ['Knight', 'Ranger'];
            final char1: String = args[0];
            final ch1 = Player.addCharacter('Hero', char1);
            if (args.length > 1) {
                final char2: String = args[1];
                final ch2 = Player.addCharacter('Hero', char2);
            }
            trace('Now player has ${Player.characters.length} chars');
            return 'Ok';
        },
        'test' => function(args: Args) {
            Log.runCommand('musicOff');
            Log.runCommand('swapChars Knight Ranger');
            Log.runCommand('skipTutorial');
            Log.runCommand('disableIntroMessages');
            return 'Ok';
        },
        'setVar' => function(args: Args) {
            final varname = args[0];
            final value = args[1];
            Log.variables[varname] = value;
            return 'Ok';
        },
        'getVar' => function(args: Args) {
            if (Log.variables.exists(args[0]))
                return Log.variables[args[0]];
            else return 'null';
        },
        'testJourney2' => function(_: Args) {
            Player.characters = [];
            final kn = Player.addCharacter('Andrew', 'Knight');
            final ra = Player.addCharacter('Roger', 'Ranger');
            Player.giveRandomItemsForTesting();
            Player.progression.currentJourneyIndex = 1;
            GameMap.goToMapSceneAndGenerate(Chapters.chapters[1].journeys[1]);
            return 'Ok';
        },
        'giveRandomItems' => function(_: Args) {
            Player.giveRandomItemsForTesting();
            return 'Ok';
        },
        'setupChars1.1' => function(_: Args) {
            Player.characters = [];
            final ch1 = Player.addCharacter('Hero', 'Knight');
            final ch2 = Player.addCharacter('Hero', 'Ranger');
            ch1.equipItemStandalone('Holey Shield');
            ch1.equipItemStandalone('Traveler Boots');
            ch1.equipItemStandalone('Cheap Mage Hat');
            ch2.equipItemStandalone('Hunter Hatchet');
            ch2.equipItemStandalone('Regular Goat Horn');
            ch2.equipItemStandalone('Light Bow');
            ch2.equipItemStandalone('Poaching Dagger');

            ch1.equipSpell('Long Reach');
            return 'Ok';
        },
        'setupChars1.2' => function(_: Args) {
            Player.characters = [];
            final ch1 = Player.addCharacter('Hero', 'Mage');
            final ch2 = Player.addCharacter('Hero', 'Ranger');
            ch1.equipItemStandalone('Bit of Coal');
            ch1.equipItemStandalone('Jade');
            ch1.equipItemStandalone('Cheap Mage Hat');
            ch1.equipItemStandalone('Rodan\'s Ring');
            ch2.equipItemStandalone('Hunter Hatchet');
            ch2.equipItemStandalone('Regular Goat Horn');
            ch2.equipItemStandalone('Light Bow');
            ch2.equipItemStandalone('Poaching Dagger');
            return 'Ok';
        },
        'testTurbo' => function(_: Args) {
            Game.enableTurbo();
            Player.startNewRun();
            return 'Go!';
        },
        'infect' => function(_: Args) {
            Battlefield.currentlyActiveUnit.infectRandomUninfectedSpell();
            BattlefieldUI.self.updateSpellButtons(Battlefield.currentlyActiveUnit);
            return 'Ok';
        },
        'root' => function(_: Args) {
            Battlefield.currentlyActiveUnit.root();
            BattlefieldUI.self.updateSpellButtons(Battlefield.currentlyActiveUnit);
            return 'Ok';
        },
        'silence' => function(args: Args) {
            final unitAffected =
                if (args.length == 0) Battlefield.currentlyActiveUnit
                else Battlefield.getUnitByNameLike(args[0]);
            if (unitAffected == null) {
                return 'No unit found.';
            }
            unitAffected.silence();
            return 'Ok';
        },
        'loadProgression' => function(_: Args) {
            final json = readFile('tprog.json');
            Player.progression = haxe.Json.parse(json);
            if (Player.progression.piratesItemsStored.length > 0 && Player.progression.piratesItemsStored[0] == 'nothing') {
                Player.progression.piratesItemsStored = [];
            }
            if (Player.progression.lectureTablePassives.length > 0 && Player.progression.lectureTablePassives[0].char == 'nothing') {
                Player.progression.lectureTablePassives = [];
            }
            return 'Ok';
        },
        'printPlayerJSON' => function(_: Args) {
            trace(haxe.Json.stringify(Player.toDynamic()));
            return 'Printed to console.';
        },
        'printSettingsJSON' => function(_: Args) {
            trace(haxe.Json.stringify(Game.savedSettings));
            return 'Printed to console.';
        },
        'printMapJSON' => function(_: Args) {
            trace(haxe.Json.stringify(GameMap.toDynamic()));
            return 'Printed to console.';
        },
        'loadIsInRun' => function(_: Args) {
            final yesOrNo = readFile('IsInRun.txt');
            setGameAttribute('IsInRun', yesOrNo);
            return 'Ok';
        },
        'loadPlayerJSON' => function(_: Args) {         // Loads a custom PlayerJSON attribute from the extras folder
            final json = readFile('PlayerJSON.json');
            final playerObjectDynamic = haxe.Json.parse(json);
            Player.loadFromDynamic(playerObjectDynamic);
            return 'Ok. Now go back to the menu.';
        },
        'loadSettingsJSON' => function(_: Args) {       // Loads a custom SettingsJSON attribute from the extras folder
            final json = readFile('SettingsJSON.json');
            final settingsObjectDynamic = haxe.Json.parse(json);
            Game.setSettings(settingsObjectDynamic);
            return 'Ok. Now go back to the menu.';
        },
        'loadMapJSON' => function(_: Args) {            // Loads a custom MapJSON attribute from the extras folder
            final json = readFile('MapJSON.json');
            final mapObjectDynamic = haxe.Json.parse(json);
            GameMap.loadFromDynamic(mapObjectDynamic);
            return 'Ok. Now go back to the menu.';
        },
        'skipCutscene' => function(_: Args) {
            NonCombatEvents.callback();
            return 'Ok';
        },
        'setAchievement' => function(args: Args) {
            Game.setAchievement(args[0]);
            return 'Ok';
        },
        'Sys.command' => function(args: Args) {
            #if sys
            Sys.command(args[0]);
            return 'Ok';
            #else
            return 'Not on Sys platform.';
            #end
        },
        'exportSpellNamesAndDescriptions' => function(_: Args) {
            SpellDatabase.exportSpellNamesAndDescriptions();
            return 'Ok';
        },
        'enableMobileDebugMode' => function(_: Args) {
            Game.isDebugMode = true;
            return 'Ok';
        },
        'disableMobileDebugMode' => function(_: Args) {
            Game.isDebugMode = false;
            return 'Ok';
        },
        'ad' => function(_: Args) {
            showInterstitialAd();
            loadInterstitialAd();
            return 'Ok';
        },
        'loadAd' => function(_: Args) {
            loadInterstitialAd();
            return 'Ok';
        },
        'showAd' => function(_: Args) {
            showInterstitialAd();
            return 'Ok';
        },
    ];

    public static function addSimple(name: String, cmd: Void -> Void) {
        commands[name] = function(_: Args) {
            cmd();
            return 'Ok';
        }
    }
    static function findSimilarUnit(name: String) {
        final possibleUnits = Battlefield.unitsOnBattlefield.filter(u -> u.isDead == false && u.name.toLowerCase().indexOf(name.toLowerCase()) != -1);
        if (possibleUnits.length == 0) return null;
        else return possibleUnits[0];
    }
}