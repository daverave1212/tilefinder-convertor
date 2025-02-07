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

class MainMenu
{
	public static function start() {

        try {
            Game.loadGameLicense();
        } catch (e: Any) {
            trace('WARNING: Failed to load license. Assuming full game.');
        }

        engine.moveCamera(getSceneWidth() / 2, 0);

        var xAnimate: Float = getScreenWidth() / 2;
        var yAnimate: Float = getScreenHeight();
        var yScrollExtra: Float = 0;
        var yScrollMinus: Float = 200;

        var isStillInIntro = true;

        function setupBackgroundParalax() {
            final imagesWithParalaxMultiply: Array<{name: String, ?image: ImageX, ?actor: Actor, maxParalaxX: Float, maxParalaxY: Float, originalX: Float, originalY: Float, cloudOriginalX: Float}> = [];
            function setupImage(name: String, paralaxMultiply: Float) {
                final image = new ImageX('Images/Backgrounds/Paralax/${name}.png', '${name}Layer');
                image.growTo(2, 2, 0);
                image.centerOnScreen();
                final originalX = image.getX();
                final originalY = image.getY();
                final maximumMouseOffsetX = getScreenWidth() / 2;
                final maximumMouseOffsetY = getScreenHeight() / 2;
                final maximumParalaxX = maximumMouseOffsetX * paralaxMultiply;
                final maximumParalaxY = maximumMouseOffsetY * paralaxMultiply;
                imagesWithParalaxMultiply.push({
                    name: name,
                    image: image,
                    cloudOriginalX: originalX,
                    originalX: originalX, originalY: originalY,
                    maxParalaxX: maximumParalaxX, maxParalaxY: maximumParalaxY
                });
                return image;
            }
            function setupActor(skyImage: ImageX, actorName: String, x: Float, y: Float, paralaxMultiply: Float, layer: String) {
                final actor = createActor(actorName, layer);
                final originalWidth = actor.getWidth();
                final originalHeight = actor.getHeight();
                actor.growTo(2, 2, 0);
                actor.setX(skyImage.getX() + x * 2 + originalWidth * 0.5);
                actor.setY(skyImage.getY() + y * 2 + originalHeight * 0.5);
                final originalX = actor.getX();
                final originalY = actor.getY();
                final maximumMouseOffsetX = getScreenWidth() / 2;
                final maximumMouseOffsetY = getScreenHeight() / 2;
                final maximumParalaxX = maximumMouseOffsetX * paralaxMultiply;
                final maximumParalaxY = maximumMouseOffsetY * paralaxMultiply;
                imagesWithParalaxMultiply.push({
                    name: actorName,
                    actor: actor,
                    cloudOriginalX: originalX,
                    originalX: originalX, originalY: originalY,
                    maxParalaxX: maximumParalaxX, maxParalaxY: maximumParalaxY
                });
                return actor;
            }
            // function setupClouds(sky: Actor) {
            //     final cloud1 = createActor('MenuCloudsActor', 'CloudsLayer');
            //     cloud1.setX(sky.getX() - cloud1.getWidth() / 2);
            //     cloud1.setY(sky.getY());
            //     final cloud2 = createActor('MenuCloudsActor', 'CloudsLayer');
            //     cloud1.setX(sky.getX() + sky.getWidth() - cloud1.getWidth() / 2);
            //     cloud1.setY(sky.getY());
            // }
            final sky = setupImage('Sky', 0.10);
            // TODO: Add 1more cloud
            // setupImage('Clouds', 0.15);
            final CLOUD_WIDTH = 382;
            setupActor(sky, 'MenuCloudsActor', - CLOUD_WIDTH, 0, 0.15, 'CloudsLayer');
            final mountain = setupActor(sky, 'MenuMountainsActor', 0, 0, 0.20, 'MountainsLayer');
            setupImage('Village', 0.25);
            setupImage('Pines', 0.30);
            setupImage('Cliff', 0.35);
            final heroCape = setupActor(sky, 'MenuHeroActor', 280, 92, 0.35, 'HeroLayer');
            heroCape.setFilter([createHueFilter(-15)]);
            setupImage('Lights', 0.40);

            final maximumMouseOffsetX = getScreenWidth() / 2;
            final maximumMouseOffsetY = getScreenHeight() / 2;
            doEvery(10, () -> {
                final mouseXOffset = if (Game.isMobile) 0 else maximumMouseOffsetX - getMouseX();
                final mouseYOffset = if (Game.isMobile) 0 else maximumMouseOffsetY - getMouseY();
                final mouseXOffsetPercent = mouseXOffset / maximumMouseOffsetX;
                final mouseYOffsetPercent = mouseYOffset / maximumMouseOffsetY;
                for (imageData in imagesWithParalaxMultiply) {
                    final paralaxOffsetX = imageData.maxParalaxX * mouseXOffsetPercent;
                    final paralaxOffsetY = imageData.maxParalaxY * mouseYOffsetPercent + yScrollExtra;
                    if (imageData.name == 'MenuCloudsActor') {
                        if (imageData.originalX > getScreenX() + getScreenWidth() + CLOUD_WIDTH / 2) {
                            imageData.originalX = imageData.cloudOriginalX;
                        }
                        imageData.originalX += 0.1;
                    }
                    if (imageData.image != null) {
                        imageData.image.setX(imageData.originalX + paralaxOffsetX);
                        imageData.image.setY(imageData.originalY + paralaxOffsetY);
                    }
                    if (imageData.actor != null) {
                        imageData.actor.setX(imageData.originalX + paralaxOffsetX);
                        imageData.actor.setY(imageData.originalY + paralaxOffsetY);
                    }
                }
            });

            animateValue(75, 0, 1750, (newValue: Float) -> {
                yScrollExtra = newValue;
            });
            doAfter(1800, () -> {
                isStillInIntro = false;
            });
        }
        setupBackgroundParalax();

        final logoButton = new SUIButton('LogoActor', 'UI', null, { enablePopAnimations: false });
        logoButton.actor.growTo(1.5, 1.5, 0);
        logoButton.centerHorizontally();
        logoButton.setTop(50);
        var clickedOnce = false;
        function go() {
            if (isStillInIntro) return;
            trace('Going!');
            if (clickedOnce) return;
            trace('Going! Okay, not clicked once.');
            clickedOnce = true;
            if (Player.progression.tutorialIsDone == false) {
                trace('Starting tut');
                Player.startTutorialRun();
            } else if (getStringGameAttributeOr('IsInRun', 'NO') == 'YES') {
                trace('Continuarr');
                Game.continueAfterLoad();
            } else {
                trace('Nevgam');
                Game.newGame();
            }
        }

        final buttonsBottom = 15;
        final steamButton = new SUIButton('ExternalLinkButtonActor', 'UI', 'Steam', { enablePopAnimations: false });
        final discordButton = new SUIButton('ExternalLinkButtonActor', 'UI', 'Discord', { enablePopAnimations: false });
        final startButton = new SButton('GenericMenuButtonActor', 'UI', 'Start');
        final feedbackButton = new SButton('GenericMenuButtonActor', 'UI', 'Give Feedback');
        final exitButton = new SButton('GenericMenuButtonActor', 'UI', 'Exit');
        
        startButton.centerHorizontally();
        startButton.setY(logoButton.getY() + 25);
        startButton.click = () -> go();

        feedbackButton.centerHorizontally();
        feedbackButton.setY(startButton.getY() + startButton.getHeight() + 4);
        feedbackButton.click = () -> openURLInBrowser(Constants.URL_FEEDBACK);

        exitButton.centerHorizontally();
        exitButton.setY(feedbackButton.getY() + feedbackButton.getHeight() + 4);
        exitButton.click = () -> {
            Game.closeAchievementTriggerer();
            exitGame();
        }

        final platformsY = exitButton.getY() + exitButton.getHeight() + 3;
        steamButton.actor.fadeTo(0.35, 0, Easing.linear);
        steamButton.actor.growTo(0.125, 0.125, 0);
        steamButton.setLeft(getScreenWidth() / 2 - 16 - 2);
        steamButton.setY(platformsY);
        steamButton.click = () -> openURLInBrowser(Constants.URL_STEAM);
        discordButton.actor.fadeTo(0.35, 0, Easing.linear);
        discordButton.actor.growTo(0.125, 0.125, 0);
        discordButton.setLeft(getScreenWidth() / 2 + 2);
        discordButton.setY(platformsY);
        discordButton.click = () -> openURLInBrowser(Constants.URL_DISCORD);
        
        final pauseButton = MiscDatabases.generatePauseButton(() -> {
            ResolutionSelect.goToResolutionSelect(false);
        });
        
        // final versionText = new TextLine(Player.updateVersion, getFont(UPDATE_VERSION_FONT));
        // versionText.enable();
        // versionText.setText(Player.updateVersion);
        // final versionTextX = getScreenX() + getScreenWidth() - getFont(UPDATE_VERSION_FONT).getTextWidth(Player.updateVersion) / Engine.SCALE - 2;
        // final versionTextY = getScreenY() + getScreenHeight() - getFont(UPDATE_VERSION_FONT).getHeight() / Engine.SCALE - 2;
        // versionText.setSceneX(versionTextX);
        // versionText.setSceneY(versionTextY);
        
        final patchNotesWidth = 110;
        final patchNotes = new TextBox(patchNotesWidth, 63, 0, 0, getFont(PATCH_NOTES_FONT));
        patchNotes.lineSpacing = 8;
        patchNotes.alignRight = true;
        if (Game.isMobile) {
            patchNotes.setText(Player.patchNotesMobile);
        } else {
            patchNotes.setText(Player.patchNotes);
        }
        patchNotes.alpha = 0.5;
        patchNotes.startDrawing();
        patchNotes.x = getScreenX() + getScreenWidth() - 2;
        patchNotes.y = getScreenY() + getScreenHeight() - patchNotes.nLines * 8 - 2;

        final invisiblePatchNotesButton = createActor('InvisiblePatchNotesButton', 'UI');
        invisiblePatchNotesButton.setX(getScreenXRight() - invisiblePatchNotesButton.getWidth());
        invisiblePatchNotesButton.setY(getScreenYBottom() - invisiblePatchNotesButton.getHeight());
        onClick(() -> {
            if (Game.isMobile) return;
            openURLInBrowser(Player.patchNotesURL);
        }, invisiblePatchNotesButton);

        if (Player.progression.tutorialIsDone) {
            Game.setAchievement('TUTORIAL_IS_DONE');
        }
    }
}