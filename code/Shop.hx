
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

import scripts.ItemsDatabase.getRandomItem;
import scripts.ItemsDatabase.getRandomGearOfLevel;
import scripts.ItemsDatabase.getRandomConsumableOfLevel;
import scripts.ItemsDatabase.getRandomUsableSpellTomeOfMaxLevel;
import scripts.ItemsDatabase.getRandomGearOfLevelWithTag;
import scripts.Constants.*;
import scripts.SpecialEffectsFluff.*;
import U.*;
using U;

class Shop {

    public static var k = {
        charactersBottom: 75,
        charactersPadding: -15,
        shopkeepRight: 75,
        sayBottomOffsetY: -62,
        shopInventoryRows: 3,
        shopInventoryCols: 4,
        feetYFromCenter: 75,
        backgroundImageExtraYOffset: 85,
    }


    public static var shopkeepActor: Actor;

    public static var backgroundImage: ImageX;
    public static var playerState = 'IDLE';
    public static var node: MapNode;
    public static var shopInventory: Inventory<Item>;
    public static var charactersInTown: Array<Actor> = [];

    public static var callback: Void -> Void;
	
    public static function goToShop(fromNode: MapNode, andThen: Void -> Void) {
        node = fromNode;
        callback = andThen;
        shopInventory = new Inventory<Item>(k.shopInventoryRows, k.shopInventoryCols);
        if (fromNode.shopItems != null)
            shopInventory.addArray(fromNode.shopItems.map(itemName -> ItemsDatabase.get(itemName)));
        else {
            switch (node.type) {
                case 'BLACKSMITH': setupBlacksmithInventory();
                case 'MERCHANT': setupMerchantInventory();
                case 'NANA_JOY': setupNanaJoyInventory();
                default: throwAndLogError('Case for shop type ${node.type} not implemented');
            }
        }
        changeScene('ShopScene');
    }

    public static function start() {    // Called from the scene
        function setupEnvironment() {
            if (node.type == 'MERCHANT') {
                final caravan = setEventMiddleActor('EventActor', 'Caravan');
                caravan.moveToLayer(engine.getLayerByName('BehindCharactersLayer'));
                final caravanHeight = caravan.getHeight() * 1.5;
                caravan.setXCenter(shopkeepActor.getXCenter());
                caravan.setY(shopkeepActor.getY() + shopkeepActor.getHeight() * 1.5 - caravanHeight - 15);
                setEventMiddleActor('UnitActor', 'Table', 55, k.feetYFromCenter + 35);
            } else if (node.type == 'BLACKSMITH') {
                final forge = setEventMiddleActor('EventActor', 'Forge');
                forge.moveToLayer(engine.getLayerByName('BehindCharactersLayer'));
                final forgeHeight = forge.getHeight() * 1.5;
                forge.setXCenter(shopkeepActor.getXCenter());
                forge.setY(shopkeepActor.getY() + shopkeepActor.getHeight() * 1.5 - forgeHeight + 6);
                setEventMiddleActor('UnitActor', 'Table', 55, k.feetYFromCenter + 35);
            } else if (node.type == 'NANA_JOY') {
                final magic = setEventMiddleActor('EventActor', 'Nana Joy Magic');
                magic.moveToLayer(engine.getLayerByName('BehindCharactersLayer'));
                final magicHeight = magic.getHeight() * 1.5;
                magic.setXCenter(shopkeepActor.getXCenter());
                magic.setY(shopkeepActor.getY() + shopkeepActor.getHeight() * 1.5 - magicHeight);
                setEventMiddleActor('EventActor', 'Lecture Table', 55, k.feetYFromCenter + 35);
            }

            final background =  if (Battlefield.lastBattlefieldEncounter != null) Battlefield.lastBattlefieldEncounter.waves[0].background else 'Forest';
            SpecialEffectsFluff.tryStartSpawningNonCombatSea({
                background: background,
                setBackground: (newBG) -> {
                    backgroundImage.kill();
                    backgroundImage = setupEventBackgroundImage(newBG, k.backgroundImageExtraYOffset);
                },
                x: backgroundImage.getX(),
                getBackgroundY: () -> {
                    final backgroundHeight = backgroundImage.getHeight();
                    final y = backgroundImage.getYCenter() - backgroundHeight / 2;
                    return y;
                }
            });
            SpecialEffectsFluff.tryStartSpawningLeaves(background);
            SpecialEffectsFluff.tryStartSpawningStalagmites(background);
            SpecialEffectsFluff.tryStartSpawningMist(background);
        }
        if (node == null) throwAndLogError('Went to ShopScene without a node. Use goToShop instead of changeScene.');
        GUI.startBeforeLoading();
        GUI.load('InventoryUI');
        GUI.load('PopupUI');
        GUI.load('SpellPopupUI');
        GUI.load('CharacterUI');
        GUI.load('StandardCharacterButtonsUI');
        ShopUI.init();
        
        centerCameraInScene();
        charactersInTown = setupCharactersAtEvent(k.feetYFromCenter);
        shopkeepActor = setEventMiddleActor('ShopkeepActor', ShopHelper.getShopkeepAnimationName(node.type), 80, k.feetYFromCenter);

        

        final backgroundPath =
            if (GameMap.lastAccessedNode != null && GameMap.lastAccessedNode.defaultAnimation != null) 'Images/Backgrounds/${GameMap.lastAccessedNode.defaultAnimation}.png'
            else 'Images/Backgrounds/House.png';
        backgroundImage = setupEventBackgroundImage(backgroundPath, k.backgroundImageExtraYOffset);
        onClick(() -> { onClickOnShopkeep(); }, shopkeepActor);
        setupHighlight();

        setupEnvironment();

        playerState = 'IDLE';
        if (!Player.progression.tutorialDidShopTutorial) {
            Player.progression.tutorialDidShopTutorial = true;
            ShopUI.startTutorial();
        }
        playAudio('ShopDoorBellAudio');
        doAfter(700, () -> {
            playAudio(
                if (node.type == 'BLACKSMITH') 'BlacksmithAudio'
                else if (node.type == 'MERCHANT') 'MerchantHelloAudio'
                else 'NanaJoyHelloAudio'
            );
            if (playerState != 'TUTORIAL') {
                sayShopkeepStartQuote();
            }
        });

        openStandardUIWithState(playerState);

        onEscapeKeyPress(() -> {
            if (GUI.isOpen('PopupUI')) {
                GUI.close('PopupUI');
            } else if (GUI.isOpen('InventoryUI')) {
                GUI.close('InventoryUI');
            } else if (GUI.isOpen('CharacterUI')) {
                GUI.close('CharacterUI');
            } else if (GUI.isOpen('SpellPopupUI')) {
                trace('Closing SpellPopup');
                GUI.close('SpellPopupUI');
            }
        });
    }

    static var lastTriggeredSay: SayerReturnObject;
    public static function sayFromShopkeep(sayWhat: String, ?xOffset: Float = 0, ?yOffset: Float = 0) {
        lastTriggeredSay = sayBubble(sayWhat, shopkeepActor.getXCenter() + xOffset, shopkeepActor.getY() + shopkeepActor.getHeight() + k.sayBottomOffsetY + yOffset, 4);
    }
    public static function sayFromShopkeepAuto(sayWhat: String) {
        switch (node.type) {
            case 'BLACKSMITH': sayFromShopkeep(sayWhat, 20, 0);
            case 'MERCHANT': sayFromShopkeep(sayWhat);
            case 'NANA_JOY': sayFromShopkeep(sayWhat, -8, -7);
        }
    }
    public static function sayShopkeepStartQuote() {
        switch (node.type) {
            case 'BLACKSMITH': sayFromShopkeep(MiscDatabases.getRandomBlacksmithQuote(), 20, 0);
            case 'MERCHANT': sayFromShopkeep(MiscDatabases.getRandomMerchantQuote());
            case 'NANA_JOY': sayFromShopkeep(MiscDatabases.getRandomNanaJoyQuote(), -8, -7);
        }
    }


    static function addItems(type: String, level: Int, includeTags: Array<Int> = null, nItems=1) {
        for (_ in 0...nItems) {
            final foundItem = getRandomItem({
                type: type,
                preferredLevel: level,
                includeTags: includeTags,
                excludeTags: [SPECIAL_ITEM]
            });
            if (foundItem.name == 'Oopsie') {
                trace('WARNING: Found Oopsie - ${foundItem.effect.description}');
                continue;
            }
            shopInventory.add(foundItem);
        }
    }
    static function setupMerchantInventory() {
        final level = node.level;
        trace('Got shop level: ${level}');

        if (level >= 1)
            addItems('GEAR', level-1, [TRINKET], randomIntBetween(0, 1));
        if (level >= 0)
            addItems('GEAR', level,   [TRINKET], randomIntBetween(2, 4));
        addItems('GEAR', level+1, [TRINKET], randomOf([0, 1, 1]));

        addItems('CONSUMABLE', level, null, randomIntBetween(1, 2));
        addItems('CONSUMABLE', randomOf([level, level-1]), null, randomIntBetween(1, 2));
    
        // Maybe tome
        if (percentChance(75)) shopInventory.add(getRandomItem({
            type: 'SPELL',
            usableTome: true,
            maxLevel: 99
        }));
        if (Player.progression.isCellarKeyFound == false) {
            shopInventory.add(ItemsDatabase.get('Cellar Key'));
        }
    }
    static function setupBlacksmithInventory() {
        final level = node.level;
        trace('Got BS level: ${level}');

        addItems('GEAR', level-1, [METAL], randomIntBetween(1, 4));
        addItems('GEAR', level,   [METAL], randomIntBetween(2, 4));
        addItems('GEAR', level+1, [METAL], randomIntBetween(2, 4));
    }
    static function setupNanaJoyInventory() {
        final level = node.level;
        trace('Setup nana joy inv for level ${level}');
        final nTomes = randomIntBetween(2, 4);
        trace('nTomes: ${nTomes}');
        for (i in 0...nTomes) {
            final item = getRandomItem({
                type: 'SPELL',
                usableTome: true,
                maxLevel: level + 1
            });
            trace('Added item ${item.name}');
            shopInventory.add(item);
        }
        final nTrinkets = randomIntBetween(1, 2);
        addItems('GEAR', level, [TRINKET], randomIntBetween(1, 2));

        addItems('CONSUMABLE', level+1, null, randomIntBetween(2, 3));
        if (Player.progression.didNanaJoyMeeting) {
            shopInventory.add(ItemsDatabase.get('Tooth of Insomnia'));
            shopInventory.add(ItemsDatabase.get(ItemsDatabase.getTomeNameFromSpellName('Summon Candle')));
            shopInventory.add(ItemsDatabase.get(ItemsDatabase.getTomeNameFromSpellName('Summon Candle')));
        }
        if (Player.progression.didNanaJoyAfterDialogue) {
            function getRandomTomeOfPower() {
                final tomeName: String = randomOf(['Tome of Health', 'Tome of Damage', 'Tome of Spell Power', 'Tome of Mana']);
                return ItemsDatabase.get(tomeName);
            }
            for (i in 0...randomIntBetween(2, 4)) {
                shopInventory.add(getRandomTomeOfPower());
            }
        }
    }
    
    static function setupHighlight() {
        onEnter(function(): Void {
            switch (shopkeepActor.getAnimation()) {
                case 'Merchant': shopkeepActor.setAnimation('MerchantHighlighted');
                case 'Blacksmith': shopkeepActor.setAnimation('BlacksmithHighlighted');
                case 'NanaJoy': shopkeepActor.setAnimation('NanaJoyHighlighted');
            }
        }, shopkeepActor);
        onExit(function(): Void {
            switch (shopkeepActor.getAnimation()) {
                case 'MerchantHighlighted': shopkeepActor.setAnimation('Merchant');
                case 'BlacksmithHighlighted': shopkeepActor.setAnimation('Blacksmith');
                case 'NanaJoyHighlighted': shopkeepActor.setAnimation('NanaJoy');
            }
        }, shopkeepActor);
    }
    static function closeAnyOpenSayBubble() {
        if (lastTriggeredSay != null)
            Sayer.remove(lastTriggeredSay);
    }

    static function onClickOnCharacterButton(index: Int) {
        onClickOnCharacter(Player.characters[index]);
    }
    static function onClickOnCharacterInTown(character: CharacterInTown) {
        // onClickOnCharacter(character.playerCharacter);
    }
    static function onClickOnCharacter(pc: PlayerCharacter) {
        if (playerState != 'IDLE') return;
        closeAnyOpenSayBubble();
        function closeUIForInspect() {
            closeStandardUIWithState('INSPECTING');
        }
        GUI.openWith('CharacterUI', {
            currentlyOpenCharacter: pc,
            onOpen: closeUIForInspect,
            onSpellClick: closeUIForInspect,
            onItemClick: closeUIForInspect,
            onClose: function() {
                openStandardUIWithState('IDLE');
            },
        });
    }

    static function onClickOnShopkeep() {
        if (playerState != 'IDLE') return;
        if (ShopUI.tutorialIndicator != null) recycleActor(ShopUI.tutorialIndicator);
        closeAnyOpenSayBubble();
        closeStandardUIWithState('BUYING');
        GUI.openWith('InventoryUI', {
            inventory: shopInventory,
            scope: BUY,
            onClose: () -> {
                GUI.close('PopupUI');
                openStandardUIWithState('IDLE');
            },
            onItemClick: (itemClicked: Item) -> {
                GUI.openWith('PopupUI', {
                    item: itemClicked,
                    inventory: shopInventory,
                    reason: BUY,
                    yOffset: 5,
                    callback: (didClickOnBuy: Bool, _: Int) -> {
                        if (didClickOnBuy) {
                            final didBuy = Player.tryBuyItemFromInventory(itemClicked, shopInventory);
                            if (didBuy) {
                                playAudio('CoinAudio');
                                doAfter(250, () -> {
                                    if (node.type == MERCHANT) {
                                        playAudio('MerchantHelloAudio');
                                    } else if (node.type == BLACKSMITH) {
                                        playAudio('BlacksmithAudio');
                                    } else if (node.type == NANA_JOY) {
                                        playAudio('NanaJoyHelloAudio');
                                    }
                                    
                                });
                                
                                doHardcodedOnItemBuy(itemClicked);
                                InventoryUI.self.refresh();
                            }
                        }
                        GUI.close('PopupUI');
                    }
                });
            }
        });
    }
    public static function onClickOnOnlyButton() {
        if (playerState != 'IDLE') return;
        closeAnyOpenSayBubble();
        closeStandardUIWithState('SELLING');
        GUI.openWith('InventoryUI', {
            inventory: Player.inventory,
            scope: SELL,
            onClose: () -> {
                openStandardUIWithState('IDLE');
            },
            onItemClick: (itemClicked) -> {
                GUI.openWith('PopupUI', {
                    item: itemClicked,
                    inventory: Player.inventory,
                    reason: SELL,
                    callback: (didSell: Bool, _: Int) -> {
                        GUI.close('PopupUI');
                        if (didSell) {
                            playAudio('CoinAudio');
                            Player.sellItem(itemClicked);
                            InventoryUI.self.refresh();
                        }
                    }
                });
            }
        });
        ShopUI.disableArrow();
    }
    static function openStandardUIWithState(newState: String) {
        ShopUI.enableArrow();
        trace('Opening StandardUI from Shop');
        GUI.open('StandardCharacterButtonsUI', [onClickOnCharacterButton, onClickOnOnlyButton]);
        playerState = newState;
    }
    static function closeStandardUIWithState(newState: String) {
        ShopUI.disableArrow();
        GUI.close('StandardCharacterButtonsUI');
        playerState = newState;
    }
    static function doHardcodedOnItemBuy(item: Item) {
        switch (item.name) {
            case 'Cellar Key':
                Game.setAchievement('IS_CELLAR_KEY_FOUND');
                Player.progression.isCellarKeyFound = true;
                Player.removeItem(item);
        }
    }
    

    public static function _testShop() {
        
    }
}

class ShopHelper {
    public static function getShopkeepAnimationName(type: String) {
        final types = [
            'MERCHANT' => 'Merchant',
            'NANA_JOY' => 'NanaJoy',
            'BLACKSMITH' => 'Blacksmith'
        ];
        if (!!!types.exists(type)) throwAndLogError('Shop type does not exist ${type}');
        return types[type];
    }
}

class ShopUI {

    public static var arrow: SUIButton;
    public static var adButton: FramedItem;
    public static var tutorialIndicator: Actor;

    static var isArrowClickable = true;

    public static function init() {
        arrow = new SUIButton('ArrowActor', 'UI', 'ArrowRight', {
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
            if (!!!isArrowClickable) return;
            if (GUI.isOpen('InventoryUI') || GUI.isOpen('CharacterUI') || GUI.isOpen('PopupUI') || GUI.isOpen('SpellPopupUI')) return;
            if (Shop.callback != null) {
                Shop.callback();
            }
        }

        if (Game.isMobile == false) return;
        adButton = new FramedItem('Icons/Ad.png', 'UI', 0, 0);
        adButton.setBottom(StandardCharacterButtonsUI.k.padding);
        adButton.setRight(StandardCharacterButtonsUI.k.padding * 2 + Constants.ICON_FRAME_SIZE);
        adButton.anchorToScreen();
        adButton.enablePopAnimation();
        var didAdWork = false;
        adButton.click = function() {
            U.showInterstitialAd();
            U.loadInterstitialAd();
            adButton.disableAndMarkAsGrayed();
            doAfter(500, () -> {
                if (didAdWork == false) {
                    Shop.sayFromShopkeepAuto("Hmm. That didn't work. Is your INTERNET working?");
                }
            });
        }
        U.onMobileAdOpened(function() {
            didAdWork = true;
        });
        U.onMobileAdClosed(function() {
            for (i in 1...7) {
                doAfter(i * 100, () -> {
                    playAudio('CoinAudio');
                    SpecialEffectsFluff.doItemToInventoryAnimation('Images/Other/Coin.png', Shop.shopkeepActor.getXCenter() + randomIntBetween(-10, 10), Shop.shopkeepActor.getYCenter() + randomIntBetween(-10, 10), false);
                });
            }
            final gold = Std.int(Player.totalGoldAcquiredThisRun / 6 * 4);  // Because the gold multiplier for mobile is 0.6; so 0.6 / 6 = 0.1 * 4 = 0.4, which fills it as 1
            Player.giveExtraGold(gold);
            didAdWork = true;
        });
    }
    public static function disableArrow() {
        arrow.hide();
        isArrowClickable = false;
    }
    public static function enableArrow() {
        arrow.show();
        doAfter(100, () -> isArrowClickable = true);
    }

    public static function startTutorial() {
        var lastTriggeredSay: SayerReturnObject;
        function alertAndWait(message: String) {
            lastTriggeredSay = sayAlert(message, getScreenXCenter(), getScreenYCenter(), -1);
        }
        Shop.playerState = 'TUTORIAL';
        var currentMessageIndex = 0;
        final messages = [
            "Welcome to the shop!",
            if (Game.isMobile)
                "Tap on the merchant to buy items or open your inventory to sell items."
            else
                "Click on the merchant to buy items or open your inventory to sell items.",
            if (Game.isMobile)
                "To equip an item, open your character and tap on an empty inventory square (on the right)."
            else
                "To equip an item, open your character and click on an empty inventory square (on the right).",
            "I\'m sure you'll figure it out!"
        ];
        doAfter(750, () -> {
            alertAndWait(messages[currentMessageIndex]);
            currentMessageIndex++;
            onClick(function(): Void {
                if (Shop.playerState != 'TUTORIAL') return;
                Sayer.remove(lastTriggeredSay);
                if (currentMessageIndex >= messages.length) {
                    final x = Shop.shopkeepActor.getX() - 25;
                    final y = Shop.shopkeepActor.getY() + 25;
                    tutorialIndicator = SpecialEffectsFluff.indicateWithArrows(x, y, true); // isFlipped=true
                    tutorialIndicator.growTo(-1.5, 1.5, 0);
                    doAfter(100, () -> {
                        Shop.playerState = 'IDLE';
                    });
                    return;
                }
                alertAndWait(messages[currentMessageIndex]);
                currentMessageIndex++;
            });
        });
    }
}
