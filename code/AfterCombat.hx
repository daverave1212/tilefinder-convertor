
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
import scripts.Game.q;
import U.*;

import Std.int;

using U;






class AfterCombat {

    public static var k = {
        iconWidth: 34,
        extraItemsY: 320 - 34 - 4,
        extraItemsPadding: 12,
    }

    static var rewardLevel: Int = 1;
    static var specificLoot: Array<String>;
    
    static var itemChoices: Array<Item>;
    
    static var gearOrSpell = 'ANY';
    static var extraLootItemNames: Array<String>;
    static var extraExtraLootItemNames: Array<String>;  // Setup for special cases, before goToAfterCombat; adds extra items to extra loot
    static var extraGold: Int;                          // Setup for special cases, before goToAfterCombat; adds this gold to the next loot
    static var callback: Item -> Void;
    static var preventItemLoot: Bool = false;           // If true, nothing will happen when the player chooses the item
    static var autochooseItemForTesting: Bool = false;            // Used for testing only
    static var alwaysAutochooseItemForTesting: Bool = false;      // Used for testing only

    static var didClickOnChooseOnce = false;            // To prevent clicking on an item after choosing

    public static function goToAfterCombat(level: Int, ?options: {
        ?gearOrSpell: String,
        ?extraLootItemNames: Array<String>,
        ?specificLoot: Array<String>,
        ?preventItemLoot: Bool,
        ?autochooseItemForTesting: Bool
    }, andThen: Item -> Void) {
        if (options == null) {
            trace('Received null options');
            options = {};
        }
        gearOrSpell = if (options.gearOrSpell != null) options.gearOrSpell else 'ANY';
        trace('Received gearOrSpell as ${options.gearOrSpell}');
        extraLootItemNames = if (options.extraLootItemNames == null) [] else options.extraLootItemNames;
        preventItemLoot = if (options.preventItemLoot != null) options.preventItemLoot else false;
        specificLoot = options.specificLoot;
        if (extraExtraLootItemNames != null && extraExtraLootItemNames.length > 0) {
            extraLootItemNames = extraLootItemNames.concat(extraExtraLootItemNames);
            extraExtraLootItemNames = null;
        }
        autochooseItemForTesting     = if (options.autochooseItemForTesting != null) options.autochooseItemForTesting else false;
        rewardLevel        = level;
        callback           = andThen;

        changeScene('AfterCombatScene');
    }

    public static function start() {
        q('A: Starting After Combat');
        didClickOnChooseOnce = false;
        GUI.load('PopupUI');
        playAudio('AfterCombatAudio');
        setupGoldAndChestItems();
        final itemType = if (gearOrSpell == 'GEAR' || gearOrSpell == 'SPELL') gearOrSpell else (if (percentChance(25)) 'SPELL' else 'GEAR');
        setupItemLoot(itemType);
        if (autochooseItemForTesting || alwaysAutochooseItemForTesting) {
            final item: Item = randomOf(itemChoices);
            chooseItemAndContinue(item);
        }
        q('A: Finished After Combat setup');
    }

    static function setupItemLoot(spellOrGear: String) {
        final itemLevel = if (rewardLevel < 1) 1 else if (rewardLevel > 5) 5 else rewardLevel;
        final itemRarity = ANY_RARITY;
        
        q('A: Setting up item loot with ${spellOrGear}, level ${itemLevel} from reward level ${rewardLevel}');

        if (specificLoot != null) {
            itemChoices = specificLoot.map(name -> ItemsDatabase.get(name));
            specificLoot = null;
        } else {
            trace('Getting items...');
            itemChoices =
                if (spellOrGear == 'SPELL') ItemsDatabase.get3RandomItems({
                    usableTome: true,
                    type: 'SPELL',
                    maxLevel: itemLevel,
                    maxRarity: itemRarity,
                    excludeTags: [SPECIAL_ITEM]
                }) else ItemsDatabase.get3RandomItems({
                    type: 'GEAR',
                    level: itemLevel,
                    maxRarity: itemRarity,
                    excludeTags: [SPECIAL_ITEM]
                });
            trace('Getting 20%');
            if (percentChance(20) && specificLoot == null) {    // Only if it's random reward
                if (spellOrGear == 'GEAR') {
                    itemChoices[itemChoices.length - 1] = ItemsDatabase.getRandomItem({
                        type: 'SPELL',
                        usableTome: true,
                        maxLevel: itemLevel,
                        maxRarity: itemRarity
                    });
                } else if (spellOrGear == 'SPELL') {
                    itemChoices[itemChoices.length - 1] = ItemsDatabase.getRandomItem({
                        type: 'GEAR',
                        level: itemLevel,
                        maxRarity: itemRarity
                    });
                } else {
                    throw 'Unknown spellOrGear parameter ${spellOrGear}';
                }
            }
        }

        if (itemChoices.length == 0) {
            q('A: No item choices available of type ${spellOrGear}, item level ${itemLevel}.');
            doAfterFrom('setupItemLoot(${spellOrGear})', 250, () -> {
                AfterCombat.callback(null);
            });
            return;
        }

        final totalEmptySpace = getScreenWidth() - itemChoices.length * PopupUI.k.width;
        final padding = totalEmptySpace / (itemChoices.length + 1);
        for (i in 0...itemChoices.length) {
            final item = itemChoices[i];
            item.customData = { index: i };
            final x = padding + i * (PopupUI.k.width + padding);
            final popupUIInstance = PopupUI.newInstance(false);  // hasCloseButtonSlot = false
            popupUIInstance.openWith({
                item: item,
                reason: LOOT,
                x: x + 3,
                yOffset: -30,
                showCloseButton: false,
                callback: function(didClickOnChoose: Bool, _: Int) {
                    if (didClickOnChoose) {
                        playAudio('AfterCombatChooseAudio', 6); // Random channel that's not music channel
                        chooseItemAndContinue(item);
                    }
                }
            });
        }
    }
    static function getGoldMultiplierByLevel(level: Int): Float {
        switch (level) {
            case -1,0,1,2: return 1.0;
            case 3: return 0.85;
            case 4: return 0.8;
            case 5: return 0.7;
            case 6: return 0.65;
            default: return 1.0;
        }
    }
    static function getStandardGoldRewardByLevel(level: Int): Int {
        var goldAmount = Std.int(
            randomIntBetween(6, 10) *
            (level + 2) *
            getGoldMultiplierByLevel(level)   // To fix player getting too much gold later
        );
        return goldAmount;
    }
    static function setupGoldAndChestItems() {
        final allExtraItemsAndGold: Array<Item> = [];
        var goldAmount = Std.int(
            getStandardGoldRewardByLevel(rewardLevel) *
            if (Game.isMobile) 0.6 else 1    // To make it harder to acquire gold on mobile
        );

        // Special Item
        if (percentChance(35)) {
            goldAmount += 10 * Player.getNEquippedItemsWithName('Lucky Coin');
        }

        if (extraGold > 0) {
            goldAmount += extraGold;
            extraGold = 0;
        }
        if (Battlefield.chest.isDead) {
            allExtraItemsAndGold.push(ItemsDatabase.get(Battlefield.chest.itemDroppedName));
            goldAmount += Battlefield.chest.goldDropped;
        }
        if (Battlefield.killedVampireLord) {
            allExtraItemsAndGold.push(ItemsDatabase.get('Tooth of Insomnia'));
        }
        allExtraItemsAndGold.push(ItemsDatabase.get('Gold'));

        if (extraLootItemNames != null && extraLootItemNames.length > 0) {
            for (itemName in extraLootItemNames) {
                allExtraItemsAndGold.push(ItemsDatabase.get(itemName));
            }
        }

        // Draw them
        final extraRewardsPanel = new ImageX('UI/ExtraLootRewardsPanel.png', 'PanelsLayer');
        extraRewardsPanel.centerOnScreen().setBottom(0);
        final totalWidth = (allExtraItemsAndGold.length - 1) * AfterCombat.k.extraItemsPadding + allExtraItemsAndGold.length * AfterCombat.k.iconWidth;
        final startX = getScreenXCenter() - totalWidth / 2;
        for (i in 0...allExtraItemsAndGold.length) {
            final item = allExtraItemsAndGold[i];
            final x = startX + i * (AfterCombat.k.extraItemsPadding + ICON_FRAME_SIZE);
            final y = getScreenY() + getScreenHeight() - ICON_FRAME_SIZE - 2;
            var extraLootItemFramed: FramedItem;
            if (item.name == 'Gold') {
                extraLootItemFramed = new FramedItemWithGold(item.imagePath, 'ItemIconsLayer', goldAmount, x, y);
            } else {
                extraLootItemFramed = new FramedItem(item.imagePath, 'ItemIconsLayer', x, y);
            }
        }

        // Give them to the player
        Player.giveGold(goldAmount);
        for (item in allExtraItemsAndGold) {
            if (item.name != 'Gold')
                Player.giveItem(item);
        }
    }
    public static function setupExtraExtraLoot(array: Array<String>) extraExtraLootItemNames = array;
    public static function setupExtraGold(amount: Int) extraGold = amount;

    static function chooseItemAndContinue(item: Item) {
        if (didClickOnChooseOnce) return;
        didClickOnChooseOnce = true;
        if (preventItemLoot == false) {
            Player.giveItem(item);
            Player.autolearnOrEquip(item);
        }
        final itemName = if (item == null) 'null' else item.name;
        doAfterFrom('chooseItemAndContinue(${itemName})', 250, () -> {
            AfterCombat.callback(item);
        });
    }
    // static function onClickOnItem(item: Item) {
    //     if (didClickOnChooseOnce) return;
    //     if (GUI.isOpen('PopupUI')) return;
    //     GUI.openWith('PopupUI', {
    //         item: item,
    //         reason: LOOT,
    //         callback: (wasItemChosen: Bool, _: Int) -> {
    //             GUI.close('PopupUI');
    //             if (wasItemChosen) {
    //                 chooseItemAndContinue(item);
    //             }
    //         }
    //     });
    // }

   


}

class FramedItemWithGold extends FramedItem {
    public function new(imagePath: String, layer: String, amount: Int, x, y) {
        super(imagePath, layer, x, y);
        var priceFrame = new ImageX('UI/PriceFrame.png', 'ItemIconsOverlayLayer');
        priceFrame.setXY(frame.getX() - 4, frame.getY() - 4);
        final goldTextX = priceFrame.getXCenter();
        final goldTextY = priceFrame.getY() + 1;
        var goldText = new TextLine('', getFont(PRICE_FONT_ID), goldTextX, goldTextY);
        goldText.alignCenter();
        goldText.setText('' + amount);
        goldText.preventDrawing = () -> GUI.isOpen('PopupUI');
    }
}