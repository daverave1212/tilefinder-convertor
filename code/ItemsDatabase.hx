

package scripts;

import U.*;

import scripts.Constants.*;

import com.stencyl.behavior.Script;
import com.stencyl.behavior.Script.*;

import scripts.UnitTemplate.*;

import Math.ceil;
import Math.max;
import Math.min;

import Std.int;


using U;
using StringTools;

/*"
	Json Format:
	{
		"name" 			: "Cobblesword",
		"level" 		: 20,								* Default is 1
		"isStackable" 	: true,								* Default is false
		"nStacks" 		: 5,								* ONLY use if item is stackable
		"isSpell"		: true,								* ONLY if it teaches the player character a new spell
		"icon"			: "Icons/Cobblesword.png",			* Default is "Icons/Default.png"
		"imagePath"		: "Icons/Cobblesword.png",			* Same as above, this or that
		"rarity" 		: 2,								* 1 to 5 (default is 1)
		"price" 		: 200,								* Default is 0
		"stats"			: {
			"health"		    : 20,                       * Optional, default is 0
			"damage"		: 5,                        * Optional, default is 0
			"armor"			    : 5,                        * Optional, default is 0
			"crit"			    : 2,                        * Optional, default is 0
			"dodge"			    : 2,                        * Optional, default is 0
			"initiative"		: 3,                        * Optional, default is 0
			"mana"			: 20,                       * Optional, default is 0
			"manaRegeneration"	: 5,	                    * Optional, default is 0
			"speed"			    : 1,                        * Optional, default is 0
			"spellPower":		: 0							* Optional, default is 0
		},
		"effect"	: {										* Optional, all optional below
			"description"	: "This is shown",
			"healAmount"	: 20
		}
	}
	
	2. Make sure you have the specified image in the Icons folder

	Item Stat Prices:
	1 HP:			10		***
	1 Mana: 		8		**
	1 Damage: 		20		**
	1 Spell Power:	20		**
	1 Armor:		35		**
	1 Magic Res:	20		**
	1 Crit:			15		**
	1 Dodge:		15		*
	1 Initiative: 	20		*
	1 Speed:		75	
	10 Resistance:	40
	10 Amplification: 80

	

	Classify items as:
	- Tank
	- Mage
	- DPS
	- A combination of the 2

"*/

class ItemsDatabase_Items {
	public static var gear: Array<Dynamic> = [
		// Level 0 (25g)
		{	name: 'Clean Underwear',			// [Mage]
			tags: [TRINKET, CLOTH, METAL],
			level: 0,
			imagePath: 'Icons/Underwear.png',
			rarity: 1,
			price: 25,
			stats: {
				spellPower: 1,
			},
			flavor: 'Smells like linden and lavander. Unlike your current underwear...'
		},
		{	name: 'Rotten Boot',				// [Tank]
			level: 0,
			tags: [TRINKET, METAL],
			imagePath: 'Icons/RottenBoot.png',
			rarity: 1,
			price: 20,
			stats: {
				health: 2,
			},
			flavor: 'If it loses its durability, you can still eat it for its proteic mold!'
		},
		{	name: 'Oopsie',
			level: 0,
			imagePath: 'Icons/Oopsie.png',
			rarity: 2,
			price: 40,
			stats: {
				health: 3
			},
			flavor: 'Oops! This item does not exist... Here, have +1 Health and please report this as a bug. Thank you!'
		},

		// Level 1 (50g)
		{	name: "Three Leaf Clover",			// [DPS]
			level: 1,
			tags: [TRINKET, PLANT],
			imagePath: "Icons/ThreeLeafClover.png",
			rarity: 2,
			price: 45,
			stats: {
				crit: 5
			},
			flavor: "Have you noticed people only ever find 4-leaf clovers? The 3-leaf ones must be so rare!"
		},
		{	name: "Lucky Coin",					// [Other]
			level: 1,
			rarity: RARE,
			tags: [TRINKET, METAL],
			imagePath: "Icons/LuckyCoin.png",
			price: 45,
			stats: {
				dodge: 4
			},
			flavor: "If equipped, provides a chance of finding 10 extra gold after every battle."
		},
		{	name: "Dirty Shirt",				// [Tank]
			level: 1,
			tags: [METAL, CLOTH],
			imagePath: "Icons/DirtyShirt.png",
			price: 38,
			stats: {
				health: 3
			},
			flavor: "The stains protect you from damage and from finding a partner."
		},
		{	name: "1 Leg Armor",				// [Tank]
			level: 1,
			tags: [METAL, CLOTH],
			imagePath: "Icons/LegArmor.png",
			price: 48,
			stats: {
				health: 2,
				armor: 5
			},
			flavor: "Still can't wear 2 of these. Rules are rules."
		},
		{	name: "Socks",						// [Tank]
			level: 1,
			rarity: RARE,
			tags: [TRINKET, METAL, CLOTH],
			imagePath: "Icons/Socks.png",
			price: 70,
			stats: {
				dodge: 7
			},
			flavor: "There's a reason everyone wears them."
		},
		{	name: "Cheap Mage Hat",				// [Mage]
			level: 1,
			tags: [TRINKET, CLOTH],
			imagePath: "Icons/CheapMageHat.png",
			price: 40,
			stats: {
				mana: 2
			},
			flavor: "Made by a cheap mage."
		},	
		{	name: "Shivery Shiv",				// [DPS]
			level: 1,
			tags: [METAL, WEAPON],
			imagePath: "Icons/ShiveryShiv.png",
			price: 35,
			stats: {
				damage: 1
			},
			flavor: "Brings your enemies hot-cold flashes."
		},
		{	name: "Regular Goat Horn",			// [DPS]
			level: 1,
			rarity: RARE,
			tags: [TRINKET, METAL],
			imagePath: "Icons/RegularGoatHorn.png",
			price: 45,
			stats: {
				damage: 3,
				health: -4
			},
			flavor: "We all have one."
		},
		{	name: "Bit of Coal",				// [Mage]
			level: 1,
			tags: [TRINKET, METAL, ORE],
			imagePath: "Icons/BitOfCoal.png",
			price: 55,
			stats: {
				spellPower: 1
			},
			flavor: "Has a 0.1% chance to increase your fire damage taken by 1000%."
		},
		{	name: 'Spoooky Wand',				// [Mage]
			appearCondition: () -> Player.progression.defeatedSpatula2,
			level: 1,
			rarity: EPIC,
			tags: [TRINKET, MAGICAL],
			imagePath: 'Icons/SpoookyWand.png',
			price: 80,
			stats: {
				manaRegeneration: 2,
			},
			flavor: "Hey there, bootiful! Let's have some boos and spook up tonight!",
		},
		{	name: 'Small Amulet',				// [Mage]
			level: 1,
			rarity: RARE,
			tags: [TRINKET, MAGICAL],
			imagePath: 'Icons/SmallAmulet.png',
			price: 40,
			stats: {
				manaRegeneration: 1,
			},
			flavor: "SMALLER MULLET!!!",
		},

		{	name: 'Holy Candle',
			level: 1,
			rarity: ARTIFACT,
			tags: [TRINKET, MAGICAL],
			imagePath: "Icons/HolyCandle.png",
			price: 100,
			stats: {},
			flavor: 'Increases all your damage by 10% and makes you immune to Silence.',
			onCombatStart: function(unit: Unit) {
				unit.damageDoneMultiplier += 0.1;
				unit.isImmuneToSilence = true;
			}
		},
		{	name: 'Poaching Dagger',
			level: 1,
			rarity: ARTIFACT,
			tags: [TRINKET, METAL, WEAPON],
			imagePath: 'Icons/PoachingDagger.png',
			price: 75,
			stats: {},
			flavor: 'Gain 2-4 gold for every killed enemy.',
			onCombatStart: function(self: Unit) {
				Battlefield.addAfterUnitTakingDamageEvent(function(source: Unit, target: Unit, amount: Int, type: Int) {
					if (self == source && target.isDead && target.owner == ENEMY) {
						final tileWhereDied = target.tileWhereDied;
						if (tileWhereDied == null) return;
						final nGolds = randomIntBetween(2, 4);
						Player.giveGold(nGolds);
						trace('GOLDING YES ${nGolds} GOLDS!');
						for (i in 1...nGolds + 1) {
							doAfter(i * 100, () -> {
								playAudio('CoinAudio');
								SpecialEffectsFluff.doItemToInventoryAnimation('Images/Other/Coin.png', tileWhereDied.getXCenter(), tileWhereDied.getYCenter(), false);
							});
						}
					} else {
						trace('No gold now');
					}
				});
			}
		},
		{	name: 'Rancid Slime',
			level: 1,
			rarity: ARTIFACT,
			tags: [TRINKET, METAL, WEAPON],
			imagePath: 'Icons/RancidSlime.png',
			price: 55,
			stats: {},
			flavor: 'When killing a plant, 33% chance to evolve this item into something beautiful. Mushrooms are plants.',
			onCombatStart: function(self: Unit) {
				var didEvolveSlime = false;
				Battlefield.addAfterUnitTakingDamageEvent(function(source: Unit, target: Unit, amount: Int, type: Int) {
					if (self == source && target.isDead && target.owner == ENEMY) {
						final tileWhereDied = target.tileWhereDied;
						if (tileWhereDied == null) return;
						if (target.hasTag(ENEMY_PLANT) == false) return;
						if (percentChance(60)) return;
						if (self.playerCharacter == null) return; 	// Not sure how this is possible
						if (didEvolveSlime) return;
						didEvolveSlime = true;
						self.playEffect('Toxic Smoke');
						self.scrollGreen('Evolved Slime!');
						self.playerCharacter.removeItem('Rancid Slime');
						self.playerCharacter.equipItemStandalone('Something Beautiful');
						self.stats.damage += 3;
						self.stats.spellPower += 3;
						self.stats.mana += 2;
						self.setMaxHealth(self.stats.health + 4);
					}
				});
			}
		},
		{	name: 'Something Beautiful',
			level: 1,
			rarity: ARTIFACT,
			tags: [SPECIAL_ITEM, MAGICAL, PLANT],
			imagePath: 'Icons/SomethingBeautiful.png',
			stats: {
				health: 4,
				mana: 2,
				damage: 3,
				spellPower: 3
			},
			price: 165,
			flavor: 'Such pretty colors... must... look at it...'
		},

		// Level 2 (100g)
		{	name: 'Witch Ladle',
			level: 2,
			tags: [TRINKET, WEAPON],
			imagePath: 'Icons/WitchLadle.png',
			price: 135,
			amplifications: {
				dark: 0.25
			},
			flavor: 'Amplifies your DARK damage by 25%.'
		},
		{	name: 'Studded Leather',			// [Tank]
			level: 2,
			imagePath: 'Icons/StuddedLeather.png',
			stats: {
				health: 4
			},
			resistances: {
				shock: -0.15
			},
			price: 100,
			flavor: 'Reduces SHOCK damage taken by 15%.'
		},
		{	name: "Holey Shield",				// [Tank]
			level: 2,
			tags: [METAL],
			imagePath: "Icons/HoleyShield.png",
			price: 90,
			stats: {
				manaRegeneration: 1,
				health: 3
			},
			flavor: "All its holy areas have been broken by arrows."
		},
		{	name: "Thug Tunic",					// [Tank]
			level: 2,
			tags: [METAL],
			imagePath: "Icons/ThugTunic.png",
			price: 130,
			stats: {
				dodge: 10,
			},
			flavor: "Makes your victims spot you from 10 meters away."
		},
		{	name: "Head Bucket",				// [Tank]
			level: 2,
			tags: [METAL],
			imagePath: "Icons/HeadBucket.png",
			price: 105,
			stats: {
				armor: 15
			},
			flavor: "Carries 80 to 85% water!"
		},
		{	name: 'Froggo Leg',					// [Tank]
			imagePath: 'Icons/FroggoLeg.png',
			level: 2,
			tags: [TRINKET],
			price: 100,
			resistances: {
				cold: -0.25
			},
			flavor: 'Gives 25% resistance to COLD damage.'
		},
		{	name: 'Ruby',						// [Tank]
			rarity: RARE,
			imagePath: 'Icons/Ruby.png',
			level: 2,
			tags: [TRINKET, ORE],
			price: 179,
			resistances: {
				fire: -0.25
			},
			flavor: 'Reduces FIRE damage taken by 25%.'
		},
		{	name: 'Transylvanian Pants',			// [Tank]
			level: 2,
			tags: [CLOTH],
			imagePath: 'Icons/AntigypsyPants.png',
			price: 100,
			resistances: {
				dark: -0.25
			},
			flavor: 'Reduces DARK damage taken by 25% and protects you from Romanians.'
		},
		{	name: "Hunter Hatchet",				// [DPS]
			level: 2,
			tags: [METAL, WEAPON],
			imagePath: "Icons/HunterHatchet.png",
			price: 95,
			stats: {
				damage: 3,
				crit: 5
			},
			flavor: "Melee survival hunters!?"
		},
		{	name: "Speedcritter",				// [DPS]
			level: 2,
			tags: [METAL, WEAPON],
			imagePath: "Icons/Speedcritter.png",
			price: 95,
			stats: {
				speed: 1,
				crit: 10
			},
			flavor: "Small bits, big crits."
		},
		{	name: "Blight Arrow",				// [DPS/Mage]
			level: 2,
			rarity: RARE,
			tags: [METAL, WEAPON, MAGICAL, TRINKET],
			imagePath: "Icons/BlightArrow.png",
			price: 115,
			stats: {
				damage: 2,
				spellPower: 2
			},
			amplifications: {
				shock: -0.5
			},
			flavor: "Reduces your SHOCK damage done by 50%."
		},
		{	name: 'Torch',						// [DPS/Mage]
			rarity: RARE,
			level: 2,
			tags: [TRINKET, WEAPON],
			imagePath: 'Icons/Torch.png',
			price: 160,
			amplifications: {
				fire: 0.2
			},
			flavor: 'Amplifies your FIRE damage by 20%.'
		},
		{	name: "Jade",						// [Mage]
			level: 2,
			rarity: RARE,
			tags: [TRINKET, ORE],
			imagePath: "Icons/Jade.png",
			price: 193,
			stats: {
				spellPower: 2
			},
			flavor: "This item sells for way more gold than it should!"
		},
		{	name: 'Cold Shortstaff',			// [Mage]
			level: 2,
			tags: [TRINKET, WEAPON, PLANT],
			imagePath: 'Icons/ColdShortstaff.png',
			price: 150,
			stats: {
				spellPower: 2
			},
			amplifications: {
				cold: 0.15
			},
			flavor: 'Amplifies your COLD damage by 15%.'
		},

		{	name: "Branch of Gore",				// [DPS]
			level: 2,
			rarity: EPIC,
			tags: [TRINKET, WEAPON],
			imagePath: "Icons/BranchOfGore.png",
			price: 95,
			stats: {
				damage: 4,
				crit: 10,
				spellPower: -4
			},
			flavor: "KING BARBARUS WAS IN SEARCH OF GUTS AND BLOOD AND GORE"
		},
		{	name: "Branch of Lore",				// [Mage]
			level: 2,
			rarity: EPIC,
			tags: [TRINKET, MAGICAL],
			imagePath: "Icons/BranchofLore.png",
			price: 95,
			stats: {
				mana: 4
			},
			flavor: "In the year 208 of the second era, king Barbarus the Plagued invaded the docile lands of Kaliria in search of a..."
		},
		{	name: "Nana Necklace",				// [Mage]
			appearCondition: () -> Player.progression.defeatedKingOrMarceline,
			level: 2,
			rarity: EPIC,
			tags: [TRINKET, ORE, MAGIC],
			imagePath: "Icons/NanaNecklace.png",
			price: 155,
			stats: {
				spellPower: 4
			},
			flavor: "E voice echoes 'She must never know...'"
		},
		{	name: 'Cranedrainer',				// [Mage]
			rarity: ARTIFACT,
			level: 3,
			tags: [ARMOR, TRINKET, MAGICAL],
			imagePath: 'Icons/Cranedrainer.png',
			price: 200,
			stats: {
				mana: 3
			},
			flavor: 'For each 25 Mana spent during combat, permanently gain 1 maximum Mana.',
			onCombatStart: function(self: Unit) {
				self.customData.ints['totalManaSpent'] = 0;
				Battlefield.addAfterUnitCastSpellEvent(function(unit: Unit, spell: Spell, targetTile: TileSpace) {
					if (unit != self) return;
					self.customData.ints['totalManaSpent'] += spell.getManaCost();
					if (self.customData.ints['totalManaSpent'] >= 25) {
						self.customData.ints['totalManaSpent'] -= 25;
						self.stats.mana += 1;
						self.updateBars();
						if (self.playerCharacter == null) {
							Game.q('ID: Huh? How is self ${self.name} playerCharacter null??');
							return;
						}
						self.playerCharacter.stats.mana += 1;
					}
				});
			}
		},
		{	name: "Traveler Boots",				// [Other]
			level: 2,
			rarity: EPIC,
			tags: [TRINKET, METAL],
			imagePath: "Icons/TravelerBoots.png",
			price: 105,
			stats: {
				dodge: 5,
				speed: 1
			},
			flavor: "Quite elastic. You know, for traveling!"
		},

		{	name: 'Primal Necklace',			// [Other]
			level: 2,
			rarity: ARTIFACT,
			tags: [TRINKET],
			imagePath: 'Icons/PrimalNecklace.png',
			price: 155,
			stats: {
				dodge: 10
			},
			flavor: 'After every combat, gain some random stats (1 DMG/SP, 5% ARM, 1 HP, 3 CRIT/DODGE, etc).',
			onCombatEnd: function(unit: Unit) {
				final statGain = [
					'health' => 1,
					'mana' => 1,
					'spellPower' => 1,
					'damage' => 1,
					'dodge' => 3,
					'crit' => 3,
					'armor' => 5
				];
				final randomStat: String = randomOf([for (elem in statGain.keys()) elem]);	// Because keys() is an iterator, not an array
				unit.playerCharacter.stats.addStat(randomStat, statGain[randomStat]);
			}
		},
		{	name: "Skankbang",					// [DPS]
			appearCondition: () -> Player.progression.defeatedCaptainStashton,
			level: 2,
			rarity: ARTIFACT,
			tags: [METAL, WEAPON, TRINKET],
			imagePath: "Icons/Skankbang.png",
			price: 125,
			stats: {
				damage: 4
			},
			flavor: "Increases your damage done against HUMANS and HALF-HUMANS by 25%. Easy skankin'...",
			onCombatStart: function(unit: Unit) {
				unit.addDamageUnitModificationEvent(function(target: Unit, amount: Int): Int {
					if (target == null) return amount;
					if (target.isDead) return amount;
					if (target.hasTag(HUMAN) == false) return amount;
					return int(1.25 * amount);
				});
			}
		},
		{	name: "Dragon Claw",				// [Mage]
			appearCondition: () -> Player.progression.defeatedStormjr,
			level: 2,
			rarity: ARTIFACT,
			tags: [METAL, WEAPON, TRINKET],
			imagePath: "Icons/DragonClaw.png",
			price: 135,
			stats: {
				spellPower: 4
			},
			flavor: "Increases your damage done against ANIMALS by 25%. Slimes are animals too.",
			onCombatStart: function(unit: Unit) {
				unit.addDamageUnitModificationEvent(function(target: Unit, amount: Int): Int {
					if (target == null) return amount;
					if (target.isDead) return amount;
					if (target.hasTag(ANIMAL) == false) return amount;
					return int(1.25 * amount);
				});
			}
		},

		// Level 3 (120g)
		{	name: "Rodan's Ring",			// [Mage]
			rarity: RARE,
			level: 3,
			tags: [TRINKET, METAL],
			imagePath: "Icons/RodanRing.png",
			price: 130,
			stats: {
				health: 4,
				spellPower: 2,
				mana: 2
			},
			flavor: "Statistically the most purchased item in the game."
		}, 
		{	name: "Arcane Focus",			// [Mage]
			level: 3,
			tags: [TRINKET, METAL, WEAPON],
			imagePath: "Icons/ArcaneFocus.png",
			price: 135,
			stats: {
				spellPower: 2,
				manaRegeneration: 1,
				mana: 1
			},
			flavor: "You don't need to sacrifice crickets to summon plants or something like that."
		},
		{	name: 'Staff of Staffness',		// [Mage]
			level: 3,
			tags: [PLANT, MAGICAL, TRINKET],
			imagePath: 'Icons/StaffOfStaffness.png',
			price: 155,
			stats: {
				spellPower: 3,
				crit: 10
			},
			flavor: "Requires 10 years of experience to use. Juniors only."
		},
		{	name: 'Leafy',					// [Mage]
			level: 3,
			tags: [PLANT, MAGICAL, TRINKET],
			imagePath: 'Icons/Leafy.png',
			price: 155,
			stats: {
				spellPower: 4
			},
			flavor: "Makes you immune to being ROOTED."
		},
		{	name: "Ok Shield",				// [Tank]
			level: 3,
			tags: [METAL, ARMOR],
			imagePath: "Icons/OkShield.png",
			price: 120,
			stats: {
				armor: 15,
				health: 4
			},
			flavor: "This shield is quite ok."
		},
		{	name: "Shoulderblade",			// [Tank]
			level: 3,
			tags: [METAL, ARMOR],
			imagePath: "Icons/Shoulderblade.png",
			price: 135,
			stats: {
				damage: -2,
				health: 9
			},
			flavor: "The blade is so dull, it makes your other blades weaker as well."
		},
		{	name: "Ball And Chain",			// [Tank]
			level: 3,
			tags: [METAL, ARMOR, WEAPON],
			imagePath: "Icons/BallAndChain.png",
			price: 175,
			stats: {
				armor: 35,
				dodge: -15,
				speed: -1,
				damage: 1
			},
			flavor: "Rock stone was my pillow :("
		},
		{	name: "Light Bow",				// [DPS]
			level: 3,
			tags: [METAL],
			imagePath: "Icons/LightBow.png",
			price: 140,
			stats: {
				damage: 4,
				dodge: 5
			},
			flavor: 'Not to be confused with Bow of Light, which increases damage done by 18.'
		},
		{	name: "Fish Knife",				// [DPS]
			level: 3,
			tags: [METAL, WEAPON],
			imagePath: "Icons/FishKnife.png",
			price: 195,
			stats: {
				crit: 5,
				dodge: 5,
				damage: 2
			},
			flavor: 'Commonly used by Fishmen (you will encounter them on the beaches).'
		},
		{	name: "RPG Sword",				// [DPS/Mage]
			level: 3,
			tags: [METAL, WEAPON],
			imagePath: "Icons/RPGSword.png",
			price: 195,
			stats: {
				manaRegen: 2,
				damage: 2
			},
			flavor: 'Its stats are basic AF.'
		},
		{	name: 'Eldritch Shrimp',		// [DPS/Mage]
			rarity: EPIC,
			level: 3,
			tags: [TRINKET, MAGICAL],
			imagePath: 'Icons/EldritchShrimp.png',
			price: 200,
			stats: {},
			flavor: 'Every combat, randomly gain 35% of your DODGE as SP or DAMAGE.',
			onCombatStart: function(unit: Unit) {
				if (percentChance(50)) {
					unit.stats.spellPower += int(unit.stats.dodge * 0.35);
				} else {
					unit.stats.damage += int(unit.stats.dodge * 0.35);
				}
			}
		},
		{	name: "Cute Spear",				// [DPS]
			level: 3,
			tags: [METAL, WEAPON],
			imagePath: "Icons/CuteSpear.png",
			price: 155,
			stats: {
				armor: -25,
				damage: 5
			},
			flavor: 'UwU'
		},
		{	name: "Summer Dress",			// [Other]
			level: 3,
			tags: [TRINKET, CLOTH],
			imagePath: "Icons/SummerDress.png",
			price: 175,
			stats: {
				manaRegeneration: 1,
				crit: 10,
				speed: 1
			},
			flavor: 'The pattern makes you wonder what the true color of the dress is.'
		},
		{	name: 'Brass Wrench',			// [Other]
			imagePath: 'Icons/BrassWrench.png',
			level: 3,
			tags: [METAL],
			price: 200,
			resistances: {
				fire: -0.25
			},
			flavor: 'Amplifies your SHOCK damage by 25%.'
		},
		{	name: "Mason Gloves",			// [Other]
			level: 3,
			tags: [TRINKET, METAL, CLOTH],
			imagePath: "Icons/MasonGloves.png",
			price: 115,
			stats: {
				armor: 10,
				mana: 3
			},
			flavor: 'This is a secret item. Shh...'
		},
		{	name: 'Pearl Ring',				// [Other]
			appearCondition: () -> Player.progression.defeatedStormjr,
			rarity: RARE,
			level: 3,
			tags: [TRINKET, METAL, ORE],
			imagePath: 'Icons/PearlRing.png',
			price: 200,
			amplifications: {
				cold: 0.25
			},
			flavor: 'Amplifies your COLD damage by 25%.'
		},

		{	name: 'Mirror of Ice',			// [Tank]
			rarity: EPIC,
			level: 3,
			tags: [METAL, TRINKET],
			imagePath: 'Icons/MirrorofIce.png',
			price: 200,
			stats: {
				armor: 20,
				manaRegeneration: 2
			},
			resistances: {
				cold: -0.3
			},
			flavor: 'Reduces COLD damage taken by 30%.'
		},
		{	name: "Devilish Helm",			// [Tank]
			appearCondition: () -> Player.progression.defeatedNatas,
			level: 3,
			rarity: EPIC,
			tags: [METAL, ARMOR],
			imagePath: "Icons/DevilishHelm.png",
			price: 160,
			stats: {
				armor: 16,
				dodge: 16
			},
			flavor: "YOU FACE NATAS, DEMON LORD OF THE BURNING REGION!!!"
		},
		{	name: "Very Lucky Coin",		// [Other]
			level: 3,
			tags: [TRINKET, METAL],
			imagePath: "Icons/VeryLuckyCoin.png",
			rarity: 2,
			price: 138,
			stats: {
				dodge: 12
			},
			flavor: "If equipped, provides a chance of finding 50 extra gold after every battle."
		},
		{	name: 'Vampire Jordans',		// [Other]
			appearCondition: () -> Player.progression.defeatedSpatula1,
			rarity: ARTIFACT,
			level: 3,
			tags: [METAL, WEAPON],
			imagePath: 'Icons/VampireVelcros.png',
			price: 200,
			stats: {
				mana: 5,
				dodge: 15
			},
			flavor: "Tip-toe-ing in one's jawdins... What on earth does that even mean?"
		},
		{	name: 'Pocket Bug',				// [Mage]
			appearCondition: () -> Player.progression.defeatedBlessedChildren,
			rarity: EPIC,
			level: 3,
			tags: [TRINKET, MAGICAL, PLANT],
			imagePath: 'Icons/PocketBug.png',
			price: 200,
			stats: {},
			flavor: 'At the end of every turn, gain +1 Spell Power.',
			onCombatStart: function(unit: Unit) {
				Battlefield.addOnRoundEndEvent(function(roundNumber: Int) {
					if (unit.isDead) return;
					unit.stats.spellPower += 1;
					unit.scrollBlue('+1 SP');
				});
			}
		},
		{	name: 'Helm of Evolution',		// [Other]
			level: 3,
			rarity: ARTIFACT,
			tags: [METAL, MAGICAL],
			imagePath: 'Icons/HelmOfEvolution.png',
			price: 195,
			flavor: 'After every combat, improve the regular stats of a random equipped item by up to 20%.',
			onCombatEnd: function(unit: Unit) {
				final items = unit.playerCharacter.getEquippedItems().filter(i -> i.name != 'Helm of Evolution' && i.getNumberOfNonZeroStats() > 0);
				if (items.length == 0) return;
				final item: Item = randomOf(items);
				unit.playerCharacter.subtractItemStats(item);
				item.improveQuality(1.2);
				unit.playerCharacter.addItemStats(item);
			}
		},
		{	name: "Pumpkin Armor",			// [Other]
			appearCondition: () -> Player.progression.defeatedPumpzilla,
			level: 3,
			rarity: ARTIFACT,
			tags: [TRINKET, METAL, CLOTH],
			imagePath: "Icons/PumpkinArmor.png",
			price: 115,
			stats: {
				armor: 20,
				mana: 5,
			},
			flavor: 'Carved from the innards of the pumpkin matriarch. It\'s still slimy.'
		},
		{	name: 'The Magnetizer',			// [Tank]
			appearCondition: () -> Player.progression.defeatedSpatula1,
			rarity: EPIC,
			level: 3,
			tags: [METAL, WEAPON],
			imagePath: 'Icons/TheMagnetizer.png',
			price: 200,
			stats: {
				armor: 10
			},
			flavor: 'Gain Mana Regeneration equal to 10% of your ARMOR.',
			onCombatStart: function(unit: Unit) {
				unit.stats.manaRegeneration += int(unit.stats.armor * 0.1);
			}
		},
		{	name: 'Shadowblade',			// [Mage + Tank]
			appearCondition: () -> Player.progression.defeatedSpatula1,
			rarity: ARTIFACT,
			level: 3,
			tags: [METAL, WEAPON],
			imagePath: 'Icons/Shadowblade.png',
			price: 200,
			stats: {},
			flavor: 'During combat, you have extra SP equal to 25% of your total HP, but your ARMOR is always 0.',
			onCombatStart: function(unit: Unit) {
				unit.stats.spellPower += int(unit.stats.health * 0.25);
			}
		},

		// Level 4 (250g)
		{	name: 'Hook and String',		// [DPS]
			imagePath: 'Icons/HookandRope.png',
			tags: [TRINKET, METAL, WEAPON],
			level: 4,
			price: 215,
			stats: {
				damage: 3,
				speed: 1,
				crit: 10
			},
			flavor: 'Some people call this a Chorus and Chord.'
		},		
		{	name: 'Axe Edge',				// [DPS]
			imagePath: 'Icons/AxeEdge.png',
			tags: [TRINKET, METAL, WEAPON],
			level: 4,
			price: 205,
			stats: {
				crit: 20
			},
			flavor: 'Smells like deodorant.'
		},
		{	name: 'Swingstabber',			// [DPS/Tank]
			tags: [WEAPON, TRINKET, METAL],
			imagePath: 'Icons/Swingstabber.png',
			level: 4,
			price: 160,
			stats: {
				armor: 15,
				damage: 4
			},
			flavor: 'That protrusion is actually an AK-47 metal magazine.'
		},
		{	name: 'Magic Antiglaive',		// [Mage]
			tags: [WEAPON, TRINKET, METAL],
			imagePath: 'Icons/MagicAntiglaive.png',
			level: 4,
			price: 185,
			stats: {
				spellPower: 5,
				manaRegeneration: 2,
				damage: -5
			},
			flavor: 'Ha ha Spell Power go brrrrr'
		},
		{	name: 'Sunken Ring',			// [Mage]
			imagePath: 'Icons/SunkenRing.png',
			tags: [TRINKET, MAGICAL, METAL],
			level: 4,
			price: 225,
			stats: {
				spellPower: 5,
				mana: 4
			},
			flavor: 'Lemurs HATE it.'
		},
		{	name: "Asterscope",				// [Mage]
			level: 4,
			tags: [METAL, WEAPON, TRINKET],
			imagePath: "Icons/Asterscope.png",
			price: 280,
			amplifications: {
				fire: 0.20,
				shock: 0.20,
				cold: 0.20,
				dark: 0.20,
			},
			flavor: "Amplifies your FIRE, COLD, SHOCK and DARK damage by 20%."
		}, 	
		{	name: 'Caenturion Helm',		// [Tank]
			imagePath: 'Icons/CaenturionHelm.png',
			tags: [ARMOR, METAL],
			rarity: RARE,
			level: 4,
			price: 210,
			stats: {
				health: 5,
				armor: 20,
				manaRegeneration: 2
			},
			flavor: 'Lorem ipsum dolor sit amet, caenturianus!'
		},			
		{	name: 'Bishop Amulet',			// [Tank-ish]
			imagePath: 'Icons/BishopAmulet.png',
			tags: [TRINKET, MAGICAL],
			rarity: RARE,
			level: 4,
			price: 280,
			stats: {
				dodge: 20
			},
			flavor: 'Lets you avoid damage like priests avoid tax.'
		},		
		{	name: 'Good Apparel',			// [Tank]
			tags: [METAL, ARMOR],
			imagePath: 'Icons/GoodApparel.png',
			level: 4,
			price: 155,
			stats: {
				mana: 3,
				health: 5
			},
			flavor: "It's, uhh.. It's quite ok, you know? Quite, uhh... quite good, yeah."
		},
		{	name: "Metal Sneakers",			// [Tank]
			level: 4,
			tags: [TRINKET, METAL, ARMOR],
			imagePath: "Icons/MetalSneakers.png",
			price: 305,
			stats: {
				speed: 1,
				armor: 25
			},
			flavor: "Elom Nusk wears these casually."
		},
		{	name: "Zobi Mask",				// [Other]
			level: 4,
			tags: [TRINKET, CLOTH],
			imagePath: "Icons/ZobiMask.png",
			price: 245,
			stats: {
				manaRegeneration: 2,
				speed: 1,
				armor: 15,
				health: 2
			},
			flavor: 'In the first round, all enemies have -1 Speed.'
		},

		{	name: 'Ocarina of Lime',		// [Mage]
			imagePath: 'Icons/OcarinaofLime.png',
			tags: [TRINKET, MAGICAL, METAL],
			rarity: EPIC,
			level: 4,
			price: 205,
			stats: {
				spellPower: 8,
				crit: 8
			},
			flavor: 'Honestly, I have no idea what this actually is. I am too young.'
		},

		{	name: 'Book of Mathematics',	// [Mage-ish]
			imagePath: 'Icons/BookofMathematics.png',
			tags: [TRINKET],
			rarity: EPIC,
			level: 4,
			stats: {
				mana: 8,
			},
			price: 260,
			flavor: '3/5x^2 - 18x - 240 = 0'
		},
		{	name: 'White King Bar',			// [Mage + Tank]
			imagePath: 'Icons/WhiteKingBar.png',
			tags: [TRINKET, WEAPON, METAL, ARMOR],
			level: 4,
			price: 210,
			rarity: EPIC,
			stats: {
				spellPower: 6,
				health: 6,
				armor: 25
			},
			flavor: 'A white walks into a fu.'
		},

		{	name: 'Bow of Stars',			// [Mage + DPS]
			imagePath: 'Icons/BowofStars.png',
			tags: [WEAPON, TRINKET],
			rarity: ARTIFACT,
			level: 4,
			price: 200,
			stats: {
				damage: 5,
				spellPower: 8
			},
			flavor: 'Bow of Stairs; Bow of Scars; Bow of Sparse; Bow of Stirs; Bow of Strass; Bow of SARS;'
		},
		{	name: 'Landblade',				// [DPS + Tank]
			tags: [WEAPON, TRINKET, METAL],
			rarity: ARTIFACT,
			imagePath: 'Icons/Landblade.png',
			level: 4,
			price: 190,
			stats: {
				health: 10,
				damage: 6
			},
			flavor: 'Can\'t tell if dog poop or just dirt...'
		},
		{	name: 'Shuriken Pack',			// [DPS]
			tags: [WEAPON, METAL, TRINKET],
			rarity: ARTIFACT,
			level: 4,
			imagePath: 'Icons/ShurikenPack.png',
			price: 261,
			stats: {
				crit: 33,
				armor: -50
			},
			flavor: 'The icon shows 3 stars, but there are actualy 217 in the pack.'
		},

		// Level 5 (325g)
		{	name: 'Time Dagger',			// [DPS]
			appearCondition: () -> Player.progression.defeatedBlessedChildren,
			level: 5,
			tags: [TRINKET, MAGICAL, METAL, WEAPON],
			imagePath: 'Icons/TimeDagger.png',
			price: 290,
			stats: {
				crit: 2
			},
			flavor: 'At the end of every turn, gain 10% Crit.',
			onCombatStart: function(unit: Unit) {
				Battlefield.addOnRoundEndEvent(function(roundNumber: Int) {
					if (unit.isDead) return;
					unit.stats.crit += 10;
					unit.scrollRed('+10% CRIT');
				});
			}
		},
		{	name: 'The Inquisitor',			// [DPS + Tank]
			imagePath: 'Icons/ElBastardo.png',
			tags: [METAL, WEAPON],
			level: 5,
			price: 275,
			stats: {
				damage: 5,
				dodge: 15
			},
			flavor: 'Nobody expects him!'
		},		
		{	name: 'Handmaiden',				// [DPS]
			imagePath: 'Icons/Handmaiden.png',
			tags: [METAL, WEAPON],
			level: 5,
			price: 245,
			stats: {
				damage: 9,
				health: -9
			},
			flavor: 'Your knees weaken at the sight of such greatness!'
		},
		{	name: "Flamingo Sword",			// [DPS + Mage]
			level: 5,
			rarity: RARE,
			tags: [METAL, WEAPON],
			imagePath: "Icons/FlamingoSword.png",
			price: 380,
			stats: {
				damage: 6
			},
			amplifications: {
				fire: 0.35
			},
			flavor: "Amplifies your FIRE damage by 35%."
		}, 	
		{	name: 'Heavy Wizard Hat',		// [Mage]
			tags: [ARMOR, TRINKET, CLOTH],
			imagePath: 'Icons/HeavyWizardHat.png',
			level: 5,
			price: 300,
			rarity: RARE,
			stats: {
				spellPower: 6,
				mana: 5
			},
			flavor: "A wizard was too fat to wear this. So he swapped it for an Armor of Kings."
		},
		{	name: "Dark Logo Helm",			// [Mage + Tank]
			level: 5,
			tags: [METAL, ARMOR],
			imagePath: "Icons/DarkLogoHelm.png",
			rarity: RARE,
			price: 390,
			stats: {
				spellPower: 3,
				health: 7
			},
			amplifications: {
				dark: 0.25
			},
			resistances: {
				dark: -0.25
			},
			flavor: "Gives 25% resistance to DARK damage taken and 25% amplification to DARK damage done."
		},
		{	name: "Bettermail",				// [Tank]
			level: 5,
			tags: [METAL, CLOTH, ARMOR],
			imagePath: "Icons/Bettermail.png",
			price: 255,
			stats: {
				health: 12
			},
			flavor: "Simply better than the normal mail you use at home (which also claims to be better)."
		},
		{	name: 'Obsidian Shield',		// [Tank]
			tags: [ARMOR, METAL, ORE],
			imagePath: 'Icons/ObsidianShield.png',
			level: 5,
			price: 300,
			stats: {
				health: 5,
				armor: 15,
				manaRegeneration: 3
			},
			flavor: 'If you put lava and water in the wrong order, you get a Cobblestone Shield.'
		},
		{	name: 'Armor of Kings',			// [Tank]
			tags: [ARMOR, METAL],
			imagePath: 'Icons/ArmorofKings.png',
			rarity: EPIC,
			level: 5,
			price: 310,
			stats: {
				health: 10,
				manaRegeneration: 2,
				dodge: 10
			},
			flavor: 'Our current king is too skinny to wear this.'
		},
		{	name: 'Wicked Squirm',			// [Other]
			tags: [WEAPON, TRINKET],
			imagePath: 'Icons/WickedSquirm.png',
			level: 5,
			price: 305,
			stats: {
				mana: 4,
				health: 8,
				dodge: 12
			},
			flavor: 'Eldritch adjunct unwedded from reprobate abomination, immuring primed to assail the confiding.'
		},
		{	name: 'Omnicrown',				// [Other]
			tags: [ARMOR, METAL, TRINKET],
			imagePath: 'Icons/Omnicrown.png',
			rarity: RARE,
			level: 5,
			price: 350,
			stats: {
				health: 5,
				mana: 5,
				spellPower: 3,
				armor: 15,
			},
			flavor: 'This is the kind of item in games that nobody needs or wants, but they just got nothing better to wear.'
		},

		{	name: 'Frozen Spear',			// [Mage + Tank]
			level: 5,
			rarity: EPIC,
			tags: [METAL, WEAPON],
			imagePath: 'Icons/FrozenSpear.png',
			price: 390,
			stats: {
				armor: 35
			},
			amplifications: {
				cold: 0.4
			},
			flavor: 'Amplifies your COLD damage by 40%.'
		},
		{	name: 'Crossmourne',			// [DPS]
			tags: [WEAPON, METAL],
			imagePath: 'Icons/Crossmourne.png',
			level: 5,
			price: 355,
			rarity: ARTIFACT,
			stats: {
				damage: 6,
				crit: 20
			},
			flavor: 'Crossmourne hungers.'
		},
		{	name: 'Golden Goat Horn',		// [Other]
			level: 5,
			rarity: ARTIFACT,
			tags: [METAL, TRINKET, ORE],
			imagePath: 'Icons/GoldenGoatHorn.png',
			price: 405,
			stats: {
				health: -8,
				mana: 7,
				crit: 15,
				dodge: 15
			},
			amplifications: {
				shock: 0.4
			},
			flavor: 'Amplifies your SHOCK damage by 40% (seriously).'
		},



		{	name: 'Sword of 1000 Whats',
			level: 99,
			imagePath: 'Icons/Crossmourne.png',
			price: 9999,
			stats: {
				damage: 16,
				speed: 4,
				health: 25
			},
			flavor: 'The ultimate developer item. Use with care...'
		},
		{	name: 'Placeholder',
			level: 99,
			imagePath: 'Icons/Oopsie.png',
			price: 0,
			flavor: 'If you see this item, it is a bug. Report this to Dave. Thank you!'
		}
	];
	public static var _templateItem = 
		{	name: '',
			imagePath: 'Icons/.png',
			level: 4,
			price: 210,
			stats: {
				health: 7,
				damage: 7
			},
			flavor: ''
		}
	public static var consumables: Array<Dynamic> = [
		{	name: "Moldy Bread",
			type: "CONSUMABLE",
			level: 1,
			stats: {},
			imagePath: "Icons/MoldyBread.png",
			price: 12,
			effect: {
				description: "Heals 3 health. \n Would have tasted ok a few days ago.",
				audio: 'EatAudio'
			},
			onUse: (unit, char) -> doItemHeal(unit, char, 3)
		},
		{	name: "Bit of Water",
			type: "CONSUMABLE",
			tags: [LIQUID],
			level: 1,
			stats: {},
			imagePath: "Icons/BitofWater.png",
			price: 15,
			effect: {
				description: "Heals 3 health and restores 3 mana. \n It's just water, bro.",
				healAmount: 3,
				replenishAmount: 3,
				audio: 'BottleBubbleAudio'
			},
			onUse: (unit, char) -> {
				doItemReplenish(unit, char, 3);
				doItemHeal(unit, char, 3);
			}
		},
		{	name: "Blueberry",
			type: "CONSUMABLE",
			tags: [PLANT],
			level: 1,
			stats: {},
			imagePath: "Icons/Blueberry.png",
			price: 10,
			effect: {
				description: "Replenishes 5 mana. \n Blueberries are high in vitamin M, which replenishes mana and improves bowel movement.",
				replenishAmount: 5,
				audio: 'EatAudio'
			},
			onUse: (unit, char) -> {
				doItemReplenish(unit, char, 5);
			}
		},
		{	name: "Cheese",
			type: "CONSUMABLE",
			level: 2,
			stats: {},
			imagePath: "Icons/Cheese.png",
			price: 21,
			effect: {
				description: "Heals 5 health and smells atrocious.",
				healAmount: 5,
				audio: 'EatAudio'
			},
			onUse: (unit, char) -> doItemHeal(unit, char, 5)
		},
		{	name: "Bishop Candy",
			type: "CONSUMABLE",
			level: 2,
			stats: {},
			imagePath: "Icons/BishopCandy.png",
			price: 22,
			effect: {
				description: "Replenishes 10 mana. \n Helps keep a bishop's breath cool during sermons.",
				replenishAmount: 10,
				audio: 'EatAudio'
			},
			onUse: (unit, char) -> doItemHeal(unit, char, 10)
		},
		{	name: "Bomb",
			appearCondition: () -> Player.progression.defeatedCaptainStashton,
			type: "CONSUMABLE",
			level: 2,
			stats: {},
			imagePath: "Icons/Bomb.png",
			price: 39,
			effect: {
				description: "Deals 7 FIRE damage to a random enemy.",
				isCombatOnly: true
			},
			onUse: (unit, char) -> {
				if (unit.isDead) return;
				final enemies = Battlefield.getAllAliveEnemyUnits();
				if (enemies.length == 0) {
					unit.say('No enemies there!', 3);
					return;
				}
				final enemy = randomOf(enemies);
				final explosion = SpecialEffectsFluff.doExplosionEffect(enemy.getXCenter(), enemy.getYCenter());
				explosion.growTo(0.5, 0.5, 0);
				unit.damageUnit(enemy, int(7 * unit.amplifications.fire), FIRE);
			}
		},
		{	name: "Sandwich",
			type: "CONSUMABLE",
			tags: [SPECIAL_ITEM],	// Only obtainable by digging
			level: 0,
			stats: {},
			imagePath: "Icons/Sandwich.png",
			price: 12,
			effect: {
				description: "Heals 7 health. Why someone would bury this is beyond me.",
				healAmount: 7,
				audio: 'EatAudio'
			},
			onUse: (unit, char) -> doItemHeal(unit, char, 7)
		},
		{	name: "Fish Tail",
			type: "CONSUMABLE",
			tags: [SPECIAL_ITEM],	// Only obtainable by giving gold to the pirates
			level: 0,
			stats: {},
			imagePath: "Icons/FishTail.png",
			price: 21,
			effect: {
				description: "Heals 5 health. Has some sand on it. Can be washed in the sea, but the sea also has some sand in it.",
				healAmount: 5,
				audio: 'EatAudio'
			},
			onUse: (unit, char) -> doItemHeal(unit, char, 5)
		},
		{	name: 'Blood Mixture',
			type: 'CONSUMABLE',
			tags: [LIQUID, SPECIAL_ITEM],
			level: 0,
			stats: {},
			imagePath: 'Icons/RedPotion.png',
			price: 76,
			effect: {
				description: 'Take 5 damage, but increase all damage you do this combat by 25%! (usable only in combat)',
				audio: 'BottleBubbleAudio',
				isCombatOnly: true
			},
			onUse: (unit: Unit, pc: PlayerCharacter) -> {
				if (getCurrentSceneName() == 'BattlefieldScene') {
					unit.damageUnit(unit, 3, PURE);
					unit.damageDoneMultiplier += 0.25;
					U.flashRed(unit.actor, 100);
					unit.scrollRed('+25% RAAGHH');
				} else {
					trace('WARNING: Used the Blood Mixture outside of combat!');
				}
			}
		},
		{	name: 'Unknown Potion',
			type: 'CONSUMABLE',
			tags: [LIQUID, SPECIAL_ITEM],
			level: 0,
			stats: {},
			imagePath: 'Icons/PotionofRandomness.png',
			price: 39,
			effect: {
				description: 'Has a random effect. 80% chance to have a good effect. Try it! (combat only)',
				audio: 'BottleBubbleAudio',
				isCombatOnly: true
			},
			onUse: (unit: Unit, pc: PlayerCharacter) -> {
				if (getCurrentSceneName() == 'BattlefieldScene') trace('WARNING: Used Unknown Potion outside of combat!');
				final variantIndex: Int = randomOf([0, 1, 2, 3, 3]);
				final variants = [
					() -> { unit.heal(int(unit.stats.health * 0.25)); },
					() -> {
						unit.damage(5);
						if (unit.tileOn.hasTrap() == false) {
							final spawnedTrap = Battlefield.spawnTrap('Toxic Fog', unit.tileOn);
							final centerPoint = spawnedTrap.getCenterPoint();
							Effects.playParticleAndThen(centerPoint, centerPoint, 'Toxic Smoke', 150, () -> {});
						}
						unit.say('Dammit! It was acid!');
					},
					() -> {
						unit.stats.speed += 1;
						if (unit.isPlayerCharacter()) {
							unit.playerCharacter.stats.speed += 1;
						}
						unit.scrollGreen('+1 SPD');
						doAfter(2000, function() {
							if (unit.isDead) return;
							unit.say('I feel permanently faster!');
						});
					},
					() -> {
						final statName: String = randomOf(['Damage', 'Spell Power', 'Initiative', 'Mana', 'Health']);
						if (statName == 'Damage') {
							unit.stats.damage += 4;
							if (unit.isPlayerCharacter()) {
								unit.playerCharacter.stats.damage += 4;
							}
							unit.scrollRed('+4 DMG');
						} else if (statName == 'Spell Power') {
							unit.stats.spellPower += 4;
							if (unit.isPlayerCharacter()) {
								unit.playerCharacter.stats.spellPower += 4;
							}
							unit.scrollBlue('+4 SP');
						} else if (statName == 'Mana') {
							unit.stats.mana += 2;
							if (unit.isPlayerCharacter()) {
								unit.playerCharacter.stats.mana += 2;
							}
							unit.scrollBlue('+2 MANA');
						} else if (statName == 'Health') {
							unit.stats.health += 4;
							if (unit.isPlayerCharacter()) {
								unit.playerCharacter.stats.health += 4;
							}
							unit.scrollGreen('+4 HP');
						}
						doAfter(2000, () -> {
							unit.say('My $statName is now higher!');
						});
					}
				];
				final chosenVariant = variants[variantIndex];
				chosenVariant();
			}

		},
	
		// Special
		{	name: "Penicillin Bread",
			type: "CONSUMABLE",
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: "Icons/PenicillinBread.png",
			price: 36,
			effect: {
				description: "Heals 12 health. \n Heals you and cures you and staph.",
				audio: 'EatAudio'
			},
			onUse: (unit, char) -> doItemHeal(unit, char, 12)
		},
		{	name: "Moldy Sandwich",
			type: "CONSUMABLE",
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: "Icons/MoldySandwich.png",
			price: 36,
			effect: {
				description: "Heals 12 health. \n No no, this mold is actually healthy!",
				audio: 'EatAudio'
			},
			onUse: (unit, char) -> doItemHeal(unit, char, 12)
		},
		{	name: "Blue Cheese",
			type: "CONSUMABLE",
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: "Icons/BlueCheese.png",
			price: 63,
			effect: {
				description: "Heals 21 health. \n Better than the waffles from the same cuisine.",
				audio: 'EatAudio'
			},
			onUse: (unit, char) -> doItemHeal(unit, char, 21)
		},
		{	name: "Taco",
			type: "CONSUMABLE",
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: "Icons/Taco.png",
			price: 33,
			effect: {
				description: "Heals 11 health and might give you cramps if used while fighting.",
				audio: 'EatAudio'
			},
			onUse: (unit, char) -> {
				doItemHeal(unit, char, 11);
				if (unit != null) {
					unit.addBuff(new Buff('Taco Cramps', 3, null, {
						onTick: function(self: Unit) {
							playAudio(if (percentChance(50)) 'Fart1Audio' else 'Fart2Audio');
							Effects.playParticleAndThen(self.getCenterPoint(), self.getCenterPoint(), 'Toxic Smoke', 150, () -> {});
							self.say('Ohh...');
						}
					}));
				}
			}
		},
		{	name: 'Potion of Armor',
			type: 'CONSUMABLE',
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: 'Icons/PotionofArmor.png',
			price: 55,
			effect: {
				description: 'Gain +25% ARMOR for the rest of this combat.',
				audio: 'BottleBubbleAudio',
				isCombatOnly: true
			},
			onUse: (unit: Unit, char: PlayerCharacter) -> {
				if (unit != null)
					unit.stats.armor += 25;
				unit.scrollBlue('+25 ARM');
			}
		},
		{	name: 'Potion of Healing',
			type: 'CONSUMABLE',
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: 'Icons/PotionofHealing.png',
			price: 55,
			effect: {
				description: 'Heal for 25% of missing Health.',
				audio: 'BottleBubbleAudio'
			},
			onUse: (unit: Unit, char: PlayerCharacter) -> {
				if (unit != null) {
					final healAmount: Int = ceil((unit.stats.health - unit.health) * 0.25);
					unit.heal(healAmount);
				} else if (char != null) {
					final healAmount: Int = ceil((char.stats.health - char.health) * 0.25);
					char.heal(healAmount);
				}
			}
		},
		{	name: 'Potion of Magic',
			type: 'CONSUMABLE',
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: 'Icons/PotionofMagic.png',
			price: 55,
			effect: {
				description: 'Restores 50% of total MANA and gives +6 SP for the rest of the combat.',
				audio: 'BottleBubbleAudio',
				isCombatOnly: true
			},
			onUse: (unit: Unit, char: PlayerCharacter) -> {
				final replenishAmount = ceil(unit.stats.mana * 0.5);
				unit.replenish(replenishAmount);
				unit.stats.spellPower += 6;
				doAfter(500, () -> {
					unit.scrollBlue('+6 SP');
				});
			}
		},
		{	name: 'Anamita Cusmaria',
			type: 'CONSUMABLE',
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: 'Icons/AnamitaCusmaria.png',
			price: 138,
			effect: {
				description: 'TuRnS oN cOoOoL mOdE!!!1!',
				audio: 'EatAudio'
			},
			onUse: function(unit: Unit, char: PlayerCharacter) {
				playMusic('RickRollMusic');
			}
		},

		{	name: 'Tome of Health',
			type: 'CONSUMABLE',
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: 'Icons/TomeofHealth.png',
			price: 18,
			effect: {
				description: 'Gain +3 Health this run (usable only out of combat).',
				audio: 'HealingWordAudio',
				isNonCombatOnly: true
			},
			onUse: function(unit: Unit, char: PlayerCharacter) {
				char.stats.health += 3;
				char.health += 3;
			}
		},
		{	name: 'Tome of Damage',
			type: 'CONSUMABLE',
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: 'Icons/TomeofDamage.png',
			price: 13,
			effect: {
				description: 'Gain +1 Damage this run (usable only out of combat).',
				audio: 'HealingWordAudio',
				isNonCombatOnly: true
			},
			onUse: function(unit: Unit, char: PlayerCharacter) {
				char.stats.damage += 1;
			}
		},
		{	name: 'Tome of Spell Power',
			type: 'CONSUMABLE',
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: 'Icons/TomeofSpellPower.png',
			price: 13,
			effect: {
				description: 'Gain +1 Spell Power this run (usable only out of combat).',
				audio: 'HealingWordAudio',
				isNonCombatOnly: true
			},
			onUse: function(unit: Unit, char: PlayerCharacter) {
				char.stats.spellPower += 1;
			}
		},
		{	name: 'Tome of Mana',
			type: 'CONSUMABLE',
			tags: [SPECIAL_ITEM],
			level: 1,
			stats: {},
			imagePath: 'Icons/TomeofMana.png',
			price: 23,
			effect: {
				description: 'Gain +2 Mana this run (usable only out of combat).',
				audio: 'HealingWordAudio',
				isNonCombatOnly: true
			},
			onUse: function(unit: Unit, char: PlayerCharacter) {
				char.stats.mana += 2;
			}
		},
	];
	static function tomeItemForSpell(rarity: Int = COMMON, level: Int = 1, spellName: String, ?description: String, ?price = 100, ?appearCondition: Void -> Bool) {
		function getDescription(): String {
			final baseDescription = SpellDatabase.get(spellName).description;
			final newDescription = baseDescription.replace('@', '');	// Remove all @ because they are used for formatting
			return newDescription;
		}
		function getLearnSuffix(): String {
			final possibleClasses = CharacterClassDatabase.classesById.filter(cc -> cc.availableSpells.indexOf(spellName) != -1).map(cc -> cc.name);
			if (possibleClasses != null && possibleClasses.length == 0) {
				return '';
			}
			if (possibleClasses.length == CharacterClassDatabase.classesById.length) {
				return '(any class)';
			}
			return ' (${possibleClasses.join(", ")})';
		}
		if (spellName == 'Unholy Revival') {
			trace('Got appear condition null? ${appearCondition == null}');
		}
		return {
			name			: ItemsDatabase.getTomeNameFromSpellName(spellName),
			imagePath		: 'Icons/Tome${spellName.split(" ").join("")}.png',
			level			: level,
			type			: "SPELL",
			rarity 			: rarity,
			price 			: price,
			stats			: {},
			effect			: {
				description	: if (description != null) description else 'Learn ${getLearnSuffix()}: ${getDescription()}'
			},
			appearCondition: appearCondition
		};
	}
	// Spell tomes automatically bind to the respective spells by name
	// Needs to be a function to load them AFTER the spells are loaded, an not on app start
	public static function getSpells() {
		return [
			tomeItemForSpell(COMMON, 1, 'Triple Arrow'),
			tomeItemForSpell(RARE, 1, 'Fox Companion'),
			tomeItemForSpell(RARE, 1, 'Fox Attack'),
			tomeItemForSpell(RARE, 1, 'Bola Shot'),
			tomeItemForSpell(RARE, 2, 'Flare Shot'),
			tomeItemForSpell(COMMON, 2, 'Bear Trap'),
			tomeItemForSpell(COMMON, 2, 'Disorient'),
			tomeItemForSpell(EPIC, 2, 'Quickfoot'),
			tomeItemForSpell(COMMON, 2, 'Cobra Shot'),
			tomeItemForSpell(RARE, 2, 'Crystal Arrow'),
			tomeItemForSpell(RARE, 2, 'Firrow'),
			tomeItemForSpell(RARE, 2, 'Steady Shooting'),
			tomeItemForSpell(COMMON, 2, 'Longdraw'),
			
			tomeItemForSpell(COMMON, 1, 'Dark Lance'),
			tomeItemForSpell(RARE, 1, 'Throw Rock'),
			tomeItemForSpell(RARE, 1, 'Dig'),
			tomeItemForSpell(RARE, 1, 'Storm Spear'),
			tomeItemForSpell(EPIC, 1, 'Blind Execution'),
			tomeItemForSpell(RARE, 1, 'Long Reach'),
			tomeItemForSpell(RARE, 2, 'Kill Block'),
			tomeItemForSpell(RARE, 2, 'Big Block'),
			tomeItemForSpell(COMMON, 2, 'Charge'),
			tomeItemForSpell(COMMON, 2, 'Haymaker'),
			tomeItemForSpell(COMMON, 2, 'Intimidation'),
			tomeItemForSpell(ARTIFACT, 2, 'Smite'),
			tomeItemForSpell(RARE, 2, 'Condemnation'),
			tomeItemForSpell(EPIC, 2, 'Implosion', () -> Player.progression.defeatedSpatula1),
			tomeItemForSpell(EPIC, 3, 'Skull Break'),

			tomeItemForSpell(RARE, 1, 'Blink'),
			tomeItemForSpell(COMMON, 1, 'Flex Arrow'),
			tomeItemForSpell(RARE, 1, 'Mana Ward'),
			tomeItemForSpell(COMMON, 2, 'Poswap'),
			tomeItemForSpell(COMMON, 2, 'Ice Cube'),
			tomeItemForSpell(COMMON, 2, 'Ignite'),
			tomeItemForSpell(RARE, 2, 'Fire Ball'),
			tomeItemForSpell(RARE, 2, 'Obstacle Focus'),
			tomeItemForSpell(EPIC, 2, 'Frost Nova'),
			tomeItemForSpell(EPIC, 2, 'Flame Dagger'),
			tomeItemForSpell(EPIC, 2, 'Tsunami', () -> Player.progression.defeatedStormjr),
			tomeItemForSpell(EPIC, 2, 'Iceberg Drop'),
			tomeItemForSpell(EPIC, 2, 'Shocking Startup'),
	
			// Special
			tomeItemForSpell(RARE, 3, 'Everblocker'),
			tomeItemForSpell(RARE, 3, 'Momentum Magic'),
			tomeItemForSpell(RARE, 3, 'Hero Health'),
			tomeItemForSpell(ARTIFACT, 3, 'Elementulus'),
			tomeItemForSpell(RARE, 3, 'Flaming Passion'),
			tomeItemForSpell(RARE, 3, 'Electric Vibe'),
			tomeItemForSpell(RARE, 3, 'Cold Stare'),
			tomeItemForSpell(RARE, 3, 'Dark Thoughts'),
			tomeItemForSpell(COMMON, 3, 'Fire Heart'),
			tomeItemForSpell(COMMON, 3, 'Winter Wonder'),
			tomeItemForSpell(COMMON, 3, 'Iron Deficiency'),
			tomeItemForSpell(COMMON, 3, 'Meditator'),
			tomeItemForSpell(EPIC, 3, 'Time Warp'),
			tomeItemForSpell(EPIC, 3, 'Rabbit Foot'),
			
			tomeItemForSpell(ARTIFACT, 3, 'Unholy Revival', 'Learn the Unholy Revival ability, which revives you when you die in combat with 25% of total Health, but only ONCE. Doctors HATE it!', () -> false),
			tomeItemForSpell(ARTIFACT, 3, 'Summon Candle', 'Summons a candle in the Somnium, which protects you from darkness.', 35, () -> false),
			tomeItemForSpell(ARTIFACT, 3, 'Fiery Presence', () -> false),
			tomeItemForSpell(ARTIFACT, 3, 'Soul Drain', () -> false),
			tomeItemForSpell(RARE, 3, 'Boom Barrel', () -> Player.progression.defeatedCaptainStashton),
		];
	}
	public static var trash: Array<Dynamic> = [
		// Very special
		{	name: 'Gold',
			type: 'JUNK',
			tags: [SPECIAL_ITEM],
			imagePath: 'Icons/Gold.png',
			price: 0,
			stats: {},
			effect: {
				description: 'NOTE: Looting Gold automatically adds it to your total gold.'
			}
		},
		// Special
		{	name: 'Tooth of Insomnia',
			type: 'JUNK',
			tags: [SPECIAL_ITEM, UNHOLY],
			imagePath: 'Icons/ToothOfInsomnia.png',
			price: 73,
			flavor: 'Doesn\'t seem to do anything. Maybe there\'s a way to activate it...'
		},
		{	name: 'Cellar Key',
			type: 'JUNK',
			tags: [SPECIAL_ITEM],
			imagePath: 'Icons/CellarKey.png',
			price: 240,
			flavor: 'Unlocks the blacksmith\'s cellar. What secrets lie down there...?'
		},
		{	name: 'Heart',
			type: 'JUNK',
			tags: [SPECIAL_ITEM, UNHOLY],
			imagePath: 'Icons/Heart.png',
			price: 19,
			flavor: 'Usable as a pillow for hamsters.'
		},
		{	name: 'Bone',
			type: 'JUNK',
			tags: [SPECIAL_ITEM, UNHOLY],
			imagePath: 'Icons/Bone.png',
			price: 10,
			flavor: 'Belongs to someone spooky and scary.'
		},
		{	name: 'Just Some Dirt',
			type: 'JUNK',
			tags: [SPECIAL_ITEM],
			imagePath: 'Icons/JustSomeDirt.png',
			price: 2,
			flavor: '\\_=<_/'
		},
		{	name: 'Flowers',
			type: 'JUNK',
			tags: [SPECIAL_ITEM],
			imagePath: 'Icons/Flowers.png',
			price: 26,
			flavor: 'There is definitely something... holy... pure... about these flowers...'
		},
		// Normals
		{	name: "Soft Fur",
			type: "JUNK",
			tags: [CLOTH],
			imagePath: "Icons/SoftFur.png",
			price: 6,
			stats: {},
			flavor: "No purpose other than to keep your heart warm."
		},
		{	name: 'Planks',
			type: 'JUNK',
			imagePath: 'Icons/Planks.png',
			price: 4,
			flavor: 'You thought this was for crafting? Haha, no. There\'s no crafting in this game. You think this is Minecraft?'
		},
		{	name: 'Scrap Metal',
			type: 'JUNK',
			tags: [METAL, ORE],
			imagePath: 'Icons/ScrapMetal.png',
			price: 16,
			flavor: '"FIARE VECHI! FIARE VECHI LUAM!" - Unknown Child, 2018'
		},
		{	name: 'Candle',
			type: 'JUNK',
			tags: [UNHOLY],
			imagePath: 'Icons/Candle.png',
			price: 10,
			flavor: 'You no take!'
		},
		{	name: 'Toilet Paper',
			type: 'JUNK',
			tags: [CLOTH],
			imagePath: 'Icons/ToiletPaper.png',
			price: 30,
			flavor: 'Seems to be in short supply these days; no wonder it\'s so expensive.'
		},
		{	name: 'Church Stocks',
			type: 'JUNK',
			tags: [CLOTH],
			imagePath: 'Icons/ChurchStocks.png',
			price: 52,
			flavor: 'I guarantee its price will stay the same.'
		}
	];


	static function doItemHeal(unit: Unit, pc: PlayerCharacter, amount: Int) {
		if (unit != null)
			unit.heal(amount);
		if (pc != null)
			pc.heal(amount);
	}
	static function doItemReplenish(unit: Unit, pc: PlayerCharacter, amount: Int) {
		if (unit != null)
			unit.replenish(amount);
		if (pc != null)
			pc.replenish(amount);
	}

}

// 'icon' or 'imagePath'
class ItemsDatabase
{

	static var _checkPaths = true;	// Turn this to false when shipping the game
	public static var itemsByName	: Map<String, Item>;
	public static var itemsById		: Array<Item>;

	public static function load(){
		itemsByName = new Map<String, Item>();
		itemsById	= [];
		var gear = ItemsDatabase_Items.gear;
		var spellItems = ItemsDatabase_Items.getSpells();
		var consumables = ItemsDatabase_Items.consumables;
		var trashItems = ItemsDatabase_Items.trash;
		var items = gear.concat(spellItems).concat(consumables).concat(trashItems);
		var didFindItemWithoutIcon = false;
		for (i in items){
			var item = Item.createFromDynamic(i);
			item.id	= itemsById.length;
			itemsById.push(item);
			itemsByName[item.name] = item;
			if (_checkPaths) if (ImageX.imageExists(item.imagePath) == false) {
				trace ('WARNING: Image ${item.imagePath} for item ${i.name} does not exist!');
				didFindItemWithoutIcon = true;
			}
		}
		if (didFindItemWithoutIcon) {
			throw 'ERROR: Found items without icons. Exiting.';
		}
	}

	public static function getOopsie(extraText: String) {
		final oopsie = get('Oopsie');
		oopsie.flavor += ' (${extraText})';
		return oopsie;
	}

	public static function get(?id : Int, ?name : String){
		if (id != null){
			if (id < 0 || id >= itemsById.length) trace('ERROR: Item id ${id} is out of bounds.');
			return itemsById[id].clone();
		} else {
			if (!itemsByName.exists(name)) {
				return getOopsie('no item named "${name}" exists');
			}
			return itemsByName[name].clone();
		}
	}
	public static function itemExists(name: String) {
		return itemsByName.exists(name);
	}



	public static function getRandomGearOfLevel(level: Int, ?rarity: Int = ANY_RARITY) : Item {
		if (level < 1) level = 1;
		var possibleItems = itemsById.filter(item -> item.type == 'GEAR').filter(item -> item.level == level);
		if (rarity != -1)
			possibleItems = possibleItems.filter(item -> item.rarity == rarity);
		if (possibleItems.length == 0) {
			return getOopsie('no gear of level ${level} found');
		}
		var chosenItem : Item = cast randomOf(possibleItems);
		return chosenItem;
	}
	public static function getRandomGearOfLevelWithTag(level: Int, tag: Int, ?rarity: Int = ANY_RARITY): Item {
		var possibleItems = itemsById.filter(item -> item.type == 'GEAR' && item.level == level && !!!item.isSpecial());
		if (rarity != -1)
			possibleItems = possibleItems.filter(item -> item.rarity == rarity);
		if (possibleItems.length == 0) {
			return getOopsie('no gear of level ${level} with tag ${Constants.itemTagToString(tag)} and rarity ${rarity} found');
		}
		var chosenItem : Item = cast randomOf(possibleItems);
		return chosenItem;
	}
	public static function getRandomConsumableOfLevel(level: Int, ?rarity: Int = ANY_RARITY): Item {
		if (level < 1) level = 1;
		var possibleItems = itemsById.filter(item -> item.type == 'CONSUMABLE').filter(item -> item.level == level && !!!item.isSpecial());
		if (rarity != -1)
			possibleItems = possibleItems.filter(item -> item.rarity == rarity);
		if (possibleItems.length == 0) {
			return getOopsie('no consumable of level ${level} found');
		}
		final chosenItem : Item = cast randomOf(possibleItems);
		return chosenItem;
	}
	public static function getRandomUsableSpellTomeOfMaxLevel(level: Int, maxRarity: Int): Item {
		final classes = Player.characters.map(chr -> chr.characterClass);
		final availableSpellsByClass: Array<Array<String>> = classes.map(cls -> cls.availableSpells);
		final totalUsableSpells: Array<String> = mergeArrays(availableSpellsByClass);
		trace('Got total usable spells: [${totalUsableSpells.join(', ')}]');
		var possibleItems: Array<Item> = totalUsableSpells.map(name -> get(ItemsDatabase.getTomeNameFromSpellName(name))).filter(item -> item.level <= level);
		trace('Got possible items as: ${possibleItems.map(item -> if (item != null) item.name else "NULL")}');
		if (possibleItems == null) trace('Null possibleItems!');
		if (maxRarity != -1)
			possibleItems = possibleItems.filter(item -> item.rarity <= maxRarity);
		if (possibleItems == null) trace('Null possibleItems!');
		if (possibleItems.length == 0) trace('Possible items .length = 0 with maxRarity=${maxRarity} and level=${level}!!');
		var chosenItem : Item = cast randomOf(possibleItems);
		return chosenItem;
	}
	


	public static function getSpellNameFromItemName(itemName: String) {
		if (itemName == null) throw 'ERROR: Null itemName given!';
		if (itemName.charAt(0) != '~') throw 'ERROR: Trying to get spell name from item name ${itemName}';
		return itemName.substring(2, itemName.length - 2);
	}
	public static function getTomeNameFromSpellName(spellName: String) {
		return '~ ${spellName} ~';
	}

	static var _getPossibleItemsExampleOptions = {
		usableTome: false,		// If this is true, only searches usable tomes by class
		type: 'CONSUMABLE',
		level: 2,				// Or maxLevel: 2, or preferredLevel: 2
		rarity: RARE,			// Or maxRarity: RARE
		includeTags: [TRINKET, METAL],
		excludeTags: [SPECIAL_ITEM]
	}
	public static function getPossibileItemsWithOptions(options: Dynamic) {
		var possibleItems: Array<Item> = itemsById.filter(item -> item.appearCondition == null || item.appearCondition() == true);
		trace('o Searching items by criteria: ${haxe.Json.stringify(options)}');
		if (options.usableTome == true) {
			trace('Yes usable tome');
			final classes = Player.characters.map(chr -> chr.characterClass);
			trace('Classes: ${classes.length}');
			final availableSpellsByClass: Array<Array<String>> = classes.map(cls -> cls.availableSpells);
			final totalUsableSpells: Array<String> = mergeArrays(availableSpellsByClass);
			final knownSpells = Player.getAllEquippedSpells();
			trace('totalUsableSpells: ${totalUsableSpells.join(', ')}');
			final totalAvailableSpells = totalUsableSpells.filter(spellName -> knownSpells.indexOf(spellName) == -1);
			possibleItems = totalAvailableSpells.map(name -> get(getTomeNameFromSpellName(name)));
			possibleItems = possibleItems.filter(item -> item.appearCondition == null || item.appearCondition() == true);
			trace('possibleItems: ${possibleItems.length}');
			if (possibleItems.length == 0) return [getOopsie('No usable tome found.')];
		}
		if (options.type != null) {
			trace('Got my option as: ${options.type}');
			trace('Searching ${possibleItems.length} spells: ${possibleItems.map(i -> i.name + "$" + i.type)}');
			if (possibleItems.length > 0) {
				trace('E.g.1: comparing ${possibleItems[0].type} with ${options.type}: ${possibleItems[0].type == options.type}');
			}
			possibleItems = possibleItems.filter(item -> item.type == options.type);
			if (possibleItems.length == 0) return [getOopsie('No item of type ${options.type} found')];
		}
		if (options.level != null) {
			possibleItems = possibleItems.filter(item -> item.level == options.level);
			if (possibleItems.length == 0) return [getOopsie('No item of level ${options.level} found')];
		}
		if (options.preferredLevel != null) {
			final newPossibleItems = possibleItems.filter(item -> item.level == options.preferredLevel);
			if (newPossibleItems != null && newPossibleItems.length > 0) {
				possibleItems = newPossibleItems;
			}
		}
		if (options.maxLevel != null) {
			possibleItems = possibleItems.filter(item -> item.level <= options.maxLevel);
			if (possibleItems.length == 0) return [getOopsie('No item of max level ${options.maxLevel} found')];
		}
		if (options.rarity != null && options.rarity != ANY_RARITY) {
			possibleItems = possibleItems.filter(item -> item.rarity == options.rarity);
			if (possibleItems.length == 0) return [getOopsie('No item of rarity ${options.rarity} found')];
		}
		trace('@@@@@---- BEFORE rarity items: ${possibleItems.map(i -> i.name).join(", ")}');
		if (options.maxRarity != null && options.maxRarity != ANY_RARITY) {
			final rarityToChanceMapping = [
				ANY_RARITY => 100,
				COMMON => 100,
				TRASH => 100,
				RARE => 50,
				EPIC => 25,
				ARTIFACT => 10
			];
			possibleItems = possibleItems.filter(item -> item.rarity <= options.maxRarity && (percentChance(rarityToChanceMapping[item.rarity])));	// To make ARTIFACT items a bit less common
			if (possibleItems.length == 0) return [getOopsie('No item of max rarity ${options.maxRarity} found')];
		}
		if (options.includeTags != null) {
			final includeTags: Array<Int> = cast options.includeTags;
			for (tag in includeTags) {
				possibleItems = possibleItems.filter(item -> item.tags.indexOf(tag) != -1);
			}
			if (possibleItems.length == 0) return [getOopsie('No item of with tags ${includeTags} found')];
		}
		if (options.excludeTags != null) {
			trace('Searching ${possibleItems.length} items');
			final excludeTags: Array<Int> = cast options.excludeTags;
			for (tag in excludeTags) {
				possibleItems = possibleItems.filter(item -> item.tags.indexOf(tag) == -1);
			}
			if (possibleItems.length == 0) {
				trace('* And none found :c');
				return [getOopsie('No item found: type=${options.type} pl=${options.preferredLevel} exclT=${options.excludeTags} inclT=${options.includeTags}')];
			};
		}
		trace('Got ${possibleItems.length} item possibilities.');
		return possibleItems;
	}
	public static function getRandomItem(options: Dynamic): Item {
		final possibleItems = getPossibileItemsWithOptions(options);
		return randomOf(possibleItems).clone();
	}
	public static function get3RandomItems(options: Dynamic): Array<Item> {
		final possibleItems = getPossibileItemsWithOptions(options);
		shuffle(possibleItems);
		return possibleItems.slice(0, 3);
	}

}
