package scripts;

import com.stencyl.Engine;

import U.*;
import scripts.Constants.*;
import scripts.Pathing.*;

import Math.min;
import Std.int;

using scripts.Pathing;

// A static class which makes a unit take turns on the Battlefield.
class AI
{

    // -------------------------------- Base Func --------------------------------

	public static function takeTurnAndThen(unit : Unit, endTurn : Void -> Void) {
        trace('%% Taking turn with ${unit.name}');
        // An AI unit tries to use its spells in order of priority, left to right
        function chooseWhichSpellToUse(unit : Unit) {
            function isSpellUsable(spell: Spell): Bool {       // Returns the spell if it's usable; Otherwise, null
                if (spell.cooldownRemaining > 0) return false;
                if (unit.isSilenced() && spell.aiIsUsableWhileSilenced() == false) return false;
                switch (spell.getEffectType()) {
                    case END_TURN, NO_EFFECT, TIDAL_WAVE:
                        if (spell.getName() == 'Charm') {
                            return SpellDatabase.isCharmUsable(unit);
                        }
                        return true;
                    case ANY_ALLY:
                        if (spell.template.aiFlags.doesHeal) {
                            var damagedAllies = getDamagedUnitsOwnedByAI();
                            if (spell.effect().anyAlly.allowSelf == false) {
                                damagedAllies = damagedAllies.filter(u -> u != unit);
                            }
                            if (damagedAllies.length == 0) return false;
                            if (spell.getManaCost() > unit.mana) return false;
                            return true;
                        }
                    case SKILL_SHOT, SKILL_SHOT_SPLIT, MULTI_SKILL_SHOT:
                        if (canHitUnitWithOwnerWithSkillshot(unit, spell, PLAYER) != NO_DIRECTION) {
                            return true;
                        } else if (unit.hasSpell('Prop Breaker') && canHitUnitWithOwnerWithSkillshot(unit, spell, NEUTRAL) != NO_DIRECTION) {
                            return true;
                        } else if (canMoveToHitAPlayerWithSkillshot(unit, spell) != null) {
                            return true;
                        }
                    case SKILL_SHOT_GHOST:
                        trace('Checking can hit');
                        if (canHitUnitWithOwnerWithSpell(unit, spell, PLAYER)) {
                            trace('Yes, can hit with ghost from ${unit.tileOn.toString()}');
                            return true;
                        } else if (unit.hasSpell('Prop Breaker') && canHitUnitWithOwnerWithSpell(unit, spell, NEUTRAL)) {
                            return true;
                        } else if (canMoveToHitPlayerWithSpell(unit, spell) != null) {
                            trace('Yes, can MOVE to hit with ghost from ${unit.tileOn.toString()}');
                            return true;
                        }
                    case SKILL_SHOT_PIERCING:
                        if (canHitAPlayerWithSkillshotPiercing(unit, spell) != NO_DIRECTION)
                            return true
                        else if (canMoveToHitAPlayerWithSkillshotPiercing(unit, spell) != null)
                            return true;
                    case TILE_IN_RANGE, TARGET_IN_RANGE:
                        if (unit.getAIType() == 'molotov-peasant') return true;
                        if (canHitUnitWithOwnerWithSpell(unit, spell, PLAYER)) {
                            return true;
                        } else if (canMoveToHitPlayerWithSpell(unit, spell) != null) {
                            return true;
                        }
                    case AOE_AROUND:
                        if (canHitAtLeast2PlayersWithAOEAroundSpell(unit, spell)) {
                            return true;
                        } else if (canMoveToHitAtLeast2PlayersWithAOEAroundSpell(unit, spell) != null) {
                            return true;
                        }
                }
                return false;
            }
            if (unit.hasAISpellSequence()) {
                final sequenceSpellName = unit.nextSpellInSequence();
                var spellName: String;
                if (unit.hasOverrideSpellSequence()) {
                    final overrideSpellName = unit.getOverrideSpellSequence();
                    spellName = if (overrideSpellName != null) overrideSpellName else sequenceSpellName;    // If it is null, then just cast the normal one
                } else {
                    spellName = sequenceSpellName;
                }

                if (!unit.hasSpell(spellName)) {
                    Game.q('ERROR: Unit ${unit.name} does not have spell ${spellName} for sequence cast! Has override? ${unit.hasOverrideSpellSequence()}.');
                    return null;
                }
                    
                final spell = unit.getSpell(spellName);
                if (unit.getAIType() == 'canon' && spell.isOfAnyType([SKILL_SHOT, SKILL_SHOT_PIERCING, SKILL_SHOT_SPLIT, MULTI_SKILL_SHOT]))
                    return spell;
                if (isSpellUsable(spell)) {
                    trace('- Spell ${spellName} is usable');
                    return spell;
                } else {
                    trace('- Spell not usable.');
                }
                return null;
            } else {
                if (unit.getAIType() == 'canon') {
                    final spell = unit.getFirstSkillShotSpell();    // Skill shot or multi skill shot or piercing skill shot
                    if (spell == null) throwAndLogError('Unit ${unit.name} has ai type "canon" but no skill shot!');
                    return spell;
                } 
                for (spell in unit.spells) {
                    if (isSpellUsable(spell)) return spell;
                }
                return null;
            }
        }
        
        var spell = chooseWhichSpellToUse(unit);
        if (spell == null) {
            trace('Unit ${unit.name} no spell. Moving...');
            switch (unit.getAIType()) {
                case 'brute', 'advancer':
                    moveCloserToAnyPlayerUnit(unit, endTurn);
                case 'scared':
                    runAwayFromPlayerUnits(unit, endTurn);
                case 'shooter', 'canon':
                    unit.say('* ${unit.name} waits *');
                    endTurn();
                case 'horse', 'restless':
                    trace('  Moving randomly...');
                    moveRandomly(unit, endTurn);
                case 'molotov-peasant':
                    endTurn();
                default:
                    throwAndLogError('Unknown AI type ${unit.getAIType()} for unit ${unit.name}');
            }
        } else {
            switch (spell.getEffectType()) {
                case END_TURN:
                    endTurn();
                case TIDAL_WAVE:
                    unit.castSpellAndThen(spell, null, endTurn);
                case NO_EFFECT:
                    if (unit.getAIType() == 'advancer') {
                        moveCloserToAnyPlayerUnit(unit, () -> {
                            unit.castSpellAndThen(spell, null, null, endTurn);
                        });
                    } else if (unit.getAIType() == 'restless') {
                        moveRandomly(unit, () -> {
                            unit.castSpellAndThen(spell, null, null, endTurn);
                        });
                    } else {
                        unit.castSpellAndThen(spell, null, null, endTurn);
                    }
                case SKILL_SHOT, SKILL_SHOT_SPLIT, MULTI_SKILL_SHOT:
                    if (unit.getAIType() == 'canon') {
                        final targetTile = getSkillShotTargetsTile(unit.tileOn, spell, LEFT, unit.isLarge);
                        unit.castSpellAndThen(spell, targetTile, endTurn);
                    } else if (unit.getAIType() == 'restless') {
                        if (canMoveToHitAPlayerWithSkillshot(unit, spell) != null) {
                            takeTurnWithSkillshotAndThen(unit, spell, endTurn);
                        } else {
                            moveRandomly(unit, endTurn);
                        }
                    } else {
                        takeTurnWithSkillshotAndThen(unit, spell, endTurn);
                    }
                case SKILL_SHOT_PIERCING:
                    if (unit.getAIType() == 'canon') {
                        final targetTile = getSkillShotTargetsTile(unit.tileOn, spell, LEFT, unit.isLarge);
                        unit.castSpellAndThen(spell, targetTile, endTurn);
                    } else {
                        takeTurnWithSkillshotPiercingAndThen(unit, spell, endTurn);
                    }
                case SKILL_SHOT_GHOST:
                    trace('Ok, taking turn with ghosty');
                    takeTurnWithSkillshotGhostAndThen(unit, spell, endTurn);
                case ANY_ALLY:
                    if (spell.template.aiFlags.doesHeal) {
                        takeTurnWithAnyAllyHealAndThen(unit, spell, endTurn);
                    } else {
                        unit.say('I don\'t know what to do with this spell: ${spell.getName()}', 4);
                        endTurn();
                    }
                case TARGET_IN_RANGE, TILE_IN_RANGE:
                    if (unit.getAIType() == 'restless') {
                        final movePos = canMoveToHitPlayerWithSpell(unit, spell);
                        if (movePos == null) {
                            trace('no cant move to hit player. just taking turn');
                            takeTurnWithTargetInRangeAndThen(unit, spell, endTurn);
                        } else {
                            final tileToMoveTo = Battlefield.getTileByPos(movePos);
                            trace('Gotta move to ${movePos.toString()}');
                            unit.castSpellAndThen(unit.getMoveSpell(), tileToMoveTo, () -> {
                                takeTurnWithTargetInRangeAndThen(unit, spell, endTurn);
                            });
                        }
                    } else {
                        takeTurnWithTargetInRangeAndThen(unit, spell, endTurn);
                    }
                case AOE_AROUND:
                    if (canHitAtLeast2PlayersWithAOEAroundSpell(unit, spell)) {
                        takeTurnWithAOEAroundSpellAndThen(unit, spell, endTurn);
                    } else {
                        unit.say('What can I do with this spell: ${spell.getName()}', 4);
                        endTurn();
                    }
                default:
                    unit.say('I don\'t know what do do with this spell: ${spell.getName()}', 4);
                    endTurn();
            }
        }
    }









    // -------------------------------- Take Turn --------------------------------

    public static function takeTurnWithSkillshotGhostAndThen(unit: Unit, spell: Spell, continueBattle: Void -> Void) {
        function castTheSpellAndContinueBattle(direction: Int) {
            final targetTile = unit.tileOn.getNextTileInDirection(direction);
            spell.castByClickedTile(unit, targetTile, continueBattle);
        }
        final hitDirection = canHitUnitWithOwnerWithSkillshotGhost(unit, spell, PLAYER);
        if (hitDirection != NO_DIRECTION) {
            castTheSpellAndContinueBattle(hitDirection);
            return;
        }
        final propHitDirection = canHitUnitWithOwnerWithSkillshotGhost(unit, spell, NEUTRAL);
        if (unit.hasSpell('Prop Breaker') && propHitDirection != NO_DIRECTION) {
            final targetTile = unit.tileOn.getNextTileInDirection(propHitDirection);
            spell.castByClickedTile(unit, targetTile, continueBattle);
            return;
        }
        // Move to hit player
        final goodMoveMatrix = getMoveMatrixToHitWithSpell(unit, spell);
        final hitMatrix = spell.getLocationsFromWhereSpellCanHitUnitWithOwner(unit, unit.isLarge, PLAYER);
        final positionsForAttackMatrix = intersectValidityMatrices(goodMoveMatrix, hitMatrix);
        final tileToMoveTo = getRandomValidPosition(positionsForAttackMatrix);
        if (tileToMoveTo == null) {
            unit.say('Can not move to null!');
            trace('WARNING: Can not ghost-move to null!');
        }
        trace('Found tile to move to as ${tileToMoveTo.toString()}');
        unit.castSpellAndThen(unit.getMoveSpell(), Battlefield.getTileByPos(tileToMoveTo), () -> {
            if (unit.isDead) {
                continueBattle();
            } else {
                final attackDirection = canHitUnitWithOwnerWithSkillshotGhost(unit, spell);
                if (attackDirection == NO_DIRECTION) {
                    continueBattle();
                    trace('WARNING: After moving, attackDirection is NO_DIRECTION?!');
                    return;
                } else {
                    final hitDirection = canHitUnitWithOwnerWithSkillshotGhost(unit, spell, PLAYER);
                    castTheSpellAndContinueBattle(hitDirection);
                }
            }
        });
    }
    public static function takeTurnWithSkillshotAndThen(unit : Unit, spell : Spell, continueBattle : Void -> Void) {
        function castTheSpellAndThen(direction: Int, andThen: Void -> Void) {
            final targetTile = getSkillShotTargetsTile(unit.tileOn, spell, direction, unit.isLarge);
            unit.castSpellAndThen(spell, targetTile, andThen);   // And cast the skillshot
        }
        function moveAndTryHitPlayer(positionToMoveTo: Position, andThen: Void -> Void) {
            if (positionToMoveTo != null) {
                final tileToMoveTo = Battlefield.getTileByPos(positionToMoveTo);
                trace('%%%% Moving to ${tileToMoveTo.toString()}');
                unit.castSpellAndThen(unit.getMoveSpell(), tileToMoveTo, () -> {
                    trace('%%%% Moved. Is dead? ${unit.isDead}');
                    if (unit.isDead == false) {
                        final direction = canHitUnitWithOwnerWithSkillshot(unit, spell);
                        castTheSpellAndThen(direction, andThen);
                    } else {
                        andThen();
                    }
                        
                });
            } else unit.say('ERROR: I am supposed to cast ${spell.getName()} but I have no target!', 6);
        }
        function getCorrectMovePosition() return canMoveToHitAPlayerWithSkillshot(unit, spell);
        function getShooterRunAwayMovePosition() return canShooterRunAwayAndHitAPlayerWithSkillshot(unit, spell);
        
        trace('z z z Taking turn with Skill Shot.');

        final direction = canHitUnitWithOwnerWithSkillshot(unit, spell, PLAYER);
        final canHitAnyPlayer = direction != NO_DIRECTION;
        
        if (canHitAnyPlayer) {
            if (unit.getAIType() == 'shooter' && unit.isNearPlayerUnit()) {
                // THIS NO WORK!
                final positionToMoveTo = getShooterRunAwayMovePosition();
                if (positionToMoveTo != null) {
                    moveAndTryHitPlayer(positionToMoveTo, continueBattle);
                } else {
                    castTheSpellAndThen(direction, continueBattle);
                }
            } else {
                castTheSpellAndThen(direction, continueBattle);
            }
        } else if (unit.hasSpell('Prop Breaker')) {
            tryAttackNearbyProp(unit, (didAttack: Bool) -> {
                if (didAttack) {
                    continueBattle();
                } else {
                    moveAndTryHitPlayer(getCorrectMovePosition(), continueBattle);
                }
            });
        } else if (unit.canMove()) {
            final movePos = getCorrectMovePosition();
            moveAndTryHitPlayer(getCorrectMovePosition(), continueBattle);
        } else {
            continueBattle();
        }
    }
    public static function takeTurnWithSkillshotPiercingAndThen(unit: Unit, spell: Spell, doThis: Void -> Void) {
        final direction = canHitAPlayerWithSkillshotPiercing(unit, spell);
        final firstTile = unit.tileOn.getNextTileInDirection(direction);
        if (direction != NO_DIRECTION) {
            unit.castSpellAndThen(spell, firstTile, doThis);
        } else if (unit.canMove()) {
            final positionToMoveTo = canMoveToHitAPlayerWithSkillshotPiercing(unit, spell);
            if (positionToMoveTo == null) unit.say('ERROR: I am supposed to cast ${spell.getName()} but I have no target!', 6);
            final tileToMoveTo = Battlefield.getTileByPos(positionToMoveTo);
            unit.castSpellAndThen(unit.getMoveSpell(), tileToMoveTo, function() {    // Move to that position
                takeTurnWithSkillshotPiercingAndThen(unit, spell, doThis);
            });
        } else {
            doThis();
        }
    }
    // public static function takeTurnWithThrowMolotov(unit: Unit, spell: Spell, doThis) {
    //     function throwMolotovRandomly() {
    //         trace('%%% Throwin lil molly');
    //         final validTargetTiles = spell.getDefaultTileHighlightMatrix(unit);
    //         final randomValidPos = getRandomValidPosition(validTargetTiles);
    //         // final randomValidPos: Position = if (unit.tileOn.hasTrap()) null else new Position(unit.tileOn.getI(), unit.tileOn.getJ());
    //         if (randomValidPos == null) {
    //             trace('%%% Uh oh?');
    //             unit.say('Uh oh...!');
    //             doThis();
    //             return;
    //         }
    //         trace('%%% Quack, all good!');
    //         unit.castSpellAndThen(spell, Battlefield.getTileByPos(randomValidPos), doThis);
    //     }
    //     trace('%%% Throwing.');
    //     if (unit.isNearPlayerUnit()) {
    //         trace('%%% Yaa man near player unit wa gwan.');
    //         final playerUnits = unit.getNeighborPlayerUnits();
    //         final validMoveTiles = unit.getMoveSpell().getDefaultTileHighlightMatrix(unit);
    //         var invalidMoveTilesWithinDistance = playerUnits[0].getMoveSpell().getDefaultTileHighlightMatrix(playerUnits[0]); // "unit" because we use the caster's move speed, not the player character's
    //         for (playerUnit in playerUnits) {
    //             invalidMoveTilesWithinDistance = joinValidityMatrices(invalidMoveTilesWithinDistance, playerUnit.getMoveSpell().getDefaultTileHighlightMatrix(playerUnits[0]));
    //         }
    //         final goodMoveTiles = subtractValidityMatrices(validMoveTiles, invalidMoveTilesWithinDistance);
    //         final finalPosition = getRandomValidPosition(goodMoveTiles);
    //         if (finalPosition == null) {
    //             unit.say('* waits *');
    //             throwMolotovRandomly();
    //         } else {
    //             trace('%%% Gots to move..');
    //             unit.castSpellAndThen(unit.getMoveSpell(), Battlefield.getTileByPos(finalPosition), () -> {
    //                 trace('%%% Did done movin..');
    //                 throwMolotovRandomly();
    //             });
    //         }
    //     } else {
    //         throwMolotovRandomly();
    //     }
    // }
    public static function takeTurnWithTargetInRangeAndThen(unit : Unit, spell : Spell, doThis) {
        function canHitSomething() return canHitUnitWithOwnerWithSpell(unit, spell, PLAYER);
        function castSpellToHitSomething() {
            var possibleTargets: Matrix<Int>;
            possibleTargets = Pathing.crawlInRangeWithFunction(unit.getI(), unit.getJ(), spell.getRange(), (stepData) -> {
                var i: Int = stepData.i;
                var j: Int = stepData.j;
                if (stepData.value == UNIT) {
                    if (Battlefield.getTile(i, j).getOwner() == PLAYER)
                        stepData.mark(VALID);
                }
                return true;
            });
            var target = Pathing.getRandomValidPosition(possibleTargets);
            if (target == null) {
                unit.say('WTF? Something weird just happened... Tell the developer!', 3);
                doThis();
            } else {
                unit.castSpellAndThen(spell, Battlefield.tiles.get(target.i, target.j), doThis);
            }
        }
        
        if (canHitSomething()) {    // If unit is sitting on a position from where it can hit an enemy
            castSpellToHitSomething();
        } else if (unit.getAIType() == 'restless') {
            moveRandomly(unit, () -> {
                if (canHitSomething()) {
                    castSpellToHitSomething();
                } else {
                    if (doThis != null) doThis();
                }
            });
        } else {
            var positionICanMoveTo = canMoveToHitPlayerWithSpell(unit, spell);
            if (positionICanMoveTo != null) {
                var tileToMoveTo = Battlefield.getTileByPos(positionICanMoveTo);
                unit.castSpellAndThen(unit.getMoveSpell(), tileToMoveTo, () -> {    // Move to that position
                    var possibleTargets = Pathing.mapTilesForPlayerUnitsInRange(unit.tileOn, spell.getRange());
                    var target = Pathing.getRandomValidPosition(possibleTargets);
                    var targetTile = Battlefield.getTileByPos(target);
                    unit.castSpellAndThen(spell, targetTile, doThis);
                });
            } else {
                moveCloserToAnyPlayerUnit(unit, doThis);
            }
        }
    }
    public static function takeTurnWithAOEAroundSpellAndThen(unit : Unit, spell : Spell, doThis : Void -> Void) {
        if (canHitAtLeast2PlayersWithAOEAroundSpell(unit, spell)) {
            var allAffectedTiles = spell.getTileHighlightMatrix(unit);
            var anyTile = Battlefield.getTileByPos(Pathing.getFirstValidPosition(allAffectedTiles));
            unit.castSpellAndThen(spell, anyTile, doThis);
        } else {
            unit.say('Woof.', 4);
            doThis();
        }
    }
    public static function takeTurnWithAnyAllyHealAndThen(unit, spell: Spell, doThis) {
        var damagedAllies = getDamagedUnitsOwnedByAI();
        if (spell.effect().anyAlly.allowSelf == false) {
            damagedAllies = damagedAllies.filter(u -> u != unit);
        }
        if (damagedAllies.length == 0) {
            unit.say('No heal target!', 2);
            doThis();
            return;
        }
        var randomAlly : Unit = cast randomOf(damagedAllies);
        unit.castSpellAndThen(spell, randomAlly.tileOn, doThis);
    }

    static function tryAttackNearbyProp(unit: Unit, doThis: Bool -> Void) { // didAttack -> Void
        final skillshot = unit.getAnySkillshotSpell();
        if (skillshot == null) {
            doThis(false);
            return;
        }
        final direction = canHitUnitWithOwnerWithSkillshot(unit, skillshot, NEUTRAL);
        if (direction != NO_DIRECTION) {
            var targetTile = getSkillShotTargetsTile(unit.tileOn, skillshot, direction, unit.isLarge);
            unit.castSpellAndThen(skillshot, targetTile, () -> {
                doThis(true);
            });
        } else {
            doThis(false);
        }
    }
    
    static function moveRandomly(unit: Unit, doThis: Void -> Void) {
        if (unit.canMove() == false) {
            doThis();
            return;
        }
        var moveSpell = unit.getMoveSpell();
        var validMovementLocations: Matrix<Int> = moveSpell.getDefaultTileHighlightMatrix(unit);
        Matrix.traceIntMatrix(validMovementLocations, 'Valid move locations');
        var tileToMoveToPosition = getRandomValidPosition(validMovementLocations);
        if (tileToMoveToPosition == null) {
            unit.say('* stuck *');
            doThis();
            return;
        }
        var tileToMoveTo = Battlefield.getTileByPos(tileToMoveToPosition);
        unit.castSpellAndThen(moveSpell, tileToMoveTo, doThis);
    }
    static function moveCloserToAnyPlayerUnit(unit: Unit, doThis : Void -> Void) {
        if (unit.canMove() == false) {
            doThis();
            return;
        }
        if (unit == null) throwAndLogError('Unit given in moveCloserToAnyPlayerUnit is null!');
        final path = Pathing.findShortestPathToAPlayerWithBlockAtUnits(unit.tileOn, unit.isLarge);
        if (path == null || path.length == 0) {
            if (unit.hasOnStuckEvent()) {
                unit.doOnStuckEvent(doThis);
            } else {
                doThis();
            }
            return;
        }
        final positionToMoveTo = path[int(min(path.length - 1, unit.getSpeed() - 1))];   // Get the furthest I can get to
        final tileToMoveTo = Battlefield.getTileByPos(positionToMoveTo);
        unit.castSpellAndThen(unit.getMoveSpell(), tileToMoveTo, () -> {
            if (unit.hasSpell('Prop Breaker')) {
                tryAttackNearbyProp(unit, (_) -> doThis());
            } else {
                doThis();
            }
        });
    }
    static function runAwayFromPlayerUnits(unit: Unit, doThis: Void -> Void) {
        if (unit.canMove() == false) {
            doThis();
            return;
        }
        final runAwayPosition = getBestRunAwayPosition(unit);
        if (runAwayPosition == null) {
            unit.say('Can not run away!', 2);
            if (doThis != null) doThis();
            return;
        }
        final tileToMoveTo = Battlefield.getTileByPos(runAwayPosition);
        if (tileToMoveTo == null || tileToMoveTo.hasUnit()) {
            unit.say('Can not run to ${tileToMoveTo.toString()}');
            return;
        }
        unit.castSpellAndThen(unit.getMoveSpell(), tileToMoveTo, doThis);
    }
    








    // ------------------------------ Can Move/Hit -------------------------------

    static function canHitAtLeast2PlayersWithAOEAroundSpell(unit : Unit, spell : Spell) : Bool {
        var validityMatrix = Pathing.mapTilesForPlayerUnitsInRange(unit.tileOn, spell.getRange());
        var nPlayersAround = 0;
        validityMatrix.forEach(v -> {
            if (v == Pathing.VALID) nPlayersAround++;
        });
        return nPlayersAround >= 2;
    }
    static function canHitUnitWithOwnerWithSpell(unit : Unit, spell : Spell, owner: Int) : Bool {
        trace(' Can hit unit with owner with spell?');
        var validLocations = spell.getLocationsFromWhereSpellCanHitUnitWithOwner(unit, unit.isLarge, owner);
        var i = unit.tileOn.matrixY;
        var j = unit.tileOn.matrixX;
        return (validLocations.get(i, j) == VALID);
    }
    static function canHitUnitWithOwnerWithSkillshot(unit : Unit, spell : Spell, ?whatOwner = PLAYER) : Int { // Returns the direction
        // Does it work with large units? (no, cant detect targets to right). Why?
        function canHitAPlayerWithSkillshotInDirection(direction) {
            var targetTile = getSkillShotTargetsTile(unit.tileOn, spell, direction, unit.isLarge);
            if (targetTile != null && targetTile.getOwner() == whatOwner) return true;
            else return false;
        }
        final availableDirs = spell.getAllPossileDirections();
        final possibleDirsToHit = availableDirs.filter(direction -> canHitAPlayerWithSkillshotInDirection(direction));
        if (possibleDirsToHit.length == 0)
            return NO_DIRECTION;
        else {
            final finalDirection: Int = randomOf(possibleDirsToHit);
            return finalDirection;
        }
    }
    static function canHitUnitWithOwnerWithSkillshotGhost(unit: Unit, spell: Spell, ?whatOwner = PLAYER) : Int {
        for (direction in spell.getAllPossileDirections()) {
            if (spell.canShootInDirection(direction)) {
                trace('   Can shoot in direction ${directionToString(direction)}');
                final targetTile = unit.tileOn.getNextTileInDirection(direction);
                if (targetTile == null)
                    continue;
                final targetTileHasPlayerUnit = targetTile.hasUnit() && targetTile.unitOnIt.owner == whatOwner;
                if (!!! targetTileHasPlayerUnit)
                    continue;
                trace('   Tile ${targetTile} not null');
                final landingTile = targetTile.getNextTileInDirection(direction);
                if (landingTile == null)
                    continue;
                trace('   Tile ${landingTile} not null');
                if (landingTile.hasUnit() == false) {
                    return direction;
                }
            }
        }
        return NO_DIRECTION;
    }
    static function canHitAPlayerWithSkillshotPiercing(unit: Unit, spell: Spell): Int {
        function canHitInDirection(direction: Int) {
            final firstTile = unit.tileOn.getNextTileInDirection(direction);
            final allTilesInDir = getAllTilesInDirection(firstTile, spell.getRange(), direction);
            for (tile in allTilesInDir) {
                if (tile.hasUnit() && tile.unitOnIt.owner == PLAYER) return true;
            }
            return false;
        }
        if (spell.getDirections().up && canHitInDirection(UP)) return UP;
        if (spell.getDirections().down && canHitInDirection(DOWN)) return DOWN;
        if (spell.getDirections().left && canHitInDirection(LEFT)) return LEFT;
        if (spell.getDirections().right && canHitInDirection(RIGHT)) return RIGHT;
        if (spell.getDirections().upLeft && canHitInDirection(UP_LEFT)) return UP_LEFT;
        if (spell.getDirections().upRight && canHitInDirection(UP_RIGHT)) return UP_RIGHT;
        if (spell.getDirections().downLeft && canHitInDirection(DOWN_LEFT)) return DOWN_LEFT;
        if (spell.getDirections().downRight && canHitInDirection(DOWN_RIGHT)) return DOWN_RIGHT;
        return NO_DIRECTION;
    }

    // If the unit can move so that it can hit a player with that skillshot spell, returns the position to move to
    // Otherwise, returns null
    static function canMoveToHitAPlayerWithSkillshot(unit : Unit, spell : Spell): Position {
        if (unit.canMove() == false) return null;
        final goodMoveMatrix = getMoveMatrixToHitWithSpell(unit, spell);
        final positionToMoveTo = goodMoveMatrix.getRandomValidPosition();
        return positionToMoveTo;
    }
    static function canMoveToHitAPlayerWithSkillshotPiercing(unit: Unit, spell: Spell) {
        return canMoveToHitAPlayerWithSkillshot(unit, spell);
    }
    static function canMoveToHitPlayerWithSpell(unit : Unit, spell : Spell) : Position {
        if (unit.canMove() == false) return null;
        final movePositions = unit.getLocationsWhereCanMove();
        final validLocations = spell.getLocationsFromWhereSpellCanHitUnitWithOwner(unit, unit.isLarge, PLAYER);
        final positionsICanMoveTo = Pathing.intersectValidityMatrices(movePositions, validLocations);
        final anyValidPosition = Pathing.getRandomValidPosition(positionsICanMoveTo);
        if (anyValidPosition == null) {
            return null;
        }
        return anyValidPosition;
    }
    static function canShooterRunAwayAndHitAPlayerWithSkillshot(unit: Unit, spell: Spell) {
        function getRunAwayMoveMatrixforSkillshot(unit: Unit, spell: Spell) {
            if (unit.isLarge) throwAndLogError('No functionality to run away and shoot implemented for large units! ${unit.name}, ${spell.getName()}');
            if (unit.getAIType() != 'shooter') throwAndLogError('Unit ${unit} must be a shooter instead of ${unit.getAIType()}!');
            final goodMoveMatrix = getMoveMatrixToHitWithSpell(unit, spell);
            final tooCloseMatrix = Pathing.battlefieldTilesToValidityMatrix();
            tooCloseMatrix.forEachIndices((i, j) -> {
                final isPlayerUnitHere = tooCloseMatrix.get(i, j) == Pathing.UNIT && Battlefield.getTile(i, j).unitOnIt.owner == PLAYER;
                function tryMakePositionUnavailable(_i: Int, _j: Int) {
                    if (tooCloseMatrix.isOutOfBounds(_i, _j)) return;
                    tooCloseMatrix.set(_i, _j, Pathing.VALID);  // VALID because VALID - VALID = UNAVAILABLE
                }
                if (isPlayerUnitHere) {
                    tryMakePositionUnavailable(i+1, j);
                    tryMakePositionUnavailable(i-1, j);
                    tryMakePositionUnavailable(i, j+1);
                    tryMakePositionUnavailable(i, j-1);
                }
            });
            final moveAwayMatrix = subtractValidityMatrices(goodMoveMatrix, tooCloseMatrix);
            return moveAwayMatrix;
        }
        if (unit.canMove() == false) return null;
        final moveAwayMatrix = getRunAwayMoveMatrixforSkillshot(unit, spell);
        final positionToMoveTo = moveAwayMatrix.getRandomValidPosition();
        return positionToMoveTo;
    }
    static function canMoveToHitAtLeast2PlayersWithAOEAroundSpell(unit, spell) : Position {
        // TODO
        return null;
    }







    // ------------------------------ Getters -------------------------------

    // Returns the validity matrix for moving then shooting
    static function getMoveMatrixToHitWithSpell(unit: Unit, spell: Spell) {
        final locationsFromWhereSpellCanHit = spell.getLocationsFromWhereSpellCanHitUnitWithOwner(unit, unit.isLarge, PLAYER);
        var moveValidityMatrix: Matrix<Int>;
        if (unit.canMove()) {
            moveValidityMatrix = unit.getMoveSpell().getTileHighlightMatrix(unit);
        } else {
            moveValidityMatrix = Pathing.battlefieldTilesToValidityMatrix();
            moveValidityMatrix.set(unit.getI(), unit.getJ(), VALID);
        }
        final goodMoveMatrix = intersectValidityMatrices(locationsFromWhereSpellCanHit, moveValidityMatrix);
        return goodMoveMatrix;
    }
    static function getBestRunAwayPosition(unit: Unit): Position {
        var currentBestPosition: Position = null;
        var currentBestPositionDistance: Int = 0;
        final moveMatrix = unit.getLocationsWhereCanMove();
        Matrix.traceIntMatrix(moveMatrix, '>> Move matrix:');
        moveMatrix.forEachIndices((i, j) -> {
            if (moveMatrix.get(i, j) != VALID) return;
            final shortestPathToAPlayer = Pathing.findShortestPathToAPlayerJumpOverUnits(Battlefield.getTile(i, j), unit.isLarge);
            if (shortestPathToAPlayer != null && shortestPathToAPlayer.length > currentBestPositionDistance) {
                currentBestPosition = new Position(i, j);
                currentBestPositionDistance = shortestPathToAPlayer.length;
            }
        });
        return currentBestPosition;
    }
    static function getDamagedUnitsOwnedByAI() return Battlefield.unitsOnBattlefield.filter(unit -> unit.health < unit.stats.health && unit.owner == ENEMY && unit.isDead == false);

}
