
package scripts;

import com.stencyl.Engine;

import scripts.Constants.*;
import Math.max;
import Std.int;

class PlayerMercenary {

    public var unitTemplate: UnitTemplate;
    public var health: Int;
    public var mana: Int;
	
    public function new (_unitTemplate: UnitTemplate) {
        unitTemplate = _unitTemplate;
        health = _unitTemplate.stats.health;
        mana = _unitTemplate.stats.mana;
    }

    public inline function getName() return unitTemplate.name;

}