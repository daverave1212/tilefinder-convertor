package scripts;

import com.stencyl.Engine;

class MapNodeScaffold {
    public var type: String;
    public var state = 'UNAVAILABLE';
    public var nextNodesIndicesInNextTier: Array<Int>;
    public var options = {
        battlefieldEncounterName: ''
    }
    public function new(opts: Dynamic) {
        setOptionsFromDynamic(opts);
    }

    function setOptionsFromDynamic(given: Dynamic) {
        options.battlefieldEncounterName = given.battlefieldEncounterName != null? given.battlefieldEncounterName: '';
    }
}