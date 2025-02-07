

package scripts;

import U.*;
using U;

import scripts.Constants.*;


class CharacterClassDatabase_Classes {
    public static var classes: Array<Dynamic> = [
        {   name: 'Knight',
            thumbnailPath: 'auto',
            characterSelectIconPath: 'Icons/Knight.png',
            stats: {
                health: 20,
                damage: 10,
                mana: 10,
                spellPower: 7,
                speed: 2,
                initiative: 99,
                manaRegeneration: 5
            },
            availableSpells: [
                'Throw Rock',
                'Dark Lance',
                'Dig',
                'Charge',
                'Haymaker',
                'Intimidation',
                'Storm Spear',
                'Big Block',
                'Condemnation',
                'Smite',
                'Implosion',
                'Blind Execution',
                'Skull Break',
            
                'Long Reach',
                'Kill Block',

                'Rabbit Foot',
                'Time Warp',
                'Momentum Magic',
                'Everblocker',
                'Hero Health',
                'Elementulus',
                'Flaming Passion',
                'Electric Vibe',
                'Cold Stare',
                'Dark Thoughts',
                'Fire Heart',
                'Winter Wonder',
                'Iron Deficiency',
                'Meditator',

                'Boom Barrel',

                'Summon Candle',
                'Unholy Revival'
            ],
            startingSpells: ['Move', 'Melee Attack', 'Block'],
            combatStartQuotes: ['The cavalry is here!', 'Break their ranks!'],
            killQuotes: ['Justice was served!', 'Be honored to die by my blade.'],
            sayOffsetX: 2,
            sayOffsetY: -5,
            audio: {
                onHit: 'Human2Audio',
                onDeath: 'Human1Audio'
            }
        },
        {   name: 'Ranger',
            thumbnailPath: 'Icons/Small/Ranger.png',
            stats: {
                health: 15,
                damage: 10,
                crit: 5,
                dodge: 5,
                initiative: 99,
                mana: 10,
                spellPower: 7,
                speed: 2,
                manaRegeneration: 5
            },
            startingSpells: ['Move', 'Shoot Arrow', 'Throw Net'],
            availableSpells: [
                'Fox Attack',
                'Triple Arrow',
                'Flare Shot',
                'Bear Trap',
                'Disorient',
                'Cobra Shot',
                'Crystal Arrow',
                'Bola Shot',
                'Firrow',
                
                'Quickfoot',
                'Fox Companion',
                'Steady Shooting',
                'Longdraw',
                
                
                'Rabbit Foot',
                'Time Warp',
                'Momentum Magic',
                'Everblocker',
                'Hero Health',
                'Elementulus',
                'Flaming Passion',
                'Electric Vibe',
                'Cold Stare',
                'Dark Thoughts',
                'Fire Heart',
                'Winter Wonder',
                'Iron Deficiency',
                'Meditator',
                
                'Boom Barrel',

                'Summon Candle',
                'Unholy Revival'
            ],
            combatStartQuotes: ["Ready yourselves!", "I've got the beast in my sights."],
            killQuotes: ["Right between the eyes.", "One shot, one kill.", "Another one bites the dust.", "Shoot to kill!"],
            rogueQuotes: [],
            mageQuotes: [],
            audio: {
                onHit: 'RangerHitAudio',
                onDeath: 'RangerDeathAudio'
            }
        },
        {   name: 'Mage',
            thumbnailPath: 'Icons/Small/Mage.png',
            stats: {
                health: 14,
                damage: 5,
                initiative: 99,
                mana: 10,
                spellPower: 10,
                manaRegeneration: 5,
                speed: 2
            },
            availableSpells: [
                'Blink',
                'Poswap',
                'Mana Ward',
                'Ice Cube',
                'Ignite',
                'Obstacle Focus',
                'Frost Nova',
                'Iceberg Drop',
                'Fire Ball',
                'Flame Dagger',

                'Shocking Startup',
                'Flex Arrow',

                'Rabbit Foot',
                'Time Warp',
                'Momentum Magic',
                'Everblocker',
                'Hero Health',
                'Elementulus',
                'Fire Heart',
                'Winter Wonder',
                'Iron Deficiency',
                'Meditator',

                'Summon Candle',
                'Unholy Revival'
            ],
            startingSpells: ['Move', 'Magic Arrow', 'Siphon Mana'],
            combatStartQuotes: ['My magic will tear you apart!'],
            killQuotes: ['Vanished!'],
            audio: {
                onHit: 'MageHitAudio',
                onDeath: 'MageDeathAudio'
            }
        }
    ];
}

class CharacterClassDatabase
{	
	public static var classesByName	: Map<String, CharacterClass>;
	public static var classesById	: Array<CharacterClass>;


	public static function get(?id : Int, ?name : String) {
		if (id != null) {
			return classesById[id];
		} else {
			return classesByName[name];
		}
	}
	
	public static function load(){
		classesByName = new Map<String, CharacterClass>();
		classesById	= [];
		var classes : Array<Dynamic> = null;
        try {
            // classes = readJSON("Databases/CharacterClasses.json");	// Array of UnitTemplate
            classes = CharacterClassDatabase_Classes.classes;
        } catch (e : String) {
            trace('ERROR: Failed to load CharacterClass database. Error is: ${e}');
        }
        for(c in classes){
            var characterClass = CharacterClass.createFromDynamic(c);
            characterClass.id = classesById.length;
            classesById.push(characterClass);
            classesByName[characterClass.name] = characterClass;
        }
		//trace('Loaded classes...');
	}

    

}