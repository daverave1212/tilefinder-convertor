
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
import Math.*;

import scripts.Constants.*;
import scripts.UnitTemplate.*;

using U;

/*
    To create a trap in the battlefield, use Trap.createFromTemplate
    To use the database, use Trap.database.get(id | name)
*/

class Trap
{

    public var isTemplate   : Bool = false;         // This is only true if it's an object in the traps database
    public var id           : Int = -1;             // This only matters for templates

    public var name         : String = 'Bear Trap';
    public var animationNameRedirect: String = null;    // In case a trap has the same animation as another one
    public var description: String = '';
    public var tileOn       : TileSpace;
    public var uses         : Int = 1;
    public var age          : Int = 0;                  // Number of rounds it has survived
    public var isAlwaysOnTop: Bool = false;
    public var yOffset      : Int = 0;

    public var onStep       : Trap -> Unit -> Void;     // Trap = self
    public var onRoundEnd   : Trap -> Void;             // Trap = self
    public var onUnitStartTurn: Trap -> Unit -> Void;     // Trap = self

    public var actor        : Actor = null;

    public var customData   : Dynamic = null;           // Used in special cases for special effects

    public static var database = {
        load: () -> TrapDatabase.load(),
        get: (?id, ?name) -> TrapDatabase.get(id, name),
        trapExists: name -> TrapDatabase.trapsByName.exists(name)
    }

    private function new() {}
    public static function createFromTemplate(?template : Trap, ?templateName : String, tile : TileSpace) {
        if (template == null && templateName != null) {
            template = TrapDatabase.get(templateName);
        }
        var trap = new Trap();
        trap.name = template.name;
        trap.description = template.description;
        trap.animationNameRedirect = template.animationNameRedirect;
        trap.onStep = template.onStep;
        trap.onRoundEnd = template.onRoundEnd;
        trap.onUnitStartTurn = template.onUnitStartTurn;
        trap.uses = template.uses;
        trap.isAlwaysOnTop = template.isAlwaysOnTop;
        trap.yOffset = template.yOffset;
        trap.actor = U.createActor('TrapActor', if (template.isAlwaysOnTop) 'OverUnits' else 'BehindUnits');
        trap.actor.setAnimation(if (template.animationNameRedirect != null) template.animationNameRedirect else template.name);
        trap.putOnTile(tile);
        Battlefield.trapsOnBattlefield.push(trap);
        return trap;
    }
    public static inline function createFromTemplateByName(templateName: String, tile) {
        return createFromTemplate(null, templateName, tile);
    }
    public static function createTemplateFromDynamic(obj : Dynamic) {
        var trap = new Trap();
        trap.name = obj.name;
        trap.description = obj.description;
        trap.onStep = obj.onStep;
        trap.onRoundEnd = obj.onRoundEnd;
        trap.onUnitStartTurn = obj.onUnitStartTurn;
        trap.isAlwaysOnTop = if (obj.isAlwaysOnTop != null) obj.isAlwaysOnTop else false;
        if (obj.yOffset != null) trap.yOffset = obj.yOffset;
        if (obj.animationNameRedirect != null) trap.animationNameRedirect = obj.animationNameRedirect;
        trap.uses = obj.uses;
        return trap;
    }

    public function putOnTile(tile : TileSpace) {
        if (tile == null) throwAndLogError('Null tile given to Trap.putOnTile');
        if (tile.hasTrap()) throw 'Tile ${tile.toString()} already has a trap on it: ${tile.trapOnIt.name}';
        var targetX = tile.getXCenter() - actor.getWidth() / 2;
        var targetY = tile.getY() + tile.getHeight() - actor.getHeight() - TileSpace.k.unitFeetSpace + yOffset;
        actor.setX(targetX);
        actor.setY(targetY);
        if (tileOn != null) {
            tileOn.trapOnIt = null;
        }
        tileOn = tile;
        tile.trapOnIt = this;
    }
    public function isDead() return tileOn == null;
    public function kill() {
        if (isDead()) return;
        tileOn.trapOnIt = null;
        tileOn = null;
        recycleActor(actor);
    }

    public function trigger(unit : Unit) {
        if (onStep != null) {
            onStep(this, unit);
        }
        uses--;
        if (uses == 0) kill();
    }
    public inline function hasOnUnitStartTurnEvent() return onUnitStartTurn != null;

    public function getCenterPoint() return new Point(actor.getXCenter(), actor.getYCenter());
    public function getXCenter() return actor.getXCenter();
    public function getYCenter() return actor.getYCenter();
    public function getI() return tileOn.getI();
    public function getJ() return tileOn.getJ();

    public function toSymbolString() {
        if (name == null) return '??';
        if (name.length >= 2) {
            return name.substring(0, 2);
        } else {
            return name;
        }
    }
}



class TrapDatabase_Traps {
    public static var traps: Array<Dynamic> = [
        {   name: 'Sand Pile',
            description: 'INFECTS a random spell when you step on it.',
            nUses: 1,
            onStep: (self: Trap, unit: Unit) -> {
                unit.playEffect('Sand');
                unit.infectRandomUninfectedSpell();
                self.kill();
            }
        },
        {   name: "Meat",
            description: 'If a Hell Hound steps on it, the Hell Hound grows. If something else steps on it, it takes 5 PURE damage.',
            uses: 1,
            onStep: (self: Trap, unit: Unit) -> {
                if (unit.name == 'Hell Hound') {
                    SpellDatabase.growWaterElemental(unit);
                } else {
                    unit.damage(5, PURE);
                }
                self.kill();
            }
        },
        {   name: "Bear Trap",
            description: 'Deals 4 PHYSICAL damage to whoever steps on it.',
            uses: 1,
            onStep: (self: Trap, unit: Unit) -> {
                playAudio('BearTrapAudio');
                unit.damage(4, PHYSICAL);
            }
        },
        {   name: "Spine Skull Corpse",
            description: 'Corpse of a Spine Skull. Revives soon if there are other enemies left. Unless...',
            uses: 999,
            onStep: (self: Trap, unit: Unit) -> {},  // Does nothing
            onRoundEnd: function(self: Trap) {
                self.customData.turnsRemaining --;  // Default is 3, made from UnitsDatabase, Spine Skull;
                if (self.customData >= 1) return;
                if (self.tileOn.hasUnit()) return;
                final willRevive = Battlefield.getAllAliveEnemyUnits().length > 0;
                if (!willRevive) return;
                final ss = Battlefield.spawnEnemyOnTile('Spine Skull', self.tileOn);
                U.flashWhite(ss.actor, 550);
                ss.growTo(1.5, 0.5, 0.01, () -> {
                    ss.growTo(0.8, 1.2, 0.25, () -> {
                        ss.growTo(1, 1, 0.25);
                    });
                });
                self.tileOn.playEffect('Smoke');
                self.kill();
                playAudio('SummonSpiritAudio');
            }
        },
        {   name: "Ranger Bear Trap",
            description: 'Deals damage to the first unit that steps on it.',
            animationNameRedirect: 'Bear Trap',
            uses: 1,
            onStep: (self: Trap, unit: Unit) -> {
                if (self.customData == null) throwAndLogError('Ranger Bear Trap: customData is null!');
                if (self.customData.damageDoneOnTrigger == null) throwAndLogError('Ranger Bear Trap: customData.damageDoneOnTrigger is null!');
                unit.damage(self.customData.damageDoneOnTrigger, PHYSICAL);
            }
        },
        {   name: "Muffin Trap",
            description: 'If Big Boyo steps on it, Big Boyo grows. If anyone else steps on it, it takes damage.',
            uses: 1,
            onStep: (self: Trap, unit: Unit) -> {
                if (self.customData == null) throwAndLogError('Muffin Trap: customData is null!');
                if (self.customData.damageDoneOnTrigger == null) throwAndLogError('MuffinTrap: customData.damageDoneOnTrigger is null!');
                if (unit.name == 'Big Boyo' || unit.name == 'Big Boyo Wasp') {
                    unit.growToScale(unit.actorScale + 0.25);
                    unit.stats.damage += 1;
                } else {
                    unit.damage(self.customData.damageDoneOnTrigger, PHYSICAL);
                }
            }
        },
        {   name: "Acid Trap",
            description: 'Deals 3 damage and lowers ARMOR by 25% if the target has more than 0%.',
            uses: 2,
            onStep: function(self: Trap, unit: Unit): Void {
                if (unit.hasTag(IMMUNE_TO_ACID_TRAP)) return;
                unit.damage(3, PURE);
                if (unit.stats.armor > 0) {
                    unit.stats.armor -= 25;
                }
            }
        },
        {   name: "Oil",
            uses: 2,
            description: 'Ignites when hit with FIRE. Molotov Cocktails ignite nearby Oil puddles.',
            onStep: function(self: Trap, unit: Unit): Void {
                // Does nothing
            }
        },
        {   name: 'Spike Trap',
            description: 'Every 2 turns, it triggers, dealing 3 PHYSICAL damage to the unit on it.',
            uses: 99,
            onStep: (self: Trap, unit: Unit) -> {},
            yOffset: 4,
            onRoundEnd: (self: Trap) -> {
                if (self.actor.getAnimation() == 'Spike Trap None') {
                    self.actor.setAnimation('Spike Trap');
                } else if (self.actor.getAnimation() == 'Spike Trap') {
                    self.actor.setAnimation('Spike Trap Up');
                    if (!self.isDead() && self.tileOn.hasUnit()) {
                        playAudio('SpikeTrapAudio');
                        self.tileOn.unitOnIt.damage(3, PHYSICAL);
                    }
                    doAfter(500, () -> self.actor.setAnimation('Spike Trap None'));
                }
            }
        },
        {   name: 'Thorns Trap',
            description: 'Deals 3 PURE damage to whoever steps on it.',
            uses: 99,
            onStep: (self: Trap, unit: Unit) -> { unit.damage(3, PURE); }
        },
        {   name: 'Fire',
            description: 'Deals 3 FIRE damage when you step on it and if you start your turn on it. Lasts up to 3 turns.',
            uses: 99,
            onStep: (self: Trap, unit: Unit) -> {
                unit.damage(3, FIRE);
            },
            onUnitStartTurn: (self: Trap, unit: Unit) -> {
                unit.damage(3, FIRE);
            },
            onRoundEnd: (self: Trap) -> {
                if (self.age >= 4) {
                    self.kill();
                }
            }
        },
        {   name: 'Toxic Fog',
            description: 'Deals 3 PURE damage if you step on it. Has a chance to spread every turn. Lasts for up to 3 turns.',
            uses: 99,
            isAlwaysOnTop: true,
            onUnitStartTurn: (self: Trap, unit: Unit) -> {
                unit.damage(3, PURE);
            },
            onRoundEnd: (self: Trap) -> {
                if (percentChance(35) && self.age >= 2) {
                    final neighbors = self.tileOn.getNeighbors();
                    final freeNeighbors = neighbors.filter(tile -> tile.hasTrap() == false);
                    if (freeNeighbors.length == 0)
                        return;
                    final chosenTile: TileSpace = randomOf(freeNeighbors);
                    final spawnedTrap = Battlefield.spawnTrap('Toxic Fog', chosenTile.getI(), chosenTile.getJ());
                    final centerPoint = spawnedTrap.getCenterPoint();
                    Effects.playParticleAndThen(centerPoint, centerPoint, 'Toxic Smoke', 150, () -> {});
                    spawnedTrap.age = -1;   // To prevent overspawning
                }
                if (self.age >= 4) {
                    final centerPoint = self.getCenterPoint();
                    Effects.playParticleAndThen(centerPoint, centerPoint, 'Toxic Smoke', 150, () -> {});
                    self.kill();
                }
            }

        },
        {   name: "Bloodbath",
            description: 'Massively heals Spatula if he steps on it. If anyone else steps on it, the Bloodbath vanishes.',
            uses: 99,
            yOffset: 6,
            onStep: (self: Trap, unit: Unit) -> {
                if (unit.name != 'Count Spatula Unleashed') {
                    unit.playEffect('Blood');
                    self.kill();
                    return;
                }
                unit.heal(40);
                unit.playEffect('Lifesteal');
                self.kill();
            }
        },
        {   name: "Web",
            description: 'Reduces SPEED by 1 (unless you are an insect).',
            uses: 3,
            yOffset: 8,
            onStep: (self: Trap, unit: Unit) -> {
                if (unit.name == 'Big Boyo Wasp' || unit.name == 'Lil Munchy Centipede' || unit.name == 'Suzanna the Fair Spider') {
                    return;
                }
                unit.addBuff(new Buff('Web', 2, { speed: -1 }));
            }
        },


        {   name: "Pedestal",                        // Spawned by Tyl at the start of the combat
            description: 'Whatever this does, it can\'t be good...',
            uses: 999,                               // ... and all logic is implemented in Tyl
            onStep: (self: Trap, unit: Unit) -> {},  // Does nothing
            onRoundEnd: (self: Trap) -> {}           // Implemented in Tyl
        },
        {   name: "Silence Trap",
            description: 'SILENCES whoever steps on it.',
            uses: 1,
            onStep: (self: Trap, unit: Unit) -> {
                unit.playEffect('Silence', 1250);
                unit.silence();
            }
        },
        
    ];
}

class TrapDatabase {
    public static var trapsByName       : Map<String, Trap>;
    public static var trapsById         : Array<Trap>;

    public static function get(?id : Int, ?name : String){
		if (id != null) return trapsById[id];
		else return trapsByName[name];
    }
    public static function trapExists(trapName: String) return trapsByName.exists(trapName);
	public static function load(){
		trapsByName = new Map<String, Trap>();
		trapsById	= [];
		var templates : Array<Dynamic> = null;
        try {
            // templates = readJSON("Databases/Traps.json");	// Array of Trap
            templates = TrapDatabase_Traps.traps;
        } catch (e : String) {
            trace(e);
            trace('ERROR: Failed to load Trap database');
        }
        for(t in templates){
            var template = Trap.createTemplateFromDynamic(t);
            template.id = trapsById.length;
            trapsById.push(template);
            trapsByName[template.name] = template;
        }
		//trace('Loaded traps...');
	}
}