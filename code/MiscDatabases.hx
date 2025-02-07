

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
import com.stencyl.graphics.ScaleMode;

import U.*;
using U;

import scripts.Constants.*;

class MiscDatabases {

    public static var merchantQuotes = [
        'I will buy ANYTHING from you!',
        'Oh jolly! A customer!',
        'The bird is not for sale!',
        'A snake your size bit my face once! Fun times!',
        'If you die, I\'m taking your stuff!',
        'I found these in a... actually, you don\'t wanna know...',
        'These items just fell from the sky! I swear!',
        "I found the bird in someone's house. Finders keepers!",
        "Remember: you can't equip 2 of the same item!",
        "If you buy it... don't tell Nagnus you got it from me!",
        "Did I tell you I had a crush on Nana Joy back in my day?",
        "I totally didn't take these from dead adventurers!",
        "Chests are never mimicks! Never!",
        'Flowers can cleanse a lot of unholy places!',
        'Never trust pirates! Unless...',
        'Cyclops cut their hand off, and sharpen the bone into a blade!',
        'Cyclops make their clothes from human skin!'
    ];

    public static var blacksmithQuotes = [
        'Ye gonna buy something or what?',
        "If ye see Willard, tell him he's an arse.",
        "Ladies are nice and all, but have ye ever seen an Elvish sword?",
        "Ever tried digging a grave? You might find something...",
        "Ye know, goblins are not bad at all!",
        "Don't disturb too many graves! It attracts vampires!",
        "ARMOR reduces your ATTACK damage taken (not FIRE, COLD or MAGIC).",
        "Armor works against metal or wooden traps too!",
        'You can not reduce damage below 1 with Armor.',
        'Flowers are rare, but useful in many events. Trust me, buddy.',
        'If a mercenary dies, it stays dead.',
        'Mermaids aren\'t very offensive, but gosh are they annoying...',
        'Careful! A mermaid might be the evil Vodyanoy in disguise!'
    ];

    public static var nanaJoyQuotes = [
        "Who's my favorite adventurer? Yes, you! <3",
        "My, oh, my! Who's this handsome gentleman? <3",
        "Are you hungry, dear? You look so skinny!",
        "You look like a real hero with that cape, dear!",
        "Aww, came to visit Nana Joy? How thoughtful! <3",
        "Remember, kids: you can't have the same spell twice!",
        "Let Nana Joy teach you a thing or 2...",
        "Some spells are ACTIVE, some are PASSIVE.",
        "Some monsters are vulnerable to FIRE or COLD!",
        "Be careful! Traps like toxic fog and acid deal PURE damage!",
        'Always bring flowers to an event! <3',
        'Some enemies become FEARFUL when alone, basically surrendering!'
    ];
	
    public static function getRandomMerchantQuote() return merchantQuotes[randomIntBetween(0, merchantQuotes.length - 1)];
    public static function getRandomBlacksmithQuote() return blacksmithQuotes[randomIntBetween(0, blacksmithQuotes.length - 1)];
    public static function getRandomNanaJoyQuote() return nanaJoyQuotes[randomIntBetween(0, nanaJoyQuotes.length - 1)];
    
    public static function getRandomGameOverMessage(): String {
        final options = [
            'R.I.P.',
            'Game Over',
            'Feels Bad Man',
            'YOU DIED',
            "Unlucky..."
        ];
        return randomOf(options);
    }

    public static final startingGear = [
        'Knight' => ['Studded Leather', 'Shivery Shiv'],
        'Ranger' => ['Hunter Hatchet'],
        'Mage'   => ['Bit of Coal', 'Cheap Mage Hat']
    ];

    // Saving
    public static var mockPlayerSaveJSON = '{}';
    public static var mockMapSaveJSON = '{}';

    // Settings
    public static final aspectRatios = [
        '16:9',
        '21:9',
        '4:3',
        '5:3',
        '5:4',
        '16:10'
    ];
        
    public static final resolutionOptions = [
            // iPhone 13 pro max (674.5x321)
        { name: '16:9 (1080p)', w: 480, h: 270, scale: ScaleMode.FULLSCREEN },
            // Xiaomi Redmi 9 Power
            // Xiaomi Redmi Note 10 Pro
            // Google Pixel 6                       | 600x270
            // Vivo V20                             | 600x270
            // TCL 20S                              | 600x270
            // iPhone 13 mini                       | 585x270
            // Samsung Galaxy Z Flip 3              | 660x270
            // Also 1280x720
        { name: '16:9 (Other)', w: 480, h: 360, scale: ScaleMode.FULLSCREEN },
            // e.g. 1280x960
            // e.g. 1440x1080
        { name: '4:3', w: 480, h: 320, scale: ScaleMode.FULLSCREEN },
            // 1650x1050
            // 1440x900
        { name: '16:10', w: 480, h: 350, scale: ScaleMode.FULLSCREEN },
            // 2K wide
        { name: '21:9', w: 480, h: 320, scale: ScaleMode.FULLSCREEN }
    ];

    public static function getNewGameMessagesBasedOnNRuns(nRuns: Int): Array<String> {
        final messages = [
            ['In times of need...', 'A hero arises!'],
            ['In times of need...', 'A hero tries again!'],
            ['A hero arises...', 'Again?'],
            ['Persistent, are you?'],
            ['In times blah blah...'],
            ['<invalid text>'],
            ['You\'re still here!?'],
            ['Pampam pararampam...'],
            ['In times of weed...', 'A hero arises!', 'Hehe... get it?']
        ];
        if (nRuns >= 0 && nRuns < 9) return messages[nRuns];
        else {
            final message: Array<String> = randomOf(messages);
            return message;
        }
    }



    // Buttons setup
    public static function setupCloseButton(closeButton: Actor, background: ImageX) {
        closeButton.enableActorDrawing();
		closeButton.growTo(1, 1, 0);
		closeButton.setX(background.getX() + background.getWidth() - closeButton.getWidth() - 3);
		closeButton.setY(background.getY() + 4);
    }
    public static function generatePauseButton(onClick: Void -> Void) {
        final pauseButton = new SUIButton('PauseActor', 'UI', null, { enablePopAnimations: true });
        pauseButton.setTop(if (Game.isMobile) 16 else 4);
        pauseButton.setRight(if (Game.isMobile) 16 else 4);
        pauseButton.click = onClick;
        return pauseButton;
    }
    public static function generateInspectButton(onClick: Void -> Void) {   // Only for Battlefield
        final inspectButton = new SUIButton('InspectButtonActor', 'UI', null, { enablePopAnimations: true });
        inspectButton.setTop(14 + 4 + if (Game.isMobile) 16 else 4);
        inspectButton.setRight(if (Game.isMobile) 16 else 4);
        inspectButton.click = onClick;

        var keyFrame: ImageX;
        var keyTextImage: ImageX;

        U.onEnter(() -> {
            FramedItem.doShowKeyFunctionality({
                keyFrame: keyFrame,
                keyTextImage: keyTextImage,
                frame: inspectButton.actor,
                text: 'Q',
                setKeyFrame: (newValue) -> keyFrame = newValue,
                setKeyTextImage: (newValue) -> keyTextImage = newValue
            });
        }, inspectButton.actor);

        U.onExit(() -> {
            FramedItem.doHideKeyFunctionality({
                keyFrame: keyFrame,
                keyTextImage: keyTextImage,
                setKeyFrame: (newValue) -> keyFrame = newValue,
                setKeyTextImage: (newValue) -> keyTextImage = newValue
            });
        }, inspectButton.actor);

        return inspectButton;
    }
}