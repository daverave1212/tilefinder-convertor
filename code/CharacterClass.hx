
package scripts;

import com.stencyl.Engine;
import U.*;

class CharacterClass
{

	public var name				: String;
	public var id				: Int;		// Its position in the CharacterClass array database
	public var thumbnailPath	: String = 'Icons/Small/NotFound.png';
	
	public var stats			: Stats;

	public var availableSpells 	: Array<String>;
	public var startingSpells	: Array<String>;

	public var combatStartQuotes : Array<String>;
	public var killQuotes : Array<String>;

	public var sayOffsetX: Float = 0;
	public var sayOffsetY: Float = 0;

	public var audio = {
		onHit: '',
		onDeath: ''
	}

	public function new(n){
		name = n;
		availableSpells = [];
		startingSpells = [];
	}


	public static function createFromDynamic(c : Dynamic){
		var characterClass = new CharacterClass(c.name);
		characterClass.stats = Stats.createFromDynamic(c.stats);
		characterClass.availableSpells = c.availableSpells;
		characterClass.startingSpells = c.startingSpells;
		characterClass.combatStartQuotes = c.combatStartQuotes;
		characterClass.killQuotes = c.killQuotes;
		if (c.audio != null) {
			characterClass.audio.onHit = nullOr(c.audio.onHit, '');
			characterClass.audio.onDeath = nullOr(c.audio.onDeath, '');
		}
		if (c.thumbnailPath != null) {
			if (c.thumbnailPath == 'auto') {
				characterClass.thumbnailPath = 'Icons/Small/${c.name}.png';
			} else {
				characterClass.thumbnailPath = c.thumbnailPath;
			}
		}
		if (c.sayOffsetX != null) characterClass.sayOffsetX = c.sayOffsetX;
		if (c.sayOffsetY != null) characterClass.sayOffsetY = c.sayOffsetY;
		return characterClass;
	}

}