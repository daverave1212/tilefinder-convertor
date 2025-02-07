
package scripts;

/*
    Buffs should be created dynamically. No need for a database.
*/
class Buff
{
    public var name : String = "Taco Cramps";
    public var stats : Stats;
    public var remainingDuration: Int = 99; // Duration 1 still triggers once; tick buffs happens on turn start

    public var onAdd: Unit -> Void;     // When buff is added to unit
    public var onRemove: Unit -> Void;  // When buff is removed from unit
    public var onTick: Unit -> Void;    // When buff ticks (on unit turn start)
    public var onTurnEnd: Unit -> Void; // On the turn end of the unit

    var _isImageValid = true;
    public function new(n, duration, ?_stats: Dynamic, ?events: Dynamic) {
        name = n;
        remainingDuration = duration;
        if (_stats == null) _stats = {};
        stats = Stats.createFromDynamic(_stats);
        if (events != null) {
            if (events.onAdd != null) onAdd = events.onAdd;
            if (events.onRemove != null) onRemove = events.onRemove;
            if (events.onTick != null) onTick = events.onTick;
            if (events.onTurnEnd != null) onTurnEnd = events.onTurnEnd;
        }
        if (ImageX.imageExists(getIconPath()) == false) {
            Game.q('ERROR: Image ${getIconPath()} does not exist!');
            _isImageValid = false;
        }
    }

    public inline function getIconPath() {
        if (_isImageValid)
            return 'Icons/Buffs/${name}.png';
        else
            return 'Icons/Buffs/Taco Cramps.png';
    }
}