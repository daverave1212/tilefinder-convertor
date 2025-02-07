

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

import U.*;
using U;
using Lambda;

import scripts.Constants.*;
import scripts.UnitTemplate.*;
import scripts.SpecialEffectsFluff.*;

class UnitsDatabase_Units {
    public static var database: Array<Dynamic> = [

        // Obstacles
        {   name: "Treasure Chest",
            description: 'Break it for extra loot.',
            isObstacle: true,
            neverFlip: true,
            stats: { health: 20, armor: 25 },
            tags: [UNIT_WOOD, NEUTRAL_WITH_HEALTH_BAR],
            resistances: { fire: 1.5, shock: 0.5 },
            afterDeath: function(self: Unit, tile: TileSpace) {
                final encounterLevel = Battlefield.currentBattlefieldEncounter.level;
                Battlefield.chest.isDead = true;
                Battlefield.chest.goldDropped = int(randomIntBetween(12, 17) * encounterLevel * 0.5);
                Battlefield.chest.itemDroppedName = ItemsDatabase.getRandomConsumableOfLevel(encounterLevel).name;
                SpecialEffectsFluff.doItemToInventoryAnimation('Icons/Gold.png', tile.getX(), tile.getY());
                doAfter(450, () -> {
                    final imagePath = ItemsDatabase.get(Battlefield.chest.itemDroppedName).imagePath;
                    final actor = SpecialEffectsFluff.doItemToInventoryAnimation(imagePath, tile.getX(), tile.getY());
                    actor.moveToBottom();
                });
            },
            onRoundEnd: (self: Unit) -> {
                SpecialEffectsFluff.doChestJumpAnimation(self.actor);
            },
            audio: {
                onHit: 'CrateHitAudio',
                onDeath: 'CrateDeath2Audio'
            }
        },
        {   name: "Boulder",
            description: 'Has a ton of armor and HP.',
            isObstacle: true,
            isLarge: true,
            stats: { health: 45, armor: 60 },
            actorOffsetY: 5,
            tags: [UNIT_STONE],
            audio: {
                onHit:   'RockHitAudio',
                onDeath: 'RockDeathAudio'
            }
        },
        {   name: "Anchor",
            description: "It's an anchor, I don't know.",
            isObstacle: true,
            stats: { health: 30, armor: 30 },
            tags: [UNIT_STONE],
        },
        {   name: "Rock Blockage",
            description: 'Rock solid.',
            isObstacle: true,
            isLarge: true,
            stats: { health: 80, armor: 60 },
            actorOffsetY: 5,
            tags: [UNIT_STONE],
            audio: {
                onHit:   'RockHitAudio',
                onDeath: 'RockDeathAudio'
            }
        },
        {   name: "Log",
            description: 'Contrary to it\'s name, this is not used to output messages.',
            isObstacle: true,
            isLarge: true,
            stats: { health: 20, armor: 10 },
            resistances: { fire: 1.5, shock: 0.5 },
            tags: [UNIT_WOOD],
            audio: {
                onHit: 'CrateHitAudio',
                onDeath: 'CrateDeath2Audio'
            }
        },
        {   name: "Table",
            description: 'Pirates play Ping Pong on it.',
            isObstacle: true,
            isLarge: true,
            stats: { health: 15, armor: 0 },
            resistances: { fire: 1.5, shock: 0.5 },
            tags: [UNIT_WOOD],
            audio: {
                onHit: 'CrateHitAudio',
                onDeath: 'CrateDeath2Audio'
            }
        },
        {   name: "Rock",
            description: 'My least favorite music genre.',
            isObstacle: true,
            stats: { health: 45, armor: 60 },
            actorOffsetY: 5,
            tags: [UNIT_STONE],
            audio: {
                onHit:   'RockHitAudio',
                onDeath: 'RockDeathAudio'
            }
        },
        {   name: "Stones",
            description: 'They will not break my soul.',
            isObstacle: true,
            stats: { health: 80, armor: 60 },
            actorOffsetY: 5,
            tags: [UNIT_STONE],
            audio: {
                onHit:   'RockHitAudio',
                onDeath: 'RockDeathAudio'
            }
        },
        {   name: "Crate",
            description: 'It does not drop loot. Stop farming these!',
            isObstacle: true,
            stats: { health: 10, armor: 0 },
            resistances: { fire: 1.5, shock: 0.5 },
            tags: [UNIT_WOOD],
            audio: {
                onHit: 'CrateHitAudio',
                onDeath: 'CrateDeath2Audio'
            }
        },
        {   name: "Gravestone",
            description: 'Gravestones, meet the Gravestones...',
            isObstacle: true,
            stats: { health: 20, armor: 20 },
            tags: [UNIT_STONE],
            audio: {
                onHit:   'RockHitAudio',
                onDeath: 'RockDeathAudio'
            }
        },
        {   name: "Barrel",
            description: 'DO A BARREL tumble.',
            isObstacle: true,
            stats: { health: 25, armor: 0 },
            resistances: { fire: 1.5, shock: 0.5 },
            tags: [UNIT_WOOD],
            audio: {
                onHit:   'BubakHitAudio',
                onDeath: 'BubakDeathAudio'
            }
        },
        {   name: "Bush",
            description: 'Heh.',
            isObstacle: true,
            stats: { health: 2, armor: 0 },
            tags: [UNIT_FLAMABLE],
            audio: {
                onHit:   'BushAudio',
                onDeath: 'BushAudio'
            }
        },
        {   name: "Hay",
            description: 'Ho, let\'s go! Folklore, rock \'n\' roll!',
            isObstacle: true,
            stats: { health: 2, armor: 0 },
            actorOffsetY: 5,
            tags: [UNIT_FLAMABLE],
            audio: {
                onHit:   'BushAudio',
                onDeath: 'BushAudio'
            }
        },
        {   name: "Vase",
            description: '...de sange? Nah.',
            isObstacle: true,
            stats: { health: 1, armor: 0, mana: 8 },
            tags: [UNIT_STONE],
            audio: {
                onHit:   'CrystalHitAudio',
                onDeath: 'CrystalDeathAudio'
            },
            onDeath: (self: Unit) -> {
                if (self.tileOn.hasTrap() == false)
                    Trap.createFromTemplateByName('Acid Trap', self.tileOn);
                for (i in 0...3) {
                    final randomTile = self.tileOn.getRandomNeighbor(true);
                    if (randomTile.hasTrap() == false) {
                        Trap.createFromTemplateByName('Acid Trap', randomTile);
                        if (randomTile.hasUnit() && !randomTile.unitOnIt.hasTag(IMMUNE_TO_ACID_TRAP)) {
                            self.damageUnit(randomTile.unitOnIt, 2, PURE);
                        }
                    }
                }
            }
        },
        {   name: "Pumpkin",
            description: 'Transforms into a Pumpling when hit.',
            isObstacle: true,
            stats: { health: 1, armor: 0, initiative: 1 },
            tags: [UNIT_FLAMABLE],
            audio: {
                onHit:   'PumplingHitAudio',
                onDeath: 'PumplingDeathAudio'
            },
            actorOffsetY: 1,
            afterDeath: (self: Unit, tileWhereDied: TileSpace) -> {
                Battlefield.spawnUnit('Pumpling', tileWhereDied.getI(), tileWhereDied.getJ(), ENEMY);
            }
        },
        {   name: "Explosive Barrel",
            description: 'WHAT DO YOU THINK THIS DOES IF YOU BREAK IT!?',
            tags: [UNIT_FLAMABLE],
            isObstacle: true,
            stats: { health: 1, armor: 0 },
            afterDeath: (self: Unit, tileWhereDied: TileSpace) -> {
                Battlefield.preventNextTurnOnce();  // To finish chaining all cool animations
                SpecialEffectsFluff.doExplosionEffect(self.getXCenter(), self.getYCenter());
                final neighborUnits = tileWhereDied.getNeighbors(true).filter(tile -> tile.hasUnit()).map(tile -> tile.unitOnIt);
                doAfter(250, () -> {
                    for (unit in neighborUnits) {
                        if (unit.isDead == false) unit.damage(12, PURE);
                    }
                });
                doAfter(1000, () -> {
                    if (Battlefield.didPreventNextTurn) {   // If the next turn was prevented
                        Battlefield.nextTurn();             // Trigger next turn
                    } else {
                        Battlefield.unpreventNextTurn();    // Else, continue normally
                    }
                });
            },
            audio: {}   // Audio included in explosion effect
        },
        {   name: 'Spike Barricade',        // Hardcoded; deals 2 damage when moving in a tile near the barricade
            description: 'Damages you if you land next to it.',
            isObstacle: true,
            stats: { health: 10 },
            tags: [UNIT_WOOD],
            actorOffsetY: 7,
            audio: {
                onHit: 'CrateHitAudio',
                onDeath: 'CrateDeath2Audio'
            }
        },
        {   name: "Ice Cube",
            description: 'Today was a good day.',
            isObstacle: true,
            stats: { health: 20, armor: 0, mana: 8 },
            tags: [UNIT_ICE],
            audio: {
                onHit:   'RockHitAudio',
                onDeath: 'RockDeathAudio'
            }
        },
        {   name: "Magic Candles",
            description: 'Stay near it to prevent the Somnium damaging you.',
            isObstacle: true,
            stats: { health: 12, armor: 0, mana: 8 },
            resistances: { fire: 1.5, shock: 0.5 },
            tags: [UNIT_WOOD],
            onSpawn: function(self: Unit) {
                self.addAttachment('Magic Candles Light');
            }
        },

        // Other
        {   name: 'Fox',
            description: 'UwU',
            stats: {
                health: 15,
                mana: 5,
                damage: 4,
                speed: 3,
                manaRegeneration: 5,
                initiative: 98
            },
            damageVariation: 2,
            tags: [ANIMAL],
            spells: ['Move', 'Melee Attack'],
            audio: {
                onHit:   'FoxHitAudio',
                onDeath: 'FoxDeathAudio'
            },
            onCombatStart: function(self: Unit) {
                final ranger = Battlefield.getUnitByName('Ranger');
                self.setMaxHealth(int(ranger.stats.health * 0.35));
                self.stats.damage += int(ranger.stats.damage * 0.35);
                self.health = self.stats.health;
                self.updateBars();
            }
        },
        {   name: 'Cobra',
            description: 'Moves 2 tiles diagonally. Immune to Acid Trap. Attacks inflict a PURE BLEED.',
            stats: {
                health: 12,
                mana: 5,
                damage: 1,
                speed: 3,
                manaRegeneration: 5,
                initiative: 98
            },
            damageVariation: 2,
            tags: [IMMUNE_TO_ACID_TRAP, ANIMAL],
            spells: ['Diagonal Move', 'Poison Attack'],
            audio: {
                onHit:   'CobraShotThrowAudio',
                onDeath: 'CobraShotThrowAudio'
            },
            onSpawn: function(self: Unit) {
                final ranger = Battlefield.getUnitByName('Ranger');
                var cobraHP = int(ranger.stats.dodge * 0.5);
                if (cobraHP <= 0) cobraHP = 1;
                self.setMaxHealth(cobraHP);
                self.stats.spellPower = ranger.stats.spellPower;
                self.amplifications = ranger.amplifications;
                self.health = self.stats.health;
                self.updateBars();
            }
        },
        {   name: 'Goblin',
            description: 'Protect the goblin! If he dies, you get no loot!',
            stats: {
                health: 42,
                damage: 0,
                speed: 1,
                dodge: 35,
                initiative: 98
            },
            afterDeath: (self: Unit, tile: TileSpace) -> {
                
            },
            onCombatStart: function(self: Unit) {   // Has the average of player characters HP / 2
                final goblinHP = int(arraySumInt(Player.characters.map(c -> c.stats.health)) / Player.characters.length * 0.66667);
                trace('Got HP as: ${goblinHP}');
                self.setMaxHealth(goblinHP);
                self.health = goblinHP;
                self.updateBars();
            },
            spells: ['Move', 'Player Owned'],
            audio: {
                onHit: 'GoblinHitAudio',
                onDeath: 'GoblinDeathAudio'
            }
        },
        {   name: 'Exploding Crystal',
            description: 'If this dies, it explodes, damaging everything for 35% of their max HEALTH.',
            stats: {
                health: 42,
                speed: 1,
                initiative: 98
            },
            tags: [IMMUNE_TO_STUN],
            afterDeath: function(self: Unit, tile: TileSpace) {
                final bigExplosion = doExplosionEffect(self.getXCenter(), self.getYCenter());
                bigExplosion.growTo(3, 3, 0, Easing.linear);
                for (unit in Battlefield.getAllAliveUnits()) {
                    final damage = int(Math.min(unit.stats.health * 0.35, 30));
                    self.damageUnit(unit, damage, PHYSICAL);
                }
            },
            onSpawn: function(self: Unit) {   // Has the average of player characters HP / 2
                final crystalHP = int((arraySumInt(Player.characters.map(c -> c.stats.health)) / Player.characters.length) * 0.67666);
                self.setMaxHealth(crystalHP);
                self.health = crystalHP;
                self.updateBars();
            },
            spells: ['Diagonal Move', 'Player Owned'],
            audio: {
                onHit:   'CrystalHitAudio',
                onDeath: 'CrystalDeathAudio'
            }
        },

        // Mercenaries
        {   name: 'Soldier',
            description: 'No special abilities or resistances.',
            animationUsed: 'Guard',
            isFlippedHorizontally: true,
            stats: {
                health: 20,
                damage: 2,
                speed: 2
            },
            damageVariation: 1,
            spells: ['Move', 'Melee Attack (Monster)', 'End Turn'],
            audio: {
                onHit: 'Human3Audio',
                onDeath: 'Human1Audio'
            }
        },
        {   name: 'Effigy',
            description: 'Has a special assortment of abilities.',
            stats: {
                health: 21,
                mana: 12,
                speed: 0,
                dodge: 10,
                initiative: 2
            },
            spells: ['Restore Mana', 'Offer Block', 'Push All Away'],
            audio: {
                onHit:   'BubakHitAudio',
                onDeath: 'BubakDeathAudio'
            }
        },

        // Monsters
        // Tutorial
        {   name: "Patrolling Guard",
            description: 'No special abilities or resistances.',
            stats: {
                health: 12,
                damage: 1,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            tags: [HUMAN],
            damageVariation: 1,
            spells: ['Move', 'Melee Attack (Monster)'],
            audio: {
                onHit: 'Human3Audio',
                onDeath: 'Human1Audio'
            }
        },
        {   name: "Guard With Socks",
            description: 'He wears socks, obviously.',
            stats: {
                health: 20,
                damage: 1,
                armor: 0,
                crit: 0,
                dodge: 25,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            tags: [HUMAN],
            damageVariation: 1,
            spells: ['Move', 'Melee Attack (Monster)'],
            audio: {
                onHit: 'Human3Audio',
                onDeath: 'Human1Audio'
            }
        },
        
        // Level 1
        {   name: "Peasant",
            thumbnailPath: 'auto',
            description: 'Tries to ROOT you every 3 to 7 turns (3 range). On death, drops a Bear Trap.',
            stats: {
                health: 21,
                damage: 1,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: -3,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 1,
            tags: [HUMAN],
            damageVariation: 1,
            combatStartQuotes: ["Ready to work."],
            spells: ['Move', 'Throw Net (Enemy)', 'Melee Attack (Monster)'],
            audio: {
                onHit: 'PeasantHitAudio',
                onDeath: 'PeasantDeathAudio'
            },
            onCombatStart: function(self: Unit) {
                putThrowNetOnRandomCooldown(self);
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (tileWhereDied.hasTrap() == false) {
                    Battlefield.spawnTrap('Bear Trap', tileWhereDied);
                }
            },
            onTurnStart: function(self: Unit) {
                addAttachmentIfWillThrowNetNextTurn(self);
                
            }
        },
        {   name: "Rooter",
            thumbnailPath: 'auto',
            description: '',
            stats: {
                health: 21,
                damage: 1,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: -3,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 1,
            damageVariation: 1,
            combatStartQuotes: ["Ready to work."],
            spells: ['Move', 'Throw Net (Enemy No CD)'],
            audio: {
                onHit: 'PeasantHitAudio',
                onDeath: 'PeasantDeathAudio'
            },
            onCombatStart: function(self: Unit) {},
            onTurnStart: function(self: Unit) {}
        },
        {   name: "Crossbow Guard",
            thumbnailPath: 'auto',
            description: 'Will not shoot unless it has line of sight.',
            stats: {
                health: 15,
                damage: 2,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 1,
            tags: [HUMAN],
            ai: { type: 'shooter' },
            damageVariation: 2,
            spells: ['Move', 'Shoot Arrow (Enemy)'],
            audio: {
                onHit: 'Human3Audio',
                onDeath: 'Human1Audio'
            }
        },
        {   name: "Molotov Peasant",
            thumbnailPath: 'auto',
            description: 'Throws a molotov that leaves Fire and ignites nearby Oil.',
            stats: {
                health: 15,
                damage: 2,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 4,
                mana: 5, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 1,
            resistances: { fire: 0.70 },
            tags: [FEARFUL, HUMAN],
            ai: { type: 'shooter' },
            damageVariation: 1,
            combatStartQuotes: ["Burn, baby, burn!"],
            spells: ['Move', 'Molly'],
            audio: {
                onHit: 'PeasantHitAudio',
                onDeath: 'PeasantDeathAudio'
            }
        },
        {   name: "Scrub Scout",
            description: '',
            stats: {
                health: 13,
                damage: 2,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 1,
            tags: [HUMAN],
            damageVariation: 1,
            combatStartQuotes: ["Heh... what do we have here?"],
            spells: ['Move', 'Melee Attack Diagonal']
        },
        {   name: "Little Scout",
            description: 'Shoots a delayed pebble in a line.',
            stats: {
                health: 2,
                damage: 2,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0,
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 1,
            tags: [HUMAN],
            damageVariation: 0,
            sayOffsetX: 1,
            sayOffsetY: 15,
            combatStartQuotes: ["Sir, yes sir!"],
            spells: ['Move', 'Slingshot'],
            audio: {
                onHit: 'Child2Audio',
                onDeath: 'Child1Audio'
            }
        },
        {   name: "Evil Paprika",
            description: 'Spikes deal DARK damage to all units in a line. Leaves Toxic Fog when it dies.',
            stats: {
                health: 28,
                damage: 5,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 1,
            resistances: { fire: 1.35 },
            tags: [FEARFUL, ENEMY_PLANT],
            combatStartQuotes: ["Bleaaghh!!"],
            spells: ['Move', 'Spike Rush'],
            onDeath: (self: Unit) -> {
                Battlefield.spawnTrap('Toxic Fog', self.getI(), self.getJ());
            },
            audio: {
                onHit:   'EvilPaprikaHitAudio',
                onDeath: 'EvilPaprikaDeathAudio'
            }
        },
        {   name: "Serfmaster",
            thumbnailPath: 'auto',
            description: 'Stuns all units caught every 4 turns.',
            stats: {
                health: 37,
                damage: 2,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: -2,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 1
            },
            level: 1,
            tags: [HUMAN],
            sayOffsetX: -4,
            isLarge: true,
            spells: ['Move', 'Fat Slam', 'Sumo Wave', 'End Turn'],
            ai: {
                type: 'advancer',
                spellSequence: ['Fat Slam', 'Fat Slam', 'Fat Slam', 'Sumo Wave', 'End Turn']
            },
            audio: {
                onHit: 'PeasantHitAudio',
                onDeath: 'PeasantDeathAudio'
            }
        },
        {   name: 'Bishop',
            description: 'Heals allies for 7. ',
            stats : {
                health : 18,
                damage : 1,
                dodge : 10,
                spellPower : 1,
                mana: 7,
                initiative: 0,
                speed : 2
            },
            level: 1,
            resistances: { dark: 1.35 },
            tags: [HUMAN],
            ai: { type: 'shooter' },
            spells: ["Move", "Healing Word", 'Melee Attack (Monster)'],
            audio: {
                onHit: 'PriestHitAudio',
                onDeath: 'PriestDeathAudio'
            }
        },
        {   name: 'Pumpling',
            description: 'Explodes when it dies, INFECTING a random spell from nearby units.',
            stats: {
                health: 5,
                damage: 2,
                speed: 2,
                mana: 2
            },
            resistances: {
                dark: 0.4
            },
            level: 1,
            tags: [ENEMY_PLANT],
            onStuck: (self: Unit, callback: Void -> Void) -> {
                self.say('* Pumpling goes dormant *');
                final i = self.getI();
                final j = self.getJ();
                final centerPoint = new Point(self.getXCenter(), self.getYCenter());
                Effects.playParticleAndThen(centerPoint, centerPoint, 'Smoke', 150, () -> {});
                self.remove();
                Battlefield.spawnUnit('Pumpkin', i, j, NEUTRAL);
                callback();
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (self.mana <= 0) return;
                final affectedTiles = tileWhereDied.getNeighbors();
                for (tile in affectedTiles) {
                    tile.flashTargeted();
                    tile.playEffect('Spores', 500);
                    if (tile.hasUnit()) {
                        tile.unitOnIt.infectRandomUninfectedSpell();
                    }
                }
            },
            damageVariation: 1,
            spells: ['Move', 'Melee Attack (Monster)'],
            audio: {
                onHit:   'PumplingHitAudio',
                onDeath: 'PumplingDeathAudio'
            }
        },


        // Level 2
        {   name: 'Wolf',
            description: 'Moves in the shape of an L.',
            stats: {
                health: 28,
                damage: 3,
                speed: 3,
                initiative: 2
            },
            level: 2,
            tags: [ANIMAL],
            ai: { type: 'horse' },
            damageVariation: 1,
            combatStartQuotes: ['Grrr...', 'Woof...'],
            spells: ['Horse Move', 'Melee Attack (Monster)'],
            audio: {
                onHit:   'WolfHitAudio',
                onDeath: 'WolfDeathAudio'
            }
        },
        {   name: 'Hell Hound',
            description: 'Moves in the shape of L.',
            stats: {
                health: 41,
                damage: 3,
                speed: 3,
                initiative: 2
            },
            tags: [ANIMAL],
            level: 2,
            resistances: {
                dark: 0.7,
                fire: 0.7,
                cold: 1.35
            },
            ai: { type: 'horse' },
            damageVariation: 3,
            combatStartQuotes: ['Grrr...', 'Woof...'],
            spells: ['Horse Move', 'Melee Attack (Monster)'],
            audio: {
                onHit:   'WolfHitAudio',
                onDeath: 'WolfDeathAudio'
            }
        }, 
        {   name: "Guard",
            description: 'Attacks have 2 range. \n Gains 1 BLOCK whenever a player unit moves. Casts Block every 2 turns.',
            stats: {
                health: 22,
                damage: 3,
                armor: 35,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 7,
                manaRegeneration: 0,
                speed: 2
            },
            level: 2,
            tags: [HUMAN],
            damageVariation: 1,
            combatStartQuotes: ["Don't move!", "Stay where you are!"],
            ai: {
                spellSequence: ['Spear Thrust', 'Block (Monster)']
            },
            onCombatStart: (self: Unit) -> {
                Battlefield.addOnUnitMoveEvent((unitThatMoved: Unit, previousTile: TileSpace) -> {
                    if (unitThatMoved.isPlayerCharacter()) {
                        self.block++;
                        self.updateBars();
                    }
                });
            },
            spells: ['Move', 'Spear Thrust', 'Block (Monster)'],
            audio: {
                onHit: 'Human3Audio',
                onDeath: 'Human1Audio'
            }
        },
        {   name: 'Highwayman',
            description: 'Shoots 2 tiles (delayed). Once in a while, targets a player unit and shoots 4 times. There must be a way to mitigate it...',
            stats : {
                health : 30,
                damage : 4,
                mana: 5,
                dodge : 0,
                spellPower : 0,
                initiative: 3,
                speed : 2
            },
            level: 2,
            damageVariation: 1,
            tags: [HUMAN],
            spells: ["Move", "Shoot Location", 'Shoot Target'],
            ai: {
                spellSequence: ['Shoot Location', 'Shoot Location', 'Shoot Target'],
                overrideSpellSequence: function(self: Unit, currentAISpellIndex: Int): String {
                    final otherHighwaymen = Battlefield.unitsOnBattlefield.filter(u -> u.isDead == false && (u.name == 'Highwayman' || u.name == 'Darkwayman' || u.name == 'Bucaneer') && u != self);
                    for (highwayman in otherHighwaymen) {
                        if (highwayman.customData.strings['isTargeting'] == 'yes')
                            return 'Shoot Location';
                    }
                    if (currentAISpellIndex == 2 && self.mana == 0) return 'Shoot Location';
                    return null;
                }
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (self.customData.strings['isTargeting'] == 'yes') {
                    if (self.aiData == null) return;
                    if (self.aiData.targetedUnit == null) return;
                    final target: Unit = self.aiData.targetedUnit;
                    if (target.isDead) return;
                    target.removeAttachment('Targeted');
                }
            },
            onCombatStart: function(self: Unit) {
                self.customData.strings['isTargeting'] = 'no';
            },
            combatStartQuotes: ['Give us all your gold!', 'All your gold are belong to us!'],
            audio: {
                onHit:   'BanditHitAudio',
                onDeath: 'BanditDeathAudio'
            }
        },
        {   name: "Bandit Peasant",
            thumbnailPath: 'auto',
            description: 'Tries to ROOT you every 3 to 7 turns (3 range). On death, drops a Bear Trap.',
            stats: {
                health: 26,
                damage: 3,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: -3,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 2,
            tags: [HUMAN],
            damageVariation: 1,
            combatStartQuotes: ["Heh... we'll take your stuff!"],
            spells: ['Move', 'Throw Net (Enemy)', 'Melee Attack (Monster)'],
            audio: {
                onHit: 'PeasantHitAudio',
                onDeath: 'PeasantDeathAudio'
            },
            onCombatStart: function(self: Unit) {
                putThrowNetOnRandomCooldown(self);
            },
            onTurnStart: function(self: Unit) {
                addAttachmentIfWillThrowNetNextTurn(self);
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (tileWhereDied.hasTrap() == false) {
                    Battlefield.spawnTrap('Bear Trap', tileWhereDied);
                }
            }
        },
        {   name: "Rat",
            description: 'Attacks diagonally. Breaks vases. Gains +1 DAMAGE when an ally dies. Immune to Acid.',
            stats: {
                health: 25,
                damage: 3,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 2,
            damageVariation: 1,
            sayOffsetY: 6,
            tags: [IMMUNE_TO_ACID_TRAP, ANIMAL],
            spells: ['Move', 'Melee Attack Diagonal', 'Prop Breaker'],
            resistances: { dark: 0.7 },
            onCombatStart: (self: Unit) -> {
                Battlefield.addOnUnitDeathEvent((killer: Unit, dyingUnit: Unit) -> {
                    if (dyingUnit.owner == ENEMY && self.isDead == false && self != dyingUnit) {
                        self.addBuff(new Buff('Damage Boost', 99, { damage: 1 }));
                        U.flashRed(self.actor, 200);
                        self.scrollRed('+1 DMG');
                        doAfter(750, () -> {
                            self.say('Scrrrr!!', 1.5);
                        });
                    }
                });
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (tileWhereDied.hasTrap() == false) {
                    Battlefield.spawnTrap('Oil', tileWhereDied);
                }
            },
            audio: {
                onHit:   'RatHitAudio',
                onDeath: 'RatDeathAudio'
            }
        },
        {   name: 'Vampire Lord',
            thumbnailPath: 'Icons/Small/Count Spatula.png',
            description: '',
            stats: {
                health: 40,
                damage: 6,
                speed: 3,
                initiative: 2
            },
            level: 2,
            ai: { type: 'horse' },
            damageVariation: 1,
            afterDeath: (self: Unit, tile: TileSpace) -> {
                Battlefield.killedVampireLord = true;
            },
            audio: {
                onHit: 'VampireHit2Audio',
                onDeath: 'VampireDeathAudio'
            },
            spells: ['Horse Move', 'Melee Attack (Monster)']
        }, 
        {   name: 'Bubak',
            description: 'Heals its allies around for 5. On death, its allies gain 10% DODGE and 10% CRIT.',
            stats: {
                health: 31,
                damage: 3,
                armor: 10,
                mana: 10,
                speed: 0
            },
            level: 2,
            ai: { type: 'canon' },
            damageVariation: 1,
            spells: ['Damned Aura'],
            tags: [IMMUNE_TO_STUN, FEARFUL],
            resistances: { fire: 1.35, dark: 0.7 },
            onDeath: (self: Unit) -> {
                for (enemy in Battlefield.getAllAliveEnemyUnits()) {
                    doAfter(randomIntBetween(0, 100), () -> playAudio('CrowEchoedAudio'));
                    enemy.addBuff(new Buff('Crow Bless', 9, {
                        crit: 10,
                        dodge: 10,
                        manaRegeneration: 1
                    }));
                    Effects.playParticleAndThen(enemy.getCenterPoint(), enemy.getCenterPoint(), "Crow's Blessing", 1350);
                }
            },
            audio: {
                onHit:   'BubakHitAudio',
                onDeath: 'BubakDeathAudio'
            }
        },

        // Level 3
        {   name: "Canon",
            description: 'Shoots a canonball every 2 turns. Canon spelled with 1 n.',
            stats: {
                health: 20,
                damage: 11,
                armor: 50,
                crit: 0,
                dodge: 0,
                initiative: 8,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 0
            },
            level: 3,
            resistances: { shock: 1.5 },
            damageVariation: 4,
            tags: [IMMUNE_TO_STUN, FEARFUL],
            ai: {
                type: 'canon',
                spellSequence: ['End Turn', 'Shoot Canonball']
            },
            audio: {
                onDeath: 'BubakDeathAudio'
            },
            combatStartQuotes: ["*Squiggly squig*"],
            spells: ['Shoot Canonball', 'End Turn'],
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (tileWhereDied.hasTrap() == false) {
                    Battlefield.spawnTrap('Oil', tileWhereDied);
                }
            },
        },
        {   name: "Crewmate",
            thumbnailPath: 'auto',
            description: 'Enrages at half health. Then, every turn, gains +2 DAMAGE.',
            stats: {
                health: 50,
                damage: 2,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 3,
            tags: [HUMAN],
            sayOffsetX: 4,
            sayOffsetY: -5,
            combatStartQuotes: ["ARGGHH!"],
            spells: ['Move', 'Melee Attack (Monster)', 'Anchor'],
            audio: {
                onHit: 'PirateHitAudio',
                onDeath: 'PirateDeathAudio'
            },
            onCombatStart: function(self: Unit) {
                self.customData.strings['isEnraged'] = 'no';
            },
            onSpawn: function(self: Unit) {
                self.customData.strings['isEnraged'] = 'no';
            },
            afterTakingDamage: function(self: Unit, amount: Int) {
                if (self.health <= self.stats.health / 2)
                    if (self.customData.strings['isEnraged'] == 'no') {
                        self.customData.strings['isEnraged'] = 'yes';
                        self.removeSpell('Anchor');
                        self.addBuff(new Buff('Enrage', 99, {}, {
                            onTick: function(sameSelf: Unit) {
                                sameSelf.stats.damage += 2;
                                flashRed(sameSelf.actor, 250);
                                self.scrollRed('+2 DMG!');
                                self.actor.setAnimation('Crewmate Bloodied');
                                doAfter(750, () -> {
                                    final quote: String = randomOf([
                                        'YAHAHARGGH!!',
                                        'NOW I AM ANGRYYY!',
                                        'I SMELL BLOOOOOOOOD!!'
                                    ]);
                                    self.say(quote);
                                });
                            }
                        }));
                    }
            }
        },
        {   name: "Pirate Peasant",
            thumbnailPath: 'auto',
            description: 'Tries to ROOT you every 3 to 7 turns (3 range). On death, drops a Bear Trap.',
            stats: {
                health: 33,
                damage: 4,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: -3,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 3,
            tags: [HUMAN],
            damageVariation: 1,
            combatStartQuotes: ["Blood and plunder!"],
            spells: ['Move', 'Throw Net (Enemy)', 'Melee Attack (Monster)'],
            audio: {
                onHit: 'PeasantHitAudio',
                onDeath: 'PeasantDeathAudio'
            },
            onCombatStart: function(self: Unit) {
                putThrowNetOnRandomCooldown(self);
            },
            onTurnStart: function(self: Unit) {
                addAttachmentIfWillThrowNetNextTurn(self);
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (tileWhereDied.hasTrap() == false) {
                    Battlefield.spawnTrap('Bear Trap', tileWhereDied);
                }
            },
        },
        {   name: "Big Slime",
            thumbnailPath: 'auto',
            isLarge: true,
            description: 'Can summon Slimes. On death, splits into 2 Slimes.',
            stats: {
                health: 48,
                damage: 4,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 8,
                spellPower: 0,
                manaRegeneration: 0,
                speed: 1
            },
            level: 3,
            tags: [IMMUNE_TO_ACID_TRAP, ANIMAL],
            damageVariation: 1,
            resistances: { cold: 1.35 },
            combatStartQuotes: ["*SQUOSH SQUOSH*"],
            spells: ['Move', 'Spawn Slime', 'Melee Attack (Monster) (Pure)'],
            audio: {
                onHit: 'SlimeHitAudio',
                onDeath: 'SlimeDeathAudio'
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                final emptyNeighborTiles = tileWhereDied.getAvailableNeighbors();
                var s1: Unit = null;
                var s2: Unit = null;
                if (emptyNeighborTiles.length == 0) {
                    s1 = Battlefield.spawnEnemyOnTile('Slime', tileWhereDied);
                } else if (emptyNeighborTiles.length == 1) {
                    s1 = Battlefield.spawnEnemyOnTile('Slime', tileWhereDied);
                    s2 = Battlefield.spawnEnemyOnTile('Slime', emptyNeighborTiles[0]);
                } else {
                    shuffle(emptyNeighborTiles);
                    s1 = Battlefield.spawnEnemyOnTile('Slime', emptyNeighborTiles[0]);
                    s2 = Battlefield.spawnEnemyOnTile('Slime', emptyNeighborTiles[1]);
                }
                s1.playEffect('Green Smoke');
                if (s2 != null)
                    s2.playEffect('Green Smoke');
            }
        },
        {   name: "Slime",
            thumbnailPath: 'auto',
            description: 'Runs away from the player and spawns Acid Traps. On death, spawns 2 Small Slimes.',
            stats: {
                health: 22,
                damage: 4,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 4,
                mana: 5, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 3,
            resistances: { cold: 1.35 },
            damageVariation: 1,
            combatStartQuotes: ["*SQUASH SQUASH*"],
            spells: ['Move'],
            tags: [IMMUNE_TO_ACID_TRAP, ANIMAL],
            ai: { type: 'scared' },
            audio: {
                onHit: 'SlimeHitAudio',
                onDeath: 'SlimeDeathAudio'
            },
            onSpawn: (self: Unit) -> {
                Battlefield.addOnUnitMoveEvent(function(unitThatMoved: Unit, previousTile: TileSpace): Void {
                    if (unitThatMoved != self) return;
                    if (self.tileOn.hasTrap()) return;
                    if (previousTile == null)  return;
                    if (self.mana == 0) return;
                    Battlefield.spawnTrap('Acid Trap', previousTile);
                });
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                final emptyNeighborTiles = tileWhereDied.getAvailableNeighbors();
                var s1: Unit = null, s2: Unit = null;
                if (emptyNeighborTiles.length == 0) {
                    s1 = Battlefield.spawnEnemyOnTile('Small Slime', tileWhereDied);
                } else if (emptyNeighborTiles.length == 1) {
                    s1 = Battlefield.spawnEnemyOnTile('Small Slime', tileWhereDied);
                    s2 = Battlefield.spawnEnemyOnTile('Small Slime', emptyNeighborTiles[0]);
                } else {
                    shuffle(emptyNeighborTiles);
                    s1 = Battlefield.spawnEnemyOnTile('Small Slime', emptyNeighborTiles[0]);
                    s2 = Battlefield.spawnEnemyOnTile('Small Slime', emptyNeighborTiles[1]);
                }
                s1.playEffect('Green Smoke');
                if (s2 != null)
                    s2.playEffect('Green Smoke');
            }
        },
        {   name: "Small Slime",
            thumbnailPath: 'Icons/Small/Smol Slime.png',
            description: 'Squishy.',
            stats: {
                health: 15,
                damage: 2,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 2,
                mana: 0,
                spellPower: 0,
                manaRegeneration: 0,
                speed: 1
            },
            level: 3,
            damageVariation: 1,
            resistances: { cold: 1.35 },
            combatStartQuotes: ["*squish squish*"],
            tags: [IMMUNE_TO_ACID_TRAP, ANIMAL],
            spells: ['Move', 'Melee Attack (Monster) (Pure)'],
            audio: {
                onHit: 'SlimeHitAudio',
                onDeath: 'SlimeDeathAudio'
            }
        },
        {   name: "Blubber",
            description: 'Shoots bubbles that split into 2 more perpendicular bubbles; they damage enemies and shield fish. Blub blub...',
            stats: {
                health: 16,
                damage: 5,
                armor: 25,
                crit: 0,
                dodge: 0,
                initiative: 3,
                mana: 8, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 1
            },
            level: 3,
            tags: [ANIMAL],
            resistances: { cold: 0.5, fire: 1.45, shock: 1.4 },
            ai: { type: 'shooter' },
            onCombatStart: function(self: Unit) {
                self.block = 16;
                self.doesBlockDecay = false;
                self.updateBars();
            },
            damageVariation: 2,
            spells: ['Move', 'Bubble Fission'],
            audio: {
                onHit:   'BlubberHitAudio',
                onDeath: 'BlubberDeathAudio'
            }
        },
        {   name: "Reverse Mermaid",
            description: 'Shields itself. Shoots a bubble that consumes their shield to deal that much damage.',
            stats: {
                health: 35,
                damage: 1,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 10,
                manaRegeneration: 0,
                speed: 1
            },
            level: 3,
            tags: [ANIMAL],
            onTakingDamage: function(self: Unit, amount: Int) {
                if (self.isDead) return;
                if (self.block > 0) return;
                if (self.hasAttachment('Bubble Shield')) {
                    self.removeAttachment('Bubble Shield');
                }
            },
            resistances: { cold: 0.6, fire: 0.75, shock: 1.6 },
            damageVariation: 1,
            ai: { type: 'advancer' },
            combatStartQuotes: ["Blub blub?"],
            spells: ['Move', 'Bubble Blast', 'Bubble Shield'],
            onSpawn: (self: Unit) -> {
                self.doesBlockDecay = false;
            },
            audio: {
                onHit:   'ReverseMermaidHitAudio',
                onDeath: 'ReverseMermaidDeathAudio'
            }
        },
        {   name: "Spore Keeper",
            description: 'Infects a random player unit\'s spell. On death, spawns Oil.',
            stats: {
                health: 42,
                damage: 3,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 8, 
                spellPower: 10,
                manaRegeneration: 0,
                speed: 0
            },
            level: 3,
            tags: [ENEMY_PLANT],
            resistances: { dark: 0.55, fire: 1.45 },
            damageVariation: 1,
            spells: ['Spore Infection'],
            audio: {
                onHit:   'SporeKeeperHitAudio',
                onDeath: 'SporeKeeperDeathAudio'
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (tileWhereDied.hasTrap() == false) {
                    Battlefield.spawnTrap('Oil', tileWhereDied);
                }
            },
        },
        {   name: 'Mermaid',
            description: 'Buffs allies with +3 DAMAGE; attack them to dispell! Casts a long range ROOT every few turns.',
            stats: {
                health: 37,
                damage: 3,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 7,
                mana: 8, 
                spellPower: 10,
                manaRegeneration: 0,
                speed: 2
            },
            level: 3,
            tags: [FEARFUL],
            resistances: { cold: 0.7, shock: 1.3 },
            damageVariation: 2,
            onSpawn: function(self: Unit) {
                Battlefield.addAfterUnitTakingDamageEvent(function(source: Unit, victim: Unit, amount: Int, type: Int) {
                    if (victim.hasBuff('Charm')) {
                        victim.removeBuff('Charm');
                        victim.scrollGreen('CHARM OFF!');
                    }
                    if (victim.hasAttachment('Charm')) {
                        victim.removeAttachment('Charm');
                    }
                });
            },
            ai: { type: 'scared' },
            spells: ['Move', 'Throw Net (Mermaid)', 'Charm', 'Shoot Arrow (Enemy)'],
            audio: {
                onHit:   'MermaidHitAudio',
                onDeath: 'MermaidDeathAudio'
            },
            onCombatStart: function(self: Unit) {
                self.getSpell('Throw Net (Mermaid)').cooldownRemaining = randomIntBetween(3, 7);
            },
            onTurnStart: function(self: Unit) {
                if (self.getSpell('Throw Net (Mermaid)').cooldownRemaining == 2) {
                    self.addAttachment('Has Net', 24, 16);
                }
            }
        },
        {   name: 'Bucaneer',
            description: 'Shoots 2 tiles (delayed). Once in a while, targets a player unit and shoots 4 times. There must be a way to mitigate it...',
            stats : {
                health : 40,
                mana: 3,
                damage : 8,
                dodge : 0,
                spellPower : 0,
                initiative: 3,
                speed : 2
            },
            level: 3,
            spells: ["Move", "Shoot Location", 'Shoot Target'],
            damageVariation: 1,
            tags: [HUMAN],
            ai: {
                spellSequence: ['Shoot Location', 'Shoot Location', 'Shoot Target'],
                overrideSpellSequence: function(self: Unit, currentAISpellIndex: Int): String {
                    final otherHighwaymen = Battlefield.unitsOnBattlefield.filter(u -> u.isDead == false && (u.name == 'Highwayman' || u.name == 'Darkwayman' || u.name == 'Bucaneer') && u != self);
                    for (highwayman in otherHighwaymen) {
                        if (highwayman.customData.strings['isTargeting'] == 'yes')
                            return 'Shoot Location';
                    }
                    if (currentAISpellIndex == 2 && self.mana == 0) return 'Shoot Location';
                    return null;
                }
            },
            onCombatStart: function(self: Unit) {
                self.customData.strings['isTargeting'] = 'no';
            },
            combatStartQuotes: ['Give us all yer gold!', 'To Davie Jones\'s locker with ye!'],
            audio: {
                onHit:   'BanditHitAudio',
                onDeath: 'BanditDeathAudio'
            }
        },
        {   name: 'Pirate Bishop',
            description: 'Heals allies for 13.',
            stats : {
                health : 27,
                damage : 1,
                dodge : 10,
                spellPower : 2,
                mana: 8,
                speed : 2
            },
            level: 3,
            resistances: { dark: 1.3 },
            damageVariation: 1,
            ai: { type: 'shooter' },
            tags: [HUMAN],
            spells: ["Move", "Healing Word 2", 'Melee Attack (Monster)'],
            audio: {
                onHit:   'PriestHitAudio',
                onDeath: 'PriestDeathAudio'
            }
        },

        // Level 4
        {   name: 'Darkwayman',
            description: 'Shoots 2 tiles (delayed). Once in a while, targets a player unit and shoots 4 times. There must be a way to mitigate it...',
            stats : {
                health : 46,
                mana: 3,
                damage : 11,
                dodge : 0,
                spellPower : 0,
                initiative: 3,
                speed : 2
            },
            level: 4,
            resistances: { dark: 0.6, shock: 1.35 },
            damageVariation: 1,
            spells: ["Move", "Shoot Location", 'Shoot Target'],
            tags: [HUMAN],
            ai: {
                spellSequence: ['Shoot Location', 'Shoot Location', 'Shoot Target'],
                overrideSpellSequence: function(self: Unit, currentAISpellIndex: Int): String {
                    final otherHighwaymen = Battlefield.unitsOnBattlefield.filter(u -> u.isDead == false && (u.name == 'Highwayman' || u.name == 'Darkwayman' || u.name == 'Bucaneer') && u != self);
                    for (highwayman in otherHighwaymen) {
                        if (highwayman.customData.strings['isTargeting'] == 'yes')
                            return 'Shoot Location';
                    }
                    if (currentAISpellIndex == 2 && self.mana == 0) return 'Shoot Location';
                    return null;
                }
            },
            onCombatStart: function(self: Unit) {
                self.customData.strings['isTargeting'] = 'no';
            },
            combatStartQuotes: ['It will all be over soon...', 'The unseen gun is the deadliest.'],
            audio: {
                onHit:   'BanditHitAudio',
                onDeath: 'BanditDeathAudio'
            }
        },
        {   name: 'Wraith',
            description: 'Ghosts right through you. Every 3rd attack reduces your max HP by 3.',
            stats: {
                health: 50,
                damage: 10,
                speed: 4,
                mana: 10,
                dodge: 33,
                initiative: 1,
                armor: 35
            },
            level: 4,
            resistances: { dark: 0.35, fire: 2 },
            ai: { type: 'scared' },
            damageVariation: 3,
            audio: {
                onHit:   'WraithHitAudio',
                onDeath: 'WraithDeathAudio'
            },
            spells: ['Fly Move', 'Ghost Attack']
        },
        {   name: 'Natas',
            description: 'here\'s Natas!',
            stats: {
                health: 114,
                damage: 10,
                mana: 10,
                speed: 6,
                initiative: 1,
                armor: 25
            },
            level: 4,
            resistances: { cold: 1.5, fire: 0.5 },
            ai: { type: 'restless' },
            damageVariation: 3,
            spells: ['Flyer', 'Natas Move', 'Shotgun Blast'],
            audio: {
                onHit:   'NatasHitAudio',
                onDeath: 'NatasDeathAudio'
            },
            afterDeath: (self: Unit, tile: TileSpace) -> {
                final natas2 = UnitsDatabase.spawnUnitNicely('Natas (2)', tile, ENEMY);
                doAfter(2000, () -> {
                    natas2.say('Why, you little brats!', 3.5, -30);
                });
            },
        },
        {   name: 'Natas (2)',
            description: 'Here\'s still Natas! But angrier!',
            stats: {
                health: 80,
                damage: 8,
                speed: 6,
                initiative: 1,
                armor: 2
            },
            level: 4,
            resistances: { cold: 1.5, fire: 0.5 },
            ai: { type: 'restless', spellSequence: ['Throw Meat', 'Canon Blast'] },
            damageVariation: 3,
            spells: ['Flyer', 'Natas Move', 'Throw Meat', 'Canon Blast'],
            audio: {
                onHit:   'NatasHitAudio',
                onDeath: 'NatasDeathAudio'
            },
        },
        {   name: "Zombie",
            description: 'If the Zombie attacks, it will transform into a Zombie Peasant!',
            stats: {
                health: 36,
                damage: 7,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                speed: 1
            },
            level: 4,
            spells: ['Move', 'Chomp'],
            audio: {
                onHit:   'ZombieHitAudio',
                onDeath: 'ZombieDeathAudio'
            },
            tags: [IMMUNE_TO_STUN, HUMAN],
            onRoundEnd: function(self: Unit) {
                if (self.hasBuff('Transforming')) {
                    if (self.isSilenced()) {
                        self.doDownUpAnimation();
                        return;
                    }
                    final myTile = self.tileOn;
                    self.remove();
                    final myHealthDeficit = self.stats.health - self.health;
                    final zp = UnitsDatabase.spawnUnitNicely('Zombie Peasant', myTile, ENEMY);
                    zp.health -= myHealthDeficit;
                    zp.updateBars();
                }
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                // final aiData: Array<Dynamic> = self.aiData;
                // if (aiData == null || aiData.length == 0) return;
                // for (data in aiData) {
                //     final drainWho: Unit = data.drainWho;
                //     final drainWhat: String = data.drainWhat;
                //     final drainAmount: Int = data.drainAmount;
                //     drainWho.stats.set(drainWhat, drainWho.stats.get(drainWhat) + drainAmount);
                // }
                // final players: Array<Unit> = aiData.map(data -> data.drainWho);
                // final playersNoDupes: Array<Unit> = removeDuplicates(players);
                // for (unit in playersNoDupes) {
                //     if (unit.isDead) continue;
                //     unit.scrollGreen('Stats restored!');
                // }
            }
        },
        {   name: "Zombie Peasant",
            thumbnailPath: 'auto',
            description: 'Tries to ROOT you every 3 to 7 turns (3 range). On death, drops a Bear Trap.',
            stats: {
                health: 37,
                damage: 5,
                armor: 25,
                crit: 0,
                dodge: 0,
                initiative: -3,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 4,
            tags: [HUMAN, IMMUNE_TO_STUN],
            damageVariation: 1,
            combatStartQuotes: ["BLOOD AND BRAINS!!!"],
            spells: ['Move', 'Throw Net (Enemy)', 'Melee Attack (Monster)'],
            audio: {
                onHit: 'ZombieHitAudio',
                onDeath: 'ZombieDeathAudio'
            },
            onCombatStart: function(self: Unit) {
                putThrowNetOnRandomCooldown(self);
            },
            onTurnStart: function(self: Unit) {
                addAttachmentIfWillThrowNetNextTurn(self);
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (tileWhereDied.hasTrap() == false) {
                    Battlefield.spawnTrap('Bear Trap', tileWhereDied);
                }
            },
        },
        {   name: "Lantern Ghoul",
            description: 'Revives allies into Zombies.',
            stats: {
                health: 43,
                damage: 2,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: -6,
                mana: 10, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 3
            },
            level: 4,
            resistances: { shock: 1.3 },
            tags: [FEARFUL],
            ai: { type: 'restless' },
            spells: ['Move', 'Raise Dead', 'Melee Attack (Monster)'],
            audio: {
                onHit:   'GhoulHitAudio',
                onDeath: 'GhoulDeathAudio'
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (tileWhereDied.hasTrap() == false) {
                    Battlefield.spawnTrap('Oil', tileWhereDied);
                }
            },
        },
        {   name: "Spine Skull",
            description: 'On death, revives in 3 turns if there are still other monsters left.',
            stats: {
                health: 31,
                damage: 6,
                armor: 0,
                crit: 0,
                dodge: 25,
                initiative: -1,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 4,
            ai: { type: 'restless' },
            spells: ['Fly Move', 'Melee Attack (Monster)'],
            audio: {
                onHit:   'SpineSkullHitAudio',
                onDeath: 'SpineSkullDeathAudio'
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                var tileToMakeCorpse: TileSpace;
                if (tileWhereDied.hasTrap() == false) {
                    tileToMakeCorpse = tileWhereDied;
                } else {
                    tileToMakeCorpse = tileWhereDied.getRandomEmptyNeighbor();
                    if (tileToMakeCorpse == null)
                        return;
                }

                final corpse = Battlefield.spawnTrap('Spine Skull Corpse', tileToMakeCorpse);
                corpse.customData = { turnsRemaining: 3 }   // 3 Because the end of this round makes it 2; then give it another round to wait
            }
        },
        {   name: "Beholder",
            description: 'They are very tame, no worries.',
            stats: {
                health: 51,
                damage: 10,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 15, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 1
            },
            level: 4,
            tags: [ANIMAL],
            resistances: { shock: 0.35 },
            ai: {
                type: 'advancer',
                spellSequence: ['Silencio', 'Exprecio', 'Zonancio'],
                overrideSpellSequence: function(self: Unit, currentAISpellIndex: Int): String {
                    if (self.mana == 0) return 'Zonancio';
                    final choice: String = randomOf(['Silencio', 'Exprecio', 'Zonancio']);
                    return choice;
                }
            },
            spells: ['Move', 'Silencio', 'Exprecio', 'Zonancio'],
            audio: {
                onHit:   'BeholderHitAudio',
                onDeath: 'BeholderDeathAudio'
            }
        },
        {   name: "Fire Beholder",
            description: 'They do fire stuff. Easy to dodge.',
            stats: {
                health: 40,
                damage: 7,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 15, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 4,
            tags: [ANIMAL],
            resistances: { fire: 0.5, cold: 1.5 },
            ai: {
                type: 'advancer',
                spellSequence: ['Fire Silencio', 'Fire Exprecio', 'Fire Zonancio'],
                overrideSpellSequence: function(self: Unit, currentAISpellIndex: Int): String {
                    final choice: String = randomOf(['Fire Silencio', 'Fire Exprecio', 'Fire Zonancio']);
                    if (self.mana == 0) return 'Fire Zonancio';
                    return choice;
                }
            },
            spells: ['Move', 'Fire Silencio', 'Fire Exprecio', 'Fire Zonancio'],
            audio: {
                onHit:   'BeholderHitAudio',
                onDeath: 'BeholderDeathAudio'
            }
            // onTakingDamage: function(self: Unit, amount: Int) {
            //     if (self.customData.ints.exists('novaCounter') == false) {
            //         self.customData.ints['novaCounter'] = 1;
            //     } else {
            //         self.customData.ints['novaCounter'] += 1;
            //     }
            //     if (self.customData.ints['novaCounter'] >= 3) {
            //         self.customData.ints['novaCounter'] = 0;
            //         final targets = self.getNeighborUnits(true);
            //         for (target in targets) {
            //             self.damageUnit(target, self.getDamageWithVariation(), PURE);
            //         }
            //     }
            // }
        },
        {   name: "Drider",
            description: 'Shoots DARK spikes in a line. \n Thorns: every time it takes damage, damages units around it (Physical) and increases Thorns damage by 1.',
            stats: {
                health: 118,
                damage: 8,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: -4,
                mana: 0,
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 4,
            isLarge: true,
            damageVariation: 1,
            tags: [ANIMAL],
            resistances: { fire: 1.3 },
            ai: { type: 'brute', spellSequence: ['Spike Rush', 'Throw Net (Enemy)', 'Spike Rush', 'Sumo Wave', 'End Turn', 'Spike Rush'] },
            spells: ['Move', 'Throw Net (Enemy)', 'Spike Rush', 'Sumo Wave', 'End Turn'],
            combatStartQuotes: ['For the spider kingdom!'],
            audio: {
                onHit:   'DriderHitAudio',
                onDeath: 'DriderDeathAudio'
            },
            onTurnEnd: function(self: Unit) {
                if (willCastSpellNextTurn(self, 'Throw Net (Enemy)')) {
                    self.addAttachment('Has Net', 24, 16);
                } else if (self.hasAttachment('Has Net')) {
                    self.removeAttachment('Has Net');
                }
            },
            afterTakingDamage: function(self: Unit, amount: Int) {
                if (amount <= 2) return;
                if (self.isDead) return;
                if (self.customData.ints.exists('thornsDamage') == false) {
                    self.customData.ints['thornsDamage'] = 1;
                } else {
                    self.customData.ints['thornsDamage'] += 1;
                }
                self.scrollRed('+1 THORNS');
                final targets = self.getNeighborUnits(true);
                for (target in targets) {
                    if (target.isDead) return;
                    if (target.name != 'Drider') {
                        self.damageUnit(target, self.customData.ints['thornsDamage']);
                    }
                }
            }
        },
        {   name: 'Laser Crystal',
            description: 'Moves diagonally, then shoots a FIRE laser.',
            stats: {
                health: 38,
                mana: 15,
                damage: 10,
                armor: 35,
                speed: 1,
                initiative: 1,
            },
            level: 4,
            ai: { type: 'restless' },
            damageVariation: 1,
            audio: {
                onHit:   'CrystalHitAudio',
                onDeath: 'CrystalDeathAudio'
            },
            spells: ['Crystal Move', 'Shoot Laser']
        },
        {   name: 'Draining Crystal',
            description: 'Drains 3 MANA from nearby units.',
            stats: {
                health: 38,
                damage: 0,
                mana: 5,
                armor: 35,
                speed: 1,
                initiative: 1,
            },
            level: 4,
            ai: { type: 'restless' },
            tags: [FEARFUL],
            audio: {
                onHit:   'CrystalHitAudio',
                onDeath: 'CrystalDeathAudio'
            },
            spells: ['Crystal Move', 'Drain Mana'],
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                if (self.customData.ints.exists('manaStored') == false) return;
                if (self.customData.ints['manaStored'] == 0) return;
                final targets = tileWhereDied.getNeighborUnits(true);
                for (target in targets) {
                    self.damageUnit(target, self.customData.ints['manaStored'], PURE);
                }
                doExplosionEffect(tileWhereDied.getXCenter(), tileWhereDied.getYCenter(), 'Explosion Blue');
            }
        },
        {   name: 'Lightning Crystal',
            description: 'Deals 5 SHOCK damage to a random player unit.',
            stats: {
                health: 23,
                damage: 0,
                mana: 5,
                armor: 35,
                speed: 0,
                initiative: -1,
            },
            level: 4,
            resistances: { shock: 0.2 },
            audio: {
                onHit:   'CrystalHitAudio',
                onDeath: 'CrystalDeathAudio'
            },
            spells: ['Lightning Rain'],
            onCombatStart: function(self: Unit) {
                self.block = 23;
                self.doesBlockDecay = false;
                self.updateBars();
            }
        },
        {   name: 'Charging Crystal',
            description: 'Increases SHOCK damage of other monsters every turn.',
            stats: {
                health: 23,
                damage: 0,
                armor: 35,
                speed: 0,
                initiative: 4,
            },
            level: 4,
            audio: {
                onHit:   'CrystalHitAudio',
                onDeath: 'CrystalDeathAudio'
            },
            spells: ['Lightning Empower'],
            tags: [FEARFUL],
            onCombatStart: function(self: Unit) {
                self.block = 23;
                self.doesBlockDecay = false;
                self.updateBars();
            }
        },
        {   name: 'Void Crystal',
            description: 'Slows adjacent units by 1. \n On death, all enemy units gain +1 SPEED.',
            stats: {
                health: 18,
                damage: 0,
                mana: 0,
                armor: 35,
                speed: 1,
                initiative: 2,
            },
            level: 4,
            resistances: { dark: 0.7, shock: 1.5 },
            ai: { type: 'restless' },
            tags: [FEARFUL],
            audio: {
                onHit:   'CrystalHitAudio',
                onDeath: 'CrystalDeathAudio'
            },
            spells: ['Crystal Move', 'Slow Down'],
            onCombatStart: function(self: Unit) {
                self.block = 18;
                self.doesBlockDecay = false;
                self.updateBars();
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                final targets = Battlefield.getAllAliveEnemyUnits();
                for (target in targets) {
                    target.addBuff(new Buff('Speed Up', 4, { speed: 1 }));
                    flashColor(target.actor, 255, 25, 215);
                }
            }
        },
        {   name: "Crystal Golem",
            thumbnailPath: 'auto',
            description: 'Throws you over the shoulder. \n Stuns around every once in a while. \n On death, transforms into a Crystalid.',
            stats: {
                health: 32,
                damage: 8,
                armor: 85,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 1
            },
            level: 4,
            damageVariation: 2,
            isLarge: true,
            spells: ['Move', 'Shoulder Throw', 'Fat Slam'],
            audio: {
                onHit:   'CrystalGolemHitAudio',
                onDeath: 'CrystalGolemDeathAudio'
            },
            onCombatStart: function(self: Unit) {
                self.block = 36;
                self.doesBlockDecay = false;
                self.updateBars();
                self.customData.ints['blockGain'] = 1;
            },
            onRoundEnd: function(self: Unit) {
                if (self.health <= 11) {
                    final tile = self.tileOn;
                    self.playEffect('Smoke', 150);
                    self.playEffect('Crystal Shards', 150);
                    self.remove();
                    Battlefield.spawnEnemyOnTile('Crystalid', tile);
                } else {
                    self.block += self.customData.ints['blockGain'];
                    self.customData.ints['blockGain'] += 1;
                    self.playEffect('Block', 1500);
                    self.updateBars();
                }
            }
        },
        {   name: 'Crystalid',
            description: 'Will soon morph into something beautiful.',
            stats: {
                health: 23,
                damage: 0,
                mana: 99,
                armor: 35,
                speed: 0,
                initiative: 1,
            },
            level: 4,
            spells: ['End Turn'],
            audio: {
                onHit:   'CrystalHitAudio',
                onDeath: 'CrystalDeathAudio'
            },
            onRoundEnd: function(self: Unit) {
                if (self.isDead) return;
                if (self.customData.ints.exists('turnsToMorph') == false) {
                    self.customData.ints['turnsToMorph'] = 2;
                } else {
                    self.customData.ints['turnsToMorph'] --;
                }
                if (self.customData.ints['turnsToMorph'] == 0) {
                    final tile = self.tileOn;
                    self.playEffect('Crystal Shards', 150);
                    self.kill();
                    final possibleCrystals = ['Laser Crystal', 'Draining Crystal', 'Void Crystal'];
                    final crystal: String = randomOf(possibleCrystals);
                    Battlefield.spawnEnemyOnTile(crystal, tile);
                }
            }
        },
        {   name: "Cyclops",
            thumbnailPath: 'auto',
            description: 'Blasts a large area around him (delayed). \n Every time it takes damage, gains +1 DAMAGE.',
            stats: {
                health: 106,
                damage: 8,
                armor: 0,
                crit: 50,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 4,
            isLarge: true,
            damageVariation: 1,
            ai: { type: 'restless' },
            audio: {
                onHit:   'CyclopsHitAudio',
                onDeath: 'CyclopsDeathAudio'
            },
            spells: ['Move', 'Big Smash'],
            afterTakingDamage: function(self: Unit, amount: Int) {
                self.playEffect('Enrage', 1150);
                self.stats.damage += 1;
                self.scrollRed('+1 DMG!');
            }
        },
        {   name: "Hell Giant",
            thumbnailPath: 'auto',
            description: 'Blasts a large area around him (delayed). \n Every time it takes damage, gains +1 DAMAGE.',
            stats: {
                health: 76,
                damage: 5,
                armor: 0,
                crit: 50,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 4,
            isLarge: true,
            ai: { type: 'restless' },
            audio: {
                onHit:   'CyclopsHitAudio',
                onDeath: 'CyclopsDeathAudio'
            },
            spells: ['Move', 'Big Smash'],
            afterTakingDamage: function(self: Unit, amount: Int) {
                self.playEffect('Enrage', 1150);
                self.stats.damage += 1;
                self.scrollRed('+1 DMG!');
            }
        },
        
        
        // Bosses
        {   name: "Pumpkin Tentacle",
            description: 'Shoots delayed DARK spikes in a line. Casts a ROOT every 3 turns.',
            stats: {
                health: 27,
                damage: 5,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 2,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 0
            },
            level: 4,
            resistances: { fire: 1.5 },
            tags: [FEARFUL, ENEMY_PLANT],
            ai: {
                type: 'canon',
                spellSequence: ['Spike Rush Long', 'End Turn', 'Throw Net (Enemy No CD)']
            },
            combatStartQuotes: ["*Squiggly squig*"],
            spells: ['Spike Rush Long', 'Throw Net (Enemy No CD)', 'End Turn'],
            audio: {
                onHit:   'PumplingHitAudio',
                onDeath: 'PumplingDeathAudio'
            },
            onTurnStart: function(self: Unit) {
                if (self.getNextSpellInSequence() == 'Throw Net (Enemy No CD)') {
                    self.addAttachment('Has Net', 24, 16);
                }
            }
        },
        {   name: 'Pumpzilla',
            isLarge: true,
            description: 'IT IS ALIVE!!!',
            stats: {
                health: 113,
                mana: 10,
                damage: 5,
                initiative: 0,
                speed: 1
            },
            level: 4,
            tags: [ENEMY_PLANT],
            spells: ['Move', 'Swipe Attack', 'Melee Attack (Monster)'],
            audio: {
                onHit:   'PumpzillaHitAudio',
                onDeath: 'PumpzillaDeathAudio'
            }
        },
        {   name: 'Hellzilla',
            isLarge: true,
            description: 'WAIT THERE ARE MORE OF THESE IN HELL!?',
            stats: {
                health: 86,
                damage: 7,
                initiative: 0,
                speed: 1
            },
            tags: [ENEMY_PLANT],
            resistances: {
                fire: 0.8,
                cold: 1.5,
                shock: 1.25
            },
            level: 4,
            damageVariation: 1,
            spells: ['Move', 'Swipe Attack', 'Melee Attack (Monster)'],
            audio: {
                onHit:   'PumpzillaHitAudio',
                onDeath: 'PumpzillaDeathAudio'
            }
        },
        {   name: 'Giant Pumpkin',
            isLarge: true,
            description: 'You feel a deep, dark presence emanating from it...',
            stats: {
                health: 86,
                damage: 8
            },
            level: 4,
            onCombatStart: function(self: Unit) {
                // Battlefield.addOnRoundEndEvent(function(roundNumber: Int) {
                //     final allEnemies = Battlefield.getAllAliveEnemyUnits();
                //     if (allEnemies.length == 1 && allEnemies[0] == self) {  // Aka this unit is the only one left
                //         self.damage(5, PURE);
                //         SpecialEffectsFluff.shakeScreenShort();
                //     }
                // });
            },
            onTakingDamage: function(self: Unit, amount: Int) {
                final tileForPumpkin = Battlefield.getRandomTileWithNoUnit();
                final pumpkin = Battlefield.spawnUnit('Pumpkin', tileForPumpkin.getI(), tileForPumpkin.getJ(), NEUTRAL);
                pumpkin.actor.disableActorDrawing();
                Effects.sendArcMissileAndThen(self.getCenterPoint(), tileForPumpkin.getCenterPointForMissile(), 'Pumpkin Missile', Effects.SLOW, function() {
                    if (pumpkin.isDead) return;
                    pumpkin.actor.enableActorDrawing();
                    Effects.playParticleAndThen(tileForPumpkin.getCenterPointForMissile(), tileForPumpkin.getCenterPointForMissile(), 'Smoke', 500, () -> {});
                });
            },
            afterDeath: (self: Unit, tile: TileSpace) -> {
                // Spawn Tentacles
                final topRightTile    = Battlefield.getTile(0, 6);
                final bottomRightTile = Battlefield.getTile(4, 6);
                final tentacle1       = trySpawnUnitAroundTile('Pumpkin Tentacle', topRightTile);
                final tentacle2       = trySpawnUnitAroundTile('Pumpkin Tentacle', bottomRightTile);
                if (tentacle1 == null) {
                    tentacle1.say('* prevents tentacle from spawning *');
                    Effects.playParticleAndThen(tentacle1.getCenterPoint(), tentacle1.getCenterPoint(), 'Spike Rush', 500, () -> {});
                    tentacle1.damage(10, PURE);
                }
                if (tentacle2 == null) {
                    tentacle2.say('* prevents tentacle from spawning *');
                    Effects.playParticleAndThen(tentacle2.getCenterPoint(), tentacle2.getCenterPoint(), 'Spike Rush', 500, () -> {});
                    tentacle2.damage(10, PURE);
                }
                // Spawn Pumpzilla
                final pumpzilla = UnitsDatabase.spawnUnitNicely('Pumpzilla', tile, ENEMY);
                Unit.doAfterUnit(pumpzilla, 2000, () -> {
                    pumpzilla.say('Fools.', 1.5, -15, 0);
                });
                Unit.doAfterUnit(pumpzilla, 4000, () -> {
                    pumpzilla.say('You have no idea who you are facing.', 3.5, -15, 0);
                });
            },
            ai: {
                spellSequence: ['Cross Spikes', 'Corner Spikes', 'X Spikes']
            },
            spells: ['Cross Spikes', 'Corner Spikes', 'X Spikes', 'End Turn'],
            audio: {
                onHit:   'PumplingHitAudio',
                onDeath: 'PumplingDeathAudio'
            }
        },
        {   name: 'Stormjr',
            description: 'The J is pronounced as Y.',
            stats: {
                health: 191,
                damage: 20,
                mana: 20,
                speed: 1,
                initiative: 1,
                armor: 25
            },
            level: 6,
            tags: [ANIMAL],
            resistances: { cold: 0.8 },
            isLarge: true,
            ai: {
                type: 'canon',
                spellSequence: ['Tidal Wave Odd', 'End Turn', 'Tidal Wave Even', 'Tidal Wave All', 'Switch Stormjr Position', 'Triple Tide', 'End Turn', 'Tidal Wave All Reversed', 'End Turn', 'Triple Tide', 'Unswitch Stormjr Position']
            },
            damageVariation: 3,
            sayOffsetX: -50,
            sayOffsetY: -3,
            audio: {
                onHit:   'StormjrHitAudio',
                onDeath: 'StormjrDeathAudio'
            },
            spells: ['Move', 'Tidal Wave Odd', 'End Turn', 'Tidal Wave Even', 'Tidal Wave All', 'Switch Stormjr Position', 'Unswitch Stormjr Position', 'Triple Tide', 'Tidal Wave All Reversed']
        },
        {   name: "Water Elemental",
            description: 'Grows when hit by Stormjr\'s waves. \n On death, explodes.',
            stats: {
                health: 30,
                mana: 1,
                damage: 3,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 2,
            resistances: { cold: 0.5, shock: 1.5 },
            damageVariation: 2,
            spells: ['Move', 'Melee Attack (Monster) (Cold)'],
            afterDeath: function(self: Unit, tile: TileSpace) {
                Effects.playEffectAt(tile.getXCenter(), tile.getYCenter(), 'Water Explosion', 750);
                playAudio('WaterExplosionAudio');
                final unitsToDamage = tile.getNeighbors(true).filter(t -> t.hasUnit()).map(t -> t.unitOnIt);
                for (unit in unitsToDamage) {
                    self.damageUnit(unit, self.stats.damage * 2, COLD);
                }
            },
            audio: {
                onHit:   'WaterElementalHitAudio',
                onDeath: 'WaterExplosionAudio'
            }
        },
        {   name: 'Brat',
            description: 'Squeak squeak!',
            stats: {
                health: 27,
                damage: 5,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 3
            },
            level: 2,
            tags: [ANIMAL],
            ai: { type: 'restless' },
            actorOffsetY: 10,
            spells: ['Fly Move', 'Melee Attack (Monster)'],
            audio: {
                onDeath: 'BatDeathAudio'
            }
        },
        {   name: 'Bat',
            description: 'Kill as many as you can to weaken Spatula!',
            stats: {
                health: 17,
                damage: 3,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 2,
            tags: [ANIMAL],
            damageVariation: 2,
            actorOffsetY: 10,
            ai: { type: 'restless' },
            spells: ['Fly Move', 'Melee Attack (Monster)'],
            audio: {
                onDeath: 'BatDeathAudio'
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {    // Summon Spatula if all bats are dead
                Battlefield.customData.ints['nBatsKilled'] += 1;
                
                final areAnyBatsAlive = Battlefield.unitsOnBattlefield.filter(u -> u.name == 'Bat' && u.isDead == false).length > 0;
                if (areAnyBatsAlive) return;
                if (Battlefield.customData.strings['isSpatulaAlive'] == 'yes') return;  // To prevent summoning Spatula if more bats die simultanuously

                final healthDeficit = Battlefield.customData.ints['nBatsKilled'] * 7;
                if (healthDeficit < 80) {                                                // If not too much HP is lost, resummon Spatula!
                    final spatula = UnitsDatabase.spawnUnitNicely('Count Spatula', tileWhereDied);
                    spatula.health -= healthDeficit;
                    spatula.updateBars();
                    Battlefield.customData.strings['isSpatulaAlive'] = 'yes';
                } else {                                                                 // If too much HP is lost, you win the battle!
                    if (Battlefield.currentBattlefieldEncounter.name == 'Count Spatula Unleashed') {    // Unless of course the second Phase is incoming!
                        spawnSpatulaUnleashed(tileWhereDied);
                    }
                }
            }
        },
        {   name: 'Count Spatula Unleashed',
            animationUsed: 'Vampire Lord',
            thumbnailPath: 'Icons/Small/Count Spatula.png',
            description: 'Do NOT let him step on Bloodbaths!',
            stats: {
                health: 133,
                mana: 15,
                damage: 10,
                speed: 4,
                initiative: 2
            },
            level: 6,
            resistances: { dark: 0.8, fire: 1.2 },
            ai: {
                type: 'restless',
                spellSequence: ['Vampire Attack Unleashed', 'Hashtag Attack', 'Vampire Attack Unleashed', 'Vampire Attack Unleashed'],
            },
            damageVariation: 1,
            spells: ['Fly Move', 'Vampire Attack Unleashed', 'Hashtag Attack'],
            audio: {
                onHit: 'VampireHit2Audio',
                onDeath: 'VampireDeathAudio'
            }
        },
        {   name: 'Count Spatula',
            animationUsed: 'Vampire Lord',
            description: 'Chhh...',
            stats: {
                health: 98,
                damage: 10,
                mana: 15,
                speed: 4,
                initiative: 2
            },
            level: 6,
            resistances: { dark: 0.8, fire: 1.2 },
            ai: {
                type: 'restless',
                spellSequence: ['Vampire Attack', 'Hashtag Attack', 'Summon Bats'],
                overrideSpellSequence: function(self: Unit, currentAISpellIndex: Int): String {
                    if (self.health >= self.stats.health / 2) return null;
                    final nBrats = Battlefield.getAllAliveEnemyUnits().filter(u -> u.name == 'Brat').length;
                    if (nBrats == 0) return null;
                    return 'Sacrifice Bat';
                }
            },
            damageVariation: 1,
            spells: ['Fly Move', 'Vampire Attack', 'Summon Bats', 'Sacrifice Bat', 'Hashtag Attack'],
            onCombatStart: function(self: Unit) {
                Battlefield.initCustomString('isSpatulaAlive', 'yes');                              // For bats, to regulate when to spawn Spatula
                Battlefield.addOnRoundEndEvent(function(roundNumber: Int) {                         // Every round, check if to remove bats and summon spatula

                    if (Battlefield.customData.strings['isSpatulaAlive'] == 'yes') return;          // Continue only if Spatula is dead
                    Battlefield.customData.ints['turnsRemainingToSpawnSpatula'] -= 1;
                    if (Battlefield.customData.ints['turnsRemainingToSpawnSpatula'] != 0) return;   // It might be less than 0 and we don't care about that

                    // If 0 turns left to spawn Spatula, spawn Spatula
                    final bats = Battlefield.getAllAliveEnemyUnits().filter(u -> u.name == 'Bat');
                    if (bats.length == 0) {
                        trace('WARNING: No bats are alive when Count spatula is dead.');
                        return;
                    }

                    // If there are any bats...
                    Battlefield.preventNextTurnOnce();
                    Battlefield.customData.strings['isSpatulaAlive'] = 'yes';

                    final bat = bats.pop();
                    final tileToSummon = bat.tileOn;
                    bat.remove();

                    for (b in bats)
                        b.actor.moveTo(
                            tileToSummon.getXCenter() - b.actor.getWidth() / 2,
                            tileToSummon.getYCenter() - b.actor.getHeight(),
                        0.5, Easing.expoOut);

                    doAfter(750, () -> {
                        for (b in bats) b.remove();
                        final spatula = UnitsDatabase.spawnUnitNicely('Count Spatula', tileToSummon);
                        spatula.playEffect('Smoke', 150);
                        var healthDeficit = Battlefield.customData.ints['nBatsKilled'] * 7;
                        if (healthDeficit > self.stats.health / 2) {   // Just to make sure nothing really bad ever happens
                            healthDeficit = int(self.stats.health / 2);
                        }
                        spatula.health -= healthDeficit;
                        spatula.updateBars();
                        doAfter(2000, () -> {
                            spatula.say('I live once more!!', 2);
                            Battlefield.unpreventNextTurn();
                        });
                    });
                });
            },
            afterDeath: (self: Unit, tileWhereDied: TileSpace) -> {
                function trySummonBats(): Bool {    // Returns true if it succeeded
                    var nBatsSummoned = 0;
                    final totalHPDeficit = Battlefield.customData.ints['nBatsKilled'] * 10;
                    if (totalHPDeficit >= self.stats.health / 2) return false;

                    function summonBat(tile: TileSpace) {
                        nBatsSummoned += 1;
                        final bat = Battlefield.spawnEnemyOnTile('Bat', tile);
                        bat.playEffect('Smoke', 150);
                    }


                    final totalBatsSummoned = int(Math.min(5, (80 - totalHPDeficit) / 10));

                    summonBat(tileWhereDied);
                    if (totalBatsSummoned == 1) return true;

                    final otherTiles = tileWhereDied.getEmptyNeighbors();
                    for (tile in otherTiles) {
                        summonBat(tile);
                        if (nBatsSummoned == totalBatsSummoned) return true;
                    }

                    while (nBatsSummoned < totalBatsSummoned) {
                        final tile = Battlefield.getRandomTileWithNoUnit();
                        summonBat(tile);
                    }
                    return true;
                }
                
                Battlefield.initCustomInt('nBatsKilled', 0);
                Battlefield.customData.strings['isSpatulaAlive'] = 'no';
                Battlefield.customData.ints['turnsRemainingToSpawnSpatula'] = 3;

                final didSummonBats = trySummonBats();
                if (didSummonBats)
                    return;
                else {
                    if (Battlefield.currentBattlefieldEncounter.name == 'Count Spatula 2') {
                        spawnSpatulaUnleashed(tileWhereDied);
                    }
                }
            },
            audio: {
                onHit: 'VampireHit2Audio',
                onDeath: 'VampireDeathAudio'
            }
        },
        {   name: 'Captain Stashton',
            description: 'Yahaharghh...',
            stats: {
                health: 99,
                mana: 5,
                damage: 7,
                speed: 2,
                initiative: 16
            },
            level: 6,
            ai: {
                type: 'restless',
                spellSequence: ['Melee Attack (Monster)', 'Bullet Hell', 'Shoot Location', 'Anchor Drop'],
                overrideSpellSequence: function(slef: Unit, currentAISpellIndex: Int): String {
                    if (currentAISpellIndex != 3) return null;
                    final allAnchors = Battlefield.getAllAliveNeutralUnits().filter(u -> u.name == 'Anchor');
                    if (allAnchors.length < 2) return null;

                    for (anchor in allAnchors) {
                        final nearbyPlayers = anchor.getNeighborPlayerUnits();
                        if (nearbyPlayers.length == 0) continue;
                        else return 'Anchor Lift';
                    }
                    return null;
                }
            },
            audio: {
                onHit:   'CaptainStashtonHitAudio',
                onDeath: 'CaptainStashtonDeathAudio'
            },
            spells: ['Move', 'Melee Attack (Monster)', 'Shoot Location', 'Bullet Hell', 'Anchor Drop', 'Anchor Lift']
        },
        {   name: 'Blessed Children of Almund',
            description: 'This can\'t be the boss, right? Right?',
            stats: {
                health: 88,
                mana: 10,
                damange: 5,
                speed: 1
            },
            level: 6,
            spells: ['Move', 'Melee Attack (Monster)'],
            tags: [HUMAN],
            audio: {
                onHit:   'BlessedChildrenHitAudio'
            },
            onCombatStart: function(self: Unit) {
                Battlefield.addOnUnitMoveEvent(function(unit: Unit, toTile: TileSpace) {
                    if (unit == self) {
                        final quote: String = randomOf(['A bit crowded...', 'This is kind of slow...', 'Oof.', 'You stepped on my foot!', 'Don\'t break formation!']);
                        unit.say(quote);
                    }
                });
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                Battlefield.pauseNextTurn();

                function spawnChild(childName: String, i: Int, j: Int) {
                    var child = Battlefield.spwanEnemyAroundTile(childName, Battlefield.getTile(i, j));
                    if (child == null)
                        child = Battlefield.spawnEnemyOnTile(childName, Battlefield.getRandomTileWithNoUnit());
                    final x = child.actor.getX(), y = child.actor.getY();
                    child.actor.disableActorDrawing();
                    Effects.sendArcMissileAndThen(
                        tileWhereDied.getCenterPointForMissile(),
                        new Point(x, y),
                        childName,  // Missile has this exact same name
                        Effects.MEDIUM,
                        () -> {
                            child.playEffect('Smoke');
                            child.actor.enableActorDrawing();
                        }
                    );
                    return child;
                }
                
                final su = spawnChild('Suzanna the Fair', 2, 5);
                final big = spawnChild('Big Boyo', 1, 3);
                final lil = spawnChild('Lil Munchy', 4, 4);

                doAfter(2000, () -> {
                    su.say('Our formation is broken!!', 2);
                    doAfter(2000, () -> {
                        lil.say('...it was a stupid formation.', 2);
                    });
                    doAfter(4000, () -> {
                        big.say('FRESH MEAT!!', 2);
                        Battlefield.resumeNextTurn();
                    });
                });
            }
        },
        {   name: 'Suzanna the Fair',
            description: 'Heals.',
            stats : {
                health : 32,
                mana: 10,
                damage : 3,
                dodge : 0,
                spellPower : 1,
                speed : 3
            },
            level: 3,
            tags: [HUMAN],
            ai: { type: 'restless' },
            spells: ["Move", "Healing Word", "Melee Attack (Monster)"],
            audio: {
                onHit:   'SuzannaHitAudio',
                onDeath: 'SuzannaDeathAudio'
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                final didEmpower = empowerLilMunchy();
                final suzanna = UnitsDatabase.spawnUnitNicely('Suzanna the Fair Spider', tileWhereDied);
                suzanna.playEffect('Bat Explosion');
                playAudio('SuzannaSpiderDeathAudio');
                if (didEmpower) {
                    suzanna.say('AID ME, LITTLE BROTHER!', 2);
                    doAfter(3000, () -> {
                        suzanna.say('YOU MUST FEED!!', 2);
                    });
                } else {
                    suzanna.say('I must... FEED!!', 2);
                }
            }
        },
        {   name: "Lil Munchy",
            description: 'Throws muffin traps that deal DARK damage.',
            stats: {
                health: 25,
                damage: 4,
                speed: 2
            },
            level: 3,
            tags: [HUMAN],
            ai: { type: 'molotov-peasant' },
            damageVariation: 1,
            spells: ['Move', 'Throw Muffin Trap'],
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                final didEmpower = empowerBigBoyo();
                final centipede = UnitsDatabase.spawnUnitNicely('Lil Munchy Centipede', tileWhereDied);
                centipede.playEffect('Bat Explosion');
                playAudio('LilMunchyCentipedeDeathAudio');
                if (didEmpower) {
                    centipede.say('Big Brother...', 2);
                    doAfter(3000, () -> {
                        centipede.say('AVENGE ME!!', 2);
                    });
                } else {
                    centipede.say('I WILL CONSUME YOUR LIVER!!', 2);
                }
            }
        },
        {   name: 'Big Boyo',
            description: 'Tanks.',
            stats: {
                health: 55,
                damage: 2,
                speed: 1
            },
            level: 3,
            tags: [HUMAN],
            damageVariation: 1,
            spells: ['Move', 'Melee Attack Diagonal'],
            audio: {
                onHit:   'BigBoyoHitAudio',
                onDeath: 'BigBoyoDeathAudio'
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                final didEmpower = empowerSuzanna();
                final wasp = UnitsDatabase.spawnUnitNicely('Big Boyo Wasp', tileWhereDied);
                wasp.playEffect('Bat Explosion');
                playAudio('BigBoyoWaspDeathAudio');
                if (didEmpower) {
                    wasp.say('Sister...', 2);
                    doAfter(3000, () -> {
                        wasp.say('EAT THEIR KIDNEYS!!', 2);
                    });
                } else {
                    wasp.say('I WILL FEED ON YOUR FLESH!!', 2);
                }
            }
        },
        {   name: 'Suzanna the Fair Spider',
            description: 'Spits web. \n Spits slime that INFECTS. \n Might damage her human brothers.',
            stats: {
                health: 42,
                mana: 10,
                damage: 3,
                speed: 3,
            },
            level: 3,
            tags: [ANIMAL, HUMAN],
            damageVariation: 1,
            audio: {
                onHit:   'SuzannaSpiderHitAudio',
                onDeath: 'SuzannaSpiderDeathAudio'
            },
            ai: {
                type: 'restless',
                spellSequence: ['Spit Web', 'Spit Web', 'Spit Web'],
                overrideSpellSequence: function(self: Unit, currentAISpellIndex: Int): String {
                    if (currentAISpellIndex % 3 == 2) {
                        return 'Spit Slime';
                    }
                    if (self.isWithinRangeOfPlayerUnit(2)) {
                        return 'Spit Web';
                    }
                    final lil = Battlefield.getUnitByName('Lil Munchy');
                    final big = Battlefield.getUnitByName('Big Boyo');
                    if (lil != null || big != null) {
                        return 'Damage Ally';
                    }
                    return 'Spit Web';
                }
            },
            spells: ['Move', 'Spit Web', 'Spit Slime', 'Damage Ally'],
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                var lil = Battlefield.getUnitByName('Lil Munchy Centipede');
                if (lil == null)
                    lil = Battlefield.getUnitByName('Lil Munchy');
                if (lil == null)
                    return;
                empowerLilMunchy();
                lil.say('I will avenge you, Sister!!', 2);
            }
        },
        {   name: 'Big Boyo Wasp',
            description: 'BZZZ...',
            stats: {
                health: 45,
                armor: -30,
                speed: 3,
                damage: 7
            },
            level: 3,
            damageVariation: 2,
            doesFlipHorizontally: false,
            audio: {
                onHit:   'BigBoyoWaspHitAudio',
                onDeath: 'BigBoyoWaspDeathAudio'
            },
            tags: [ANIMAL, HUMAN],
            ai: {
                type: 'restless',
                spellSequence: [],
                overrideSpellSequence: function(self: Unit, currentAISpellIndex: Int): String {
                    if (currentAISpellIndex % 3 == 2) {
                        return 'Wasp Flip';
                    }
                    if (self.isFlippedHorizontally)
                        return 'Sting Left';
                    return 'Sting Right';
                }
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                var su = Battlefield.getUnitByName('Suzanna the Fair');
                if (su == null)
                    su = Battlefield.getUnitByName('Suzanna the Fair Spider');
                if (su == null)
                    return;
                empowerSuzanna();
                if (su.name == 'Suzanna the Fair') {
                    su.say('Thou art not forsaken, brother.', 2);
                } else {
                    su.say('Thy buzzing shall be avenged, brother!', 2);
                }
            },
            spells: ['Fly Move', 'Sting Right', 'Sting Left', 'Wasp Flip']
        },
        {   name: 'Lil Munchy Centipede',
            description: 'Thee bethought this child can not speaketh words of meaning? Pathetic humans.',
            stats: {
                health: 22,
                armor: 50,
                speed: 2,
                damage: 5
            },
            level: 3,
            tags: [ANIMAL],
            audio: {
                onHit:   'LilMunchyCentipedeHitAudio',
                onDeath: 'LilMunchyCentipedeDeathAudio'
            },
            ai: {
                spellSequence: ['Burrow', 'End Turn', 'Quad Spikes']
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                var big = Battlefield.getUnitByName('Big Boyo');
                if (big == null)
                    big = Battlefield.getUnitByName('Big Boyo Wasp');
                if (big == null)
                    return;
                empowerBigBoyo();
                if (big.name == 'Big Boyo') {
                    big.say('NO! NNOOOO!!!', 2);
                } else {
                    big.say('BZZZZZ!!!', 2);
                }
            },
            spells: ['Move', 'Burrow', 'Quad Spikes', 'End Turn']
        },
        {   name: 'Father Almund',
            description: 'Pious? Check. \n Beard? Check. \n Orthodox? Oh, check!!!',
            stats: {
                health: 89,
                mana: 15,
                speed: 2,
                damage: 9,
                initiative: 4,
            },
            level: 6,
            tags: [HUMAN],
            resistances: {
                dark: 1.35
            },
            ai: {
                type: 'restless',
                spellSequence: ['Holy Cross', 'Holy Consecration', 'Holy X']
            },
            spells: ['Move', 'Holy Cross', 'Holy Consecration', 'Holy X', 'End Turn'],
            audio: {
                onHit:   'FatherAlmundHitAudio',
                onDeath: 'FatherAlmundDeathAudio'
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                Battlefield.pauseNextTurn();
                final almund = UnitsDatabase.spawnUnitNicely('Father Almund (2)', tileWhereDied);
                almund.playEffect('Holy Revival', 1300);
                doAfter(2000, () -> {
                    almund.say('The voices...', 2);
                });
                doAfter(5000, () -> {
                    almund.say('I feel the burning...', 2);
                });
                doAfter(8000, () -> {
                    almund.say('Forgive me, O Lord...', 2);
                });
                doAfter(11000, () -> {
                    almund.say('AND BEAR WITNESS TO MY NEW POWER!!', 3.5);
                });
                doAfter(1100, () -> {
                    Battlefield.resumeNextTurn();
                });
            }
        },
        {   name: 'Father Almund (2)',
            thumbnailPath: 'Icons/Small/Father Almund.png',
            description: 'Mostly the same as before. Can revive the Peasants.',
            stats: {
                health: 89,
                mana: 15,
                speed: 2,
                damage: 9,
                initiative: 4,
            },
            level: 6,
            tags: [HUMAN],
            ai: {
                type: 'restless',
                spellSequence: ['Revive Peasants', 'Dark Cross', 'Dark Consecration', 'Dark X']
            },
            audio: {
                onHit:   'FatherAlmund2HitAudio',
                onDeath: 'FatherAlmundDeathAudio'
            },
            spells: ['Move', 'Dark Cross', 'Dark Consecration', 'Dark X', 'Revive Peasants', 'End Turn']
        },
        {   name: 'Tyl',        // Fire Tyl
            description: 'Creates fire in corners. Summons a demon portal. Shoots crystals.',
            stats: {
                health: 245,
                mana: 604,
                armor: 25,
                speed: 3,
                damage: 13,
                spellPower: 6
            },
            level: 6,
            actorOffsetX: 15,
            isLarge: true,
            damageVariation: 4,
            resistances: { fire: 0.8, cold: 0.8, shock: 0.8, dark: 0.8 },
            tags: [IMMUNE_TO_SILENCE, ANIMAL],
            ai: {
                type: 'restless',
                spellSequence: ['Fire Arena', 'Demon Portal', 'Crystal Shot', 'End Turn']
            },
            spells: ['Fly Move', 'Fire Arena', 'Demon Portal', 'Crystal Shot', 'End Turn'],
            audio: {
                onHit:   'TylHitAudio',
                onDeath: 'TylDeathAudio'
            },
            onCombatStart: function(self: Unit) {

                // Fire Move
                Battlefield.addOnUnitMoveEvent((unitThatMoved: Unit, previousTile: TileSpace) -> {  // Leaves fire when he moves
                    if (self == unitThatMoved) {
                        if (previousTile.hasTrap())
                            return;
                        Battlefield.spawnTrap('Fire', previousTile);
                    }
                });


                final getTile = Battlefield.getTile;
                function createPedestalAt(x: Float, y: Float, layer: String) {
                    final pedestal = U.createActor('TrapActor', layer);
                    pedestal.setAnimation('Pedestal');
                    pedestal.setXCenter(x);
                    pedestal.setY(y - pedestal.getHeight());
                    return pedestal;
                }


                final pedestalPairs: Array<Array<Actor>> = [
                    [createPedestalAt(getTile(0, 5).getXCenter(), getTile(0, 5).getY(), 'Units0'),
                    createPedestalAt(getTile(0, 5).getXCenter(), getTile(4, 5).getY() + 47, 'Particles')],

                    [createPedestalAt(getTile(0, 1).getXCenter(), getTile(0, 1).getY(), 'Units0'),
                    createPedestalAt(getTile(0, 1).getXCenter(), getTile(4, 1).getY() + 47, 'Particles')],

                    [createPedestalAt(getTile(1, 6).getXCenter() + 35, getTile(1, 6).getYCenter(), 'Units1'),
                    createPedestalAt(getTile(1, 0).getXCenter() - 35, getTile(1, 0).getYCenter(), 'Units1')],

                    [createPedestalAt(getTile(3, 6).getXCenter() + 35, getTile(3, 6).getYCenter(), 'Units1'),
                    createPedestalAt(getTile(3, 0).getXCenter() - 35, getTile(3, 0).getYCenter(), 'Units1')]
                ];

                pedestalPairs[0][0].setAnimation('Pedestal Active');
                pedestalPairs[0][1].setAnimation('Pedestal Active');

                Battlefield.addOnUnitCastSpellEvent(function(caster: Unit, spell: Spell, tile: TileSpace) {
                    if (caster.isEnemy()) return;
                    if (['Melee Attack', 'Shoot Arrow', 'Shoot Arrow Long', 'Melee Attack Long', 'Move'].indexOf(spell.getName()) != -1) return;
                    
                    // Find latest active pedestal pair
                    var foundPedestalPair: Array<Actor> = [];
                    var foundPedestalPairIndex = 0;
                    for (i in 0...pedestalPairs.length) {
                        final pair = pedestalPairs[i];
                        if (pair[0].getAnimation() == 'Pedestal Active') {
                            foundPedestalPair = pair;
                            foundPedestalPairIndex = i;
                            break;
                        }
                    }

                    // Make that pair inactive
                    if (foundPedestalPair != null) {
                        foundPedestalPair[0].setAnimation('Pedestal');
                        foundPedestalPair[1].setAnimation('Pedestal');
                    }

                    // Do laser
                    final laser = createActor('SpecialEffectActor', 'Particles');
                    laser.setAnimation('Laser Beam');
                    stretchActorBetweenPoints(laser, foundPedestalPair[0].getXCenter(), foundPedestalPair[0].getYCenter() - 4, foundPedestalPair[1].getXCenter(), foundPedestalPair[1].getYCenter() - 4);
                    doAfter(300, () -> recycleActor(laser));

                    // Do damage
                    var affectedTiles: Array<TileSpace>;
                    if (foundPedestalPairIndex == 0) {
                        affectedTiles = Battlefield.tiles.getCol(5);
                    } else if (foundPedestalPairIndex == 1) {
                        affectedTiles = Battlefield.tiles.getCol(1);
                    } else if (foundPedestalPairIndex == 2) {
                        affectedTiles = Battlefield.tiles.getRow(1);
                    } else {
                        affectedTiles = Battlefield.tiles.getRow(3);
                    }
                    for (tile in affectedTiles) {
                        if (tile.hasUnit()) {
                            tile.unitOnIt.damage(self.getSpellPowerWithVariation(FIRE), FIRE);
                        }
                    }

                    // Make next pedestals active
                    final nextPedestalPairIndex = if (foundPedestalPairIndex == 3) 0 else foundPedestalPairIndex + 1;
                    pedestalPairs[nextPedestalPairIndex][0].setAnimation('Pedestal Active');
                    pedestalPairs[nextPedestalPairIndex][1].setAnimation('Pedestal Active');
                });
            },
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                Battlefield.pauseNextTurn();

                function trySpawnSilenceTrap(i: Int, j: Int) {
                    final tile = Battlefield.getTile(i, j);
                    tile.playEffect('Silence');
                    if (tile.hasUnit()) {
                        tile.unitOnIt.silence();
                    } else if (tile.hasTrap()) {
                        tile.trapOnIt.kill();
                    }
                    final trap = Battlefield.spawnTrap('Silence Trap', tile);
                    trace('On tile $i $j, spawning trap? ${trap != null}');
                    if (Battlefield.isPlayerTurnNow()) {
                        Battlefield.updateUI();
                    }
                }
                function spawnSilenceTraps() {
                    trySpawnSilenceTrap(2, 3);
                    doAfter(250, () -> {
                        playAudio('ZapCastAudio');
                        trySpawnSilenceTrap(1, 2);
                        trySpawnSilenceTrap(3, 4);
                    });
                    doAfter(500, () -> {
                        playAudio('ZapCastAudio');
                        trySpawnSilenceTrap(0, 1);
                        trySpawnSilenceTrap(4, 5);
                    });
                    doAfter(750, () -> {
                        playAudio('ZapCastAudio');
                        trySpawnSilenceTrap(1, 0);
                        trySpawnSilenceTrap(3, 6);
                    });
                    doAfter(1000, () -> {
                        playAudio('ZapCastAudio');
                        trySpawnSilenceTrap(3, 2);
                        trySpawnSilenceTrap(1, 4);
                    });
                    doAfter(1250, () -> {
                        playAudio('ZapCastAudio');
                        trySpawnSilenceTrap(4, 1);
                        trySpawnSilenceTrap(0, 5);
                    });
                    doAfter(1500, () -> {
                        playAudio('ZapCastAudio');
                        trySpawnSilenceTrap(3, 0);
                        trySpawnSilenceTrap(1, 6);
                    });
                }

                final tyl = UnitsDatabase.spawnUnitNicely('Tyl (2)', tileWhereDied);
                doAfter(1500, () -> {
                    tyl.say('I\'ve had enough of you, foolish mortals!', 3, -55, -53);
                    spawnSilenceTraps();
                    doAfter(3000, () -> {
                        Battlefield.resumeNextTurn();
                        tyl.say('Prepare thy innards. Doom is nigh.', 3, -55, -53);
                    });
                });
            }
        },
        {   name: 'Tyl (2)',    // Lightning Tyl
            description: 'Shoots lightning. Shoots a bolt of acid. Shoots a bouncing ball of electricity. Spawns Slimes.',
            stats: {
                health: 176,
                mana: 69,
                speed: 3,
                damage: 13
            },
            level: 6,
            tags: [IMMUNE_TO_SILENCE, ANIMAL],
            resistances: { shock: 0.8 },
            actorOffsetX: 15,
            isLarge: true,
            damageVariation: 2,
            ai: {
                type: 'restless',
                spellSequence: ['Lightning Rain (Tyl)', 'Fireball Bolt', 'End Turn', 'Bouncing Flame', 'Spawn Slime'],
            },
            spells: ['Fly Move', 'Fireball Bolt', 'Bouncing Flame', 'Lightning Rain (Tyl)', 'Spawn Slime', 'End Turn'],
            audio: {
                onHit:   'TylHitAudio',
                onDeath: 'TylDeathAudio'
            },
            onSpawn: function(self: Unit) {
                self.initCustomString('isPreparingLightning', 'no');
                self.initCustomInt('lightningDamage', 0);

                Battlefield.addOnUnitMoveEvent(function(unit: Unit, previousTile: TileSpace) {
                    if (unit.owner != PLAYER) return;              // Only when players move...
                    if (self.customData.strings['isPreparingLightning'] == 'no') return;
                    self.customData.ints['lightningDamage'] += 5;
                    self.say('Yes! Give my toxins static electricity!', 3);
                    unit.infectRandomUninfectedSpell();
                });

            }
        },
        {   name: 'Demon Portal',
            description: 'Summons an Imp every 2 turns.',
            stats: {
                health: 33,
                speed: 0,
            },
            level: 6,
            resistances: { cold: 2 },
            spells: ['Summon Imp', 'End Turn'],
            audio: {
                onHit:   'PortalHitAudio',
                onDeath: 'PortalDeathAudio'
            },
            ai: {
                spellSequence: ['Summon Imp', 'End Turn']
            }
        },
        {   name: "Imp",
            thumbnailPath: 'auto',
            description: 'Oh sure, send the little guy...',
            stats: {
                health: 26,
                damage: 2,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 0,
                speed: 2
            },
            level: 3,
            resistances: { cold: 1.5, fire: 0.8 },
            damageVariation: 1,
            ai: { type: 'restless' },
            combatStartQuotes: ["THIS WAS NOT IN OUR CONTRACT!"],
            spells: ['Fly Move', 'Melee Attack (Monster)'],
            audio: {
                onHit:   'ImpHitAudio',
                onDeath: 'ImpDeathAudio'
            },
        },
        {   name: 'Royal Guard Stationary',
            animationUsed: 'Royal Guard',
            description: 'Obeys the orders of the King.',
            stats: {
                health: 71,
                damage: 5,
                armor: 35,
                speed: 1
            },
            ai: {
                spellSequence: ['End Turn'] // Only casts spells by order from the King
            },
            level: 3,
            spells: ['End Turn'],
            audio: {
                onHit: 'Human3Audio',
                onDeath: 'Human1Audio'
            },
            tags: [IMMUNE_TO_STUN, IMMUNE_TO_ROOT, IMMUNE_TO_SILENCE, IMMUNE_TO_PUSH, HUMAN],
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                final guards = Battlefield.getAllAliveEnemyUnits().filter(u -> u.name == 'Royal Guard Stationary');
                for (guard in guards) {
                    final remainingHP = guard.health;
                    final tile = guard.tileOn;
                    guard.remove();
                    final newGuard = Battlefield.spawnEnemyOnTile('Royal Guard', tile);
                    newGuard.health = remainingHP;
                    newGuard.updateBars();
                }
                final kingOld = Battlefield.getUnitByName('King Erio');
                if (kingOld == null || kingOld.isDead) return;
                final kingRemainingHealth = kingOld.health;
                final kingTile = kingOld.tileOn;
                kingOld.cancelDelayedSpell();
                kingOld.remove();
                final kingNew = Battlefield.spawnEnemyOnTile('King Erio (2)', kingTile);
                kingNew.say('Your formation is broken!', 3);
                doAfter(4000, () -> {
                    kingNew.say('Free for all, men!', 3);
                });
            }
        },
        {   name: "Royal Guard",
            description: 'Acts like a regular Guard.',
            stats: {
                health: 71,
                damage: 8,
                armor: 35,
                crit: 0,
                dodge: 0,
                initiative: 0,
                mana: 0, 
                spellPower: 0,
                manaRegeneration: 3,
                speed: 2
            },
            level: 3,
            tags: [HUMAN],
            damageVariation: 2,
            onSpawn: (self: Unit) -> {
                self.isImmuneToRoot = true;
                self.isImmuneToSilence = true;
                Battlefield.addOnUnitMoveEvent((unitThatMoved: Unit, previousTile: TileSpace) -> {
                    if (unitThatMoved.isPlayerCharacter()) {
                        self.block++;
                        self.updateBars();
                    }
                });
            },
            spells: ['Move', 'Spear Thrust'],
            audio: {
                onHit: 'Human3Audio',
                onDeath: 'Human1Audio'
            }
        },
        {   name: 'King Erio',
            description: 'Orders guards to throw spears, poke or advance.',
            stats: {
                health: 154,
                mana: 10,
                damage: 8,
                speed: 1
            },
            level: 6,
            tags: [HUMAN],
            damageVariation: 1,
            ai: {
                spellSequence: ['Order: Throw Spear', 'Order: Threaten', 'Order: Advance'],
                overrideSpellSequence: function(self: Unit, currentAISpellIndex: Int): String {
                    if (currentAISpellIndex == 2) { // If Order: Advance
                        function canDoAdvance() {
                            final guards = Battlefield.getAllAliveEnemyUnits().filter(u -> u.name == 'Royal Guard Stationary');
                            for (guard in guards) {
                                final leftTile = guard.tileOn.getNextTileInDirection(LEFT);
                                if (leftTile == null || leftTile.hasUnit()) {
                                    return false;
                                }
                            }
                            return true;
                        }
                        if (canDoAdvance()) {
                            return null;                    // It's ok, just advannce
                        }
                        else {                              // If can't advance...
                            return 'Order: Throw Spear';    // Throw spears
                        }
                    }
                    return null;
                }
            },
            spells: ['Order: Throw Spear', 'Order: Threaten', 'End Turn', 'Order: Advance'],
            audio: {
                onHit:   'KingHitAudio',
                onDeath: 'KingDeathAudio'
            }
        },
        {   name: 'King Erio (2)',
            animationUsed: 'King Erio',
            thumbnailPath: 'Icons/Small/King Erio.png',
            description: 'Throws spoons.',
            stats: {
                health: 154,
                mana: 10,
                damage: 8,
                speed: 1
            },
            level: 6,
            tags: [HUMAN],
            damageVariation: 1,
            ai: {
                type: 'restless',
                spellSequence: ['Throw Spoons'],
            },
            spells: ['Move', 'Throw Spoons'],
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                Battlefield.pauseNextTurn();
                final newKing = UnitsDatabase.spawnUnitNicely('King Erio (3)', tileWhereDied);
                for (i in 0...6) {
                    final tile: TileSpace = Battlefield.getRandomTileWithNoUnit();
                    if (tile != null) {
                        Battlefield.spawnEnemyFromOutOfScreen('Patrolling Guard', tile.getI(), tile.getJ());
                    }
                }
                doAfter(1000, () -> {
                    newKing.say('You have outgrown my patience, heroes.', 2);
                });
                doAfter(4000, () -> {
                    newKing.say('Militia!', 2);
                });
                doAfter(2000, () -> {
                    Battlefield.resumeNextTurn();
                });
            },
            audio: {
                onHit:   'KingHitAudio',
                onDeath: 'KingDeathAudio'
            }
        },
        {   name: 'King Erio (3)',
            thumbnailPath: 'Icons/Small/King Erio.png',
            animationUsed: 'King Erio',
            description: 'Summons cheerios that explode!',
            stats: {
                health: 154,
                mana: 10,
                damage: 8,
                speed: 1
            },
            level: 6,
            tags: [HUMAN],
            damageVariation: 1,
            ai: {
                type: 'restless',
                spellSequence: ['Cheerios', 'Explode Cheerios'],
            },
            spells: ['Move', 'Cheerios', 'Explode Cheerios'],
            audio: {
                onHit:   'KingHitAudio',
                onDeath: 'KingDeathAudio'
            }
        },
        {   name: 'Giant Cheerio',
            description: 'Can be exploded by the King.',
            stats: {
                health: 38,
                armor: -40
            },
            level: 4,
            ai: {
                spellSequence: ['End Turn']
            },
            spells: ['End Turn'],
            audio: {
                onHit:   'CheerioAudio',
                onDeath: 'CheerioAudio'
            }
        },
        {   name: 'Marceline',
            description: 'Sends a wave of Swords that persists through the combat. Shoots a red sword that comes back. Pins a player unit with swords. Summons spirits.',
            stats: {
                health: 483,
                mana: 25,
                damage: 15,
                speed: 3
            },
            level: 6,
            tags: [HUMAN],
            ai: {
                type: 'restless',
                spellSequence: ['Sword Wave', 'Red Spectral Sword', 'Sword Mark', 'Summon Spirit']
            },
            spells: ['Marceline Move', 'Sword Wave', 'Red Spectral Sword', 'Sword Mark', 'Summon Spirit', 'End Turn'],
            audio: {
                onHit:   'MarcelineHahAudio'
            },
            onCombatStart: function(self: Unit) {
                self.initCustomInt('currentPhase', 1);

                self.aiData = {
                    waves: new Array<{ currentCol: Int, direction: Int }>(),
                    previousWaveDirection: LEFT
                };

                Battlefield.addOnUnitMoveEvent(function(unit: Unit, previousTile: TileSpace) {
                    if (unit.hasAttachment('Rotating Sword')) {
                        final tiles = previousTile.getNeighbors(true);
                        for (tile in tiles)
                            tile.removeDangerMarker();

                        final newTiles = unit.tileOn.getNeighbors(true);
                        for (tile in newTiles)
                            tile.addDangerMarker();
                    }
                });

                Battlefield.addAfterUnitTakingDamageEvent(function(source: Unit, victim: Unit, amount: Int, type: Int) {
                    if (victim != self) return;

                    if (self.isHealthBelowPercent(75) && self.customData.ints['currentPhase'] == 1) {
                        self.customData.ints['currentPhase'] = 2;
                        self.say('Let\'s see how you deal with this!');
                        doAfter(1000, function() {
                            var spawnTile = Battlefield.getTile(2, 4);
                            if (spawnTile.hasUnit())
                                spawnTile = spawnTile.getRandomEmptyNeighbor(true);
                            if (spawnTile == null) {
                                doAfter(2000, function() {
                                    self.say('Wh-where\'s my crystal!?');
                                });
                            } else {
                                UnitsDatabase.spawnUnitNicely('Exploding Crystal', spawnTile, PLAYER);
                            }
                        });

                    } else if (self.isHealthBelowPercent(40) && self.customData.ints['currentPhase'] == 2) {
                        self.customData.ints['currentPhase'] = 3;
                        self.say('I summon my ancestors\' greatsword!', 3);
                        doAfter(2000, () -> {
                            final spawnTile = Battlefield.getTile(2, 3);
                            if (spawnTile.hasUnit()) {
                                var pushTile = spawnTile.getRandomEmptyNeighbor();
                                if (pushTile != null) {
                                    self.damageUnit(spawnTile.unitOnIt, self.getDamageWithVariation(), PURE);
                                    self.slideToTile(pushTile);
                                } else {
                                    spawnTile.unitOnIt.kill();
                                }
                            }
                            UnitsDatabase.spawnUnitNicely('Spectral Sword', spawnTile);
                        });
                    }
                });
            },
            onRoundEnd: function(self: Unit) {
                final waves: Array<{ currentCol: Int, direction: Int }> = self.aiData.waves;
                for (wave in waves) {
                    final tiles: Array<TileSpace> = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> j == wave.currentCol);
                    for (tile in tiles) {
                        playAudio('ExplosionAudio');
                        playAudio('RestoreManaAudio');
                        tile.playEffect('Green Explosion', 700);
                        if (tile.hasUnit())
                            self.damageUnit(tile.unitOnIt, self.getDamageWithVariation(), PURE);
                        tile.removeDangerMarker();
                    }
                    startShakingScreen(0.01, 0.25);
                    
                    
                    if (wave.direction == RIGHT)
                        wave.currentCol += 1;
                    else
                        wave.currentCol -= 1;
                }

                // Filter out out of bounds waves
                final newWaves = waves.filter(wave -> wave.currentCol >= 0 && wave.currentCol <= 6);
                self.aiData.waves = newWaves;

                // Add red markers
                for (wave in newWaves) {
                    final tiles: Array<TileSpace> = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> j == wave.currentCol);
                    for (tile in tiles)
                        tile.addDangerMarker();
                }
            }
        },
        {   name: 'Sandman',
            description: 'Summons piles of Sand that INFECT. If a unit is hit directly, it is STUNNED.',
            stats: {
                health: 100,
                mana: 10,
                damage: 8,
                speed: 2
            },
            level: 6,
            tags: [HUMAN],
            ai: {
                type: 'restless',
                spellSequence: ['Move Or Sleep', 'Lights Off']
            },
            spells: ['Fly Move', 'Move Or Sleep', 'Lights Off', 'End Turn'],
            afterDeath: function(self: Unit, tileWhereDied: TileSpace) {
                final sandman = UnitsDatabase.spawnUnitNicely('Sandman (2)', tileWhereDied);
                doAfter(1500, () -> {
                    sandman.say('NOT IN YOUR DREAMS!!', 2);
                });
            }
        },
        {   name: 'Sandman (2)',
            description: 'Summons piles of Sand that INFECT. If a unit is hit directly, it is STUNNED. Summons Moons that hatch Simulacra.',
            stats: {
                health: 100,
                mana: 10,
                damage: 9,
                speed: 4
            },
            level: 6,
            tags: [HUMAN],
            ai: {
                type: 'restless',
                spellSequence: ['Simulacrum', 'Move Or Sleep', 'Lights Off']
            },
            spells: ['Fly Move', 'Simulacrum', 'Move Or Sleep', 'Lights Off', 'End Turn'],
        },
        {   name: 'Full Moon',
            description: 'Will soon hatch into something... beautiful!',
            stats: {
                health: 20,
                damage: 0,
                armor: 10,
                speed: 0,
                initiative: 1,
            },
            level: 6,
            spells: ['End Turn'],
            audio: {
                onHit:   'RockHitAudio',
                onDeath: 'RockDeathAudio'
            },
            onRoundEnd: function(self: Unit) {
                if (self.isDead) return;
                if (self.customData.ints.exists('turnsToMorph') == false) {
                    self.customData.ints['turnsToMorph'] = 2;
                } else {
                    self.customData.ints['turnsToMorph'] --;
                }
                if (self.customData.ints['turnsToMorph'] == 0) {
                    final tile = self.tileOn;
                    self.playEffect('Sand');
                    self.kill();
                    final possibleCrystals = Player.characters.map(pc -> pc.getClassName() + ' Simulacrum');    // e.g "Knight Simulacrum", "Mage Simulacrum" or "Ranger Simulacrum"
                    final crystal: String = randomOf(possibleCrystals);
                    Battlefield.spawnEnemyOnTile(crystal, tile);
                }
            }
        },
        {   name: "Knight Simulacrum",
            thumbnailPath: 'auto',
            description: 'Must... block...',
            stats: {
                health: 30,
                damage: 3,
                mana: 10,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                spellPower: 10,
                manaRegeneration: 0,
                speed: 2
            },
            level: 3,
            tags: [HUMAN],
            damageVariation: 2,
            ai: { type: 'advancer', spellSequence: ['Melee Attack (Monster)', 'Block (Monster)']},
            spells: ['Move', 'Melee Attack (Monster)', 'Block (Monster)'],
            audio: {
                onHit: 'Human2Audio',
                onDeath: 'Human1Audio'
            }
        },
        {   name: "Ranger Simulacrum",
            thumbnailPath: 'auto',
            description: 'Arrows... arrows... arrows...',
            stats: {
                health: 37,
                mana: 10,
                damage: 3,
                armor: 0,
                crit: 50,
                dodge: 0,
                initiative: 0,
                spellPower: 0,
                manaRegeneration: 0,
                speed: 3
            },
            level: 3,
            tags: [HUMAN],
            damageVariation: 2,
            ai: { type: 'shooter' },
            spells: ['Move', 'Throw Net (Enemy)', 'Shoot Arrow Delayed'],
            audio: {
                onHit: 'RangerHitAudio',
                onDeath: 'RangerDeathAudio'
            },
            onCombatStart: function(self: Unit) {
                putThrowNetOnRandomCooldown(self);
            },
            onTurnStart: function(self: Unit) {
                addAttachmentIfWillThrowNetNextTurn(self);
            }
        },
        {   name: 'Mage Simulacrum',
            thumbnailPath: 'auto',
            description: 'DARK DARK LONELY SO LONELY BLIND WHERE ARE MY EYES I CAN\'T SEE',
            stats: {
                health: 25,
                mana: 10,
                damage: 3,
                armor: 0,
                crit: 0,
                dodge: 0,
                initiative: 0,
                spellPower: 10,
                manaRegeneration: 0,
                speed: 2
            },
            level: 3,
            tags: [HUMAN],
            damageVariation: 2,
            ai: { type: 'restless' },
            spells: ['Move', 'Iceberg Drop (Enemy)', 'Magic Arrow (Enemy)', 'End Turn'],
            audio: {
                onHit: 'MageHitAudio',
                onDeath: 'MageDeathAudio'
            }
        },
        
        {   name: 'Spectral Sword',
            description: 'Barrages an area shaped like rombus.',
            stats: {
                health: 125,
                damage: 15,
                speed: 0
            },
            tags: [FEARFUL],
            ai: {
                spellSequence: ['Sword Barrage Close', 'Sword Barrage Medium', 'Sword Barrage Far']
            },
            spells: ['Sword Barrage Close', 'Sword Barrage Medium', 'Sword Barrage Far']
        },
        {   name: 'Red Spectral Sword',
            description: 'Returns in the direction it was shot.',
            stats: {
                health: 47,
                damage: 13,
                speed: 0
            },
            tags: [FEARFUL],
            ai: {
                spellSequence: ['End Turn', 'Shoot Sword In Direction']
            },
            spells: ['End Turn', 'Shoot Sword In Direction', 'Shoot Sword']
        },
        {   name: "Evil Paprika Spirit",
            description: 'Acts like a regular Evil Paprika.',
            stats: {
                health: 15,
                damage: 12,
                speed: 2
            },
            tags: [ENEMY_PLANT],
            combatStartQuotes: ["Bleaaghh!!"],
            spells: ['Move', 'Spike Rush'],
            audio: {
                onHit:   'EvilPaprikaHitAudio',
                onDeath: 'EvilPaprikaDeathAudio'
            }
        },
        {   name: "Pumpkin Tentacle Spirit",
            description: 'Acts like a regular Pumpkin Tentacle.',
            stats: {
                health: 15,
                damage: 12,
                initiative: 2
            },
            tags: [ENEMY_PLANT],
            ai: {
                type: 'canon',
                spellSequence: ['End Turn', 'Spike Rush Long']
            },
            audio: {
                onHit:   'PumplingHitAudio',
                onDeath: 'PumplingDeathAudio'
            },
            combatStartQuotes: ["*Squiggly squig*"],
            spells: ['Spike Rush Long', 'End Turn']
        },
        {   name: "Spore Keeper Spirit",
            description: 'Acts like a regular Spore Keeper.',
            stats: {
                health: 15,
                damage: 5, 
                spellPower: 10,
            },
            damageVariation: 1,
            tags: [ENEMY_PLANT],
            spells: ['Spore Infection'],
            audio: {
                onHit:   'SporeKeeperHitAudio',
                onDeath: 'SporeKeeperDeathAudio'
            }
        },
    ];



    static function trySpawnUnitAroundTile(unitName: String, onTile: TileSpace): Unit {
        if (onTile.hasUnit() == false) {
            return Battlefield.spawnEnemy(unitName, onTile.getI(), onTile.getJ());
        } else {
            final nearbyTile = onTile.getRandomEmptyNeighbor();
            if (nearbyTile != null) {
                return Battlefield.spawnEnemy(unitName, nearbyTile.getI(), nearbyTile.getJ());
            } else {
                return null;
            }
        }
    }
    static function spawnSpatulaUnleashed(tile: TileSpace) {
        final csu = UnitsDatabase.spawnUnitNicely('Count Spatula Unleashed', tile);
        final neutrals = Battlefield.getAllAliveNeutralUnits();
        for (unit in neutrals) {
            unit.kill();
        }
        Battlefield.customData.strings['isSpatulaAlive'] = 'yes';    // To prevent respawn, in onCombatStart
        csu.say('Now...', 2);
        doAfter(3000, () -> {
            csu.say('I AM COMPLETE!', 2);
        });
        function spawnBloodbath(i: Int, j: Int): Void {
            if (Battlefield.getTile(i, j).hasTrap()) {
                trace('Killing trap ${Battlefield.getTile(i, j).trapOnIt.name}');
                Battlefield.getTile(i, j).trapOnIt.kill();
            }
            trace('Spawning at ${i} ${j}');
            final bb = Battlefield.spawnTrap('Bloodbath', i, j);
            trace('Null?');
            if (bb != null) {
                trace('Not null!');
                bb.tileOn.playEffect('Enrage', 1150);
                playAudio('ChargeAudio');
            } else {
                trace('Null!! WTF');
            }
        }
        doAfter(250, () -> spawnBloodbath(1, 1));
        doAfter(500, () -> spawnBloodbath(4, 0));
        doAfter(750, () -> spawnBloodbath(4, 2));
        doAfter(1000, () -> spawnBloodbath(2, 3));
        doAfter(1250, () -> spawnBloodbath(0, 5));
        doAfter(1500, () -> spawnBloodbath(3, 5));
    }

    static function empowerBigBoyo() {
        var big: Unit = Battlefield.getUnitByName('Big Boyo');
        if (big == null)
            big = Battlefield.getUnitByName('Big Boyo Wasp');
        if (big == null)
            return false;
        big.stats.damage += 3;
        flashRed(big.actor, 350);
        big.scrollRed('+3 DMG');
        return true;
    }
    static function empowerLilMunchy() {
        var lil: Unit = Battlefield.getUnitByName('Lil Munchy');
        if (lil == null)
            lil = Battlefield.getUnitByName('Lil Munchy Centipede');
        if (lil == null)
            return false;
        lil.stats.damage += 3;
        flashRed(lil.actor, 350);
        lil.scrollRed('+3 DMG');
        return true;
    }
    static function empowerSuzanna() {
        var su: Unit = Battlefield.getUnitByName('Suzanna the Fair');
        if (su == null)
            su = Battlefield.getUnitByName('Suzanna the Fair Spider');
        if (su == null)
            return false;
        su.stats.dodge += 25;
        su.stats.speed += 2;
        flashRed(su.actor, 350);
        su.scrollRed('+25 DODGE +2 SPD');
        return true;
    }
    static function willCastSpellNextTurn(unit: Unit, spell: String) {
        trace('currentAISpellIndex: ${unit.currentAISpellIndex}');
        trace('unit.unitTemplate.ai.spellSequence: ${unit.unitTemplate.ai.spellSequence}');
        if (unit.unitTemplate == null) return false;
        if (unit.currentAISpellIndex == -1) return false;
        if (unit.unitTemplate.ai == null) return false;
        if (unit.unitTemplate.ai.spellSequence == null) return false;
        if (unit.unitTemplate.ai.spellSequence.length == 0) return false;
        final spellSequence = unit.unitTemplate.ai.spellSequence;
        var currentAISpellIndex = unit.currentAISpellIndex;
        if (currentAISpellIndex == spellSequence.length)
            currentAISpellIndex = 0;
        var nextAISpellIndex = currentAISpellIndex + 1;
        if (nextAISpellIndex == spellSequence.length)
            nextAISpellIndex = 0;
        trace('nextAISpellIndex: ${nextAISpellIndex}');
        trace('spellSequence[nextAISpellIndex] == spell: ${spellSequence[nextAISpellIndex] == spell}');
        return spellSequence[nextAISpellIndex] == spell;
    }

    static function addAttachmentIfWillThrowNetNextTurn(self: Unit) {
        if (self.getSpell('Throw Net (Enemy)').cooldownRemaining == 2) {
            self.addAttachment('Has Net', 24, 16);
            self.addBuff(new Buff('Will Root', 2));
        }
    }
    static function putThrowNetOnRandomCooldown(self: Unit) {
        self.getSpell('Throw Net (Enemy)').cooldownRemaining = randomIntBetween(3, 7);
    }
}




class UnitsDatabase
{

	public static var unitsByName	: Map<String, UnitTemplate>;
	public static var unitsById		: Array<UnitTemplate>;

	public static function get(?id : Int, ?name : String) {
		if (id != null) {
			return unitsById[id];
		} else {
            if (!unitsByName.exists(name))
                throwAndLogError('Unit with name ${name} does not exist');
			return unitsByName[name];
		}
    }
    
    public static function unitExists(unitName: String) return unitsByName.exists(unitName);
	
	public static function load(){
		unitsByName = new Map<String, UnitTemplate>();
		unitsById	= [];
		var unitTemplates : Array<Dynamic> = null;
        try {
            // unitTemplates = readJSON("Databases/UnitTemplates.json");	// Array of UnitTemplate
            unitTemplates = UnitsDatabase_Units.database;
        } catch (e : String) {
            trace(e);
            throwAndLogError('Failed to load Unit database');
        }
        for(u in unitTemplates){
            var unitTemplate = UnitTemplate.createFromDynamic(u);
            unitTemplate.id = unitsById.length;
            unitsById.push(unitTemplate);
            unitsByName[unitTemplate.name] = unitTemplate;
        }
		//trace('Loaded units...');
	}

    public static function spawnUnitNicely(unitName: String, tile: TileSpace, owner: Int = ENEMY) {
        Battlefield.preventNextTurnOnce();  // If it would happen meanwhile, prevent the transition to next turn
        var blackOverlay = new ImageX('UI/BlackScreen.png', 'Underlay');
        blackOverlay.centerOnScreen();
        blackOverlay.setAlpha(0.7);
        var vampire = Battlefield.spawnUnit(unitName, tile.getI(), tile.getJ(), owner);
        vampire.actor.moveToLayer(getLayer('Other'));
        vampire.actor.disableActorDrawing();
        vampire.spells = vampire.spells.filter(s -> s.isPassive() == false);
        doAfter(500, () -> {
            playAudio('Phase2Audio');
        });
        doAfter(1000, () -> {
            vampire.actor.enableActorDrawing();
            var lightning = createActor('SpecialEffectActor', 'Other');
            lightning.setAnimation('Lightning Strike');
            setXCenter(lightning, vampire.actor.getXCenter());
            setYBottom(lightning, vampire.tileOn.getYCenter() - 10);
            for (i in 0...3) {
                final randomTile = tile.getRandomNeighbor(true);
                if (randomTile.hasTrap() == false) {
                    Trap.createFromTemplateByName('Fire', randomTile);
                }
            }
            flashWhite(vampire.actor, 800, () -> {
                killActor(lightning);
                blackOverlay.kill();
                vampire.actor.moveToLayer(getLayer('Units${tile.getI()}'));
                vampire.actor.moveToBottom();           // In the same layer, to make attachments appear properly
            });
            doAfter(1500, () -> {
                if (Battlefield.didPreventNextTurn) {   // If the next turn was prevented
                    Battlefield.nextTurn();             // Trigger next turn
                } else {
                    Battlefield.unpreventNextTurn();    // Else, continue normally
                }
            });
        });
        return vampire;
    }

}