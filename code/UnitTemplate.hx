package scripts;

import U.*;

// This is what is held in the database as JSON
// To create a unit, see UnitDatabase.hx
// A UnitTemplate refers to non-player units in the game
class UnitTemplate
{

    public static inline var IMMUNE_TO_ACID_TRAP = 1;
    public static inline var UNIT_WOOD = 2;
    public static inline var UNIT_STONE = 3;
    public static inline var UNIT_FLAMABLE = 4;
    public static inline var UNIT_ICE = 5;
    public static inline var IMMUNE_TO_STUN = 6;
    public static inline var FEARFUL = 7;
    public static inline var NEUTRAL_WITH_HEALTH_BAR = 8;
    public static inline var HUMAN = 9;
    public static inline var IMMUNE_TO_ROOT = 10;
    public static inline var IMMUNE_TO_SILENCE = 11;
    public static inline var IMMUNE_TO_PUSH = 12;
    public static inline var ANIMAL = 13;
    public static inline var ENEMY_PLANT = 14;


    public static var alowedAITypes = [
        'brute',                // Moves closer to players and attacks
        'shooter',              // Moves/move-attacks if can. Otherwise, waits
        'horse',                // Moves/move-attacks if can. Otherwise, moves randomly
        'molotov-peasant',      // Throws molotov randomly. If enemy is too close, moves away.
        'canon',                // Always shoots a skill shot to the left. Does nothing else,
        'scared',               // If it can't attack an enemy, it runs away
        'restless',             // Always moves randomly before doing anything,
        'advancer'              // Like brute, but always moves before doing a NO_EFFECT spell
    ];

    public var name		        : String = "";
    public var description      : String = '';
    public var thumbnailPath    : String = 'Icons/Small/NotFound.png';
    public var animationUsed    : String = null;
    public var level            : Int = 1;
    public var stats	        : Stats;
    public var resistances      : Resistances;
    public var damageVariation  : Int = 0;          // If baseDamage is 5 and damageVariation is 2, then the actual damage is 5 - 7
	public var spells           : Array<String>;    // Holds the names of all spells it has
    public var id               : Int;              // Refers to its position in the database array
    public var isLarge          : Bool = false;     // If it's large, it takes 2 spots on the board
    public var isObstacle       : Bool = false;     // If it's obstacle, it has no health bar and takes no actions
    public var neverFlip        : Bool = false;     // If true and it's an obstacle, never spawn with random horizontal flip    

    public var offsetOnTileX    : Int = 0;          // Custom offset when on tile; optional
    public var offsetOnTileY    : Int = 0;          // Custom offset when on tile; optional
    public var isFlippedHorizontally: Bool = false; // The default flip of the unit
    public var doesFlipHorizontally: Bool = true;   // If true, it will not flip in combat
    
	public var combatStartQuotes    : Array<String>;
	public var killQuotes			: Array<String>;

    public var onDeath              : Unit -> Void;                     // Unit::kill <- Unit::doOnDeathEvent <- onDeath; happens BEFORE the unit dies
    public var afterDeath           : Unit -> TileSpace -> Void;        // Unit::kill <- Unit::doAfterDeathEvent <- onDeath; happens AFTER the unit dies
    public var afterTakingDamage    : Unit -> Int -> Void;              // Unit::damage <- afterTakingDamage
    public var onTakingDamage       : Unit -> Int -> Void;              // Unit::damage <- onTakingDamage
    public var onSpawn              : Unit -> Void;                     // Battlefield.spawnUnit <- Unit::doOnSpawnEvent <- onSpawn
    public var onTurnStart          : Unit -> Void;                     // Battlefield.nextTurn <- Unit::onTurnStart <- onTurnStart
    public var onTurnEnd            : Unit -> Void;                     // Battlefield.nextTurn <- Unit::onTurnEnd <- onTurnEnd
    public var onRoundEnd           : Unit -> Void;                     // BattlefieldEventDispatcher.doEndOfRoundEvents <- Unit.doOnRoundEndEvent -> onRoundEnd
    public var onCombatStart        : Unit -> Void;                     // BattlefieldEventDispatcher.doCombatStartEvents <- onCombatStart
    public var onStuck              : Unit -> (Void -> Void) -> Void;   // AI.moveCloserToAnyPlayerUnit <- Unit::doOnstuckEvent <- onStuck

    public var actorOffsetY         : Int = 0;
    public var actorOffsetX         : Int = 0;
    public var sayOffsetY         : Int = 0;
    public var sayOffsetX         : Int = 0;
    
    public var tags: Array<Int> = [];               // Used for all sorts of stuff

    public var ai: {
        type: String,
        spellSequence: Array<String>,
        overrideSpellSequence: Unit -> Int -> String                    // Self -> Current spell sequence index -> overriding spell name; if it returns null, it will just do its regular thing
    } = {
        type: 'brute',
        spellSequence: null,
        overrideSpellSequence: null                                     // This function is called by the AI and tries to cast the spell name it returns every turn instead of the unit's normal action
    };

    public var audio = {
        onHit: '',
        onDeath: ''
    }

    public function hasAudioOnHit() return audio.onHit != null && audio.onHit.length > 0;
    public function hasAudioOnDeath() { return audio.onDeath != null && audio.onDeath.length > 0; }

    public function new(n){
        name = n;
    }

    public function getXPAwarded() return Std.int(0.5  + 0.5 * level);

    public inline function getCombatStartQuotes() return combatStartQuotes.copy();
    public inline function getKillQuotes() return killQuotes.copy();

    public static function createFromDynamic(u : Dynamic) {
        var unitTemplate = new UnitTemplate(u.name);
        unitTemplate.damageVariation = if (u.damageVariation == null) 0 else u.damageVariation;
        unitTemplate.description = if (u.description == null) '' else u.description;
        unitTemplate.level = if (u.level == null) 1 else u.level;
        unitTemplate.animationUsed = if (u.animationUsed == null) null else u.animationUsed;
        unitTemplate.stats = Stats.createFromDynamic(u.stats);
        if (u.resistances != null) {
            unitTemplate.resistances = Resistances.createFromDynamic(u.resistances);
        } else {
            unitTemplate.resistances = new Resistances();
        }
        unitTemplate.spells = if (u.spells == null) [] else u.spells;
        unitTemplate.combatStartQuotes = if (u.combatStartQuotes == null) [] else u.combatStartQuotes;
        unitTemplate.killQuotes = if (u.killQuotes == null) [] else u.killQuotes;
        unitTemplate.isLarge = if (u.isLarge == null) false else u.isLarge;
        unitTemplate.isObstacle = if (u.isObstacle == null) false else u.isObstacle;
        unitTemplate.neverFlip = if (u.neverFlip == null) false else u.neverFlip;
        unitTemplate.isFlippedHorizontally = if (u.isFlippedHorizontally == null) false else u.isFlippedHorizontally;
        unitTemplate.doesFlipHorizontally = if (u.doesFlipHorizontally == null) true else u.doesFlipHorizontally;

        if (u.thumbnailPath == 'auto' || u.thumbnailPath == null) {
            final thumbnailPath = 'Icons/Small/${u.name}.png';
            if (ImageX.imageExists(thumbnailPath))
                unitTemplate.thumbnailPath = thumbnailPath;
            else
                unitTemplate.thumbnailPath = 'Icons/Small/NotFound.png';
        } else {
            unitTemplate.thumbnailPath = u.thumbnailPath;
        }

        if (u.ai != null) {
            if (u.ai.type != null) {
                if (alowedAITypes.indexOf(u.ai.type) == -1)
                    throwAndLogError('Given AI type "${u.ai.type}" to unit "${u.name}" is invalid.');
                unitTemplate.ai.type = u.ai.type;
            }
            unitTemplate.ai.spellSequence = if (u.ai.spellSequence != null) u.ai.spellSequence else null;
            unitTemplate.ai.overrideSpellSequence = if (u.ai.overrideSpellSequence != null) u.ai.overrideSpellSequence else null;
        }
        
        unitTemplate.offsetOnTileX = if (u.offsetOnTileX == null) 0 else u.offsetOnTileX;
        unitTemplate.offsetOnTileY = if (u.offsetOnTileY == null) 0 else u.offsetOnTileY;

        unitTemplate.onDeath = if (u.onDeath == null) null else u.onDeath;
        unitTemplate.afterDeath = if (u.afterDeath == null) null else u.afterDeath;
        unitTemplate.onRoundEnd = if (u.onRoundEnd == null) null else u.onRoundEnd;
        unitTemplate.onTurnStart = if (u.onTurnStart == null) null else u.onTurnStart;
        unitTemplate.onTurnEnd = if (u.onTurnEnd == null) null else u.onTurnEnd;
        unitTemplate.onCombatStart = if (u.onCombatStart == null) null else u.onCombatStart;
        unitTemplate.onTakingDamage = if (u.onTakingDamage == null) null else u.onTakingDamage;
        unitTemplate.afterTakingDamage = if (u.afterTakingDamage == null) null else u.afterTakingDamage;
        unitTemplate.onStuck = if (u.onStuck == null) null else u.onStuck;
        unitTemplate.onSpawn = if (u.onSpawn == null) null else u.onSpawn;

        unitTemplate.tags = if (u.tags == null) null else u.tags;

        unitTemplate.actorOffsetY = if (u.actorOffsetY == null) 0 else u.actorOffsetY;
        unitTemplate.actorOffsetX = if (u.actorOffsetX == null) 0 else u.actorOffsetX;
        unitTemplate.sayOffsetY = if (u.sayOffsetY == null) 0 else u.sayOffsetY;
        unitTemplate.sayOffsetX = if (u.sayOffsetX == null) 0 else u.sayOffsetX;

        if (u.audio != null) {
            unitTemplate.audio.onHit = nullOr(u.audio.onHit, '');
            unitTemplate.audio.onDeath = nullOr(u.audio.onDeath, '');
        }
        return unitTemplate;
    }

}