

package scripts;

typedef NonCombatEventOptionDynamic = {
    var title: String;
    var description: String;
    var onChoose: Void -> Void;
    var ?appearCondition: Void -> Bool;
}

typedef NonCombatEventDynamic = {
    var name: String;
    var init: (Void -> Void) -> Void;
    var ?appearCondition: Void -> Bool;
    var ?preventCharacterDrawing: Bool;
    var options: Array<NonCombatEventOptionDynamic>;
}