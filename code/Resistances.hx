
package scripts;

import com.stencyl.Engine;

import scripts.Constants.*;

// Damage taken is MULTIPLIED by resistance
// E.g. 1.5 FIRE Resistance = takes 50% EXTRA damage from fire
// E.g. 0.7 FIRE Resistance = takes 30% LESS damage from fire
@:publicFields class Resistances
{
	
    var fire: Float = 1.0;
    var cold: Float = 1.0;
    var dark: Float = 1.0;
    var shock: Float = 1.0;

    function new(?r: Resistances) {
        if (r != null) copy(r);
    }

    static function createFromDynamic(r: Dynamic) {
        final resistances = new Resistances();
        if (r.fire != null) resistances.fire = r.fire;
        if (r.cold != null) resistances.cold = r.cold;
        if (r.dark != null) resistances.dark = r.dark;
        if (r.shock != null) resistances.shock = r.shock;
        return resistances;
    }

    static function createFromDynamicForItem(r: Dynamic) {
        final resistances = new Resistances();
        resistances.fire = if (r.fire != null) r.fire else 0;
        resistances.cold = if (r.cold != null) r.cold else 0;
        resistances.dark = if (r.dark != null) r.dark else 0;
        resistances.shock = if (r.shock != null) r.shock else 0;
        return resistances;
    }

    function toDynamic() {
        return {
            fire: fire,
            cold: cold,
            dark: dark,
            shock: shock
        }
    }

    function copy(r: Resistances) {
        fire = r.fire;
        cold = r.cold;
        dark = r.dark;
        shock = r.shock;
    }
    function clone(): Resistances {
        return new Resistances(this);
    }

    function get(damageType: Int): Float {
        switch damageType {
            case FIRE: return fire;
            case COLD: return cold;
            case DARK: return dark;
            case SHOCK: return shock;
            default: return 1.0;
        }
    }
    function add(r: Resistances) {
        fire += r.fire;
        cold += r.cold;
        dark += r.dark;
        shock += r.shock;
    }
    function subtract(r: Resistances) {
        fire -= r.fire;
        cold -= r.cold;
        dark -= r.dark;
        shock -= r.shock;
    }

    public static function keys() {
		return ['fire', 'cold', 'dark', 'shock'];
	}

	public function forEach(func : String -> Float -> Void) {
		var statNames = keys();
		var statValues: Array<Float> = [fire, cold, dark, shock];
		for (i in 0...statNames.length) {
			func(statNames[i], statValues[i]);
		}
	}

}