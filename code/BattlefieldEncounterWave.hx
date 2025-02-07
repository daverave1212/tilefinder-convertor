
package scripts;

import U.*;

// Child class of BattlefieldEncounter. Needed a separate file to be visible in Battlefield.hx.
class BattlefieldEncounterWave {

    public var battlefieldEncounter : BattlefieldEncounter;

    public var background : String; // Without path, just e.g. Cave, Forest, etc

    public var playerPositions : Array<Position>;
    
    public var enemyNames : Array<String>;
    public var enemyPositions : Array<Position>;

    public var trapNames : Array<String>;
    public var trapPositions : Array<Position>;

    public var isTutorial = false;

    public var events = {
        start:  [function(): Void {}],   // To signal to the compiler it's an array of Void->Void functions. The array is overwritten when reading database.
        end:    [function(): Void {}],   // End events trigger each and the user advances them with clicks
        begin:  function(): Void {},     // Begin triggers once, no wait
        finish: function(): Void {}      // Finish triggers once, no wait
    }

    public function new(battlefieldEncounter){
        if (battlefieldEncounter == null) trace('ERROR: Null battlefieldEnc given to BattlefieldEncounterWave');
        this.battlefieldEncounter = battlefieldEncounter;
    }

    public inline function hasTraps() return trapNames != null && trapNames.length > 0;
    public inline function getStartDialoguesCopy() return this.events.start.copy();
    public inline function getBackgroundImagePath() return 'Images/Backgrounds/${background}.png';
    public inline function hasStartEvents() return events.start.length > 0;

    public static function createFromDynamic(wave : Dynamic, battlefieldEncounter : BattlefieldEncounter, waveIndex : Int = -1) {
        function error(msg) {
            var encounterName = battlefieldEncounter.name;
            trace('ERROR: BattlefieldEncounterWave createFromDynamic error at encounter named $encounterName, wave number $waveIndex');
            trace('Error message: $msg');
            throwAndLogError(msg + ' (see logs)');
        }
        
        if (wave.background == null) error('Null background given');

        var w = new BattlefieldEncounterWave(battlefieldEncounter);
        
        w.background = wave.background;
        if (wave.isTutorial != null) w.isTutorial = wave.isTutorial;
        if (wave.board == null) error('No board given to the encounter');

        w.playerPositions = [];
        w.enemyNames = [];
        w.enemyPositions = [];
        w.trapNames = [];
        w.trapPositions = [];
        var board : Array<Array<String>> = cast wave.board;
        var skipNext = false;   // Used to skip the next tile if the unit is large
        for (i in 0...board.length) {
            for (j in 0...board[i].length) {
                if (skipNext) {
                    skipNext = false;
                    continue;
                }
                var slot = board[i][j];
                if (BattlefieldEncounterDatabase.isShorthand(slot))
                    slot = BattlefieldEncounterDatabase.getShorthandMeaning(slot);
                if (wave.shorthands != null) {
                    var shorthands : Map<String, String> = cast wave.shorthands;
                    if (shorthands.exists(slot)) {
                        slot = shorthands[slot];
                    }
                }
                if (slot == '_' || slot == '__' || slot == '  ' || slot == ' ') continue;
                if (slot == 'Player' || slot == 'P' || slot == 'Pl') {
                    w.playerPositions.push(new Position(i, j));
                    continue;
                }
                if (UnitsDatabase.unitExists(slot)) {
                    w.enemyNames.push(slot);
                    w.enemyPositions.push(new Position(i, j));
                    if (UnitsDatabase.get(slot).isLarge)
                        skipNext = true;
                } else if (Trap.database.trapExists(slot)) {
                    w.trapNames.push(slot);
                    w.trapPositions.push(new Position(i, j));
                } else {
                    error('No trap, unit or symbol "${slot}" found.');
                }
            }
        }



        if (wave.events != null) {
            if (wave.events.start != null) {
                var eventFunctions: Array<Void->Void> = cast wave.events.start;
                w.events.start = [for (f in eventFunctions) f];
            } else {
                w.events.start = [];
            }
            if (wave.events.end != null) {
                var eventFunctions: Array<Void->Void> = cast wave.events.end;
                w.events.end = [for (f in eventFunctions) f];
            } else {
                w.events.end = [];
            }
            if (wave.events.finish != null) {
                w.events.finish = wave.events.finish;
            }
            if (wave.events.begin != null) {
                w.events.begin = wave.events.begin;
            }
        }

        // if (wave.events != null && wave.events.startDialogue != null) {
        //     var dialogues : Array<Dynamic> = cast wave.events.startDialogue;
        //     w.events.startDialogue = [for (d in dialogues) BattlefieldDialogueEvent.createFromDynamic(d)];
        // } else {
        //     w.events.startDialogue = [];
        // }

        return w;

    }

}