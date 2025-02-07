
package scripts;

import com.stencyl.Engine;

import U.*;
import scripts.Constants.*;
using U;

// These are automatically bound to the respectiev MissileActor animation name by spellName
class MissileParticleDatabase_Particles {
    public static var particles: Array<Dynamic> = [
        {   spellName: "Firrow",
            radius: 14,
            frequency: 20,
            imagePath: "Images/Particles/Fire Ball Particle.png",
            sizeMin: 0.45,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 848,
            direction: 0,
            directionVariance: 0,
            speedMin: 0,
            speedMax: 0,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Storm Spear",
            radius: 14,
            frequency: 20,
            imagePath: "Images/Particles/LightningParticle.png",
            sizeMin: 0.45,
            sizeMax: 1.25,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 848,
            direction: 0,
            directionVariance: 0,
            speedMin: 0,
            speedMax: 0,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Lightning Ball", 
            radius: 14,
            frequency: 20,
            imagePath: "Images/Particles/LightningParticle.png",
            sizeMin: 0.5,
            sizeMax: 1.5,
            hasRandomRotation: false,
            rotationSpeed: 0,
            imageLifetime: 848,
            direction: 0,
            directionVariance: 0,
            speedMin: 0,
            speedMax: 0,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Flare", 
            radius: 14,
            frequency: 20,
            imagePath: "Images/Particles/FlareParticle.png",
            sizeMin: 1,
            sizeMax: 2,
            hasRandomRotation: false,
            rotationSpeed: 0,
            imageLifetime: 848,
            direction: 0,
            directionVariance: 0,
            speedMin: 0,
            speedMax: 0,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Bubble", 
            radius: 14,
            frequency: 20,
            imagePath: "Images/Particles/Bubble.png",
            sizeMin: 0.2,
            sizeMax: 0.35,
            hasRandomRotation: false,
            rotationSpeed: 2,
            imageLifetime: 848,
            direction: 0,
            directionVariance: 0,
            speedMin: 0,
            speedMax: 0,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Molotov",
            radius: 14,
            frequency: 20,
            imagePath: "Images/Particles/Fire Ball Particle.png",
            sizeMin: 0.25,
            sizeMax: 0.5,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 848,
            direction: 0,
            directionVariance: 0,
            speedMin: 0,
            speedMax: 0,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Fire Ball",
            radius: 14,
            frequency: 20,
            imagePath: "Images/Particles/Fire Ball Particle.png",
            sizeMin: 0.45,
            sizeMax: 1,
            hasRandomRotation: true,
            rotationSpeed: 2,
            imageLifetime: 848,
            direction: 0,
            directionVariance: 0,
            speedMin: 0,
            speedMax: 0,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        },
        {   spellName: "Magic Arrow",
            radius: 14,
            frequency: 20,
            imagePath: "Images/Particles/Magic Arrow Particle.png",
            sizeMin: 0.65,
            sizeMax: 1,
            hasRandomRotation: false,
            rotationSpeed: 0,
            imageLifetime: 848,
            direction: 0,
            directionVariance: 0,
            speedMin: 0,
            speedMax: 0,
            opacityStart: 1,
            opacityEnd: 0,
            gravityX: 0,
            gravityY: 0
        }
    ];
}

/*

    When adding a new entry to the missile particle database,
    it is automatically binded to that spell's missile.
    The script that does this is inside the MissileActor

    {
        spellName: "Fire Ball",
        radius: 14,
        frequency: 20,
        imagePath: "Images/Particles/Fire Ball Particle.png",
        sizeMin: 0.45,
        sizeMax: 1,
        hasRandomRotation: true,
        rotationSpeed: 2,
        imageLifetime: 848,
        direction: 0,
        directionVariance: 0,
        speedMin: 0,
        speedMax: 0,
        opacityStart: 1,
        opacityEnd: 0,
        gravityX: 0,
        gravityY: 0
  }


*/

class MissileParticleDatabase
{
    
    public static var missileParticlesByName    : Map<String, Dynamic>;
    public static var missileParticlesById      : Array<Dynamic>;

    public static function get(?id : Int, ?name : String){
		if(id != null){
			if (missileParticlesById[id] == null)
				trace('WARNING: No missile particle with id ${id} found.');
			return missileParticlesById[id];
		} else {
			if(missileParticlesByName[name] == null)
				trace('WARNING: No missile particle with name ${name} found.');
			return missileParticlesByName[name];
		}
    }

    public static function exists(?id : Int, ?name: String) {
        if (id != null && name == null) {
            return id >=0 && id < missileParticlesById.length;
        } else if (name != null && id == null) {
            return missileParticlesByName.exists(name);
        } else {
            trace('ERROR: Wrong parameters for MissileParticleDatabase.exists: id=$id, name=$name');
            return false;
        }
    }
    
    public static function load(){
		missileParticlesByName = new Map<String, Dynamic>();
		missileParticlesById	 = [];
		var missileParticles : Array<Dynamic> = null;
		try{
			// missileParticles = readJSON("Databases/MissileParticles.json");
            missileParticles = MissileParticleDatabase_Particles.particles;
		} catch(e : String) {
			trace("ERROR When loading json. Check that the JSON is syntactically correct");
			throw "ERROR";
		}
		// trace('Loaded JSON');
		if(missileParticles != null) trace("Successfully loaded MissileParticles.json");
		else trace("ERORR: Failed to load MissileParticles.json");
        
        for(p in missileParticles){
			missileParticlesById.push(p);
			missileParticlesByName[p.spellName] = p;
			// trace('Pushed ${p.spellName}');
		}
	}
    

}