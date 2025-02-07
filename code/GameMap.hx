

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
import scripts.Game.q;
import Std.int;

class GameMap
{

    public static var k = {
        nodeHeight: 48
    };


    public static var nodesByTier: Array<Array<MapNode>>;
    public static var lastAccessedNode: MapNode;
    public static var backgroundImage: ImageX;

    public static var playerState = 'IDLE';
    private static var _possibleStates = ['IDLE', 'INSPECTING', 'USING', 'IN_SETTINGS'];
    public static var savedScrollX: Int = -1;

    public static function toDynamic() {
        return {
            nodesByTier:
                if (nodesByTier == null) null
                else nodesByTier.map(arrayOfMapNode -> arrayOfMapNode.map(mapNode -> mapNode.toDynamic())),
            lastAccessedNodeIndices:
                if (lastAccessedNode == null) null
                else lastAccessedNode.getPositionAsIndices()
        };
    }
    public static function loadFromDynamic(dyn: Dynamic) {
        if (dyn.nodesByTier == null) throwAndLogError('No map was generated from save game.');
        nodesByTier = GameMapGenerator.generateNodesByTierFromDynamicByTier(dyn.nodesByTier);
        lastAccessedNode =
            if (dyn.lastAccessedNode == null) null
            else nodesByTier[dyn.lastAccessedNodeIndices.tierIndex][dyn.lastAccessedNodeIndices.nodeIndexInTier];
    }


    static var isPreventingMusic = false;
    public static function preventMusicStart() isPreventingMusic = true;

    public static function generateTutorialMap() {
        clear();
        nodesByTier = GameMapGenerator.generateTutorialMap();
        getOnlyRootNode().makeAvailable();
    }
    public static function goToMapSceneAndGenerate(journey: ChapterJourney) {       // Use when going to the game map the first time
        clear();
        switch (journey.generationFlag) {
            case 'NORMAL': nodesByTier = GameMapGenerator.generateMap(journey);
            default: throwAndLogError('Flag ${journey.generationFlag} does not exist.');
        }
        for (node in getRootNodes()) {
            node.makeAvailable();
        }
        Game.save(() -> {
            changeScene('MapScene');
        });
    }
    public static function goToMapSceneAfterLoad() {
        trace('Going to map scene.');
        changeScene('MapScene');
    }
    public static function goToMapSceneAndContinue() {                              // Use when going to the map with an already existing generated map
        function makeOldNodesSkipped() {
            final nNodesVisited = countNodesVisited();
            if (nNodesVisited == 1) {
                for (node in nodesByTier[0]) {
                    if (node.state == 'AVAILABLE' && node.hasChild(lastAccessedNode) == false)  // Make all other root nodes skipped
                        node.state = 'UNAVAILABLE';
                }
            }
            if (nNodesVisited < 3) return;
            final nTiersSkipped = int((nNodesVisited - 1) * 0.6666);
            for (i in 0...nTiersSkipped) {
                final nodesInTier = nodesByTier[i];
                for (node in nodesInTier) {
                    if (node.state != 'VISITED')
                        node.makeSkipped();
                }
            }
        }
        if (lastAccessedNode == null) throwAndLogError('Nothing to continue from; no map is generated!');
        lastAccessedNode.makeVisited();     // THis has to be before makeOldNodesSkipped
        makeOldNodesSkipped();
        for (node in lastAccessedNode.nextNodes) {
            if (node.state == 'UNAVAILABLE') {
                node.state = 'AVAILABLE';
            }
        }
        if (lastAccessedNode.hasParent()) {
            for (node in lastAccessedNode.getParents()) {
                if (node.state == 'UNAVAILABLE') {
                    node.state = 'AVAILABLE';
                }
            }
        }
        Game.save(() -> {
            changeScene('MapScene');
        });
    }
    public static function reload() {
        trace(' -->> Reloading GameMap');
        playerState = 'IDLE';
        savedScrollX = -1;
        closeAllUI();
        changeScene('MapScene');
    }
    public static function clear() {
        savedScrollX = -1;
        nodesByTier = null;
        lastAccessedNode = null;
        setGameAttribute('IsInRun', 'NO');
    }

    public static function start() {
        function drawAllMapNodes() {
            trace('Drawing nodes.');
            function getXByTier(tier: Int) {
                var nodeXPadding =
                    if (nodesByTier.length <= 6) getScreenWidth() / (nodesByTier.length + 1)
                    else getSceneWidth() / (nodesByTier.length + 1);
                return nodeXPadding * (tier + 1);
            }
            function getYByNodeInTier(nodeIndex: Int = 0, nNodesInTier: Int) {
                final nodeYPadding = getScreenHeight() / (nNodesInTier + 1);
                return nodeYPadding * (nodeIndex + 1) - k.nodeHeight / 2;
            }
            trace('n tiers:');
            trace(nodesByTier.length);
            for (tierIndex in 0...nodesByTier.length) {
                trace('At tier ${tierIndex}');
                final tier = nodesByTier[tierIndex];
                for (nodeIndex in 0...tier.length) {
                    trace('At node ${nodeIndex}');
                    final x = getXByTier(tierIndex);
                    final y = getYByNodeInTier(nodeIndex, tier.length);
                    tier[nodeIndex].addToScene(x, y);
                }
            }
            trace('Done! Drew nodes');
        }
        function drawConnections() {
            function drawConnection(nodeA: MapNode, nodeB: MapNode) {
                final middleX = (nodeA.getXCenter() + nodeB.getXCenter()) / 2;
                final middleY = (nodeA.getYCenter() + nodeB.getYCenter()) / 2;
                var footStepsActor = createActor('FootStepsActor', 'FootStepsLayer');
                footStepsActor.setXCenter(middleX);
                footStepsActor.setYCenter(middleY);
                footStepsActor.setAngle(Utils.RAD * angleBetweenPoints(middleX, middleY, nodeB.getXCenter(), nodeB.getYCenter()));
                footStepsActor.growTo(0.75, 0.75, 0, Easing.linear);
                if (nodeA.state == 'VISITED' && nodeB.state == 'VISITED')
                    footStepsActor.setAnimation('Active');
                else if (nodeA.state == 'VISITED' && nodeB.state == 'AVAILABLE')
                    footStepsActor.setAnimation('Active');
                else if (nodeA.state == 'AVAILABLE' && nodeB.state == 'VISITED')
                    footStepsActor.setAnimation('Active');
                else
                    footStepsActor.setAnimation('Inactive');
            }
            var previousTier = nodesByTier[0];
            for (tierIndex in 1...nodesByTier.length) {
                var currentTier = nodesByTier[tierIndex];
                for (node in previousTier) {
                    for (connectedNode in node.nextNodes) {
                        drawConnection(node, connectedNode);
                    }
                }
                previousTier = currentTier;
            }
        }
        function drawMapBorders() {
            final topLeft = new ImageX('Images/Backgrounds/Map/MapBorderTopLeft.png', 'MapBackgroundLayer');
            topLeft.setXY(0, getScreenY());
            final topRight = new ImageX('Images/Backgrounds/Map/MapBorderTopRight.png', 'MapBackgroundLayer');
            topRight.setXY(getSceneWidth() - topRight.getWidth(), getScreenY());

            final bottomLeft = new ImageX('Images/Backgrounds/Map/MapBorderBottomLeft.png', 'MapBackgroundLayer');
            bottomLeft.setXY(0, getScreenY() + getScreenHeight() - bottomLeft.getHeight());
            final bottomRight = new ImageX('Images/Backgrounds/Map/MapBorderBottomRight.png', 'MapBackgroundLayer');
            bottomRight.setXY(getSceneWidth() - topRight.getWidth(), getScreenY() + getScreenHeight() - bottomRight.getHeight());
        }
        playerState = 'IDLE';
        if (nodesByTier == null) {
            final message = 'ERROR: Map not generated. Use goToMapSceneAndGenerate!';
            trace(message);
            throwAndLogError(message);
        }
        if (isPreventingMusic == false) {
            final durationInMiliseconds = playAudio('AdventureMusic', MUSIC_CHANNEL); // To not loop
            doAfter(35 * 1000, () -> {
                if (getCurrentSceneName() == 'MapScene')
                    playAudio('GrassAmbience', MUSIC_CHANNEL);
            });
        } else {

        }
        isPreventingMusic = false;
        drawAllMapNodes();
        drawConnections();
        CameraScroller.initialize(false);
        CameraScroller.lockVertical();
        GUI.startBeforeLoading();
        GUI.load('CharacterUI');
        GUI.load('InventoryUI');
        GUI.load('PopupUI');
        GUI.load('SpellPopupUI');
        GUI.load('SettingsUI');
        GUI.load('StandardCharacterButtonsUI');
        final backgroundImagePath =
            if (Player.isTurboModeEnabled || Player.getCurrentJourneyInCurrentChapter() == null) 'Images/Backgrounds/MapGrass.png'
            else Player.getCurrentJourneyInCurrentChapter().backgroundImagePath;
        backgroundImage = new ImageX(backgroundImagePath, 'MapBackgroundLayer');
        backgroundImage.setXY(0, 0);
        // drawMapBorders();
        if (savedScrollX != -1) {
            engine.moveCamera(savedScrollX, getScreenYCenter());
            trace('Moving camera to ${savedScrollX}');
        }

        U.loadInterstitialAd();

        MiscDatabases.generatePauseButton(() -> {
            CameraScroller.lockHorizontal();
            CameraScroller.stopCameraDrag();        // Prevents accidental camera drag
            toggleSettingsUI();
        });
        onEscapeKeyPress(() -> {
            if (GUI.isOpen('PopupUI')) {
                GUI.close('PopupUI');
            } else if (GUI.isOpen('InventoryUI')) {
                GUI.close('InventoryUI');
            } else if (GUI.isOpen('CharacterUI')) {
                GUI.close('CharacterUI');
            } else if (GUI.isOpen('SpellPopupUI')) {
                GUI.close('SpellPopupUI');
            } else if (GUI.isOpen('SettingsUI')) {
                CameraScroller.unlockHorizontal();
                toggleSettingsUI();
            } else {
                CameraScroller.lockHorizontal();
                toggleSettingsUI();
            }
        });

        doAfter(250, () -> {
            openStandardUIWithState('IDLE');
        });

        if (Player.isTurboModeEnabled) {
            autonavigate();
        }
    }

    static function autonavigate() {
        doAfter(25, () -> {
            toggleSettingsUI();
        });
        doAfter(50, () -> {
            toggleSettingsUI();
        });
        doAfter(75, () -> {
            onClickOnCharacterButton(0);
        });
        doAfter(100, () -> {
            GUI.close('CharacterUI');
        });
        doAfter(100, () -> {
            if (lastAccessedNode == null) {
                onClickOnMapNode(nodesByTier[0][0]);
                return;
            }
            if (lastAccessedNode.nextNodes == null || lastAccessedNode.nextNodes.length == 0) return;
            onClickOnMapNode(lastAccessedNode.nextNodes[0]);
        });
    }

    static function toggleSettingsUI() {
        if (playerState == 'IDLE') {
            CameraScroller.lockHorizontal();
            closeStandardUIWithState('IDLE');   // ERR is this right? TODO
            GUI.openWith('SettingsUI', {
                onCloseClick: () -> {
                    toggleSettingsUI();

                }
            });
            playerState = 'IN_SETTINGS';
        } else if (playerState == 'IN_SETTINGS') {
            CameraScroller.unlockHorizontal();
            CameraScroller.stopCameraDrag();    // Prevents accidental camera drag
            GUI.close('SettingsUI');
            openStandardUIWithState('IDLE');
        }
    }
    static function openStandardUIWithState(newState: String) {
        playerState = newState;
        CameraScroller.stopCameraDrag();
        GUI.open('StandardCharacterButtonsUI', [onClickOnCharacterButton, onClickOnOnlyButton]);
    }
    static function closeStandardUIWithState(newState) {
        playerState = newState;
        CameraScroller.stopCameraDrag();
        GUI.close('StandardCharacterButtonsUI');
    }
    


    

    public static function onClickOnCharacterButton(index: Int) {
        if (playerState != 'IDLE') return;
        if (GUI.isOpen('SettingsUI')) return;
        final playerCharacter = Player.characters[index];
        function closeUIForInspect() {
            CameraScroller.lockHorizontal();
            closeStandardUIWithState('INSPECTING');
        }
        GUI.openWith('CharacterUI', {
            currentlyOpenCharacter: playerCharacter,
            onOpen: closeUIForInspect,
            onClose: function(): Void {
                CameraScroller.unlockHorizontal();
                openStandardUIWithState('IDLE');
            },
            onSpellClick: closeUIForInspect,
            onItemClick: closeUIForInspect
        });
    }
    public static function onClickOnOnlyButton() {
        if (GUI.isOpen('SettingsUI')) return;
        switch (playerState) {
            case 'IDLE':
                CameraScroller.lockHorizontal();
                closeStandardUIWithState('USING');
                GUI.openWith('InventoryUI', {
                    inventory: Player.inventory,
                    reason: USE,
                    onItemClick: function(itemClicked: Item) {
                        if (itemClicked.type != 'CONSUMABLE' || itemClicked.effect.isCombatOnly) {
                            GUI.openWith('PopupUI', {
                                item: itemClicked,
                                inventory: Player.inventory,
                                reason: INSPECT,
                                callback: function(didUseItem: Bool, whichCharacterIndex: Int) {
                                    GUI.close('PopupUI');
                                }
                            });
                        } else {
                            GUI.openWith('PopupUI', {
                                item: itemClicked,
                                inventory: Player.inventory,
                                reason: USE,
                                callback: function(didUseItem: Bool, whichCharacterIndex: Int) {
                                    GUI.close('PopupUI');
                                    if (!!!didUseItem) return;
                                    Player.characters[whichCharacterIndex].useItemFromInventory(itemClicked);
                                    InventoryUI.self.refresh();
                                }
                            });
                        }
                       
                    },
                    onClose: function() {
                        CameraScroller.cancelCameraDragging();    // Prevents the camera moving slightly because "s-a agatat in click"
                        CameraScroller.unlockHorizontal();
                        openStandardUIWithState('IDLE');
                    }
                });
            case 'USING', 'INSPECTING':
                return;
        }

    }
    public static function onClickOnMapNode(clickedNode: MapNode) {
        if (playerState != 'IDLE') return;
        if (GUI.isOpen('SettingsUI')) return;
        lastAccessedNode = clickedNode;
        q('M: Clicked on map node. Null? ${lastAccessedNode == null}');
        q('M: Printing node: ${clickedNode.toString()}');
        
        switch (clickedNode.state) {
            case 'UNAVAILABLE': return;
            case 'VISITED': return;
            case 'AVAILABLE':
                stopMusic();
                savedScrollX = int(getScreenXCenter());
                if (clickedNode.type == 'BATTLEFIELD_ENCOUNTER') {
                    if (clickedNode.battlefieldEncounter == null) {
                        q('ERROR: Node has no battlefieldEncounter, even though the type is BATTLEFIELD_ENCOUNTER!');
                        return;
                    }
                    if (clickedNode.battlefieldEncounter.isRescueMission()) {
                        q('M: Going to rescue mission.');
                        if (isOutOfBounds(nodesByTier, clickedNode.tierIndex)) {
                            q('ERROR: tierIndex ${clickedNode.tierIndex} of node is out of bounds!');
                        }
                        for (node in nodesByTier[clickedNode.tierIndex]) {
                            if (node != clickedNode) node.makeSkipped();
                        }
                    }
                    q('\nM: Going to battle: ${clickedNode.battlefieldEncounter.name}');
                    Battlefield.goToBattle(clickedNode.battlefieldEncounter.name);
                } else if (clickedNode.type == 'CAMPFIRE') {
                    Campfire.goToCampfire(() -> {
                        Player.continueJourney();
                    });
                } else if (clickedNode.isShop()) {
                    Shop.goToShop(clickedNode, () -> {
                        Player.continueJourney();
                    });
                } else if (clickedNode.type == EVENT) {
                    NonCombatEvents.goToNonCombatEvents(clickedNode.nonCombatEvent, () -> {
                        Player.continueJourney();
                    });
                } else {
                    throwAndLogError('Unknown node type ${clickedNode.type}');
                }
        }
    }
    public static function getTierIndexByNode(nodeToFind: MapNode) {
        for (tierIndex in 0...nodesByTier.length) {
            for (node in nodesByTier[tierIndex]) {
                if (node == nodeToFind) return tierIndex;
            }
        }
        return -1;
    }

    public static function closeAllUI() {
        GUI.close('SettingsUI');
        GUI.close('CharacterUI');
        GUI.close('InventoryUI');
        GUI.close('PopupUI');
        closeStandardUIWithState('WAITING');
        doAfter(500, () -> { playerState = 'IDLE'; });   // To prevent clicking through
    }

    public static function getOnlyRootNode() return nodesByTier[0][0];
    public static function getRootNodes() return nodesByTier[0];
    public static function isLastAccessedNodeLastInJourney() return lastAccessedNode != null && lastAccessedNode.isLastNode();
    public static function isMapGenerated() return nodesByTier != null;
    public static function countNodesVisited() return arraySumInt(nodesByTier.map(arr -> arr.filter(node -> node.state == 'VISITED').length));
    // Debug
    public static function skipNodes(nNodes: Int = 1) {
        var nodesRemaining = nNodes;
        if (lastAccessedNode == null) {
            lastAccessedNode = nodesByTier[0][0];
        }
        while (lastAccessedNode.hasChildren() && nodesRemaining > 0) {
            lastAccessedNode = lastAccessedNode.nextNodes[0];
            nodesRemaining--;
        }
        if (lastAccessedNode.isLastNode())
            Player.continueJourney();
        else
            goToMapSceneAndContinue();
    }
}

