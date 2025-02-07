
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
import Math.min;

class Campfire
{

    static var charactersAtCampfire: Array<Actor>;
    static var playerState = 'IDLE';        // INSPECTING (character)
    static var callback: Void -> Void;

    public static function start() {
        function setupCampfireAndCharacters() {
            centerCameraInScene();
            final backgroundImageName = 
                if (Battlefield.lastFoughtEncounterName == null) 'Images/Backgrounds/Forest.png'
                else BattlefieldEncounterDatabase.get(Battlefield.lastFoughtEncounterName).waves[0].getBackgroundImagePath();
            final backgroundImage = SpecialEffectsFluff.setupEventBackgroundImage(backgroundImageName, 35);
            // final backgroundImage = new ImageX(backgroundImageName, 'Background');
            // backgroundImage.centerOnScreen();
            final campfire = createActor('TrapActor', 'CampfireLayer');
            campfire.setAnimation('Fire');
            centerActorOnScreen(campfire);
            campfire.setY(campfire.getY() + 25);
            campfire.growTo(1.5, 1.5, 0);
            final shadow = createActor('CampfireStonesActor', 'CampfireShadowLayer'); shadow.setAnimation('CampfireShadow');
            shadow.setX(campfire.getX());
            shadow.setY(campfire.getY());
            shadow.growTo(1.5, 1.5, 0);
            final stones = createActor('CampfireStonesActor', 'CampfireStonesLayer'); stones.setAnimation('CampfireStones');
            stones.setX(campfire.getX());
            stones.setY(campfire.getY());
            stones.growTo(1.5, 1.5, 0);

            SpecialEffectsFluff.createDarknessInScene();
            
            charactersAtCampfire = [];
            final feetY = campfire.getY() + campfire.getHeight();
            final character1 = createActor('UnitActor', 'CharactersLayer');
            character1.setAnimation(Player.characters[0].getClassName());
            character1.setY(feetY - character1.getHeight());
            character1.setXCenter(campfire.getX() - campfire.getWidth() / 2 - 25);
            character1.growTo(1.5, 1.5, 0);
            charactersAtCampfire.push(character1);
            if (Player.characters.length > 1) {
                final character2 = createActor('UnitActor', 'CharactersLayer');
                character2.setAnimation(Player.characters[1].getClassName());
                character2.setY(feetY - character2.getHeight());
                character2.setXCenter(campfire.getX() + campfire.getWidth() * 1.5 + 25);
                character2.growTo(-1.5, 1.5, 0);
                charactersAtCampfire.push(character2);
            }
            GUI.open('StandardCharacterButtonsUI', [onClickOnCharacterButton, onClickOnOnlyButton]);
            U.showInterstitialAd();
            U.loadInterstitialAd();
        }
        function setupArrow() {
            final arrow = new SUIButton('ArrowActor', 'UI', 'ArrowRight', {
                enablePopAnimations: false
            });
            arrow.setupHoverAndClickAnimations({
                hover: {
                    animationName: 'ArrowRightHover',
                    textOffsetYChange: 0
                },
                click: {
                    animationName: 'ArrowRightClick',
                    textOffsetYChange: 0
                }
            });
            arrow.centerVertically().setRight(12 + if (Game.isMobile) 16 else 0);
            arrow.click = function() {
                onClickOnArrow();
            }
        }
        function healCharacters() {
            final healAmounts = Player.characters.map(char -> int(min(int(0.2 * char.stats.health), char.getMissingHealth())));
            for (i in 0...Player.characters.length) {
                Player.characters[i].heal(healAmounts[i]);
            }
            doAfter(1000, () -> {
                if (getCurrentSceneName() != 'CampfireScene') return;
                final scrollingTextManager = new ScrollingTextManager(getFont(SHADED_FONT_BIG_GREEN));
                for (i in 0...Player.characters.length) {
                    final x = charactersAtCampfire[i].getXCenter() - getScreenX();
                    final y = charactersAtCampfire[i].getYCenter() - getScreenY() - 10;
                    scrollingTextManager.pump(healAmounts[i] + '', x, y);
                }
            });
        }
        function setupFox() {
            final foxChar = Player.hasFox();
            if (foxChar == -1) return;
            final fox = createActor('UnitActor', 'CharactersLayer');
            fox.setAnimation('Fox Sleeping');
            fox.growTo(1.5, 1.5, 0);
            if (foxChar == 0) {
                fox.setX(charactersAtCampfire[0].getX() - 20);
                fox.setY(charactersAtCampfire[0].getY() + 20);
            } else if (foxChar == 1) {
                fox.setX(charactersAtCampfire[1].getX() + 20);
                fox.setY(charactersAtCampfire[1].getY() + 20);
                fox.growTo(-1.5, 1.5, 0);
            }
            onClick(() -> {
                final heartY = fox.getY() + 77 + randomIntBetween(-7, 0);
                final heartX = fox.getX() + (if (foxChar == 1) 31 else 96 - 31) + randomIntBetween(-7, 7);
                final heart = createActor('OtherParticles', 'CharactersLayer');
                heart.setAnimation('Heart');
                heart.setX(heartX); heart.setY(heartY);
                heart.moveBy(0, -15, 0.5, Easing.expoOut);
                doAfter(500, () -> {
                    if (getCurrentSceneName() != 'CampfireScene') return;
                    recycleActor(heart);
                });
            }, fox);
        }
        GUI.load('InventoryUI');
        GUI.load('PopupUI');
        GUI.load('SpellPopupUI');
        GUI.load('CharacterUI');
        GUI.load('StandardCharacterButtonsUI');
        setupCampfireAndCharacters();
        setupArrow();
        setupFox();
        healCharacters();
        playMusic('CampfireAudio');
    }


    public static function goToCampfire(andThen: Void -> Void) {
        changeScene('CampfireScene');
        callback = andThen;
    }

    static function onClickOnCharacterButton(i: Int) {
        if (playerState != 'IDLE') return;
        final pc = Player.characters[i];
        GUI.openWith('CharacterUI', {
            currentlyOpenCharacter: pc,
            onOpen: () -> {
                playerState = 'INSPECTING';
                StandardCharacterButtonsUI.self.setButtonAnimation('Icons/Back.png');
            }
        });
    }
    static function onClickOnOnlyButton() {
        switch (playerState) {
            case 'IDLE':
                playerState = 'USING';
                StandardCharacterButtonsUI.self.setButtonAnimation('Icons/Back.png');
                StandardCharacterButtonsUI.openInventoryForUseAuto(() -> {
                    StandardCharacterButtonsUI.self.setButtonAnimation('Icons/Inventory.png');
                    playerState = 'IDLE';
                });
            case 'USING', 'INSPECTING':
                playerState = 'IDLE';
                StandardCharacterButtonsUI.self.setButtonAnimation('Icons/Inventory.png');
                GUI.close('CharacterUI');
                GUI.close('InventoryUI');
                GUI.close('PopupUI');
        }
    }
    static function onClickOnArrow() {
        if (playerState != 'IDLE') return;
        if (Player.hasItem('Tooth of Insomnia')) {
            Player.removeItem(Player.getItem('Tooth of Insomnia'));
            Player.startNewJourney(3);
            return;
        }
        if (callback != null) {
            final theCallback = callback;   // To prevent scene transition problems
            callback = null;
            theCallback();
        }
    }
}