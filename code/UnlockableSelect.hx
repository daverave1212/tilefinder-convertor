
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
import Std.int;


import scripts.Constants.*;
import scripts.SpecialEffectsFluff.sayAlert;
import U.*;

class UnlockableSelect
{

    public static var k = {
        startButtonBottom: 10
    }

    public static var playerState = 'IDLE';
    public static var startButton: SUIButton;

	public static function start() {
        startButton = new SUIButton('GenericButtonHugeActor', 'BannersLayer');
        startButton.centerHorizontally();
        startButton.setBottom(k.startButtonBottom);
        startButton.setText('START', getFont(BROWN_ON_BROWN_TITLE_FONT), BUTTON_TEXT_Y);
        startButton.click = () -> {
            if (playerState != 'IDLE') return;
            Player.startNewRun();
        }
        final bannerPadding =
            (getScreenHeight()
            - startButton.getHeight() - k.startButtonBottom
            - 2 * UnlockableBanner.k.bannerHeight)
            / 3;
        createBanners() ;
        if (Player.progression.tutorialDidUnlockableSelect == false) {
            Player.progression.tutorialDidUnlockableSelect = true;
            startTutorial();
        }
    }

    public static var currentBannerIndex = 0;
    static function createBanners() {
        new UnlockableBanner('Tutorial Done', 'Icons/HelmetLogo.png', COMMON, Player.progression.tutorialIsDone, "Gives you access to the normal game mode.");
        new UnlockableBanner('Ranger', 'Icons/Ranger.png', COMMON, Player.progression.isRangerUnlocked, "You can start a new run as Rook the Ranger.");
        new UnlockableBanner('Mage', 'Icons/Mage.png', COMMON, Player.progression.isMageUnlocked, "You can start a new run as the Aelina the Mage.");
        new UnlockableBanner('Cellar Key', 'Icons/CellarKey.png', RARE, Player.progression.isCellarKeyFound, "Unlocks the blacksmith's cellar.");
        new UnlockableBanner('Starting Gear', 'Icons/GoodApparel.png', RARE, Player.progression.hasStartingGear, "Unlocks starting equipment for all characters.");
        new UnlockableBanner('Fell Pumpzilla', 'Icons/Pumpzilla.png', RARE, Player.progression.defeatedPumpzilla, "Defeated Pumpzilla, unlocking extra encounters.");
        new UnlockableBanner('Fell Stormjr', 'Icons/Stormjr.png', RARE, Player.progression.defeatedStormjr, "Defeated Stormjr, unlocking extra encounters and items.");
        new UnlockableBanner('Fell Spatula 1', 'Icons/CountSpatula.png', RARE, Player.progression.defeatedSpatula1, "Defeated Count Spatula 1, unlocking extra spells and items.");
        new UnlockableBanner('Fell Spatula 2', 'Icons/CountSpatula.png', RARE, Player.progression.defeatedSpatula2, "Defeated Count Spatula 2, unlocking extra spells and items.");
        new UnlockableBanner('Fell Children', 'Icons/BlessedChildren.png', RARE, Player.progression.defeatedBlessedChildren, "Defeated Blessed Children of Almund, unlocking extra items.");
        new UnlockableBanner('Fell Almund', 'Icons/FatherAlmund.png', RARE, Player.progression.defeatedFatherAlmund, "Defeated Father Almund, unlocking extra encounters.");
        new UnlockableBanner('Fell King', 'Icons/KingErio.png', RARE, Player.progression.defeatedKingOrMarceline && Player.progression.sidedWith == 'King', "Defeated King Erio, unlocking extra encounters.");
        new UnlockableBanner('Fell Marceline', 'Icons/Marceline.png', RARE, Player.progression.defeatedKingOrMarceline && Player.progression.sidedWith == 'Marceline', "Defeated Marceline, unlocking extra encounters.");
        new UnlockableBanner('Fell Tyl', 'Icons/Tyl.png', RARE, Player.progression.defeatedTyl, "Defeated Tyl, unlocking all remaining extra content.");
        new UnlockableBanner('Pieces Found (1)', 'Icons/Pieces1.png', RARE, Player.progression.nTileShardsFound > 0, "Marks progression in the game.");
        new UnlockableBanner('Pieces Found (2)', 'Icons/Pieces2.png', RARE, Player.progression.nTileShardsFound > 1, "Marks progression in the game.");
        new UnlockableBanner('Pieces Found (3)', 'Icons/Pieces3.png', RARE, Player.progression.nTileShardsFound > 2, "Marks progression in the game.");
        new UnlockableBanner('Pieces Found (4)', 'Icons/Pieces4.png', RARE, Player.progression.nTileShardsFound > 3, "Marks progression in the game.");
        new UnlockableBanner('Vampire Weakened', 'Icons/EvilOrb.png', RARE, Player.progression.isVampireWeakened, "Weakens Count Spatula forever.");
        new UnlockableBanner('Fallen Hero', 'Icons/Smite.png', RARE, Player.progression.isFallenHeroReunited, "Unlocks the permanent Fallen Hero buff.");
        new UnlockableBanner('Natas Defeated', 'Icons/Natas.png', RARE, Player.progression.isVampireWeakened, "Unlocks the permanent Natas buff.");
    }

    static function startTutorial() {
        var lastTriggeredSay: SayerReturnObject;
        function alertAndWait(message: String) {
            lastTriggeredSay = sayAlert(message, getScreenXCenter(), getScreenYCenter(), -1);
        }
        playerState = 'TUTORIAL';
        var currentMessageIndex = 0;
        final messages = [
            "This page displays what features you have unlocked.",
            "All of these are unlocked by doing specific things during a run, whether you die or finish!",
            "Bosses, enemies and events can change from run to run, depending on unlockables.",
            "You will need to finish multiple runs to get the final ending!"
        ];
        doAfter(500, () -> {
            alertAndWait(messages[currentMessageIndex]);
            currentMessageIndex++;
            onClick(function(): Void {
                if (playerState != 'TUTORIAL') return;
                Sayer.remove(lastTriggeredSay);
                if (currentMessageIndex >= messages.length) {
                    playerState = 'IDLE';
                    return;
                }
                alertAndWait(messages[currentMessageIndex]);
                currentMessageIndex++;
            });
        });
    }
}

class UnlockableBanner extends Positionable {

    public static var k = {
        bannerHeight: 125,
        bannerWidth: 100,
        bannerPadding: 10,
        titleOffsetY: 51,
        descriptionOffsetY: 93,
        descriptionWidth: 90,
        iconOffsetY: 7
    }
    
    public var bannerActor: Actor;
    public var framedIcon: FramedItem;
    public var title: TextLine;
    public var description: TextBox;

    public function new(name: String, iconPath: String, rarity: Int, isActive: Bool, desc: String) {
        if (isActive == false) return;
        final i = UnlockableSelect.currentBannerIndex;
        final x = k.bannerPadding + int(i / 2) * (k.bannerPadding + k.bannerWidth);
        final y = if (i % 2 == 0) k.bannerPadding else (k.bannerPadding * 2 + k.bannerHeight);

        bannerActor = createActor('UnlockableBannerActor', 'BannersLayer');
        bannerActor.setX(x);
        bannerActor.setY(y);
        bannerActor.setAnimation(
            if (rarity == COMMON) 'Common' else
            if (rarity == RARE) 'Rare' else
            if (rarity == EPIC) 'Epic'
            else 'Legendary'
        );
        final middleX = x + bannerActor.getWidth() / 2;
        framedIcon = new FramedItem(iconPath, 'IconsLayer', 0, 0);
        framedIcon.setX(middleX - ICON_FRAME_SIZE / 2);
        framedIcon.setY(y + k.iconOffsetY);
        title = new TextLine('', getFont(BROWN_ON_BROWN_TITLE_FONT), middleX, y + k.titleOffsetY);
        title.alignCenter();
        title.setText(name);
        description = new TextBox(k.descriptionWidth, 150, middleX, y +k.descriptionOffsetY, getFont(BROWN_ON_BROWN_TITLE_FONT));
        description.lineSpacing = 10;
        description.centerHorizontally = true;
        description.centerVertically = true;
        description.setText(desc);
        description.startDrawing();

        UnlockableSelect.currentBannerIndex += 1;
    }

}