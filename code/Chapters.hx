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
import U.*;
import scripts.BattlefieldEncounterDatabase.getRandomEncounterOfLevel;
import scripts.BattlefieldEncounterDatabase.getRandomEncounterOfLevelWithFlag;
import scripts.BattlefieldEncounterDatabase.getRandomEncounterWithFlag;
import scripts.BattlefieldEncounterDatabase.getRandomEncounterOfLevelWithoutFlag;
import scripts.GameMapGenerator.getRandomNodeInPath;
import scripts.GameMapGenerator.getAllPathsFromNode;
import scripts.GameMapGenerator.pathContainsShop;
import scripts.GameMapGenerator.pathContainsNodeType;




class Chapters {

    static var k = {
        firstJourney: {
            nTiers: 9,
            rescueMissionTier: 2,
            dialogueTier: 5
        },
        secondJourney: {
            nTiers: 10,
            middleTier: 4,
            dialogueTier: 5
        },
        thirdJourney: {
            nTiers: 8,
            middleTier: 3,
            dialogueTier: 2
        }
    }

    public static var chapters: Array<GameChapter> = [
        new GameChapter({
            name: 'Tutorial',
            bannerAnimation: 'Tutorial',
            onStart: (callbackThatWillBeSkipped: Void -> Void) -> {                 // The callback (from Player) is skipped because it redirects to the GameMap
                MessageScreen.goToMessageScreenWhiteAndThen('One day...', () -> {
                    NonCombatEvents.goToNonCombatEvents('Intro', () -> {
                        Player.progression.currentJourneyIndex = 0;
                        Player.gold = 25;
                        GameMap.generateTutorialMap();
                        GameMap.onClickOnMapNode(GameMap.getOnlyRootNode());
                        GameMap.savedScrollX = -1;
                    });
                });
            },
            journeys: [
                new ChapterJourney({
                    name: 'Tutorial',
                    generationFlag: 'TUTORIAL',
                    defaultNodeAnimation: 'Forest',
                    backgroundImagePath: 'Images/Backgrounds/MapGrass.png',
                    preventMessageScreen: true,      // Message screen for tutorial is handled in the chapter start for this tutorial
                    onJourneyEnd: (callback: Void -> Void) -> {
                        Player.progression.tutorialIsDone = true;
                        Game.save(() -> {
                            callback();
                        });
                    }
                })
            ]
        }),
        new GameChapter({
            name: 'Chapter 2',
            bannerAnimation: 'Chapter2',
            onStart: null,
            journeys: [
                new ChapterJourney({
                    name: 'Road To The King',
                    generationFlag: 'NORMAL',
                    defaultNodeAnimation: 'Forest',
                    backgroundImagePath: 'Images/Backgrounds/MapGrass.png',
                    nTiers: k.firstJourney.nTiers,
                    setupShops: (allTiers: Array<Array<MapNode>>) -> setupShopsStandardByHalf(allTiers, k.firstJourney.rescueMissionTier, { tryAlwaysNatas: true, tryAlwaysDarkCellar: true, tryAlwaysNanaJoyMeeting: true, tryAlwaysNanaJoyAfter: true }),
                    nodesPerTier: (tierIndex) -> {
                        final progression = Player.progression;
                        if (tierIndex == 0) return 1;
                        if (tierIndex == 1) return randomIntBetween(1, 2);
                        if (tierIndex == k.firstJourney.rescueMissionTier) return 2;    // Rescue mission
                        if (tierIndex == k.firstJourney.nTiers - 1) {                   // Boss tier
                            var nBosses = 1;                                            // Pumpzilla
                            if (progression.defeatedSpatula1) nBosses += 1;             // Blessed Children
                            if (progression.defeatedSpatula2) nBosses += 1;             // Father Almund
                            return nBosses;
                        }
                        if (tierIndex == k.firstJourney.dialogueTier) {
                            if (progression.didKingIntro == false) return 1;
                            if (progression.didKingDefeatedEncounter == false && Player.progression.defeatedKingOrMarceline) return 1;
                        }
                        
                        return randomIntBetween(2, 4);   // Any mission except the last
                    },
                    onEveryNode: (node: MapNode, tierIndex: Int, _) -> {
                        node.setDefaultAnimation('Forest');
                        final nTiers = k.firstJourney.nTiers, rescueMissionTier = k.firstJourney.rescueMissionTier, dialogueTier = k.firstJourney.dialogueTier;
                        final nodeIndexInTier = node.nodeIndexInTier;
                        
                        function determineIfGearOrSpellLoot() {
							final wasBossFight = GameMap.lastAccessedNode != null && GameMap.nodesByTier != null && GameMap.lastAccessedNode.tierIndex == GameMap.nodesByTier.length - 1;
							final shouldGiveSpellReward = [1,2,5,8].indexOf(tierIndex) != -1;
							final isFirstJourney = Player.progression.currentJourneyIndex == 0;
							if (isFirstJourney == false) {
                                trace('For node at tier ${tierIndex} = ANY');
                                return 'ANY';
                            }
							else {
								if (wasBossFight == false && shouldGiveSpellReward) {
                                    trace('For node at tier ${tierIndex} = SPELL');
                                    return 'SPELL';
                                } else {
                                    trace('For node at tier ${tierIndex} = GEAR');
                                    return 'GEAR';
                                }
							}
						}

                        node.afterCombatOptions = {
                            gearOrSpell: determineIfGearOrSpellLoot()
                        }

                        node.level =
                            if (tierIndex == 0) 0
                            else if (tierIndex > 0 && tierIndex < k.firstJourney.rescueMissionTier + 2) 1
                            else 2;


                        if (tierIndex < rescueMissionTier && node.isCombat() == false) {
                            node.makeRandomNormalBattlefieldEncounter();
                        } else if (tierIndex == rescueMissionTier) {
                            final classToFlag = [
                                'Knight' => 'WHITE_FLAG',
                                'Mage' => 'BLUE_FLAG',
                                'Ranger' => 'GREEN_FLAG'
                            ];
                            final currentClassFlag = classToFlag[Player.characters[0].getClassName()];
                            var remainingRescues = BattlefieldEncounterDatabase
                                .getRescueEncounters()
                                .filter(e -> e.hasFlag(currentClassFlag) == false);
                            remainingRescues = [remainingRescues[0], remainingRescues[1]];
                            final encounter = remainingRescues[nodeIndexInTier];
                            node.makeBattlefieldEncounter(encounter);
                        } else if (tierIndex == dialogueTier) {
                            if (Player.progression.didKingIntro == false) node.makeNonCombatEvent('King Intro');
                            else if (Player.progression.defeatedKingOrMarceline && Player.progression.didKingDefeatedEncounter == false) node.makeNonCombatEvent('King Meeting Defeated');
                            else if (node.isCombat()) node.makeRandomNormalBattlefieldEncounter();
                        } else if (tierIndex == nTiers - 1) {
                            switch (node.nodeIndexInTier) {
                                case 0:
                                    node.setOverrideAnimation('Pumpzilla');
                                    node.makeBattlefieldEncounter('Pumpzilla');
                                case 1:
                                    node.setOverrideAnimation('Blessed Children of Almund');
                                    if (Player.progression.defeatedBlessedChildren == false) {
                                        node.makeBattlefieldEncounter('Blessed Children of Almund');
                                    } else {
                                        node.makeBattlefieldEncounter('Blessed Children of Almund 2');
                                    }
                                case 2:
                                    node.setOverrideAnimation('Father Almund');
                                    if (Player.progression.defeatedFatherAlmund) {
                                        node.makeBattlefieldEncounter('Father Almund 2');
                                    } else {
                                        node.makeBattlefieldEncounter('Father Almund');
                                    }
                                default: trace('WARNING: Nodeindex ${node.nodeIndexInTier} has no case.');
                            }
                        } else if (node.isCombat()) {
                            node.makeRandomNormalBattlefieldEncounter();
                        } else {
                            return;
                        }
                    },
                    onJourneyEnd: (callback: Void -> Void) -> {
                        if (Game.isFullGame) {
                            callback();
                        } else {
                            Game.clearSave(() -> {       
                                MessageScreen.goToMessageScreenWhiteAndThen('End of demo', () -> {
                                    MessageScreen.goToMessageScreenWhiteAndThen('Thanks for playing!', () -> {
                                        MessageScreen.goToMessageScreenWhiteAndThen('Wishlist on Steam!', () -> {
                                            changeScene('Menu');
                                        });
                                    });
                                });
                            });
                        }
                    }
                }),
                new ChapterJourney({
                    name: 'Treasure Cove',
                    generationFlag: 'NORMAL',
                    defaultNodeAnimation: 'Beach',
                    backgroundImagePath: 'Images/Backgrounds/MapBeach.png',
                    nTiers: k.secondJourney.nTiers,
                    setupShops: (allTiers: Array<Array<MapNode>>) -> setupShopsStandardByHalf(allTiers, k.secondJourney.middleTier, { tryAlwaysNatas: true, tryAlwaysHellPortal: true, tryAlwaysNanaJoyAfter: true }),
                    nodesPerTier: (tierIndex) -> {
                        final progression = Player.progression;
                        if (tierIndex == k.secondJourney.nTiers - 1) {              // Boss battle
                            var nBosses = 1;                                        // Stormjr
                            if (progression.didMarcelineEncounter) nBosses += 1;    // Captain Stashton
                            return nBosses;
                        }
                        if (tierIndex == k.secondJourney.dialogueTier) {
                            if (progression.defeatedStormjr == false) return 1;                          // Stashton and Marceline partial
                            if (Player.progression.didKingPleadEncounter == false && Player.progression.defeatedFatherAlmund) return 1;
                            if (progression.defeatedKingOrMarceline && progression.didMarcelineDefeatedEncounter == false) return 1;
                        }
                        return randomIntBetween(2, 4);   // Any mission except the last
                    },
                    onEveryNode: (node: MapNode, tierIndex: Int, _) -> {
                        node.setDefaultAnimation('Ship');
                        final nTiers = k.secondJourney.nTiers, dialogueTier = k.secondJourney.dialogueTier;
                        node.level =                        
                            if (tierIndex >= 0 && tierIndex < k.secondJourney.middleTier) 3
                            else 4;
                       
                        if (tierIndex == dialogueTier) {
                            if (Player.progression.defeatedStormjr == false) node.makeNonCombatEvent('Captain Stashton and Marceline');
                            else if (Player.progression.didKingPleadEncounter == false && Player.progression.defeatedFatherAlmund) {
                                node.setDefaultAnimation('Castle');
                                node.makeNonCombatEvent('King Plead Meeting');
                            }
                            else if (Player.progression.defeatedKingOrMarceline && Player.progression.didMarcelineDefeatedEncounter == false) node.makeNonCombatEvent('Marceline Meeting Defeated');
                            else if (node.isCombat()) node.makeRandomNormalBattlefieldEncounter();
                        } else if (tierIndex == nTiers - 1) {
                            if (node.nodeIndexInTier == 0) {
                                node.setOverrideAnimation('Stormjr');
                                if (Player.progression.defeatedStormjr == false) {
                                    node.makeBattlefieldEncounter('Stormjr');
                                } else if (Player.progression.defeatedStormjr2 == false) {
                                    node.makeBattlefieldEncounter('Stormjr 2');     // Same combat, just different dialogue
                                } else if (Player.progression.didStormjr3Dialogue == false) {
                                    node.makeNonCombatEvent('Stormjr 3');
                                } else {
                                    node.makeBattlefieldEncounter('Stormjr 4');     // Same combat, just different dialogue
                                }
                            }
                            if (node.nodeIndexInTier == 1) {
                                node.setOverrideAnimation('Captain Stashton');
                                if (Player.progression.defeatedCaptainStashton == false) {
                                    node.makeBattlefieldEncounter('Captain Stashton');
                                } else {
                                    node.makeBattlefieldEncounter('Captain Stashton 2');
                                }
                            }
                        } else if (node.isCombat()) {
                            node.makeRandomNormalBattlefieldEncounter();
                        } else {
                            return;
                        }
                    },
                    onJourneyEnd: (callback: Void -> Void) -> {
                        callback();
                    }
                }),
                new ChapterJourney({
                    name: "Hell's Gate",
                    isSpecial: true,
                    generationFlag: 'NORMAL',
                    defaultNodeAnimation: 'Cave',
                    backgroundImagePath: 'Images/Backgrounds/MapHell.png',
                    nTiers: 6,
                    nodesPerTier: (tierIndex) -> {
                        if (tierIndex != 5) {
                            return randomIntBetween(1, 2);   // Any mission except the last
                        } else {
                            return 1;
                        }
                    },
                    setupShops: (allTiers: Array<Array<MapNode>>) -> {
                        // Do not setup any shops
                    },
                    onEveryNode: (node: MapNode, tierIndex: Int, _) -> {
                        node.setDefaultAnimation('Hell');
                        node.level = 4;
                        final nTiers = 6;
                        if (tierIndex == nTiers - 1) {
                            node.makeBattlefieldEncounter(BattlefieldEncounterDatabase.get('Natas'));
                        } else {
                            node.makeBattlefieldEncounter(BattlefieldEncounterDatabase.getRandomEncounterOfLevelWithFlag(4, 'HELL'));
                        }
                    }
                }),
                new ChapterJourney({
                    name: 'The Somnium',
                    isSpecial: true,
                    generationFlag: 'NORMAL',
                    defaultNodeAnimation: 'Forest',
                    backgroundImagePath: 'Images/Backgrounds/MapSomnium.png',
                    nTiers: 5,
                    nodesPerTier: (tierIndex) -> {
                        if (tierIndex != 4) {
                            return randomIntBetween(1, 2);   // Any mission except the last
                        } else {
                            return 1;
                        }
                    },
                    setupShops: (allTiers: Array<Array<MapNode>>) -> {
                        // Do not setup any shops
                    },
                    onEveryNode: (node: MapNode, tierIndex: Int, _) -> {
                        node.setDefaultAnimation('Somnium');
                        node.level = 4;
                        final nTiers = 5;
                        if (tierIndex == nTiers - 1) {
                            node.makeBattlefieldEncounter(BattlefieldEncounterDatabase.get('Sandman'));
                        } else {
                            node.makeBattlefieldEncounter(BattlefieldEncounterDatabase.getRandomEncounterOfLevelWithFlag(4, 'SOMNIUM'));
                        }
                    }
                }),
                new ChapterJourney({
                    name: 'To The Castle!',
                    generationFlag: 'NORMAL',
                    defaultNodeAnimation: 'Cave',
                    backgroundImagePath: 'Images/Backgrounds/MapCave.png',
                    nTiers: k.thirdJourney.nTiers,
                    nodesPerTier: (tierIndex) -> {
                        final progression = Player.progression;
                        if (tierIndex == k.thirdJourney.nTiers - 1) {               // Boss tier
                            var nBosses = 1;                                        // Spatula / Spatula 2
                            if (progression.didKingPleadEncounter && progression.defeatedKingOrMarceline == false) nBosses += 1;   // King/Marceline
                            if (progression.defeatedKingOrMarceline) nBosses += 1;  // Tyl
                            return nBosses;
                        }
                        if (tierIndex == k.thirdJourney.dialogueTier) {
                            if (progression.didMarcelineEncounter == false) return 1;               // Marceline Meeting 1
                            if (Player.progression.defeatedCaptainStashton && Player.progression.didMarcelineEncounter2 == false) return 1; // Marceline meeting 2
                            if (progression.didKingPleadEncounter && progression.sidedWith == 'none') return 1; // King vs Marceline Encounter
                        }
                        
                        return randomIntBetween(2, 4);   // Any mission except the last
                    },
                    setupShops: (allTiers: Array<Array<MapNode>>) -> {
                        setupShopsStandardByHalf(allTiers, k.thirdJourney.middleTier);
                    },
                    onEveryNode: (node: MapNode, tierIndex: Int, _) -> {
                        node.setDefaultAnimation('Cave');
                        final nTiers = k.thirdJourney.nTiers, dialogueTier = k.thirdJourney.dialogueTier;
                        node.level = 5;
                       
                        if (tierIndex == dialogueTier) {
                            if (Player.progression.didMarcelineEncounter == false) node.makeNonCombatEvent('Marceline Meeting');
                            else if (Player.progression.defeatedCaptainStashton && Player.progression.didMarcelineEncounter2 == false) node.makeNonCombatEvent('Marceline Meeting 2');
                            else if (Player.progression.didKingPleadEncounter && Player.progression.sidedWith == 'none') node.makeNonCombatEvent('King vs Marceline');
                            else if (node.isCombat()) node.makeRandomNormalBattlefieldEncounter();
                        } else if (tierIndex == nTiers - 1) {
                            node.skipAfterCombat = true;
                            if (node.nodeIndexInTier == 0) {
                                if (Player.progression.defeatedSpatula1 == false) {
                                    node.setOverrideAnimation('Count Spatula');
                                    node.makeNonCombatEvent('Spatula 1 Before');
                                } else {
                                    node.setOverrideAnimation('Count Spatula');
                                    node.makeBattlefieldEncounter('Count Spatula 2');
                                }
                            }
                            if (node.nodeIndexInTier == 1) {
                                if (Player.progression.defeatedKingOrMarceline == false) {
                                    node.makeNonCombatEvent('King or Marceline Battle');
                                }
                                if (Player.progression.defeatedKingOrMarceline) {
                                    node.setOverrideAnimation('Tyl');
                                    node.makeBattlefieldEncounter('Tyl');
                                }
                            }
                        } else if (node.isCombat()) {
                            node.makeRandomNormalBattlefieldEncounter();
                        } else {
                            return;
                        }
                    },
                    onJourneyEnd: (callback: Void -> Void) -> {
                        callback();
                    }
                })
            ]
        })
    ];

    public static function getTutorialChapter() return chapters[0];
    public static function getRegularRun() return chapters[1];
    public static function getChapterByIndex(index: Int) return chapters[index];


    
    static function ensureAllPathsContainAtLeast1Shop(paths: Array<Array<MapNode>>) {
        for (path in paths) {
            final longestCombatChain = GameMapGenerator.getLongestCombatChain(path);
            if (longestCombatChain.length <= 1) return;
            final lonelyCombatIndex = GameMapGenerator.getMaybeEdgiestCombatNode(path);
            final nodeToTurnIntoNonCombat = path[lonelyCombatIndex];
            if (percentChance(75)) {
                nodeToTurnIntoNonCombat.makeRandomShop();
            } else {
                nodeToTurnIntoNonCombat.makeCampfire();
            }

            if (pathContainsNodeType(path, EVENT) == false) {
                final anotherLonelyCombatIndex = GameMapGenerator.getMaybeEdgiestCombatNode(path);
                if (anotherLonelyCombatIndex == -1 || anotherLonelyCombatIndex == 0) {
                    continue;
                }
                final nodeToMakeEvent = path[anotherLonelyCombatIndex];
                nodeToMakeEvent.makeRandomEvent();
            }
        }
    }
    
    /* Splits the map into 2 halves and a middleNodes.
       - All paths in the first half have at least 1 shop
       - All paths in the second half have at least 1 shop
       - The indexOfHalf has only combat nodes */
    static function setupShopsStandardByHalf(allTiers: Array<Array<MapNode>>, indexOfHalf: Int, ?options: {
        ?tryAlwaysDarkCellar: Bool,
        ?tryAlwaysNatas: Bool,
        ?tryAlwaysHellPortal: Bool,
        ?tryAlwaysNanaJoyMeeting: Bool,
        ?tryAlwaysNanaJoyAfter: Bool
    }): Void {
        if (options == null) options = {};
        function getRandomNonCombatNode(fromTier: Int, ?toTier = -1) {
            final foundNodes: Array<MapNode> = [];
            if (toTier == -1) toTier = allTiers.length - 1;
            for (tierIndex in fromTier...allTiers.length - 1) {
                if (tierIndex == indexOfHalf) continue;
                final tier = allTiers[tierIndex];
                for (node in tier) {
                    if (node.type == EVENT || node.type == MERCHANT || node.type == NANA_JOY || node.type == BLACKSMITH) foundNodes.push(node);
                }
            }
            if (foundNodes.length == 0) return null;
            shuffle(foundNodes);
            return foundNodes[0];
        }
        final rootNode = allTiers[0][0];
        final allPathsToHalf = getAllPathsFromNode(rootNode, indexOfHalf);
        ensureAllPathsContainAtLeast1Shop(allPathsToHalf);
        final secondHalfNodesStart = allTiers[indexOfHalf + 2];             // Ignore first tier after rescue
        final secondHalfLength = allTiers.length - (indexOfHalf + 1) - 1;   // -1 because ignore last node (boss)
        for (node in secondHalfNodesStart)
            ensureAllPathsContainAtLeast1Shop(getAllPathsFromNode(node, secondHalfLength));

        // NOTE: Check for == true, because it could be null!
        if (options.tryAlwaysDarkCellar == true && Player.progression.isCellarKeyFound && Player.progression.hasStartingGear == false) {
            final cellarNode = getRandomNonCombatNode(3);
            if (cellarNode == null) return;
            cellarNode.makeNonCombatEvent('Dark Cellar');
        }
        if (options.tryAlwaysNatas == true && Player.progression.didStormjr3Dialogue && Player.progression.didNatasClarificationDialogue == false) {
            final natasNode = getRandomNonCombatNode(3);
            if (natasNode == null) return;
            natasNode.makeNonCombatEvent('Natas');
        }
        if (options.tryAlwaysHellPortal == true && Player.progression.didNatasClarificationDialogue && Player.progression.defeatedNatas == false) {
            final portalNode = getRandomNonCombatNode(3);
            if (portalNode == null) return;
            portalNode.makeNonCombatEvent('Hell Portal');
        }
        if (options.tryAlwaysNanaJoyMeeting == true && Player.progression.hasStartingGear && Player.progression.didNanaJoyMeeting == false) {
            final nanaNode = getRandomNonCombatNode(3);
            if (nanaNode == null) return;
            nanaNode.makeNonCombatEvent('Nana Joy Meeting');
        }
        if (options.tryAlwaysNanaJoyAfter == true && Player.progression.hasStartingGear && Player.progression.defeatedSandman == true) {
            final nanaNode = getRandomNonCombatNode(3);
            if (nanaNode == null) return;
            nanaNode.makeNonCombatEvent('Nana Joy After');
        }
    }
    static function tracePath(path: Array<MapNode>) {
        trace(path.map(node -> node.toString()).join(' -> '));
    }
	
}