

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

import com.stencyl.behavior.Script;
import com.stencyl.behavior.Script.*;

import scripts.Constants.*;
// import scripts.Battlefield.alertAndWait;
import scripts.Battlefield.sayFromUnitAndWait;
import scripts.Battlefield.getUnitByName;
import scripts.Battlefield.getRandomEnemyUnit;
import scripts.Battlefield.getRandomAlivePlayerUnit;
import scripts.Battlefield.getEnemyUnitWithName;
import scripts.Battlefield.sayFromActorAndWait;
import scripts.Battlefield.sayFromActor;
import scripts.Battlefield.getRandomUnitWithName;
import scripts.Battlefield.getRandomPlayerCharacterUnit;

import scripts.SpecialEffectsFluff.sayBubble;

import Std.int;

class BattlefieldEncounterDatabase_Encounters {

    public static inline var _      = '_';          // Empty tile
    public static inline var P      = 'Player';     // Player
    public static var tileShorthands = [
        '^^'    => 'Spike Trap',        'WW'    => 'Bear Trap',
        '~~'    => 'Acid Trap',         'OO'    => 'Toxic Fog',
        '<>'    => 'Silence Trap',      '&&'    => 'Oil',

        '--'    => '_',                 '[$]'   => 'Treasure Chest',
        '[]'    => 'Crate',             '(_)'   => 'Barrel',
        '(X)'   => 'Explosive Barrel',
        '()'    => 'Vase',              'R1'    => 'Rock',
        'R2'    => 'Rock Blockage',     'B1'    => 'Stones',
        'B2'    => 'Boulder',           'TT'    => 'Table',
        '@@'    => 'Bush',              '=='    => 'Log',
        '/@'    => 'Hay',               '+]'    => 'Gravestone',
        '88'    => 'Pumpkin',           '->'    => 'Spike Barricade',
        'ii'    => 'Magic Candles',

        'Pe' => 'Peasant',          'Ra' => 'Rat',
        'Pu' => 'Pumpling',         'Bk' => 'Bubak',
        'MP' => 'Molotov Peasant',  'LS' => 'Little Scout',
        'Ps' => 'Peasant',
        'SM' => 'Serfmaster',
        'HW' => 'Highwayman', 'HM' => 'Highwayman',

        'XC' => 'Exploding Crystal',
        'Go' => 'Goblin',


        'SK' => 'Spore Keeper',
        'RM' => 'Reverse Mermaid',
        'Bl' => 'Blubber',
        'BS' => 'Big Slime',
        'SS' => 'Small Slime',
        'Sl' => 'Slime',
        'CM' => 'Crewmate',
        'PB' => 'Pirate Bishop',
        'PP' => 'Pirate Peasant',
        'Ca' => 'Canon',
        'Bu' => 'Bucaneer',
        'Me' => 'Mermaid',

        'DW' => 'Darkwayman',   'DM' => 'Darkwayman',
        'Zo' => 'Zombie',       'Br' => 'Brat',
        'Be' => 'Beholder',
        'LG' => 'Lantern Ghoul',
        'Sk' => 'Spine Skull',
        'Dr' => 'Drider',
        'Wr' => 'Wraith',
        'LC' => 'Laser Crystal',
        'DC' => 'Draining Crystal',
        'Li' => 'Lightning Crystal',
        'CC' => 'Charging Crystal',
        'VC' => 'Void Crystal',
        'CG' => 'Crystal Golem',
        'Cy' => 'Cyclops',

        'Im' => 'Imp',
        'HH' => 'Hell Hound',
        'HG' => 'Hell Giant',
        'FB' => 'Fire Beholder',
        'HZ' => 'Hellzilla'
    ];

    static inline function makeWave(background: String, shorthands: Map<String, String>, board: Array<Array<String>>, ?events: Dynamic) {
        return {
            background: background,
            shorthands: shorthands,
            board: board,
            events: events == null ? ({start: [], end: [], finish: () -> {}}) : events
        }
    }

    static var lastCreatedIndicator: Actor;
    public static var encounters: Array<Dynamic> = [
        // Tutorial Encounters
        {   name: "Tutorial",
            animationName: 'Forest',
            flags: ['SPECIAL'],
            level: 0,
            waves: [
                makeWave('Road', ['PG' => 'Patrolling Guard'], [
                    ['__', '__', '__', '[]', '__', '__', '__'],
                    ['__', '__', '__', '__', '__', '__', '__'],
                    ['Pl', '__', 'PG', '__', '  ', '__', '  '],
                    ['__', '__', '__', '__', '__', '__', '__'],
                    ['__', '[]', '__', '__', '__', '__', 'PG']
                ], {
                    start: [
                        () -> {
                            var pc = Battlefield.getRandomPlayerCharacterUnit();
                            sayFromUnitAndWait(pc, "I'll deal with you one way or another...");
                        },
                        () -> alertAndWait('This is the battle board.'),
                        () -> alertAndWait('You always start on the left.', -100),
                        () -> alertAndWait('Enemies always start on the right.', 100),
                        () -> alertAndWait('During your turn, you can Move and Attack in any order.'),
                        () -> alertAndWait('When you\'re done, you can end your turn.'),
                        () -> alertAndWait('Defeat all enemies to win the battle!')
                    ],
                    end: [
                        () -> alertAndWait('You regenerate 20% of your total Health at the end of every battle.')
                    ],
                    finish: () -> { Player.characters[0].equippedSpells = ['Move', 'Melee Attack', 'Block']; }
                })
            ]
        },
        {   name: "Home Break-In",
            animationName: 'House',
            flags: ['SPECIAL'],
            level: 0,
            waves: [
                makeWave('House', ['Xg' => 'Crossbow Guard'], [
                    ['  ', '  ', '  ', '  ', '[]', '  ', '  '],
                    ['  ', '  ', '[]', '  ', '  ', '  ', '[]'],
                    ['Pl', '  ', '  ', '  ', '  ', '  ', 'Xg'],
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['[]', '  ', '  ', '[]', '  ', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "One step closer and you die!"),
                        () -> alertAndWait('Ok, listen carefully:'),
                        () -> {
                            alertAndWait("The blue bar under your HP is your MANA.");
                            final point = getUnitByName('Knight').getManaBarPointForTutorialIndicator();
                            lastCreatedIndicator = SpecialEffectsFluff.indicateWithArrows(point.x, point.y);
                        },
                        () -> {
                            alertAndWait("Every action costs MANA, except Moving.");
                            SpecialEffectsFluff.removeIndicator(lastCreatedIndicator);
                        },
                        () -> alertAndWait('You can do many actions on your turn, as long as you have enough MANA.'),
                        () -> alertAndWait('Every ability has a COOLDOWN timer.'),
                        () -> alertAndWait('Every time you cast an ability, you reduce the cooldowns of other spells by 1.'),
                        () -> alertAndWait('You now also have the Block ability!'),
                        () -> {
                            if (Game.isMobile) {
                                alertAndWait('Hold TAP on an Ability to see its description.');
                            } else {
                                alertAndWait('Good luck!');
                            }
                        }
                    ],
                    end: [
                        () -> alertAndWait('You will get other abilities later.'),
                        () -> alertAndWait('And no, you won\'t be forever alone.'),
                        () -> alertAndWait('You will have more characters as the game goes on!')
                    ],
                    finish: function() {
                        BattlefieldUI.self.setTutorialState('NONE');
                    }
                })
            ]
        },
        {   name: 'Stolen Socks',
            animationName: 'House',
            flags: ['SPECIAL'],
            level: 0,
            specificLoot: ['Cheese', 'Socks', 'Dirty Shirt'],
            waves: [
                makeWave('House', ['GS' => 'Guard With Socks'], [
                    ['  ', '  ', '[]', '  ', '  ', '[]', '  '],
                    ['WW', '  ', '[]', '  ', '  ', '  ', '  '],
                    ['Pl', 'WW', '  ', '  ', '  ', '  ', 'GS'],
                    ['WW', '  ', '[]', '  ', '[]', '  ', '  '],
                    ['[]', '  ', '[]', '  ', '  ', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Hey! Those are MY socks!"),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "Not anymore, criminal!"),
                        () -> alertAndWait('In fights, there will be traps on the ground.'),
                        () -> alertAndWait('They will trigger ONLY if you LAND on them when moving.'),
                        () -> {
                            if (Game.isMobile) {
                                alertAndWait('Tap on the Magnifying Glass icon to toggle INSPECT mode.');
                            } else {
                                alertAndWait('Also, hold Q to inspect units and traps.');
                            }
                        },
                    ],
                    end: [
                        () -> alertAndWait('After every battle, you will pick 1 out of 3 rewards.'),
                        () -> alertAndWait('If a reward glows, it means it is a RARE item!'),
                        () -> alertAndWait('Choose wisely!')
                    ]
                })
            ]
        },
        {   name: "Mad Peasants",
            animationName: 'Forest',
            flags: ['SPECIAL'],
            level: 0,
            waves: [
                {
                    background: "Forest",
                    shorthands: ['Ps' => 'Peasant', 'Xg' => 'Crossbow Guard'],
                    board: [
                        ['^^', '  ', '  ', '[]', '  ', '  ',  '/@'],
                        ['  ', '  ', '  ', '  ', '  ', 'Xg',  '  '],
                        ['Pl', '  ', 'WW', '  ', '  ', '  ',  '[]'],
                        ['  ', '  ', '  ', '  ', '/@', '  ',  '  '],
                        ['==', '==', 'WW', '  ', '  ', '  ',  'Ps']
                    ],
                    events: {
                        start: [
                            () -> alertAndWait('If you die, it\'s game over and you have to start from the beginning!'),
                            () -> alertAndWait('So don\'t die!'),
                            () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Die!!!')
                        ],
                        end: []
                    }
                }
            ]
        },
        {   name: 'Kingly',
            appearCondition: () -> Player.progression.defeatedSpatula1,
            animationName: 'Road',
            flags: ['SPECIAL', 'BOSS_MUSIC'],
            level: 1,
            waves: [
                makeWave('Road', ['PG' => 'Patrolling Guard', 'XG' => 'Crossbow Guard'], [
                    ['@@', '  ', '  ', '  ', '  ', '@@', '  '],
                    ['  ', '  ', '  ', '  ', '  ', 'PG', '@@'],
                    ['  ', 'Pl', '  ', '[]', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', 'XG'],
                    ['  ', '[]', '  ', '  ', '  ', '  ', '@@']
                ], {
                    start: [
                        () -> {
                            sayFromUnitAndWait(getEnemyUnitWithName('Patrolling Guard'), 'Halt!');
                        },
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Patrolling Guard'), 'Turn back, sir.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Patrolling Guard'), 'The King\'s castle is being evacuated!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Evacuated? What happened?'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Patrolling Guard'), 'A great evil has taken the castle!'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Patrolling Guard'), 'The King is in grave danger!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'I can help! I must get to the king immediately!'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Patrolling Guard'), '...'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Patrolling Guard'), 'TO CAUSE EVEN MORE TROUBLE, SCUM!?'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'But the great evil...'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Patrolling Guard'), 'GET HIM!!!')
                    ],
                    end: [
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'The King is in danger...'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'I must get to the King as fast as possible.'),
                        () -> {
                            Game.setAchievement('TUTORIAL_IS_DONE');
                            sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'No time to waste!');
                        }
                    ]
                })
            ]
        },
        

        // Rescue Encounters
        {   name: 'Knight Rescue Mission',
            animationName: 'Cave',
            level: 1,
            flags: ['RESCUE', 'WHITE_FLAG', 'SPECIAL'],
            waves: [
                makeWave('Cave', ['PG' => 'Patrolling Guard', 'XG' => 'Crossbow Guard'], [
                    ['WW', '  ', '  ', '  ', '()', 'R1', '  '],
                    ['()', 'Pl', '  ', 'WW', '  ', '  ', 'PG'],
                    ['  ', '  ', '  ', '  ', '  ', 'XG', '  '],
                    ['  ', 'Pl', '  ', '()', '  ', '  ', 'PG'],
                    ['WW', 'R1', '  ', '  ', 'WW', '  ', 'R1']
                ], {
                    begin: () -> {
                        final knightX = Battlefield.getTile(2, 6).getX() + 15;
                        final knightY = Battlefield.getTile(2, 6).getY() - 50;

                        var knight = U.createActor('UnitActor', 'BehindUnits', knightX, knightY);
                        knight.setAnimation('Knight');
                        U.flipActorHorizontally(knight);
                        var snare = U.createActor('TrapActor', 'BehindUnits', knightX + 29, knightY + 28);
                        snare.setAnimation('Snare');
                        Battlefield.encounterData = { knight: knight };
                    },
                    start: [
                        () -> {
                            for (unit in Battlefield.getAllAliveEnemyUnits().filter(u -> u.name != 'Crossbow Guard')) {
                                unit.flipHorizontally();
                            }
                            final knight: Actor = Battlefield.encounterData.knight;
                            sayFromActorAndWait(knight, 'Let me go! You\'re making a mistake!');
                        },
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Patrolling Guard'), "Back to prison with you."),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Patrolling Guard'), "Filthy dog."),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Crossbow Guard'), "Guys?"),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Patrolling Guard'), "* sigh *"),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Patrolling Guard'), "What now, Terry!?"),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Crossbow Guard'), "We have company!"),
                        () -> {
                            for (unit in Battlefield.getAllAliveUnitsWithName('Patrolling Guard')) {
                                unit.flipHorizontally();
                            }
                            sayFromUnitAndWait(getRandomUnitWithName('Patrolling Guard'), "Oh...");
                        },
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Patrolling Guard'), "DAMN YOU TERRY!! You left the door unlocked again!")
                    ],
                    end: [
                        () -> sayFromActorAndWait(Battlefield.encounterData.knight, 'Thanks for saving me, ${Player.characters[0].name}!'),
                        () -> sayFromActorAndWait(Battlefield.encounterData.knight, 'I knew you wouldn\'t let me rot in here!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "No problem!"),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Come, let's get you out of there.")
                    ],
                    finish: () -> {
                        Player.addCharacter('Andrew', 'Knight');
                    }
                })
            ]

        },
        {   name: 'Mage Rescue Mission',
            animationName: 'Church',
            level: 1,
            flags: ['RESCUE', 'BLUE_FLAG', 'SPECIAL'],
            waves: [
                makeWave('Church', ['Pe' => 'Peasant', 'Bi' => 'Bishop', 'PG'=>'Patrolling Guard'], [
                    ['TT', 'TT', '  ',  '(X)', '  ', '  ', '[]'],
                    ['  ', 'Pl', '  ',  '  ',  '  ', 'Pe', '  '],
                    ['  ', '  ', '  ',  'TT',  'TT', '  ', 'Bi'],
                    ['[]', 'Pl', '  ',  '  ',  '  ', '  ', '  '],
                    ['  ', '  ', '(X)', '  ',  '  ', 'PG', '  ']
                ], {
                    begin: function() {
                        for (unit in Battlefield.getAllAliveEnemyUnits()) {
                            unit.flipHorizontally();
                        }
                        final mageX = Battlefield.getTile(2, 6).getX() + 15;
                        final mageY = Battlefield.getTile(2, 6).getY() - 50;

                        var mage = U.createActor('UnitActor', 'BehindUnits', mageX, mageY);
                        mage.setAnimation('Mage');
                        U.flipActorHorizontally(mage);
                        var snare = U.createActor('TrapActor', 'BehindUnits', mageX + 34, mageY + 31);
                        snare.setAnimation('Snare');
                        Battlefield.encounterData = { mage: mage };
                    },
                    start: [
                        () -> {
                            final mage: Actor = Battlefield.encounterData.mage;
                            sayFromActorAndWait(mage, 'Let go of me, you filthy rednecks!!!');
                        },
                        () -> sayFromActorAndWait(Battlefield.encounterData.mage, 'Just wait until you hear from my lawyer...'),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Bishop'), "Let's begin the sermon."),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Bishop'), "Ehem..."),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Bishop'), "In nomine Pater."),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Bishop'), "Amen!"),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Patrolling Guard'), "That was so good!"),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Patrolling Guard'), "Congratulations, father."),
                        () -> sayFromUnitAndWait(getRandomUnitWithName('Peasant'), "Burn the witch!!!"),
                        () -> {
                            for (unit in Battlefield.getAllAliveEnemyUnits()) {
                                unit.flipHorizontally();
                            }
                            sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Not while I'm here!");
                        }
                    ],
                    end: [
                        () -> sayFromActorAndWait(Battlefield.encounterData.mage, 'Finally!'),
                        () -> sayFromActorAndWait(Battlefield.encounterData.mage, 'What took you so long!?'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "You know... rednecks."),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Come, let's go."),
                    ],
                    finish: () -> {
                        Game.setAchievement('IS_MAGE_UNLOCKED');
                        Player.progression.isMageUnlocked = true;
                        Player.addCharacter('Zaina', 'Mage');
                    }
                })
            ]
        },
        {   name: "Ranger Rescue Mission",
            animationName: 'Forest',
            level: 1,
            description: "Two adventurers need your help and you must hurry! Unfortunately, you can only save one. Do you chose to save the Ranger?",
            flags: ['RESCUE', 'GREEN_FLAG', 'SPECIAL'],
            waves: [
                {
                    background: "Forest",
                    shorthands: ['SM' => 'Serfmaster'],
                    board: [
                        ['==', '==', '[]', '  ', '  ', '  ', '[]'],
                        ['  ', '  ', '  ', '  ', '  ', 'SM', '  '],
                        ['  ', 'Pl', '[]', '  ', '  ', '  ', '  '],
                        ['  ', '  ', '  ', '[]', '  ', '  ', '->'],
                        ['[]', '  ', '  ', '  ', '  ', '  ', '  ']
                    ],
                    events: {
                        begin: () -> {
                            var serfmasterActor = getRandomEnemyUnit().actor;
                            final rangerX = Battlefield.getTile(2, 6).getX() + 15;
                            final rangerY = Battlefield.getTile(2, 6).getY() - 47;
                            var ranger = U.createActor('UnitActor', 'BehindUnits', rangerX, rangerY);
                            ranger.setAnimation('Ranger');
                            U.flipActorHorizontally(ranger);
                            var snare = U.createActor('TrapActor', 'BehindUnits', rangerX + 29, rangerY + 28);
                            snare.setAnimation('Snare');
                            U.flipActorHorizontally(getRandomEnemyUnit().actor);
                            Battlefield.encounterData = { ranger: ranger };
                        },
                        start: [
                            () -> {
                                sayFromUnitAndWait(getRandomEnemyUnit(), "I'll cut off those ears of yours, elf.");
                            },
                            () -> sayFromUnitAndWait(getRandomEnemyUnit(), "Make myself a lucky charm... hehehe..."),
                            () -> sayFromActorAndWait(Battlefield.encounterData.ranger, 'Not very smart, are you?'),
                            () -> sayFromActorAndWait(Battlefield.encounterData.ranger, 'Look behind, chief.'),
                            () -> {
                                U.unflipActorHorizontally(getRandomEnemyUnit().actor);
                                sayFromUnitAndWait(getRandomEnemyUnit(), "Huh?");
                            },
                            () -> sayFromUnitAndWait(getRandomEnemyUnit(), "Who's disturbing MY play time?!"),
                            () -> sayFromUnitAndWait(getRandomEnemyUnit(), "Get'em, boys!"),
                            () -> {
                                Battlefield.spawnEnemyFromOutOfScreen('Little Scout', 0, 5);
                                Battlefield.spawnEnemyFromOutOfScreen('Little Scout', 4, 5);
                                var scout = Battlefield.spawnEnemyFromOutOfScreen('Little Scout', 2, 5);
                                sayFromUnitAndWait(scout, 'Sir, yes, sir!');
                            }
                        ],
                        end: [
                            () -> sayFromActorAndWait(Battlefield.encounterData.ranger, 'It all went just as planned.'),
                            () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "You're lucky I was on time."),
                            () -> sayFromActorAndWait(Battlefield.encounterData.ranger, 'Yeah, yeah.'),
                            () -> sayFromActorAndWait(Battlefield.encounterData.ranger, 'Just get me out of here and let\'s go.'),
                        ],
                        finish: () -> {
                            Game.setAchievement('IS_RANGER_UNLOCKED');
                            Player.progression.isRangerUnlocked = true;
                            Player.addCharacter('Rook', 'Ranger');
                        }
                    }
                }
            ]
        },
        

        // Level 0 Encounters
        {   name: 'Found You',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 0,
            waves: [
                makeWave('Forest', ['Ps' => 'Peasant', 'LS' => 'Little Scout'], [
                    ['  ', '  ', '  ', '@@', '  ', '  ', '  '],
                    ['WW', '  ', '  ', '  ', '  ', 'LS', '  '],
                    ['  ', 'Pl', '  ', 'WW', '  ', '  ', '  '],
                    ['  ', 'Pl', 'WW', '  ', '  ', 'Ps', '@@'],
                    ['@@', '  ', '  ', '  ', '  ', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Hey! I know you!')
                    ]
                })
            ]
        },
        {   name: 'Likkl Scouts',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 0,
            waves: [
                makeWave('Forest', ['Ps' => 'Peasant', 'LS' => 'Little Scout'], [
                    ['  ', 'WW', '  ', '  ', '  ', '  ', 'WW'],
                    ['LS', '  ', '  ', 'WW', '  ', 'LS', '  '],
                    ['  ', '  ', '  ', 'Pl', '  ', '  ', '  '],
                    ['  ', '  ', '  ', 'Pl', 'WW', '  ', '  '],
                    ['WW', 'LS', '  ', '  ', '  ', 'WW', 'LS']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Ok, boys!'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Just like we practiced!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "You practiced for killing me?"),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Oh, you have no idea...'),
                    ]
                })
            ]
        },
        {   name: 'Pumplingses',
            animationName: 'Fields',
            flags: ['TOWN'],
            level: 0,
            waves: [
                makeWave('Fields', ['Pu' => 'Pumpling'], [
                    ['88', '  ', '  ', '/@',  'Pu', '  ', '  '],
                    ['->', '  ', '  ', '  ',  '  ', '  ', '/@'],
                    ['  ', 'Pl', '  ', '[$]', '  ', '  ', '  '],
                    ['  ', '  ', '  ', 'WW',  '  ', '  ', 'Pu'],
                    ['->', '88', '/@', 'Pu',  '/@', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Hey there, little guys!'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Crrr!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Wow, that was really rude!')
                    ]
                })
            ]
        },
        {   name: 'Paprikases',
            animationName: 'Fields',
            flags: ['TOWN'],
            level: 0,
            waves: [
                makeWave('Fields', ['LS' => 'Little Scout', 'EP' => 'Evil Paprika'], [
                    ['/@', '/@', '  ', '/@', '  ', '  ',  'EP'],
                    ['  ', '  ', '  ', '  ', '  ', '  ',  '/@'],
                    ['  ', 'Pl', '88', '  ', '  ', '  ',  'LS'],
                    ['/@', 'Pl', '  ', '  ', '  ', '[$]', '  '],
                    ['  ', '/@', '  ', '  ', '  ', '  ',  '  ']
                ])
            ]
        },
        {   name: 'Guards and Roses',
            animationName: 'Road',
            flags: ['TOWN'],
            level: 0,
            waves: [
                makeWave('Road', ['PG' => 'Patrolling Guard', 'MP' => 'Molotov Peasant'], [
                    ['WW', 'R1', '&&', '  ', '&&', '&&', 'Pe'],
                    ['  ', '  ', '  ', 'WW', 'R1', 'MP', '  '],
                    ['  ', 'Pl', '&&', '&&', '&&', '  ', '  '],
                    ['  ', 'Pl', '  ', 'WW', '  ', '[]', '  '],
                    ['R1', '  ', '&&', '[]', '&&', '&&', 'PG']
                ])
            ]
        },
        {   name: 'Highway Myway',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 0,
            waves: [
                makeWave('House', [], [
                    ['  ', '(_)', '  ', '  ', '(_)', '  ', '(_)'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['(X)', '  ', '  ', '(X)', '  ', 'Pe', 'HW'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '(_)', '  ', '  ', '(_)', '  ', '(_)']
                ])
            ]
        },
        {   name: 'Pumpguards',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 0,
            waves: [
                makeWave('Forest', ['PG' => 'Patrolling Guard'], [
                    ['88', '@@', '  ', '@@', '  ', 'Pu', '  '],
                    ['  ', 'Pl', '  ', '  ', 'PG', '  ', '@@'],
                    ['WW', '  ', '88', '  ', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', 'PG', '  '],
                    ['  ', '88', '  ', '@@', '88', '  ', 'Pu']
                ])
            ]
        },

       

        // Level 1 Encounters
        {   name: 'There They Are Sir',       // Peasant + Xg
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Forest', ['Ps' => 'Peasant', 'Xg' => 'Crossbow Guard'], [
                    ['R1', '  ', '  ', 'R2', 'R2', '  ', '@@'],
                    ['Pl', '  ', '  ', '  ', '  ', 'Ps', '  '],
                    ['  ', '  ', 'R1', '  ', '  ', '  ', '  '],
                    ['Pl', '  ', '  ', '  ', 'Xg', '  ', '  '],
                    ['  ', '@@', '  ', '  ', '  ', '  ', 'R1']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Peasant'), 'There they is, sir, the murderer!'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Crossbow Guard'), 'I\'ll handle this...')
                    ]
                })
            ]
        },
        {   name: 'There They Are Sir 2',     // Peasant + Xg
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Forest', ['Ps' => 'Peasant', 'Xg' => 'Crossbow Guard'], [
                    ['->', '  ', 'R2', 'R2', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Ps'],
                    ['  ', '  ', 'R1', '  ', '@@', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Xg'],
                    ['@@', '  ', '@@', '  ', '  ', '  ', 'R1']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Peasant'), 'Look!'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Peasant'), "It's a bird!"),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Peasant'), "Wait, no... it's a plane!"),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Crossbow Guard'), "No, wait! It's the murderer!!"),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Crossbow Guard'), "Get 'em!!"),
                    ]
                })
            ]
        },
        {   name: 'Hehe Sneaky Sneaky!',
            animationName: 'House',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('House', ['Xg' => 'Crossbow Guard'], [
                    ['  ', '  ', '  ', '[$]',  '  ',  '  ',  '[]'],
                    ['Pl', '  ', '[]', '  ',   '[]',  '  ',  'Xg'],
                    ['  ', '  ', '  ', '^^',   '(X)', '  ',  '(X)'],
                    ['Pl', '^^', '  ', '(X)',  '  ',  '(X)', '  '],
                    ['  ', '  ', 'TT', 'TT',   'Xg',  '  ',  '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Crossbow Guard'), 'I sure hope no one will sneak on us.')
                    ]
                })
            ]
        },
        {   name: "Forks and Candles",      // Peasant + Bishop
            description: "There are strange chants coming from the graveyard...",
            animationName: 'Church',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Church', ['Ps' => 'Peasant', 'Bi' => 'Bishop'], [
                    ['@@', '@@', '  ', '@@',  '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', 'WW',  '  ', '@@', '  '],
                    ['  ', '  ', '@@', '[$]', '  ', 'Ps', 'Bi'],
                    ['  ', 'Pl', '  ', 'WW',  '  ', '@@', '  '],
                    ['@@', '@@', '  ', '@@',  '  ', '  ', 'MP']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Peasant'), 'Forgive me Father, for I have sinned...'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Peasant'), 'AND I WILL KEEP ON SINNING!!'),
                    ]
                })
            ]
        },
        {   name: "Forks and Candles 2",      // Peasant + Bishop
            description: "There are strange chants coming from the graveyard...",
            animationName: 'Church',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Church', ['Ps' => 'Peasant', 'Bi' => 'Bishop'], [
                    ['TT', 'TT', '  ', '  ', '  ', 'TT', 'TT'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'Pe', '  '],
                    ['  ', 'TT', 'TT', '  ', 'TT', 'TT', 'Bi'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['TT', 'TT', '  ', '  ', '  ', 'TT', 'TT']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Peasant'), 'My sins are grave, father...'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Peasant'), "BUT I'LL MAKE THEM GRAVER!!!"),
                    ]
                })
            ]
        },
        {   name: 'Molotov Cocktails',      // Peasant + Molly      |   2 Molly
            animationName: 'Fields',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Fields', ['Ps' => 'Peasant', 'MP' => 'Molotov Peasant'], [
                    ['[]', '&&', '(_)', '  ', '@@',  '  ', '  '],
                    ['&&', 'Pl', '  ',  '@@', '  ',  '@@', 'MP'],
                    ['@@', '  ', '&&',  '  ', '&&',  'Ps', '  '],
                    ['  ', 'Pl', '  ',  '  ', '(_)', '&&', '  '],
                    ['@@', 'TT', 'TT',  '&&', '  ',  '@@', '[]']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Molotov Peasant'), 'Make it bu\'n them!')
                    ]
                })
            ]
        },
        {   name: 'Molotov Cocktails 2',      // Peasant + Molly      |   2 Molly
            animationName: 'Fields',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Fields', ['Ps' => 'Peasant', 'MP' => 'Molotov Peasant'], [
                    ['88', '  ', '88', '  ', '&&', '  ', '88'],
                    ['&&', 'Pl', '  ', '  ', '  ', 'Pe', '  '],
                    ['88', '  ', '  ', '&&', '  ', '88', '&&'],
                    ['  ', 'Pl', '&&', '  ', '  ', '  ', 'MP'],
                    ['88', '  ', '  ', '88', '  ', '&&', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Molotov Peasant'), 'We a blaze de fyah...')
                    ]
                })
            ]
        },
        {   name: 'Serfmaster and Molly',
            animationName: 'Road',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Road', ['Pe' => 'Peasant', 'MP' => 'Molotov Peasant'], [
                    ['  ', '->', '  ', '  ', '  ', '->', '  '],
                    ['Pl', '&&', '&&', '&&', '&&', '  ', 'MP'],
                    ['  ', '&&', 'TT', 'TT', '&&', '  ', '  '],
                    ['Pl', '&&', '&&', '&&', '&&', 'Pe', '  '],
                    ['->', '  ', '  ', '  ', '  ', '  ', '  ']
                ])
            ]
        },
        {   name: 'Stupid Pumpkins',
            animationName: 'Fields',
            description: 'The powerful magic of Marceline seems to have brought not only the dead, but also plants to life. Purge them!',
            level: 1,
            waves: [
                makeWave('Fields', ['Pu' => 'Pumpling', 'Ps' => 'Peasant'], [
                    ['/@', '  ', '  ', '  ', '/@', '  ', '88'],
                    ['  ', '  ', '/@', 'Pu', '  ', '88', '  '],
                    ['Pl', '  ', '  ', '  ', '  ', '  ', '/@'],
                    ['Pl', '  ', '  ', 'Ps', 'Pu', '  ', '  '],
                    ['  ', '88', '  ', '/@', '  ', '  ', 'Pu']
                ], {
                    start: [
                        () -> {
                            Battlefield.encounterData = { peasant: getEnemyUnitWithName('Peasant') };
                            U.flipActorHorizontally(Battlefield.encounterData.peasant.actor);
                            sayFromUnitAndWait(Battlefield.encounterData.peasant, 'Stupid pumpkins!');
                        },
                        () -> sayFromUnitAndWait(Battlefield.encounterData.peasant, 'Get off my lawn!!'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Pumpling'), '* Crrr *'),
                        () -> {
                            unturn(Battlefield.encounterData.peasant.actor);
                            sayFromUnitAndWait(Battlefield.encounterData.peasant, 'What the...?');
                        }
                    ]
                })
            ]
        },
        {   name: 'WTH Is A Paprika',
            animationName: 'Fields',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Fields', ['EP' => 'Evil Paprika', 'Ps' => 'Peasant'], [
                    ['/@', '  ', '88', '  ', '  ', '  ', '/@'],
                    ['Pl', '  ', '  ', '  ', '/@', 'Ps', '  '],
                    ['  ', '88', '  ', '  ', '  ', '  ', '[]'],
                    ['Pl', '  ', '  ', '  ', 'EP', '/@', '  '],
                    ['  ', '  ', '  ', '88', '  ', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "What the hell is that!?"),
                        () -> {
                            Battlefield.encounterData = { peasant: getEnemyUnitWithName('Peasant') };
                            sayFromUnitAndWait(Battlefield.encounterData.peasant, "My paprika! What did you do!?");
                        },
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "What? I didn't do anything!")
                    ]
                })
            ]
        },
        {   name: 'Paprikario',
            animationName: 'Fields',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Fields', ['EP' => 'Evil Paprika', 'Ps' => 'Peasant'], [
                    ['  ', '88', '  ', '88', '  ', '88', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', 'EP', '  '],
                    ['88', '  ', '88', '  ', '88', '  ', '88'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'EP', '  '],
                    ['  ', '88', '  ', '88', '  ', '88', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Easy there, paprika..."),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "* Grr... *"),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "HEY! Don't talk about my mom like that!"),
                    ]
                })
            ]
        },
        {   name: 'Bad Dog',
            animationName: 'Forest',
            level: 1,
            waves: [
                makeWave('Road', ['Wf' => 'Wolf', 'LS' => 'Little Scout'], [
                    ['->', '  ', '  ', '  ', '  ', '  ', 'R1'],
                    ['  ', 'Pl', 'WW', '  ', '  ', 'Wf', '  '],
                    ['  ', '  ', '==', '==', '  ', '  ', 'LS'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'WW', '  '],
                    ['->', '  ', '  ', '  ', '->', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Little Scout'), 'Get \'em, boy!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'What, are we supposed to fight children now?')
                    ]
                })
            ]
        },
        {   name: 'Jolly Molly',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Forest', [], [
                    ['WW', '&&', '  ', '&&', 'WW', '&&', 'WW'],
                    ['  ', 'Pl', 'WW', '  ', '&&', '  ', 'MP'],
                    ['&&', '  ', 'WW', '  ', 'Pe', 'Pe', '  '],
                    ['  ', 'Pl', 'WW', '&&', '  ', '  ', 'MP'],
                    ['WW', '  ', '&&', '  ', 'WW', '&&', 'WW']
                ])
            ]
        },
        {   name: 'Jolly Molly 2',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 1,
            waves: [
                makeWave('Forest', [], [
                    ['^^', '&&', '  ', '^^', '@@', '&&', 'MP'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'Pe', '[]'],
                    ['[]', '  ', '@@', '[]', '&&', '  ', '[$]'],
                    ['&&', 'Pl', '  ', '  ', '  ', 'Pe', '[]'],
                    ['^^', '  ', '&&', '^^', '@@', '&&', 'MP']
                ])
            ]
        },

        // Level 2 Encounters
        {   name: 'Wolves at Our Heels',
            animationName: 'Forest',
            level: 2,
            waves: [
                makeWave('Forest', ['Wf' => 'Wolf'], [
                    ['  ', 'R1', '  ', 'Wf', '  ', '  ', 'R1'],
                    ['Pl', '  ', 'WW', '  ', '  ', 'Wf', '  '],
                    ['  ', '  ', '==', '==', '  ', '  ', '  '],
                    ['Pl', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['R1', '  ', '  ', '  ', 'R1', 'Wf', 'Wf']
                ])
            ]
        },
        {   name: 'Wolves at Our Heels 2',
            animationName: 'Forest',
            level: 2,
            waves: [
                makeWave('Forest', ['Wf' => 'Wolf'], [
                    ['  ', '->', '  ', '  ', '  ', '->', '  '],
                    ['Wf', '  ', '  ', 'Pl', '  ', '  ', 'Wf'],
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['Wf', '  ', '  ', 'Pl', '  ', '  ', 'Wf'],
                    ['  ', '->', '  ', '  ', '  ', '->', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Purrr...')
                    ]
                })
            ]
        },
        {   name: 'Road Blockade',
            description: 'The road is blocked by 5 guards! This should be a quick fight, but it could also be deadly...',
            animationName: 'Road',
            level: 2,
            waves: [
                makeWave('Road', ['Xg' => 'Crossbow Guard'], [
                    ['->', '  ', '  ', '@@', '  ', '  ', 'Xg'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Xg'],
                    ['  ', '  ', '[]', '  ', '  ', '  ', 'Xg'],
                    ['  ', 'Pl', '  ', '  ', '[]', '  ', 'Xg'],
                    ['->', '  ', '  ', '  ', '  ', '  ', 'Xg']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Halt!'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'In the name of Father Almund, you are sentenced to death!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Father Almund? Who is that?'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Father Almund is the head of our church, of course!'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Bishop of Bishops...'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Master of Candles...'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Bringer of Light...'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Amen!')
                    ]
                })
            ]
        },
        {   name: 'Heh. Trap',
            animationName: 'Forest',
            level: 2,
            waves: [
                makeWave('Forest', ['BP' => 'Bandit Peasant', 'HW' => 'Highwayman'], [
                    ['@@', '  ', '  ', 'Pl', '  ', '  ', '@@'],
                    ['HW', '  ', '  ', '  ', '  ', '  ', 'BP'],
                    ['  ', '  ', '==', '==', '==', '==', '  '],
                    ['BP', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['WW', '  ', '  ', 'Pl', '  ', '  ', 'HW']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Heh. You walked right into our ambush.'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'We know.'),
                    ]
                })
            ]
        },
        {   name: 'Heh. Trap 2',
            animationName: 'Forest',
            level: 2,
            waves: [
                makeWave('Forest', ['BP' => 'Bandit Peasant', 'HW' => 'Highwayman'], [
                    ['[]', '  ', '(X)', '@@', '  ', '[]', 'HW'],
                    ['  ', '  ', '  ',  'Pl', '  ', '  ', '  '],
                    ['  ', 'BP', '  ',  '  ', '[]', '  ', '  '],
                    ['HW', '  ', '  ',  'Pl', '  ', '  ', 'BP'],
                    ['  ', '@@', '  ',  '  ', '[]', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Heh...'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Heh heh heh...')
                    ]
                })
            ]
        },
        {   name: 'Call of Duty',
            animationName: 'House',
            level: 2,
            waves: [
                makeWave('House', ['Gu' => 'Guard', 'HW' => 'Highwayman'], [
                    ['/@', '  ', '()',  '  ', '  ',  'Pe', '  '],
                    ['Pl', '  ', '  ',  '  ', '()',  '  ', 'HW'],
                    ['  ', '->', '  ',  '  ', '  ',  '  ', '  '],
                    ['Pl', '  ', '()',  '  ', '  ',  '  ', '  '],
                    ['  ', '  ', '  ',  '  ', 'Gu',  '  ', '/@']
                ])
            ]
        },
        {   name: 'Call of Duty 2',
            animationName: 'House',
            level: 2,
            waves: [
                makeWave('House', ['Gu' => 'Guard', 'HW' => 'Highwayman'], [
                    ['->', '  ', '  ', '@@', '  ', 'Gu', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'WW'],
                    ['  ', '  ', '[]', 'HW', '  ', '@@', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['->', 'WW', '  ', '  ', '@@', '  ', 'Pe']
                ])
            ]
        },
        {   name: 'Hungry Dead',
            animationName: 'Fields',
            level: 2,
            waves: [
                makeWave('Fields', ['EP' => 'Evil Paprika'], [
                    ['()', '  ', '  ', 'EP', '  ', '88',  '  '],
                    ['Pl', '()', '  ', '  ', '  ', '  ',  '  '],
                    ['  ', '  ', '~~', '  ', '()', '~~',  'EP'],
                    ['Pl', '  ', '  ', '  ', '~~', '  ',  '  '],
                    ['  ', '88', '  ', 'EP', '  ', '[$]', '  ']
                ])
            ]
        },
        {   name: 'Hungry Dead 2',
            animationName: 'Fields',
            level: 2,
            waves: [
                makeWave('Fields', ['EP' => 'Evil Paprika'], [
                    ['  ', 'EP', '  ', '  ', '88', 'EP', '  '],
                    ['  ', '  ', '  ', 'Pl', '  ', '  ', '  '],
                    ['  ', '88', '  ', '  ', '  ', '88', '  '],
                    ['  ', '  ', '  ', 'Pl', '  ', '  ', '  '],
                    ['EP', '  ', '  ', '  ', '88', '  ', 'EP']
                ])
            ]
        },
        {   name: 'Peasant Paprikas',
            animationName: 'Fields',
            level: 2,
            waves: [
                makeWave('Fields', ['EP' => 'Evil Paprika', 'Pe' => 'Peasant'], [
                    ['88', '  ', '  ', 'EP', '  ', 'Pe',  '88'],
                    ['WW', 'Pl', '  ', 'WW', '  ', '  ',  '  '],
                    ['  ', '88', '  ', '  ', 'Pe', '/@',  '  '],
                    ['WW', 'Pl', '  ', 'WW', '  ', '  ',  'EP'],
                    ['88', '  ', '  ', '/@', '  ', '  ',  '88']
                ])
            ]
        },
        {   name: 'Peasant Paprikas 2',
            animationName: 'Fields',
            level: 2,
            waves: [
                makeWave('Fields', ['EP' => 'Evil Paprika', 'Pe' => 'Peasant'], [
                    ['88', '  ', '^^', '  ', '^^', '  ', '88'],
                    ['  ', 'Pl', '  ', '88', '  ', 'Pe', '  '],
                    ['  ', '  ', '88', 'EP', '88', '  ', 'EP'],
                    ['  ', 'Pl', '  ', '88', '  ', 'Pe', '  '],
                    ['88', '  ', '^^', '  ', '^^', '  ', '88']
                ])
            ]
        },
        {   name: 'Rats, Everywhere',
            animationName: 'House',
            level: 2,
            waves: [
                makeWave('House', ['Ra' => 'Rat'], [
                    ['  ', '()', '  ', '()',  'Ra', '  ', '[]'],
                    ['Pl', '  ', '  ', '  ',  '  ', '  ', '  '],
                    ['()', '  ', '()', '  ',  '  ', '  ', 'Ra'],
                    ['Pl', '  ', '  ', 'Ra',  '  ', '()', '  '],
                    ['  ', '()', '  ', '  ',  '  ', '  ', '  ']
                ])
            ]
        },
        {   name: 'Help Me 1',
            animationName: 'Road',
            flags: ['GOBLIN'],
            level: 2,
            waves: [
                makeWave('Road', ['Go' => 'Goblin', 'HW' => 'Highwayman', 'Gu' => 'Guard'], [
                    ['  ', '  ', '[]', 'Gu', '  ', '  ', 'HW'],
                    ['@@', 'Pl', '  ', '  ', '  ', '==', '=='],
                    ['  ', '[]', '  ', '  ', '  ', '  ', '  '],
                    ['@@', 'Pl', '  ', '  ', '[]', 'Go', 'Gu'],
                    ['  ', '  ', '[]', 'HW', '  ', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Aaaa! Save me!!')
                    ]
                })
            ]
        },
        {   name: 'Help Me 2',
            testDamageTaken: () -> randomIntBetween(5, 7),
            animationName: 'Forest',
            flags: ['GOBLIN'],
            level: 2,
            waves: [
                makeWave('Forest', ['Go' => 'Goblin', 'HW' => 'Highwayman', 'Gu' => 'Guard', 'Wo' => 'Wolf', 'Pe' => 'Peasant'], [
                    ['@@', '  ', '  ', 'Pe', '  ', 'Wo', '@@'],
                    ['  ', 'Pl', '@@', '  ', '  ', '  ', '@@'],
                    ['WW', '  ', '^^', '  ', 'Go', 'WW', '  '],
                    ['  ', 'Pl', '@@', '  ', '@@', '  ', 'Wo'],
                    ['@@', '  ', '  ', '  ', '  ', 'Wo', '@@']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'HELP!!! They\'re trying to kill me!')
                    ]
                })
            ]
        },
        {   name: 'Help Me 3',
            animationName: 'Road',
            flags: ['GOBLIN'],
            level: 2,
            waves: [
                makeWave('Road', ['Go' => 'Goblin', 'HW' => 'Highwayman', 'Gu' => 'Guard', 'Wo' => 'Wolf', 'Pe' => 'Peasant', 'MP' => 'Molotov Peasant', 'LS' => 'Little Scout'], [
                    ['(_)', '  ', '  ', '[]', '&&', 'LS', '[]'],
                    ['&&',  'Pl', '&&', '  ', '  ', '&&', 'MP'],
                    ['TT',  'TT', 'Pe', '[]', '  ', 'Go', '  '],
                    ['  ',  'Pl', '  ', '  ', '&&', '  ', 'MP'],
                    ['(_)', '  ', '&&', '[]', '  ', 'LS', '[]']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Help! Do not let them get to me!')
                    ]
                })
            ]
        },
        {   name: 'Xplodium',
            animationName: 'House',
            flags: ['EXPLODING_CRYSTAL'],
            level: 2,
            waves: [
                makeWave('House', ['PG' => 'Patrolling Guard', 'XC' => 'Exploding Crystal', 'Gu' => 'Guard', 'Wo' => 'Wolf'], [
                    ['[]', '  ', '^^', 'WW', '  ', '  ', '[]'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Wo'],
                    ['  ', '[]', '  ', '[]', 'XC', '  ', 'PG'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Wo'],
                    ['[]', '  ', '^^', 'WW', '  ', 'HW', '  ']
                ])
            ]
        },
        {   name: 'High Noon',
            animationName: 'Forest',
            level: 2,
            waves: [
                makeWave('Forest', ['HW' => 'Highwayman', 'SM' => 'Serfmaster'], [
                    ['  ', '  ', '[]', 'HW', '  ', 'Pe', '->'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['->', '  ', '  ', 'WW', '  ', '[]', 'HW'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '[]', 'HW', '  ', 'Pe', '->']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "It's high noon.")
                    ]
                })
            ]
        },
        {   name: 'High Noon 2',
            animationName: 'Forest',
            level: 2,
            waves: [
                makeWave('Forest', ['HW' => 'Highwayman', 'SM' => 'Serfmaster'], [
                    ['==', '==', '  ', '@@', 'Pe', '[]', 'HW'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '@@', '  '],
                    ['  ', 'Pl', '  ', '  ', 'Pe', '  ', 'HW'],
                    ['@@', '  ', '@@', '  ', '[]', 'HW', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "You know what time it is.")
                    ]
                })
            ]
        },
        {   name: 'Mac',
            animationName: 'Fields',
            level: 2,
            waves: [
                makeWave('Fields', ['Ra' => 'Rat', 'HW' => 'Highwayman'], [
                    ['  ', '  ', '  ', '88', '@@', 'Ra', '  '],
                    ['88', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '88', '  ', '  ', '  ', 'HW'],
                    ['  ', 'Pl', '  ', '  ', '  ', '88', '  '],
                    ['  ', '@@', '  ', '88', '  ', 'Ra', '  ']
                ])
            ]
        },
        {   name: 'Bigsplosions',
            animationName: 'House',
            level: 2,
            waves: [
                makeWave('House', ['Gu' => 'Guard'], [
                    ['(_)', '(X)', '  ', '  ',  '  ', '  ', 'Gu'],
                    ['  ',  'Pl',  '  ', '(X)', '  ', '  ', '(X)'],
                    ['(X)', '  ',  '  ', '  ',  '  ', '[]', 'HW'],
                    ['  ',  'Pl',  '  ', '(X)', '  ', '  ', '(X)'],
                    ['  ',  '(X)', '  ', '  ',  '  ', '  ', 'Gu']
                ])
            ]
        },
        {   name: 'Save Us Boy',
            animationName: 'House',
            level: 2,
            waves: [
                makeWave('House', ['LS' => 'Little Scout', 'Ra' => 'Rat'], [
                    ['TT', 'TT', '  ', '(_)', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ',  '  ', 'Ra', 'LS'],
                    ['  ', '  ', '  ', '  ',  'LS', '  ', 'LS'],
                    ['[]', 'Pl', '  ', 'TT',  'TT', '  ', '  '],
                    ['  ', '/@', '  ', '  ',  '  ', 'LS', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Little Scout'), 'AAAA!!!', 0, -20),
                        () -> sayFromUnitAndWait(getUnitByName('Little Scout'), 'Save us, boy!', 0, -20),
                        () -> sayFromUnitAndWait(getUnitByName('Rat'), 'Purr...')
                    ]
                })
            ]
        },
        {   name: 'Well This Is Awkward',
            animationName: 'House',
            testDamageTaken: () -> 0,
            level: 2,
            waves: [
                makeWave('House', ['LS' => 'Little Scout', 'Bi' => 'Bishop'], [
                    ['  ', '  ', '  ',  '  ', '  ', 'LS', '(_)'],
                    ['  ', 'Pl', '  ',  '  ', '  ', '  ', 'LS'],
                    ['  ', '  ', '(_)', '  ', '  ', 'LS', 'Bi'],
                    ['  ', 'Pl', '  ',  '  ', '  ', '  ', 'LS'],
                    ['TT', 'TT', '  ',  '  ', '(_)', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Bishop'), 'Well, this is awkward...')
                    ]
                })
            ]
        },
        {   name: 'Poor Families',
            animationName: 'House',
            level: 2,
            description: 'Invade this family and take their belongings! Will you do it? You have only today!',
            waves: [
                makeWave('House', ['Ps' => 'Peasant'], [
                    ['  ', '  ', '[]', '[]', '  ', '  ', '  '],
                    ['Pl', '  ', '[]', '  ', '  ', '[]', 'Ps'],
                    ['  ', '  ', 'WW', '  ', '  ', '[]', 'Ps'],
                    ['Pl', '  ', '/@', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '[]', '/@', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Please! Don\'t do this!'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'We are poor! We have nothing of value!'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'At least leave our children alone in the back yard!')
                    ]
                }),
                makeWave('Fields', ['LS' => 'Little Scout'], [
                    ['/@', '  ', '  ', '  ', 'LS', '  ', 'LS'],
                    ['Pl', '/@', '  ', '/@', '  ', 'LS', '/@'],
                    ['WW', '  ', '  ', '  ', '  ', '  ', 'LS'],
                    ['Pl', '/@', '  ', '  ', 'LS', '  ', '  '],
                    ['  ', '  ', '/@', 'LS', '/@', 'LS', 'LS']
                ], {
                    start: [ () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Daddy? Who are these people?') ]
                })
            ]
        },
        {   name: 'Highrock',
            animationName: 'Forest',
            level: 2,
            waves: [
                makeWave('Forest', ['Ps' => 'Peasant', 'Bi' => 'Bishop', 'MP' => 'Molotov Peasant'], [
                    ['&&', '  ', '  ', '  ', '&&', 'Ps', '[$]'],
                    ['  ', 'Pl', '  ', 'R2', 'R2', '  ', '  '],
                    ['->', '  ', '  ', 'R2', 'R2', 'MP', 'MP'],
                    ['  ', 'Pl', '  ', 'R2', 'R2', '  ', '&&'],
                    ['&&', '  ', '&&', '&&', '  ', 'Ps', 'Bi']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Molotov Peasant'), 'There they are! Behind that big rock!'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Bishop'), 'I can\'t see anything!'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Bishop'), 'There\'s a giant rock blocking my view!')
                    ]
                })
            ]
        },
        {   name: 'Highrock 2',
            animationName: 'Forest',
            level: 2,
            waves: [
                makeWave('Forest', ['Ps' => 'Peasant', 'Bi' => 'Bishop', 'MP' => 'Molotov Peasant'], [
                    ['&&', '  ', '&&', '  ', '&&',  'Pe', 'HW'],
                    ['  ', 'Pl', 'B1', 'B1', 'B1',  '  ', '  '],
                    ['&&', '  ', 'B1', '[$]', 'B1', 'MP', 'Bi'],
                    ['&&', 'Pl', 'B1', 'B1', 'B1',  '  ', '  '],
                    ['  ', '  ', '&&', '&&', '  ',  'Pe', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Molotov Peasant'), 'You will NEVER find our treasure!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Is it between those rocks?'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Molotov Peasant'), 'How did you know!?'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'We can see the battlefield from above.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Molotov Peasant'), 'What kind of evil magic is that!?'),
                    ]
                })
            ]
        },
        {   name: 'Scary Go Back',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 2,
            waves: [
                makeWave('Beach', ['Bk' => 'Bubak', 'BP' => 'Bandit Peasant'], [
                    ['/@', '  ', '88', '/@', 'Bk', '  ', '  '],
                    ['/@', 'Pl', '  ', '  ', '  ', '  ', 'BP'],
                    ['Bk', '  ', '  ', '  ', '  ', '/@', '/@'],
                    ['/@', 'Pl', '  ', '  ', '  ', '  ', 'BP'],
                    ['/@', '  ', 'Bk', '/@', '88', '  ', '  ']
                ])
            ]
        },
        {   name: 'Buraks',
            animationName: 'House',
            flags: ['TOWN'],
            level: 2,
            waves: [
                makeWave('House', ['Bk' => 'Bubak', 'Ra' => 'Rat'], [
                    ['()', '^^', '  ', '()', 'Ra', '  ', '[]'],
                    ['  ', 'Pl', '  ', '  ', '  ', '^^', '  '],
                    ['()', '  ', 'Bk', '  ', '[]', 'Bk', '[$]'],
                    ['  ', 'Pl', '  ', '  ', '  ', '^^', '  '],
                    ['()', '^^', '  ', '()', 'Ra', '  ', '[]']
                ])
            ]
        },
        {   name: 'Serfpeasants',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 2,
            waves: [
                makeWave('Forest', [], [
                    ['->', '  ', '  ', '^^', 'Pe', '==', '=='],
                    ['  ', 'Pl', '&&', '&&', '  ', '  ', 'MP'],
                    ['  ', '  ', 'WW', '&&', '&&', 'SM', '  '],
                    ['  ', 'Pl', '&&', '&&', '  ', '  ', '  '],
                    ['==', '==', '  ', '^^', '  ', 'Pe', '->']
                ])
            ]
        },
        {   name: 'Serfpeasants 2',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 2,
            waves: [
                makeWave('Forest', [], [
                    ['==', '==', '  ', '  ', '  ', 'Pe', '^^'],
                    ['  ', 'Pl', '  ', '[]', '  ', '  ', '  '],
                    ['  ', '  ', '^^', '  ', 'SM', '  ', 'HW'],
                    ['^^', 'Pl', '  ', '  ', '  ', '^^', '  '],
                    ['  ', '  ', '  ', '^^', '  ', 'Pe', '  ']
                ])
            ]
        },
        {   name: 'Peas',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 2,
            waves: [
                makeWave('Road', [], [
                    ['->', '  ', '  ', 'WW', '  ', '  ', 'Pe'],
                    ['  ', 'Pl', '  ', '  ', 'Pe', '  ', '  '],
                    ['  ', '->', '  ', 'WW', '  ', '  ', '->'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'Pe', '  '],
                    ['->', '  ', '  ', 'WW', '  ', '  ', 'Pe']
                ])
            ]
        },

        // Later unlockable encounters
        {   name: 'Pumpkin Tentacles Unlocked',
            animationName: 'Road',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Road', ['PT' => 'Pumpkin Tentacle', 'Bk' => 'Bubak', 'Gu' => 'Guard'], [
                    ['/@', '  ', '  ', '  ', 'Gu', '/@', '  '],
                    ['  ', 'Pl', 'Bk', '  ', '  ', '  ', 'PT'],
                    ['/@', '  ', '  ', '  ', '  ', '  ', '/@'],
                    ['  ', 'Pl', 'Bk', '  ', '  ', '  ', 'PT'],
                    ['/@', '  ', '  ', '  ', 'Gu', '/@', '  ']
                ])
            ]
        },


        //  [
        //     ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
        //     ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
        //     ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
        //     ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
        //     ['  ', '  ', '  ', '  ', '  ', '  ', '  ']
        // ]
        // , {
        //     start: [
        //         () -> sayFromUnitAndWait(getEnemyUnitWithName('Peasant'), 'There they is, sir, the murderer!'),
        //         () -> sayFromUnitAndWait(getEnemyUnitWithName('Crossbow Guard'), 'I\'ll handle this...')
        //     ]
        // }

        // Level 3 Encounters
        {   name: 'Crewmates',
            animationName: 'Ship',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Ship', [], [
                    ['[]', '  ', '  ', '(_)', '  ',  '  ', 'CM'],
                    ['  ', 'Pl', '^^', '  ',  '^^',  '  ', '  '],
                    ['[]', '  ', 'WW', '^^',  '[$]', '  ', '[]'],
                    ['  ', 'Pl', '^^', '  ',  '^^',  '  ', '  '],
                    ['[]', '  ', '  ', '(_)', '  ',  '  ', 'CM']
                ])
            ]
        },
        {   name: 'Crewmates 2',
            animationName: 'Ship',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Ship', [], [
                    ['CM', '  ',  '^^', '  ',  '^^', '  ',  '(X)'],
                    ['  ', 'WW',  '  ', 'Pl',  '  ', 'WW',  '  '],
                    ['  ', '  ',  '  ', '(X)', '  ', '  ',  '  '],
                    ['  ', 'WW',  '  ', 'Pl',  '  ', 'WW',  '  '],
                    ['(X)', '  ', '^^', '  ',  '^^', '  ', 'CM']
                ])
            ]
        },
        {   name: 'Bubarates',
            animationName: 'Ship',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Ship', ['Bk' => 'Bubak'], [
                    ['==', '  ', 'WW', '  ', 'PP', '  ', 'B1'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Bu'],
                    ['WW', '  ', '  ', 'Bk', '  ', '  ', '  '],
                    ['  ', 'Pl', 'WW', '  ', '  ', 'PP', '  '],
                    ['B1', '  ', '  ', 'WW', '  ', 'B1', 'B1']
                ])
            ]
        },
        {   name: 'Canoneering',
            animationName: 'Ship',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Ship', [], [
                    ['(_)', 'WW', 'WW', '  ', '(_)', '  ', '(_)'],
                    ['  ',  'Pl', '  ', '  ', '  ',  'PP', '  '],
                    ['  ',  '  ', '  ', '  ', '  ',  '  ', 'Ca'],
                    ['  ',  'Pl', '  ', '  ', '  ',  'PP', '  '],
                    ['(_)', 'WW', 'WW', '  ', '(_)', '  ', '(_)']
                ])
            ]
        },
        {   name: 'Big Buck Bucaneers',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', ['CM' => 'Crewmate', 'PB' => 'Pirate Bishop', 'PP' => 'Pirate Peasant', 'Ca' => 'Canon', 'Bu' => 'Bucaneer'], [
                    ['[]', '  ',  '[]', '  ', 'WW', 'Bu', '  '],
                    ['  ', 'Pl',  '  ', '^^', '  ', 'WW', '  '],
                    ['[]', '(_)', '[]', '  ', 'WW', 'Bu', '[$]'],
                    ['  ', 'Pl',  '  ', '^^', '  ', 'WW', '  '],
                    ['[]', '  ',  '[]', '  ', 'WW', 'Bu', '  ']
                ])
            ]
        },     
        {   name: 'One Big Slime',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['~~', '  ', '==', '==', '  ', '  ', '~~'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['~~', '  ', '~~', '  ', '~~', 'BS', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['~~', '  ', '==', '==', '  ', '  ', '~~']
                ])
            ]
        },
        {   name: 'One Big Slime 2',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['  ', '  ', '~~', '  ', '~~', '  ', '  '],
                    ['  ', 'Pl', '~~', '  ', '~~', '  ', '  '],
                    ['~~', '~~', '~~', '~~', '~~', '~~', '~~'],
                    ['  ', 'Pl', '~~', '  ', '~~', '  ', '  '],
                    ['  ', '  ', '~~', '  ', '~~', 'BS', '  ']
                ])
            ]
        },
        {   name: 'Lil Blubbing',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['R1', '  ', 'WW', '  ', 'PP', '  ', 'WW'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', 'WW', '  ', 'Bl', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'PP'],
                    ['WW', 'WW', '  ', '  ', 'WW', '  ', '[$]']
                ])
            ]
        },
        {   name: 'Casual Fish',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['  ', 'R2', 'R2', '[]', '  ', '  ', 'R1'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'RM', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', 'Bl'],
                    ['  ', 'Pl', '  ', '[]', '  ', 'RM', '  '],
                    ['B2', 'B2', '  ', '  ', '  ', '  ', '[]']
                ])
            ]
        },
        {   name: 'Casual Fish 2',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['==', '==', '  ', '~~', '  ', 'RM', '  '],
                    ['  ', 'Pl', '<>', '  ', '<>', '  ', '  '],
                    ['==', '==', '  ', '  ', 'Bl', '==', '=='],
                    ['  ', 'Pl', '<>', '  ', '<>', '  ', '  '],
                    ['==', '==', '  ', '~~', '  ', 'RM', '  ']
                ])
            ]
        },
        {   name: 'Bishmen',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['  ', '  ', '  ', 'WW', '  ', '  ', 'B1'],
                    ['B1', 'Pl', '  ', '  ', '  ', 'RM', '  '],
                    ['R1', '  ', '[]', '[]', '[]', '  ', 'PB'],
                    ['B1', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', 'WW', 'RM', '  ', 'B1']
                ])
            ]
        },
        {   name: 'Mermaid Fish',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['R1', '  ', '  ', '  ', '  ', 'R1', '[$]'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'RM', 'R1'],
                    ['[]', '  ', '  ', '  ', 'Bl', '  ', 'Me'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'RM', '  '],
                    ['  ', '  ', 'R2', 'R2', '  ', '  ', 'R1']
                ])
            ]
        },
        {   name: 'Exploding Bucaneers',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['  ',  '  ', 'WW', '  ',  'WW', '  ', 'Bu'],
                    ['  ',  'Pl', '  ', '(X)', '  ', '  ', '(_)'],
                    ['(_)', '  ', '  ', '  ',  '  ', '  ', 'Bu'],
                    ['  ',  'Pl', '  ', '(X)', '  ', '  ', '(_)'],
                    ['  ',  '  ', 'WW', '  ',  'WW', '  ', 'Bu']
                ])
            ]
        },
        {   name: 'Canon Barrels',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['(X)', '  ', '  ',  '  ', '(X)', '  ', '  '],
                    ['(X)', 'Pl', '(X)', '[]', '  ',  '[]', 'Ca'],
                    ['(X)', '  ', '(X)', '  ', '  ',  '  ', '  '],
                    ['(X)', 'Pl', '(X)', '[]', '  ',  '[]', 'Ca'],
                    ['(X)', '  ', '  ',  '  ', '(X)', '  ', '  ']
                ])
            ]
        },
        {   name: 'Spore Peasants',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['R1', '  ', '  ', '  ', '  ', '  ', 'PP'],
                    ['^^', 'Pl', '  ', 'R1', '  ', '  ', 'PP'],
                    ['R1', '  ', 'WW', '  ', '<>', 'SK', '  '],
                    ['^^', 'Pl', '  ', 'R1', '  ', '  ', '  '],
                    ['R1', '  ', '  ', '  ', '  ', '  ', 'PP']
                ])
            ]
        },
        {   name: 'Spore Big Slime',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['OO', '  ', '  ', '  ', '~~', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'SK'],
                    ['  ', '  ', '  ', 'OO', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', 'BS', '  '],
                    ['OO', '  ', '  ', '  ', '  ', '  ', '  ']
                ])
            ]
        },
        {   name: 'Foggy Slimes',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Forest', [], [
                    ['  ', '  ', '  ', '==', '==', 'Sl', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['OO', '  ', 'Sl', '  ', 'OO', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['==', '==', '  ', '[]', 'Sl', '  ', '  ']
                ])
            ]
        },
        {   name: 'Spormaid',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['  ', '  ', '  ', 'R1', '  ', '  ', '  '],
                    ['~~', 'Pl', '~~', '  ', '  ', 'PP', 'SK'],
                    ['==', '==', '  ', '  ', '  ', '  ', 'R1'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'PP', 'Me'],
                    ['~~', '  ', '  ', '~~', '  ', 'R1', '  ']
                ])
            ]
        },
        {   name: 'Free For All',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['WW', '  ', '  ', 'WW', '  ', '  ', 'PP'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'PP', '  '],
                    ['R1', 'R1', 'R1', 'R1', 'R1', 'R1', 'R1'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'PP', '  '],
                    ['WW', '  ', '  ', 'WW', '  ', '  ', 'PP']
                ])
            ]
        },
        {   name: 'Save Yard',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', ['Bi' => 'Bishop'], [
                    ['+]', '  ', '+]', '  ', '+]', '  ', '+]'],
                    ['  ', 'Pl', '  ', '  ', 'Zo', '  ', '  '],
                    ['->', '  ', '  ', '  ', '  ', 'Zo', 'Bi'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['+]', '  ', '+]', '  ', '+]', 'Zo', '+]']
                ])
            ]
        },
        {   name: 'Beah',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Cave', [], [
                    ['~~', '[]', '~~', '[]', '~~', '  ', '~~'],
                    ['~~', 'Pl', '~~', '  ', '[]', '  ', '~~'],
                    ['~~', '  ', '[]', '  ', '~~', 'Be', '~~'],
                    ['~~', 'Pl', '~~', '  ', '[]', '  ', '~~'],
                    ['~~', '[]', '~~', '[]', '~~', '  ', '~~']
                ])
            ]
        },
        {   name: 'Spore Pirates',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 3,
            waves: [
                makeWave('Beach', [], [
                    ['R1', '  ', '  ', '  ', '  ', 'R1', '  '],
                    ['WW', 'Pl', '  ', 'WW', '  ', 'PP', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', 'SK'],
                    ['  ', 'Pl', '  ', 'WW', 'CM', '  ', '  '],
                    ['->', '  ', '  ', '  ', '  ', 'R1', 'Bu']
                ])
            ]
        },
        {   name: 'Piratoblin 1',
            animationName: 'Beach',
            flags: ['GOBLIN'],
            level: 3,
            waves: [
                makeWave('Beach', ['Go' => 'Goblin'], [
                    ['B1', '  ', '  ', '[]', '  ', '  ', 'Go'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Ca'],
                    ['  ', '  ', '^^', '^^', '^^', '[]', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Ca'],
                    ['B1', '  ', '  ', '[]', '  ', '  ', 'PP']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Oh no! Pirates!!! Help!!')
                    ]
                })
            ]
        },
        {   name: 'Piratoblin 2',
            animationName: 'Beach',
            flags: ['GOBLIN'],
            level: 3,
            waves: [
                makeWave('Beach', ['Go' => 'Goblin'], [
                    ['R1', '  ', '^^', '[]', 'Bu', '  ', 'R1'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Bu'],
                    ['  ', '  ', '^^', '[]', '  ', 'Go', '  '],
                    ['  ', 'Pl', '  ', '^^', '[]', '  ', '  '],
                    ['  ', '  ', 'R1', '  ', '  ', 'Bu', '[$]']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'AAA!!! This was not in my contract!!!')
                    ]
                })
            ]
        },
        {   name: 'Piratoblin 3',
            animationName: 'Beach',
            flags: ['GOBLIN'],
            level: 3,
            waves: [
                makeWave('Beach', ['Go' => 'Goblin'], [
                    ['  ', '  ', '  ', '  ', 'B2', 'B2', '  '],
                    ['PP', '  ', '  ', 'Pl', '  ', '  ', 'PP'],
                    ['  ', 'Bu', 'B1', 'Go', 'B1', '  ', '  '],
                    ['^^', '  ', '  ', 'Pl', '  ', '  ', '^^'],
                    ['  ', 'B2', 'B2', '  ', '  ', '  ', 'CM']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Help! I am small and fragile!')
                    ]
                })
            ]
        },
        {   name: 'Expirates 1',
            animationName: 'Beach',
            flags: ['EXPLODING_CRYSTAL'],
            level: 3,
            waves: [
                makeWave('Beach', ['XC' => 'Exploding Crystal'], [
                    ['R2', 'R2', '^^', '^^', 'R1', '^^', 'PP'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Ca'],
                    ['  ', '  ', 'XC', '  ', '  ', 'PP', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Ca'],
                    ['==', '==', '^^', 'R1', '^^', '^^', '^^']
                ])
            ]
        },
        {   name: 'Expirates 2',
            animationName: 'Road',
            flags: ['EXPLODING_CRYSTAL'],
            level: 3,
            waves: [
                makeWave('Road', [], [
                    ['(_)', '  ', '  ', 'PP', '  ', '  ', '  '],
                    ['  ',  'Pl', '  ', '  ', '[]', '  ', '  '],
                    ['  ',  '  ', '<>', '  ', '  ', 'XC', '[$]'],
                    ['  ',  'Pl', '  ', '  ', '[]', '  ', '  '],
                    ['  ',  '  ', '[]', 'PP', '  ', 'PP', '  ']
                ])
            ]
        },

        

        // Level 4 Encounters
        {   name: 'Average Pirates',
            animationName: 'Ship',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Ship', [], [
                    ['B2', 'B2', '  ', '  ', 'B1', '  ', 'PB'],
                    ['  ', 'Pl', '  ', '  ', 'CM', '  ', '  '],
                    ['R1', '  ', '  ', '  ', '  ', '  ', 'Ca'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'PP', '  '],
                    ['  ', '  ', 'R1', '  ', 'Bu', '  ', 'R1']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Why are there rocks on your ship?'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "This used to be a flying ship."),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "We need them to keep the ship at the water level."),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Oh, of course.')
                    ]
                })
            ]
        },
        {   name: 'Mermaid Army',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Beach', ['CM' => 'Crewmate', 'PB' => 'Pirate Bishop', 'PP' => 'Pirate Peasant', 'Ca' => 'Canon', 'Bu' => 'Bucaneer', 'Me' => 'Mermaid'], [
                    ['[]', '  ', '<>', '  ', '<>', 'PP', '[]'],
                    ['[]', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', 'PP', '<>', 'Me'],
                    ['  ', 'Pl', '<>', '  ', '<>', 'PP', '[]'],
                    ['<>', '[]', '  ', '  ', '  ', '  ', 'PP']
                ])
            ]
        },
        {   name: 'Slime Ambush',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Forest', [], [
                    ['  ', 'SS', '  ', 'SS', '  ', 'SS', '  '],
                    ['SS', '  ', '  ', '  ', '  ', '  ', 'SS'],
                    ['  ', '  ', 'Pl', '  ', 'Pl', '  ', '  '],
                    ['SS', '  ', '  ', '  ', '  ', '  ', 'SS'],
                    ['  ', 'SS', '  ', 'SS', '  ', 'SS', '  ']
                ])
            ]
        },
        {   name: 'Double Big Slime',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Beach', [], [
                    ['~~', '  ', '  ', '  ', '  ', 'BS', '  '],
                    ['  ', 'Pl', '  ', '~~', '  ', '~~', '[]'],
                    ['~~', '  ', '~~', '  ', '~~', '  ', '  '],
                    ['  ', 'Pl', '  ', '~~', '  ', '~~', '[]'],
                    ['~~', '  ', '  ', '  ', '  ', 'BS', '  ']
                ])
            ]
        },
        {   name: 'Triple Fishy',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Beach', [], [
                    ['==', '==', '  ', '  ', '  ', '  ', 'RM'],
                    ['  ', 'Pl', '  ', 'WW', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', 'RM', 'WW', '[$]'],
                    ['  ', 'Pl', 'WW', '  ', '  ', '  ', '  '],
                    ['WW', '  ', '==', '==', '  ', 'RM', '  ']
                ])
            ]
        },
        {   name: 'Blub Blub',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Beach', ['Bl' => 'Blubber', ], [
                    ['B1', '  ', '  ', '  ', '  ', '  ', 'Bl'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'Bl', '  '],
                    ['->', '  ', '  ', 'B1', '  ', 'B1', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', 'Bl', '  '],
                    ['B1', '  ', '  ', '  ', '  ', '  ', 'Bl']
                ])
            ]
        },
        {   name: 'More Spore Pirates',
            animationName: 'Ship',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Ship', [], [
                    ['->', '  ', '  ', '  ', '  ', '  ', 'Bu'],
                    ['  ', 'Pl', '  ', '^^', 'CM', '  ', '->'],
                    ['  ', '  ', '  ', '^^', '  ', '  ', 'SK'],
                    ['  ', 'Pl', '  ', '^^', 'PP', '  ', '->'],
                    ['->', '  ', '  ', '  ', '  ', '  ', 'Bu']
                ])
            ]
        },
        {   name: 'Slime Army',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Forest', [], [
                    ['[]', '  ', 'Sl', '  ', '  ', '  ', 'Sl'],
                    ['  ', '  ', '  ', 'Pl', 'Sl', '  ', '  '],
                    ['Sl', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', 'Pl', '  ', '  ', '[]'],
                    ['  ', 'Sl', 'R1', '  ', '  ', 'Sl', '[]']
                ])
            ]
        },
        {   name: 'Crewmates Plus',
            animationName: 'Ship',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Ship', [], [
                    ['TT', 'TT', '  ', '  ', 'CM', '  ', '  '],
                    ['  ', 'Pl', 'WW', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', 'R1', '  ', '[]', 'PB'],
                    ['  ', 'Pl', 'WW', '  ', '  ', '  ', '  '],
                    ['WW', 'R1', '  ', '  ', 'CM', '  ', 'WW']
                ])
            ]
        },
        {   name: 'Double Canons',
            animationName: 'Ship',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Ship', ['CM' => 'Crewmate', 'PB' => 'Pirate Bishop', 'PP' => 'Pirate Peasant', 'Ca' => 'Canon', 'Bu' => 'Bucaneer'], [
                    ['WW', 'R1', '  ', '  ', '  ', '  ', 'Ca'],
                    ['  ', 'Pl', '  ', '  ', 'PP', '  ', '  '],
                    ['^^', '  ', '  ', '()', '  ', '  ', 'PP'],
                    ['  ', 'Pl', '  ', '  ', 'PP', '  ', '  '],
                    ['R1', '  ', '  ', '  ', '  ', '  ', 'Ca']
                ])
            ]
        },
        {   name: 'Triple Canons',
            animationName: 'Ship',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Ship', ['CM' => 'Crewmate', 'PB' => 'Pirate Bishop', 'PP' => 'Pirate Peasant', 'Ca' => 'Canon', 'Bu' => 'Bucaneer'], [
                    ['R1', '  ', '[]', '  ', '  ', '  ', 'Ca'],
                    ['  ', 'Pl', '  ', '  ', '[]', 'Bu', '  '],
                    ['@@', '  ', '  ', '<>', '  ', '  ', 'Ca'],
                    ['  ', 'Pl', '  ', '  ', '[]', 'Bu', '  '],
                    ['R1', 'B1', '  ', '  ', '[]', '  ', 'Ca']
                ])
            ]
        },
        {   name: 'Slimy Bishops',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Forest', [], [
                    ['~~', '  ', '  ', '~~', '[]', '  ', 'PB'],
                    ['  ', 'Pl', '  ', '  ', '  ', '~~', '  '],
                    ['  ', '  ', '~~', '  ', 'BS', '  ', '~~'],
                    ['  ', 'Pl', '  ', '  ', '  ', '~~', '  '],
                    ['~~', '  ', '  ', '~~', '[]', '  ', 'PB']
                ])
            ]
        },
        {   name: 'Bleasants',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Beach', ['Bl' => 'Blubber'], [
                    ['B1', '  ', '  ', '  ', 'R1', '  ', 'PP'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'WW', 'Bl'],
                    ['[]', '  ', '  ', '  ', '  ', '  ', 'PP'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'WW', 'Bl'],
                    ['R1', '  ', '  ', 'TT', '  ', '  ', 'PP']
                ])
            ]
        },
        {   name: 'Big Bishes',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Beach', [], [
                    ['<>', '<>', '  ', 'WW', '  ', '  ', 'PB'],
                    ['<>', 'Pl', '  ', '  ', '<>', '  ', 'WW'],
                    ['<>', '  ', 'WW', '  ', '  ', 'RM', 'PB'],
                    ['<>', 'Pl', '  ', '  ', '<>', '  ', 'WW'],
                    ['<>', '<>', '  ', 'WW', '  ', '  ', 'PB']
                ])
            ]
        },
        {   name: 'Slimy Bucaneer',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Beach', [], [
                    ['  ', '  ', '  ', '  ', '  ', '  ', 'Bu'],
                    ['[]', 'Pl', '  ', '[]', '  ', '  ', '[]'],
                    ['[]', '  ', 'WW', '[]', 'BS', '  ', '[]'],
                    ['[]', 'Pl', '  ', '[]', '  ', '  ', '[]'],
                    ['  ', '  ', '  ', '  ', '  ', '  ', 'Bu']
                ])
            ]
        },
        {   name: 'Spore Mates',
            animationName: 'Beach',
            flags: ['TOWN'],
            level: 4,
            waves: [
                makeWave('Beach', [], [
                    ['[]', '  ', '  ', '  ', '(X)', 'CM', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ',  '  ', '[]'],
                    ['->', '  ', '  ', '->', '  ',  '[]', 'SK'],
                    ['  ', 'Pl', '  ', '  ', 'WW',  '  ', '[]'],
                    ['[]', '  ', '^^', '  ', '  ',  'CM', '  ']
                ])
            ]
        },
        {   name: 'Bigoblin 1',
            animationName: 'Road',
            flags: ['GOBLIN'],
            level: 4,
            waves: [
                makeWave('Road', [], [
                    ['WW', '^^', 'WW', 'WW', '  ', '  ', 'CM'],
                    ['WW', 'Pl', '  ', '  ', '  ', 'WW', '  '],
                    ['WW', '  ', 'Go', '  ', 'CM', 'WW', '  '],
                    ['WW', 'Pl', '  ', '  ', '  ', 'WW', '  '],
                    ['WW', '^^', 'WW', 'WW', '  ', 'CM', 'WW']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Leave me alone, you ugly pirates!')
                    ]
                })
            ]
        },
        {   name: 'Bigoblin 2',
            animationName: 'Ship',
            flags: ['GOBLIN'],
            level: 4,
            waves: [
                makeWave('Ship', [], [
                    ['R1', '  ', '  ', '  ', '^^', 'Bl', 'R1'],
                    ['  ', 'Pl', '  ', '<>', '  ', '  ', 'Bl'],
                    ['R1', '->', '  ', '  ', 'Go', '(_)', '  '],
                    ['  ', 'Pl', '  ', '<>', '  ', '  ', 'Bl'],
                    ['R1', '  ', '  ', '  ', '^^', 'Bl', 'R1']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'THE FISH WANT TO EAT ME! HELP!')
                    ]
                })
            ]
        },
        {   name: 'Bigoblin 3',
            animationName: 'Road',
            flags: ['GOBLIN'],
            level: 4,
            waves: [
                makeWave('Road', [], [
                    ['Bu', '  ', '[]', '  ', '[]', '  ', 'Bu'],
                    ['  ', '  ', '  ', 'Pl', '  ', '  ', '  '],
                    ['WW', 'PP', '  ', 'Go', '  ', 'PP', 'WW'],
                    ['  ', '  ', '  ', 'Pl', '  ', '  ', '  '],
                    ['Bu', '  ', '[]', '  ', '[]', '  ', 'Bu']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Help! I am not bullet-proof!')
                    ]
                })
            ]
        },
        {   name: 'Explokorokoraaa 1',
            animationName: 'Road',
            flags: ['EXPLODING_CRYSTAL'],
            level: 4,
            waves: [
                makeWave('Road', [], [
                    ['R1', '  ', 'PP', '  ', '<>', '  ', '  '],
                    ['PP', '  ', '  ', 'Pl', '  ', '  ', 'PP'],
                    ['  ', 'R1', '  ', 'XC', '  ', 'R1', '  '],
                    ['PP', '  ', '  ', 'Pl', '  ', '  ', 'PP'],
                    ['  ', '  ', '<>', '  ', 'PP', '  ', 'R1']
                ])
            ]
        },
        {   name: 'Explokorokoraaa 2',
            animationName: 'Road',
            flags: ['EXPLODING_CRYSTAL'],
            level: 4,
            waves: [
                makeWave('Road', [], [
                    ['  ', '  ', '[]', '  ', '[]', '  ', 'Bu'],
                    ['[]', 'Pl', '  ', '[]', 'Bu', '[]', '  '],
                    ['  ', '  ', '  ', '  ', '[]', '  ', '  '],
                    ['[]', 'Pl', '  ', '[]', 'CM', '[]', '  '],
                    ['  ', '  ', '[]', '  ', '[]', '  ', 'XC']
                ])
            ]
        },
        
        // Level 4 Hell Encounters
        {   name: 'Imps and Giants',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', [], [
                    ['R1', '  ', 'R1', '  ', '<>', 'Im', 'R1'],
                    ['  ', 'Pl', '  ', 'R1', 'Im', '  ', '  '],
                    ['  ', '  ', '<>', '  ', '<>', 'HG', '  '],
                    ['  ', 'Pl', '  ', 'R1', 'Im', '  ', '  '],
                    ['R1', '  ', '<>', '  ', '  ', 'Im', 'R1']
                ])
            ]
        },
        {   name: '2 Giants',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', [], [
                    ['(X)', '  ', '  ', '  ', '  ', 'HG',  '  '],
                    ['  ',  'Pl', '  ', '^^', '  ', '  ',  '  '],
                    ['  ',  '  ', '  ', '^^', '  ', '(X)', '  '],
                    ['  ',  'Pl', '  ', '^^', '  ', '  ',  '  '],
                    ['(X)', '  ', '  ', '  ', '  ', 'HG',  '  ']
                ])
            ]
        },
        {   name: '3 Hounds and Sporer',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', [], [
                    ['->', '  ', '^^', '  ', '^^', 'HH', '  '],
                    ['  ', 'Pl', '^^', '  ', '^^', '  ', '  '],
                    ['  ', '  ', '^^', '  ', '^^', 'SK', '  '],
                    ['  ', 'Pl', '^^', '  ', '^^', 'HH', '  '],
                    ['->', '  ', '^^', 'HH', '^^', '  ', '  ']
                ])
            ]
        },
        {   name: 'Hell Crystals',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', [], [
                    ['B1', '  ', '  ', '<>', '  ', 'LC', '  '],
                    ['  ', 'Pl', '<>', '  ', '  ', '  ', 'B1'],
                    ['  ', '<>', '  ', '<>', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '<>', '  ', 'LC'],
                    ['  ', 'B1', '  ', 'LC', '  ', '  ', 'B1']
                ])
            ]
        },
        {   name: 'Spore Holders',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', [], [
                    ['88', '  ', '88', '  ', 'FB', '  ', '88'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', 'WW', '  ', '88', 'WW', 'SK', '88'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['88', '  ', '88', '  ', '88', '  ', 'FB']
                ])
            ]
        },
        {   name: 'Impseseses',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', [], [
                    ['CC', '  ', '@@', '  ', 'Im', '  ', '@@'],
                    ['  ', 'Pl', '  ', '  ', 'HH', '@@', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', 'SK'],
                    ['  ', 'Pl', '  ', '  ', 'HH', '@@', '  '],
                    ['CC', '  ', '@@', '  ', 'Im', '  ', '@@']
                ])
            ]
        },
        {   name: 'Molly?',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', [], [
                    ['MP', '+]', '  ', '&&', '  ', '+]', 'MP'],
                    ['  ', '&&', 'WW', 'Pl', '<>', '  ', '&&'],
                    ['+]', 'MP', '<>', '&&', '<>', 'MP', '+]'],
                    ['  ', '  ', '<>', 'Pl', 'WW', '&&', '  '],
                    ['MP', '+]', '&&', '  ', '  ', '+]', 'MP']
                ])
            ]
        },
        {   name: 'Fire Beholderses',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', [], [
                    ['(X)', '  ', '  ',  '  ', '  ',  '  ', 'FB'],
                    ['  ',  'Pl', '(X)', '  ', '(X)', 'WW', '  '],
                    ['  ',  '  ', '  ',  '(X)', '  ', 'WW', '  '],
                    ['  ',  'Pl', '(X)', '  ', '(X)', 'WW', '  '],
                    ['(X)', '  ', '  ',  '  ', '  ',  '  ', 'FB']
                ])
            ]
        },
        {   name: 'Hell Canons',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', [], [
                    ['[]', '  ', '[]', '^^', '  ', '  ', 'Ca'],
                    ['[]', 'Pl', '[]', '^^', '  ', 'Ca', '  '],
                    ['[]', '  ', '[]', '^^', '  ', 'Dr', '  '],
                    ['[]', 'Pl', '[]', '^^', '  ', 'Ca', '  '],
                    ['[]', '  ', '[]', '^^', '  ', '  ', 'Ca']
                ])
            ]
        },
        {   name: 'Darky Bois',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', [], [
                    ['^^', '  ', '^^', 'Im', '  ', 'DW', '  '],
                    ['  ', 'Pl', '  ', '^^', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '^^', 'Im'],
                    ['  ', 'Pl', '  ', '  ', '^^', '  ', '  '],
                    ['^^', '  ', '  ', '^^', 'Im', '  ', 'DW']
                ])
            ]
        },
        {   name: 'Hellzillas',
            animationName: 'Hell',
            flags: ['HELL', 'SPECIAL'],
            level: 4,
            waves: [
                makeWave('CaveNatas', ['HZ' => 'Hellzilla'], [
                    ['  ', '^^', '  ', '^^', '  ', '^^', '  '],
                    ['^^', 'Pl', '^^', '  ', '^^', 'HZ', '^^'],
                    ['  ', '^^', '  ', '^^', '  ', '^^', '  '],
                    ['^^', 'Pl', '  ', '  ', '^^', 'HZ', '^^'],
                    ['  ', '^^', '  ', '^^', '  ', '^^', '  ']
                ])
            ]
        },

        // Level 4 Somnium Encounters
        /*
            Magic Candles
            
            Brat
            Rat
            Slime

            Beholder
            Darkwayman

            Ghoul
            Bubak
            Spore Keeper
            Void Crystal
        */
        {   name: 'Brats and Rats',
            animationName: 'Somnium',
            flags: ['SOMNIUM', 'SPECIAL'],
            level: 4,
            flipUnits: true,
            waves: [
                makeWave('Somnium', [], [
                    ['@@', 'Br', '  ', 'ii', '  ', '  ', 'R1'],
                    ['Ra', '  ', '  ', '  ', '  ', 'Pl', '  '],
                    ['  ', 'ii', 'Bu', '  ', 'ii', '  ', '  '],
                    ['Ra', '  ', '  ', '  ', '  ', 'Pl', '  '],
                    ['@@', 'Br', '  ', 'ii', '  ', '  ', 'R1']
                ], {
                    begin: function() {
                        enableSomnium();
                    }
                })
            ]
        },
        {   name: 'Slimy Rats',
            animationName: 'Somnium',
            flags: ['SOMNIUM', 'SPECIAL'],
            level: 4,
            flipUnits: true,
            waves: [
                makeWave('Somnium', [], [
                    ['()', 'Ra', '  ', '()', '  ', 'ii', '  '],
                    ['  ', '  ', 'Sl', '  ', '  ', 'Pl', '  '],
                    ['()', '~~', 'ii', '~~', 'ii', '~~', '()'],
                    ['  ', '  ', 'Sl', '  ', '  ', 'Pl', '  '],
                    ['()', 'Ra', '  ', '()', '  ', 'ii', '  ']
                ], {
                    begin: function() {
                        enableSomnium();
                    }
                })
            ]
        },
        {   name: 'Ghoul and Brats',
            animationName: 'Somnium',
            flags: ['SOMNIUM', 'SPECIAL'],
            level: 4,
            flipUnits: true,
            waves: [
                makeWave('Somnium', [], [
                    ['R1', 'Br', 'Br', 'R1', 'OO', 'WW', 'R1'],
                    ['  ', '  ', '  ', '  ', '  ', 'Pl', 'WW'],
                    ['LG', '  ', 'ii', '<>', 'ii', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', 'Pl', 'WW'],
                    ['Br', 'OO', 'Br', 'R1', '  ', 'WW', 'R1']
                ], {
                    begin: function() {
                        enableSomnium();
                    }
                })
            ]
        },
        {   name: 'Darkwaycandles',
            animationName: 'Somnium',
            flags: ['SOMNIUM', 'SPECIAL'],
            level: 4,
            flipUnits: true,
            waves: [
                makeWave('Somnium', [], [
                    ['ii', 'ii', 'ii', 'ii', 'ii', 'ii', 'ii'],
                    ['DW', '  ', '<>', '<>', '  ', 'Pl', '  '],
                    ['  ', '  ', '  ', '  ', 'R1', '  ', '  '],
                    ['DW', '  ', '<>', '<>', '  ', 'Pl', '  '],
                    ['ii', 'ii', 'ii', 'ii', 'ii', 'ii', 'ii']
                ], {
                    begin: function() {
                        enableSomnium();
                    }
                })
            ]
        },
        {   name: 'Slime Ghoul',
            animationName: 'Somnium',
            flags: ['SOMNIUM', 'SPECIAL'],
            level: 4,
            flipUnits: true,
            waves: [
                makeWave('Somnium', [], [
                    ['->', '  ', 'ii', '  ', 'Sl', '  ', '->'],
                    ['LG', '  ', '  ', '<>', '  ', 'Pl', '  '],
                    ['  ', '  ', '  ', '<>', 'ii', '  ', '  '],
                    ['  ', 'Sl', '  ', '<>', '  ', 'Pl', '  '],
                    ['->', '  ', 'ii', '  ', '  ', 'Sl', '->']
                ], {
                    begin: function() {
                        enableSomnium();
                    }
                })
            ]
        },
        {   name: 'Candle Tandle',
            animationName: 'Somnium',
            flags: ['SOMNIUM', 'SPECIAL'],
            level: 4,
            flipUnits: true,
            waves: [
                makeWave('Somnium', [], [
                    ['Sl', '  ', '  ', '@@', '  ', '  ', 'DW'],
                    ['  ', '<>', '  ', 'Pl', '  ', '<>', '  '],
                    ['@@', '<>', 'ii', '  ', 'ii', '<>', '@@'],
                    ['  ', '<>', '  ', 'Pl', '  ', '<>', '  '],
                    ['DW', '  ', '  ', '@@', '  ', '  ', 'Sl']
                ], {
                    begin: function() {
                        enableSomnium();
                    }
                })
            ]
        },
        {   name: 'Void Me Man',
            animationName: 'Somnium',
            flags: ['SOMNIUM', 'SPECIAL'],
            level: 4,
            flipUnits: true,
            waves: [
                makeWave('Somnium', [], [
                    ['DW', 'ii', '  ', 'ii', '  ', '  ', '  '],
                    ['  ', '  ', 'WW', '  ', '  ', 'Pl', '  '],
                    ['  ', 'OO', 'WW', 'OO', '  ', 'VC', '[$]'],
                    ['  ', '  ', 'WW', '  ', '  ', 'Pl', '  '],
                    ['DW', 'ii', '  ', 'ii', '  ', '  ', '  ']
                ], {
                    begin: function() {
                        enableSomnium();
                    }
                })
            ]
        },
        {   name: 'Candle Holders',
            animationName: 'Somnium',
            flags: ['SOMNIUM', 'SPECIAL'],
            level: 4,
            flipUnits: true,
            waves: [
                makeWave('Somnium', [], [
                    ['->', 'ii', '  ', '  ', '  ', 'ii', '->'],
                    ['Be', '  ', 'ii', '  ', 'ii', 'Pl', '  '],
                    ['  ', '  ', '  ', '<>', '  ', '  ', '  '],
                    ['Be', '  ', 'ii', '  ', 'ii', 'Pl', '  '],
                    ['->', 'ii', '  ', '  ', '  ', 'ii', '->']
                ], {
                    begin: function() {
                        enableSomnium();
                    }
                })
            ]
        },
        {   name: 'Solder Holder',
            animationName: 'Somnium',
            flags: ['SOMNIUM', 'SPECIAL'],
            level: 4,
            flipUnits: true,
            waves: [
                makeWave('Somnium', [], [
                    ['()', '  ', '^^', '^^', '^^', '  ', '()'],
                    ['  ', '  ', '^^', 'Pl', '^^', 'VC', '  '],
                    ['Be', '  ', '^^', 'ii', '^^', '  ', 'Be'],
                    ['  ', 'VC', '^^', 'Pl', '^^', '  ', '  '],
                    ['()', '  ', '^^', '^^', '^^', '  ', '()']
                ], {
                    begin: function() {
                        enableSomnium();
                    }
                })
            ]
        },
        {   name: 'Somnium Template',
            animationName: 'Somnium',
            flags: ['SOMNIUM', 'SPECIAL'],
            // level: 4,
            level: 1293,
            flipUnits: true,
            waves: [
                makeWave('Somnium', [], [
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', 'Pl', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', 'Pl', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  ']
                ], {
                    begin: function() {
                        enableSomnium();
                    }
                })
            ]
        },
        

        // Level 5 Encounters
        {   name: 'Zombillas',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['R1', '^^', '  ', '  ', '^^', 'Zo', '  '],
                    ['  ', 'Pl', '  ', '<>', '  ', '  ', 'R1'],
                    ['<>', '  ', '  ', '  ', '  ', '  ', 'Zo'],
                    ['  ', 'Pl', '  ', '<>', '  ', 'Zo', '  '],
                    ['R1', '^^', '  ', '  ', '^^', '  ', 'Zo']
                ])
            ]
        },
        {   name: 'Zouls',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['  ', '<>', '  ', '<>', 'Zo', '  ', 'R1'],
                    ['<>', 'Pl', '<>', '  ', '<>', '  ', '<>'],
                    ['<>', '  ', '<>', '<>', '<>', '  ', 'LG'],
                    ['<>', 'Pl', '<>', '  ', '<>', 'Zo', '<>'],
                    ['  ', '<>', '  ', '<>', 'Zo', '  ', 'R1']
                ])
            ]
        },
        {   name: 'Spine Skull Look At Them',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['+]', '  ', '  ', '+]', '  ', '  ', '+]'],
                    ['+]', 'Pl', '^^', '  ', '^^', 'Sk', '+]'],
                    ['+]', '  ', '  ', 'Zo', '  ', '  ', '+]'],
                    ['+]', 'Pl', '^^', '  ', '^^', 'Sk', '+]'],
                    ['+]', '  ', '  ', '+]', '  ', '  ', '+]']
                ])
            ]
        },
        {   name: 'Lots of Spines',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['+]', 'R1', '  ', '  ', '<>', 'Sk', '[$]'],
                    ['^^', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['^^', '  ', '  ', 'R2', 'R2', 'R2', 'R2'],
                    ['^^', 'Pl', '  ', '  ', '  ', '  ', 'Sk'],
                    ['+]', 'R1', '  ', '  ', 'Sk', '<>', '  ']
                ])
            ]
        },
        {   name: 'Zombie Ambush',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['Zo', '  ', '  ', '^^', '  ', '  ', 'Zo'],
                    ['  ', '+]', '  ', 'Pl', '  ', '+]', '  '],
                    ['Zo', '  ', '^^', '  ', '^^', '  ', 'Zo'],
                    ['  ', '+]', '  ', 'Pl', '  ', '+]', '  '],
                    ['Zo', '  ', '  ', '^^', '  ', '  ', 'Zo']
                ])
            ]
        },
        {   name: 'Behold, Beholders!',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['R1', '  ', '^^', '  ', '  ', '  ', 'Zo'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'Be', 'R1'],
                    ['->', '  ', '  ', 'R1', '  ', '  ', 'Zo'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'Be', 'R1'],
                    ['R1', '  ', '^^', '  ', '  ', '  ', 'Zo']
                ])
            ]
        },
        {   name: 'Drider Boss',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['+]', '~~', '  ', '()', '  ', 'Zo', '+]'],
                    ['~~', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['()', '  ', '  ', '  ', 'Dr', '  ', 'Zo'],
                    ['~~', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['+]', '~~', '  ', '()', '  ', 'Zo', '+]']
                ])
            ]
        },
        {   name: 'Undead Army 1',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['  ', '  ', '^^', '  ', '  ', '  ', 'R1'],
                    ['  ', 'Pl', '  ', '+]', 'Wr', '  ', 'LG'],
                    ['+]', '  ', '^^', '  ', '  ', '  ', '+]'],
                    ['  ', 'Pl', '  ', '^^', '  ', 'Zo', '  '],
                    ['  ', '  ', '+]', '  ', '  ', '  ', 'Sk']
                ])
            ]
        },
        {   name: 'Undead Army 2',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['  ', '  ', '  ', '[]', 'Sk', '  ', '[]'],
                    ['->', 'Pl', '  ', '  ', '  ', '[]', 'LG'],
                    ['  ', '  ', '  ', '[]', 'Zo', '  ', '  '],
                    ['->', 'Pl', '  ', '  ', '  ', '  ', '+]'],
                    ['  ', '  ', '[]', 'Zo', '  ', '  ', 'Sk']
                ])
            ]
        },
        {   name: 'Plain Ghouls',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['LG', 'WW', '  ', '+]', '  ', 'WW', 'LG'],
                    ['  ', '  ', '^^', 'Pl', '^^', '  ', '  '],
                    ['+]', '  ', '  ', '  ', '  ', '  ', '+]'],
                    ['  ', '  ', '^^', 'Pl', '^^', '  ', '  '],
                    ['LG', 'WW', '  ', '+]', '  ', 'WW', 'LG']
                ])
            ]
        },
        {   name: 'Wraith and Master',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['WW', '  ', '/@', '  ', '^^', '  ', '/@'],
                    ['WW', 'Pl', '  ', '  ', 'Wr', '  ', '[$]'],
                    ['  ', '  ', '^^', '  ', 'Wr', 'Dr', '  '],
                    ['WW', 'Pl', '  ', '  ', 'Wr', '  ', '  '],
                    ['WW', '  ', '/@', '  ', '^^', '  ', '/@']
                ])
            ]
        },
        {   name: 'More Beholders',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['R1', '  ', 'R1', '  ', 'R1', '  ', 'R1'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Be'],
                    ['^^', '  ', '  ', '  ', '  ', '  ', 'Be'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'Be', '  '],
                    ['R1', '  ', 'R1', '  ', 'R1', '  ', 'R1']
                ])
            ]
        },
        {   name: 'Red Crystal Cavern',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['^^', '  ', '^^', '  ', '  ', 'LC', '^^'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '^^', '  ', '  ', '  '],
                    ['^^', 'Pl', '  ', '  ', '  ', '  ', 'LC'],
                    ['  ', '^^', '  ', 'LC', '  ', '^^', '  ']
                ])
            ]
        },
        {   name: 'Crystal Wraiths',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['  ', '  ', 'WW', '  ', '  ', 'R1', 'LC'],
                    ['R1', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', 'WW', '  ', 'R1', 'Wr'],
                    ['R1', 'Pl', '  ', '  ', 'LC', '  ', '  '],
                    ['  ', '  ', 'WW', '  ', 'R1', '  ', 'Wr']
                ])
            ]
        },
        {   name: 'Beholder Trap',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['[]', '  ', '  ',  '  ',  'R1',  'Be', 'WW'],
                    ['WW', 'Pl', 'WW',  '(X)', '  ',  'WW', 'WW'],
                    ['WW', '  ', 'WW',  '  ',  '  ',  'WW', '(X)'],
                    ['WW', 'Pl', 'WW',  '  ',  '(X)', 'WW', 'WW'],
                    ['[]', '  ', '(X)', '  ',  '  ',  'Be', 'WW']
                ])
            ]
        },
        {   name: 'Mermaid Drider',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Beach', [], [
                    ['==', '==', '  ', '  ', '@@', '  ', 'Zo'],
                    ['  ', 'Pl', '  ', '~~', '  ', '~~', '  '],
                    ['  ', '  ', '  ', '  ', 'Dr', '  ', 'Me'],
                    ['~~', 'Pl', '~~', '  ', '~~', '  ', '  '],
                    ['@@', '  ', '==', '==', '  ', 'Zo', '  ']
                ])
            ]
        },
        {   name: 'Fungus Wraiths',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['Wr', '^^', '  ', '+]', '  ', '^^', 'Wr'],
                    ['  ', '  ', '  ', 'Pl', '  ', '  ', '  '],
                    ['+]', '  ', '  ', 'SK', '  ', '  ', '+]'],
                    ['  ', '  ', '  ', 'Pl', '  ', '  ', '  '],
                    ['Wr', '^^', '  ', '+]', '  ', '^^', 'Wr']
                ])
            ]
        },
        {   name: 'A Few Crystals',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['R1', '  ', '  ', 'R2', 'R2', '  ', 'Zo'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'LC', '  '],
                    ['->', '  ', '  ', 'DC', '  ', '  ', 'Zo'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['R1', 'R1', '  ', '  ', 'WW', 'LC', 'R1']
                ])
            ]
        },
        {   name: 'Lightning Crystals',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['R1', '  ', 'R1', 'R1', 'R1', '  ', 'R1'],
                    ['R1', 'Pl', '  ', '  ', '  ', 'Li', 'R1'],
                    ['R1', '  ', 'WW', 'WW', 'Li', '  ', 'R1'],
                    ['R1', 'Pl', '  ', '  ', '  ', 'Li', 'R1'],
                    ['R1', '  ', 'R1', 'R1', 'R1', '  ', 'R1']
                ])
            ]
        },
        {   name: 'Charge Please',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['~~', 'Zo', '^^', '  ', 'WW', '  ', 'R1'],
                    ['  ', '  ', '  ', 'Pl', '  ', '  ', '  '],
                    ['CC', '  ', '+]', '  ', '+]', '  ', 'Li'],
                    ['  ', '  ', '  ', 'Pl', '  ', '  ', '  '],
                    ['R1', '  ', 'WW', '  ', '^^', 'Zo', '~~']
                ])
            ]
        },
        {   name: 'Ignore The Drider',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['^^', '  ', '  ', 'Li', '  ', '  ', '^^'],
                    ['  ', 'Pl', 'WW', '  ', '  ', 'WW', '  '],
                    ['WW', '  ', '  ', '  ', 'Dr', '  ', 'CC'],
                    ['  ', 'Pl', 'WW', '  ', '  ', 'WW', '  '],
                    ['^^', '  ', '  ', 'Li', '  ', '  ', '^^']
                ])
            ]
        },
        {   name: 'Golems',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['R1', '  ', '  ', '^^', '  ', 'CG', '  '],
                    ['  ', 'Pl', '^^', '^^', '^^', '  ', '^^'],
                    ['  ', '  ', '^^', '^^', '^^', '  ', '^^'],
                    ['  ', 'Pl', '^^', '^^', '^^', '  ', '^^'],
                    ['R1', '  ', '  ', '^^', '  ', 'CG', '  ']
                ])
            ]
        },
        {   name: 'Golems and Crystals',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['^^', '  ', '  ', '  ', '^^', '  ', '^^'],
                    ['  ', 'Pl', '  ', 'LC', '  ', 'CG', '  '],
                    ['R1', '  ', '  ', '^^', '  ', 'LC', '[$]'],
                    ['  ', 'Pl', '  ', 'LC', '  ', 'CG', '  '],
                    ['^^', '  ', '  ', '  ', '^^', '  ', '^^']
                ])
            ]
        },
        {   name: 'Void Zombies',
            animationName: 'Graveyard',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['~~', '~~', '  ', '  ', 'Zo', '  ', '~~'],
                    ['~~', 'Pl', '~~', '~~', '  ', 'Zo', '  '],
                    ['[]', '  ', '  ', 'VC', 'Zo', '~~', '[$]'],
                    ['~~', 'Pl', '~~', '  ', '  ', 'Zo', '  '],
                    ['~~', '  ', '  ', '~~', 'Zo', '  ', '~~']
                ])
            ]
        },
        {   name: 'Driholders',
            animationName: 'Graveyard',
            flags: ['TOWN'],    // TODO: Make more!!
            level: 5,
            waves: [
                makeWave('Graveyard', [], [
                    ['  ', '  ', '^^', '^^', '^^', 'Be', '  '],
                    ['<>', 'Pl', '  ', '  ', '  ', '  ', '<>'],
                    ['  ', '<>', '+]', '+]', 'Dr', '<>', '  '],
                    ['<>', 'Pl', '  ', '  ', '  ', '  ', '<>'],
                    ['  ', '  ', '^^', '^^', '^^', '  ', 'Be']
                ])
            ]
        },
        {   name: 'Drillasers',
            animationName: 'Cave',
            flags: ['TOWN'],    // TODO: Make more!!
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['^^', '^^', '^^', '^^', '^^', '^^', '^^'],
                    ['  ', 'Pl', '  ', 'Dr', '  ', 'LC', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', 'LC'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['^^', '^^', '^^', '^^', '^^', '^^', '^^']
                ])
            ]
        },
        {   name: 'Double Drouble',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['->', '  ', 'R1', '  ', '  ', 'Dr', '  '],
                    ['R1', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', 'R1'],
                    ['R1', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['->', '  ', 'R1', '  ', '  ', 'Dr', '  ']
                ])
            ]
        },
        
        {   name: 'Mr Golem and Friends',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['  ', '  ', '[]', '  ', '[]', '  ', 'DW'],
                    ['^^', 'Pl', '  ', '  ', '  ', '  ', '^^'],
                    ['  ', '  ', '  ', '^^', '  ', 'CG', '  '],
                    ['^^', 'Pl', '  ', '  ', '  ', '  ', '^^'],
                    ['  ', '  ', '[]', '  ', '[]', '  ', 'DW']
                ])
            ]
        },
        {   name: 'Cyclops Among Us',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['+]', '  ', '  ', '  ', 'Zo', '  ', '  '],
                    ['^^', 'Pl', '  ', '  ', '  ', 'Cy', '  '],
                    ['^^', '  ', '+]', 'Zo', '  ', 'Zo', '+]'],
                    ['^^', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['+]', '  ', '  ', '  ', 'Zo', '  ', '  ']
                ])
            ]
        },
        {   name: 'Many Cyclops',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Forest', [], [
                    ['->', '  ', '  ', '  ', 'Cy', '  ', '[$]'],
                    ['  ', 'Pl', '  ', '^^', '  ', '  ', '  '],
                    ['  ', '  ', '^^', '  ', '^^', '==', '=='],
                    ['  ', 'Pl', '  ', '^^', '  ', '  ', '  '],
                    ['==', '==', '  ', '  ', '  ', 'Cy', '  ']
                ])
            ]
        },
        {   name: 'Darkwayzombies',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['  ', '  ', '  ', '  ', '  ', 'Zo', 'R1'],
                    ['  ', 'Pl', '  ', 'WW', '  ', '  ', 'DW'],
                    ['WW', '  ', 'R1', '  ', 'Zo', '[]', '  '],
                    ['  ', 'Pl', '  ', 'WW', '  ', '  ', 'DW'],
                    ['R1', '  ', '  ', '  ', '  ', 'Zo', '  ']
                ])
            ]
        },
        {   name: 'Many Crystals',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['R1', '  ', '  ', '<>', '  ', '  ', 'LC'],
                    ['R1', 'Pl', '<>', '  ', '<>', '  ', '[]'],
                    ['R1', '  ', '  ', '<>', 'LC', '[]', 'Li'],
                    ['R1', 'Pl', '<>', '  ', '<>', '  ', '[]'],
                    ['R1', '  ', '  ', '<>', '  ', '  ', 'LC']
                ])
            ]
        },
        {   name: 'Spine Fodder',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['  ', '+]', '  ', '  ', '  ', '+]', '  '],
                    ['^^', 'Pl', '  ', 'WW', 'Sk', '^^', 'DW'],
                    ['^^', '  ', '^^', '  ', '+]', '^^', '+]'],
                    ['^^', 'Pl', '  ', 'WW', 'Sk', '^^', 'DW'],
                    ['  ', '+]', '  ', '  ', '  ', '+]', '  ']
                ])
            ]
        },
        {   name: 'Wraith Fodder',
            animationName: 'Cave',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['  ', 'WW', '+]', '  ', '  ', '  ', 'Wr'],
                    ['WW', 'Pl', '  ', '  ', 'WW', 'DW', '  '],
                    ['+]', '  ', '  ', '+]', '  ', '  ', '+]'],
                    ['WW', 'Pl', '  ', '  ', 'WW', 'DW', '  '],
                    ['  ', 'WW', '+]', '  ', '  ', '  ', 'Wr']
                ])
            ]
        },
        {   name: 'Goblast 1',
            animationName: 'Cave',
            flags: ['GOBLIN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['R1', '  ', '  ', 'R1', '  ', 'DM', '  '],
                    ['  ', 'Pl', 'WW', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', 'WW', 'Zo', 'Go', 'Zo'],
                    ['  ', 'Pl', 'WW', '  ', '  ', 'R1', '  '],
                    ['R1', '  ', '  ', 'Zo', 'R1', '  ', 'Zo']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Aaa!!! They want to eat my brain!')
                    ]
                })
            ]
        },
        {   name: 'Goblast 2',
            animationName: 'Cave',
            flags: ['GOBLIN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['B1', '  ', 'WW', '  ', 'WW', 'Wr', '  '],
                    ['^^', 'Pl', '  ', 'WW', '  ', '  ', '  '],
                    ['^^', '  ', '  ', 'Go', '  ', 'B1', 'DM'],
                    ['^^', 'Pl', '  ', 'WW', '  ', '  ', '  '],
                    ['B1', '  ', 'WW', '  ', 'WW', 'Wr', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'GHOSTS! HELP!')
                    ]
                })
            ]
        },
        {   name: 'Goblast 3',
            animationName: 'Cave',
            flags: ['GOBLIN'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['<>', '  ', '->', '  ', '<>', '  ', 'DM'],
                    ['  ', 'Pl', '  ', '  ', '  ', 'Cy', '  '],
                    ['  ', '  ', '  ', '[]', 'Go', '  ', '[$]'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['<>', '  ', '->', '  ', '<>', '  ', 'DM']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Back, you huge dirty ape! Back!')
                    ]
                })
            ]
        },
        {   name: 'Level 5 Exploding Crystal 1',
            animationName: 'Cave',
            flags: ['EXPLODING_CRYSTAL'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['->', '  ', '  ', 'R1', '  ', '  ', 'LC'],
                    ['  ', 'Pl', '<>', '  ', '  ', '^^', '  '],
                    ['  ', '  ', '<>', 'Wr', 'Be', '  ', 'XC'],
                    ['  ', 'Pl', '<>', '  ', '  ', '^^', '  '],
                    ['->', '  ', '  ', 'R1', '  ', '  ', 'LC']
                ])
            ]
        },
        {   name: 'Level 5 Exploding Crystal 2',
            animationName: 'Cave',
            flags: ['EXPLODING_CRYSTAL'],
            level: 5,
            waves: [
                makeWave('Cave', [], [
                    ['R1', '  ', '  ', '  ', '  ', 'Wr', '  '],
                    ['  ', 'Pl', 'R1', '  ', 'R1', '  ', 'Wr'],
                    ['  ', '  ', '  ', 'XC', '  ', '  ', 'Be'],
                    ['  ', 'Pl', 'R1', '  ', 'R1', '  ', '  '],
                    ['R1', '  ', '  ', '  ', '  ', 'Wr', '  ']
                ])
            ]
        },
        



        // Boss Battles
        {   name: 'Pumpzilla',
            animationName: 'Fields',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            level: 3,
            waves: [
                makeWave('Fields', ['EP' => 'Evil Paprika', 'Pz' => 'Giant Pumpkin'], [
                    ['/@', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '88', '  ', '/@', '  '],
                    ['/@', '  ', '  ', 'Pz', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '/@', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Wow! A giant pumpkin!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Let's kill it!")
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_PUMPZILLA');
                Player.progression.defeatedPumpzilla = true;
                andThen();
            }
        },
        {   name: 'Stormjr',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            level: 5,
            animationName: 'Forest',
            waves: [
                makeWave('Beach', ['St' => 'Stormjr', 'WE' => 'Water Elemental'], [
                    ['  ', '  ', 'R1', '  ', '  ', '<>', '  '],
                    ['  ', 'Pl', '<>', '  ', '  ', '  ', 'R1'],
                    ['  ', '  ', '  ', '<>', '  ', 'St', '  '],
                    ['  ', 'Pl', '  ', '  ', '<>', '  ', '  '],
                    ['  ', '<>', '  ', 'R1', '  ', '  ', 'R1']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'You must flee from this place, mortals!', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'My heart is corrupted...', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'My soul is chained...', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'By the power of the Tile Shard.', 0, -35),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'The Tile Shard?'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'One of the 4 pieces?'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Yes...', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'I thought the Tile Shard would bring me great power.', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Instead, it tainted my soul with eldritch foulness...', 0, -35),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'We need the Tile Shard, Stormjr.'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Give it to us and we will be on our way.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'No...', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'I can\'t...', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'I want to, but my spirit won\'t let go of it.', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Fight me mortals!', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Put me out of my misery.', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'And the first Tile Shard will be yours!', 0, -35)
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_STORMJR');
                Player.progression.defeatedStormjr = true;
                NonCombatEvents.goToNonCombatEvents('Stormjr Defeated', andThen);
            }
        },
        {   name: 'Stormjr 2',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            level: 5,
            animationName: 'Forest',
            waves: [
                makeWave('Beach', ['St' => 'Stormjr', 'WE' => 'Water Elemental'], [
                    ['  ', '  ', 'R1', '  ', '  ', '<>', '  '],
                    ['  ', 'Pl', '<>', '  ', '  ', '  ', 'R1'],
                    ['  ', '  ', '  ', '<>', '  ', 'St', '  '],
                    ['  ', 'Pl', '  ', '  ', '<>', '  ', '  '],
                    ['  ', '<>', '  ', 'R1', '  ', '  ', 'R1']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'You are doing well, mortals.', 0, -35),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'We meet again.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Indeed.', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Yet, I can not allow you to pass.', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'For it is my soul\'s duty to stand in your way.', 0, -35),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'We shall defeat you again, then.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'I hope you will be able to also defeat my brother...', 0, -35),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Your brother?'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'We, dragons, are all one family.', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'But my brother has chosen the path of evil.', 0, -35),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Who is your brother?'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'He is the incarnation of evil!', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Our blood\'s black sheep.', 0, -35),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Yes, but who is he?'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'He is a disgrace to our kind!', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'He spit on our traditions and honor...', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), '...and his soul turned wicked.', 0, -35),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), '* sigh *'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Okay, Stormjr.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Fight me, mortals!', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Put me to rest once again!', 0, -35)
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Player.progression.defeatedStormjr2 = true;
                andThen();
            }
        },
        {   name: 'Stormjr 4',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            level: 5,
            animationName: 'Forest',
            waves: [
                makeWave('Beach', ['St' => 'Stormjr', 'WE' => 'Water Elemental'], [
                    ['  ', '  ', 'R1', '  ', '  ', '<>', '  '],
                    ['  ', 'Pl', '<>', '  ', '  ', '  ', 'R1'],
                    ['  ', '  ', '  ', '<>', '  ', 'St', '  '],
                    ['  ', 'Pl', '  ', '  ', '<>', '  ', '  '],
                    ['  ', '<>', '  ', 'R1', '  ', '  ', 'R1']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'I can no longer withhold my anger, heroes.', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Fight me!', 0, -35),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Stormjr'), 'Put out this eldritch flame inside my soul!', 0, -35)
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                andThen();
            }
        },
        {   name: 'Count Spatula',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            level: 5,
            animationName: 'Forest',
            waves: [
                makeWave('Church', ['Sp' => 'Count Spatula'], [
                    ['  ', '  ', '  ', '+]', '  ', '  ', '  '],
                    ['  ', 'Pl', '<>', '  ', '<>', '  ', '  '],
                    ['+]', '  ', '  ', '  ', '  ', 'Sp', '+]'],
                    ['  ', 'Pl', '<>', '  ', '<>', '  ', '  '],
                    ['  ', '  ', '  ', '+]', '  ', '  ', '  ']
                ])
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_SPATULA_1');
                Player.progression.defeatedSpatula1 = true;
                NonCombatEvents.goToNonCombatEvents('Spatula 1 Defeated', andThen);
            }
        },
        {   name: 'Count Spatula 2',    // CS Unleashed is summoned when CS normal dies
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            level: 5,
            animationName: 'Forest',
            waves: [
                makeWave('Church', ['Sp' => 'Count Spatula'], [
                    ['<>', '  ', '  ', '+]', '  ', '  ', '<>'],
                    ['  ', 'Pl', '+]', '  ', '+]', '  ', '  '],
                    ['VC', '  ', '  ', '  ', '  ', 'Sp', 'VC'],
                    ['  ', 'Pl', '+]', '  ', '+]', '  ', '  '],
                    ['<>', '  ', '  ', '+]', '  ', '  ', '<>']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Count Spatula'), "I've been exthpecting you, adventurers...", 0, -15),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Just like last time.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Count Spatula'), 'EHEM...', 0, -15),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Count Spatula'), 'No!', 0, -15),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Count Spatula'), 'This time...', 0, -15),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Count Spatula'), 'THIS TIME I SHALL HAVE YOUR HEADS!', 0, -15),
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_SPATULA_2');
                Player.progression.defeatedSpatula2 = true;
                NonCombatEvents.goToNonCombatEvents('Spatula 2 Defeated', andThen);
            }
        },
        {   name: 'Blessed Children of Almund',
            animationName: 'Forest',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            level: 3,
            waves: [
                makeWave('Church', ['BC' => 'Blessed Children of Almund'], [
                    ['+]', '  ', '+]', '  ', '+]', '  ', '+]'],
                    ['<>', 'Pl', '  ', '  ', '  ', '  ', '<>'],
                    ['<>', '  ', '  ', '  ', 'BC', '  ', '<>'],
                    ['<>', 'Pl', '  ', '  ', '  ', '  ', '<>'],
                    ['+]', '  ', '+]', '  ', '+]', '  ', '+]']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Stop right there, heatherns!', 3),
                        () -> sayFromRandomCharacterAndWait('Move out of the way, kids!'),
                        () -> sayFromRandomCharacterAndWait('We are after Father Almund, head of the church.'),
                        () -> sayFromRandomCharacterAndWait('We have no business with you.'),
                        () -> {
                            SpecialEffectsFluff.shakeScreenShort();
                            getRandomEnemyUnit().jot(LEFT);
                            sayFromUnitAndWait(getRandomEnemyUnit(), 'KNEEL BEFORE US, HEATHENS!!!', 3);
                        },
                        () -> sayFromRandomCharacterAndWait('O...K...?'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'You shall NEVER find Father Almund!!', -28, 15),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'He uses the power of the Tile Shard to conceal himself!!', 26, 10),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Your search is futile.', 3),
                        () -> sayFromRandomCharacterAndWait('So he has another one of the Tile Shards.'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'And he has granted us extraordinary powers.', 26, 10),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'WE SHALL DEFEND HIM WITH OUR LIVES!!!', 3)
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_BLESSED_CHILDREN');
                Player.progression.defeatedBlessedChildren = true;
                NonCombatEvents.goToNonCombatEvents('Blessed Children Defeated', andThen);
            }
        },
        {   name: 'Blessed Children of Almund 2',
            animationName: 'Forest',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            level: 3,
            waves: [
                makeWave('Church', ['BC' => 'Blessed Children of Almund'], [
                    ['+]', '  ', '+]', '  ', '+]', '  ', '+]'],
                    ['<>', 'Pl', '  ', '  ', '  ', '  ', '<>'],
                    ['<>', '  ', '  ', '  ', 'BC', '  ', '<>'],
                    ['<>', 'Pl', '  ', '  ', '  ', '  ', '<>'],
                    ['+]', '  ', '+]', '  ', '+]', '  ', '+]']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Oh, our worldly father, forgive us...', 3),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Oh, our joyful mother, grants us absolution...', 3),
                        () -> sayFromRandomCharacterAndWait('Wait, ok, we know father Almund.'),
                        () -> sayFromRandomCharacterAndWait('But mother?'),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Wicked woman, she is...', 3),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Foul woman.', -28, 15),
                        () -> sayFromRandomCharacterAndWait('An awful lot of motherless people on these lands.'),
                        () -> sayFromRandomCharacterAndWait('Almost like someone wanted to make a point...'),
                        () -> {
                            SpecialEffectsFluff.shakeScreenShort();
                            getRandomEnemyUnit().jot(LEFT);
                            sayFromUnitAndWait(getRandomEnemyUnit(), 'SILENCE!!!', 3);
                        },
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 'Talk time is over!', -28, 15),
                        () -> {
                            SpecialEffectsFluff.shakeScreenShort();
                            getRandomEnemyUnit().jot(LEFT);
                            sayFromUnitAndWait(getRandomEnemyUnit(), 'DIE NOW!!!', 3);
                        }
                    ]
                })
            ]
        },
        {   name: 'Captain Stashton Partial',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            animationName: 'Ship',
            level: 4,
            waves: [
                makeWave('Ship', ['PP' => 'Pirate Peasant'], [
                    ['->', '(_)', '  ', '  ', '  ', 'PP', '->'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Bu'],
                    ['  ', '  ', '  ', '[]', 'PP', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Bu'],
                    ['->', '(_)', '  ', '  ', '  ', '  ', '->']
                ], {
                    start: [
                        function() {
                            final captain: Actor = U.createActor('UnitActor', 'Units');
                            captain.setAnimation('Captain Stashton');

                            centerActorOnScreen(captain);
                            captain.setX(Battlefield.getTile(2, 6).getXCenter() - 2);
                            captain.setY(captain.getY() - 3);
                            Battlefield.encounterData = {
                                captain: captain,
                                captainMarkedTiles: new Array<TileSpace>()
                            };
                            sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Hey!");
                            Battlefield.addOnRoundEndEvent(function(roundNumber) {
                                if (roundNumber % 2 == 0) {
                                    playAudio('GunCockAudio');
                                    final randomChar = getRandomPlayerCharacterUnit();
                                    final tile1 = randomChar.tileOn;
                                    final tile2 = randomChar.tileOn.getRandomEmptyNeighbor(true);
                                    final redTiles = [tile1];
                                    if (tile2 != null)
                                        redTiles.push(tile2);
                                    for (tile in redTiles) {
                                        tile.addDangerMarker();
                                    }
                                    Battlefield.encounterData.captainMarkedTiles = redTiles;
                                } else {
                                    final redTiles: Array<TileSpace> = Battlefield.encounterData.captainMarkedTiles;
                                    Battlefield.sayFromActor(Battlefield.encounterData.captain, 'Hahahaarrrgh!!');
                                    playAudio('GunShootAudio');
                                    for (tile in redTiles) {
                                        tile.removeDangerMarker();
                                        if (tile.hasUnit())
                                            tile.unitOnIt.damage(6, PHYSICAL);
                                    }
                                }
                            });
                        },
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Get in here!"),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, 'Yahaharghh!'),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, 'No!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Not fair!")
                    ],
                    end: [
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "We defeated your crew!"),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Face us, now!"),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, 'Well...'),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, 'No!'),
                        () -> {
                            Battlefield.encounterData.captain.growTo(-1, 1, 0.25, Easing.expoOut);
                            doAfter(250, () -> {
                                Battlefield.encounterData.captain.moveBy(getScreenWidth() / 2, 0, 0.5, Easing.expoIn);
                            });
                            doAfter(500, () -> {
                                sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Come on!!");
                            });
                        }
                    ]
                })
            ]
        },
        {   name: 'Captain Stashton',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            animationName: 'Fields',
            level: 5,
            waves: [
                makeWave('Ship', ['Cr' => 'Crewmate', 'Bu' => 'Bucaneer', 'PP' => 'Pirate Peasant'], [
                    ['  ', '  ', '  ', '  ', 'Cr',  '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ',  '  ', '  '],
                    ['  ', '  ', '  ', '  ', '[$]', 'Bu', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ',  '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ',  '  ', 'PP']
                ], {
                    begin: function() {
                        captainStashtonBegin();
                    },
                    start: [
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, 'We meet again, landlubbers!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "You're supposed to be the boss..."),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "You're not even on the battlefield!"),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, 'Walk the plank, would ye!?'),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, 'Where\'s the fun in dying, yahahahaharggh!!')
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_CAPTAIN_STASHTON');
                Player.progression.defeatedCaptainStashton = true;
                NonCombatEvents.goToNonCombatEvents('Captain Stashton Defeated', andThen);
            }
        },
        {   name: 'Captain Stashton 2',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            animationName: 'Fields',
            level: 5,
            waves: [
                makeWave('Ship', ['Cr' => 'Crewmate', 'Bu' => 'Bucaneer', 'PP' => 'Pirate Peasant'], [
                    ['  ', '  ', '  ', '  ', '  ',  'Cr', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ',  '  ', 'PP'],
                    ['  ', '  ', '  ', '  ', '  ',  '[$]', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ',  '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ',  'Bu', '  ']
                ], {
                    begin: function() {
                        captainStashtonBegin();
                    },
                    start: [
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, 'What do ye scoundrels want again? Leave me alone!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Let us through, Captain Stashton!"),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, 'What!? Ye\'re on MY ship!'),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, 'And ye don\'t even say "please"?'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Just move out of the way."),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, "I'm a boss fight, arrren\'t I?!"),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, "You'll have to kill me like the blacksmith killed..."),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Wait... he killed who?"),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, "Let's just say he's not a gentlemen with ladies..."),
                        () -> sayFromActorAndWait(Battlefield.encounterData.captain, "Yahahargh...")
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_CAPTAIN_STASHTON');
                andThen();
            }
        },
        {   name: 'Father Almund',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            animationName: 'Forest',
            level: 3,
            waves: [
                makeWave('Church', ['FA' => 'Father Almund', 'Ps' => 'Peasant'], [
                    ['  ', '  ', '[]', '  ', 'Ps', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['TT', 'TT', '  ', '  ', '  ', 'FA', '+]'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '[]', '  ', 'Ps', '  ', '  ']
                ], {
                    start: [
                        () -> {
                            trace('Doing Father almund flippy');
                            getUnitByName('Father Almund').flipHorizontally();
                            sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Father Almund...");
                        },
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "O Lord and Savior, hear me...", -12),
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "In these dark moments, deliver me from evil...", -12),
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "O Lord...", -12),
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "Why hast thou forsaken me...", -12),
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "I only hear the voices of demons.", -12),
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "If only this Tile Shard could empower my faith...", -12),
                        () -> {
                            getUnitByName('Father Almund').flipHorizontally();
                            sayFromUnitAndWait(getUnitByName('Father Almund'), "TO DESTROY THEE, PAGANS!!", 12);
                        },
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Uh-oh...")
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                if (Player.progression.defeatedFatherAlmund) {
                    andThen();
                } else {
                    Game.setAchievement('DEFEATED_FATHER_ALMUND');
                    Player.progression.defeatedFatherAlmund = true;
                    NonCombatEvents.goToNonCombatEvents('Father Almund Defeated', andThen);
                }
            }
        },
        {   name: 'Father Almund 2',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            animationName: 'Forest',
            level: 3,
            waves: [
                makeWave('Church', ['FA' => 'Father Almund', 'Ps' => 'Peasant'], [
                    ['  ', '  ', '[]', '  ', 'Ps', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['TT', 'TT', '  ', '  ', '  ', 'FA', '+]'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '[]', '  ', 'Ps', '  ', '  ']
                ], {
                    start: [
                        () -> {
                            getUnitByName('Father Almund').flipHorizontally();
                            sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Father Almund?");
                        },
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "It gnaws at me, strangers...", -12),
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "Deep within my mind...", -12),
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "O Lord...", -12),
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "Why hast thou forsaken me...", -12),
                        () -> {
                            getUnitByName('Father Almund').flipHorizontally();
                            sayFromUnitAndWait(getUnitByName('Father Almund'), "Who are these pagans at my doorstep?", 12);
                        },
                        () -> sayFromUnitAndWait(getUnitByName('Father Almund'), "Pagans! They are just PAGANS!!", 12),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Oof...")
                    ]
                })
            ]
        },
        {   name: 'Marceline',
            flags: ['SPECIAL', 'DARK_MUSIC', 'BOSS_ICON'],
            level: 5,
            animationName: 'Forest',
            waves: [
                makeWave('Cave', ['Ma' => 'Marceline'], [
                    ['R1', '  ', '<>', '  ', '<>', '  ', 'R1'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '<>', '  ', '<>', 'Ma', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['R1', '  ', '<>', '  ', '<>', '  ', 'R1']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('Marceline'), "I gave you a choice, adventurers..."),
                        () -> sayFromUnitAndWait(getUnitByName('Marceline'), "You did not pick the right one."),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Sorry, Marceline."),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "There is no go-"),
                        () -> sayFromUnitAndWait(getUnitByName('Marceline'), "There is no going back now!"),
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_MARCELINE');
                Player.progression.defeatedKingOrMarceline = true;
                NonCombatEvents.goToNonCombatEvents('Marceline Defeated', andThen);
            }
        },
        {   name: 'King Erio',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            level: 5,
            animationName: 'Forest',
            waves: [
                makeWave('Castle', ['KE' => 'King Erio', 'RG' => 'Royal Guard Stationary', 'Bi' => 'Bishop'], [
                    ['  ', '  ', '  ', '  ', 'RG', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', 'RG', '  ', 'KE'],
                    ['  ', '  ', '  ', '  ', 'RG', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', 'RG', 'Bi', '  '],
                    ['  ', '  ', '  ', '  ', 'RG', '  ', '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getUnitByName('King Erio'), "Heroes..."),
                        () -> sayFromUnitAndWait(getUnitByName('King Erio'), "I am saddened it has come to this."),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "We are sorry, King Erio."),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "But this is the right choice."),
                        () -> sayFromUnitAndWait(getUnitByName('King Erio'), "Very well."),
                        () -> sayFromUnitAndWait(getUnitByName('King Erio'), "Bannermen! To me!"),
                        () -> sayFromUnitAndWait(Battlefield.getUnit(2, 4), "We don't have a bannerman, sire."),
                        () -> {
                            sayFromUnitAndWait(getUnitByName('King Erio'), "...");
                            getUnitByName('King Erio').flipHorizontally();
                            doAfter(500, () -> {
                                getUnitByName('King Erio').flipHorizontally();
                            });
                        },
                        () -> sayFromUnitAndWait(getUnitByName('King Erio'), "Archers?"),
                        () -> sayFromUnitAndWait(Battlefield.getUnit(2, 4), "Neither, sire."),
                        () -> sayFromUnitAndWait(getUnitByName('King Erio'), "Curses!!"),
                        () -> sayFromUnitAndWait(getUnitByName('King Erio'), "Very well."),
                        () -> sayFromUnitAndWait(getUnitByName('King Erio'), "We shall do with what we have."),
                        () -> sayFromUnitAndWait(getUnitByName('King Erio'), "TO ARMS!!!")
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_KING');
                Player.progression.defeatedKingOrMarceline = true;
                NonCombatEvents.goToNonCombatEvents('King Defeated', andThen);
            }
        },
        {   name: 'Tyl',
            animationName: 'Forest',
            flags: ['SPECIAL', 'DARK_MUSIC', 'BOSS_ICON'],
            description: 'test',
            level: 5,
            waves: [
                makeWave('Castle', [], [
                    ['  ', '  ', '  ', '^^', '^^', '  ',  '  '],
                    ['Pl', '  ', '  ', '^^', '^^', '  ',  '  '],
                    ['  ', '  ', '  ', '  ', '  ', 'Tyl', '  '],
                    ['Pl', '  ', '  ', '^^', '^^', '  ',  '  '],
                    ['  ', '  ', '  ', '^^', '^^', '  ',  '  ']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "I have been watching you, mortals.", -55, -53),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "I knew you were going to fail.", -55, -53),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 
                            if (Player.progression.sidedWith == 'king') "But getting fooled like that by the king?"
                            else "But allying yourselves with my puppet, Marceline?"
                            , -55, -53),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), 
                            if (Player.progression.sidedWith == 'king') "That was most amusing."
                            else "What a bunch of simps."
                            , -55, -53),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Your words will spell your end, Tyl!"),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "Foolish to the very end.", -55, -53),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "Then it is time, mortals.", -55, -53),
                        () -> sayFromUnitAndWait(getRandomEnemyUnit(), "Your end has come!!!", -55, -53),
                    ]
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_TYL');
                Player.progression.defeatedTyl = true;
                NonCombatEvents.goToNonCombatEvents('Tyl Defeated', andThen);
            }
        },

        // Special
        {   name: 'Fallen Hero',
            animationName: 'Forest',
            flags: ['SPECIAL', 'DARK_MUSIC', 'BOSS_ICON'],
            level: 3,
            waves: [
                makeWave('Graveyard', ['Wr' => 'Wraith'], [
                    ['  ', '@@', '  ', '  ', '[]', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '+]', '  ', '  ', 'Wr'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '@@', '  ', '  ', '[]', '  ', '  ']
                ])
            ]
        },
        {   name: 'Sandman',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            animationName: 'Somnium',
            level: 5,
            waves: [
                makeWave('Somnium', ['Sa' => 'Sandman', '..' => 'Sand Pile'], [
                    ['<>', '  ', 'ii', '  ', 'ii', '  ', '<>'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['ii', '  ', '  ', '  ', '  ', 'Sa', 'ii'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['<>', '  ', 'ii', '  ', 'ii', '  ', '<>']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Sandman'), 'Intruders!!'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Sandman'), 'What are you doing in my Somnium!?'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Relax, Papa Grumps.'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'We\'re just here to check on your daughter.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Sandman'), '* gulp *'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Sandman'), 'Well, she\'s fine, no worries.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Sandman'), 'Tell tooth fairy her daughter is safe.'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Tooth fairy and Sandman... makes sense.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Sandman'), 'Away with you now, bye bye!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Wait!'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Are you suuure she is ok?'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Sandman'), 'Yes, yes, 100%.'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Can we check?'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Sandman'), 'NO! She\'s busy with... homework.'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Right...'),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'We\'ll kick your butt, then check on her.'),
                    ],
                    begin: function() {
                        enableSomnium();
                    }
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                Game.setAchievement('DEFEATED_SANDMAN');
                Player.progression.defeatedSandman = true;
                NonCombatEvents.goToNonCombatEvents('Sandman Defeated', andThen);
            }
        },
        {   name: 'Natas',
            flags: ['SPECIAL', 'BOSS_MUSIC', 'BOSS_ICON'],
            animationName: 'Hell',
            level: 5,
            waves: [
                makeWave('CaveNatas', ['Na' => 'Natas', 'Wo' => 'Wolf'], [
                    ['  ', 'R1', '  ', '  ', 'R1', '  ', '[]'],
                    ['  ', 'Pl', '  ', '  ', 'HH', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', 'Na', '  '],
                    ['  ', 'Pl', '  ', '  ', 'HH', '  ', '  '],
                    ['R2', 'R2', '  ', '[]', '  ', '  ', 'R1']
                ], {
                    start: [
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Natas'), 'What the-', 0, -30),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Natas'), 'How did-', 0, -30),
                        () -> {
                            getEnemyUnitWithName('Natas').actor.setAnimation('Natas Pissed');
                            sayFromUnitAndWait(getEnemyUnitWithName('Natas'), 'Guys, please leave.', 0, -30);
                        },
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'No.'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Natas'), 'This is my home. I have stuff to do.', 0, -30),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Natas'), 'Please leave and I won\'t torture you for eternity.', 0, -30),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'You helped Tyl conquer the kingdom!'),
                        () -> {
                            getEnemyUnitWithName('Natas').actor.setAnimation('Natas');
                            sayFromUnitAndWait(getEnemyUnitWithName('Natas'), 'Yeah, so?', 0, -30);
                        },
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'You are evil!!!'),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Natas'), 'Pfft...', 0, -30),
                        () -> sayFromUnitAndWait(getEnemyUnitWithName('Natas'), 'I am the devil, of course I\'m evil.', 0, -30),
                        () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Prepare to be smitten!!!', 0, -30)
                    ],
                    finish: () -> {
                        if (Player.progression.defeatedNatas) return;
                        Game.setAchievement('DEFEATED_NATAS');
                        Player.progression.defeatedNatas = true;
                        for (pc in Player.characters) {
                            Player.setupNatasPermanentBuffs(pc);
                        }
                    }
                })
            ],
            afterCombatEvent: function(andThen: Void -> Void) {
                NonCombatEvents.goToNonCombatEvents('Natas Defeated', andThen);
            }
        },
        {   name: 'Pirates',
            animationName: 'Forest',
            flags: ['SPECIAL'],
            level: 3,
            waves: [
                makeWave('Beach', ['CM' => 'Crewmate', 'Ca' => 'Canon', 'PP' => 'Pirate Peasant'], [
                    ['  ', '  ', 'R1', '  ', '  ', '  ', 'R1'],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', 'Ca'],
                    ['  ', '  ', '  ', '  ', 'CM', '  ', '  '],
                    ['  ', 'Pl', '  ', 'R1', '  ', 'PP', '  '],
                    ['R1', '  ', '  ', '  ', '  ', '  ', 'R1']
                ], {
                    finish: () -> {
                        AfterCombat.setupExtraExtraLoot(Player.progression.piratesItemsStored);
                        AfterCombat.setupExtraGold(Player.progression.piratesGoldStored);
                        Player.progression.piratesItemsStored = [];
                        Player.progression.piratesGoldStored = 0;
                    }
                })
            ]
        },
        
        {   name: 'Blubber Test',
            animationName: 'Forest',
            description: 'test',
            waves: [
                makeWave('Beach', ['Bl' => 'Blubber'], [
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['Pl', '  ', '  ', '  ', 'Bl', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['Pl', '  ', '  ', '  ', '  ', '  ', '  ']
                ])
            ]
        },
        {   name: 'Test',
            animationName: 'Forest',
            description: 'test',
            waves: [
                makeWave('Beach', [
                    'BB' => 'Bloodbath',
                    'CS' => 'Count Spatula Unleashed',
                    'Cy' => 'Cyclops',
                    'SM' => 'Serfmaster',
                    'CG' => 'Crystal Golem',
                    'VC' => 'Void Crystal',
                    'Li' => 'Lightning Crystal',
                    'CC' => 'Charging Crystal',
                    'LC' => 'Laser Crystal',
                    'DC' => 'Draining Crystal',
                    'Wr' => 'Wraith',
                    'Dr' => 'Drider',
                    'Be' => 'Beholder',
                    'SS' => 'Spine Skull',
                    'LG' => 'Lantern Ghoul',
                    'Zo' => 'Zombie',
                    'WE' => 'Water Elemental',
                    'Pe' => 'Peasant',
                    'Me' => 'Mermaid',
                    'SK' => 'Spore Keeper',
                    'BS' => 'Big Slime',
                    'RM' => 'Reverse Mermaid',
                ], [
                    ['  ', '  ', '  ', '  ', 'MP', 'MP', 'MP'],
                    ['  ', 'Pl', '  ', '  ', 'MP', 'MP', 'MP'],
                    ['  ', '  ', '  ', '  ', 'MP', 'MP', 'MP'],
                    ['  ', 'Pl', '  ', '  ', 'MP', 'MP', 'MP'],
                    ['  ', '  ', '  ', '  ', 'MP', 'MP', 'MP']
                ], {
                    start: [
                        // () -> sayFromUnitAndWait(getEnemyUnitWithName('Little Scout'), 'There they are! Behind that big rock!'),
                        // () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'I can\'t see anything!'),
                        // () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'There\'s a giant rock blocking my view!')
                    ]
                })
            ]
        },
        {   name: 'Test2',
            animationName: 'Forest',
            description: 'test',
            waves: [
                makeWave('Cave', [
                    'Ma' => 'Marceline',
                    'SS' => 'Spectral Sword',
                    'SM' => 'Serfmaster',
                    'CG' => 'Crystal Golem',
                    'VC' => 'Void Crystal',
                    'Li' => 'Lightning Crystal',
                    'CC' => 'Charging Crystal',
                    'LC' => 'Laser Crystal',
                    'DC' => 'Draining Crystal',
                    'Wr' => 'Wraith',
                    'Dr' => 'Drider',
                    'Be' => 'Beholder',
                    'LG' => 'Lantern Ghoul',
                    'Zo' => 'Zombie',
                    'WE' => 'Water Elemental',
                    'Pe' => 'Peasant',
                    'Me' => 'Mermaid',
                    'SK' => 'Spore Keeper',
                    'BS' => 'Big Slime',
                    'RM' => 'Reverse Mermaid'], [
                    ['R1', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', 'Pumpzilla', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['R1', '  ', '  ', '  ', '  ', '[]', '  ']
                ])
            ]
        },
        
        {   name: 'Explo Test',
            animationName: 'Forest',
            description: 'test',
            waves: [
                makeWave('Beach', ['Ps' => 'Peasant'], [
                    ['  ', '(X)', '(X)', '(X)', '(X)', '(X)', '(X)'],
                    ['  ', '(X)', '(X)', '(X)', '(X)', '(X)', '(X)'],
                    ['Pl', '(X)', '(X)', '(X)', '(X)', '(X)', 'Ps'],
                    ['  ', '(X)', '(X)', '(X)', '(X)', '(X)', '(X)'],
                    ['  ', '(X)', '(X)', '(X)', '(X)', '(X)', '(X)']
                ])
            ]
        },
        {   name: 'Tenta',
            animationName: 'Forest',
            waves: [
                makeWave('Beach', ['PT' => 'Pumpkin Tentacle', 'Pz' => 'Giant Pumpkin'], [
                    ['  ', '  ', '+]', '  ', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', 'R1', '  ', 'Pz', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['/@', '  ', '  ', '  ', '+]', '  ', '  ']
                ])
            ]

        }
    ];

    private static var copyPasteBoard = {
        board: [
            ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
            ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
            ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
            ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
            ['  ', '  ', '  ', '  ', '  ', '  ', '  ']
        ],
        
        templateEncounter:

        {   name: 'xxxx',
            animationName: 'Forest',
            flags: ['TOWN'],
            level: 5,
            waves: [
                makeWave('Road', [], [
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  '],
                    ['  ', 'Pl', '  ', '  ', '  ', '  ', '  '],
                    ['  ', '  ', '  ', '  ', '  ', '  ', '  ']
                ])
            ]
        },
        boardWithNumbers: makeWave('Road', [], [
            ['00', '01', '02', '03', '04', '05', '06'],
            ['10', '11', '12', '13', '14', '15', '16'],
            ['20', '21', '22', '23', '24', '25', '26'],
            ['30', '31', '32', '33', '34', '35', '36'],
            ['40', '41', '42', '43', '44', '45', '46']
        ]),
        nothing: null
    };

    static function doDramaticEntry(unitActor: Actor, tileToSpawn: TileSpace) {
        trace(': Doing dramatic entry for actor with animation ${unitActor.getAnimation()}');
        unitActor.setX(getScreenX() + getScreenWidth() / 3 * 2);    // Put him on the top-right of the screen
        unitActor.setY(getScreenY() - unitActor.getHeight());
        final ropeStartX = unitActor.getX();
        final ropeStartY = unitActor.getY();

        final finalPoint: Point = tileToSpawn.getHypotheticCoordinatesForActor(unitActor);
        unitActor.moveTo(finalPoint.x, finalPoint.y, 1, Easing.quadInOut);

        final ropeChain = U.createActor('LightningEffectActor', 'Units3');    // To be below Units4
        ropeChain.setAnimation('Rope');
        doEveryUntil(20, 1000, () -> {
            stretchActorBetweenPoints(ropeChain, ropeStartX, ropeStartY, unitActor.getXCenter(), unitActor.getYCenter());
        });
        doAfter(1100, () -> {
            recycleActor(ropeChain);
        });
    }





    public static function alertAndWait(message, ?xOffset = 0, ?yOffset = 0) {
        Battlefield.alertAndWait(message, int(U.getScreenXCenter()) + xOffset, int(getScreenY() + 110 + yOffset));
    }
    public static function sayFromRandomCharacterAndWait(sayWhat: String) {
        sayFromUnitAndWait(getRandomPlayerCharacterUnit(), sayWhat);
    }
    public static function getTutorialGoblinDialogue() {
        return [
            () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'You there!'),
            () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Help!'),
            () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Who are you?'),
            () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'I am the Loot Goblin!'),
            () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Loot goblin?'),
            () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'If you save me, I\'ll give you extra treasure!'),
            () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Neat!'),
            () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Oh, but if I die...'),
            () -> sayFromUnitAndWait(getUnitByName('Goblin'), 'Nobody gets anything if I die!'),
            () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Don\'t worry, little guy.'),
            () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'We\'ll do our best!')
        ];
    }
    public static function getTutorialCrystalDialogue() {
        return [
            () -> sayFromUnitAndWait(getUnitByName('Exploding Crystal'), '* Crackle *'),
            () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), 'Look at that crystal!'),
            () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "It's about to explode!"),
            () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "If it bursts, we're all screwed!"),
            () -> sayFromUnitAndWait(getUnitByName('Exploding Crystal'), '* Crackle *'),
            () -> sayFromUnitAndWait(getRandomPlayerCharacterUnit(), "Don't let it die!")
        ];
    }

    static function captainStashtonBegin() {
        final captain: Actor = U.createActor('UnitActor', 'Units');
        captain.setAnimation('Captain Stashton');
        centerActorOnScreen(captain);
        captain.setX(Battlefield.getTile(2, 6).getXCenter() - 2);
        captain.setY(captain.getY() - 3);
        
        Battlefield.encounterData = {
            captain: captain,
            captainMarkedTiles: new Array<TileSpace>()
        };

        Battlefield.initCustomInt('currentPhase', 1);
        Battlefield.addAfterUnitDeathEvent(function(dyingUnit: Unit, tileWhereDied: TileSpace) {
            if (dyingUnit.owner != ENEMY) return;
            if (Battlefield.customData.ints['currentPhase'] == 2) return;
            final areAllEnemiesDead = Battlefield.getAllAliveEnemyUnits().length == 0;
            if (!!!areAllEnemiesDead) return;

            final captainMarkedTiles: Array<TileSpace> = Battlefield.encounterData.captainMarkedTiles;
            if (captainMarkedTiles != null && captainMarkedTiles.length > 0) {
                for (tile in captainMarkedTiles) {
                    if (tile.hasDangerMarker()) {
                        tile.removeDangerMarker();
                    }
                }
            }

            Battlefield.customData.ints['currentPhase'] = 2;
            final captainTile = Battlefield.getRandomTileWithNoUnit();
            final captainUnit = Battlefield.spawnEnemyOnTile('Captain Stashton', captainTile);
            final toX = captainUnit.getX(), toY = captainUnit.getY();
            final fromX = captain.getX(), fromY = captain.getY();
            recycleActor(captain);
            captainUnit.actor.setX(fromX);
            captainUnit.actor.setY(fromY);
            captainUnit.actor.moveTo(toX, toY, 0.5, Easing.expoOut);
            doAfter(500, () -> {
                captainUnit.say('Alreight... CHALLENGE ACCEPTED!', 2);
            });
            final crewmate = Battlefield.spawnEnemyOnTile('Crewmate', Battlefield.getRandomTileWithNoUnit());
            final peasant = Battlefield.spawnEnemyOnTile('Pirate Peasant', Battlefield.getRandomTileWithNoUnit());
            final bucaneer = Battlefield.spawnEnemyOnTile('Bucaneer', Battlefield.getRandomTileWithNoUnit());
            doDramaticEntry(crewmate.actor, crewmate.tileOn);
            doDramaticEntry(peasant.actor, peasant.tileOn);
            doDramaticEntry(bucaneer.actor, bucaneer.tileOn);
        });
        Battlefield.addOnRoundEndEvent(function(roundNumber) {
            if (roundNumber % 4 == 0) {                     // Summon barrel
                if (Battlefield.customData.ints['currentPhase'] == 2) return;
                final randomChar = getRandomAlivePlayerUnit();
                final barrelTile = randomChar.tileOn.getRandomEmptyNeighbor(true);
                if (barrelTile == null) return;
                Battlefield.sayFromActor(Battlefield.encounterData.captain, 'Barrel!!');
                final barrel = Battlefield.spawnEnemyOnTile('Explosive Barrel', barrelTile);
                barrel.playEffect('Smoke');
                final originalY = barrel.actor.getY();
                final originalHeight = barrel.actor.getHeight();
                final barrelActor = barrel.actor;
                barrelActor.growTo(0.8, 1.2, 0, Easing.linear);
                barrelActor.setY(originalY - originalHeight * 0.1);
                doAfter(10, () -> {
                    barrelActor.growTo(1.2, 0.8, 0.35, Easing.expoOut);
                    barrelActor.moveTo(barrelActor.getX(), originalY + originalHeight * 0.1, 0.35, Easing.expoOut);
                    doAfter(350, () -> {
                        if (barrel.isDead) return;  // Just to be sure not to bug the game
                        barrelActor.growTo(1, 1, 0.25, Easing.linear);
                        barrelActor.moveTo(barrelActor.getX(), originalY, 0.25, Easing.linear);
                    });
                });
            } else if (roundNumber % 4 == 1) {              // Prepare to shoot
                if (Battlefield.customData.ints['currentPhase'] == 2) return;
                playAudio('GunCockAudio');
                final aBarrel = Battlefield.getUnitByName('Barrel');
                final randomChar = if (percentChance(50) && aBarrel != null) aBarrel else getRandomAlivePlayerUnit();
                final tile1 = randomChar.tileOn;
                final tile2 = randomChar.tileOn.getRandomEmptyNeighbor(true);
                final redTiles = [tile1];
                if (tile2 != null)
                    redTiles.push(tile2);
                for (tile in redTiles) {
                    tile.addDangerMarker();
                }
                Battlefield.encounterData.captainMarkedTiles = redTiles;
            } else if (roundNumber % 4 == 2) {              // Shoot and prepare to summon
                if (Battlefield.customData.ints['currentPhase'] == 1) {
                    final redTiles: Array<TileSpace> = Battlefield.encounterData.captainMarkedTiles;
                    Battlefield.sayFromActor(Battlefield.encounterData.captain, 'Hahahaarrrgh!!');
                    playAudio('GunShootAudio');
                    for (tile in redTiles) {
                        tile.removeDangerMarker();
                        if (tile.hasUnit())
                            tile.unitOnIt.damage(6, PHYSICAL);
                    }
                }

                var randomEmptyTile = Battlefield.getRandomTileWithNoUnit();
                var nTries = 0;
                while (randomEmptyTile != null && randomEmptyTile.hasDangerMarker() && nTries < 10) {
                    randomEmptyTile = Battlefield.getRandomTileWithNoUnit();
                    nTries++;   // To prevent very edge-cases
                }
                if (randomEmptyTile == null) {
                    Battlefield.encounterData.captainMarkedTiles = null;
                    return;
                }
                randomEmptyTile.addDangerMarker();
                Battlefield.encounterData.captainMarkedTiles = [randomEmptyTile];
            } else if (roundNumber % 4 == 3) {
                if (Battlefield.encounterData.captainMarkedTiles == null) return;
                if (Battlefield.encounterData.captainMarkedTiles.length == 0) return;
                final unitType: String = randomOf(['Pirate Bishop', 'Bucaneer', 'Pirate Peasant', 'Crewmate']);
                final tileToSpawn: TileSpace = Battlefield.encounterData.captainMarkedTiles[0];
                tileToSpawn.removeDangerMarker();
                var unitActor: Actor;
                if (tileToSpawn.hasNoUnit()) {
                    final unit = Battlefield.spawnEnemyOnTile(unitType, tileToSpawn);
                    unitActor = unit.actor;
                    if (unitActor == null) {
                        trace('WARNING: unitActor for when Stashton summons is null!');
                        return;
                    }
                    doDramaticEntry(unitActor, tileToSpawn);
                    doAfter(1000, () -> {
                        unit.say('Yaargh!!', 2);
                    });
                } else {
                    unitActor = U.createActor('UnitActor', 'Units4');
                    unitActor.setAnimation(unitType);
                    doDramaticEntry(unitActor, tileToSpawn);
                    doAfter(1000, () -> {
                        if (tileToSpawn.unitOnIt != null) {
                            tileToSpawn.unitOnIt.damage(5, PHYSICAL);
                        }
                        SpecialEffectsFluff.doFlinchAnimation(unitActor, () -> {
                            if (unitActor != null && unitActor.isAlive()) {
                                recycleActor(unitActor);
                            }
                        });
                    });
                }

                
            }
        });
    
    }
    public static function enableSomnium() {
        final darkness = new ImageX('Images/Other/SomniumDarkness.png', 'Darkness');
        darkness.centerOnScreen();
        Battlefield.addOnRoundEndEvent(function(roundNumber) {
            for (unit in Battlefield.getAllAlivePlayerUnits()) {
                final isNearMagicCandle = unit.getNeighborUnits(true).filter(u -> u.name == 'Magic Candles').length > 0;
                if (isNearMagicCandle == false) {
                    playAudio('CurseAudio');
                    unit.playEffect('Implosion', 700);
                    unit.damage(5, DARK);
                }
            }
        });
    }

    static function turn(actor: Actor, ?isInstant = false, ?callback: Void -> Void) {
        actor.growTo(-1, 1, if (isInstant) 0 else 0.25, Easing.expoOut);
        if (isInstant == false && callback != null)
            doAfter(250, callback);
    }
    static function unturn(actor: Actor, ?isInstant = false, ?callback: Void -> Void) {
        actor.growTo(1, 1, if (isInstant) 0 else 0.25, Easing.expoOut);
        if (isInstant == false && callback != null)
            doAfter(250, callback);
    }
}








class BattlefieldEncounterDatabase
{
	public static var encountersByName	: Map<String, BattlefieldEncounter>;
	public static var encountersById	: Array<BattlefieldEncounter>;
    public static var usedEncounters    : Map<BattlefieldEncounter, Bool> = [];  // An encounter will exists here if it has already been used for a node

	public static function get(?id : Int, ?name : String) {
		if (id == null && name == null) throwAndLogError('Null id and name given to BattlefieldEncounterDatabase.get...');
		if (id != null && (id < 0 || id >= encountersById.length)) throwAndLogError('No encounter with id ${id} found');
		if (name != null && !encountersByName.exists(name)) throwAndLogError('No encounter with name ${name} exists.');
		if (id != null) {
			return encountersById[id];
		} else {
			return encountersByName[name];
		}
    }
    
	public static function load(){
		// trace('Loading encounters...');
		encountersByName = new Map<String, BattlefieldEncounter>();
		encountersById	= [];
		//var encounters : Array<Dynamic> = readJSON("Databases/BattlefieldEncounters.json");	// Array of Item
        var encounters: Array<Dynamic> = BattlefieldEncounterDatabase_Encounters.encounters;
		for (i in encounters) {
			var enc = BattlefieldEncounter.createFromDynamic(i);
			enc.id	= encountersById.length;
			encountersById.push(enc);
			encountersByName.set(enc.name, enc);
			// trace('Loaded encounter "${encountersByName[enc.name].name}"');
		}
	}


    static function isUsed(encounter: BattlefieldEncounter) return usedEncounters.exists(encounter);
    static function addToUsed(encounter: BattlefieldEncounter) { usedEncounters[encounter] = true; }
    public static function exists(encounterName: String) return encountersByName.exists(encounterName);

    public static function getRandomNonUsedFrom(encounters: Array<BattlefieldEncounter>) {
        if (encounters.length == 0) return null;
        var foundEncounter = encounters[randomIntBetween(0, encounters.length - 1)];
        var nTries = 0;
        while (isUsed(foundEncounter) && nTries < 10) {
            foundEncounter = encounters[randomIntBetween(0, encounters.length - 1)];
            nTries++;
        }
        if (nTries == 10) Log.goAndTrace('WARNING: Could not find a non-used encounter!');
        return foundEncounter;
    }
    public static function getRandomEncounterOfLevel(level: Int) {
        final availableEncounters = encountersById.filter(enc -> enc.level == level);
        return getRandomNonUsedFrom(availableEncounters);
    }
    public static function getRandomEncounterOfLevelWithoutFlag(level: Int, flag: String) {
        final availableEncounters = encountersById.filter(enc -> enc.level == level && enc.flags.indexOf(flag) == -1);
        return getRandomNonUsedFrom(availableEncounters);
    }
    public static function getRandomEncounterOfLevelWithFlag(level: Int, flag: String) {
        var availableEncounters = encountersById.filter(enc -> enc.level == level);
        availableEncounters = availableEncounters.filter(enc -> enc.flags.indexOf(flag) != -1);
        return getRandomNonUsedFrom(availableEncounters);
    }
    public static function getRandomEncounterWithFlag(flag: String) {
        var availableEncounters = encountersById.filter(enc -> enc.flags.indexOf(flag) != -1);
        return getRandomNonUsedFrom(availableEncounters);
    }
    public static function getRescueEncounters() {
        return [
            get('Knight Rescue Mission'),
            get('Ranger Rescue Mission'),
            get('Mage Rescue Mission')
        ];
    }

    public static function isShorthand(shorthandName: String) return BattlefieldEncounterDatabase_Encounters.tileShorthands.exists(shorthandName);
    public static function getShorthandMeaning(shorthandName: String) return BattlefieldEncounterDatabase_Encounters.tileShorthands[shorthandName];

    public static function getTutorialGoblinDialogue() return BattlefieldEncounterDatabase_Encounters.getTutorialGoblinDialogue();
    public static function getTutorialCrystalDialogue() return BattlefieldEncounterDatabase_Encounters.getTutorialCrystalDialogue();

    
}