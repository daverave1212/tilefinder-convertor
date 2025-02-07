
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
using U;

class Merchant extends TownNPC {

    public static var inventory : Inventory<Item>;

    public var k = {
        x : 300,
        y : 110
    }

    public function new(name){
        super(name, 'MerchantActor', k.x, k.y);
        inventory = new Inventory<Item>(4, 4);
        inventory.addArray([
            ItemsDatabase.get('Red Potion'),
            ItemsDatabase.get('Socks'),
            ItemsDatabase.get('Jade'),
            ItemsDatabase.get('Mason Gloves'),
            ItemsDatabase.get('Summer Dress'),
            ItemsDatabase.get('Moldy Bread'),
            ItemsDatabase.get('Cheap Mage Hat'),
            ItemsDatabase.get('Cheese')
        ]);
    }

    // public override function onClick(): Void{
    //     if (Town.playerState != IN_TOWN) return;
    //     GUI.open('InventoryUI', [inventory, BUY]);
    //     TownUI.self.inventoryButton.setAnimation('Back');
    //     Town.playerState = BUYING;
    // }

}

class Blacksmith extends TownNPC {

    public static var inventory : Inventory<Item>;

    public var k = {
        x : 100,
        y : 88
    }

    public function new(name){
        super(name, 'BlacksmithActor', k.x, k.y);
        inventory = new Inventory<Item>(4, 4);
        inventory.addArray([
            ItemsDatabase.get('Dirty Shirt'),
            ItemsDatabase.get('Fish Knife'),
            ItemsDatabase.get('Head Bucket'),
            ItemsDatabase.get('Holey Shield'),
            ItemsDatabase.get('Light Bow'),
            ItemsDatabase.get('Ok Shield')
        ]);
    }

    // public override function onClick(){
    //     if(Town.playerState != IN_TOWN) return;
    //     GUI.open('InventoryUI', [inventory, BUY]);
    //     TownUI.self.inventoryButton.setAnimation('Back');
    //     Town.playerState = BUYING;
    // }

}

class TownRegion {
    public var name: String = 'Not Set';
    public var x = 0;

    // public var inventory : Inventory<Item>;

    public function new(props: Dynamic) {
        name = props.name;
        x = props.x;
        // inventory = if (props.inventory != null) props.inventory else null;
    }

    public static function _getTemplateBlacksmithInventory() {
        var inventory = new Inventory<Item>(4, 4);
        inventory.addArray([
            ItemsDatabase.get('Dirty Shirt'),
            ItemsDatabase.get('Fish Knife'),
            ItemsDatabase.get('Head Bucket'),
            ItemsDatabase.get('Holey Shield'),
            ItemsDatabase.get('Light Bow'),
            ItemsDatabase.get('Ok Shield')
        ]);
        return inventory;
    }
    public static function _getTemplateMerchantInventory() {
        var inventory = new Inventory<Item>(4, 4);
        inventory.addArray([
            ItemsDatabase.get('Red Potion'),
            ItemsDatabase.get('Socks'),
            ItemsDatabase.get('Jade'),
            ItemsDatabase.get('Mason Gloves'),
            ItemsDatabase.get('Summer Dress'),
            ItemsDatabase.get('Moldy Bread'),
            ItemsDatabase.get('Cheap Mage Hat'),
            ItemsDatabase.get('Cheese')
        ]);
        return inventory;
    }

}

class Town {

    public static var k = {
        charactersBottom: 75,
        charactersPadding: -15,
        cameraSlideTime: 500            // Millisecons
    }

    public static var backgroundImage: ImageX;

    public static var townRegions: Array<TownRegion>;
    public static var currentRegionIndex = 0;

    public static var playerState = IN_TOWN;
    public static var charactersInTown : Array<CharacterInTown>;
	
    public static function start(){
        playerState = IN_TOWN;
        backgroundImage = new ImageX('Images/Backgrounds/TownBackground.png', 'Town');
        backgroundImage.centerOnScreen();
        spawnCharacters();
        townRegions = [
            new TownRegion({ name: 'Blacksmith', x: 345 }),
            new TownRegion({ name: 'Players', x: 770 }),
            new TownRegion({ name: 'Merchant', x: 1100 })
        ];
        GUI.load('InventoryUI');
        GUI.load('PopupUI');
        GUI.load('SpellPopupUI');
        GUI.load('TownUI');
        GUI.load('CharacterUI');
        engine.moveCamera(townRegions[currentRegionIndex].x, getScreenYCenter());
        decideIfHideOrShowArrows();

        U.onClick(() -> {
            if (playerState != IN_TOWN) return;
            playerState = BUYING;
            GUI.open('InventoryUI', [TownRegion._getTemplateBlacksmithInventory(), BUY]);
        }, getActor(2));

        U.onClick(() -> {
            if (playerState != IN_TOWN) return;
            playerState = BUYING;
            GUI.open('InventoryUI', [TownRegion._getTemplateMerchantInventory(), BUY]);
        }, getActor(3));

        U.onKeyPress(keyCode -> {
            var key = charFromCharCode(keyCode);
            if (key == 'd') moveCameraToNextRegion();
            if (key == 'a') moveCameraToPrevRegion();
        });
    }

    static function moveCameraToNextRegion() {
        currentRegionIndex++;
        if (currentRegionIndex >= townRegions.length) throwAndLogError('Town currentRegionIndex ${currentRegionIndex} out of bounds (0:${townRegions.length})');
        trace('Sliding camera to ${townRegions[currentRegionIndex].x}');
        U.slideCameraXCubic(townRegions[currentRegionIndex].x, k.cameraSlideTime);
    }
    static function moveCameraToPrevRegion() {
        currentRegionIndex--;
        if (currentRegionIndex < 0) throwAndLogError('Town currentRegionIndex ${currentRegionIndex} out of bounds (0:${townRegions.length})');
        U.slideCameraXCubic(townRegions[currentRegionIndex].x, k.cameraSlideTime);
    }
    static function decideIfHideOrShowArrows() {
        trace('Now at region x: ${townRegions[currentRegionIndex].x} and cameraX: ${getScreenXCenter()}');
        if (currentRegionIndex == 0) TownUI.self.hideArrowLeft();
        else if (currentRegionIndex == townRegions.length - 1) TownUI.self.hideArrowRight();
        else {
            TownUI.self.showArrowLeft();
            TownUI.self.showArrowRight();
        }
    }
    public static function onClickOnArrowLeft() {   // Called by TownUI arrow buttons
        moveCameraToPrevRegion();
        decideIfHideOrShowArrows();
    }
    public static function onClickOnArrowRight() {  // Called by TownUI arrow buttons
        moveCameraToNextRegion();
        decideIfHideOrShowArrows();
    }

    static function spawnCharacters(){
        charactersInTown = [for (character in Player.characters) new CharacterInTown(character)];
        for(c in charactersInTown) c.onClick = function() onClickOnCharacter(c);
        var charactersActors = [for (c in charactersInTown) c.actor];
        new ActorGroup(charactersActors)
            .alignHorizontally()
            .setPaddingX(k.charactersPadding)
            .centerHorizontallyInScene()
            .setBottom(k.charactersBottom);
    }

    public static function onClickOnCharacter(character : CharacterInTown){
        if (playerState != IN_TOWN) return;
        // Open...
        TownUI.self.inventoryButton.setAnimation('Back');
        playerState = INSPECTING_CHARACTER;
    }

    public static function onClickOnInventoryButton(){
        switch(playerState){
            case IN_TOWN:   // Open player inventory for inspect
                GUI.open('InventoryUI', [Player.inventory, SELL]);
                TownUI.self.inventoryButton.setAnimation('Back');
                playerState = SELLING;
            case BUYING, SELLING, EQUIPPING, UNEQUIPPING:
                GUI.close('PopupUI');
                GUI.close('InventoryUI');
                TownUI.self.inventoryButton.setAnimation('Inventory');
                playerState = IN_TOWN;
                trace('InventoryUI open? ${GUI.isOpen('InventoryUI')}');
			case INSPECTING_CHARACTER:
				GUI.close('CharacterUI');
                TownUI.self.inventoryButton.setAnimation('Inventory');
                playerState = IN_TOWN;
            case CHOOSING_SPELL_TO_LEARN:
                GUI.close('InventoryUI');
                GUI.close('SpellPopupUI');
                GUI.close('CharacterUI');
                TownUI.self.inventoryButton.setAnimation('Inventory');
                playerState = IN_TOWN;
        }
    }

    public static function onClickOnGate() {    // From the actual actor
        if (playerState != IN_TOWN || GUI.isOpen('InventoryUI')) return;
        U.changeScene('LevelSelectScene');
    }

}