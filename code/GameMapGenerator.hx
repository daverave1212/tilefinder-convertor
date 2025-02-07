
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

class GameMapGenerator {

    public static function generateMap(journey: ChapterJourney) {
        var nodesByTier: Array<Array<MapNode>> = [];
        for (tierIndex in 0...journey.nTiers) {
            nodesByTier.push([]);
            final nNodesInTier = journey.nodesPerTier(tierIndex);
            for (nodeIndexInTier in 0...nNodesInTier) {
                final node = new MapNode(BATTLEFIELD_ENCOUNTER, {
                    tierIndex: tierIndex,
                    nodeIndexInTier: nodeIndexInTier
                });
                nodesByTier[tierIndex].push(node);
            }
            if (tierIndex > 0)
                linkPreviousNodesToCurrentNodes(nodesByTier[tierIndex-1], nodesByTier[tierIndex]);
        }
        journey.setupShops(nodesByTier);
        for (tierIndex in 0...journey.nTiers) {
            var tier = nodesByTier[tierIndex];
            for (nodeIndex in 0...tier.length) {
                var node = tier[nodeIndex];
                journey.onEveryNode(node, tierIndex, tier);
            }
        }
        return nodesByTier;
    }

    public static function generateNodesByTierFromDynamicByTier(dynByTier: Array<Array<Dynamic>>): Array<Array<MapNode>> {
        var nodesByTier: Array<Array<MapNode>> = [];
        function getMapNodeByIndices(pos: {tierIndex: Int, nodeIndexInTier: Int}) return nodesByTier[pos.tierIndex][pos.nodeIndexInTier];
        for (tierIndex in 0...dynByTier.length) {
            nodesByTier.push([]);
            for (nodeDyn in dynByTier[tierIndex]) {
                final node = MapNode.createFromDynamicWithoutNextAndParent(nodeDyn);
                nodesByTier[tierIndex].push(node);
            }
            if (tierIndex != 0) {
                final prevTierIndex = tierIndex - 1;
                for (prevNodeIndex in 0...nodesByTier[prevTierIndex].length) {
                    final prevMapNode = nodesByTier[prevTierIndex][prevNodeIndex];
                    final prevDynNode = dynByTier[prevTierIndex][prevNodeIndex];
                    prevMapNode.nextNodes = prevDynNode.nextNodesIndices.map(indices -> getMapNodeByIndices(indices));
                }
            }
        }
        return nodesByTier;
    }


    public static function generateTutorialMap() {
        var mission1 = new MapNode(BATTLEFIELD_ENCOUNTER, { tierIndex: 0, battlefieldEncounterName: 'Tutorial', skipAfterCombat: true });
        var mission2 = new MapNode(BATTLEFIELD_ENCOUNTER, { tierIndex: 1, battlefieldEncounterName: 'Home Break-In', skipAfterCombat: true });
        var mission3 = new MapNode(BATTLEFIELD_ENCOUNTER, { tierIndex: 2, battlefieldEncounterName: 'Stolen Socks', skipAfterCombat: false});
            mission3.afterCombatOptions = {
                specificLoot: ['Dirty Shirt', 'Socks', 'Three Leaf Clover']
            };
        var mission4 = new MapNode(MERCHANT, { tierIndex: 3, shopItems: ['Moldy Bread', 'Clean Underwear', 'Rotten Boot', 'Cheese', 'Bit of Coal'] });
            mission4.setDefaultAnimation('Forest');
        var mission5 = new MapNode(BATTLEFIELD_ENCOUNTER, { tierIndex: 4, battlefieldEncounterName: 'Mad Peasants', skipAfterCombat: true });
        var mission6 = new MapNode(BATTLEFIELD_ENCOUNTER, { tierIndex: 5, battlefieldEncounterName: 'Kingly', skipAfterCombat: true });
        mission1.addNextNode(mission2).addNextNode(mission3).addNextNode(mission4).addNextNode(mission5).addNextNode(mission6);
        var nodesByTier: Array<Array<MapNode>> = [
            [mission1], [mission2], [mission3], [mission4], [mission5], [mission6]
        ];
        return nodesByTier;
    }

    static function linkPreviousNodesToCurrentNodes(prevNodes: Array<MapNode>, currNodes: Array<MapNode>) {
        if (prevNodes.length == 1) {
            for (node in currNodes) prevNodes[0].addNextNode(node);
        } else if (currNodes.length == 1) {
            for (node in prevNodes) node.addNextNode(currNodes[0]);
        } else if (prevNodes.length == currNodes.length) {
            for (i in 0...prevNodes.length) prevNodes[i].addNextNode(currNodes[i]);
            function addExtraLink() {
                final nodeWithExtraLinkIndex = randomIntBetween(0, prevNodes.length - 1);
                final nodeToLinkToIndex: Int =
                    if (nodeWithExtraLinkIndex == 0) 1 else
                    if (nodeWithExtraLinkIndex == prevNodes.length - 1) prevNodes.length - 2 else
                    if (percentChance(50)) nodeWithExtraLinkIndex - 1
                    else nodeWithExtraLinkIndex + 1;
                prevNodes[nodeWithExtraLinkIndex].addNextNode(currNodes[nodeToLinkToIndex]);
            }
            if (percentChance(50)) {
                addExtraLink();
            }
        } else if (prevNodes.length <= currNodes.length) {
            function addBToA(a, b) a.addNextNode(b);
            linkNodes(prevNodes, currNodes, addBToA);
        } else {
            function addAToB(a, b) b.addNextNode(a);
            linkNodes(currNodes, prevNodes, addAToB);
        }
    }

    static function linkNodes(prevNodes: Array<MapNode>, currNodes: Array<MapNode>, linkFunction: MapNode -> MapNode -> Void) {
        function match1To1(nodesA: Array<MapNode>, nodesB: Array<MapNode>) { for (i in 0...nodesA.length) { linkFunction(nodesA[i], nodesB[i]); } }
        function match1ToAll(nodeA: MapNode, nodesB: Array<MapNode>) { for (nodeB in nodesB) linkFunction(nodeA, nodeB); }

        var prevNodeIndex = 0;
        for (currNodeIndex in 0...currNodes.length) {
            linkFunction(prevNodes[prevNodeIndex], currNodes[currNodeIndex]);

            final prevNodesRemaining = prevNodes.length - 1 - prevNodeIndex;
            final currNodesRemaining = currNodes.length - 1 - currNodeIndex;
            if (prevNodesRemaining == currNodesRemaining) {
                final restOfPrevNodes = prevNodes.slice(prevNodeIndex + 1);
                final restOfCurrNodes = currNodes.slice(currNodeIndex + 1);
                match1To1(restOfPrevNodes, restOfCurrNodes);
                break;
            }
            if (prevNodesRemaining == 0) {
                final lastPrevNode = prevNodes[prevNodeIndex];
                final restOfCurrNodes = currNodes.slice(currNodeIndex + 1);
                match1ToAll(lastPrevNode, restOfCurrNodes);
                break;
            }
            if (percentChance(50))
                prevNodeIndex++;
        }
    }

    // Not used atm
    static function setupAllShops(rootNode: MapNode) {
        function setupShops(currentPath: Array<MapNode>) {
            function getRandomNodeOfType(path: Array<MapNode>, nodeType: String): MapNode {
                final availableNodes = path.filter(node -> node.type == nodeType);
                if (availableNodes.length == 0) throwAndLogError('No available nodes found!');
                final returnedNode: MapNode = randomOf(availableNodes);
                return returnedNode;
            }
            function changeRandomBattlefieldEncounterNode(path: Array<MapNode>, nodeType: String) {
                var randomAvailableNode = getRandomNodeOfType(path, BATTLEFIELD_ENCOUNTER);
                randomAvailableNode.type = nodeType;
            }
    
            var nodeIterator = currentPath[currentPath.length - 1];
            if (nodeIterator.hasChildren()) {
                for (nextNode in nodeIterator.nextNodes) {
                    var pathCopy = currentPath.map(o -> o);
                    pathCopy.push(nextNode);
                    setupShops(pathCopy);
                }
            } else {    // If it's the end of the path
                if (!!!pathContainsNodeType(currentPath, MERCHANT))
                    changeRandomBattlefieldEncounterNode(currentPath, MERCHANT);
                if (!!!pathContainsNodeType(currentPath, BLACKSMITH))
                    changeRandomBattlefieldEncounterNode(currentPath, BLACKSMITH);
                if (!!!pathContainsNodeType(currentPath, NANA_JOY))
                    changeRandomBattlefieldEncounterNode(currentPath, NANA_JOY);
            }
    
        }
        var startingPath = [rootNode];
        setupShops(startingPath);
    }


    
    public static function pathContainsNodeType(path: Array<MapNode>, nodeType: String) return path.filter(node -> node.type == nodeType).length > 0;
    public static function pathContainsShop(path: Array<MapNode>) return path.filter(node -> MapNode.getAllShopTypes().indexOf(node.type) != -1).length > 0;
    public static function getAllPathsFromNode(rootNode: MapNode, ?maxLength: Int = 999) {
        var currentPath = [rootNode];
        var allPaths: Array<Array<MapNode>> = [currentPath];

        function mapAllPaths(currentPath: Array<MapNode>, remainingLength = 0) {
            if (remainingLength == 0) return;
            var lastNode = currentPath[currentPath.length - 1];
            if (!lastNode.hasChildren()) {
                return;
            } else if (lastNode.nextNodes.length == 1) {
                currentPath.push(lastNode.getOnlyChild());
                mapAllPaths(currentPath, remainingLength - 1);
            } else {
                allPaths.remove(currentPath);
                for (node in lastNode.nextNodes) {
                    var newPath = currentPath.copy();
                    newPath.push(node);
                    allPaths.push(newPath);
                    mapAllPaths(newPath, remainingLength - 1);
                }
            }
        }

        mapAllPaths(currentPath, maxLength - 1);
        return allPaths;
    }
    public static function getRandomNodeInPath(path: Array<MapNode>, ?constraint: MapNode -> Bool) {
        var usedPath = if (constraint != null) path.filter(constraint) else path;
        return usedPath[randomIntBetween(0, usedPath.length - 1)];
    }

    public static function getLongestCombatChain(path: Array<MapNode>): Array<Int> {
        var longestCombatChainStartIndex = 0;
        var longestChainLength = 0;

        var currentCombatChainStartIndex = 0;
        var currentChainLength = 0;

        var state = 'IN_CHAIN';
        function ifLongestThenRecordIt() {
            if (currentChainLength >= longestChainLength) {
                longestChainLength = currentChainLength;
                longestCombatChainStartIndex = currentCombatChainStartIndex;
            }
        }
        for (i in 0...path.length) {
            final node = path[i];

            switch (state) {
                case 'IN_CHAIN':
                    if (node.type == BATTLEFIELD_ENCOUNTER) {
                        currentChainLength++;
                    } else {
                        state = 'OUT_OF_CHAIN';
                        ifLongestThenRecordIt();
                        currentChainLength = 0;
                    }
                case 'OUT_OF_CHAIN':
                    if (node.type == BATTLEFIELD_ENCOUNTER) {
                        currentChainLength++;
                        currentCombatChainStartIndex = i;
                        state = 'IN_CHAIN';
                    }
            }
        }
        ifLongestThenRecordIt();
        if (longestChainLength == 0) {
            return [];
        } else {
            return [for (i in longestCombatChainStartIndex...(longestCombatChainStartIndex + longestChainLength)) i];
        }
    }

    public static function getRandomCombatNodeInPath(path: Array<MapNode>) return getRandomNodeInPath(path, node -> node.isCombat());
    public static function getLoneliestCombatNodeInPath(path: Array<MapNode>): Int {
        final longestChain = getLongestCombatChain(path);
        if (longestChain.length == 0) return -1;
        final firstIndex = longestChain[0];
        final middleIndex: Int = firstIndex + int(longestChain.length / 2);
        return middleIndex;
    }
    public static function getMaybeLoneliestCombatNode(path: Array<MapNode>): Int {
        final longestChain = getLongestCombatChain(path);
        if (longestChain.length == 0) return -1;
        if (longestChain.length == 1) return 0;
        if (longestChain.length == 2) {
             final randomIndex: Int = cast randomOf([0, 1]);
             return randomIndex;
        }
        final indicesByLikelyhood: Array<Int> = [];
        final halfIndex = int(longestChain.length / 2);
        for (i in 0...halfIndex + 1) {
            final nTimesToRepeat = i + 1;
            pushTimes(indicesByLikelyhood, i, nTimesToRepeat);
        }
        for (i in (halfIndex + 1)...longestChain.length) {
            final nTimesToRepeat = longestChain.length - i;
            pushTimes(indicesByLikelyhood, i, nTimesToRepeat);
        }
        final result: Int = randomOf(indicesByLikelyhood);
        return result;
    }
    public static function getMaybeEdgiestCombatNode(path: Array<MapNode>): Int {
        final longestChain = getLongestCombatChain(path);   // This contains an array of indices
        if (longestChain.length == 0) return -1;
        if (longestChain.length <= 2) {
            final randomIndex: Int = cast randomOf(longestChain);
            return randomIndex;
        }

        final indicesByLikelyhood: Array<Int> = [];
        final halfIndex = int(longestChain.length / 2);

        for (i in 0...halfIndex + 1) {
            final nTimesToRepeat = int(longestChain.length / 2) - i;
            pushTimes(indicesByLikelyhood, longestChain[i], nTimesToRepeat);
        }
        for (i in (halfIndex + 1)...longestChain.length) {
            final nTimesToRepeat = i - int(longestChain.length);
            pushTimes(indicesByLikelyhood, longestChain[i], nTimesToRepeat);
        }
        final result: Int = randomOf(indicesByLikelyhood);
        return result;
    }

}