
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

class MapNodeHelper {
    public static var availableStates = ['AVAILABLE', 'VISITED', 'UNAVAILABLE', 'SKIPPED'];
    public static function assertStateExists(state: String) if (availableStates.indexOf(state) < 0) throwAndLogError('State ${state} for MapNode does not exist.');
}

class MapNode {

    public var type: String;
    public var state = 'UNAVAILABLE';
    public var tierIndex: Int = 0;
    public var nodeIndexInTier: Int = 0;
    public var level: Int = -1;             // Usually set with onEveryNode
    public var defaultAnimation: String;    // Overriden by anything else (e.g BattlefieldEncounter animation)
    public var overrideAnimation: String;   // Overrides all other animations
    public var overrideOverlay: String;     // Overrides all overlay animations

    public var nextNodes: Array<MapNode> = [];

    public var icon: Actor;
    var nextConnectionActors: Array<Actor> = [];
    var overlay: ImageX;
    var sheen: Actor;


    // Specific data
    public var battlefieldEncounter: BattlefieldEncounter;
    public var skipAfterCombat = false;     // Set in GameMapGenerator tutorial and Chapters last journey node
    public var afterCombatOptions: Dynamic; // Set externally and given to AfterCombat.goToAfterCombat. Optional

    public var shopItems: Array<String> = null;

    public var nonCombatEvent: NonCombatEventDynamic = null;   // Exists only if node type is EVENT





    public function toDynamic() {
        if (type == BATTLEFIELD_ENCOUNTER && battlefieldEncounter == null) {
            trace('ERROR: Encounter at ${tierIndex}, ${nodeIndexInTier} has no battlefield encounter!');
        }
        return {
            type: type,
            state: state,
            tierIndex: tierIndex,
            nodeIndexInTier: nodeIndexInTier,
            level: level,
            defaultAnimation: defaultAnimation,
            overrideAnimation: overrideAnimation,
            overrideOverlay: overrideOverlay,

            nextNodesIndices: nextNodes.map(node -> node.getPositionAsIndices()),

            battlefieldEncounterName: if (battlefieldEncounter == null) null else battlefieldEncounter.name,
            skipAfterCombat: skipAfterCombat,
            afterCombatOptions: afterCombatOptions,

            shopItems: shopItems,

            nonCombatEventName: if (nonCombatEvent == null) null else nonCombatEvent.name
        };
    }
    public static function createFromDynamicWithoutNextAndParent(dyn: Dynamic) {
        var node = new MapNode(dyn.type);
        node.state = dyn.state;
        node.tierIndex = dyn.tierIndex;
        node.nodeIndexInTier = dyn.nodeIndexInTier;
        node.defaultAnimation = dyn.defaultAnimation;
        node.overrideAnimation = dyn.overrideAnimation;
        node.overrideOverlay = dyn.overrideOverlay;
        node.level = dyn.level;

        node.nextNodes = [];

        final battlefieldEncounterName: String = dyn.battlefieldEncounterName;
        node.battlefieldEncounter =
            if (battlefieldEncounterName == null) null
            else BattlefieldEncounterDatabase.get(battlefieldEncounterName);

        node.skipAfterCombat = dyn.skipAfterCombat;
        node.afterCombatOptions = node.afterCombatOptions;

        node.shopItems = dyn.shopItems;

        final nonCombatEventName: String = dyn.nonCombatEventName;
        node.nonCombatEvent =
            if (nonCombatEventName == null) null
            else NonCombatEventsDatabase.get(nonCombatEventName);

        return node;
    }

    public function getPositionAsIndices() {
        return {
            tierIndex: tierIndex,
            nodeIndexInTier: nodeIndexInTier
        };
    }

    public function new(nodeType: String, ?options: {
        ?battlefieldEncounterName: String,
        ?shopItems: Array<String>,
        ?tierIndex: Int,
        ?nodeIndexInTier: Int,
        ?skipAfterCombat: Bool,
        ?nonCombatEventName: String
    }) {
        if (options == null) options = {};
        type = nodeType;
        state = 'UNAVAILABLE';
        tierIndex = nullOr(options.tierIndex, -1);
        nodeIndexInTier = nullOr(options.nodeIndexInTier, 0);

        // BATTLEFIELD_ENCOUNTER only
        if (options.battlefieldEncounterName != null)
            battlefieldEncounter = BattlefieldEncounterDatabase.get(options.battlefieldEncounterName);
        skipAfterCombat = options.skipAfterCombat == true;

        // Shop only
        if (options.shopItems != null) shopItems = options.shopItems;
        
        // EVENT only
        if (options.nonCombatEventName != null) nonCombatEvent = NonCombatEventsDatabase.get(options.nonCombatEventName);
    }

    public static function getAllShopTypes() { return ['MERCHANT', 'BLACKSMITH', 'NANA_JOY']; }

    public function addToScene(x, y) {
        function sayAndReturnError() { trace('Type ${type} no exist!'); return 'Error'; }
        function autosetupAnimation() {
            var iconAnimation = 'Error';
            if (defaultAnimation != null) iconAnimation = defaultAnimation; // Overrides Error
            if (type == BATTLEFIELD_ENCOUNTER) {                            // Overrides defaultAnimation
                if (battlefieldEncounter != null) {
                    iconAnimation = battlefieldEncounter.animationName;
                } else {
                    trace('WARNING: Has no battlefield encounter?? ${tierIndex}, ${nodeIndexInTier}');
                }
            }
            if (overrideAnimation != null) {
                iconAnimation = overrideAnimation;
            }
            icon.setAnimation(iconAnimation);

        }
        function autosetupOverlay() {
            var overlayAnimation = 'Images/MapNodeOverlays/' +
                if (type == MERCHANT)           'Merchant.png'
                else if (type == BLACKSMITH)    'Blacksmith.png'
                else if (type == NANA_JOY)      'NanaJoy.png'
                else if (type == CAMPFIRE)      'Campfire.png'
                else if (type == BATTLEFIELD_ENCOUNTER && battlefieldEncounter != null) (
                    if (battlefieldEncounter.hasFlag('BOSS_ICON')) 'Boss.png'
                    else if (battlefieldEncounter.hasFlag('RESCUE')) getRescueOverlay()
                    else if (battlefieldEncounter.hasFlag('GOBLIN')) 'BattlefieldEncounterGoblin.png'
                    else if (battlefieldEncounter.hasFlag('EXPLODING_CRYSTAL')) 'BattlefieldEncounterCrystal.png'
                    else 'BattlefieldEncounter.png'
                ) else if (type == BATTLEFIELD_ENCOUNTER && battlefieldEncounter == null) 'Error.png'
                else if (type == EVENT)         'Event.png'
                else 'Error.png';
            if (overlayAnimation == 'Error.png') trace('WARNING: overlay animation set to Error.png for node of type ${type}');
            overlay = new ImageX(if (overrideOverlay != null) overrideOverlay else overlayAnimation, 'MapNodesOverlay');
            overlay.setXY(icon.getX(), icon.getY());
            overlay.attachToActor(icon, 0, 0);
        }

        icon = createActor('MapNodeIconActor', 'MapNodesLayer');
        icon.setX(x);
        icon.setY(y);
        if (type == BATTLEFIELD_ENCOUNTER && battlefieldEncounter == null) trace('Null battlefieldEncounter for encounter at tier ${tierIndex}, index ${nodeIndexInTier}');

        autosetupAnimation();
        autosetupOverlay();
        
        sheen = createActor('MapNodeSheenActor', 'MapNodesSheen');
        sheen.setXY(icon.getX(), icon.getY());
        onClickAndRelease(() -> GameMap.onClickOnMapNode(this), icon);
        SpecialEffectsFluff.addPopBehaviorToActor(icon, (_: String) -> { return state == 'AVAILABLE'; });
        SpecialEffectsFluff.addPopBehaviorToActor(sheen, (_: String) -> { return state == 'AVAILABLE'; });
        updateStateVisuals();
    }

    public function addNextNode(mapNode: MapNode) {
        nextNodes.push(mapNode);
        return mapNode;
    }
    public function updateStateVisuals() {
        if (getCurrentSceneName() != 'MapScene') throwAndLogError('Trying to update map node while not in MapScene.');
        MapNodeHelper.assertStateExists(state);
        icon.clearFilters();
        overlay.show();
        overlay.setAlpha(1);
        sheen.disableActorDrawing();
        switch (state) {
            case 'UNAVAILABLE':
                setActorSaturation(icon, 25);
                overlay.setAlpha(0.5);
            case 'AVAILABLE':
                sheen.enableActorDrawing();
            case 'VISITED':
                overlay.changeImage('Images/MapNodeOverlays/Done.png');
            case 'SKIPPED':
                overlay.changeImage('Images/MapNodeOverlays/Skipped.png');
                overlay.setAlpha(0.5);
                setActorSaturation(icon, 35);
                
            default: throwAndLogError('No case for updateStateVisuals(${state})');
        }
    }

    public function setStateInScene(newState: String) {    // Will only work if the game is in MapScene
        state = newState;
        updateStateVisuals();
    }
    public function visitAndMakeAllNextNodesAvailable() {         // Only updates the state. No visuals.
        state = 'VISITED';
        for (next in nextNodes)
            next.state = 'AVAILABLE';
    }
    public function makeSkipped() {
        state = 'SKIPPED';
    }
    public function makeAvailable() {
        state = 'AVAILABLE';
    }
    public function makeVisited() {
        state = 'VISITED';
    }

    public function makeRandomNormalBattlefieldEncounter() {
        type = BATTLEFIELD_ENCOUNTER;
        final encounter = BattlefieldEncounterDatabase.getRandomEncounterOfLevelWithoutFlag(level, 'SPECIAL');
        setBattlefieldEncounter(encounter);
    }
    public function setBattlefieldEncounter(?encounterName: String, ?encounter: BattlefieldEncounter) {
        if (type != 'BATTLEFIELD_ENCOUNTER')
            type = BATTLEFIELD_ENCOUNTER;
        if (encounterName != null)
            this.battlefieldEncounter = BattlefieldEncounterDatabase.get(encounterName);
        if (encounter != null)
            this.battlefieldEncounter = encounter;
    }
    public function setOverrideAnimation(animationName: String) {
        overrideAnimation = animationName;
    }
    public function setDefaultAnimation(animationName: String) {    // Base animation for the node actor; Overriden by the BatltefieldEncounter animation
        defaultAnimation = animationName;
    }
    public function setShopItems(givenShopItems: Array<String>) {
        shopItems = givenShopItems;
    }
    public function getShopItemsAsItemArray() {
        return shopItems.map(name -> ItemsDatabase.get(name));
    }
    public function makeBattlefieldEncounter(?encounterName: String, ?encounter: BattlefieldEncounter) {
        type = BATTLEFIELD_ENCOUNTER;
        setBattlefieldEncounter(encounterName, encounter);
    }
    public function makeRandomShop() {
        final allPossibleTypes = getAllShopTypes();
        this.type = allPossibleTypes[randomIntBetween(0, allPossibleTypes.length - 1)];
    }
    public function makeCampfire() {
        this.type = CAMPFIRE;
    }
    public function makeRandomEvent() {
        // This will do Battlefield.goToBattle('Fallen Hero')
        // After the combat, the player will receive Flowers as extra loot
        // It works because Battlefield.getCurrentNode() returns the same node as the Event
        // Then, it will redirect Player.continueJourney
        type = EVENT;
        nonCombatEvent = NonCombatEventsDatabase.getRandom();
        trySetupSpecificEventMetadata();
    }
    public function makeNonCombatEvent(eventName: String) {
        type = EVENT;
        nonCombatEvent = NonCombatEventsDatabase.get(eventName);
        trySetupSpecificEventMetadata();
    }
    function trySetupSpecificEventMetadata() {
        switch (nonCombatEvent.name) {
            case 'Grave of a Fallen Warrior':
                afterCombatOptions = {
                    extraLoot: ['Flowers']
                };
            case 'Hell Portal':
                overrideAnimation = 'Hell';
            case 'Natas':
                if (Player.progression.didStormjr3Dialogue && Player.progression.didNatasClarificationDialogue == false) {
                    overrideOverlay = 'Images/MapNodeOverlays/Story.png';
                }
            case 'King Intro',
                 'Captain Stashton and Marceline',
                 'Stormjr 3',
                 'King Plead Meeting',
                 'Marceline Meeting Defeated',
                 'King Meeting Defeated',
                 'Marceline Meeting',
                 'Marceline Meeting 2',
                 'King vs Marceline',
                 'Dark Cellar',
                 'King or Marceline Battle',
                 'Nana Joy Meeting':
                overrideOverlay = 'Images/MapNodeOverlays/Story.png';
            default:
        }
    }

    public function getX() return icon.getX();
    public function getY() return icon.getY();
    public function getXCenter() return icon.getXCenter();
    public function getYCenter() return icon.getYCenter();

    public function hasChildren() return nextNodes.length > 0;
    public function getNChildren() return nextNodes.length;
    public function hasChild(node: MapNode) return hasChildren() && nextNodes.indexOf(node) != -1;
    public function getOnlyChild() return nextNodes[0];
    public function getOnlyVisitedChild() {
        final visitedChildren = nextNodes.filter(node -> node.state == 'VISITED');
        if (visitedChildren.length > 0) return visitedChildren[0];
        return null;
    }
    public function getRandomNextNode() {
        return nextNodes[randomInt(0, nextNodes.length - 1)];
    }
	public function isLastNode() return hasChildren() == false;
    public function isShop() return getAllShopTypes().indexOf(type) != -1;
    public function isCombat() return type == 'BATTLEFIELD_ENCOUNTER';
    public function isNonCombat() return isShop() || type == CAMPFIRE || type == EVENT;
    public function isRoot() {
        return tierIndex == 0;
    }
    public function getConnectionWith(node: MapNode): Actor {
        for (i in 0...nextNodes.length) {
            if (nextNodes[i] == node) return nextConnectionActors[i];
        }
        return null;
    }
    public function getRescueOverlay(): String {
        return
            if (battlefieldEncounter.hasFlag('GREEN_FLAG')) 'RescueRanger.png'
            else if (battlefieldEncounter.hasFlag('BLUE_FLAG')) 'RescueMage.png'
            else 'RescueKnight.png';
    }
    public function toString() return haxe.Json.stringify(toDynamic());
    public function hasParent() return tierIndex != 0;
    public function getParents(): Array<MapNode> {
        if (hasParent() == false) return [];
        return GameMap.nodesByTier[tierIndex - 1].filter(node -> node.nextNodes.indexOf(this) != -1);
    }
}



