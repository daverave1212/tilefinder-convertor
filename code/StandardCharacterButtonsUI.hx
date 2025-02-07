
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

class StandardCharacterButtonsUI extends SimpleUI
{
    public static var self: StandardCharacterButtonsUI;
	public static var k = {
        padding: 12,
        mobileExtraMargin: 12
    }

    public var theOnlyButton: FramedItem;
    public var characterButtons: Array<FramedItem>;

    public var onClickOnOnlyButton: Void -> Void;
    public var onClickOnCharacterButton: Int -> Void;
    var isOpen = false;

    public function new() {
        super('StandardCharacterButtonsUI');
        self = this;
    }

    public override function load() {
        onClickOnOnlyButton = null;
        onClickOnCharacterButton = null;
        theOnlyButton = new FramedItem('Icons/Inventory.png', 'UI', 0, 0);
        theOnlyButton.setBottom(k.padding);
        theOnlyButton.setRight(k.padding + if (Game.isMobile) k.mobileExtraMargin else 0);
        theOnlyButton.anchorToScreen();
        theOnlyButton.enablePopAnimation();
        theOnlyButton.click = function() { onClickOnOnlyButton(); }
        characterButtons = [];
        for (i in 0...Player.characters.length) {
            var character = Player.characters[i];
            var characterButton = new FramedItem('Icons/${character.getClassName()}.png', 'UI', 0, 0);
            characterButton.setBottom(k.padding);
            characterButton.setLeft(k.padding + (k.padding + ICON_FRAME_SIZE) * i);
            characterButton.anchorToScreen();
            characterButton.click = function() {
                if (!isOpen) return;
                onClickOnCharacterButton(i);
            }
            characterButton.enablePopAnimation();
            characterButtons.push(characterButton);
        }
        close();
    }

    public override function open(?metadata: Array<Dynamic>) {
        onClickOnCharacterButton = cast metadata[0];
        onClickOnOnlyButton      = cast metadata[1];
        theOnlyButton.show();
        for (btn in characterButtons) {
            btn.show();
        }
        isOpen = true;
    }

    public function setButtonAnimation(iconPath: String) theOnlyButton.setIcon(iconPath);
    public override function close() {
        onClickOnOnlyButton = null;
        onClickOnCharacterButton = null;
        theOnlyButton.hide();
        for (btn in characterButtons) {
            btn.hide();
        }
        isOpen = false;
    }


    // Static functions
    public static function openInventoryForUseAuto(andThen: Void -> Void) {
        GUI.open('InventoryUI', [Player.inventory, USE, null, (itemClicked: Item) -> {
            if (itemClicked.type != 'CONSUMABLE') return;
            GUI.openWith('PopupUI', {
                item: itemClicked,
                reason: USE,
                callback: (didUseItem: Bool, whichCharacterIndex: Int) -> {
                    GUI.close('PopupUI');
                    GUI.close('InventoryUI');
                    if (didUseItem) {
                        itemClicked.onUse(null, Player.characters[whichCharacterIndex]);
                        final itemCoordinates: Position = itemClicked.consume(Player.inventory);				// Consumes the current item
                        InventoryUI.self.updateItemVisuals(itemCoordinates.i, itemCoordinates.j);				// Updates inventory visuals
                    }
                    andThen();
                }
            });
        }]);
    }

}