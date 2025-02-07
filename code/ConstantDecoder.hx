
package scripts;


import U.*;
import scripts.Constants.*;

using U;

class ConstantDecoder
{
    public static init(){

    }

    public static inline function get(constantName : String){
        return decode[constantName];
    }



	decodeMissileSpeed = new Map<String, Int>();
    decodeMissileSpeed["FAST"]	 = Effects.FAST;
    decodeMissileSpeed["MEDIUM"] = Effects.MEDIUM;
    decodeMissileSpeed["SLOW"]	 = Effects.SLOW;
    decodeEffectType = new Map<String, Int>();
    decodeEffectType["NO_EFFECT"]	= NO_EFFECT;
    decodeEffectType["NORMAL_MOVE"] = NORMAL_MOVE;
    decodeEffectType["SKILL_SHOT"]	= SKILL_SHOT;
    decodeEffectType["ANY_ALLY"]	= ANY_ALLY;
    decodeEffectType["END_TURN"]	= END_TURN;
    decodeEffectType["TARGET_IN_RANGE"]	= TARGET_IN_RANGE;
    decodeDamageType = new Map<String, Int>();
    decodeDamageType["PHYSICAL"]	= PHYSICAL;
    decodeDamageType["FIRE"]		= FIRE;
    decodeDamageType["COLD"]		= COLD;
    decodeDamageType["DARK"]		= DARK;
    decodeDamageType["PURE"]		= PURE;

	public function new()
	{
	}
}