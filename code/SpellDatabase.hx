

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
import com.stencyl.Data;

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
import Math.min;
import Math.max;

import U.*;
import scripts.Constants.*;
import scripts.SpecialEffectsFluff.*;

import scripts.Battlefield.pauseNextTurn;
import scripts.Battlefield.resumeNextTurn;

using U;
using Lambda;

class SpellDatabase_Spells {
	public static var spells: Array<Dynamic> = [
		
		// ACtives for All
		{	name: 'Time Warp',
			description: 'Reset all your cooldowns. Usable once per combat.',
			manaCost: 3,
			isInstant: true,
			isFreeAction: true,
			cooldown: 99,
			effect: {
				type: 'NO_EFFECT'
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				caster.playEffect('Time Warp');
				caster.resetSpellCooldowns();
				caster.getSpell('Time Warp').cooldownRemaining = 99;
			},
			audio: {
				onCast: 'ImplosionAudio'
			}
		},
		
		// Unlockable Passives	
		{	name: 'Kill Block',
			description: 'After you kill a unit, cast Block for free!',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						Battlefield.addAfterUnitTakingDamageEvent(function(source: Unit, target: Unit, amount: Int, type: Int) {
							if (self == source && target.isDead) {
								self.addBlock(int(self.getSpellPowerWithVariation() * 0.6));
								self.updateBars();
								self.playEffect('Block', 1500);
							}
						});
					}
				}
			}
		},
		{	name: 'Long Reach',
			description: 'Increases the range of Melee Attack by 1 (hits only 1 target though)',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.replaceEquippedSpell('Melee Attack', 'Melee Attack Long');
					},
					unlearn: function(pc: PlayerCharacter) {
						pc.replaceEquippedSpell('Melee Attack Long', 'Melee Attack');
					},
				}
			}
		},

		{	name: 'Fox Companion',
			description: 'At the start of every combat, summon a Fox Companion! It has 35% of your HP and 35% of your DMG.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						var foxSpawnTile = self.tileOn.getRandomEmptyNeighbor();
						if (foxSpawnTile == null) {
							self.say('No space for my fox!');
							return;
						}
						Battlefield.spawnUnit('Fox', foxSpawnTile.getI(), foxSpawnTile.getJ(), PLAYER);
					}
				}
			}
		},
		{	name: 'Quickfoot',
			description: 'You permanently gain +1 Movement.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						self.stats.speed++;
					}
				}
			}
		},
		{	name: 'Longdraw',
			description: 'Increases the range of Shoot Arrow by 1.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.replaceEquippedSpell('Shoot Arrow', 'Shoot Arrow Long');
					}
				}
			}
		},
		{	name: 'Steady Shooting',
			description: 'Every 2nd Shoot Arrow on the same target deals 35% extra damage.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit) {
						self.initCustomString('hasSteadyShooting', 'yes');
					}
				}
			}

		},

		{	name: 'Flex Arrow',
			description: 'Magic Arrow becomes castable in a regular line as well.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.replaceEquippedSpell('Magic Arrow', 'Magic Arrow (Any)');
					},
					unlearn: function(pc: PlayerCharacter) {
						pc.replaceEquippedSpell('Magic Arrow (Any)', 'Magic Arrow');
					},
				}
			}
		},
		{	name: 'Shocking Startup',
			description: 'On combat start, damage a random enemy for @(16 + 50% SP).',
			value: (caster: EntityWithStats, atIndex: Int) -> 16 + int(caster.stats.spellPower * 0.5),
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						final randomEnemy: Unit = randomOf(Battlefield.getAllAliveEnemyUnits());
						randomEnemy.playEffect('Lightning Strike', 800);
						playAudio('LightningStrikeAudio');
						self.damageUnit(randomEnemy, 16 + int(self.getSpellPowerWithVariation(SHOCK)), SHOCK);
					}
				}
			}
		},

		{	name: 'Rabbit Foot',
			description: 'Every time you move by any means, increase your damage done by 10% for each 1 distance traveled.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						self.customData.ints['rabbitFoot'] = 0;
						trace('QUACK');
						Battlefield.addOnUnitMoveEvent(function(unit: Unit, previousTile: TileSpace) {
							if (self != unit) return;
							final distanceTraveled = unit.tileOn.getDistanceToTile(previousTile);
							trace('Unit ${unit.name} moved ${distanceTraveled}');
							self.customData.ints['rabbitFoot'] += distanceTraveled * 10;
							self.damageDoneMultiplier += distanceTraveled * 0.1;
							trace('Multiplier is now ${self.damageDoneMultiplier}');
							self.scrollRed('+${distanceTraveled * 10}% DAMAGE');
						});
						Battlefield.addOnRoundEndEvent(function(roundNr: Int) {
							self.damageDoneMultiplier -= self.customData.ints['rabbitFoot'] / 100;
							self.customData.ints['rabbitFoot'] = 0;
						});
					}
				}
			},
		},
		{	name: 'Momentum Magic',
			description: 'After every ability you use, gain 1 or 2 (randomly) SP until the end of the turn.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						self.customData.ints['momentumMagicSP'] = 0;
						Battlefield.addAfterUnitCastSpellEvent(function(unit: Unit, spell: Spell, tile: TileSpace) {
							if (self != unit) return;
							final extraSP = randomIntBetween(1, 2);
							self.stats.spellPower += extraSP;
							self.customData.ints['momentumMagicSP'] += extraSP;
						});
						Battlefield.addOnRoundEndEvent(function(roundNr: Int) {
							self.stats.spellPower -= self.customData.ints['momentumMagicSP'];
							self.customData.ints['momentumMagicSP'] = 0;
						});
					}
				}
			},
		},
		{	name: 'Everblocker',
			description: 'After every ability you use, gain 1 or 2 (randomly) BLOCK.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						Battlefield.addAfterUnitCastSpellEvent(function(unit: Unit, spell: Spell, tile: TileSpace) {
							if (self != unit) return;
							self.addBlock(randomIntBetween(1, 2), { textDelay: 500 });
						});
					}
				}
			}
		},
		{	name: 'Hero Health',
			description: 'Regenerate an extra 3 Health after every combat.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT'
			},
			customData: {
				healAmount: 3
			}
		},	
		{	name: 'Elementulus',
			description: 'You ignore elemental resistances, but vulnerabilities still work (that\'s a good thing)!',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						self.doesIgnoreResistances = true;
					}
				}
			},
		},
		{	name: 'Vampirism',
			description: 'Whenever you kill an enemy, heal for @(3 + 15% SP).',
			value: (self: Unit) -> 3 + int(self.stats.spellPower * 0.15),
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						Battlefield.addAfterUnitTakingDamageEvent(function(source: Unit, victim: Unit, damage: Int, type: Int) {
							if (self == source && victim.isDead) {
								self.heal(3 + int(self.stats.spellPower * 0.15));
								self.playEffect('Lifesteal', 1100);
								playAudio('LifestealAudio');
							}
						});
					}
				}
			},
		},

		{	name: 'Soul Drain',
			description: 'This hero gains +1 Health for every enemy it kills',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						if (!!!self.isPlayerCharacter()) return;
						Battlefield.addOnUnitDeathEvent((killer: Unit, victim: Unit) -> {
							if (killer == self && victim.owner == ENEMY) {
								killer.stats.health += 1;
								killer.heal(1);
								killer.playerCharacter.stats.health += 1;
								final victimPoint = victim.getCenterPoint();
								final killerPoint = killer.getCenterPoint();
								trace('Missiling from ${victimPoint.toString()} to ${killerPoint.toString()}');
								Effects.sendMissileAndThen(victimPoint, killerPoint, 'Soul', Effects.SLOW, function() {
									if (killer.isDead) return;
									killer.playEffect('Siphon Mana', 500);
								});
							}
						});
					}
				}
			}
		},
		{	name: 'Unholy Revival',
			description: 'When you die in combat, revive with 25% of total Health, but only ONCE. Doctors HATE it!',
			isPassive:  true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit): Void {
						self.preventDeathAnimationOnce = true;
						Battlefield.addAfterUnitDeathEvent((unit: Unit, tileWhereDied: TileSpace) -> {
							if (unit != self) return;
							if (!!!unit.isPlayerCharacter()) return;
							if (!!!unit.playerCharacter.hasSpell('Unholy Revival')) return;
							final health = int(unit.stats.health * 0.25);
							unit.revive(tileWhereDied, health);
							unit.playerCharacter.unequipSpell('Unholy Revival');
							final effectPoint = tileWhereDied.getCenterPoint();
							effectPoint.y -= 85;
							unit.flinch(() -> {
								unit.resetActorPosition();
								unit.actor.disableActorDrawing();
								Effects.playParticleAndThen(effectPoint, effectPoint, 'Unholy Revival', 1200);
								playAudio('UnholyRevivalAudio');
								doAfter(600, () -> {
									unit.actor.enableActorDrawing();
									flashWhite(unit.actor, 500);
								});
							});
						});
					}
				}
			}
		},
		{	name: 'Tuberculosis',
			description: 'You have -15% Dodge, -15% Crit and -10% Armor for 3 battles. Careful when interacting with dead people!',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(playerCharacter: PlayerCharacter) {
						playerCharacter.customData.ints['tuberculosisDuration'] = 3;
					},
					combatStart: function(self: Unit): Void {
						self.stats.dodge -= 15;
						self.stats.crit -= 15;
						self.stats.armor -= 10;
						// self.actor.setFilter([createTintFilter(Utils.getColorRGB(255,200,0), 1)]);
					},
					combatEnd: function(self: Unit): Void {
						final playerCharacter = self.playerCharacter;
						playerCharacter.customData.ints['tuberculosisDuration'] -= 1;
						if (playerCharacter.customData.ints['tuberculosisDuration'] <= 0) {
							playerCharacter.unequipSpell('Tuberculosis');
						}
					}
				}
			}
		},

		{	name: 'Flaming Passion',
			description: 'Increase all FIRE damage you deal by 25%.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.amplifications.fire += 0.25;
					},
					unlearn: function(pc: PlayerCharacter) {
						pc.amplifications.fire -= 0.25;
					},
				}
			}
		},
		{	name: 'Electric Vibe',
			description: 'Increase all SHOCK damage you deal by 25%.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.amplifications.shock += 0.25;
					},
					unlearn: function(pc: PlayerCharacter) {
						pc.amplifications.shock -= 0.25;
					},
				}
			}
		},
		{	name: 'Cold Stare',
			description: 'Increase all COLD damage you deal by 25%.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.amplifications.cold += 0.25;
					},
					unlearn: function(pc: PlayerCharacter) {
						pc.amplifications.cold -= 0.25;
					},
				}
			}
		},
		{	name: 'Dark Thoughts',
			description: 'Increase all DARK damage you deal by 25%.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.amplifications.dark += 0.25;
					},
					unlearn: function(pc: PlayerCharacter) {
						pc.amplifications.dark -= 0.25;
					},
				}
			}
		},

		{	name: 'Fire Heart',
			description: 'Reduce all FIRE damage you take by 25%.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.resistances.fire -= 0.25;
					},
					unlearn: function(pc: PlayerCharacter) {
						pc.resistances.fire += 0.25;
					}
				}
			}
		},
		{	name: 'Winter Wonder',
			description: 'Reduce all COLD damage you take by 25%.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.resistances.cold -= 0.25;
					},
					unlearn: function(pc: PlayerCharacter) {
						pc.resistances.cold += 0.25;
					}
				}
			}
		},
		{	name: 'Iron Deficiency',
			description: 'Reduce all SHOCK damage you take by 25%, but reduces your total Health by 1.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.resistances.shock -= 0.25;
						pc.stats.health -= 1;
						if (pc.health > pc.stats.health) pc.health = pc.stats.health;
					},
					unlearn: function(pc: PlayerCharacter) {
						pc.resistances.shock += 0.25;
						pc.stats.health += 1;
						pc.health += 1;
					}
				}
			}
		},
		{	name: 'Meditator',
			description: 'Reduce all DARK damage you take by 25%.',
			isPassive: true,
			effect: {
				type: 'NO_EFFECT',
				events: {
					learn: function(pc: PlayerCharacter) {
						pc.resistances.dark -= 0.25;
					},
					unlearn: function(pc: PlayerCharacter) {
						pc.resistances.dark += 0.25;
					}
				}
			}
		},

		// Hardcoded Passives
		{	name: 'Prop Breaker',		// Hardcoded
			description: 'When put on an AI unit, it will also try to break props.',
			isPassive: true,
			effect: { type: 'NO_EFFECT' }
		},
		{	name: 'Player Owned',		// Hardcoded
			description: 'A unit with this passive is owned by the player',
			isPassive: true,
			effect: { type: 'NO_EFFECT' }
		},
		{	name: 'Flyer',
			description: 'A unit with this passive can fly over units and obstacles',
			isPassive: true,
			effect: { type: 'NO_EFFECT' }
		},
		{	name: 'Fiery Presence',
			description: 'All attacks and spells deal extra damage equal to 50% of your Level (rounded up).',
			isPassive: true,
			effect: { type: 'NO_EFFECT' }
		},
		

		// Base Actives
		{	name: "Melee Attack (Monster) (Cold)",	// Like for player, but costs 0 mana
			isDefault: true,
			description : "Make an attack on a close enemy for @(100% ATK) COLD damage!",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.damage,
			range : 1,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up	: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL);
			},
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Splash",
				duration: 0.5
			},
			audio: { onCast: 'MeleeAttackAudio' }
		},
		{	name: "Melee Attack (Monster) (Pure)",	// Like for player, but costs 0 mana
			isDefault: true,
			description : "Make an attack on a close enemy for @(100% ATK) PURE damage!",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.damage,
			range : 1,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up	: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				caster.damageUnit(target, caster.getDamageWithVariation(), PURE);
			},			
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Acid",
				duration: 0.5
			},
			audio: { onCast: 'MeleeAttackAudio' }
		},
		{	name: "Melee Attack (Monster)",	// Like for player, but costs 0 mana
			isDefault: true,
			description : "Make an attack on a close enemy for @(100% ATK) damage!",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.damage,
			range : 1,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL);
			},
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: { onCast: 'MeleeAttackAudio' }
		},
		{	name: "Melee Attack",
			isDefault: true,
			description : "Make an attack on a close target for @(100% ATK) damage! Deals 35% extra damage if the target is stunned!",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.damage,
			range : 1,
			cooldown: 1,
			manaCost: 5,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up	: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, int(caster.getDamageWithVariation() * if (target.isStunned()) 1.35 else 1), PHYSICAL),
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: { onCast: 'MeleeAttackAudio' }
		},
		{	name: "Melee Attack Long",
			isDefault: true,
			description : "Make an attack for @(100% ATK) damage. Deals 35% extra damage if the target is stunned!",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.damage,
			range : 2,
			cooldown: 1,
			manaCost: 5,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up	: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster, target) -> int(caster.damageUnit(target, caster.getDamageWithVariation() * if (target.isStunned()) 1.35 else 1, PHYSICAL)),
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: { onCast: 'MeleeAttackAudio' }
		},
		{	name: "Melee Attack Diagonal",
			description : "Make an attack on a close enemy!",
			range : 1,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft: true,
					upRight: true,
					downLeft: true,
					downRight: true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL),
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: { onCast: 'MeleeAttackAudio' }
		},
		{	name: "Shoot Arrow (Enemy)",
			description : "Shoot an arrow in a direction for @(100% ATK) damage!",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.damage,
			range : 4,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				target.initCustomInt('nArrowsStuck', 0);
				target.customData.ints['nArrowsStuck'] += 1;
				var damageDone = caster.getDamageWithVariation();
				if (
					caster.customData.strings.exists('hasSteadyShooting') &&	// from the Steady Shooting passive
					target.customData.ints['nArrowsStuck'] % 2 == 0
				) {
					damageDone += int(0.5 * caster.getDamageWithVariation());
					playAudio('SteadyShootingAudio');
				}
				caster.damageUnit(target, damageDone, PHYSICAL);
			},
			missile : {
				animationName : "Arrow",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'ShootArrowCastAudio',
				onHit: 'ShootArrowHitAudio'
			}
		},
		{	name: "Shoot Arrow Delayed",
			description : "Shoot an arrow in a direction for @(100% ATK) damage!",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.damage,
			range : 4,
			effect : {
				isDelayed: true,
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				target.initCustomInt('nArrowsStuck', 0);
				target.customData.ints['nArrowsStuck'] += 1;
				var damageDone = caster.getDamageWithVariation();
				if (
					caster.customData.strings.exists('hasSteadyShooting') &&	// from the Steady Shooting passive
					target.customData.ints['nArrowsStuck'] % 2 == 0
				) {
					damageDone += int(0.5 * caster.getDamageWithVariation());
					playAudio('SteadyShootingAudio');
				}
				caster.damageUnit(target, damageDone, PHYSICAL);
			},
			missile : {
				animationName : "Arrow",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'ShootArrowCastAudio',
				onHit: 'ShootArrowHitAudio'
			}
		},
		{	name: "Shoot Arrow",
			description : "Shoot an arrow in a direction for @(100% ATK) damage! Resets your Move ability if it hits something. Deals 50% less damge point-blank.",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.damage,
			range : 4,
			cooldown: 1,
			manaCost: 5,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				target.initCustomInt('nArrowsStuck', 0);
				target.customData.ints['nArrowsStuck'] += 1;
				var damageDone = caster.getDamageWithVariation();
				if (
					caster.customData.strings.exists('hasSteadyShooting') &&	// from the Steady Shooting passive
					target.customData.ints['nArrowsStuck'] % 2 == 0
				) {
					damageDone += int(0.35 * caster.getDamageWithVariation());
					playAudio('SteadyShootingAudio');
				}
				if (caster.isRooted == false) {
					caster.getMoveSpell().cooldownRemaining = 0;
					caster.getMoveSpell().isWasted = false;
				}
				if (target.tileOn.getDistanceToTile(caster.tileOn) == 1) damageDone = int(damageDone / 2);
				caster.damageUnit(target, damageDone, PHYSICAL);
			},
			missile : {
				animationName : "Arrow",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'ShootArrowCastAudio',
				onHit: 'ShootArrowHitAudio'
			}
		},
		{	name: "Shoot Arrow Long",
			description : "Shoot an arrow in a direction for @(100% ATK) damage! Resets your Move ability if it hits something. Deals 50% less damge point-blank.",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.damage,
			range : 5,
			cooldown: 1,
			manaCost: 5,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				target.initCustomInt('nArrowsStuck', 0);
				target.customData.ints['nArrowsStuck'] += 1;
				var damageDone = caster.getDamageWithVariation();
				if (
					caster.customData.strings.exists('hasSteadyShooting') &&	// from the Steady Shooting passive
					target.customData.ints['nArrowsStuck'] % 2 == 0
				) {
					damageDone += int(0.35 * caster.getDamageWithVariation());
					playAudio('SteadyShootingAudio');
				}
				caster.getMoveSpell().cooldownRemaining = 0;
				if (caster.isRooted == false) caster.getMoveSpell().isWasted = false;
				if (target.tileOn.getDistanceToTile(caster.tileOn) == 1) damageDone = int(damageDone / 2);
				caster.damageUnit(target, damageDone, PHYSICAL);
			},
			missile : {
				animationName : "Arrow",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'ShootArrowCastAudio',
				onHit: 'ShootArrowHitAudio'
			}
		},
		{	name: "Move",
			isDefault: true,
			description	: "Move @tiles (number of tiles equal to your speed). Restores 1 mana. Does not reduce cooldowns.",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.speed,
			isFreeAction: true,
			cooldown	: 0,
			effect		: {
				type	: "NORMAL_MOVE"
			},
			missile	: {},
			targetEffect : {},
			onTargetedTile: function(self: Unit, _: TileSpace) {
				if (self.owner == PLAYER) {
					self.replenish(1);
					self.getMoveSpell().cooldownRemaining = 0;
					self.getMoveSpell().isWasted = true;
				}
			},
			audio: { onCast: 'MoveAudio' }
		},
		{	name: "Horse Move",
			isDefault: true,
			description	: "Move in the shape of L, like chess.",
			isFreeAction: true,
			effect		: {
				type	: "HORSE_MOVE"
			},
			missile	: {},
			targetEffect : {},
			audio: { onCast: 'MoveAudio' }
		},
		{	name: "Natas Move",
			isDefault: true,
			description	: "Teleport in a fiery way!",
			isFreeAction: true,
			effect		: {
				type	: "TELEPORT_MOVE"
			},
			missile	: {},
			targetEffect : {
				animationName: "Circular Fire",
				duration: 0.9
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'FoomAudio'
			}
		},
		{	name: "Marceline Move",
			isDefault: true,
			description	: "Teleport in a marceliny way!",
			isFreeAction: true,
			effect		: {
				type	: "TELEPORT_MOVE"
			},
			missile	: {},
			targetEffect : {
				animationName: "Marceline Teleport",
				duration: 1.45
			}
		},
		{	name: "Fly Move",
			isDefault: true,
			description	: "Fly to the location (over obstacles).",
			isFreeAction: true,
			effect		: {
				type	: "FLY_MOVE"
			},
			audio: { onCast: 'MoveAudio' },
			missile	: {},
			targetEffect : {}
		},
		{	name: "Crystal Move",
			isDefault: true,
			description	: "Moves 1 tile diagonally. By default, it tries to move down-left.",
			isFreeAction: true,
			effect		: {
				type	: "CRYSTAL_MOVE"
			},
			audio: { onCast: 'MoveAudio' },
			missile	: {},
			targetEffect : {}
		},
		{	name: "Diagonal Move",
			isDefault: true,
			description	: "Moves diagonally.",
			isFreeAction: true,
			effect		: {
				type	: "PLAYER_CRYSTAL_MOVE"
			},
			audio: { onCast: 'MoveAudio' },
			missile	: {},
			targetEffect : {}
		},
		
		{	name: "End Turn",
			isDefault: true,
			description : "End your turn.",
			isInstant : true,
			effect : {
				type : "END_TURN"
			},
			missile : {},
			targetEffect : {},
			audio: { onCast: 'MoveAudio' }
		},

		// Knight Actives
		{	name: "Charge",
			description : "Move straight 2 tiles and damage all units near where you land for @(3 + 65% ATK). Interrupts them if they were preparing a delayed ability.",
			value: (caster: EntityWithStats, atIndex: Int) -> 3 + int(0.65 * caster.stats.damage),
			manaCost: 5,
			cooldown: 5,
			range : 2,
			isFreeAction: true,
			effect : {
				type : "CHARGE",
				directions : {
					up	: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster, target) -> {
				caster.damageUnit(target, 3 + int(caster.getDamageFlat() * 0.65), PHYSICAL);
				target.interrupt();
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'ChargeAudio'
			}
		},
		{	name: 'Block',
			description: 'Block up to @(2 + 35% SP) damage until your next turn.',
			value: (caster: EntityWithStats, atIndex: Int) -> int(2 + 0.35 * caster.stats.spellPower),
			range: 0, 
			manaCost: 3,
			cooldown: 1,
			isInstant : true,
			isFreeAction: true,
			effect: {
				type: 'NO_EFFECT',
				hasNoCastDelay: true
			},
			missile: {},
			onTargetedEnemy: (caster: Unit, alsoCaster: Unit) -> {
				final blockAmount = 2 + int(caster.getSpellPowerWithVariation() * 0.35);
				caster.addBlock(blockAmount);
				caster.updateBars();
			},
			targetEffect: {
				animationName: 'Block',
				duration: 1.5
			},
			audio: {
				onCast: 'BlockAudio'
			}
		},
		{	name: 'Big Block',
			description: 'Block up to @(100% SP) damage until your next turn.',
			value: (caster: EntityWithStats, atIndex: Int) -> int(caster.stats.spellPower),
			range: 0, 
			manaCost: 4,
			cooldown: 1,
			isInstant : true,
			isFreeAction: true,
			effect: {
				type: 'NO_EFFECT',
				hasNoCastDelay: true
			},
			missile: {},
			onTargetedEnemy: (caster: Unit, alsoCaster: Unit) -> {
				final blockAmount = caster.getSpellPowerWithVariation();
				caster.addBlock(blockAmount);
				caster.updateBars();
			},
			targetEffect: {
				animationName: 'Big Block',
				duration: 1.5
			},
			audio: {
				onCast: 'BlockAudio'
			}
		},
		{	name: 'Smite',
			description: 'Your next attack or ability deals 15% extra damage and heals you for the damage dealt. 1 use per combat.',
			range: 0,
			manaCost: 6,
			isInstant: true,
			isFreeAction: true,
			cooldown: 99,
			effect: {
				type: 'NO_EFFECT',
				events: {
					combatStart: function(self: Unit) {
						self.customData.strings['hasSmite'] = 'no';
						Battlefield.addOnUnitCastSpellEvent(function(unit: Unit, spell: Spell, tile: TileSpace) {
							if (self != unit) return;
							if (self.customData.strings['hasSmite'] == 'no') return;
							if (spell.isOfAnyType([NORMAL_MOVE, END_TURN])) return;
							if (spell.getName() == 'Smite') return;
							self.customData.ints['totalUnitsHPBeforeCast'] = arraySumInt(Battlefield.getAllAliveUnits().map(u -> u.health));
						});
						Battlefield.addAfterUnitCastSpellEvent(function(unit: Unit, spell: Spell, tile: TileSpace) {
							if (self != unit) return;
							if (self.customData.strings['hasSmite'] == 'no') return;
							if (spell.isOfAnyType([NORMAL_MOVE, END_TURN])) return;
							if (spell.getName() == 'Smite') return;
							final totalUnitsHPBeforeCast = self.customData.ints['totalUnitsHPBeforeCast'];
							final totalUnitsHPAfterCast = arraySumInt(Battlefield.getAllAliveUnits().map(u -> u.health));
							final totalDamageDone = totalUnitsHPBeforeCast - totalUnitsHPAfterCast;
							if (totalDamageDone <= 0) {
								trace('0 damage done with smite. LOL!');
							} else {
								self.heal(totalDamageDone);
								self.playEffect('Healing Word', 1200);
								playAudio('HolyImpactAudio');
							}
							self.customData.strings['hasSmite'] = 'no';
						});
					}
				}
			},
			missile: {},
			targetEffect: {
				animationName: 'Smite',
				duration: 1.5
			},
			audio: {
				onCast: 'HolyConsecrationAudio'
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				caster.damageDoneMultiplier += 0.25;
				caster.customData.strings['hasSmite'] = 'yes';
			}
		},
		{	name: "Haymaker",
			description : "Deal @(75% ATK) FIRE damage and push the target away. \n If it collides with something, it takes the damage again! Allies don't take damage from this.",
			value: (caster: EntityWithStats, atIndex: Int) -> int(0.85 * caster.stats.damage),
			manaCost: 6,
			range : 1,
			isFreeAction: true,
			cooldown: 4,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				final pushDirection = target.getPushDirectionFromUnit(caster);
				if (target.owner != PLAYER) {
					caster.damageUnit(target, caster.getDamageFlat() * 0.75 * caster.amplifications.fire);
				}
				if (target.isDead) return;
				final pushDistance = 5;
				final tileLandedOn = caster.pushTargetAwayFromMe(target, pushDistance);
				if (tileLandedOn == null) return;
				final nextTile = tileLandedOn.getNextTileInDirection(pushDirection);
				final targetCollidedWithSomething = nextTile != null && nextTile.hasUnit();
				if (targetCollidedWithSomething) {
					if (target.owner != PLAYER) {
						final damageDone = caster.getDamageFlat() * 0.75 * caster.amplifications.fire;
						doAfter(250, () -> {
							target.tileOn.igniteIfHasOil();
							caster.damageUnit(target, damageDone, FIRE);
						});
					}
				}
			},
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: {
				onCast: 'HaymakerAudio'
			}
		},
		{	name: "Throw Rock",
			description: 'Throw a rock at any target within range! Deals @(33% SP) PURE damage.',
			value: (caster: EntityWithStats, atIndex: Int) -> int(0.33 * caster.stats.spellPower),
			manaCost: 2,
			range: 7,
			isFreeAction: true,
			effect: {
				type: 'TILE_IN_RANGE',
				tileInRange: {
					allowUnits: true
				}
			},
			missile: {
				animationName: 'Rock',
				isArced: true,
				speed: 'FAST'
			},
			targetEffect : {
				animationName: "Throw Rock",
				duration: 0.5
			},
			onTargetedTile: (caster: Unit, tile: TileSpace) -> {
				if (tile.hasUnit())
					caster.damageUnit(tile.unitOnIt, int(caster.getSpellPowerWithVariation() * 0.33), PURE);
			},
			audio: {
				onCast: 'WooshSimpleAudio',
				onHit: 'ThrowRockHitAudio'
			}
		},
		{	name: 'Intimidation',
			description: 'Reduces damage of enemies by 10% and deals @(50% SP) as COLD damage to them. Does not stack.',
			value: (caster: EntityWithStats, atIndex: Int) -> int(0.5 * caster.stats.spellPower),
			range: 0,
			manaCost: 6,
			cooldown: 4,
			isInstant : true,
			isFreeAction: true,
			effect: {
				type: 'NO_EFFECT',
				hasNoCastDelay: true
			},
			missile: {},
			onCastStart: function(caster: Unit) {
				final baseY = caster.getY();
				caster.actor.growTo(1.3, 1.2, 0.25, Easing.expoOut);
				caster.actor.moveBy(0, -caster.actor.getHeight() * 0.1, 0.25, Easing.expoOut);
				doAfter(250, () -> {
					caster.actor.growTo(1, 1, 0.25, Easing.expoOut);
					caster.actor.moveTo(caster.getX(), baseY, 0.25, Easing.expoOut);
				});
				shakeScreenShort();
			},
			onTargetedEnemy: (caster: Unit, alsoCaster: Unit) -> {
				for (target in Battlefield.getAllAliveEnemyUnits()) {
					caster.damageUnit(target, caster.getSpellPowerWithVariation(COLD) * 0.5, COLD);
					if (target.hasBuff('Intimidation')) continue;
					target.scrollRed('-10% DMG');
					target.addBuff(new Buff('Intimidation', 99, {}, {
						onAdd: (targetUnit: Unit) -> { targetUnit.damageDoneMultiplier -= 0.1; }
					}));
				}
			},

			audio: {
				onCast: 'IntimidationAudio'
			}
		},
		{	name: "Dark Lance",
			description : "Thrust your lance in a line. All units hit take @(70% ATK + 70% SP) DARK damage!",
			value: (caster: EntityWithStats, atIndex: Int) -> int(0.70 * caster.stats.damage) + int(0.70 * caster.stats.spellPower),
			range : 3,
			manaCost: 7,
			cooldown: 2,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT_PIERCING",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.amplifications.dark * (caster.getDamageWithVariation() * 0.75 + caster.getSpellPowerWithVariation() * 0.75), DARK),
			missile : {},
			audio: {
				onCast: 'MeleeAttackAudio',
				onHit: 'LanceThrustAudio'
			},
			slashEffect: {
				animationName: "Thrust",
				duration: 0.5
			},
			targetEffect: {
				animationName: "Crescent Darkness",
				duration: 0.5
			}
		},
		{	name: "Dig",
			description : "Dig in a nearby tile. Who knows what may happen!?",
			range : 2,
			manaCost: 2,
			cooldown: 3,
			isFreeAction: true,
			audio: {
				onCast: 'DigAudio'
			},
			effect : {
				type : "TILE_IN_RANGE",
			},
			onTargetedTile: function(caster: Unit, tile: TileSpace) {
				if (tile.hasTrap())
					tile.trapOnIt.kill();
				if (tile.hasUnit() == false) {
					if (percentChance(40) == false) {
						caster.say(cast randomOf([
							'No luck.',
							'Nothing here.',
							'Unlucky.',
							'Only dirt here.'
						]));
						return;
					}
					final foundItemName: String = cast randomOf(['Ham Sandwich', 'Heart', 'Scrap Metal', 'Bone', 'Just Some Dirt']);
					final foundItem: Item = ItemsDatabase.get(foundItemName);
					final itemPath = foundItem.imagePath; 
					Player.giveItem(foundItemName);
					SpecialEffectsFluff.doItemToInventoryAnimation(itemPath, tile.getXCenter(), tile.getYCenter());
					caster.say(cast randomOf([
						'Hah! Caught one!',
						'I found something!',
						'Look at this!',
						"I... I won't even ask...",
						"Finders keepers!"
					]));
				} else {
					final unitName = tile.unitOnIt.name;
					if (['Boulder', 'Rock Blockage', 'Log', 'Rock', 'Stones', 'Pumpkin', 'Bush'].indexOf(unitName) != -1) {
						caster.say('Obstacle cleared!');
						tile.unitOnIt.remove();
					} else if (unitName == 'Gravestone') {
						caster.say('Oh no...');
						tile.unitOnIt.remove();
						UnitsDatabase.spawnUnitNicely('Vampire Lord', tile);
					} else if (unitName == 'Pumpkin Tentacle') {
						caster.damageUnit(tile.unitOnIt, 20, PURE);
						caster.say('Take this, stupid tentacle!');
					} else {
						caster.damageUnit(tile.unitOnIt, 4, PURE);
						caster.say('Get away! I can\'t dig!');
					}
				}
			},
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			}
		},
		{	name: "Storm Spear",
			description : "Throw a spear diagonally that deals @(115% SP) SHOCK damage and 50% extra damage vs block! This chains to 2 adjacent units for half damage!",
			value: (caster: EntityWithStats, atIndex: Int) -> int(caster.stats.spellPower * 1.15),
			manaCost: 7,
			cooldown: 4,
			range : 4,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft		: true,
					upRight		: true,
					downLeft	: true,
					downRight	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				var damage: Int = int(
					(
						if (target.block > 0) 1.65
						else 1.15
					) * caster.stats.spellPower);

				final targetTle = target.tileOn;
				caster.damageUnit(target, damage, SHOCK);

				final unitsAffected: Array<Unit> = [caster, target];
				function chainLightning(fromUnit: Unit, toUnit: Unit) {
					final lightning = createActor('SpecialEffectActor', 'Particles');
					lightning.setAnimation('Chain Lightning');
					playAudio('ChainLightningAudio');
					stretchActorBetweenPoints(lightning, fromUnit.getXCenter(), fromUnit.getYCenter(), toUnit.getXCenter(), toUnit.getYCenter());
					doAfter(300, () -> {
						recycleActor(lightning);
					});

					final targetTile = toUnit.tileOn;
					var damage: Int = int(
						(
							if (toUnit.block > 0) 0.825
							else 0.575
						) * caster.stats.spellPower);
					caster.damageUnit(toUnit, damage, SHOCK);

					unitsAffected.push(toUnit);

					final extraTargets = targetTile.getNeighbors(true).filter(t -> t.hasUnit()).map(t -> t.unitOnIt).filter(u -> unitsAffected.indexOf(u) == -1);
					if (extraTargets.length == 0) return null;

					final randomTarget: Unit = randomOf(extraTargets);
					return randomTarget;
				}
				
				final tile = targetTle;
				final neighborTiles = tile.getNeighbors(true);
				final neighborsWithUnits = neighborTiles.filter(t -> t.hasUnit());
				final neighbors = neighborsWithUnits.map(t -> t.unitOnIt);
				final extraTargets = neighbors.filter(u -> unitsAffected.indexOf(u) == -1);
				if (extraTargets.length == 0) return;

				final target2: Unit = randomOf(extraTargets);
				if (target2 == null) return;
				final target3 = chainLightning(target, target2);
				if (target3 == null) return;
				chainLightning(target2, target3);
			},
			missile : {
				animationName : "Lightning Spear",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Lightning Blast",
				duration: 0.5
			},
			audio: {
				onCast: 'LightningThrowAudio',
			}
		},
		{	name: "Condemnation",
			description: 'Choose 3 tiles vertically (front or back). STUN all targets caught, and heal 3 + 15% SP for each target hit!',
			range: 1,
			manaCost: 8,
			cooldown: 8,
			isFreeAction: true,
			effect: {
				type: 'CUSTOM_EFFECT'
			},
			overrideGetTileHighlightMatrix: function(caster: Unit) {
				final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
				function tryMark(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					validityMatrix.set(i, j, Pathing.VALID);
				}
				final i = caster.getI();
				final j = caster.getJ();

				tryMark(i-1, j+1);
				tryMark(i, j+1);
				tryMark(i+1, j+1);

				tryMark(i-1, j-1);
				tryMark(i, j-1);
				tryMark(i+1, j-1);

				return validityMatrix;
			},
			onTargetedTile: function(self: Unit, tile: TileSpace) {
				function condemn(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					final tile = Battlefield.getTile(i, j);
					tile.playEffect('Condemnation', 1900);
					if (tile.hasUnit()) {
						self.heal(3 + int(0.15 * self.stats.spellPower));
						tile.unitOnIt.stun();
					}
				}
				final i = self.getI(), j = self.getJ();
				if (tile.getJ() > self.getJ()) {
					condemn(i-1, j+1);
					condemn(i, j+1);
					condemn(i+1, j+1);
				} else {
					condemn(i-1, j-1);
					condemn(i, j-1);
					condemn(i+1, j-1);
				}
				
			},
			audio: {
				onCast: 'CondemnationAudio'
			}

		},
		{	name: 'Blind Execution',
			description: 'Deal @(165% ATK) DARK damage. @(50% - your ARMOR) chance to hit another random unit nearby (if there is any). If you kill it, gain the mana back and reset your movement!',
			value: (caster: EntityWithStats, atIndex: Int) -> {
				if (atIndex == 0) return int(1.65 * caster.stats.damage);
				else return int(Math.max(0, 50 - caster.stats.armor));
			},
			range: 1, 
			manaCost: 6,
			cooldown: 7,
			isFreeAction: true,
			isInstant: false,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			overrideGetTileHighlightMatrix: function(caster: Unit) {
				final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
				function tryMark(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					if (Battlefield.getTile(i, j).hasUnit() == false) return;
					validityMatrix.set(i, j, Pathing.VALID);
				}
				final i = caster.getI();
				final j = caster.getJ();
				for (tile in caster.tileOn.getNeighbors(true)) {
					if (tile.hasUnit()) {
						validityMatrix.set(tile.getI(), tile.getJ(), Pathing.VALID);
					}
				}
				return validityMatrix;
			},
			onTargetedTile: function(caster: Unit, targetTile: TileSpace) {
				function slapTarget(target: Unit) {
					Spell.doGenericSlashEffect(caster.getCenterPoint(), target.getCenterPoint(), 'Slash Forward Big', 400);
					playAudio('BlindExecutionAudio');
					caster.damageUnit(target, int(1.65 * caster.getDamageWithVariation()), DARK);
					target.playEffect('Blind Execution', 650);
					if (target.isDead) {
						doAfter(500, function() {
							if (caster.isDead) return;
							caster.playEffect('Enrage', 1500);
							playAudio('ResetTurnAudio');
							caster.getMoveSpell().isWasted = false;
							caster.getMoveSpell().cooldownRemaining = 0;
							caster.replenish(6);
						});
					}
				}
				final possibleTargets = caster.getNeighborUnits(true).filter(u -> u.tileOn != targetTile);
				final hitChance = int(Math.max(0, 50 - caster.stats.armor));
				final willHitTargetUnit = percentChance(hitChance) && targetTile.hasUnit();
				final hasNoOtherTargets = possibleTargets.length == 0;
				if (willHitTargetUnit || hasNoOtherTargets) {
					slapTarget(targetTile.unitOnIt);
					return;
				}

				final target: Unit = randomOf(possibleTargets);
				slapTarget(target);
			},
			targetEffect: {},
			audio: {
				onCast: 'MeleeAttackAudio'
			}
		},
		{	name: "ANCHORRR",
			description : "Shoot a hook diagonally that deals @(100% ATK) damage and brings the target hit close to you!",
			cooldown: 4,
			manaCost: 5,
			range : 5,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft	  : true,
					upRight	  : true,
					downLeft  : true,
					downRight : true
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL);
				if (!target.isDead) {
					final direction = target.getDirectionTowardsUnit(caster);
					target.pushInDirection(direction, 5);
				}
			},
			missile : {
				animationName : "Anchor",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'ShootArrowCastAudio',
				onHit: 'AnchorAudio'
			}
		},
		{	name: 'Implosion',
			description: 'Deal @(20% Your Max Health) DARK damage to all units within 2 tiles of you (diagonally too).',
			value: (caster: EntityWithStats, atIndex: Int) -> int(0.2 * caster.stats.health),
			manaCost: 3,
			isInstant: true,
			isFreeAction: true,
			effect: {
				type: 'NO_EFFECT'
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				caster.playEffect('Implosion', 700);
				final damageDone = int(0.2 * caster.stats.health);
				function affectUnit(i, j) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					final tile = Battlefield.getTile(i, j);
					tile.playEffect('Implosion Reverse', 700);
					if (tile.hasUnit() == false) return;
					caster.damageUnit(tile.unitOnIt, damageDone, DARK);
				}

				final i = caster.getI(), j = caster.getJ();
				affectUnit(i-2, j-2); affectUnit(i-2, j-1); affectUnit(i-2, j); affectUnit(i-2, j+1); affectUnit(i-2, j+2);
				affectUnit(i-1, j-2); affectUnit(i-1, j-1); affectUnit(i-1, j); affectUnit(i-1, j+1); affectUnit(i-1, j+2);
				affectUnit(i, j-2); affectUnit(i, j-1); affectUnit(i, j+1); affectUnit(i, j+2);
				affectUnit(i+1, j-2); affectUnit(i+1, j-1); affectUnit(i+1, j); affectUnit(i+1, j+1); affectUnit(i+1, j+2);
				affectUnit(i+2, j-2); affectUnit(i+2, j-1); affectUnit(i+2, j); affectUnit(i+2, j+1); affectUnit(i+2, j+2);
			},
			audio: {
				onCast: 'ImplosionAudio'
			}
		},
		{	name: "Skull Break",
			description : "Throw your shield. Deals @(40% SP) + your current BLOCK FIRE damage. Does not remove your BLOCK.",
			value: (caster: EntityWithStats, atIndex: Int) -> int(caster.stats.spellPower * 0.4),
			manaCost: 5,
			range : 5,
			cooldown: 2,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft		: true,
					upRight		: true,
					downLeft	: true,
					downRight	: true,
					up			: true,
					left		: true,
					right		: true,
					down		: true
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				final damageDone = int(caster.stats.spellPower * 0.4 + caster.block);
				target.playEffect('Fire Ball');
				caster.damageUnit(target, damageDone, FIRE);
			},
			missile : {
				animationName : "Skull Break",
				speed : "FAST"
			},
			audio: {
				onCast: 'ThrowSpoonsAudio',
				onHit: 'HaymakerAudio'
			}
		},

		// Ranger Actives
		{	name: "Flare Shot",
			description : "Shoot an arrow that deals @(120% SP) FIRE damage, interrupts prepared abilities and reduces ARMOR and DODGE by 25%",
			value: (caster: EntityWithStats, atIndex: Int) -> int(1.2 * caster.stats.spellPower),
			manaCost: 3,
			isFreeAction: true,
			range : 4,
			cooldown: 3,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		  : true,
					left	  : true,
					down	  : true,
					right	  : true,
					upLeft	  : true,
					upRight	  : true,
					downLeft  : true,
					downRight : true
				}
			},
			onTargetedEnemy: (caster, target) -> {
				clearFog(target.tileOn);
				target.interrupt();
				if (!!!target.hasBuff('Flare Shot'))
					target.addBuff(new Buff('Flare Shot', 99, {
						armor: -25,
						dodge: -25
					}));
				target.tileOn.igniteIfHasOil();
				caster.damageUnit(target, caster.getSpellPowerWithVariation(FIRE) * 1.2, FIRE);
			},
			audio: {
				onCast: 'FlareMissileAudio',
				onHit: 'FlareCrackleAudio'
			},
			missile : {
				animationName : "Flare",
				isArced: true,
				speed : "SLOW"
			},
			targetEffect: {
				animationName: "Flare",
				duration: 0.5
			}
		},
		{	name: "Triple Arrow",
			description : "Shoot 3 arrows in front, up-front and down-front for @(105% ATK) PHYSICAL damage each!",
			value: (caster: EntityWithStats, atIndex: Int) -> int(1.05 * caster.stats.damage),
			manaCost: 7,
			range : 4,
			isFreeAction: true,
			effect : {
				type : "MULTI_SKILL_SHOT",
				directions : {
					upRight		: true,
					right		: true,
					downRight	: true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageFlat() * 1.05, PHYSICAL),
			audio: {
				onCast: 'ShootArrowCastAudio',
				onHit: 'ShootArrowHitAudio'
			},
			missile : {
				animationName : "Arrow",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			}
		},
		{	name: "Fox Attack",
			description: "Deals @(55% ATK) PHYSICAL damage to any target in 9 range. Applies a bleed for @(55% SP) DARK damage for 3 turns.",
			value: (caster: EntityWithStats, atIndex: Int) ->
				if (atIndex == 0) int(0.55 * caster.stats.damage)
				else int(0.55 * caster.stats.spellPower),
			range: 9,
			manaCost: 5,
			isFreeAction: true,
			effect: {
				type	: "TARGET_IN_RANGE",
				targetInRange : {
					allowSelf : false
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				caster.damageUnit(target, caster.getDamageWithVariation() * 0.55 * caster.amplifications.dark, DARK);
				final buffTickDamage = int(caster.getSpellPowerWithVariation(DARK) * 0.55);
				target.addBuff(new Buff('Fox Bleed', 3, {}, {
					onTick: (bleedingTarget: Unit) -> {
						caster.damageUnit(bleedingTarget, buffTickDamage, DARK);
					}
				}));
				var foxSpecialEffect = U.createActor('OtherParticles', 'Particles');
				foxSpecialEffect.setAnimation('Fox Attack');
				foxSpecialEffect.setX(getScreenXCenter());
				foxSpecialEffect.setY(getScreenHeight());
				final foxAngle = angleBetweenPoints(foxSpecialEffect.getXCenter(), foxSpecialEffect.getYCenter(), target.getX(), target.getY());
				foxSpecialEffect.setAngle(foxAngle * Utils.RAD);
				// y = mx + c; we need the 3rd point on the FoxStart-Unit-(FoxEnd) line
				// m  (y2 - y1) / (x2 - x1)
				var m = calculateSlope(foxSpecialEffect, target.actor);
				var c = calculateIntercept(foxSpecialEffect.getX(), foxSpecialEffect.getY(), m);
				var landingY: Float = getScreenY() - 35;
				var landingX: Float = (landingY - c) / m;
				foxSpecialEffect.moveTo(landingX, landingY, 0.5, Easing.linear);
				doAfter(500, () -> recycleActor(foxSpecialEffect));
			},
			targetEffect : {
				animationName : "Blood",
				duration	: 0.5
			},
			audio: {
				onCast: 'FoxAttackAudio'
			}
		},
		{	name: "Bear Trap",
			description: "Put a special Bear Trap on an empty tile. It deals @(150% SP) PHYSICAL damage when it triggers.",
			value: (caster: EntityWithStats, atIndex: Int) -> int(1.5 * caster.stats.spellPower),
			range: 6,
			manaCost: 4,
			cooldown: 4,
			isFreeAction: true,
			effect		: {
				type	: "TILE_IN_RANGE"
			},
			missile: {
				animationName: 'Bear Trap',
				isArced: true,
				speed: 'MEDIUM'
			},
			overrideGetTileHighlightMatrix: function(caster: Unit) {
				final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
				Pathing.crawlInRangeWithFunction(validityMatrix, caster.getI(), caster.getJ(), 4, function(data) {
					final i: Int = data.i;
					final j: Int = data.j;
					final tile = Battlefield.getTile(i, j);
					if (tile.hasUnit() == false && tile.hasTrap() == false) {
						data.mark(Pathing.VALID);
					}
					return true;
				});
				return validityMatrix;
			},
			onTargetedTile: function(caster, tile: TileSpace) {
				if (tile.hasTrap()) return;
				if (tile.hasUnit()) return;
				var bearTrap = Trap.createFromTemplateByName('Ranger Bear Trap', tile);
				bearTrap.customData = { damageDoneOnTrigger: int(caster.getSpellPowerWithVariation() * 1.5) };
				playAudio('BearTrapPlacementAudio');
			},
			targetEffect : {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'WooshSimpleAudio'
			}
		},
		{	name: "Disorient",
			description: "Deal SHOCK damage equal to 65% of your max MANA and push all units away from the impact. Allies don't take damage.",
			range: 3,
			manaCost: 5,
			isFreeAction: true,
			cooldown: 3,
			effect		: {
				type	: "TILE_IN_RANGE"
			},
			missile: {
				animationName: 'Disorient',
				speed: 'FAST'
			},
			onTargetedTile: (caster, tile: TileSpace) -> {
				if (tile == null) throwAndLogError('Null tile given.');
				if (tile.hasUnit()) {
					caster.damageUnit(tile.unitOnIt, caster.stats.mana * 0.65 * caster.amplifications.shock, SHOCK);
				}
				final tileInDirectionHasUnit = direction -> {
					final nextTile = tile.getNextTileInDirection(direction);
					if (nextTile == null) return false;
					return nextTile.hasUnit();
				};
				final directionsWithNeighborUnits = Constants.getDirections().filter(tileInDirectionHasUnit);
				for (direction in directionsWithNeighborUnits) {
					final unitToPush = tile.getNextTileInDirection(direction).unitOnIt;
					if (unitToPush.owner == ENEMY) {
						caster.damageUnit(unitToPush, caster.stats.mana * 0.65 * caster.amplifications.shock, SHOCK);
					}
					if (unitToPush.isDead == false) {
						unitToPush.pushInDirection(direction, 3);
					}
				}
			},
			targetEffect : {
				animationName: "Disorient",
				duration: 0.5
			},
			audio: {
				onCast: 'LightningThrowAudio',
				onHit: 'ZapHitAudio'
			}
		},
		{	name: 'Cobra Shot',
			description: 'Spawns 3 Acid Traps and summons a cute Cobra. Traps immediately shred all BLOCK on the targets hit. Cobra has @(50% DODGE) HP and BLEEDS enemies for @(25% SP) PURE damage.',
			value: (caster: EntityWithStats, atIndex: Int) -> if (atIndex == 0) int(0.5 * caster.stats.dodge) else int(0.25 * caster.stats.spellPower),
			range: 1,
			manaCost: 3,
			cooldown: 6,
			isFreeAction: true,
			effect: {
				type: 'CUSTOM_EFFECT',
			},
			missile: {
				animationName: 'Cobra Shot',
				speed: 'FAST'
			},
			audio: {
				onCast: 'CobraShotThrowAudio'
			},
			overrideGetTileHighlightMatrix: function(caster: Unit) {
				final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
				function tryMark(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					if (Battlefield.getTile(i, j).hasTrap()) return;
					validityMatrix.set(i, j, Pathing.VALID);
				}
				final i = caster.getI();
				final j = caster.getJ();
				if (i != 0) {	// For a bit of optimization
					tryMark(i-1, j-3); tryMark(i-1, j-2); tryMark(i-1, j-1); tryMark(i-1, j); tryMark(i-1, j+1); tryMark(i-1, j+2); tryMark(i-1, j+3);
				}
				tryMark(i, j-3); tryMark(i, j-2); tryMark(i, j-1); tryMark(i, j+1); tryMark(i, j+2); tryMark(i, j+3);
				if (i != 4) {	// For a bit of optimization
					tryMark(i+1, j-3); tryMark(i+1, j-2); tryMark(i+1, j-1); tryMark(i+1, j); tryMark(i+1, j+1); tryMark(i+1, j+2); tryMark(i+1, j+3);
				}
				return validityMatrix;
			},
			onTargetedTile: function(caster: Unit, targetTile: TileSpace) {
				final possibleTiles = [targetTile.getNextTileInDirection(LEFT), targetTile, targetTile.getNextTileInDirection(RIGHT)];
				final tiles = possibleTiles.filter(t -> t != null);
				for (i in 0...tiles.length) {
					final tile = tiles[i];
					doAfter(i * 300, () -> {
						Battlefield.spawnTrap('Acid Trap', tile);
						tile.playEffect('Toxic Smoke');
						playAudio('CobraShotAudio');
						if (tile.hasUnit()) {
							if (tile.unitOnIt.block > 0) {
								tile.unitOnIt.block = 0;
								tile.unitOnIt.updateBars();
							}
							if (tile.unitOnIt.stats.armor > 0) {
								tile.unitOnIt.stats.armor -= 25;
							}
						}
					});
				}
				// Spawn cobra
				var cobra: Unit = null;
				for (tile in tiles) {
					if (tile.hasUnit() == false) {
						cobra = Battlefield.spawnUnitOnTile('Cobra', tile, PLAYER);
						break;
					}
				}
				
				if (cobra == null) {
					caster.say('No space for my cute Cobra!!!', 3);
				}

			}

		},
		{	name: "Bola Shot",
			description : "Shoot a bola. STUN the first target hit, push it away 1 tile and deal @(80% SP) DARK damage.",
			value: (caster: EntityWithStats, atIndex: Int) -> int(0.5 * caster.stats.damage),
			range : 3,
			manaCost: 7,
			cooldown: 4,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				caster.damageUnit(target, int(0.8 * caster.getSpellPowerWithVariation(DARK)), DARK);
				if (target.isDead)
					return;
				if (target.wasLastDamageInstanceDodged)
					return;
				target.stun();
				caster.pushTargetAwayFromMe(target, 1);
			},
			missile : {
				animationName : "Bola",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Big Smash",
				duration: 0.5
			},
			audio: {
				onCast: 'BolaAudio'
			}
		},
		{	name: "Crystal Arrow",
			description : "Shoot diagonally and jump back if you hit. Deal @(30% ATK + 80% SP) COLD damage and gain Block equal to the damage dealt.",
			value: (caster: EntityWithStats, atIndex: Int) -> int(0.8 * caster.stats.spellPower),
			range : 3,
			manaCost: 4,
			cooldown: 3,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft		: true,
					upRight		: true,
					downLeft	: true,
					downRight	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				target.pushTargetAwayFromMe(caster, 2);
				final originalTargetBlock = target.block;
				var damageDone = caster.damageUnit(target, int(0.8 * caster.getSpellPowerWithVariation(COLD)), COLD);
				if (originalTargetBlock > 0) {
					damageDone += originalTargetBlock - target.block;
				}
				caster.addBlock(damageDone);
				caster.updateBars();
				caster.playEffect('Block', 1500);
			},
			missile : {
				animationName : "Crystal Arrow",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Crystal Shards",
				duration: 0.5
			},
			audio: {
				onHit: 'CrystalArrowAudio',
				onCast: 'CrystalShotCastAudio'
			}
		},
		{	name: "Firrow",
			description : "Shoot a flaming arrow that deals @(55% ATK + 90% SP) FIRE damage. The arrow splits into 2 more FIRE arrows!",
			value: (caster: EntityWithStats, atIndex: Int) -> int(caster.stats.spellPower * 0.9 + caster.stats.damage * 0.55),
			range : 5,
			manaCost: 7,
			cooldown: 6,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT_SPLIT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				caster.damageUnit(target, int((caster.stats.spellPower * 0.9 + caster.stats.damage * 0.55) * caster.amplifications.fire), FIRE);
			},
			missile : {
				animationName : "Firrow",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Hit",
				duration: 0.5
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'FoomAudio'
			}
		},

		{	name: "Poison Attack",
			description : "Damage a unit for 1. Poisons them for @(25% SP) PURE damage per turn for 3 turns. Damage does not stack.",
			value: (caster: EntityWithStats, atIndex: Int) -> int(caster.stats.spellPower * 0.25),
			isDefault: true,
			manaCost: 5,
			range : 1,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft		: true,
					upRight		: true,
					downLeft	: true,
					downRight	: true,
					up			: true,
					left		: true,
					right		: true,
					down		: true
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				if (target.hasBuff('Snake Bleed') == false) {
					final buffTickDamage = int(caster.stats.spellPower * 0.25);
					target.addBuff(new Buff('Snake Bleed', 3, {}, {
						onTick: (bleedingTarget: Unit) -> {
							caster.damageUnit(bleedingTarget, buffTickDamage, PURE);
						}
					}));
				} else {
					target.getBuff('Snake Bleed').remainingDuration = 3;
				}

				caster.damageUnit(target, 1, PURE);
			},
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Spores",
				duration: 0.5
			},
			audio: {
				onCast: 'MeleeAttackAudio',
				onHit: 'SlimeDeathAudio'
			}
		},

		// Mage Actives
		{	name: "Magic Arrow",
			description : "Hurl a magical arrow diagonally for @(3 + 85% SP) COLD damage. Deals 50% extra damage to Silenced or Rooted units.",
			isDefault: true,
			value: (caster: EntityWithStats, atIndex: Int) -> 2 + int(caster.stats.spellPower * 0.85),
			manaCost: 5,
			range : 4,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft		: true,
					upRight		: true,
					downLeft	: true,
					downRight	: true
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				final damageDone =
					if (target.isRooted || target.isSilenced()) 5 + int(caster.getSpellPowerWithVariation(COLD) * 1.275)
					else 3 + int(caster.getSpellPowerWithVariation(COLD) * 0.85);
				caster.damageUnit(target, damageDone, COLD);
			},
			missile : {
				animationName : "Magic Arrow",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'MagicArrowAudio',
				onHit: 'ZapHitAudio'
			}
		},
		{	name: "Magic Arrow (Any)",
			description : "Hurl a magical arrow diagonally for @(3 + 85% SP) COLD damage. Deals 50% extra damage to Silenced or Rooted units.",
			isDefault: true,
			value: (caster: EntityWithStats, atIndex: Int) -> 2 + int(caster.stats.spellPower * 0.85),
			manaCost: 5,
			range : 4,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft		: true,
					upRight		: true,
					downLeft	: true,
					downRight	: true,
					up			: true,
					left		: true,
					right		: true,
					down		: true
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				final damageDone =
					if (target.isRooted || target.isSilenced()) 5 + int(caster.getSpellPowerWithVariation(COLD) * 1.275)
					else 3 + int(caster.getSpellPowerWithVariation(COLD) * 0.85);
				caster.damageUnit(target, damageDone, COLD);
			},
			missile : {
				animationName : "Magic Arrow",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'MagicArrowAudio',
				onHit: 'ZapHitAudio'
			}
		},
		{	name: 'Siphon Mana',
			description: 'Drain up to 4 mana from a unit within 4 tiles.',
			isFreeAction: true,
			manaCost: 2,
			cooldown: 4,
			range: 4,
			effect: {
				type: 'TARGET_IN_RANGE',
				allowSelf: false,
			},
			onTargetedEnemy: function(caster, target) {
				var manaDrained: Int = 0;
				if (target.stats.mana > 0) {
					if (target.mana > 0) {
						if (target.mana < manaDrained) {
							manaDrained = target.mana;
						} else {
							manaDrained = 4;
						}
					}
				}
				if (manaDrained == 0) return;
				caster.replenish(manaDrained);
				caster.playEffect('Siphon Mana', 500);
				target.deplete(manaDrained);
				target.playEffect('Siphon Mana Reversed', 500);
			},
			audio: {
				onCast: 'SiphonManaAudio'
			}
		},
		{	name: 'Mana Ward',
			description: 'Shield a target for @(40% max MANA).',
			value: (caster: EntityWithStats, atIndex: Int) -> int(caster.stats.mana * 0.4),
			isFreeAction: true,
			cooldown: 5,
			range: 9,
			manaCost: 5,
			isFriendly: true,
			effect: {
				type: 'TARGET_IN_RANGE',
				allowSelf: true,
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				target.addBlock(int(caster.stats.mana * 0.4));
				target.updateBars();
				target.playEffect('Block', 1500);
			},
			audio: {
				onCast: 'BlockAudio'
			}
		},
		{	name: 'Blink',
			description: 'Teleport to a tile within 4 tiles.',
			range: 1,
			manaCost: 3,
			cooldown: 6,
			isFreeAction: true,
			effect: {
				type: 'CUSTOM_EFFECT',
			},
			audio: {
				onCast: 'TeleportAudio'
			},
			overrideGetTileHighlightMatrix: function(caster: Unit) {
				final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
				Pathing.crawlInRangeWithFunction(validityMatrix, caster.getI(), caster.getJ(), 4, function(data) {
					final i: Int = data.i;
					final j: Int = data.j;
					if (Battlefield.getTile(i, j).hasUnit() == false) {
						data.mark(Pathing.VALID);
					}
					return true;
				});
				return validityMatrix;
			},
			onTargetedTile: function(caster: Unit, targetTile: TileSpace) {
				final originTile = caster.tileOn;
				caster.playEffect('Mage Teleport', 1450);
				caster.putOnTile(targetTile);
				caster.playEffect('Mage Teleport', 1450);
				caster.slideToTileVisualOnly(originTile, 0);
				doAfter(950, () -> {
					caster.putOnTile(targetTile);
				});
			}
		},
		{	name: 'Iceberg Drop',
			description: 'Drops an iceberg at the start of the next turn, dealing @(165% SP) COLD damage.',
			value: (caster: EntityWithStats, atIndex: Int) -> int(caster.stats.spellPower * 1.65),
			manaCost: 9,
			cooldown: 9,
			range: 5,
			isFreeAction: true,
			effect: { type: 'TILE_IN_RANGE', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				for (t in tile.getNeighbors(true)) {
					caster.markTileRed(t);
				}
			},
			onTargetedTile: function(caster: Unit, tile: TileSpace) {
				final iceberg = createActor('SpecialEffectActor', 'Units${tile.getI()}');
				iceberg.setAnimation('Iceberg');
				final icebergY = tile.getHypotheticCoordinatesForActor(iceberg).y;
				final icebergX = tile.getHypotheticCoordinatesForActor(iceberg).x;
				iceberg.setY(getScreenY() - iceberg.getHeight());
				iceberg.setX(iceberg.getX());
				iceberg.moveTo(icebergX, icebergY, 0.5, Easing.expoIn);
				playAudio('CrystalShotAudio');
				doAfter(500, () -> {
					playAudio('IcebergDropAudio');
					startShakingScreen(0.01, 0.25);
					final affectedTiles = [tile].concat(tile.getNeighbors(true));
					for (tile in affectedTiles) {
						if (tile.hasUnit()) {
							caster.damageUnit(tile.unitOnIt, int(caster.getSpellPowerWithVariation(COLD) * 1.65), COLD);
						}
					}
					doAfter(1000, () -> {
						iceberg.fadeTo(0, 1, Easing.linear);
						doAfter(1000, () -> {
							recycleActor(iceberg);
						});
					});
				});
			}
		},
		{	name: 'Ice Cube',
			description: 'Conjure an ice cube on a given tile. That\'s all. It, like, blocks the way... and stuff. Has @(100% SP) health.',
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.spellPower,
			manaCost: 4,
			cooldown: 4,
			range: 9,
			isFreeAction: true,
			effect: { type: 'TILE_IN_RANGE' },
			missile: {},
			overrideGetTileHighlightMatrix: function(caster: Unit) {
				final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
				Pathing.crawlInRangeWithFunction(validityMatrix, caster.getI(), caster.getJ(), 9, function(data) {
					final i: Int = data.i;
					final j: Int = data.j;
					final tile = Battlefield.getTile(i, j);
					if (tile.hasUnit() == false && tile.hasTrap() == false) {
						data.mark(Pathing.VALID);
					}
					return true;
				});
				return validityMatrix;
			},
			onTargetedTile: function(caster: Unit, tile: TileSpace) {
				final iceCube = Battlefield.spawnUnitOnTile('Ice Cube', tile, NEUTRAL);
				iceCube.setMaxHealth(caster.stats.spellPower);
				iceCube.playEffect('Snowflakes');
				SpecialEffectsFluff.doActorDropInAnimation(iceCube.actor, () -> {
					SpecialEffectsFluff.sheenActor(iceCube.actor);
				});
			}
		},
		{	name: 'Boom Barrel',
			description: 'Summon an explosive barrel!!!',
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.spellPower,
			manaCost: 3,
			cooldown: 4,
			range: 9,
			isFreeAction: true,
			effect: { type: 'TILE_IN_RANGE' },
			missile: {},
			overrideGetTileHighlightMatrix: function(caster: Unit) {
				final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
				Pathing.crawlInRangeWithFunction(validityMatrix, caster.getI(), caster.getJ(), 9, function(data) {
					final i: Int = data.i;
					final j: Int = data.j;
					final tile = Battlefield.getTile(i, j);
					if (tile.hasUnit() == false && tile.hasTrap() == false) {
						data.mark(Pathing.VALID);
					}
					return true;
				});
				return validityMatrix;
			},
			onTargetedTile: function(caster: Unit, tile: TileSpace) {
				final iceCube = Battlefield.spawnUnitOnTile('Explosive Barrel', tile, NEUTRAL);
				iceCube.setMaxHealth(caster.stats.spellPower);
				iceCube.playEffect('Smoke');
				playAudio('BoomBarrelAudio');
				SpecialEffectsFluff.doActorDropInAnimation(iceCube.actor, () -> {});
			}
		},
		{	name: 'Poswap',
			description: 'Swap position with a non-large unit. Gain @(100% SP) BLOCK.',
			isFreeAction: true,
			manaCost: 4,
			cooldown: 7,
			range: 6,
			effect: { type: 'TILE_IN_RANGE' },
			audio: { onCast: 'TeleportAudio' },
			overrideGetTileHighlightMatrix: function(caster: Unit) {
				final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
				Pathing.crawlInRangeWithFunction(validityMatrix, caster.getI(), caster.getJ(), 6, function(data: Dynamic) {
					if (data.value == Pathing.UNIT) {
						final tile = Battlefield.getTile(data.i, data.j);
						if (tile.hasUnit() && tile.unitOnIt.isLarge == false && tile.unitOnIt != caster) {
							data.mark(Pathing.VALID);
						}
					}
					return true;
				});
				return validityMatrix;
			},
			onTargetedTile: function(caster: Unit, targetTile: TileSpace) {
				final casterTile = caster.tileOn;
				if (targetTile.hasUnit() == false || targetTile.unitOnIt.isDead)
					return;
				final target = targetTile.unitOnIt;
				caster.playEffect('Marceline Teleport', 1450);
				target.playEffect('Marceline Teleport', 1450);
				doAfter(950, () -> {
					caster.detachFromBoard();
					target.detachFromBoard();
					caster.putOnTile(targetTile);
					target.putOnTile(casterTile);
				});
			}

		},
		{	name: 'Ignite',
			description: 'Ignite all enemies for @(30% SP) FIRE damage per turn, for 3 turns.',
			value: (caster: EntityWithStats, atIndex: Int) -> int(0.35 * caster.stats.spellPower),
			range: 0, 
			manaCost: 6,
			cooldown: 3,
			isInstant : true,
			isFreeAction: true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			onTargetedEnemy: (caster: Unit, alsoCaster: Unit) -> {
				final enemies = Battlefield.getAllAliveEnemyUnits();
				for (i in 0...enemies.length) {
					final unit = enemies[i];
					if (unit.tileOn.hasTrap('Oil')) {
						unit.tileOn.trapOnIt.kill();
						Battlefield.spawnTrap('Fire', unit.tileOn);
					}
					unit.addBuff(new Buff('Ignite', 3, {}, {
						onTick: function(enemy: Unit) {
							caster.damageUnit(enemy, int(caster.getSpellPowerWithVariation(FIRE) * 0.30), FIRE);
						}						
					}));
					doAfter(i * 100, () -> {
						unit.playEffect('Fire Ball');
						playAudio('IgniteAudio');
					});
				}
			}
		},
		{	name: 'Frost Nova',
			description: 'Damage all nearby units for @(50% SP) FROST damage and ROOTS them. If they are already rooted, deals double damage and STUNS them.',
			value: (caster: EntityWithStats, atIndex: Int) -> 2 + int(0.5 * caster.stats.spellPower),
			range: 0, 
			manaCost: 6,
			cooldown: 6,
			isInstant : true,
			isFreeAction: true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			onTargetedEnemy: (caster: Unit, alsoCaster: Unit) -> {
				final tiles = caster.tileOn.getNeighbors(true);
				for (tile in tiles) {
					tile.playEffect('Freeze', 1375);
					tile.playEffect('Snowflakes');
					if (tile.hasUnit()) {
						final unit = tile.unitOnIt;
						if (unit.isRooted) {
							caster.damageUnit(unit, caster.getSpellPowerWithVariation(COLD), COLD);
							unit.unroot();
							unit.stun();
						} else {
							caster.damageUnit(unit, int(caster.getSpellPowerWithVariation(COLD) / 2), COLD);
							unit.root();
						}
					}
				}
			},
			audio: {
				onCast: 'FrostNovaAudio'
			}
		},
		{	name: "Obstacle Focus",
			description: 'Choose an obstacle. It bursts with a different effect based on its material.',
			range: 1,
			manaCost: 6,
			cooldown: 5,
			isFreeAction: true,
			effect: {
				type: 'CUSTOM_EFFECT'
			},
			overrideGetTileHighlightMatrix: function(caster: Unit) {
				final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
				final neutrals = Battlefield.getAllAliveNeutralUnits();
				for (unit in neutrals) {
					validityMatrix.set(unit.getI(), unit.getJ(), Pathing.VALID);
				}
				return validityMatrix;
			},
			onTargetedTile: function(self: Unit, tile: TileSpace) {
				if (tile == null) {
					warnLog('Tile is null.');
					return;
				}
				if (tile.hasUnit() == false) {
					warnLog('Tile ${tile.toString()} should have a unit.');
					return;
				}
				final unit = tile.unitOnIt;
				final targets = unit.getNeighborUnits(true);
				final tag: Int = unit.getRandomTag();
				if (tag == UnitTemplate.UNIT_WOOD) {
					for (target in targets) {
						target.playEffect('Spike Rush', 200);
						self.damageUnit(target, int(unit.getSpellPowerWithVariation() * 0.85), PURE);
						if (target.isDead == false) {
							target.root();
						}
						playAudio('SpikeRushAudio');
					}
				} else if (tag == UnitTemplate.UNIT_STONE) {
					for (target in targets) {
						target.playEffect('Sumo Wave', 700);
						self.damageUnit(target, int(unit.getSpellPowerWithVariation() * 0.25), PURE);
						if (target.isDead == false && target.wasLastDamageInstanceDodged == false) {
							target.stun();
						}
					}
					playAudio('SumoWaveAudio');
				} else if (tag == UnitTemplate.UNIT_FLAMABLE) {
					for (i in 0...targets.length) {
						final target = targets[i];
						self.damageUnit(target, int(unit.getSpellPowerWithVariation() * 0.75), PURE);
						if (target.isDead) continue;
						target.addBuff(new Buff('Ignite', 3, {}, {
							onTick: function(enemy: Unit) {
								enemy.tileOn.igniteIfHasOil();
								self.damageUnit(enemy, int(self.getSpellPowerWithVariation(FIRE) * 0.35), FIRE);
							}						
						}));
						doAfter(i * 100, () -> {
							unit.playEffect('Fire Ball');
							playAudio('IgniteAudio');
						});
					}
				} else if (tag == UnitTemplate.UNIT_ICE) {
					final tiles = unit.tileOn.getNeighbors(true);
					for (tile in tiles) {
						tile.playEffect('Freeze', 1375);
						tile.playEffect('Snowflakes');
						if (tile.hasUnit()) {
							if (tile.unitOnIt.isRooted) {
								self.damageUnit(tile.unitOnIt, self.getSpellPowerWithVariation(COLD), COLD);
								tile.unitOnIt.unroot();
								tile.unitOnIt.stun();
							} else {
								self.damageUnit(tile.unitOnIt, int(self.getSpellPowerWithVariation(COLD) / 2), COLD);
								tile.unitOnIt.root();
							}
						}
					}
				} else if (tag == -1) {
					warnLog('Unit has no tags.');
				} else {
					warnLog('Unknown unit tag ${tag}.');
				}
			}
		},
		{	name: 'Summon Candle',
			description: 'Conjure a candle which provides enough light to survive the Somnium.',
			manaCost: 4,
			cooldown: 12,
			range: 3,
			isFreeAction: true,
			effect: { type: 'TILE_IN_RANGE' },
			missile: {},
			onTargetedTile: function(caster: Unit, tile: TileSpace) {
				final iceCube = Battlefield.spawnUnitOnTile('Magic Candles', tile, NEUTRAL);
				iceCube.playEffect('Smoke');
				SpecialEffectsFluff.doActorDropInAnimation(iceCube.actor, () -> {
					SpecialEffectsFluff.sheenActor(iceCube.actor);
				});
			}
		},
		{	name: 'Tsunami',
			description: 'After 1 turn, sends 3 waves on the middle rows of the battlefield, left to right. They deal 105% SP COLD damage each!',
			range: 7,
			manaCost: 6,
			cooldown: 5,
			isFreeAction: true,
			effect: {
				isDelayed: true,
				type: 'TIDAL_WAVE',
				tidalWaveRows: [1, 2, 3],
				isTidalWaveReversed: true
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				caster.damageUnit(target, caster.getSpellPowerWithVariation(COLD), COLD);
			},
			missile: {
				animationName: 'Tidal Wave',
				speed: 'MEDIUM'
			},
			targetEffect: {
				animationName: 'Splash',
				duration: 0.5
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'WaterExplosionAudio'
			}
		},
		{	name: "Flame Dagger",
			description : "Make an attack on a target in 2 range for @(150% ATK) FIRE damage!",
			value: (caster: EntityWithStats, atIndex: Int) -> int(caster.stats.damage * 1.65),
			range : 2,
			cooldown: 2,
			manaCost: 4,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster, target) -> {
				playAudio('FoomAudio');
				caster.damageUnit(target, int(caster.getDamageWithVariation() * 1.5 * caster.amplifications.fire), FIRE);
			},
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Fire Ball",
				duration: 0.5
			},
			audio: { onCast: 'MeleeAttackAudio' }
		},
		{	name: "Fire Ball",
			description : "Throw a big fire ball that heavily damages a unit for @(250% SP) FIRE damage.",
			value: (caster: EntityWithStats, atIndex: Int) -> int(caster.stats.spellPower * 2.5),
			manaCost: 11,
			range : 4,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up: true,
					right: true,
					down: true,
					left: true
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				SpecialEffectsFluff.doExplosionEffect(target.getXCenter(), target.getYCenter());
				SpecialEffectsFluff.shakeScreenShort();
				caster.damageUnit(target, caster.getSpellPowerWithVariation(FIRE) * 2.5, FIRE);
			},
			missile : {
				animationName : "Fire Ball",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Fire Ball",
				duration: 0.5
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'FireArenaAudio'
			}
		},

		// Monster Actives
		{	name: 'Block (Monster)',
			description: 'Block up to @(3 + 50% SP) damage until your next turn.',
			range: 0, 
			manaCost: 0,
			cooldown: 1,
			isInstant : true,
			effect: {
				type: 'NO_EFFECT',
				hasNoCastDelay: true
			},
			missile: {},
			onTargetedEnemy: (caster: Unit, alsoCaster: Unit) -> {
				final blockAmount = int(caster.getSpellPowerWithVariation() * 0.5) + 3;
				caster.addBlock(blockAmount);
				caster.updateBars();
			},
			targetEffect: {
				animationName: 'Block',
				duration: 1.5
			},
			audio: {
				onCast: 'BlockAudio'
			},
			aiFlags: { isUsableWhileSilenced: false }
		},
		{	name: "Healing Word",
			description	: "Heal an ally for 7.",
			manaCost: 1,
			range			: 3,
			effect		: {
				type	: "ANY_ALLY",
				directions : {
					up		: false,
					left	: false,
					down	: false,
					right	: false
				},
				anyAlly : {
					allowSelf : false
				}
			},
			aiFlags: {
				doesHeal: true,
				doesDamage: false,
				isUsableWhileSilenced: false
			},
			onTargetedEnemy: (caster, target) -> {
				caster.doDownUpAnimation();
				target.heal(7);
			},
			missile	: {
				animationName	: "",
				speed			: "MEDIUM"
			},
			targetEffect : {
				animationName : "Healing Word",
				duration		: 1.1
			},
			audio: {
				onCast: 'HealingWordAudio'
			}
		},
		{	name: "Healing Word 2",
			description	: "Heal an ally for 13.",
			range		: 3,
			manaCost	: 1,
			effect		: {
				type	: "ANY_ALLY",
				directions : {
					up		: false,
					left	: false,
					down	: false,
					right	: false
				},
				anyAlly : {
					allowSelf : false
				}
			},
			aiFlags: {
				doesHeal: true,
				doesDamage: false,
				isUsableWhileSilenced: false
			},
			onTargetedEnemy: (caster, target) -> {
				caster.doDownUpAnimation();
				target.heal(13);
			},
			missile	: {
				animationName	: "",
				speed			: "MEDIUM"
			},
			targetEffect : {
				animationName : "Healing Word",
				duration		: 1.1
			},
			audio: {
				onCast: 'HealingWordAudio'
			}
		},	
		{	name: "Magic Arrow Any Direction",
			description : "Hurl a magical arrow (NPC only spell).",
			manaCost: 0,
			range : 4,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up			: true,
					down		: true,
					left		: true,
					right		: true,
					upLeft		: true,
					upRight		: true,
					downLeft	: true,
					downRight	: true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageWithVariation()),
			missile : {
				animationName : "Magic Arrow",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			aiFlags: { isUsableWhileSilenced: false }
		},	
		{	name: "Slingshot",
			description : "Shoot a pebble!",
			range : 5,
			effect : {
				type : "SKILL_SHOT",
				isDelayed: true,
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true,
					upLeft	  : true,
					upRight	  : true,
					downLeft  : true,
					downRight : true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL),
			missile : {
				animationName : "Slingshot",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'WooshSimpleAudio',
				onHit: 'ThrowRockHitAudio'
			}
		},
		{	name: "Shoot Location",
			range: 10,
			doJotAnimation: false,
			effect: {
				type: 'TILE_IN_RANGE',
				isDelayed: true,
				tileInRange: {
					allowUnits: true
				}
			},
			missile: {},
			audio: {
				onPrepare: 'GunCockAudio',
				onCast: 'GunShootAudio'
			},
			onDelayedSetup: (caster: Unit, tile: TileSpace) -> {
				final additionalMarkedTiles: Array<TileSpace> = [];
				final tile1 = tile.getRandomShootLocationNeighbor();
				if (tile1 != null) {
					additionalMarkedTiles.push(tile1);
				}
				final tile2 = tile.getRandomShootLocationNeighbor();
				if (tile2 != null && tile2 != tile1) {
					additionalMarkedTiles.push(tile2);
				}
				for (tile in additionalMarkedTiles) {
					tile.addDangerMarker();
					caster.tilesMarkedRed.push(tile);
				}
				caster.aiData = { additionalMarkedTiles: additionalMarkedTiles };
			},
			onTargetedTile: (caster: Unit, tile: TileSpace) -> {
				doHighwaymanGunshotEffectForUnit(caster);
				final additionalMarkedTiles: Array<TileSpace> = cast caster.aiData.additionalMarkedTiles;
				final affectedTiles = [tile].concat(additionalMarkedTiles);
				for (tile in affectedTiles) {
					trace('Playing effect:');
					tile.playEffect('Throw Rock Small');
					if (tile.hasUnit())
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PHYSICAL);
				}
			}
		},
		{	name: "Shoot Location 2",
			range: 10,
			effect: {
				type: 'TILE_IN_RANGE',
				isDelayed: true,
				tileInRange: {
					allowUnits: true
				}
			},
			missile: {},
			audio: {
				onPrepare: 'GunCockAudio',
				onCast: 'GunShootAudio'
			},
			onDelayedSetup: (caster: Unit, tile: TileSpace) -> {
				final additionalMarkedTiles: Array<TileSpace> = [];
				final tile1 = tile.getRandomShootLocationNeighbor();
				if (tile1 != null) {
					additionalMarkedTiles.push(tile1);
				}
				final tile2 = tile.getRandomShootLocationNeighbor();
				if (tile2 != null && tile2 != tile1) {
					additionalMarkedTiles.push(tile2);
				}
				final tile3 = tile1.getRandomShootLocationNeighbor();
				if (tile3 != null && tile3 != tile2 && tile3 != tile) {
					additionalMarkedTiles.push(tile2);
				}
				for (tile in additionalMarkedTiles) {
					tile.addDangerMarker();
					caster.tilesMarkedRed.push(tile);
				}
				caster.aiData = { additionalMarkedTiles: additionalMarkedTiles };
			},
			onTargetedTile: (caster: Unit, tile: TileSpace) -> {
				doHighwaymanGunshotEffectForUnit(caster);
				final additionalMarkedTiles: Array<TileSpace> = cast caster.aiData.additionalMarkedTiles;
				final affectedTiles = [tile].concat(additionalMarkedTiles);
				for (tile in affectedTiles) {
					trace('Playing effect:');
					tile.playEffect('Throw Rock Small');
					if (tile.hasUnit())
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PHYSICAL);
				}
			}
		},
		{	name: "Shotgun Blast",
			range: 10,
			effect: {
				type: 'TILE_IN_RANGE',
				isDelayed: true,
				tileInRange: {
					allowUnits: true
				}
			},
			missile: {},
			audio: {
				onPrepare: 'ShotgunLoad',
				onCast: 'ShotgunFire'
			},
			targetEffect: {
				animationName: "Fire Ball",
				duration: 0.5
			},
			onDelayedSetup: (caster: Unit, tile: TileSpace) -> {
				final additionalMarkedTiles: Array<TileSpace> = [
					tile.getNextTileInDirection(UP_LEFT),
					tile.getNextTileInDirection(UP_RIGHT),
					tile.getNextTileInDirection(DOWN_LEFT),
					tile.getNextTileInDirection(DOWN_RIGHT)
				].filter(tile -> tile != null);
				for (tile in additionalMarkedTiles) {
					tile.addDangerMarker();
					caster.tilesMarkedRed.push(tile);
				}
				caster.aiData = { additionalMarkedTiles: additionalMarkedTiles };
			},
			onTargetedTile: (caster: Unit, tile: TileSpace) -> {
				final additionalMarkedTiles: Array<TileSpace> = cast caster.aiData.additionalMarkedTiles;
				final affectedTiles = [tile].concat(additionalMarkedTiles);
				doNatasGunshotEffectForUnit(caster);
				for (tile in affectedTiles) {
					if (tile.hasUnit())
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PHYSICAL);
					if (percentChance(50)) {
						if (tile.hasTrap()) continue;
					Trap.createFromTemplateByName('Fire', tile);
					}
				}
			}
		},
		{	name: 'Throw Meat',
			description: 'Throws meat hunk that summons a hell hound when hit by a Canon Blast.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT',
				isDelayed: true
			},
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final targetTile =
					if (percentChance(50)) Battlefield.getRandomAlivePlayerUnit().tileOn
					else Battlefield.getRandomAlivePlayerUnit().tileOn.getRandomEmptyNeighbor();
				if (targetTile == null) return;
				caster.markTileRed(targetTile);
				caster.aiData = { targetTile: targetTile };
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final targetTile: TileSpace = caster.aiData.targetTile;
				Battlefield.pauseNextTurn();
				playAudio('WooshSimpleAudio');
				caster.doDownUpAnimation();
				Effects.sendArcMissileAndThen(
					caster.getCenterPointForMissile(),
					targetTile.getCenterPointForMissile(),
					'Meat',
					Effects.MEDIUM,
					() -> {
						playAudio('SlimeHitAudio');
						targetTile.playEffect('Smoke');
						if (targetTile.hasUnit() == false && targetTile.hasTrap() == false) {
							Battlefield.spawnTrap('Meat', targetTile);
						}
						if (targetTile.hasUnit()) {
							if (targetTile.unitOnIt.name == 'Hell Hound') {
								growWaterElemental(targetTile.unitOnIt);
								caster.say('Eat and grow!!');
							} else {
								caster.damageUnit(targetTile.unitOnIt, caster.getDamageWithVariation(), FIRE);
							}
						}
						final playerTilesAround = targetTile.getNeighbors().filter(t -> t.hasUnit() && t.unitOnIt.owner == PLAYER);
						if (playerTilesAround.length != 0 && percentChance(50)) {
							final playerTile: TileSpace = randomOf(playerTilesAround);
							caster.damageUnit(playerTile.unitOnIt, caster.getDamageWithVariation(), FIRE);
							Battlefield.spawnTrap('Fire', playerTile);
						} else {
							final randomTile = targetTile.getRandomEmptyNeighbor();
							if (randomTile == null) return;
							Battlefield.spawnTrap('Fire', randomTile);
						}
						Battlefield.resumeNextTurn();
					}
				);
			}
		},
		{	name: "Canon Blast",
			description : "BIG BAD BOOM!",
			range : 5,
			effect : {
				type : "SKILL_SHOT_PIERCING",
				isDelayed: true,
				directions : {
					left	: true,
					right	: true
				}
			},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final direction = caster.tileOn.getDirectionToTile(tile);
				final firstTile = caster.getNextTileInDirection(direction);
				final affectedTiles = firstTile.getAllTilesInDirectionIncluding(direction, 5);
				caster.aiData = { affectedTiles: affectedTiles };
				for (t in affectedTiles) {
					final tileUp = t.getNextTileInDirection(UP);
					final tileDown = t.getNextTileInDirection(DOWN);
					if (tileUp != null) {
						caster.markTileRed(tileUp);
					}
					if (tileDown != null) {
						caster.markTileRed(tileDown);
					}
				}
			},
			onCastStart: function(caster: Unit) {
				final affectedTiles: Array<TileSpace>  = caster.aiData.affectedTiles;
				for (i in 0...affectedTiles.length) {
					final tile = affectedTiles[i];
					function damageTileOrSummonHound(t: TileSpace) {
						if (t.hasUnit()) {
							caster.damageUnit(t.unitOnIt, caster.getDamageWithVariation());
						}
						if (t.hasTrap() && t.trapOnIt.name == 'Meat') {
							t.trapOnIt.kill();
							if (t.hasUnit()) return;
							Battlefield.spawnEnemyOnTile('Hell Hound', t);
							t.playEffect('Smoke');
							caster.say('Come, my puppy!', 3.5, -30);
						}
					}
					doAfter(i * 100, () -> {
						doNatasGunshotEffectForUnit(caster);
						SpecialEffectsFluff.doExplosionEffect(tile.getXCenter(), tile.getYCenter());
						final tileUp = tile.getNextTileInDirection(UP);
						final tileDown = tile.getNextTileInDirection(DOWN);
						damageTileOrSummonHound(tile);
						if (tileUp != null) {
							damageTileOrSummonHound(tileUp);
						}
						if (tileDown != null) {
							damageTileOrSummonHound(tileUp);
						}
					});
				}
			},
			onTargetedEnemy: (caster, target) -> {},
			missile : {}
		},
		{	name: "Spike Rush",
			description : "Shoot spikes!",
			range : 3,
			effect : {
				type : "SKILL_SHOT_PIERCING",
				isDelayed: true,
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster, target) -> {
				target.tileOn.playEffect('Spike Rush', 500);
				caster.damageUnit(target, caster.getDamageWithVariation(), DARK);
			},
			onMiss: function(caster, tile: TileSpace) {
				tile.playEffect('Spike Rush No Particles', 500);
			},
			missile : {},
			targetEffect: {},
			audio: {
				onCast: 'SpikeRushMissileAudio',
				onHit: 'SpikeRushAudio'
			}
		},
		{	name: "Spike Rush Long",
			description : "Shoot spikes!",
			range : 8,
			effect : {
				type : "SKILL_SHOT_PIERCING",
				isDelayed: true,
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageWithVariation(), DARK),
			missile : {},
			targetEffect: {
				animationName: "Spike Rush",
				duration: 0.5
			}
		},
		{	name: "Shoot Canonball",
			description : "Shoot spikes!",
			range : 8,
			effect : {
				type : "SKILL_SHOT",
				isDelayed: true,
				directions : {
					left	: true
				}
			},
			onTargetedEnemy: (caster, target) -> {
				SpecialEffectsFluff.doExplosionEffect(target.getXCenter(), target.getYCenter());
				caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL);
			},
			missile : {
				animationName: 'Canonball',
				speed: 'FAST'
			},
			targetEffect: {
				animationName: "Throw Rock",
				duration: 0.5
			},
			audio: {
				onCast: 'ExplosionAudio'
			}
		},
		{	name: "Spear Thrust",
			description : "Thrust spear!",
			range : 2,
			effect : {
				type : "SKILL_SHOT_PIERCING",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL),
			missile : {},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
		},	
		{	name: 'Throw Molotov',
			description: 'Throws a molotov over obstacles on the ground. 50% chance to target a ',
			range: 7,
			effect: {
				type: 'TILE_IN_RANGE',
				allowUnits: true
			},
			missile: {
				animationName: 'Molotov',
				isArced: true,
				speed: 'MEDIUM'
			},
			targetEffect : {
				animationName : "Fire Ball",
				duration		: 0.5
			},
			onTargetedTile: (caster: Unit, tile: TileSpace) -> {
				//var andAlsoTile = tile.getRandomEmptyNeighbor();
				if (tile.hasUnit()) caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), FIRE);
				if (!!!tile.hasTrap()) Trap.createFromTemplateByName('Fire', tile);
				// if (andAlsoTile != null) {
				// 	if (andAlsoTile.hasUnit()) caster.damageUnit(andAlsoTile.unitOnIt, caster.getDamageWithVariation(), FIRE);
				// 	if (!!!andAlsoTile.hasTrap()) Trap.createFromTemplateByName('Fire', andAlsoTile);
				// }
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'MolotovImpactAudio'
			}
		},
		{	name: "Swipe Attack",
			description : "Attack left in the shape of a [.",
			manaCost: 0,
			range : 1,
			doJotAnimation: false,
			effect : {
				type : "MULTI_SKILL_SHOT",
				isDelayed: true,
				directions : {
					up			: true,
					upLeft		: true,
					left		: true,
					downLeft	: true,
					down		: true
				}
			},
			onCastStart: (caster: Unit) -> {
				Battlefield.pauseNextTurn();
				caster.actor.moveBy(-15, -15, 0.25, Easing.expoOut);
				doAfter(250, () -> {
					caster.actor.moveBy(-15, 15, 0.25, Easing.expoOut);
				});
				doAfter(750, () -> {
					caster.actor.moveBy(30, 0, 0.25, Easing.expoOut);
					Battlefield.resumeNextTurn();
				});
				final affectedTiles = [
					caster.tileOn.getNextTileInDirection(LEFT),
					caster.tileOn.getNextTileInDirection(UP_LEFT),
					caster.tileOn.getNextTileInDirection(DOWN_LEFT),
					caster.tileOn.getNextTileInDirection(UP),
					caster.tileOn.getNextTileInDirection(DOWN)
				];
				for (i in 0...affectedTiles.length) {
					if (affectedTiles[i] == null) continue;
					doAfter(i * 100, () -> {
						affectedTiles[i].playEffect('Chomp', 1550);
						playAudio('SwipeAttackAudio');
					});
				}
			},
			onTargetedEnemy: (caster, target) -> {
				caster.damageUnit(target, caster.getDamageWithVariation() * 1.5, PHYSICAL);
			},
			missile : {},
			targetEffect: {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			}
		},
		{	name: 'Cross Spikes',
			description: 'Shoots spikes left, right up and down.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				caster.aiData = null;
				var affectedTiles: Array<TileSpace> = [];		// Used only to count batches here
				function markTileIfExists(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					if (caster == null || caster.isDead) return;
					final theTile = Battlefield.getTile(i, j);
					caster.markTileRed(theTile);
					affectedTiles.push(theTile);
				}

				final i = caster.getI(), j = caster.getJ();

				markTileIfExists(i, j-1);
				markTileIfExists(i, j-2);
				markTileIfExists(i, j-3);
				markTileIfExists(i, j-4);
				markTileIfExists(i, j+2);
				markTileIfExists(i, j+3);
				markTileIfExists(i, j+4);
				markTileIfExists(i, j+5);

				markTileIfExists(i+1, j); markTileIfExists(i+1, j+1);
				markTileIfExists(i+2, j); markTileIfExists(i+2, j+1);
				markTileIfExists(i+3, j); markTileIfExists(i+3, j+1);
				markTileIfExists(i-1, j); markTileIfExists(i-1, j+1);
				markTileIfExists(i-2, j); markTileIfExists(i-2, j+1);
				markTileIfExists(i-3, j); markTileIfExists(i-3, j+1);

				caster.aiData = { affectedTiles: affectedTiles };
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				if (caster.aiData == null) return;
				if (caster.aiData.affectedTiles == null) return;

				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles.filter(t -> t != null);

				playAudio('SpikeRushAudio');
				for (tile in affectedTiles) {
					tile.playEffect('Spike Rush', 500);
					if (tile.hasUnit()) {
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), DARK);
					}
				}

				caster.aiData = null;
			}
		},
		{	name: 'Corner Spikes',
			description: 'Shoots spikes in the corners.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				caster.aiData = null;
				var affectedTiles: Array<TileSpace> = [];		// Used only to count batches here
				function markTileIfExists(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					if (caster == null || caster.isDead) return;
					final theTile = Battlefield.getTile(i, j);
					caster.markTileRed(theTile);
					affectedTiles.push(theTile);
				}

				final i = caster.getI(), j = caster.getJ();

				markTileIfExists(0, 0);	markTileIfExists(0, 6);
				markTileIfExists(0, 1); markTileIfExists(0, 5);
				markTileIfExists(0, 2); markTileIfExists(0, 4);

				markTileIfExists(1, 0); markTileIfExists(1, 6);
				markTileIfExists(3, 0); markTileIfExists(3, 6);

				markTileIfExists(4, 0);	markTileIfExists(4, 6);
				markTileIfExists(4, 1); markTileIfExists(4, 5);
				markTileIfExists(4, 2); markTileIfExists(4, 4);
				

				caster.aiData = { affectedTiles: affectedTiles };
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				if (caster.aiData == null) return;
				if (caster.aiData.affectedTiles == null) return;

				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles.filter(t -> t != null);

				playAudio('SpikeRushAudio');
				for (tile in affectedTiles) {
					tile.playEffect('Spike Rush', 500);
					if (tile.hasUnit()) {
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), DARK);
					}
				}

				caster.aiData = null;
			}
		},
		{	name: 'X Spikes',
			description: 'Shoots spikes in an X.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				caster.aiData = null;
				var affectedTiles: Array<TileSpace> = [];		// Used only to count batches here
				function markTileIfExists(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					if (caster == null || caster.isDead) return;
					final theTile = Battlefield.getTile(i, j);
					caster.markTileRed(theTile);
					affectedTiles.push(theTile);
				}

				final i = caster.getI(), j = caster.getJ();

				markTileIfExists(0, 0);	markTileIfExists(0, 1);
				markTileIfExists(1, 1);	markTileIfExists(1, 2);

				markTileIfExists(0, 5);	markTileIfExists(0, 6);
				markTileIfExists(1, 4);	markTileIfExists(1, 5);

				markTileIfExists(3, 1);	markTileIfExists(3, 2);
				markTileIfExists(4, 0);	markTileIfExists(4, 1);

				markTileIfExists(3, 4);	markTileIfExists(3, 5);
				markTileIfExists(4, 5);	markTileIfExists(4, 6);
				

				caster.aiData = { affectedTiles: affectedTiles };
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				if (caster.aiData == null) return;
				if (caster.aiData.affectedTiles == null) return;

				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles.filter(t -> t != null);

				playAudio('SpikeRushAudio');
				for (tile in affectedTiles) {
					tile.playEffect('Spike Rush', 500);
					if (tile.hasUnit()) {
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), DARK);
					}
				}

				caster.aiData = null;
			}
		},
		{	name: "Thunder Clap",
			description : "A delayed attack that hits all nearby enemies.",
			manaCost: 0,
			range : 1,
			doJotAnimation: false,
			effect : {
				type : "MULTI_SKILL_SHOT",
				isDelayed: true,
				directions : {
					up			: true,
					upLeft		: true,
					left		: true,
					downLeft	: true,
					down		: true,
					downRight	: true,
					right		: true,
					upRight		: true
				}
			},
			onTargetedEnemy: (caster, target) -> {
				chainLightning(caster, target);
				caster.damageUnit(target, caster.getSpellPowerWithVariation(SHOCK), SHOCK);
			},
			missile : {},
			targetEffect: {}
		},
		{	name: 'Silencio',
			description: 'Silences all Units in an X.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final tiles: Array<TileSpace> = [
					randomPlayer.tileOn,
					randomPlayer.tileOn.getNextTileInDirection(UP_RIGHT),
					randomPlayer.tileOn.getNextTileInDirection(UP_LEFT),
					randomPlayer.tileOn.getNextTileInDirection(DOWN_RIGHT),
					randomPlayer.tileOn.getNextTileInDirection(DOWN_LEFT)
				].filter(t -> t != null);
				caster.aiData = { affectedTiles: tiles };
				for (t in tiles) {
					caster.markTileRed(t);
				}
				caster.doDownAnimation();
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				caster.doDownUpAnimation();
				if (affectedTiles.length == 0) return;
				for (tile in affectedTiles) {
					tile.playEffect('Silence', 1250);
                	if (tile.hasUnit()) {
						if (tile.unitOnIt.owner == PLAYER) {
							tile.unitOnIt.silence();
						}
						caster.damageUnit(tile.unitOnIt, int(caster.getDamageWithVariation() * 0.7), SHOCK);
					}
				}
			},
			aiFlags: { isUsableWhileSilenced: false }
		},
		{	name: 'Fire Silencio',
			description: 'Silences all Units in an X.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final tiles: Array<TileSpace> = [
					randomPlayer.tileOn,
					randomPlayer.tileOn.getNextTileInDirection(UP_RIGHT),
					randomPlayer.tileOn.getNextTileInDirection(UP_LEFT),
					randomPlayer.tileOn.getNextTileInDirection(DOWN_RIGHT),
					randomPlayer.tileOn.getNextTileInDirection(DOWN_LEFT)
				].filter(t -> t != null);
				caster.aiData = { affectedTiles: tiles };
				for (t in tiles) {
					caster.markTileRed(t);
				}
				caster.doDownAnimation();
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				caster.doDownUpAnimation();
				if (affectedTiles.length == 0) return;
				for (tile in affectedTiles) {
					tile.playEffect('Silence', 1250);
                	if (tile.hasUnit()) {
						if (tile.unitOnIt.owner == PLAYER) {
							tile.unitOnIt.silence();
						}
						caster.damageUnit(tile.unitOnIt, int(caster.getDamageWithVariation() * 0.7), FIRE);
					}
				}
			}
		},
		{	name: 'Exprecio',
			description: 'Damages all units in a [] and shreds block.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			aiFlags: { isUsableWhileSilenced: false },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final tiles: Array<TileSpace> = randomPlayer.tileOn.getNeighbors(true);
				caster.aiData = { affectedTiles: tiles };
				for (t in tiles) {
					caster.markTileRed(t);
				}
				caster.doDownAnimation();
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				caster.doDownUpAnimation();
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				
				if (affectedTiles.length == 0) return;
				var affectedUnits = affectedTiles.filter(t -> t.hasUnit()).map(t -> t.unitOnIt);
				if (affectedUnits.length == 0) return;
				if (affectedUnits.indexOf(caster) != -1) {
					caster.addBlock(caster.getDamageWithVariation());
					caster.updateBars();
					caster.playEffect('Block', 1500);
				}
				affectedUnits = affectedUnits.filter(u -> u != caster);
				if (affectedUnits.length == 0) return;

				chainLightning(caster, affectedUnits[0]);

				for (i in 1...affectedUnits.length) {
					chainLightning(affectedUnits[i-1], affectedUnits[i]);
				}

				for (unit in affectedUnits) {
					unit.block = 0;
					caster.damageUnit(unit, int(caster.getDamageWithVariation()), SHOCK);
				}
			}
		},
		{	name: 'Fire Exprecio',
			description: 'Damages all units in a [] and shreds block.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			aiFlags: { isUsableWhileSilenced: false },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final tiles: Array<TileSpace> = randomPlayer.tileOn.getNeighbors(true);
				caster.aiData = { affectedTiles: tiles };
				for (t in tiles) {
					caster.markTileRed(t);
				}
				caster.doDownAnimation();
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				caster.doDownUpAnimation();
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				
				if (affectedTiles.length == 0) return;
				var affectedUnits = affectedTiles.filter(t -> t.hasUnit()).map(t -> t.unitOnIt);
				if (affectedUnits.length == 0) return;
				if (affectedUnits.indexOf(caster) != -1) {
					caster.addBlock(caster.getDamageWithVariation());
					caster.updateBars();
					caster.playEffect('Block', 1500);
				}
				affectedUnits = affectedUnits.filter(u -> u != caster);
				if (affectedUnits.length == 0) return;

				chainFire(caster, affectedUnits[0]);

				for (i in 1...affectedUnits.length) {
					chainFire(affectedUnits[i-1], affectedUnits[i]);
				}

				for (unit in affectedUnits) {
					unit.block = 0;
					caster.damageUnit(unit, int(caster.getDamageWithVariation()), FIRE);
				}
			}
		},
		{	name: 'Zonancio',
			description: 'Damages all units in a [] around I and I and gain Blocke.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			aiFlags: { isUsableWhileSilenced: false },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final tiles: Array<TileSpace> = caster.tileOn.getNeighbors(true);
				caster.aiData = { affectedTiles: tiles };
				for (t in tiles) {
					caster.markTileRed(t);
				}
				if (caster.mana > 0) {
					caster.addBlock(10);
					caster.playEffect('Block', 1500);
				}
				caster.updateBars();
				caster.doDownAnimation();
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				
				caster.doDownUpAnimation();

				if (affectedTiles.length == 0) return;
				final affectedUnits = affectedTiles.filter(t -> t.hasUnit()).map(t -> t.unitOnIt);
				if (affectedUnits.length == 0) return;

				for (unit in affectedUnits) {
					chainLightning(caster, unit);
					caster.damageUnit(unit, int(caster.getDamageWithVariation() * 1.3), SHOCK);
				}
			}
		},
		{	name: 'Fire Zonancio',
			description: 'Damages all units in a [] around I and I and gain Blocke.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			aiFlags: { isUsableWhileSilenced: false },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final tiles: Array<TileSpace> = caster.tileOn.getNeighbors(true);
				caster.aiData = { affectedTiles: tiles };
				for (t in tiles) {
					caster.markTileRed(t);
				}
				if (caster.mana > 0) {
					caster.addBlock(10);
					caster.playEffect('Block', 1500);
				}
				caster.updateBars();
				caster.doDownAnimation();
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				
				caster.doDownUpAnimation();

				if (affectedTiles.length == 0) return;
				final affectedUnits = affectedTiles.filter(t -> t.hasUnit()).map(t -> t.unitOnIt);
				if (affectedUnits.length == 0) return;

				for (unit in affectedUnits) {
					chainFire(caster, unit);
					caster.damageUnit(unit, int(caster.getDamageWithVariation() * 1.3), FIRE);
				}
			}
		},
		{	name: "Fat Slam",
			description : "Deals damage and pushes 1 square.",
			range : 1,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					upRight	: true,
					left	: true,
					down	: true,
					downRight: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit): Void {
				final damageTaken = caster.damageUnit(target, caster.getDamageWithVariation());
				if (target.isDead) return;
				if (damageTaken == 0) return;
				caster.pushTargetAwayFromMe(target, 1);
			},
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			}
		},
		{	name: 'Sumo Wave',
			description: 'Delayedly tries to stun all players on a large line',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				var affectedTiles: Array<TileSpace> = [];		// Used only to count batches here
				function markTileIfExists(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					final theTile = Battlefield.getTile(i, j);
					caster.markTileRed(theTile);
					affectedTiles.push(theTile);
				}

				final i = caster.getI(), j = caster.getJ();
				
				markTileIfExists(i+1, j);
				markTileIfExists(i+1, j+1);
				markTileIfExists(i-1, j);
				markTileIfExists(i-1, j+1);

				final batch1 = affectedTiles;
				affectedTiles = [];

				markTileIfExists(i-1, j-1);
				markTileIfExists(i, j-1);
				markTileIfExists(i+1, j-1);
				markTileIfExists(i, j+2);
				markTileIfExists(i-1, j+2);
				markTileIfExists(i+1, j+2);

				final batch2 = affectedTiles;
				affectedTiles = [];

				for (ik in i-1...i+2) markTileIfExists(ik, j-2);
				for (ik in i-1...i+2) markTileIfExists(ik, j+3);
				
				final batch3 = affectedTiles;
				affectedTiles = [];


				caster.aiData = { affectedTileBatches: [batch1, batch2, batch3] };
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				Battlefield.pauseNextTurn();
				final batches: Array<Array<TileSpace>> = caster.aiData.affectedTileBatches;
				
				function slamBatch(tiles: Array<TileSpace>) {
					startShakingScreen(0.01, 0.15);
					playAudio('SumoWaveAudio');
					for (tile in tiles) {
						if (tile == null) continue;				// Not sure how it's possible though
						tile.playEffect('Sumo Wave', 700);
						if (tile.hasUnit()) {
							tile.unitOnIt.stun();
						}
					}
				}
				function doSlams() {
					slamBatch(batches[0]);
					doAfter(250, () -> {
						slamBatch(batches[1]);
						doAfter(250, () -> {
							slamBatch(batches[2]);
							doAfter(250, () -> {
								Battlefield.resumeNextTurn();
							});
						});
					});
				}

				final flipMod = if (caster.isFlippedHorizontally) -1 else 1;
				final originX = caster.getX();
				final originY = caster.getY();
				caster.growTo(1.2 * flipMod, 0.8, 0.75);		// Crouch
				doAfter(1000, () -> {
					caster.growTo(0.8 * flipMod, 1.2, 0.2);
					doAfter(200, () -> {
						caster.actor.growTo(1 * flipMod, 1, 0.2);			// Grow to normal size
						caster.actor.moveBy(0, -45, 0.4, Easing.expoOut);	// Jump
					});
					doAfter(400, () -> {
						caster.actor.growTo(1.2 * flipMod, 0.8, 0.1);
						caster.actor.moveTo(originX, originY, 0.125, Easing.linear);
						doAfter(125, () -> {
							doSlams();
							doAfter(50, () -> {
								caster.actor.growTo(1 * flipMod, 1, 0.2);
							});
						});
					});
				});

				
			}
		},
		{	name: "Damned Aura",
			description : "All allies around are healed for 5",
			manaCost: 0,
			range : 1,
			effect : {
				type : "MULTI_SKILL_SHOT",
				directions : {
					up			: true,
					upLeft		: true,
					left		: true,
					downLeft	: true,
					down		: true,
					downRight	: true,
					right		: true,
					upRight		: true
				}
			},
			onCastStart: (caster: Unit) -> {
				Effects.playParticleAndThen(caster.getCenterPoint(), caster.getCenterPoint(), 'Damned Aura Cast', 850);
			},
			onTargetedEnemy: (caster, target) -> {
				if (target == null || target.isDead) return;
				if (target.owner == ENEMY) {
					target.heal(5);
					target.playEffect('Damned Aura');
				}
			},
			missile : {},
			targetEffect: {
				animationName: "",
				duration: 0.5
			},
			aiFlags: { isUsableWhileSilenced: false },
			audio: {
				onCast: 'CrowsFleetingAudio'
			}
		},
		{	name: "Ghost Attack",
			isDefault: true,
			description : "Make an attack on a close enemy for @(100% ATK) DARK damage!",
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.damage,
			range: 1,
			effect: {
				type: "SKILL_SHOT_GHOST",
				directions: {
					up: true,
					left: true,
					down: true,
					right: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				caster.damageUnit(target, caster.getDamageWithVariation(), DARK);
				if (target.isDead) return;
				if (caster.mana == 0) return;
				if (target.customData.ints.exists('hpReductionCounter'))
					target.customData.ints['hpReductionCounter'] += 1;
				else
					target.customData.ints['hpReductionCounter'] = 1;
				if (target.customData.ints['hpReductionCounter'] == 3) {
					target.customData.ints['hpReductionCounter'] = 0;
					target.setMaxHealth(target.stats.health - 3);
					playAudio('CurseAudio');
					target.playEffect('Skull', 750);
					if (target.isPlayerCharacter()) {
						target.playerCharacter.stats.health -= 3;
					}
					doAfter(750, () -> {
						target.scrollRed('-5 HP');
					});
				}
			},
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: { onCast: 'GhostAttackAudio' }
		},
		{	name: "Anchor",
			description : "Shoot a hook that brings in the enemy closer to you",
			cooldown: 2,
			range : 3,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft	  : true,
					upRight	  : true,
					downLeft  : true,
					downRight : true
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				caster.damageUnit(target, caster.getDamageWithVariation() / 2, PHYSICAL);
				if (!target.isDead) {
					final direction = target.getDirectionTowardsUnit(caster);
					trace('Got direction as ${directionToString(direction)}');
					target.pushInDirection(direction, 5);
				} else {
					trace('Is dead?');
				}
			},
			missile : {
				animationName : "Anchor",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'ShootArrowCastAudio',
				onHit: 'AnchorAudio'
			}
		},
		{	name: 'Spawn Slime',
			description: 'At the start of the next turn, spawns a Slime.',
			range: 0, 
			manaCost: 0,
			isInstant : true,
			cooldown: 5,
			effect: {
				type: 'NO_EFFECT',
				isDelayed: true
			},
			missile: {},
			onDelayedSetup: function(self: Unit, _: TileSpace) {
				self.say('*Prepares to spawn a Slime*');
				self.doDownAnimation();
			},
			onTargetedEnemy: (caster: Unit, alsoCaster: Unit) -> {
				caster.doDownUpAnimation();
				final tileToSpawn = caster.tileOn.getRandomEmptyNeighbor();
				final slime = Battlefield.spawnEnemyOnTile('Slime', tileToSpawn);
				slime.actor.disableActorDrawing();
				playAudio('MeleeAttackAudio');
				Effects.sendArcMissileAndThen(caster.tileOn.getCenterPointForMissile(), tileToSpawn.getCenterPoint(), 'Slime', Effects.MEDIUM, () -> {
					playAudio('SlimeDeathAudio');
					final effectPoint =  tileToSpawn.getCenterPoint();
					Effects.playOnlyParticleAt(effectPoint.x, effectPoint.y, 'Toxic Smoke');
					slime.actor.enableActorDrawing();
				});
			},
			aiFlags: { isUsableWhileSilenced: false },
			targetEffect: {}
		},
		{	name: 'Bubble Shield',
			description: 'Block up to 10 damage.',
			range: 0, 
			manaCost: 0,
			isInstant : true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			onTargetedEnemy: (caster: Unit, alsoCaster: Unit) -> {
				caster.addBlock(10);
				caster.updateBars();
				if (!!!caster.hasAttachment('Bubble Shield')) {
					caster.addAttachment('Bubble Shield');
				}
			},
			targetEffect: {},
			aiFlags: { isUsableWhileSilenced: false },
			audio: {
				onCast: 'BubbleShieldAudio'
			}
		},
		{	name: "Bubble Fission",
			description : "Shoot a bubble that splits on contact!",
			range : 4,
			effect : {
				type : "SKILL_SHOT_SPLIT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				if (target.name == 'Blubber' || target.name == 'Reverse Mermaid' && caster.mana > 0) {
					target.addBlock(4);
					target.updateBars();
					if (!!!target.hasAttachment('Bubble Shield')) {
						target.addAttachment('Bubble Shield');
					}
				} else {
					trace('Bubblering with ${caster.getDamageWithVariation()} damage');
					caster.damageUnit(target, caster.getDamageWithVariation(), COLD);
				}
			},
			missile : {
				animationName : "Bubble",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Hit",
				duration: 0.5
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'BubbleImpactAudio'
			}
		},
		{	name: "Bubble Blast",
			description : "Shoot a bubble that booms on contact!",
			range : 2,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				final block = caster.block;
				caster.block = 0;
				caster.updateBars();
				caster.damageUnit(target, caster.getDamageWithVariation() + block, COLD);
			},
			missile : {
				animationName : "Bubble",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Bubble Explosion",
				duration: 0.5
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'WaterExplosionAudio'
			}
		},
		{	name: "Chomp",
			// description : "Deals damage and drains a random stat. Returns the stat on death.",
			description : "Deals damage and transforms into a Zombie Peasant.",
			range : 1,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				final damage = caster.getDamageWithVariation();
				caster.damageUnit(target, damage, DARK);
				
				if (caster.isSilenced()) return;	// Can't transform if silenced

				caster.addBuff(new Buff('Transforming', 1, {}));
				doAfter(1000, () -> {
					if (caster.isDead) return;
					caster.scrollRed('TRANSFORMING');
					caster.doDownAnimation();
				});


				// final drainWhat: String = randomOf(['damage', 'spellPower', 'dodge', 'crit', 'armor']);
                // final drainAmount: Int =
                //     if (drainWhat == 'damage' || drainWhat == 'spellPower') 1
                //     else 20;
                // final drainWho: Unit = Battlefield.getRandomPlayerCharacterUnit();
                // final pcStats = drainWho.stats;
				// pcStats.set(drainWhat, pcStats.get(drainWhat) - drainAmount);

				// target.scrollRed(
				// 	if (drainWhat == 'damage') '-${drainAmount} DMG'
				// 	else if (drainWhat == 'spellPower') '-${drainAmount} SP'
				// 	else if (drainWhat == 'dodge') '-${drainAmount} DODGE'
				// 	else if (drainWhat == 'crit') '-${drainAmount} CRIT'
				// 	else '-${drainAmount} ARMOR'
				// );

				// final drainData = {
                //     drainWhat: drainWhat,
                //     drainAmount: drainAmount,
                //     drainWho: drainWho
                // }
				// final currentAIData: Array<Dynamic> = caster.aiData;
				// caster.aiData = if (currentAIData == null) [drainData] else currentAIData.concat([drainData]);

				// final damage = caster.getDamageWithVariation();
				// caster.damageUnit(target, damage, DARK);
			},
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Chomp",
				duration: 1.55
			},
			audio: { onCast: 'SwipeAttackAudio' }
		},
		{	name: "Chain Lightning",
			range: 3,
			effect: {
				type: 'TILE_IN_RANGE',
				tileInRange: {
					allowUnits: true
				}
			},
			onTargetedTile: (caster: Unit, tile: TileSpace) -> {
				final unitsAffected: Array<Unit> = [];
				
				if (tile.hasUnit() == false) {
					trace('WARNING: Targeted tile by Chain Lightning at ${tile.toString()} has no unit!');
					return;
				}
				chainLightning(caster, tile.unitOnIt);
			},
			aiFlags: { isUsableWhileSilenced: false }
		},
		{	name: "Chain Fire",
			range: 3,
			effect: {
				type: 'TILE_IN_RANGE',
				tileInRange: {
					allowUnits: true
				}
			},
			missile: {},
			targetEffect: {
				animationName: "Fire Ball",
				duration: 0.5
			},
			onTargetedTile: (caster: Unit, tile: TileSpace) -> {
				final unitsAffected: Array<Unit> = [];
				function chainLightning(fromUnit: Unit, toUnit: Unit) {
					final lightning = createActor('SpecialEffectActor', 'Particles');
					lightning.setAnimation('Chain Fire');
					playAudio('FoomAudio');
					stretchActorBetweenPoints(lightning, fromUnit.getXCenter(), fromUnit.getYCenter(), toUnit.getXCenter(), toUnit.getYCenter());
					doAfter(525, () -> {
						recycleActor(lightning);
					});
					toUnit.tileOn.igniteIfHasOil();
					caster.damageUnit(toUnit, caster.getDamageWithVariation() + toUnit.block, FIRE);
					unitsAffected.push(toUnit);

					final extraTargets = toUnit.tileOn.getNeighbors().filter(t -> t.hasUnit()).map(t -> t.unitOnIt).filter(u -> unitsAffected.indexOf(u) == -1);
					if (extraTargets.length == 0) return;

					final randomTarget: Unit = randomOf(extraTargets);

					doAfter(125, () -> {
						chainLightning(toUnit, randomTarget);
					});
				}
				if (tile.hasUnit() == false) {
					trace('WARNING: Targeted tile by Chain Fire at ${tile.toString()} has no unit!');
					return;
				}
				chainLightning(caster, tile.unitOnIt);
			},
			aiFlags: { isUsableWhileSilenced: false }
		},
		{	name: "Shoot Laser",
			description : "Shoot a laser in that direction.",
			range : 4,
			manaCost: 1,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: (caster, target) -> {
				final laser = createActor('SpecialEffectActor', 'Particles');
				laser.setAnimation('Laser Beam');
				final from = caster.tileOn.getCenterPointForMissile();
				final to = target.tileOn.getCenterPointForMissile();
				stretchActorBetweenPoints(laser, from.x, from.y, to.x, to.y);
				target.tileOn.igniteIfHasOil();
				caster.damageUnit(target, caster.getDamageWithVariation(), FIRE);
				doAfter(300, () -> {
					recycleActor(laser);
				});
			},
			targetEffect: {
				animationName: "Laser",
				duration: 0.5
			},
			audio: {
				onCast: 'LaserAudio',
				onHit: 'HitAudio'
			}
		},
		{	name: 'Drain Mana',
			description: 'Drains 3 mana from nearby units.',
			range: 1,
			manaCost: 0,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				if (caster.customData.ints.exists('manaStored') == false) {
					caster.customData.ints['manaStored'] = 0;
				}
				final targets = caster.tileOn.getNeighborUnits();
				for (target in targets) {
					if (target.mana <= 0) continue;
					doChainEffectBetweenUnits('Drain Mana', 300, caster, target);
					final amountDrained = int(min(target.mana, 3));
					target.deplete(amountDrained);
					caster.customData.ints['manaStored'] += amountDrained;
				}
			},
			aiFlags: { isUsableWhileSilenced: false },
			audio: { onCast: 'DrainManaAudio' }
		},
		{	name: 'Raise Dead',
			description: 'Revives a dead unit into a zombie. If it can not, it will raise a wall instead.',
			range: 0, 
			manaCost: 1,
			isInstant : true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			audio: { onCast: 'RaiseDeadAudio' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				function tryToRaiseDead(): Bool {
					final availableTargets = Battlefield
						.getAllDeadUnits()
						.filter(unit -> unit.isEnemy())
						.filter(unit -> unit.customData.strings.exists('wasInvolvedInRaiseDead') == false);
					if (availableTargets.length == 0) return false;

					final target = availableTargets[0];
					target.customData.strings['wasInvolvedInRaiseDead'] = 'yes';		// So it can't be raised twice

					var tileToSpawn: TileSpace;
					if (target.tileWhereDied.hasUnit() == false)
						tileToSpawn = target.tileWhereDied;
					else {
						final nearbyTiles = target.tileWhereDied.getEmptyNeighbors();
						if (nearbyTiles.length == 0) return false;
						tileToSpawn = nearbyTiles[0];
					}
					if (tileToSpawn == null) return false;

					final spawnedUnit = Battlefield.spawnEnemyOnTile('Zombie', tileToSpawn);
					spawnedUnit.customData.strings['wasInvolvedInRaiseDead'] = 'yes';	// So it can't be raised later
					spawnedUnit.playEffect('Raise Dead', 1200);
					flashWhite(spawnedUnit.actor, 500);
					return true;
				}
				function tryToRaiseWall(): Bool {
					function spawnWallOnTile(tile: TileSpace) {
						final stone = Battlefield.spawnUnitOnTile('Gravestone', tile, NEUTRAL);
						final originalY = stone.getY();
						stone.playEffect('Smoke', 100);
						stone.actor.setY(int(stone.getY() + stone.getHeight() * 0.25));
						stone.actor.growTo(1, 0.5, 0, Easing.linear);
						doAfter(10, () -> {
							stone.actor.growTo(1, 1, 0.5, Easing.expoOut);
							stone.actor.moveTo(stone.getX(), originalY, 0.5, Easing.expoOut);
						});
					}
					for (unit in Battlefield.getAllPlayerUnits()) {
						final rightTile = unit.tileOn.getNextTileInDirection(RIGHT);
						if (rightTile != null && rightTile.hasUnit() == false) {
							spawnWallOnTile(rightTile);
							return true;
						}
						final leftTile = unit.tileOn.getNextTileInDirection(LEFT);
						if (leftTile != null && leftTile.hasUnit() == false) {
							spawnWallOnTile(leftTile);
							return true;
						}
					}
					return false;
				}

				final raiseDeadResult = tryToRaiseDead();
				if (raiseDeadResult == true) return;

				final raiseWallResult = tryToRaiseWall();
				if (raiseWallResult == true) return;
			},
			aiFlags: { isUsableWhileSilenced: false },
			targetEffect: {}
		},
		{	name: 'Lightning Rain',
			description: 'Deals 5 + Lightning Damage damage to a random enemy.',
			range: 1,
			manaCost: 0,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				caster.initCustomInt('lightningDamage', 0);
				final targets = Battlefield.getAllPlayerUnits();
				if (targets.length == 0) return;
				final target: Unit = randomOf(targets);
				final damageDone = if (caster.mana == 0) 5 else 5 + caster.customData.ints['lightningDamage'];
				caster.damageUnit(target, damageDone);
				final lightning = target.playEffect('Lightning Strike', 800);
				lightning.setY(lightning.getY() - 35);
				target.playEffect('Throw Rock', 150);
			}
		},
		{	name: 'Lightning Empower',
			description: 'Increases a targets lightning bonus damage by 1.',
			range: 1,
			manaCost: 0,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final targets = Battlefield.getAllAliveEnemyUnits().filter(u -> u.customData.ints.exists('lightningDamage'));
				if (targets.length == 0) return;
				final target: Unit = randomOf(targets);
				target.customData.ints['lightningDamage'] += randomIntBetween(1, 2);
				doChainEffectBetweenUnits('Chain Lightning Yellow', 600, caster, target);
			},
			audio: { onCast: 'LightningEmpowerAudio' }
		},
		{	name: 'Slow Down',
			description: 'Slows nearby units by 1.',
			range: 1,
			manaCost: 0,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final affectedTiles = caster.tileOn.getNeighbors();
				for (neighbor in affectedTiles) {
					neighbor.flashTargeted();
				}
				final targets = caster.getNeighborUnits();
				for (target in targets) {
					if (target.hasBuff('Slow Down')) {
						target.getBuff('Slow Down').remainingDuration += 1;
					} else {
						target.addBuff(new Buff('Slow Down', 2, { speed: -1 }));
					}
					target.playEffect('Slow Down', 150);
				}
			}
		},
		{	name: "Shoulder Throw",
			description : "Attack a unit and throw it over the shoulder",
			cooldown: 4,
			range : 1,
			doJotAnimation: false,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL);
				if (target.isLarge) return;
				final targetDirection = caster.getDirectionTowardsUnit(target);
				final throwDirection = getOppositeDirection(targetDirection);
				var landingTile = caster.tileOn.getNextTileInDirection(throwDirection);
				if (landingTile == null) return;
				if (throwDirection == RIGHT) {
					landingTile = landingTile.getNextTileInDirection(RIGHT);
				}
				if (landingTile == null) return;
				final fromPoint = target.getHypotheticCoordinatesOnTile(target.tileOn);
				final toPoint = target.getHypotheticCoordinatesOnTile(landingTile);
				target.putOnTile(landingTile);
				Effects.sendArcMissileCustomAndThen({
					from: fromPoint,
					to: toPoint,
					actorName: 'UnitActor',
					missileName: target.actor.getAnimation(),
					speed: Effects.MEDIUM,
					onActorCreated: (missile: Actor) -> {
						target.actor.disableActorDrawing();
						if (target.isFlippedHorizontally) {
							flipActorHorizontally(missile);
						}
					},
					andThen: () -> {
						target.actor.enableActorDrawing();
					}
				});
				
				final originalY = caster.actor.getY();
				caster.actor.moveTo(caster.getX(), caster.getY() - 25, 0.35, Easing.expoOut);
				doAfter(350, function() {
					caster.flipHorizontally();
					caster.actor.moveTo(caster.getX(), originalY, 0.2, Easing.linear);
				});
			},
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: { onCast: 'MeleeAttackAudio' }
		},
		{	name: "Big Smash",
			range: 2,
			effect: {
				type: 'TILE_IN_RANGE',
				isDelayed: true,
				tileInRange: {
					allowUnits: true
				}
			},
			missile: {},
			audio: {
				onCast: 'BigSmashAudio'
			},
			targetEffect: {
				animationName: "Throw Rock",
				duration: 0.5
			},
			onDelayedSetup: (caster: Unit, tile: TileSpace) -> {
				final additionalMarkedTiles: Array<TileSpace> = tile.getNeighbors();
				for (tile in additionalMarkedTiles) {
					tile.addDangerMarker();
					caster.tilesMarkedRed.push(tile);
				}
				caster.aiData = { additionalMarkedTiles: additionalMarkedTiles };
			},
			onTargetedTile: (caster: Unit, tile: TileSpace) -> {
				final additionalMarkedTiles: Array<TileSpace> = cast caster.aiData.additionalMarkedTiles;
				final affectedTiles = [tile].concat(additionalMarkedTiles);
				tile.playEffect('Dirt', 150);
				for (tile in affectedTiles) {
					if (tile.hasUnit())
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PHYSICAL);
					tile.playEffect('Big Smash', 700);
				}
			}
		},
		{	name: 'Shoot Target',
			description: 'Shoots a target 4 times with 66% hit chance. If the target is covered by another unit, has only 33% hit change and 33% to the other unit.',
			range: 1,
			manaCost: 0,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT',
				isDelayed: true
			},
			missile: {},
			audio: {
				onPrepare: 'GunCockAudio'
			},
			onDelayedSetup: (caster: Unit, tile: TileSpace) -> {
				caster.initCustomString('isTargeting', 'no');
				caster.customData.strings['isTargeting'] = 'yes';
				final targetedUnit: Unit = Battlefield.getRandomAlivePlayerUnit();
				targetedUnit.addAttachment('Targeted');
				caster.aiData = { targetedUnit: targetedUnit };
			},
			onTargetedTile: function (caster: Unit, tile: TileSpace): Void {
				final target: Unit = caster.aiData.targetedUnit;
				if (target.isDead) return;
				target.removeAttachment('Targeted');
				final isCasterToRight = target.getJ() <= caster.getJ();
				final xDistance = Math.abs(target.getJ() - caster.getJ());
				final isCasterToDown = target.getI() <= caster.getI();
				final yDistance = Math.abs(target.getI() - caster.getI());

				final hasUnitTo = (dir) -> target.tileOn.getNextTileInDirection(dir) != null && target.tileOn.getNextTileInDirection(dir).hasUnit();
				final getUnitTo = (dir) -> target.getNextUnitInDirection(dir);
				final getEitherUnitTo = (dir1, dir2) -> if (hasUnitTo(dir1)) getUnitTo(dir1) else getUnitTo(dir2);
				final getUnitInDirectionOrSelf = (dir) -> if (hasUnitTo(dir)) getUnitTo(dir) else target;
				final getEitherUnitInDirectionsOrSelf = (dir1, dir2) -> if (hasUnitTo(dir1)) getUnitTo(dir1) else if (hasUnitTo(dir2)) getUnitTo(dir2) else target;

				function shootTarget() {
					if (target.isDead) return;
					doHighwaymanGunshotEffectForUnit(caster);
					playAudio('GunShootAudio');
					if (percentChance(67) == false) {
						Battlefield.floatingTextManager.pump('MISS', target.getScreenXCenter(), target.getScreenYCenter());
						return;	// 33% chance to miss
					}

					var secondaryUnit: Unit = null;
					if (xDistance > yDistance) {
						if (isCasterToRight) {
							secondaryUnit = getUnitInDirectionOrSelf(RIGHT);
						} else {
							secondaryUnit = getUnitInDirectionOrSelf(LEFT);
						}
					} else if (xDistance < yDistance) {
						if (isCasterToDown) {
							secondaryUnit = getUnitInDirectionOrSelf(DOWN);
						} else {
							secondaryUnit = getUnitInDirectionOrSelf(UP);
						}
					} else {	// xDistance == yDistance
						if (isCasterToRight && isCasterToDown) {
							secondaryUnit = getEitherUnitInDirectionsOrSelf(RIGHT, DOWN);
						} else if (isCasterToRight && isCasterToDown == false) {
							secondaryUnit = getEitherUnitInDirectionsOrSelf(RIGHT, UP);
						} else if (isCasterToRight == false && isCasterToDown) {
							secondaryUnit = getEitherUnitInDirectionsOrSelf(LEFT, DOWN);
						} else {
							secondaryUnit = getEitherUnitInDirectionsOrSelf(LEFT, UP);
						}
					}

					trace('Secondary target: ${secondaryUnit.name}');
					final target: Unit = if (secondaryUnit == caster) target else randomOf([target, secondaryUnit]);	// Can be the same
					target.playEffect('Throw Rock Small');
					caster.damageUnit(target, int(caster.getDamageWithVariation() * 0.7));
				}

				pauseNextTurn();
				shootTarget();
				doAfter(200, () -> shootTarget());
				doAfter(400, () -> shootTarget());
				doAfter(600, () -> shootTarget());
				doAfter(800, () -> {
					resumeNextTurn();
				});
			}
		},
		{	name: 'Throw Net (Enemy)',
			description: 'Throw a net on a unit. Roots the target.',
			manaCost: 0,
			range: 3,
			cooldown: 8,
			effect: {
				type: "TARGET_IN_RANGE",
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				if (caster.hasAttachment('Has Net')) {
					caster.removeAttachment('Has Net');
				}
				if (caster.hasBuff('Will Root')) {
					caster.removeBuff('Will Root');
				}
				target.root();
			},
			missile: {
				animationName: 'Net',
				speed: 'MEDIUM'
			},
			audio: {
				onCast: 'ThrowNetAudio',
				onHit: 'HitAudio'
			}
		},
		{	name: 'Throw Net (Enemy No CD)',
			description: 'Throw a net on a unit. Roots the target.',
			manaCost: 0,
			range: 7,
			cooldown: 0,
			effect: {
				type: "TARGET_IN_RANGE",
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				if (caster.hasAttachment('Has Net')) {
					caster.removeAttachment('Has Net');
				}
				target.root();
			},
			missile: {
				animationName: 'Net',
				speed: 'MEDIUM'
			},
			audio: {
				onCast: 'ThrowNetAudio',
				onHit: 'HitAudio'
			}
		},
		{	name: 'Throw Net (Mermaid)',
			description: 'Throw a net on a unit. Roots the target.',
			manaCost: 0,
			range: 7,
			cooldown: 8,
			effect: {
				type: "TARGET_IN_RANGE",
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				if (caster.hasAttachment('Has Net')) {
					caster.removeAttachment('Has Net');
				}
				target.root();
			},
			missile: {
				animationName: 'Net',
				speed: 'MEDIUM'
			},
			audio: {
				onCast: 'ThrowNetAudio',
				onHit: 'HitAudio'
			}
		},
		{	name: 'Throw Net',
			description: 'Throw a net on a unit that roots the target and deals @(25% ATK) PURE damage.',
			value: (caster: EntityWithStats, atIndex: Int) -> min(int(caster.stats.damage * 0.25), 1),
			manaCost: 4,
			range: 5,
			cooldown: 8,
			isFreeAction: true,
			effect: {
				type: "TARGET_IN_RANGE",
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				target.root();
				caster.damageUnit(target, int(caster.getDamageWithVariation() * 0.25), PURE);
			},
			missile: {
				animationName: 'Net',
				speed: 'MEDIUM'
			},
			audio: {
				onCast: 'ThrowNetAudio',
				onHit: 'HitAudio'
			}
		},

		// Boss Spells
		{	name: "Vampire Attack",					// Normal attack, but has lifesteal and a cool effect
			isDefault: true,
			description : "A normal attack that drains 50% of the damage done as Health. Overheal adds block.",
			range : 1,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster, target) {
				caster.playEffect('Lifesteal', 1100);
				target.playEffect('Lifesteal Reversed', 1100);
				doVampireDrain(target.getCenterPointForMissile(), caster.getCenterPointForMissile());
				caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL);
				final heal = int(caster.getDamageWithVariation() / 2);
				caster.heal(heal);
				if (caster.health + heal > caster.stats.health) {
					final blockAmount = caster.health + heal - caster.stats.health;
					caster.addBlock(blockAmount);
					caster.updateBars();
				}
			},
			missile : {},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: { onCast: 'LifestealAudio' }
		},
		{	name: "Vampire Attack Unleashed",		// Like Vampire Attack but diagonal and 2 range
			isDefault: true,
			description : "A normal attack that drains 50% of the damage done as Health. Overheal adds block.",
			range : 2,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft		: true,
					upRight		: true,
					downLeft	: true,
					downRight	: true
				}
			},
			onTargetedEnemy: function(caster, target) {
				caster.playEffect('Lifesteal', 1100);
				target.playEffect('Lifesteal Reversed', 1100);
				doVampireDrain(target.getCenterPointForMissile(), caster.getCenterPointForMissile());
				caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL);
				final heal = int(caster.getDamageWithVariation() / 2);
				caster.heal(heal);
				if (caster.health + heal > caster.stats.health) {
					final blockAmount = caster.health + heal - caster.stats.health;
					caster.addBlock(blockAmount);
					caster.updateBars();
				}
			},
			missile : {},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: { onCast: 'LifestealAudio' }
		},
		{	name: 'Summon Bats',
			description: 'Summons up to 2 bats on corners of the map',
			range: 1,
			manaCost: 0,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final tilesThatCanSummon = [
					Battlefield.getTile(0, 0),
					Battlefield.getTile(4, 6),
					Battlefield.getTile(0, 6),
					Battlefield.getTile(4, 0)
				].filter(tile -> tile.hasUnit() == false);
				final tilesToSummonOn =
					if (tilesThatCanSummon.length > 2) [tilesThatCanSummon[0], tilesThatCanSummon[1]]
					else tilesThatCanSummon;
				if (tilesToSummonOn.length == 0)
					caster.say('Gah!! I can\'t summon bats!', 2);
				else {
					caster.say('To my aid!', 2);
					playAudio('BatDeathAudio');
				}
				for (tile in tilesToSummonOn) {
					final bat = Battlefield.spawnEnemyOnTile('Brat', tile);
					bat.playEffect('Smoke', 150);
				}
			}
		},
		{	name: 'Sacrifice Bat',
			description: 'Sacrifices a Bat to heal himself.',
			range: 1,
			manaCost: 0,
			isInstant: true,
			effect: { type: 'NO_EFFECT' },
			missile: {},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final bat = Battlefield.getUnitByName('Brat');
				if (bat == null) {
					caster.say('I hate you!!!', 2);
					return;
				}
				bat.playEffect('Lifesteal Reversed', 1100);
				bat.playEffect('Bat Explosion');
				bat.remove();
				caster.heal(15);
				caster.playEffect('Lifesteal', 1100);
				caster.say('Feed me!!!', 2);
				playAudio('SacrificeAudio');
			}
		},
		{	name: 'Hashtag Attack',
			description: 'Wahuu!',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final additionalMarkedTiles = Battlefield.tiles
					.filterToArray(t -> 
						(t.getI() == 1 || t.getI() == 3) || (t.getJ() == 2 || t.getJ() == 4)	// Shaped like a # hashtag
					);
				for (tile in additionalMarkedTiles) {
					caster.markTileRed(tile);
				}
				caster.aiData = { affectedTiles: additionalMarkedTiles };
				caster.say('Baww!!!', 2);
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				playAudio('LifestealAudio');
				final affectedTiles: Array<TileSpace> = cast caster.aiData.affectedTiles;
				for (tile in affectedTiles) {
					if (tile.hasUnit()) {
						doVampireDrain(tile.unitOnIt.getCenterPointForMissile(), caster.getCenterPointForMissile());
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PHYSICAL);
					}
				}
			}
		},
		{	name: 'Bullet Hell',
			description: 'Shoot half of all tiles!!',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final additionalMarkedTiles = Battlefield.tiles
					.filterToArray(t -> 
						(t.getI() % 2 == 0 && t.getJ() % 2 == 0)
						||
						(t.getI() % 2 == 1 && t.getJ() % 2 == 1)
					);
				for (tile in additionalMarkedTiles) {
					tile.addDangerMarker();
					caster.tilesMarkedRed.push(tile);
				}
				caster.aiData = { affectedTiles: additionalMarkedTiles };
				caster.say('This will be fun!', 2);
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				playAudio('BulletHellAudio');
				final affectedTiles: Array<TileSpace> = cast caster.aiData.affectedTiles;
				for (tile in affectedTiles) {
					if (tile.hasUnit())
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PHYSICAL);
				}
			}
		},
		{	name: 'Anchor Lift',
			description: 'Lifts an existing anchor and damages all units around it. Will only be cast if it can damage a player unit.',
			isInstant: true,
			effect: { type: 'NO_EFFECT' },
			audio: { onCast: 'AnchorLiftAudio' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final allAnchors = Battlefield.getAllAliveNeutralUnits().filter(u -> u.name == 'Anchor');	// Implicitly, there must be anchors because the spell was cast only if there are anchors

				var anchor: Unit = null;
				for (a in allAnchors) {
					final nearbyPlayers = a.getNeighborPlayerUnits();
					if (nearbyPlayers.length == 0) continue;
					else {
						anchor = a;
						break;
					}
				}
				if (anchor == null) {
					trace('WARNING: Null anchor for Anchor Lift!! This should not happen!');
					return;
				}

				final rope = createActor('LightningEffectActor', 'Unit0');
				rope.setAnimation('Rope');

				final ropeAttachX = 67, ropeAttachY = 12;
				final ropeOriginX = anchor.getX() + ropeAttachX, ropeOriginY = getScreenY();
				final totalRopeLength = anchor.getY() + ropeAttachY - getScreenY();
				doEveryUntil(20, 300, (time: Int) -> {
					final currentLength = time / 300 * totalRopeLength;
					stretchActorBetweenPoints(rope, ropeOriginX, ropeOriginY, anchor.getX() + ropeAttachX, anchor.getY() + ropeAttachY);
				});
				doAfter(300, () -> {
					anchor.playEffect('Smoke');
					for (unit in anchor.getNeighborUnits()) {
						caster.damageUnit(unit, caster.getDamageWithVariation() + 2, PHYSICAL);
					}
					anchor.actor.moveTo(anchor.actor.getX(), getScreenY() - anchor.actor.getHeight(), 0.5, Easing.linear);
					doEveryUntil(20, 500, () -> {
						stretchActorBetweenPoints(rope, ropeOriginX, ropeOriginY, anchor.getX() + ropeAttachX, anchor.getY() + ropeAttachY);
					});
					doAfter(500, () -> {
						recycleActor(rope);
					});
				});
			}
		},
		{	name: 'Molly',
			description: 'Throws a molotov. 50% chance to target a player unit. 50% chance to hit a player unit if lands near it.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT',
				isDelayed: true
			},
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final targetTile =
					if (percentChance(50)) Battlefield.getRandomAlivePlayerUnit().tileOn
					else Battlefield.getRandomAlivePlayerUnit().tileOn.getRandomEmptyNeighbor();
				if (targetTile == null) {
					caster.aiData = null;
					return;
				}
				caster.markTileRed(targetTile);
				caster.aiData = { targetTile: targetTile };
				caster.doDownAnimation();
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				if (caster.aiData == null) {
					return;
				}
				final targetTile: TileSpace = if (caster.aiData != null && caster.aiData.targetTile != null) caster.aiData.targetTile else null;

				if (targetTile == null) return;
				final targetPoint = targetTile.getCenterPointForMissile(NO_DIRECTION);
				
				Battlefield.pauseNextTurn();
				playAudio('FoomAudio');
				caster.doDownUpAnimation();
				Effects.sendArcMissileAndThen(
					caster.getCenterPointForMissile(),
					targetPoint,
					'Molotov',
					Effects.MEDIUM,
					() -> {
						playAudio('MolotovImpactAudio');
						if (caster.mana == 0) {
							targetTile.playEffect('Throw Rock');
							if (targetTile.hasUnit()) {
								caster.damageUnit(targetTile.unitOnIt, caster.getDamageWithVariation(), PHYSICAL);
							}
						} else {
							targetTile.playEffect('Fire Ball');
							if (targetTile.hasUnit()) {
								caster.damageUnit(targetTile.unitOnIt, caster.getDamageWithVariation(), FIRE);
							}
							if (targetTile.hasTrap() && targetTile.trapOnIt.name == 'Oil') {
								targetTile.trapOnIt.kill();
							}
							if (targetTile.hasTrap() == false) {
								Battlefield.spawnTrap('Fire', targetTile);
							}
							final oilNeighbors = targetTile.getNeighbors(true).filter(t -> t.hasTrap() && t.trapOnIt.name == 'Oil');
							for (t in oilNeighbors) {
								t.trapOnIt.kill();
								Battlefield.spawnTrap('Fire', t);
							}
						}						
						Battlefield.resumeNextTurn();
					}
				);
			}
		},
		{	name: 'Anchor Drop',
			description: 'Drops an anchor. If there is another Anchor, pull them to eachother and damage between.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final tiles: Array<TileSpace> = [randomPlayer.tileOn].concat(randomPlayer.tileOn.getNeighbors(true));
				caster.tilesMarkedRed = tiles;
				caster.aiData = { affectedTiles: tiles };
				for (t in tiles) {
					t.addDangerMarker();
				}
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				
				if (affectedTiles.length == 0) return;
				final middleTile = affectedTiles[0];
				if (middleTile.hasUnit()) return;
				
				caster.say('Anchorrgh!!', 2);
				final anchor = createActor('UnitActor', 'Units${middleTile.getI()}');
				anchor.setAnimation('Anchor');
				final anchorY = middleTile.getHypotheticCoordinatesForActor(anchor).y;
				final anchorX = middleTile.getHypotheticCoordinatesForActor(anchor).x;
				anchor.setY(getScreenY() - anchor.getHeight());
				anchor.setX(anchorX);
				anchor.moveTo(anchorX, anchorY, 0.5, Easing.expoIn);
				doAfter(500, () -> {
					playAudio('AnchorDropAudio');
					if (middleTile.hasUnit() == false) {
						final anchorUnit = Battlefield.spawnUnitOnTile('Anchor', middleTile, NEUTRAL);
						anchorUnit.playEffect('Smoke');
						recycleActor(anchor);
					} else {
						SpecialEffectsFluff.doFlinchAnimation(anchor, () -> {
							recycleActor(anchor);
						});
					}
					startShakingScreen(0.01, 0.25);
					for (tile in affectedTiles) {
						if (tile.hasUnit()) {
							if (tile.unitOnIt.name == 'Anchor' && tile != middleTile)
								tile.unitOnIt.kill();
							else
								caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation() + 5);
						}
					}
				});
			}
		},
		{	name: 'Quad Spikes',
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final tilesMarkedRed: Array<TileSpace> = [];
				function markTileIfExists(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					final tileToMark = Battlefield.getTile(i, j);
					tileToMark.addDangerMarker();
					tilesMarkedRed.push(tileToMark);
				}
				final i = caster.getI();
				final j = caster.getJ();
				markTileIfExists(i-1, j);
				markTileIfExists(i-2, j);
				markTileIfExists(i-3, j);
				markTileIfExists(i+1, j);
				markTileIfExists(i+2, j);
				markTileIfExists(i+3, j);
				markTileIfExists(i, j-1);
				markTileIfExists(i, j-2);
				markTileIfExists(i, j-3);
				markTileIfExists(i, j+1);
				markTileIfExists(i, j+2);
				markTileIfExists(i, j+3);
				caster.tilesMarkedRed = tilesMarkedRed;
				caster.aiData = { affectedTiles: tilesMarkedRed }
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				playAudio('SpikeRushAudio');
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				for (tile in affectedTiles) {
					Effects.playEffectAt(tile.getXCenter(), tile.getYCenter(), 'Spike Rush', 500);
					if (tile.hasUnit()) {
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), DARK);
					}
				}
			}
		},
		{	name: 'Burrow',
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				Battlefield.pauseNextTurn();
				final possibleTiles = [
					Battlefield.getTile(1, 0),
					Battlefield.getTile(2, 0),
					Battlefield.getTile(3, 0),
					Battlefield.getTile(1, 6),
					Battlefield.getTile(2, 6),
					Battlefield.getTile(3, 6)
				].filter(t -> t.hasNoUnit());
				if (possibleTiles.length == 0) return;
				final targetTile: TileSpace = randomOf(possibleTiles);
				caster.playEffect('Smoke');
				caster.actor.growTo(0.8, 0.2, 0.35, Easing.expoIn);
				doAfter(350, () -> {
					caster.actor.disableActorDrawing();
					caster.hideBars();
				});
				doAfter(1000, () -> {
					caster.putOnTile(targetTile);
					caster.actor.enableActorDrawing();
					caster.showBars();
					caster.playEffect('Smoke');
					if (caster.tileOn.hasTrap()) {
						caster.tileOn.trapOnIt.trigger(caster);
					}
					if (caster.isDead) {
						return;
					}
					if (caster.getJ() == 0) {
						caster.growTo(-1, 1, 0.35);
						if (caster.isFlippedHorizontally == false) {
							caster.isFlippedHorizontally = true;
						}
					} else {
						caster.growTo(1, 1, 0.35);
						if (caster.isFlippedHorizontally) {
							caster.isFlippedHorizontally = false;
						}
					}
				});

				// Now mark for charge
				doAfter(1750, () -> {
					if (caster.isDead) {
						Battlefield.resumeNextTurn();
						return;
					}
					final affectedTiles = Battlefield.tiles.filterToArrayIndicesToT((i: Int, j: Int) -> i == caster.getI() || i+1 == caster.getI() || i-1 == caster.getI());
					for (t in affectedTiles) {
						caster.markTileRed(t);
					}
					Battlefield.resumeNextTurn();
				});
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				var tileIterator = caster.tileOn;
				var direction = if (caster.getJ() == 0) RIGHT else LEFT;
				
				while (tileIterator.getNextTileInDirection(direction) != null && tileIterator.getNextTileInDirection(direction).hasNoUnit()) {
					tileIterator = tileIterator.getNextTileInDirection(direction);
				}
				caster.slideToTile(tileIterator);
				final casterI = caster.getI();
				final casterJ = caster.getJ();
				final affectedTiles = Battlefield.tiles.filterToArrayIndicesToT((i: Int, j: Int) -> 
					(i+1 == casterI || i-1 == casterI || i == casterI)
				);
				for (t in affectedTiles) {
					if (t == null) continue;	// Not sure how it could be null but be defensive
					if (t.hasUnit()) {
						t.playEffect('Spike Rush', 500);
						caster.damageUnit(t.unitOnIt, caster.getDamageWithVariation(), PHYSICAL);
					} else {
						t.playEffect('Spike Rush No Particles', 500);
					}
				}
			}
		},
		{	name: 'Throw Muffin Trap',
			description: 'Throws a Muffin Trap. Big Boyo grows if he steps on it.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final targetTile =
					if (percentChance(50)) Battlefield.getRandomAlivePlayerUnit().tileOn
					else Battlefield.getRandomAlivePlayerUnit().tileOn.getRandomEmptyNeighbor();
				if (targetTile == null) return;
				caster.markTileRed(targetTile);
				caster.aiData = { targetTile: targetTile };
				caster.doDownAnimation();
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {

				final randomPlayerUnit = Battlefield.getRandomAlivePlayerUnit();
				if (randomPlayerUnit == null || randomPlayerUnit.tileOn == null) {
					caster.say('Feh...', 2);
					return;
				}
				final targetTile: TileSpace = randomPlayerUnit.tileOn.getRandomEmptyNeighbor(true);
				if (targetTile == null) {
					caster.say('Feh...', 2);
					return;
				}
				Battlefield.pauseNextTurn();
				playAudio('WooshSimpleAudio');
				caster.doDownUpAnimation();
				Effects.sendArcMissileAndThen(
					caster.getCenterPointForMissile(),
					targetTile.getCenterPointForMissile(),
					'Muffin Trap',
					Effects.MEDIUM,
					() -> {
						playAudio('ThrowRockHitAudio');
						if (targetTile.hasUnit()) {
							if (targetTile.unitOnIt.name == 'Big Boyo' || targetTile.unitOnIt.name == 'Big Boyo Wasp') {
								targetTile.unitOnIt.say('OUCH!!!', 2);
							}
							caster.damageUnit(targetTile.unitOnIt, caster.getDamageWithVariation(), DARK);
							return;
						}
						if (!!!targetTile.hasTrap()) {
							final trap = Trap.createFromTemplateByName('Muffin Trap', targetTile);
							trap.customData = { damageDoneOnTrigger: caster.getDamageWithVariation() };
						}					
						Battlefield.resumeNextTurn();
					}
				);
			}
		},
		{	name: "Spit Slime",
			description : "Infects a spell of the target.",
			range : 3,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				target.infectRandomUninfectedSpell();
				caster.damageUnit(target, caster.getDamageWithVariation(), PURE);
			},
			missile : {
				animationName : "Shoot Slime",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Spores",
				duration: 0.5
			},
			audio: {
				onCast: 'SpitSlimeAudio',
				onHit: 'SlimeDeathAudio'
			}
		},
		{	name: 'Spit Web',
			description: 'Spits web somewhere around her.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT' },
			missile: {},
			audio: {
				onCast: 'SpitSlimeAudio'
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final tilesAround = caster.tileOn.getNeighbors().filter(t -> t.hasTrap() == false);
				if (tilesAround.length == 0) return;
				final randomTile1: TileSpace = randomOf(tilesAround);
				final web1 = Battlefield.spawnTrap('Web', randomTile1);
				web1.actor.disableActorDrawing();
				Effects.sendMissileAndThen(caster.tileOn.getCenterPointForMissile(), randomTile1.getCenterPointForMissile(), 'Shoot Slime', Effects.MEDIUM, () -> {
					web1.actor.enableActorDrawing();
				});

				final tilesAround2 = randomTile1.getNeighbors().filter(t -> t.hasTrap() == false);
				if (tilesAround2.length == 0) return;
				final tilesAround2: TileSpace = randomOf(tilesAround2);
				final web2 = Battlefield.spawnTrap('Web', tilesAround2);
				web2.actor.disableActorDrawing();
				Effects.sendMissileAndThen(caster.tileOn.getCenterPointForMissile(), tilesAround2.getCenterPointForMissile(), 'Shoot Slime', Effects.MEDIUM, () -> {
					web2.actor.enableActorDrawing();
				});
			}
		},
		{	name: 'Damage Ally',
			description: 'Damages a child.',
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final big = Battlefield.getUnitByName('Big Boyo');
				final lil = Battlefield.getUnitByName('Lil Munchy');
				if (big == null && lil == null) return;

				final whichUnit = if (lil != null) lil else big;
				caster.say('Die, and be reborn, brother!', 2);
				playAudio('SpitSlimeAudio');
				Effects.sendMissileAndThen(caster.tileOn.getCenterPointForMissile(), whichUnit.tileOn.getCenterPointForMissile(), 'Shoot Slime', Effects.MEDIUM, () -> {
					caster.damageUnit(whichUnit, caster.getDamageWithVariation() * 2, PURE);
				});
			}
		},
		{	name: 'Wasp Flip',
			isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				caster.flipHorizontally();
				playAudio('BigBoyoWaspHitAudio');
			}
		},
		{	name: "Sting Right",
			isDefault: true,
			getPreventTurningTowardsTile: true,
			range : 1,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					right	: true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL),
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: { onCast: 'MeleeAttackAudio' }
		},
		{	name: "Sting Left",
			isDefault: true,
			getPreventTurningTowardsTile: true,
			range : 1,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					left	: true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL),
			missile : {},
			slashEffect: {
				animationName: "SlashForwardBig",
				duration: 0.5
			},
			targetEffect : {
				animationName: "Hit",
				duration: 0.5
			},
			audio: { onCast: 'MeleeAttackAudio' }
		},
		{	name: 'Tidal Wave All',
			description: 'Sends 5 tidal waves!!!',
			range: 7,
			manaCost: 0,
			effect: {
				isDelayed: true,
				type: 'TIDAL_WAVE',
				tidalWaveRows: [0, 1, 2, 3, 4]
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				if (target.name == 'Water Elemental')
					growWaterElemental(target);
				else {
					caster.damageUnit(target, caster.getDamageWithVariation(), COLD);
				}
			},
			missile: {
				animationName: 'Tidal Wave',
				speed: 'MEDIUM'
			},
			targetEffect: {
				animationName: 'Splash',
				duration: 0.5
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'WaterExplosionAudio'
			}
		},
		{	name: 'Tidal Wave Odd',
			description: 'Sends tidal waves on odd rows!!!',
			range: 7,
			manaCost: 0,
			effect: {
				isDelayed: true,
				type: 'TIDAL_WAVE',
				tidalWaveRows: [1, 3]
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				if (target.name == 'Water Elemental')
					growWaterElemental(target);
				else {
					caster.damageUnit(target, caster.getDamageWithVariation(), COLD);
				}
			},
			onMiss: function(caster: Unit, lastTile: TileSpace) {
				if (lastTile.hasNoUnit()) {
					Battlefield.spawnEnemyOnTile('Water Elemental', lastTile);
				}
			},
			missile: {
				animationName: 'Tidal Wave',
				speed: 'MEDIUM'
			},
			targetEffect: {
				animationName: 'Splash',
				duration: 0.5
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'WaterExplosionAudio'
			}
		},
		{	name: 'Tidal Wave Even',
			description: 'Sends tidal waves on even rows!!!',
			range: 7,
			manaCost: 0,
			effect: {
				isDelayed: true,
				type: 'TIDAL_WAVE',
				tidalWaveRows: [0, 2, 4]
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				if (target.name == 'Water Elemental')
					growWaterElemental(target);
				else {
					caster.damageUnit(target, caster.getDamageWithVariation(), COLD);
				}
			},
			missile: {
				animationName: 'Tidal Wave',
				speed: 'MEDIUM'
			},
			targetEffect: {
				animationName: 'Splash',
				duration: 0.5
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'WaterExplosionAudio'
			}
		},
		{	name: 'Switch Stormjr Position',
			description: 'Changes Stormjrs position to the opposite side of the battlefield',
			range: 0,
			manaCost: 0,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT'
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				var anyAvailableTileLeft: TileSpace = null;
				function isAvailable(i: Int, j: Int) return Battlefield.getTile(i, j).hasNoUnit() && Battlefield.getTile(i, j+1).hasNoUnit();
				if (isAvailable(2, 0)) anyAvailableTileLeft = Battlefield.getTile(2, 0);
				else if (isAvailable(1, 0)) anyAvailableTileLeft = Battlefield.getTile(1, 0);
				else if (isAvailable(3, 0)) anyAvailableTileLeft = Battlefield.getTile(3, 0);
				else if (isAvailable(0, 0)) anyAvailableTileLeft = Battlefield.getTile(0, 0);
				else if (isAvailable(4, 0)) anyAvailableTileLeft = Battlefield.getTile(4, 0);
				else									// If it can't switch position
					caster.setSpellSequenceIndex(-1);	// Do the same spells again
				caster.slideToTile(anyAvailableTileLeft);
				caster.flipHorizontally();
				playAudio('StormjrWingsAudio');
			}
		},
		{	name: "Triple Tide",
			description : "Shoot 3 tides in front, up-front and down-front.",
			manaCost: 0,
			range : 6,
			effect : {
				type : "MULTI_SKILL_SHOT",
				directions : {
					upRight		: true,
					right		: true,
					downRight	: true
				}
			},
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageWithVariation(), COLD),
			audio: {
				onCast: 'FoomAudio',
				onHit: 'WaterExplosionAudio'
			},
			missile: {
				animationName: 'Tidal Wave',
				speed: 'MEDIUM'
			},
			targetEffect: {
				animationName: 'Splash',
				duration: 0.5
			}
		},
		{	name: 'Tidal Wave All Reversed',
			description: 'Sends 5 tidal waves!!!',
			range: 7,
			manaCost: 0,
			effect: {
				isDelayed: true,
				type: 'TIDAL_WAVE',
				tidalWaveRows: [0, 1, 2, 3, 4],
				isTidalWaveReversed: true
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				if (target.name == 'Water Elemental')
					growWaterElemental(target);
				else {
					caster.damageUnit(target, caster.getDamageWithVariation(), COLD);
				}
			},
			missile: {
				animationName: 'Tidal Wave',
				speed: 'MEDIUM'
			},
			targetEffect: {
				animationName: 'Splash',
				duration: 0.5
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'WaterExplosionAudio'
			}
		},
		{	name: 'Unswitch Stormjr Position',
			description: 'Changes Stormjrs position to the original side of the battlefield',
			range: 0,
			manaCost: 0,
			isInstant: true,
			effect: {
				type: 'NO_EFFECT'
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				var anyAvailableTileLeft: TileSpace = null;
				function isAvailable(i: Int, j: Int) return Battlefield.getTile(i, j).hasNoUnit() && Battlefield.getTile(i, j+1).hasNoUnit();
				if (isAvailable(2, 5)) anyAvailableTileLeft = Battlefield.getTile(2, 5);
				else if (isAvailable(1, 5)) anyAvailableTileLeft = Battlefield.getTile(1, 5);
				else if (isAvailable(3, 5)) anyAvailableTileLeft = Battlefield.getTile(3, 5);
				else if (isAvailable(0, 5)) anyAvailableTileLeft = Battlefield.getTile(0, 5);
				else if (isAvailable(4, 5)) anyAvailableTileLeft = Battlefield.getTile(4, 5);
				else									// If can't switch position...
					caster.setSpellSequenceIndex(5);	// Do the same spells again
				caster.slideToTile(anyAvailableTileLeft);
				caster.flipHorizontally();
				playAudio('StormjrWingsAudio');
			}
		},
		{	name: 'Fire Arena',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			audio: { onCast: 'FireArenaAudio' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {

				for (i in 0...10) {
					final emptyTile = Battlefield.getRandomTileWithNoTrap();
					if (emptyTile == null) continue;
					final fire = Battlefield.spawnTrap('Fire', emptyTile);
					fire.tileOn.playEffect('Fire Ball');
				}
			}
		},
		{	name: 'Demon Portal',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			audio: { onCast: 'PortalDeathAudio' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final possibleTiles = [
					Battlefield.getTile(2, 1),
					Battlefield.getTile(2, 0),
					Battlefield.getTile(2, 2)
				].filter(t -> t.hasNoUnit());
				if (possibleTiles.length == 0) {
					caster.say('Foolish portals!', 2);
					return;
				}

				final portalTile: TileSpace = randomOf(possibleTiles);
				final portal = Battlefield.spawnEnemyOnTile('Demon Portal', portalTile);
				portal.playEffect('Fire Ball');
				SpecialEffectsFluff.doPortalAnimation(portal.actor);
			}
		},
		{	name: 'Summon Imp',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			audio: { onCast: 'SummonImpAudio' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				Battlefield.pauseNextTurn();
				final spawnLocation = caster.tileOn.getRandomEmptyNeighbor();
                if (spawnLocation == null) {
                    caster.say('* Demon summoning is blocked! *', 2);
                    return;
                }
				caster.playEffect('Flare');
				final imp = Battlefield.spawnEnemyOnTile('Imp', spawnLocation);
				final x = imp.getX();
				final y = imp.getY();
				imp.actor.setXCenter(caster.actor.getXCenter());
				imp.actor.setYCenter(caster.actor.getYCenter());
				imp.actor.moveTo(x, y, 0.5, Easing.expoOut);
				doAfter(750, () -> {
					imp.say('This was not in my contract!');
					doAfter(500, () -> {
						Battlefield.resumeNextTurn();
					});
				});
			}
		},
		{	name: "Crystal Shot",
			range : 5,
			effect : {
				type : "SKILL_SHOT",
				isDelayed: true,
				directions : {
					left	: true,
					up		: true,
					down	: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL);
			},
			onMiss: function(caster: Unit, tile: TileSpace) {
				Battlefield.pauseNextTurn();
				final crystal = Battlefield.spawnEnemyOnTile('Laser Crystal', tile);
				crystal.playEffect('Flare');
				doAfter(500, () -> {
					Battlefield.resumeNextTurn();
				});
			},
			missile : {
				animationName : "Crystal Shot",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Flare",
				duration: 0.5
			},
			audio: {
				onCast: 'CrystalShotCastAudio',
				onHit: 'CrystalShotHitAudio'
			}
		},
		{	name: "Fireball Bolt",
			range : 5,
			effect : {
				type : "SKILL_SHOT",
				isDelayed: true,
				directions : {
					left	: true,
					up		: true,
					upLeft	: true,
					upRight : true,
					down	: true,
					downLeft: true,
					downRight: true
				}
			},
			onTargetedEnemy: function(caster: Unit, target: Unit) {
				SpecialEffectsFluff.doExplosionEffect(target.getXCenter(), target.getYCenter());
				caster.damageUnit(target, caster.getDamageWithVariation(), FIRE);
				for (unit in target.getNeighborUnits(true)) {
					caster.damageUnit(unit, caster.getDamageWithVariation(), FIRE);
				}
			},
			onMiss: function(caster: Unit, tile: TileSpace) {
				SpecialEffectsFluff.doExplosionEffect(tile.getXCenter(), tile.getYCenter());
				for (unit in tile.getNeighborUnits(true)) {
					caster.damageUnit(unit, caster.getDamageWithVariation(), FIRE);
				}
				if (tile.hasTrap() == false) {
					tile.playEffect('Toxic Smoke');
					Battlefield.spawnTrap('Toxic Fog', tile);
				}
			},
			missile : {
				animationName : "Fire Ball",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'FoomAudio',
				onHit: 'FoomAudio'
			}
		},
		{	name: 'Bouncing Flame',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				Battlefield.pauseNextTurn();
				final directionVertical = if (caster.getI() >= 2) UP else DOWN;
				final directionHorizontal = if (caster.getJ() >= 3) LEFT else RIGHT;
				final direction = getDirectionJoined(directionVertical, directionHorizontal);

				function hitUnit(unit: Unit) {
					caster.damageUnit(unit, caster.getDamageWithVariation(), SHOCK);
				}
				function bounce(currentTile: TileSpace, inDirection: Int, andThen: TileSpace -> Int -> Void) {
					var tileIter = currentTile;
					function isNull(d: Int) return tileIter.getNextTileInDirection(d) == null;
					function isFree(d: Int) return tileIter.getNextTileInDirection(d).hasNoUnit();

					while (!isNull(inDirection) && isFree(inDirection)) {
						tileIter = tileIter.getNextTileInDirection(inDirection);
					}

					var unitHit: Unit = null;
					if (!isNull(inDirection) && !isFree(inDirection)) {
						unitHit = tileIter.getNextTileInDirection(inDirection).unitOnIt;
					}

					final possibleDirections = getDiagonalBounceDirectionPriorities(inDirection);
					var newDirection = NO_DIRECTION;

					for (dir in possibleDirections) {
						if (isNull(dir)) continue;
						if (isFree(dir)) {
							newDirection = dir;
							break;
						}
					}

					Effects.sendMissileAndThen(
						currentTile.getCenterPointForMissile(),
						tileIter.getCenterPointForMissile(),
						'Lightning Ball',
						Effects.MEDIUM,
						() -> {
							playAudio('ZapHitAudio');
							if (unitHit != null)
								hitUnit(unitHit);
							else {
								if (tileIter.hasTrap() == false) {
									tileIter.playEffect('Toxic Smoke');
									Battlefield.spawnTrap('Toxic Fog', tileIter);
								}
							}
							if (newDirection != NO_DIRECTION)
								andThen(tileIter, newDirection);
						},
						{
							easingName: 'linear'
						}
					);

					
				}
			
				playAudio('ZapCastAudio');
				bounce(caster.tileOn, direction, (tile2, direction2) -> {
					bounce(tile2, direction2, (tile3, direction3) -> {
						bounce(tile3, direction3, (tile4, direction4) -> {
							Battlefield.resumeNextTurn();
						});
					});
				});
			}
		},
		{	name: 'Lightning Rain (Tyl)',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			audio: { onCast: 'LightningStrikeAudio' },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				Battlefield.tiles.forEach(tile -> {
					tile.addDangerMarker();
					caster.tilesMarkedRed.push(tile);
				});
				caster.say('Storm, spore and fire, heed my call!', 2);
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				playAudio('ZapCastAudio');
				doAfter(150, () -> {
					playAudio('LightningStrikeAudio');
				});
				for (unit in Battlefield.getAllAlivePlayerUnits()) {
					final actor = unit.playEffect('Lightning Strike');
					actor.setY(actor.getY() - 25);
					unit.playEffect('Throw Rock');
					caster.damageUnit(unit, int(caster.getDamageWithVariation() / 2) + caster.customData.ints['lightningDamage'], SHOCK);
				}
				caster.customData.ints['lightningDamage'] = 0;
			}
		},
		{	name: 'Spawn Slimes',
			range: 0, manaCost: 2, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				var nSlimesSpawned = 0;

				function trySpawnSlime(i: Int, j: Int) {
					final tile = Battlefield.getTile(i, j);
					if (tile.hasUnit()) return;
					if (tile.hasTrap('Toxic Fog')) {
						Battlefield.spawnEnemyOnTile('Slime', tile);
						tile.playEffect('Toxic Smoke');
						nSlimesSpawned += 1;
					}
				}
				
				trySpawnSlime(0, 0);
				trySpawnSlime(0, 6);
				trySpawnSlime(4, 0);
				trySpawnSlime(4, 6);

				playAudio('SpawnSlimeAudio');
				if (nSlimesSpawned > 0) {
					caster.say('Rise from the muck!', 2);
				} else {
					Battlefield.pauseNextTurn();
					caster.say('Rise, minions of the toxins!', 2);
					doAfter(3000, () -> {
						final tileToSpawn = caster.tileOn.getRandomEmptyNeighbor();
						Battlefield.spawnEnemyOnTile('Smol Slime', tileToSpawn);
						tileToSpawn.playEffect('Toxic Smoke');
					});
					doAfter(5000, () -> {
						caster.say('A... small slime?', 2);
						doAfter(2500, () -> {
							caster.say('Pff...', 2);
							Battlefield.resumeNextTurn();
						});
					});

				}
			}
		},
		{	name: 'Revive Peasants',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final unitsToRevive = Battlefield.unitsOnBattlefield.filter(u -> u.owner == ENEMY && u.isDead && u.name == 'Peasant');
				trace('Found units to revive: ${unitsToRevive.length}');
				trace('units on b: ${Battlefield.unitsOnBattlefield.map(u -> u.name).join(', ')}');
				var nUnitsRevived = 0;
				for (unit in unitsToRevive) {
					if (unit.tileWhereDied != null && unit.tileWhereDied.hasNoUnit()) {
						unit.revive(unit.tileWhereDied, 999);
					} else {
						final anyAvailableTile = unit.tileWhereDied.getRandomEmptyNeighbor();
						if (anyAvailableTile == null) continue;
						unit.revive(anyAvailableTile);
					}
					U.flashWhite(unit.actor, 750);
					unit.playEffect('Holy Revival', 1300);
					nUnitsRevived += 1;
				}
				if (nUnitsRevived > 0) {
					caster.say('Raise from the dead now!', 2);
					playAudio('UnholyRevivalAudio');
				}
			}
		},
		{	name: 'Holy Cross',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			aiFlags: { isUsableWhileSilenced: false },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final middleCol = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> j == 3 && i != 2);
				final middleRow = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> i == 2 && j!= 3);
				final middleTile = Battlefield.tiles.get(2, 3);
				final allTilesToMark = middleRow.concat(middleCol).concat([middleTile]);
				for (tile in allTilesToMark) {
					tile.addDangerMarker();
				}
				caster.tilesMarkedRed = allTilesToMark;
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final middleCol = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> j == 3 && i != 2);
				final middleRow = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> i == 2 && j != 3);
				final middleTile = Battlefield.tiles.get(2, 3);
				final affectedTiles: Array<TileSpace> = middleRow.concat(middleCol).concat([middleTile]);
				playAudio('HolyImpactAudio');
				for (tile in affectedTiles) {
					tile.playEffect('Holy Cross', 1200);
					if (tile.hasUnit()) {
						if (tile.unitOnIt.owner == PLAYER)
							caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PURE);
						else
							tile.unitOnIt.heal(85);
					}
					if (tile.hasTrap())
						tile.trapOnIt.kill();
				}
			}
		},
		{	name: 'Holy Consecration',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			aiFlags: { isUsableWhileSilenced: false },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final playerTile = randomPlayer.tileOn;
				final nearbyTiles = playerTile.getNeighbors(true);
				final outerTiles: Array<TileSpace> = [];
			
				function tryAddTile(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					outerTiles.push(Battlefield.getTile(i, j));
				}

				final i = playerTile.getI();
				final j = playerTile.getJ();
				tryAddTile(i-1, j+2);
				tryAddTile(i, j+2);
				tryAddTile(i+1, j+2);
				tryAddTile(i+2, j-1);
				tryAddTile(i+2, j);
				tryAddTile(i+2, j+1);
				tryAddTile(i+2, j+2);

				final affectedTiles = [playerTile].concat(nearbyTiles).concat(outerTiles);
				for (t in affectedTiles) {
					t.addDangerMarker();
				}
				caster.aiData = { affectedTiles: affectedTiles };
				caster.tilesMarkedRed = affectedTiles;
				
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				playAudio('HolyConsecrationAudio');
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				for (tile in affectedTiles) {
					tile.playEffect('Consecration', 925);
					if (tile.hasUnit()) {
						if (tile.unitOnIt.owner == PLAYER) {
							caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PURE);
						} else {
							tile.unitOnIt.heal(caster.getDamageWithVariation());
						}
					}
				}
				final emptyTiles = affectedTiles.filter(tile -> tile.hasNoUnitAndTrap()).slice(0, 3);
				for (tile in emptyTiles) {
					Battlefield.spawnTrap('Silence Trap', tile);
				}

			}
		},
		{	name: 'Holy X',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			aiFlags: { isUsableWhileSilenced: false },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final playerTile = randomPlayer.tileOn;
				final markedTiles: Array<TileSpace> = [];

				function tryAddTile(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					markedTiles.push(Battlefield.getTile(i, j));
					Battlefield.getTile(i, j).addDangerMarker();
				}

				final i = playerTile.getI();
				final j = playerTile.getJ();

				tryAddTile(i, j);
				tryAddTile(i+1, j+1);
				tryAddTile(i+2, j+2);
				tryAddTile(i+3, j+3);
				tryAddTile(i-1, j+1);
				tryAddTile(i-2, j+2);
				tryAddTile(i-3, j+3);
				tryAddTile(i+1, j-1);
				tryAddTile(i+2, j-2);
				tryAddTile(i+3, j-3);
				tryAddTile(i-1, j-1);
				tryAddTile(i-2, j-2);
				tryAddTile(i-3, j-3);

				caster.aiData = { affectedTiles: markedTiles };
				caster.tilesMarkedRed = markedTiles;
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				playAudio('HolyImpactAudio');
				for (tile in affectedTiles) {
					tile.playEffect('Holy Cross', 1200);
					if (tile.hasUnit()) {
						if (tile.unitOnIt.owner == PLAYER) {
							caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PURE);
						} else {
							tile.unitOnIt.heal(caster.getDamageWithVariation());
						}
					}
					if (tile.hasTrap()) {
						tile.trapOnIt.kill();
					}
				}
			}
		},
		{	name: 'Dark X',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			aiFlags: { isUsableWhileSilenced: false },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final playerTile = randomPlayer.tileOn;
				final markedTiles: Array<TileSpace> = [];

				function tryAddTile(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					markedTiles.push(Battlefield.getTile(i, j));
					Battlefield.getTile(i, j).addDangerMarker();
				}

				final i = playerTile.getI();
				final j = playerTile.getJ();

				tryAddTile(i, j);
				tryAddTile(i+1, j+1);
				tryAddTile(i+2, j+2);
				tryAddTile(i+3, j+3);
				tryAddTile(i-1, j+1);
				tryAddTile(i-2, j+2);
				tryAddTile(i-3, j+3);
				tryAddTile(i+1, j-1);
				tryAddTile(i+2, j-2);
				tryAddTile(i+3, j-3);
				tryAddTile(i-1, j-1);
				tryAddTile(i-2, j-2);
				tryAddTile(i-3, j-3);

				caster.aiData = { affectedTiles: markedTiles };
				caster.tilesMarkedRed = markedTiles;
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				playAudio('DarkImpactAudio');
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				for (tile in affectedTiles) {
					tile.playEffect('Dark Cross', 1200);
					if (tile.hasUnit()) {
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PURE);
					}
					if (tile.hasTrap()) {
						tile.trapOnIt.kill();
					}
				}
			}
		},
		{	name: 'Dark Consecration',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			aiFlags: { isUsableWhileSilenced: false },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final playerTile = randomPlayer.tileOn;
				final nearbyTiles = playerTile.getNeighbors(true);
				final outerTiles: Array<TileSpace> = [];
			
				function tryAddTile(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					outerTiles.push(Battlefield.getTile(i, j));
				}

				final i = playerTile.getI();
				final j = playerTile.getJ();
				tryAddTile(i-1, j+2);
				tryAddTile(i, j+2);
				tryAddTile(i+1, j+2);
				tryAddTile(i+2, j-1);
				tryAddTile(i+2, j);
				tryAddTile(i+2, j+1);
				tryAddTile(i+2, j+2);

				final affectedTiles = [playerTile].concat(nearbyTiles).concat(outerTiles);
				for (t in affectedTiles) {
					t.addDangerMarker();
				}
				caster.aiData = { affectedTiles: affectedTiles };
				caster.tilesMarkedRed = affectedTiles;
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				playAudio('DarkConsecrationAudio');
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				for (tile in affectedTiles) {
					tile.playEffect('Dark Consecration', 925);
					if (tile.hasUnit()) {
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PURE);
					}
					if (tile.hasTrap() == false)
						Battlefield.spawnTrap('Fire', tile);
				}
			}
		},
		{	name: 'Dark Cross',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			aiFlags: { isUsableWhileSilenced: false },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final randomEnemy = Battlefield.getRandomAlivePlayerUnit();
				if (randomEnemy == null) return;
				final middleCol = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> j == randomEnemy.getJ() && i != randomEnemy.getI());
				final middleRow = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> i == randomEnemy.getI() && j != randomEnemy.getJ());
				final middleTile = Battlefield.tiles.get(randomEnemy.getI(), randomEnemy.getJ());
				final allTilesToMark = middleRow.concat(middleCol).concat([middleTile]);
				for (tile in allTilesToMark) {
					caster.markTileRed(tile);
				}
				caster.aiData = { affectedTiles: allTilesToMark };
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				if (caster.aiData == null || caster.aiData.affectedTiles == null) return;
				playAudio('DarkImpactAudio');
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				for (tile in affectedTiles) {
					tile.playEffect('Dark Cross', 1200);
					if (tile.hasUnit()) {
						caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PURE);
					}
				}
			}
		},
		{	name: 'Order: Throw Spear',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				prepareKingSpears(caster);
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				throwKingSpears(caster);
				playAudio('ThrowSpearAudio');
			}
		},
		{	name: 'Order: Threaten',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final guardTiles: Array<{guard: Unit, affectedTiles: Array<TileSpace>}> = [];
				final tilesMarkedRed: Array<TileSpace> = [];

				final guards = Battlefield.getAllAliveEnemyUnits().filter(u -> u.name == 'Royal Guard Stationary');
				for (guard in guards) {
					if (guard.isDead) continue;
					final leftTile = guard.tileOn.getNextTileInDirection(LEFT);
					if (leftTile == null) continue;
					leftTile.addDangerMarker();
					tilesMarkedRed.push(leftTile);
					final affectedTiles = [leftTile];
					final lefterTile = leftTile.getNextTileInDirection(LEFT);
					if (lefterTile != null) {
						affectedTiles.push(lefterTile);
						lefterTile.addDangerMarker();
						tilesMarkedRed.push(lefterTile);
					}
					guardTiles.push({ guard: guard, affectedTiles: affectedTiles });
				}

				caster.tilesMarkedRed = tilesMarkedRed;
				caster.aiData = { guardTiles: guardTiles };
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final guardTiles: Array<{guard: Unit, affectedTiles: Array<TileSpace>}> = caster.aiData.guardTiles;
				for (i in 0...3) {
					doAfter(randomIntBetween(0, 100), () -> {
						playAudio('MeleeAttackAudio');
					});
				}
				for (guardAndTiles in guardTiles) {
					final affectedTiles: Array<TileSpace> = guardAndTiles.affectedTiles;
					final guard = guardAndTiles.guard;
					if (guard.isDead) continue;
					if (affectedTiles.length == 0) return;
					guard.jot(LEFT);
					final affectedUnits = affectedTiles.filter(t -> t.hasUnit()).map(t -> t.unitOnIt);
					for (u in affectedUnits) {
						guard.damageUnit(u, guard.getDamageWithVariation(), PHYSICAL);
					}
					final fromPoint = guard.tileOn.getCenterPointForMissile();
					final toPoint = new Point(fromPoint);
					toPoint.x -= 80;
					Spell.doGenericSlashEffect(fromPoint, toPoint, 'Thrust', 0.5);
				}
			}
		},
		{	name: 'Order: Advance',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final guards = Battlefield.getAllAliveEnemyUnits().filter(u -> u.name == 'Royal Guard Stationary');
				for (i in 0...3) {
					doAfter(randomIntBetween(0, 100), () -> {
						playAudio('MoveAudio');
					});
				}
				for (guard in guards) {
					guard.slideToTile(guard.tileOn.getNextTileInDirection(LEFT));	// Always possible, since it's checked by the king before it happens
				}
			}
		},
		{	name: 'Throw Spoons',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			onDelayedSetup: function(caster: Unit, _: TileSpace) {
				final playerUnits = Battlefield.getAllAlivePlayerUnits();
				final baseTiles = playerUnits.map(u -> u.tileOn);
				final allSpoonTiles: Array<TileSpace> = [];
				for (tile in baseTiles) {
					allSpoonTiles.push(tile);
					final randomNeigbor1 = tile.getRandomEmptyNeighbor();
					final randomNeigbor2= tile.getRandomEmptyNeighbor();
					if (randomNeigbor1 != null) {
						allSpoonTiles.push(randomNeigbor1);
					}
					if (randomNeigbor2 != null && randomNeigbor1 != randomNeigbor2) {
						allSpoonTiles.push(randomNeigbor2);
					}
				}
				for (tile in allSpoonTiles) {
					tile.addDangerMarker();
				}
				caster.aiData = { affectedTiles: allSpoonTiles };
				caster.tilesMarkedRed = allSpoonTiles;
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				playAudio('ThrowSpoons');
				Battlefield.pauseNextTurn();
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				final from = caster.tileOn.getCenterPointForMissile();
				for (tile in affectedTiles) {
					final to = tile.getCenterPointForMissile();
					Effects.sendArcMissileAndThen(from, to, 'Giant Spoon', Effects.MEDIUM, () -> {
						if (tile.hasUnit()) {
							caster.damageUnit(tile.unitOnIt, caster.getDamageWithVariation(), PHYSICAL);
						}
					});
				}
				doAfter(1000, () -> Battlefield.resumeNextTurn());
			}
		},
		{	name: 'Cheerios',							// Also spanws 2 guards
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				function spawnCheerio(onTile: TileSpace) {
					doAfter(randomIntBetween(0, 300), () -> {
						final cheerio = Battlefield.spawnUnitOnTile('Giant Cheerio', onTile, NEUTRAL);
						cheerio.playEffect('Healing Word', 1200);
						playAudio('CheerioAudio');
					});
				}

				final allPlayerUnits = Battlefield.getAllAlivePlayerUnits();
				var nSummonedCheerios = 0;
				for (unit in allPlayerUnits) {
					final tile: TileSpace = Battlefield.getRandomTileWithNoUnit();
                    if (tile != null) {
                        Battlefield.spawnEnemyFromOutOfScreen('Patrolling Guard', tile.getI(), tile.getJ());
                    }
					final randomTile = unit.tileOn.getRandomEmptyNeighbor(true);
					if (randomTile == null) continue;
					spawnCheerio(randomTile);
					nSummonedCheerios += 1;
					if (nSummonedCheerios == 4) break;
				}

				if (nSummonedCheerios == 4) return;

				for (i in nSummonedCheerios...4) {
					final randomTile = Battlefield.getRandomTileWithNoUnit();
					if (randomTile == null) continue;
					spawnCheerio(randomTile);
				}
			}
		},
		{	name: 'Explode Cheerios',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final cheerios = Battlefield.unitsOnBattlefield.filter(u -> u.isDead == false && u.name == 'Giant Cheerio');
				if (cheerios.length == 0) return;
				for (cheerio in cheerios) {
					final cheerioTile = cheerio.tileOn;
					SpecialEffectsFluff.doExplosionEffect(cheerioTile.getXCenter(), cheerioTile.getYCenter());
					final affectedUnits = cheerioTile.getNeighbors(true).filter(t -> t.hasUnit()).map(t -> t.unitOnIt).filter(u -> u.name != 'Patrolling Guard');
					cheerio.damageUnits(affectedUnits, caster.getDamageWithVariation(), PHYSICAL);
					cheerio.remove();
				}
				shakeScreenShort();
			}
		},
		{	name: 'Sword Barrage Close',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final damage = caster.getDamageWithVariation();
				doSwordBarrage(damage, 1, 3);
				doSwordBarrage(damage, 2, 2);
				doSwordBarrage(damage, 2, 4);
				doSwordBarrage(damage, 3, 3);
				doAfter(150, () -> shakeScreenShort());
			},
			audio: { onCast: 'SwordBarrageAudio' }
		},
		{	name: 'Sword Barrage Medium',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final damage = caster.getDamageWithVariation();
				doSwordBarrage(damage, 0, 3);
				doSwordBarrage(damage, 1, 2);
				doSwordBarrage(damage, 1, 4);
				doSwordBarrage(damage, 2, 1);
				doSwordBarrage(damage, 2, 5);
				doSwordBarrage(damage, 3, 2);
				doSwordBarrage(damage, 3, 4);
				doSwordBarrage(damage, 4, 3);
				doAfter(150, () -> shakeScreenShort());
			},
			audio: { onCast: 'SwordBarrageAudio' }
		},
		{	name: 'Sword Barrage Far',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final damage = caster.getDamageWithVariation();
				doSwordBarrage(damage, 0, 2);
				doSwordBarrage(damage, 1, 1);
				doSwordBarrage(damage, 1, 5);
				doSwordBarrage(damage, 2, 0);
				doSwordBarrage(damage, 2, 6);
				doSwordBarrage(damage, 3, 1);
				doSwordBarrage(damage, 3, 5);
				doSwordBarrage(damage, 4, 2);
				doSwordBarrage(damage, 4, 4);
				doAfter(150, () -> shakeScreenShort());
			},
			audio: { onCast: 'SwordBarrageAudio' }
		},
		{	name: "Red Spectral Sword",
			range : 3,
			effect : {
				type : "SKILL_SHOT_PIERCING",
				isDelayed: true,
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			audio: { onCast: 'EvilMagicWooshAudio' },
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL),
			onMiss: function(caster: Unit, lastTile: TileSpace) {
				if (lastTile.hasUnit()) return;		// Just to be sure, gotta be super super defensive!
				final direction = caster.tileOn.getDirectionToPosition(lastTile.getI(), lastTile.getJ());
				final sword = Battlefield.spawnEnemyOnTile('Red Spectral Sword', lastTile);
				sword.playEffect('Smoke');
				sword.customData.ints['shootDirection'] = getOppositeDirection(direction);
			},
			missile : {
				animationName: 'Spectral Sword Red',
				speed: 'MEDIUM'
			},
		},
		{	name: "Shoot Sword",	// Used by Red Spectral Sword unit
			range : 6,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					up		: true,
					left	: true,
					down	: true,
					right	: true
				}
			},
			audio: { onCast: 'EvilMagicWooshAudio' },
			onTargetedEnemy: (caster, target) -> caster.damageUnit(target, caster.getDamageWithVariation(), PHYSICAL),
			missile : {
				animationName : "Spectral Sword Red",
				speed : "MEDIUM"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			}
		},
		{	name: 'Shoot Sword In Direction',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				Battlefield.pauseNextTurn();
				final direction = caster.customData.ints['shootDirection'];
				trace(' --> Shooting in direction ${directionToString(direction)}');
				final targetTile = caster.tileOn.getNextTileInDirection(direction);
				final shootSwordSpell = caster.getSpell('Shoot Sword');
				caster.actor.disableActorDrawing();
				caster.castSpellAndThen(shootSwordSpell, targetTile, () -> {
					caster.remove();
					Battlefield.resumeNextTurn();
				});				
			}
		},
		{	name: 'Sword Wave',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				Battlefield.pauseNextTurn();
				final waves: Array<{ currentCol: Int, direction: Int }> = caster.aiData.waves;
				final previousWaveDirection: Int = caster.aiData.previousWaveDirection;
				final direction = getOppositeDirection(previousWaveDirection);
				waves.push({
					currentCol: if (direction == RIGHT) 0 else 6,
					direction: direction
				});
				final tiles: Array<TileSpace> = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> j == if (direction == RIGHT) 0 else 6);
				for (tile in tiles) {
					tile.addDangerMarker();
				}
				caster.aiData.previousWaveDirection = direction;
				doAfter(1000, () -> Battlefield.resumeNextTurn());
			}
		},
		{	name: 'Sword Mark',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final priorities = ['Ranger', 'Mage', 'Knight'];
				var target: Unit = null;
				for (name in priorities) {
					target = Battlefield.getUnitByName(name);
					if (target != null && target.isDead == false) break;
				}
				if (target == null) return;
				
				target.addAttachment('Rotating Sword');
				final markedTiles = target.tileOn.getNeighbors(true);
				for (tile in markedTiles) {
					tile.addDangerMarker();
				}

				target.addBuff(new Buff('Sword Mark', 2, {}, {
					onRemove: function(unit: Unit) {
						unit.removeAttachment('Rotating Sword');
						for (tile in unit.tileOn.getNeighbors(true)) {
							tile.removeDangerMarker();
						}
						final damage = caster.getDamageWithVariation();
						final i = unit.getI(), j = unit.getJ();
						doSwordBarrage(damage, i-1, j-1);
						doSwordBarrage(damage, i-1, j);
						doSwordBarrage(damage, i-1, j+1);
						doSwordBarrage(damage, i, j-1);
						doSwordBarrage(damage, i, j+1);
						doSwordBarrage(damage, i+1, j-1);
						doSwordBarrage(damage, i+1, j);
						doSwordBarrage(damage, i+1, j+1);
					}
				}));
				caster.say('You!');
			}
		},
		{	name: 'Summon Spirit',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			audio: { onCast: 'SummonSpiritAudio' },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				final availableSpirits = ['Evil Paprika Spirit', 'Pumpkin Tentacle Spirit', 'Spore Keeper Spirit'];
				final spirit: String = randomOf(availableSpirits);
				final possibleTiles = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> j == 5);
				if (possibleTiles.length == 0) return;
				final randomTile: TileSpace = randomOf(possibleTiles);
				final spiritUnit = Battlefield.spawnEnemyOnTile(spirit, randomTile);
				randomTile.playEffect('Green Smoke');
				caster.say('Aid me, ${spirit}!', 3);
				doAfter(4000, () -> {
					if (spiritUnit.isDead) return;
					if (spirit == 'Evil Paprika Spirit')
						spiritUnit.say('Bleagger bleag!');
					else if (spirit == 'Pumpkin Tentacle Spirit')
						spiritUnit.say('Squiggly squig!');
					else if (spirit == 'Spore Keeper Spirit')
						spiritUnit.say('Fwooshly fwoosh!');
				});
			}
		},
		{	name: 'Move Or Sleep',
			description: 'Move or sleep.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final tiles: Array<TileSpace> = randomPlayer.tileOn.getNeighbors(true);
				caster.aiData = { affectedTiles: tiles };
				for (t in tiles) {
					caster.markTileRed(t);
				}
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				
				if (affectedTiles.length == 0) return;
				final middleTile = affectedTiles[0];
				
				if (caster.name == 'Sandman')
					caster.say('Sleep now!', 2);

				for (tile in affectedTiles) {
					tile.playEffect('Sand');
					if (tile.hasUnit()) {
						tile.unitOnIt.stun();
						caster.damageUnit(tile.unitOnIt, 3, PURE);
					}
				}
			}
		},
		{	name: 'Lights Off',
			description: 'Damages in the shape of a tall box.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				final randomPlayer = Battlefield.getRandomAlivePlayerUnit();
				final affectedTiles: Array<TileSpace> = [];
				function markTileIfExists(i: Int, j: Int) {
					if (Battlefield.tiles.isOutOfBounds(i, j)) return;
					final t = Battlefield.getTile(i, j);
					affectedTiles.push(t);
					caster.markTileRed(t);
				}

				final j = randomPlayer.getJ();
				markTileIfExists(0, j-1);
				markTileIfExists(0, j);
				markTileIfExists(0, j+1);

				markTileIfExists(1, j-1);
				markTileIfExists(1, j+1);
				markTileIfExists(2, j-1);
				markTileIfExists(2, j+1);
				markTileIfExists(3, j-1);
				markTileIfExists(3, j+1);

				markTileIfExists(4, j-1);
				markTileIfExists(4, j);
				markTileIfExists(4, j+1);

				caster.aiData = { affectedTiles: affectedTiles };
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				final affectedTiles: Array<TileSpace> = caster.aiData.affectedTiles;
				
				if (affectedTiles.length == 0) return;
				final middleTile = affectedTiles[0];
				
				if (caster.name == 'Sandman')
					caster.say('Lights out!', 2);

				for (tile in affectedTiles) {
					tile.playEffect('Sand');
					if (tile.hasUnit()) {
						tile.unitOnIt.stun();
						caster.damageUnit(tile.unitOnIt, 3, PURE);
					}
					if (tile.hasTrap() == false) {
						Battlefield.spawnTrap('Sand Pile', tile);
					}
				}
			}
		},
		{	name: 'Simulacrum',
			description: 'Summons a moon that hatches into a player character simulacrum.',
			manaCost: 0,
			range: 1,
			isInstant: true,
			effect: { type: 'NO_EFFECT' },
			missile: {},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit) {
				caster.say('Full moon!!!', 2);
				final tile = Battlefield.getRandomTileWithNoUnit();
				final iceCube = Battlefield.spawnUnitOnTile('Full Moon', tile, ENEMY);
				iceCube.playEffect('Sand');
				SpecialEffectsFluff.doActorDropInAnimation(iceCube.actor, () -> {
					SpecialEffectsFluff.sheenActor(iceCube.actor);
				});
			}
		},
		{	name: 'Iceberg Drop (Enemy)',
			description: 'Drops an iceberg at the start of the next turn, dealing @(165% SP) COLD damage.',
			value: (caster: EntityWithStats, atIndex: Int) -> int(caster.stats.spellPower * 1.65),
			manaCost: 0,
			cooldown: 5,
			range: 5,
			isFreeAction: true,
			effect: { type: 'TILE_IN_RANGE', isDelayed: true },
			missile: {},
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				for (t in tile.getNeighbors(true)) {
					caster.markTileRed(t);
				}
			},
			onTargetedTile: function(caster: Unit, tile: TileSpace) {
				final iceberg = createActor('SpecialEffectActor', 'Units${tile.getI()}');
				iceberg.setAnimation('Iceberg');
				final icebergY = tile.getHypotheticCoordinatesForActor(iceberg).y;
				final icebergX = tile.getHypotheticCoordinatesForActor(iceberg).x;
				iceberg.setY(getScreenY() - iceberg.getHeight());
				iceberg.setX(iceberg.getX());
				iceberg.moveTo(icebergX, icebergY, 0.5, Easing.expoIn);
				playAudio('CrystalShotAudio');
				doAfter(500, () -> {
					playAudio('IcebergDropAudio');
					startShakingScreen(0.01, 0.25);
					final affectedTiles = [tile].concat(tile.getNeighbors(true));
					for (tile in affectedTiles) {
						if (tile.hasUnit()) {
							caster.damageUnit(tile.unitOnIt, int(caster.getSpellPowerWithVariation(COLD) * 1.65), COLD);
						}
					}
					doAfter(1000, () -> {
						iceberg.fadeTo(0, 1, Easing.linear);
						doAfter(1000, () -> {
							recycleActor(iceberg);
						});
					});
				});
			}
		},
		{	name: "Magic Arrow (Enemy)",
			description : "Hurl a magical arrow diagonally for @(100% SP) COLD damage. Deals 50% extra damage to Silenced/Rooted/Stunned units.",
			isDefault: true,
			value: (caster: EntityWithStats, atIndex: Int) -> caster.stats.spellPower,
			manaCost: 0,
			range : 3,
			isFreeAction: true,
			effect : {
				type : "SKILL_SHOT",
				directions : {
					upLeft		: true,
					upRight		: true,
					downLeft	: true,
					downRight	: true
				}
			},
			onTargetedEnemy: (caster, target) -> {
				caster.damageUnit(target, caster.getSpellPowerWithVariation(COLD), COLD);
			},
			missile : {
				animationName : "Magic Arrow",
				speed : "FAST"
			},
			targetEffect: {
				animationName: "Blood",
				duration: 0.5
			},
			audio: {
				onCast: 'MagicArrowAudio',
				onHit: 'ZapHitAudio'
			}
		},
		
		// Hardcoded Monster Actives (these have effects also coded in the game someplace else)
		{	name: "Spore Infection",
			description: "Deals 2 damage, reduces SP and ATK by 2 and infects an ability for the unit.",
			range: 12,
			manaCost: 0,
			effect: {
				type	: "TARGET_IN_RANGE",
				targetInRange : {
					allowSelf : false
				}
			},
			onTargetedEnemy: (caster: Unit, target: Unit) -> {
				caster.damageUnit(target, 2, PURE);
				final infectedSpell = target.infectRandomUninfectedSpell();
				target.playEffect('Toxic Smoke');
			},
			targetEffect : {
				animationName : "Spores",
				duration	: 0.5
			},
			aiFlags: { isUsableWhileSilenced: false },
			audio: {
				onCast: 'SporesAudio'
			}
		},
		{	name: 'Charm',
			description: 'Give +2 Attack to a random monster. Dispelled when attacked.',
			range: 0, 
			manaCost: 1,
			isInstant : true,
			effect: {
				type: 'NO_EFFECT'
			},
			missile: {},
			aiFlags: { isUsableWhileSilenced: false },
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {
				caster.doDownUpAnimation();
				final availableTargets = Battlefield.getAllAliveEnemyUnits().filter(u -> u.hasBuff('Charm') == false && u != caster);
				if (availableTargets.length == 0) return;
				final target: Unit = randomOf(availableTargets);
				if (target.hasAttachment('Charm') == false) {
					target.addAttachment('Charm');
				}
				Effects.playOnlyParticleAt(target.getXCenter(), target.getYCenter(), 'Charm');
				target.scrollRed('+2 DMG');
				target.addBuff(new Buff('Charm', 10, {
					damage: 2,
					spellPower: 2
				}, {
					onRemove: function(self: Unit) {
						if (self.hasAttachment('Charm'))		// Might not have (if the Mermaid died)
							self.removeAttachment('Charm');
					}
				}));
			},
			targetEffect: {},
			audio: {
				onCast: 'CharmAudio'
			}
		},
		

		// Mercenaries and Side Units
		{	name: 'Restore Mana',
			description: "Restore 3 mana to an ally.",
			range: 9,
			manaCost: 3,
			effect		: {
				type	: "ANY_ALLY"
			},
			missile: {},
			onTargetedTile: (caster, tile: TileSpace) -> {
				if (tile == null) throwAndLogError('Null tile given.');
				if (tile.unitOnIt == null) return;
				tile.unitOnIt.replenish(3);
			},
			targetEffect : {
				animationName: "Restore Mana",
				duration: 0.5
			},
			audio: { onCast: 'RestoreManaAudio' }
		},
		{	name: 'Offer Block',
			description: "Give 2 Block to an ally.",
			range: 9,
			manaCost: 3,
			effect		: {
				type	: "ANY_ALLY"
			},
			missile: {},
			onTargetedTile: (caster, tile: TileSpace) -> {
				if (tile == null) throwAndLogError('Null tile given.');
				if (tile.unitOnIt == null) return;
				tile.unitOnIt.replenish(3);
			},
			onTargetedEnemy: (caster: Unit, alsoCaster: Unit) -> {
				caster.addBlock(2);
				caster.updateBars();
			},
			targetEffect: {
				animationName: 'Block',
				duration: 1.5
			},
			audio: { onCast: 'BlockAudio' }
		},
		{	name: 'Push All Away',
			description: 'Push all units around the Effigy up to 2 tiles away.',
			range: 0, 
			manaCost: 3,
			isInstant : true,
			effect: {
				type: 'TARGET_IN_RANGE'
			},
			missile: {},
			audio: { onCast: 'PushAwayAudio' },
			onTargetedEnemy: (caster: Unit, alsoCaster: Unit) -> {
				final casterTile = caster.tileOn;
				if (casterTile == null) throwAndLogError('Null casterTile given.');
				final tileInDirectionHasUnit = direction -> {
					final nextTile = casterTile.getNextTileInDirection(direction);
					if (nextTile == null) return false;
					return nextTile.hasUnit();
				};
				final directionsWithNeighborUnits = Constants.getDirections().filter(tileInDirectionHasUnit);
				for (direction in directionsWithNeighborUnits) {
					casterTile.getNextTileInDirection(direction).unitOnIt.pushInDirection(direction, 2);
				}
			},
			targetEffect: {}
		},
	
		// Other
		{	name: 'SampleNoEffectSpell',
			range: 0, manaCost: 0, isInstant: true,
			effect: { type: 'NO_EFFECT' },
			onDelayedSetup: function(caster: Unit, tile: TileSpace) {
				
			},
			onTargetedEnemy: function(caster: Unit, alsoCaster: Unit): Void {

			}
		},
	];

	static function clearFog(tile: TileSpace) {
		if (tile.hasTrap() && tile.trapOnIt.name == 'Toxic Fog') {
			tile.trapOnIt.kill();
		}
	}
	static function clearFogAllAround(tile: TileSpace) {
		
	}

	public static function growWaterElemental(unit: Unit) {
		unit.growToScale(unit.actorScale + 0.5);
		unit.setMaxHealth(int(unit.stats.health * 1.5));
		unit.stats.damage = int(unit.stats.damage * 1.5);
	}
	static function prepareKingSpears(king: Unit) {
		final guards = Battlefield.getAllAliveEnemyUnits().filter(u -> u.name == 'Royal Guard Stationary');
		final aiDatas: Array<{guard: Unit, tiles: Array<TileSpace>}> = [];
		for (guard in guards) {
			final availableTiles = Battlefield.tiles.filterToArrayIndicesToT((i, j) -> i == guard.getI() && j < guard.getJ());
			if (availableTiles.length == 0) continue;
			final randomTile: TileSpace = randomOf(availableTiles);
			final randomTile2: TileSpace = randomOf(availableTiles);
			final tiles = [randomTile];
			randomTile.addDangerMarker();
			king.tilesMarkedRed.push(randomTile);
			if (randomTile2 != randomTile) {
				randomTile2.addDangerMarker();
				king.tilesMarkedRed.push(randomTile2);
				tiles.push(randomTile2);
			}
			final aiDataObject = { guard: guard, tiles: tiles }
			aiDatas.push(aiDataObject);
		}
		king.aiData = aiDatas;
		king.say('Spears!');
	}
	static function throwKingSpears(king: Unit) {
		Battlefield.pauseNextTurn();

		// Audio
		for (i in 0...3) {
			doAfter(randomIntBetween(0, 100), () -> {
				playAudio('ThrowSpearAudio');
			});
		}

		// Spears
		final aiDatas: Array<{guard: Unit, tiles: Array<TileSpace>}> = king.aiData;
		for (guardAndTiles in aiDatas) {
			final guard = guardAndTiles.guard;
			for (targetTile in guardAndTiles.tiles) {
				final from = guard.tileOn.getCenterPointForMissile();
				final to   = targetTile.getCenterPointForMissile();
				Effects.sendArcMissileAndThen(from, to, 'Spear', Effects.MEDIUM, () -> {
					if (targetTile.hasUnit()) {
						guard.damageUnit(targetTile.unitOnIt, guard.getDamageWithVariation(), PHYSICAL);
					}
				});
			}
		}

		// Resume
		doAfter(1000, () -> {
			Battlefield.resumeNextTurn();
		});
	}
	public static function doSwordBarrageVisuals(sword: Actor, x: Float, y: Float) {
		sword.setXCenter(x);
		sword.setY(y - 95);
		sword.fadeTo(0, 0, Easing.linear);
		// trace('Started sword at ${sword.getY()}');
		doAfter(10, () -> {
			sword.moveTo(sword.getX(), y, 0.25, Easing.linear);
			sword.fadeTo(1, 0.25, Easing.linear);
		});
		doAfter(1000, () -> {
			// trace('Ended sword at ${sword.getY()}');
			sword.fadeTo(0, 0.75, Easing.quadOut);
			doAfter(800, () -> {
				recycleActor(sword);
			});
		});
	}
	public static function doSwordBarrage(damage: Int, i: Int, j: Int) {
		if (Battlefield.tiles.isOutOfBounds(i, j)) return;
		final sword = createActor('OtherParticles', 'Units${i}');
		sword.setAnimation('Spectral Sword');
		final tile = Battlefield.getTile(i, j);
		final x = tile.getXCenter();
		final finalY = tile.getYBottom() - 60 - TileSpace.k.unitFeetSpace;
		doSwordBarrageVisuals(sword, x, finalY);
		tile.flashTargeted();
		doAfter(150, () -> {
			if (tile.hasUnit()) {
				tile.unitOnIt.damage(damage, PURE);
			}
		});
	}
	public static function doHighwaymanGunshotEffectForUnit(unit: Unit) {
		final actor = unit.actor;
		final layer = 'Units${unit.getI()}';
		final isFlipped = unit.isFlippedHorizontally;
		doHighwaymanGunshotEffect(actor, layer, isFlipped);
	}
	public static function doNatasGunshotEffectForUnit(unit: Unit) {
		final actor = unit.actor;
		final layer = 'Units${unit.getI()}';
		final isFlipped = unit.isFlippedHorizontally;
		doNatasGunshotEffect(actor, layer, isFlipped);
	}
	public static function doHighwaymanGunshotEffect(actor: Actor, layer: String, isFlipped: Bool) {
		final gunshot = createActor('OtherParticles', layer);
		final gunshotY = actor.getY() + 16;
		final gunshotX = if (isFlipped == false) actor.getX() - 2 else (actor.getX() + actor.getWidth() - gunshot.getWidth() + 2);
		gunshot.setAnimation('Gunshot');
		gunshot.setX(gunshotX);
		gunshot.setY(gunshotY);
		if (isFlipped) gunshot.growTo(-1, 1, 0);
		doAfter(100, () -> {
			recycleActor(gunshot);
		});
	}
	public static function doNatasGunshotEffect(actor: Actor, layer: String, isFlipped: Bool) {
		final gunshot = createActor('OtherParticles', layer);
		final gunshotY = actor.getY() + 47;
		final gunshotX = if (isFlipped == false) actor.getX() - 1 else (actor.getX() + actor.getWidth() - gunshot.getWidth() + 1);
		gunshot.setAnimation('Gunshot');
		gunshot.setX(gunshotX);
		gunshot.setY(gunshotY);
		if (isFlipped) gunshot.growTo(-1.5, 1.5, 0);
		else gunshot.growTo(1.5, 1.5, 0);
		doAfter(100, () -> {
			recycleActor(gunshot);
		});
	}
	static function chainLightning(fromUnit: Unit, toUnit: Unit) {
		if (fromUnit.isDead || toUnit.isDead) return;
		final lightning = createActor('SpecialEffectActor', 'Particles');
		lightning.setAnimation('Chain Lightning');
		playAudio('ChainLightningAudio');
		stretchActorBetweenPoints(lightning, fromUnit.getXCenter(), fromUnit.getYCenter(), toUnit.getXCenter(), toUnit.getYCenter());
		doAfter(300, () -> {
			recycleActor(lightning);
		});
		toUnit.playEffect('Sparks');
		// caster.damageUnit(toUnit, caster.getDamageWithVariation() + toUnit.block, PURE);
		// unitsAffected.push(toUnit);

		// final toUnitTile = if (toUnit.isDead) toUnit.tileWhereDied else toUnit.tileOn;
		// final extraTargets = toUnitTile.getNeighbors().filter(t -> t.hasUnit()).map(t -> t.unitOnIt).filter(u -> unitsAffected.indexOf(u) == -1);
		// if (extraTargets.length == 0) return;

		// final randomTarget: Unit = randomOf(extraTargets);

		// doAfter(100, () -> {
		// 	chainLightning(toUnit, randomTarget);
		// });
	}
	static function chainFire(fromUnit: Unit, toUnit: Unit) {
		if (fromUnit.isDead || toUnit.isDead) return;
		final lightning = createActor('SpecialEffectActor', 'Particles');
		lightning.setAnimation('Chain Fire');
		playAudio('FoomAudio');
		stretchActorBetweenPoints(lightning, fromUnit.getXCenter(), fromUnit.getYCenter(), toUnit.getXCenter(), toUnit.getYCenter());
		doAfter(300, () -> {
			recycleActor(lightning);
		});
		toUnit.playEffect('Fire Ball');
	}
	public static function doVampireDrain(fromPoint: Point, toPoint: Point) {
        for (i in 0...6) {
            final xOffset = randomIntBetween(-15, 15);
            final yOffset = randomIntBetween(-15, 15);
            final towardsXOffset = if (fromPoint.x < toPoint.x) randomIntBetween(0, 25) else if (fromPoint.x > toPoint.x) randomIntBetween(0, -25) else 0;
            final towardsYOffset = if (fromPoint.y < toPoint.y) randomIntBetween(0, 25) else if (fromPoint.y > toPoint.y) randomIntBetween(0, -25) else 0;
            doAfter(i * 30, () -> {
                final actor = createActor('OtherParticles', 'Particles');
				actor.setAnimation('Blood Point');
                final atX = fromPoint.x + xOffset;
                final atY = fromPoint.y + yOffset;
                actor.setX(atX);
                actor.setY(atY);
                actor.growTo(0.25, 0.25, 0);
                actor.growTo(1.25, 1.25, 0.2, Easing.expoOut);
                actor.moveTo(atX + towardsXOffset, atY + towardsYOffset, 0.2, Easing.expoOut);
                doAfter(200, () -> {
                    actor.growTo(0.1, 0.1, 0.4, Easing.expoOut);
                    actor.moveTo(toPoint.x, toPoint.y, 0.4, Easing.expoOut);
                    doAfter(400, () -> {
                        recycleActor(actor);
                    });
                });
            });
        }
    }
}

class SpellDatabase
{
	
	public static var spellTemplatesByName	: Map<String, SpellTemplate>;
	public static var spellTemplatesById	: Array<SpellTemplate>;
	
	private static var decodeMissileSpeed : Map<String, Int>;
	private static var decodeEffectType   : Map<String, Int>;
	private static var decodeDamageType   : Map<String, Int>;

	public static function get(?id : Int, ?name : String): SpellTemplate {
		if (id != null) {
			if(id < 0 || id > spellTemplatesById.length)
				throwAndLogError('WARNING: No spell with id ${id} found.');
			return spellTemplatesById[id];
		} else {
			if (!spellTemplatesByName.exists(name))
				throwAndLogError('WARNING: No spell with name ${name} found.');
			return spellTemplatesByName[name];
		}
	}


	public static function spellExists(name: String) {
		return spellTemplatesByName.exists(name);
	}

	public static function getTemporaryInstance(name: String): Spell {
		final spellTemplate = get(name);
		return Spell.createFromTemplate(spellTemplate);
	}

	public static function load(){
		trace('Loading Spell Database...');
		spellTemplatesByName = new Map<String, SpellTemplate>();
		spellTemplatesById	 = [];
		var spellTemplates : Array<Dynamic> = null;
		try {
			// spellTemplates = readJSON("Databases/SpellTemplates.json");
			spellTemplates = SpellDatabase_Spells.spells;
		} catch(e : String) {
			trace("ERROR When loading Spells json. Check that the JSON is syntactically correct");
			throw "ERROR";
		}
		//trace('Loaded JSON');
		if (spellTemplates != null) trace("Successfully loaded SpellTemplates.json");
		else trace("ERORR: Failed to load SpellTemplates.json");
		for (s in spellTemplates) {
			var st = SpellTemplate.createFromDynamic(s);
			st.id = spellTemplatesById.length;
			spellTemplatesById.push(st);
			spellTemplatesByName[st.name] = st;
			//trace('Pushed ${s.name}');
		}
		trace('Loaded Spell Database successfully.');
	}
	


	public static function isCharmUsable(caster: Unit) {
		final availableTargets = Battlefield.getAllAliveEnemyUnits().filter(u -> u.hasBuff('Charm') == false && u != caster);
		if (availableTargets.length == 0) return false;
		return true;
	}

	public static function doSwordBarrageVisuals(sword: Actor, x: Float, y: Float) {
		SpellDatabase_Spells.doSwordBarrageVisuals(sword, x, y);
	}

	public static function growWaterElemental(unit: Unit) {
		SpellDatabase_Spells.growWaterElemental(unit);
	}

	public static function exportSpellNamesAndDescriptions() {
		var namesAndDesc: String = '';
		for (spell in spellTemplatesById) {
			namesAndDesc += spell.name + '\n';
			namesAndDesc += spell.description + '\n';
		}
		#if sys
		sys.io.File.saveContent('_SpellNames.txt', namesAndDesc);
		#end

	}
}


















