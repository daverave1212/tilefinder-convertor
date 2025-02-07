

package scripts;

import scripts.Constants.*;
import U.*;


class BattlefieldEncounter {

    public var id : Int;        // Set by BattlefieldEncounterDatabase

    public var name          = 'ERROR: No name set';
    public var animationName = 'Ship';
    public var description   = 'ERROR: No description set';
    public var level: Int;
    public var flipUnits: Bool = false;                 // If true, all units will be flipped horizontally at start
    public var flags: Array<String> = [];               // Used for stuff like special missions
    var afterCombatEvent: (Void -> Void) -> Void;       // Takes a callback; this function is called after the combat, before AfterCombat

    public var specificLoot: Array<String>;

    public var waves : Array<BattlefieldEncounterWave>;

    public var testDamageTaken: Void -> Int;            // For quick combat; this is the damage taken by the player if quick combat

    public function new(){}

    public function hasFlag(flag: String) {
        return flags.indexOf(flag) != -1;
    }
    public function doAfterCombatEventIfExists(andThen: Void -> Void) {
        if (afterCombatEvent != null) {
            afterCombatEvent(andThen);
        } else {
            andThen();
        }
    }
    public function isRescueMission() {
        return hasFlag('WHITE_FLAG') || hasFlag('GREEN_FLAG') || hasFlag('BLUE_FLAG');
    }

    public static function createFromDynamic(dyn : Dynamic) {
        function error(msg) {
            var encounterName = if (dyn == null) "NULL ENCOUNTER"
                                else if (dyn.name == null) "NULL NAME"
                                else dyn.name;
            trace('BattlefieldEncounter createFromDynamic error at encounter named ${encounterName}');
            trace('Error message: ${msg}');
            throwAndLogError(msg + ' (see logs)');
        }
        if (dyn == null) error('Null dyn given');
        if (dyn.name == null) error('Null name given');
        if (dyn.waves == null) error('Null waves given');
        if (dyn.waves.length == 0) error('The waves given to the encounter has length 0');


        var enc             = new BattlefieldEncounter();
        enc.name            = dyn.name;
        enc.animationName   = nullOr(dyn.animationName, 'Error');
        enc.description     = if (dyn.description == null) '' else dyn.description;
        enc.level           = dyn.level != null ? dyn.level : -1;
        enc.flipUnits       = dyn.flipUnits != null ? dyn.flipUnits : false;

        if (dyn.flags != null) enc.flags = dyn.flags;
        if (dyn.specificLoot != null) enc.specificLoot = dyn.specificLoot;
        if (dyn.afterCombatEvent != null) enc.afterCombatEvent = dyn.afterCombatEvent;

        enc.waves = []; 

        var waves : Array<Dynamic> = cast dyn.waves;
        for (i in 0...waves.length) {
            enc.waves.push(BattlefieldEncounterWave.createFromDynamic(waves[i], enc, i));
        }

        trace('Loaded "${enc.name}" with animation ${enc.animationName}');

        return enc;
    }

}