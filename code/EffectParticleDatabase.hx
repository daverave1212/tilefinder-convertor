
package scripts;

import com.stencyl.Engine;

import U.*;
import scripts.Constants.*;
using U;

/*
 *      How to create a particle:
 *  - Add it here
 *  - Create an animation for its actor SpecialEffectActor with the same name
 *  - Play it with Effects.playParticleAndThen(fromPoint, atPoint, name, duration, callback)
 */

class EffectParticleDatabase_Particles {
    public static var particles: Array<Dynamic> = [
        {   spellName: 'Crescent Darkness',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/CrescentDarkness.png',
            sizeMin: 0.5,
            sizeMax: 1.25,
            hasRandomRotation: true,
            rotationSpeed: 8,
            imageLifetime: 1000,
            direction: 90,
            directionVariance: 120,
            speedMin: 10,
            speedMax: 19,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: 'Sparks',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/LightningParticle.png',
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 0.5,
            imageLifetime: 3000,
            direction: 90,
            directionVariance: 120,
            speedMin: 2,
            speedMax: 3,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Sand",
            radius: 10,
            frequency: 100,
            imagePath: "Images/Particles/Sand.png",
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 0,
            imageLifetime: 1000,
            direction: 90,
            directionVariance: 32,
            speedMin: 80,
            speedMax: 130,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.1
        },
        {   spellName: 'Snowflakes',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/Snowflake2.png',
            sizeMin: 0.8,
            sizeMax: 1.25,
            hasRandomRotation: false,
            rotationSpeed: 0,
            imageLifetime: 3000,
            direction: 90,
            directionVariance: 120,
            speedMin: 10,
            speedMax: 19,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Acid",
            radius: 20,
            frequency: 200,
            imagePath: "Images/Particles/Acid.png",
            sizeMin: 1,
            sizeMax: 2,
            hasRandomRotation: false,
            rotationSpeed: 2,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 78,
            speedMin: 25,
            speedMax: 50,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.1
        },
        {   spellName: "Lightning Blast",
            radius: 10,
            frequency: 100,
            imagePath: "Images/Particles/LightningParticle.png",
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 0,
            imageLifetime: 1000,
            direction: 90,
            directionVariance: 32,
            speedMin: 80,
            speedMax: 130,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.1
        },
        {   spellName: "Dirt",
            radius: 60,
            frequency: 100,
            imagePath: "Images/Particles/Dirt.png",
            sizeMin: 0.75,
            sizeMax: 2,
            hasRandomRotation: true,
            rotationSpeed: 0,
            imageLifetime: 1000,
            direction: 90,
            directionVariance: 78,
            speedMin: 180,
            speedMax: 180,
            opacityStart: 1,
            opacityEnd: 0.35,
            gravityX: 0,
            gravityY: 0.2
        },
        {   spellName: "Vomit",
            radius: 25,
            frequency: 200,
            imagePath: "Images/Particles/Puke.png",
            sizeMin: 0.25,
            sizeMax: 0.5,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 650,
            direction: 15,
            directionVariance: 15,
            directionSpreads: true,
            speedMin: 150,
            speedMax: 200,
            opacityStart: 1,
            opacityEnd: 0.35,
            gravityX: 0.05,
            gravityY: 0.09
        },
        {   spellName: 'Green Smoke',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/GreenSmokeParticle.png',
            sizeMin: 0.9,
            sizeMax: 1.1,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 120,
            speedMin: 10,
            speedMax: 19,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Bat Explosion",
            radius: 10,
            frequency: 100,
            imagePath: "Images/Particles/BatParts.png",
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 0,
            imageLifetime: 1000,
            direction: 90,
            directionVariance: 32,
            speedMin: 80,
            speedMax: 130,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.1
        },
        {   spellName: "Crystal Shards",
            radius: 20,
            frequency: 100,
            imagePath: "Images/Particles/CrystalShard.png",
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 0,
            imageLifetime: 1000,
            direction: 90,
            directionVariance: 78,
            speedMin: 60,
            speedMax: 100,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.1
        },
        {   spellName: 'Drain Mana',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/Magic Arrow Particle.png',
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 1.5,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 120,
            speedMin: 10,
            speedMax: 18,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: 'Laser',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/LaserParticle.png',
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 1.5,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 120,
            speedMin: 10,
            speedMax: 18,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Splash",
            radius: 37,
            frequency: 100,
            imagePath: "Images/Particles/Splash.png",
            sizeMin: 0.5,
            sizeMax: 2,
            hasRandomRotation: true,
            rotationSpeed: 0,
            imageLifetime: 1000,
            direction: 90,
            directionVariance: 78,
            speedMin: 180,
            speedMax: 180,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.2
        },
        {   spellName: 'Marceline Teleport',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/SkullParticle.png',
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 1.5,
            imageLifetime: 3000,
            direction: 90,
            directionVariance: 180,
            speedMin: 7,
            speedMax: 14,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: 'Charm',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/CharmParticle.png',
            sizeMin: 1,
            sizeMax: 2,
            hasRandomRotation: false,
            rotationSpeed: 0,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 120,
            speedMin: 4,
            speedMax: 12,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: 'Slow Down',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/TuberculosisParticle.png',
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 1.5,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 120,
            speedMin: 7,
            speedMax: 14,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: 'Spores',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/Spore.png',
            sizeMin: 0.5,
            sizeMax: 1.75,
            hasRandomRotation: true,
            rotationSpeed: 1.5,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 120,
            speedMin: 7,
            speedMax: 14,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Tuberculosis",
            radius: 55,
            frequency: 200,
            imagePath: "Images/Particles/TuberculosisParticle.png",
            sizeMin: 0.5,
            sizeMax: 1.5,
            hasRandomRotation: false,
            rotationSpeed: 2,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 180,
            speedMin: 0,
            speedMax: 5,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Circular Fire",
            radius: 20,
            frequency: 200,
            imagePath: "Images/Particles/Fire Ball Particle.png",
            sizeMin: 1,
            sizeMax: 2,
            hasRandomRotation: false,
            rotationSpeed: 2,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 78,
            speedMin: 25,
            speedMax: 50,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: -0.1
        },
        {   spellName: 'Restore Mana',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/Magic Arrow Particle.png',
            sizeMin: 0.9,
            sizeMax: 1.1,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 120,
            speedMin: 10,
            speedMax: 19,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: 'Toxic Smoke',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/ToxicSmokeParticle.png',
            sizeMin: 0.9,
            sizeMax: 1.1,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 120,
            speedMin: 10,
            speedMax: 19,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Damned Aura",
            radius: 13,
            frequency: 100,
            imagePath: "Images/Particles/Damned Aura.png",
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: false,
            rotationSpeed: 0,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 25,
            speedMin: 117,
            speedMax: 150,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: -0.05,
            hasRandomHorizontalFlip: true
        },
        {   spellName: "Disorient",
            radius: 37,
            frequency: 100,
            imagePath: "Images/Particles/FlareYellowParticle.png",
            sizeMin: 1,
            sizeMax: 2,
            hasRandomRotation: true,
            rotationSpeed: 0,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 78,
            speedMin: 117,
            speedMax: 150,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.2
        },
        {   spellName: "Flare",
            radius: 37,
            frequency: 100,
            imagePath: "Images/Particles/FlareParticle.png",
            sizeMin: 1,
            sizeMax: 2,
            hasRandomRotation: true,
            rotationSpeed: 0,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 78,
            speedMin: 117,
            speedMax: 150,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.2
        },
        {   spellName: "Spike Rush",
            radius: 37,
            frequency: 200,
            imagePath: "Images/Particles/Spike Rush Particle.png",
            sizeMin: 0.7,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 78,
            speedMin: 117,
            speedMax: 150,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.2
        },
        {   spellName: "Throw Rock Small",
            radius: 4,
            frequency: 200,
            imagePath: "Images/Particles/StalagmiteParticle.png",
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 500,
            direction: 90,
            directionVariance: 78,
            speedMin: 30,
            speedMax: 45,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.05
        },
        {   spellName: "Throw Rock",
            radius: 37,
            frequency: 200,
            imagePath: "Images/Particles/Rock.png",
            sizeMin: 0.25,
            sizeMax: 0.5,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 78,
            speedMin: 117,
            speedMax: 150,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.2
        },
        {   spellName: 'Smoke',
            radius: 12,
            frequency: 200,
            imagePath: 'Images/Particles/SmokeParticle.png',
            sizeMin: 0.9,
            sizeMax: 1.1,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 120,
            speedMin: 10,
            speedMax: 19,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Fire Ball",
            radius: 20,
            frequency: 200,
            imagePath: "Images/Particles/Fire Ball Particle.png",
            sizeMin: 1,
            sizeMax: 2,
            hasRandomRotation: false,
            rotationSpeed: 2,
            imageLifetime: 2000,
            direction: 90,
            directionVariance: 78,
            speedMin: 25,
            speedMax: 50,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0.1
        },
        {   spellName: "Chest Particles",
            radius: 15,
            frequency: 20,
            imagePath: "Images/Particles/ChestParticle.png",
            sizeMin: 0.5,
            sizeMax: 1,
            hasRandomRotation: false,
            rotationSpeed: 0,
            imageLifetime: 1433,
            direction: 92,
            directionVariance: 45,
            speedMin: 0,
            speedMax: 50,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Blood",
            radius: 25,
            frequency: 200,
            imagePath: "Images/Particles/Blood Particle.png",
            sizeMin: 0.25,
            sizeMax: 0.5,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 650,
            direction: 15,
            directionVariance: 15,
            directionSpreads: true,
            speedMin: 250,
            speedMax: 300,
            opacityStart: 1,
            opacityEnd: 0.2,
            gravityX: -0.05,
            gravityY: 0.09
          }
    ];
}

/*

    When adding a new entry to the effect particle database,
    it is automatically binded to that spell's effect (based on the effect actor's animation).
    The script that does this is inside the SpecialEffectActor

    {
        "spellName": "Healing Word",
        "radius": 14,
        "frequency": 20,
        "imagePath": "Images/Particles/Fire Ball Particle.png",
        "sizeMin": 0.45,
        "sizeMax": 1,
        "hasRandomRotation": true,
        "rotationSpeed": 2,
        "imageLifetime": 848,
        "direction": 0,
        "directionVariance": 0,
        "speedMin": 0,
        "speedMax": 0,
        "opacityStart": 1,
        "opacityEnd": 0,
        "gravityX": 0,
        "gravityY": 0
  }


*/


class EffectParticleDatabase
{
    
    public static var effectParticlesByName    : Map<String, Dynamic>;
    public static var effectParticlesById      : Array<Dynamic>;

    public static function get(?id : Int, ?name : String){
		if (id != null) {
			if (effectParticlesById[id] == null)
				trace('WARNING: No effect particle with id ${id} found.');
			return effectParticlesById[id];
		} else {
			if (effectParticlesByName[name] == null)
				trace('WARNING: No effect particle with name ${name} found.');
			return effectParticlesByName[name];
		}
    }

    public static function exists(?id : Int, ?name: String) {
        if (id != null && name == null) {
            return id >=0 && id < effectParticlesById.length;
        } else if (name != null && id == null) {
            return effectParticlesByName.exists(name);
        } else {
            trace('ERROR: Wrong parameters for EffectParticleDatabase.exists: id=$id, name=$name');
            return false;
        }
    }
    
    public static function load(){
		effectParticlesByName = new Map<String, Dynamic>();
		effectParticlesById	  = [];
		var effectParticles : Array<Dynamic> = null;
		try {
			// effectParticles = readJSON("Databases/EffectParticles.json");
            effectParticles = EffectParticleDatabase_Particles.particles;
		} catch(e : String) {
			trace("ERROR When loading json. Check that the JSON is syntactically correct");
			throw "ERROR";
		}
		//trace('Loaded JSON');
		if (effectParticles != null) trace("Successfully loaded EffectParticles.json");
		else trace("ERORR: Failed to load EffectParticles.json");
        
        for (p in effectParticles) {
			effectParticlesById.push(p);
			effectParticlesByName[p.spellName] = p;
			//trace('Pushed ${p.spellName}');
		}
	}
    

}