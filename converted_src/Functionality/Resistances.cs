using System;





// Damage taken is MULTIPLIED by resistance
// E.g. 1.5 FIRE Resistance = takes 50% EXTRA damage from fire
// E.g. 0.7 FIRE Resistance = takes 30% LESS damage from fire
public class Resistances
{
	
    double fire = 1.0;
    double cold = 1.0;
    double dark = 1.0;
    double shock = 1.0;

    Resistances(Resistances ?r) {
        if (r != null) copy(r);
    }

    static function CreateFromDynamic(Dynamic r) {
        var resistances = new Resistances();
        if (r.fire != null) resistances.fire = r.fire;
        if (r.cold != null) resistances.cold = r.cold;
        if (r.dark != null) resistances.dark = r.dark;
        if (r.shock != null) resistances.shock = r.shock;
        return resistances;
    }

    static function CreateFromDynamicForItem(Dynamic r) {
        var resistances = new Resistances();
        resistances.fire = if (r.fire != null) r.fire else 0;
        resistances.cold = if (r.cold != null) r.cold else 0;
        resistances.dark = if (r.dark != null) r.dark else 0;
        resistances.shock = if (r.shock != null) r.shock else 0;
        return resistances;
    }

    function ToDynamic() {
        return {
            fire fire,
            cold cold,
            dark dark,
            shoc shockk
        }
    }

    function Copy(Resistances r) {
        fire = r.fire;
        cold = r.cold;
        dark = r.dark;
        shock = r.shock;
    }
    Resistances Clone() {
        return new Resistances(this);
    }

    double Get(int damageType) {
        switch (damageType) {
            case FIRE: return fire;
            case COLD: return cold;
            case DARK: return dark;
            case SHOCK: return shock;
            default: return 1.0;
        }
    }
    void Add(Resistances r) {
        fire += r.fire;
        cold += r.cold;
        dark += r.dark;
        shock += r.shock;
    }
    void Subtract(Resistances r) {
        fire -= r.fire;
        cold -= r.cold;
        dark -= r.dark;
        shock -= r.shock;
    }

    public static string[] Keys() {
		return new string[] { "fire", "cold", "dark", "shock" };
	}

    public function ForEach(Action<string, double> func){
		var statNames = keys();
		double[] statValues = { fire, cold, dark, shock };
		for (int i = 0; i < statNames.length; i++){
			func(statNames[i], statValues[i]);
		}
	}

}