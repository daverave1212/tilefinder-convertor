

package scripts;

import U.*;
using U;

import scripts.Constants.*;

class BuffDatabase
{	
	public static var buffsByName	: Map<String, Buff>;
	public static var buffsById 	: Array<Buff>;


	public static function get(?id : Int, ?name : String){
		if(id != null){
			return buffsById[id];
		} else {
			return buffsByName[name];
		}
	}
	
	public static function load(){
		buffsByName = new Map<String, Buff>();
		buffsById	= [];
		var buffs : Array<Dynamic> = null;
        try {
            buffs = readJSON("Databases/Buffs.json");	// Array of Buff
        } catch (e : String) {
            throwAndLogError(e);
            throwAndLogError('Failed to load Buff database: ${e.toString()}');
        }
        for (c in buffs) {
            var buff = Buff.createFromDynamic(c);
            buff.id = buffsById.length;
            buffsById.push(buff);
            buffsByName[buff.name] = buff;
        }
		trace('Loaded buffs...');
	}

}