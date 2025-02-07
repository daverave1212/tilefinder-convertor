

package scripts;


import com.stencyl.graphics.G;
import com.stencyl.graphics.BitmapWrapper;

import com.stencyl.behavior.Script;
import com.stencyl.behavior.Script.*;
import com.stencyl.behavior.ActorScript;
import com.stencyl.behavior.SceneScript;
import com.stencyl.behavior.TimedTask;

import com.stencyl.models.Actor;
import com.stencyl.models.GameModel;
import com.stencyl.models.actor.Animation;
import com.stencyl.models.actor.ActorType;
import com.stencyl.models.actor.Collision;
import com.stencyl.models.actor.Group;
import com.stencyl.models.Scene;
import com.stencyl.models.Sound;
import com.stencyl.models.Region;
import com.stencyl.models.Font;
import com.stencyl.models.Joystick;

import com.stencyl.Engine;
import com.stencyl.Input;
import com.stencyl.Key;
import com.stencyl.utils.Utils;

import openfl.ui.Mouse;
import openfl.display.Graphics;
import openfl.display.BlendMode;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.TouchEvent;
import openfl.net.URLLoader;

import box2D.common.math.B2Vec2;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2Fixture;
import box2D.dynamics.joints.B2Joint;

import com.stencyl.utils.motion.*;

import scripts.Constants.*;

import scripts.Pathing.EMPTY;
import scripts.Pathing.UNIT;
import scripts.Pathing.UNAVAILABLE;
import scripts.Pathing.VALID;

import U.*;
using U;

class Spell_NoEffect extends Spell {
	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> return Pathing.battlefieldTilesToValidityMatrix();
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		if (template.onTargetedEnemy != null) template.onTargetedEnemy(caster, caster);
		if (template.onTargetedTile != null) template.onTargetedTile(caster, targetTile);
		if (hasAudioOnCast()) {
			playAudio(template.audio.onCast);
		}
		tryApplyTargetEffect(caster.getCenterPoint(), caster.getCenterPoint(), () -> {
			doThis();
		});
	}
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> return null;
	override public function getDelayedTargetHighlightMatrix(caster : Unit, targetTile : TileSpace): Matrix<Int> return Pathing.battlefieldTilesToValidityMatrix();
}
class Spell_CustomEffect extends Spell {
	// This should never be called, because there should always be an override function for it
	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {
		trace('WARNING: Spell ${getName()} has no overrideGetTileHighlightMatrix!!');
		return Pathing.battlefieldTilesToValidityMatrix();
	};
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		if (template.onTargetedEnemy != null) {
			trace('WARNING: For spell ${getName()}, use onTargetedTile instead of onTargetedEnemy!');
		}
		if (hasAudioOnCast()) {
			playAudio(template.audio.onCast);
		}
		final originTile = if (fromDelayedTile != null) fromDelayedTile else caster.tileOn;
		final missileFrom = originTile.getCenterPointForMissile(NO_DIRECTION);
		final missileTo = targetTile.getCenterPointForMissile(NO_DIRECTION);
		Spell.ensureCorrectMissilePosForSameX(caster, missileFrom, missileTo);
		
		final direction = getSpellDirection(originTile, targetTile);
		if (template.doJotAnimation)
			caster.jot(direction);

		trySendMissile(missileFrom, missileTo, () -> {
			applyOnTargetAndTile(caster, targetTile);
			tryApplySlashEffect(missileFrom, missileTo);
			tryApplyTargetEffect(missileFrom, missileTo, doThis);

			if (!!! targetTile.hasUnit()) {
				if (template.onMiss != null) template.onMiss(caster, targetTile);
			}
		});
	}
	// Not intended for monsters, therefore these functions doesn't matter
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> return null;
	override public function getDelayedTargetHighlightMatrix(caster : Unit, targetTile : TileSpace): Matrix<Int> return Pathing.battlefieldTilesToValidityMatrix();
}

class Spell_EndTurn extends Spell {

	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {
		trace('ERROR: This should not have happened!');
		return null;
	}
	override public function castByClickedTile(?fromDelayedTileDoesntMatter: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		Battlefield.nextTurn();
		if (doThis != null) doAfter(Battlefield.halfASecond, () -> doThis());
	}
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {
		trace('ERROR: This should not have happened!');
		return null;
	}

}

class Spell_NormalMove extends Spell {

	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {
		return Pathing.mapTilesForMove(Battlefield.tiles, caster.tileOn, caster.stats.speed, caster.isLarge);
	}
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		function slideToTargetTile(andThen: Void -> Void) {
			final previousTile = caster.tileOn;
			applyOnTargetAndTile(caster, targetTile);
			caster.slideToTile(targetTile, () -> {
				andThen();
			});
			if (hasAudioOnCast()) {
				playAudio(template.audio.onCast);
			}
			Battlefield.triggerOnUnitMoveEvents(caster, previousTile);
			
		}

		if (targetTile.isNeighborOf(caster.tileOn)) {
			slideToTargetTile(doThis);
			return;
		}

		final pathToTile = Pathing.findShortestPath(caster.tileOn, caster.isLarge, (i: Int, j: Int) -> {
			if (i == targetTile.getI() && j == targetTile.getJ()) return Pathing.STOP;
			if (Battlefield.getTile(i, j).hasUnit()) return Pathing.BLOCKED;
			return Pathing.CONTINUE;
		});
		final firstTile = if (pathToTile.length == 0) targetTile.getPosition() else pathToTile[0];
		final directionSwitchTiles: Array<TileSpace> = [];
		var currentDirection = caster.tileOn.getDirectionToPosition(firstTile.i, firstTile.j);

		for (i in 1...pathToTile.length) {
			final prevTile = Battlefield.getTileByPos(pathToTile[i-1]);
			final thisTile = Battlefield.getTileByPos(pathToTile[i]);
			final directionToThisTile = prevTile.getDirectionToPosition(thisTile.getI(), thisTile.getJ());
			if (directionToThisTile != currentDirection) {
				currentDirection = directionToThisTile;
				directionSwitchTiles.push(prevTile);
			}
		}
		
		final lastTilePos = if (pathToTile.length > 0) pathToTile[pathToTile.length - 1] else targetTile.getPosition();
		final lastTileInPath = Battlefield.getTileByPos(lastTilePos);
		if (lastTileInPath.getDirectionToPosition(targetTile.getI(), targetTile.getJ()) != currentDirection) {
			directionSwitchTiles.push(lastTileInPath);
		}

		function slideToNextTile(afterFinishing: Void -> Void) {
			if (directionSwitchTiles.length == 0) {
				afterFinishing();
			} else {
				final nextTileToMoveTo = directionSwitchTiles.shift();
				playAudio('MoveAudio');
				caster.slideToTileVisualOnly(nextTileToMoveTo, 0.2, () -> {
					slideToNextTile(afterFinishing);
				});
			}
		}

		slideToNextTile(() -> {
			slideToTargetTile(doThis);
		});
	}
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> return null;
}
class Spell_HorseMove extends Spell_NormalMove {
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		final previousTile = caster.tileOn;
		if (hasAudioOnCast()) {
			playAudio(template.audio.onCast);
		}
		Battlefield.triggerOnUnitMoveEvents(caster, previousTile);
		caster.slideToTile(targetTile, () -> {
			applyOnTargetAndTile(caster, targetTile);
			doThis();
		});
	}
	override public function getDefaultTileHighlightMatrix(caster: Unit): Matrix<Int> {
		return Pathing.mapTilesForHorseMove(caster.tileOn);
	}
}
class Spell_TeleportMove extends Spell_NormalMove {
	override public function getDefaultTileHighlightMatrix(caster: Unit): Matrix<Int> {
		return Pathing.mapTilesForFlyMove(caster.tileOn, caster.getSpeed());
	}
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		if (template.hasTargetEffect()) {
			if (hasAudioOnCast()) {
				playAudio(template.audio.onCast);
			}
			Effects.playParticleAndThen(null, caster.getCenterPoint(), getTargetEffectAnimationName(), getSpecialEffectDurationInMiliseconds(), () -> {});
			caster.actor.setFilter([createTintFilter(Utils.getColorRGB(255,102,0), 50/100)]);
			caster.actor.fadeTo(0, 0.5, Easing.expoIn);
		}
		final previousTile = caster.tileOn;
		doAfter(Battlefield.halfASecond, () -> {
			if (targetTile.hasTrap())
				targetTile.trapOnIt.trigger(caster);
			caster.putOnTile(targetTile);
			Battlefield.triggerOnUnitMoveEvents(caster, previousTile);
			Effects.playParticleAndThen(null, caster.getCenterPoint(), getTargetEffectAnimationName(), getSpecialEffectDurationInMiliseconds(), () -> {});
			if (hasAudioOnHit()) {
				playAudio(template.audio.onHit);
			}
			caster.actor.clearFilters();
			caster.actor.fadeTo(1, 0.5, Easing.expoIn);
			doAfter(Battlefield.halfASecond, () -> {
				doThis();
			});
		});
	}
}
class Spell_FlyMove extends Spell_NormalMove {
	override public function getDefaultTileHighlightMatrix(caster: Unit): Matrix<Int> {
		return Pathing.mapTilesForFlyMove(caster.tileOn, caster.getSpeed(), caster.isLarge);
	}
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		final previousTile = caster.tileOn;
		caster.slideToTile(targetTile, doThis);
		if (hasAudioOnCast()) {
			playAudio(template.audio.onCast);
		}
		Battlefield.triggerOnUnitMoveEvents(caster, previousTile);
	}
}
class Spell_CrystalMove extends Spell_FlyMove {
	override public function getDefaultTileHighlightMatrix(caster: Unit): Matrix<Int> {
		if (caster.customData.ints.exists('crystalMoveDirection') == false) {
			caster.customData.ints['crystalMoveDirection'] = DOWN_LEFT;
		}
		final currentDirection = caster.customData.ints['crystalMoveDirection'];
		function isFree(direction: Int) {
			final tileInThatDirection = caster.tileOn.getNextTileInDirection(direction);
			if (tileInThatDirection == null) return false;
			return tileInThatDirection.hasNoUnit();
		}
		function vmWithValid(direction: Int) {
			final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
			final tileInDirection = caster.tileOn.getNextTileInDirection(direction);
			validityMatrix.set(tileInDirection.getI(), tileInDirection.getJ(), VALID);
			return validityMatrix;
		}
		function setNextMoveDirection(newDirection: Int) caster.customData.ints['crystalMoveDirection'] = newDirection;
		function setNextMoveAndGetVM(direction: Int) {
			setNextMoveDirection(direction);
			return vmWithValid(direction);
		}

		if (isFree(currentDirection)) {
			return vmWithValid(currentDirection);
		}

		final directionsItCanBounce = Constants.getDiagonalBounceDirectionPriorities(currentDirection);
		for (bounceDirection in directionsItCanBounce) {
			if (isFree(bounceDirection)) return setNextMoveAndGetVM(bounceDirection);
		}

		// switch (currentDirection) {	// The order of these checks matters!
		// 	case DOWN_LEFT:
		// 		if (isFree(UP_LEFT)) return setNextMoveAndGetVM(UP_LEFT);
		// 		if (isFree(DOWN_RIGHT)) return setNextMoveAndGetVM(DOWN_RIGHT);
		// 		if (isFree(UP_RIGHT)) return setNextMoveAndGetVM(UP_RIGHT);
		// 	case UP_LEFT:
		// 		if (isFree(DOWN_LEFT)) return setNextMoveAndGetVM(DOWN_LEFT);
		// 		if (isFree(UP_RIGHT)) return setNextMoveAndGetVM(UP_RIGHT);
		// 		if (isFree(DOWN_RIGHT)) return setNextMoveAndGetVM(DOWN_RIGHT);
		// 	case UP_RIGHT:
		// 		if (isFree(DOWN_RIGHT)) return setNextMoveAndGetVM(DOWN_RIGHT);
		// 		if (isFree(UP_LEFT)) return setNextMoveAndGetVM(UP_LEFT);
		// 		if (isFree(DOWN_LEFT)) return setNextMoveAndGetVM(DOWN_LEFT);
		// 	case DOWN_RIGHT:
		// 		if (isFree(UP_RIGHT)) return setNextMoveAndGetVM(UP_RIGHT);
		// 		if (isFree(DOWN_LEFT)) return setNextMoveAndGetVM(DOWN_LEFT);
		// 		if (isFree(UP_LEFT)) return setNextMoveAndGetVM(UP_LEFT);
		// }
		return Pathing.battlefieldTilesToValidityMatrix();
	}
}
class Spell_PlayerCrystalMove extends Spell_FlyMove {
	override public function getDefaultTileHighlightMatrix(caster: Unit): Matrix<Int> {
		final validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		final i = caster.getI(), j = caster.getJ();
		function stepFunc(data: Dynamic): Bool {
			if (data.value == Pathing.UNIT || data.value == Pathing.UNAVAILABLE) {
				return false;
			}
			data.mark(Pathing.VALID);
			return true;
		}
		Pathing.crawlDirectionWithFunction(validityMatrix, i-1, j+1, caster.getSpeed(), UP_RIGHT, stepFunc);
		Pathing.crawlDirectionWithFunction(validityMatrix, i+1, j+1, caster.getSpeed(), DOWN_RIGHT, stepFunc);
		Pathing.crawlDirectionWithFunction(validityMatrix, i+1, j-1, caster.getSpeed(), DOWN_LEFT, stepFunc);
		Pathing.crawlDirectionWithFunction(validityMatrix, i-1, j-1, caster.getSpeed(), UP_LEFT, stepFunc);
		return validityMatrix;
	}
}

class Spell_TidalWave extends Spell {
	override public function getDefaultTileHighlightMatrix(caster: Unit): Matrix<Int> {
		var validityMatrix = Pathing.tilesToValidityMatrix(Battlefield.tiles);
		final fromCol = if (template.effect.isTidalWaveReversed) 1 else 0;
		final toCol = if (template.effect.isTidalWaveReversed) Battlefield.tiles.nCols else (Battlefield.tiles.nCols - 1);
		function markAllTiles(rowIndex: Int, fromCol: Int, toCol: Int) {
			for (colIndex in fromCol...toCol) {
				validityMatrix.set(rowIndex, colIndex, VALID);
			}
		}
		
		for (rowIndex in template.effect.tidalWaveRows) {
			markAllTiles(rowIndex, fromCol, toCol);
		}
		return validityMatrix;
	}
	override public function castByClickedTile(?_: TileSpace, caster: Unit, _: TileSpace, doThis: Void -> Void) {
		for (rowIndex in template.effect.tidalWaveRows) {
			
			final isSameRowAsCaster = caster.getI() == rowIndex;
			var originTile: TileSpace;
			if (template.effect.isTidalWaveReversed) {
				originTile = Battlefield.tiles.getRow(rowIndex).first();
				if (isSameRowAsCaster)
					originTile = originTile.getNextTileInDirection(RIGHT);
			} else {
				originTile = Battlefield.tiles.getRow(rowIndex).last();
				if (isSameRowAsCaster)
					originTile = originTile.getNextTileInDirection(LEFT);
			}

			final missileFrom = originTile.getCenterPointForMissile();
			final direction = if (template.effect.isTidalWaveReversed) RIGHT else LEFT;
			final actualTargetTile = Pathing.getSkillShotTargetsTile(originTile, this, direction, caster.isLarge);				// Get the target tile
			var missileTo = actualTargetTile.getCenterPointForMissile(NO_DIRECTION);
			trySendMissile(missileFrom, missileTo, () -> {
				if (actualTargetTile.hasUnit()) {
					applyOnTargetAndTile(caster, actualTargetTile);
					tryApplySlashEffect(missileFrom, missileTo);
					tryApplyTargetEffect(missileFrom, missileTo);
				} else if (template.onMiss != null) {
					template.onMiss(caster, actualTargetTile);
				}
			});
		}
		doAfter(Battlefield.halfASecond * 3, () -> {
			doThis();
		});
	}
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?caster: Unit, isCasterLarge: Bool = false, owner: Int = PLAYER): Matrix<Int> {
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		validityMatrix.setAll(VALID);
		return validityMatrix;
	}
	override public function getDelayedTargetHighlightMatrix(caster: Unit, targetTile: TileSpace) {
		return this.getDefaultTileHighlightMatrix(caster);
	}
}
class Spell_SkillShotPiercing extends Spell_SkillShot {
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		final originTile = if (fromDelayedTile != null) fromDelayedTile else caster.tileOn;
		var missileFrom = originTile.getCenterPointForMissile();
		var direction = getSpellDirection(originTile, targetTile);																// Get direction
		if (template.doJotAnimation)
			caster.jot(direction);
		final firstTile = originTile.getNextTileInDirection(direction);
		var actualTargetTile = Pathing.getLastTileInDirection(firstTile.getI(), firstTile.getJ(), getRange(), direction, (tile: TileSpace) -> true);
		var missileTo = actualTargetTile.getCenterPointForMissile(direction);
		Spell.ensureCorrectMissilePosForSameX(caster, missileFrom, missileTo);

		final allTiles = Pathing.getAllTilesInDirection(firstTile, getRange(), direction);
		final missileTime = trySendMissile(missileFrom, missileTo, () -> {
			if (template.onMiss != null) {
				if (allTiles != null && allTiles.length > 0) {
					for (t in allTiles) {
						if (t.hasNoUnit()) {
							template.onMiss(caster, t);
						}
					}
					// final lastTile = allTiles[allTiles.length - 1];
					// if (lastTile.hasNoUnit())
					// 	template.onMiss(caster, lastTile);
				}
			}
			if (doThis != null) doThis();
		});

		final timePerTile = if (allTiles.length != 0) missileTime / allTiles.length else 0;
		for (i in 0...allTiles.length) {
			final tile = allTiles[i];
			if (tile.hasNoUnit()) continue;
			function doAllEffects() {
				applyOnTargetAndTile(caster, tile);
				tryApplySlashEffect(missileFrom, tile.getCenterPointForMissile());
				tryApplyTargetEffect(missileFrom, tile.getCenterPointForMissile());
			}
			
			final delay = (i + 1) * timePerTile;
			if (delay > 0)
				doAfter(delay, () -> {
					doAllEffects();
				});
			else
				doAllEffects();
		}
	}

	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {
		final spell = this;
		final targetUnits = Battlefield.getAllAliveUnitsWithOwner(owner);
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		for (unit in targetUnits) {
			final i = unit.getMatrixY();
			final j = unit.getMatrixX();
			final I_UP = i-1, I_DOWN = i+1, J_RIGHT = j+1, J_LEFT = j-1;
			if (spell.canShootDown()) Pathing.crawlDirection(validityMatrix, I_UP, j, spell.getRange(), UP, true);
			if (spell.canShootUp()) Pathing.crawlDirection(validityMatrix, I_DOWN, j, spell.getRange(), DOWN, true);
			if (spell.canShootRight())
				if (isCasterLarge) Pathing.crawlDirection(validityMatrix, i, j-2, spell.getRange(), LEFT, true);
				else Pathing.crawlDirection(validityMatrix, i, J_LEFT, spell.getRange(), LEFT, true);
			if (spell.canShootLeft()) Pathing.crawlDirection(validityMatrix, i, J_RIGHT, spell.getRange(), RIGHT, true);
			if (spell.canShootDownLeft()) Pathing.crawlDirection(validityMatrix,  I_UP,   J_RIGHT, spell.getRange(), UP_RIGHT, true);
			if (spell.canShootDownRight()) Pathing.crawlDirection(validityMatrix, I_UP,   J_LEFT,  spell.getRange(), UP_LEFT, true);
			if (spell.canShootUpLeft()) Pathing.crawlDirection(validityMatrix, 	  I_DOWN, J_RIGHT, spell.getRange(), DOWN_RIGHT, true);
			if (spell.canShootUpRight()) Pathing.crawlDirection(validityMatrix,   I_DOWN, J_LEFT,  spell.getRange(), DOWN_LEFT, true);
		}
		return validityMatrix;
	}
}
class Spell_SkillShot extends Spell {

	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {
		var validityMatrix = Pathing.tilesToValidityMatrix(Battlefield.tiles);
		final i = caster.getMatrixY();
		final j = caster.getMatrixX();
		if (getDirections().up) Pathing.crawlDirection(validityMatrix, i-1, j, getRange(), UP);
		if (getDirections().left) Pathing.crawlDirection(validityMatrix, i, j-1, getRange(), LEFT);
		if (getDirections().right) Pathing.crawlDirection(validityMatrix, i, j+1, getRange(), RIGHT);
		if (getDirections().down) Pathing.crawlDirection(validityMatrix, i+1, j, getRange(), DOWN);
		if (getDirections().upLeft) Pathing.crawlDirection(validityMatrix, i-1, j-1, getRange(), UP_LEFT);
		if (getDirections().upRight) Pathing.crawlDirection(validityMatrix, i-1, j+1, getRange(), UP_RIGHT);
		if (getDirections().downLeft) Pathing.crawlDirection(validityMatrix, i+1, j-1, getRange(), DOWN_LEFT);
		if (getDirections().downRight) Pathing.crawlDirection(validityMatrix, i+1, j+1, getRange(), DOWN_RIGHT);
		return validityMatrix;
	}
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		if (caster == null) trace('ERROR: Null caster given to SkillShot castByClickedTile');
		final originTile = if (fromDelayedTile != null) fromDelayedTile else caster.tileOn;
		final direction = getSpellDirection(originTile, targetTile);																// Get direction
		final actualTargetTile = Pathing.getSkillShotTargetsTile(originTile, this, direction, caster.isLarge);			// Get the target tile
		final missileFrom = originTile.getCenterPointForMissile(direction);
		final missileTo = actualTargetTile.getCenterPointForMissile(NO_DIRECTION);
		Spell.ensureCorrectMissilePosForSameX(caster, missileFrom, missileTo);

		function getTilesMarkedYellow() {
			var tilesMarkedYellow: Array<TileSpace> = [];
			if (originTile == actualTargetTile)
				return tilesMarkedYellow;

			final firstTile = originTile.getNextTileInDirection(direction);
			tilesMarkedYellow = firstTile.getAllTilesUntilIncluding(actualTargetTile);
			return tilesMarkedYellow;
		}

		final tilesMarkedYellow = getTilesMarkedYellow();
		caster.showTargetedTiles(tilesMarkedYellow);
		doAfter(Std.int(Battlefield.halfASecond / 2), () -> {
			if (template.doJotAnimation)
				caster.jot(direction);
			trySendMissile(missileFrom, missileTo, () -> {
				if (actualTargetTile.hasUnit()) {
					applyOnTargetAndTile(caster, actualTargetTile);
					tryApplySlashEffect(missileFrom, missileTo);
					tryApplyTargetEffect(missileFrom, missileTo, doThis);
				} else {
					if (template.onMiss != null) template.onMiss(caster, actualTargetTile);
					if (doThis != null) doThis();
				}
				caster.hideTargetedTiles();
			});
		});
	}
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?caster: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {
		final spell = this;
		final targetUnits = Battlefield.getAllAliveUnitsWithOwner(owner);
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		for (unit in targetUnits) {
			final i = unit.getI();
			final j = unit.getJ();
			function stepFunc(options: Dynamic): Bool {
				final thisIsMe = options.i == caster.getI() && options.j == caster.getJ();
				if (thisIsMe) {
					options.mark(VALID);
					return true;
				}
				if (caster.isLarge) {
					final thisIsAlsoMe = options.i == caster.getI() && options.j == caster.getJ() + 1;
					if (thisIsAlsoMe) {
						final isThereUnitOnRight = Battlefield.tiles.isOutOfBounds(options.i, options.j + 1) == false && Battlefield.tiles.get(options.i, options.j + 1).hasUnit();
						if (isThereUnitOnRight)
							options.mark(UNAVAILABLE);
						else
							options.mark(VALID);
						return true;
					}
				}
				if (options.value == UNIT) {
					return false;
				}
				options.mark(VALID);
				return true;
			}

			for (direction in getAllPossileDirections()) {
				if (canShootInDirection(direction)) {
					final crawlDirection = getOppositeDirection(direction);
					final fromI = getNextIInDirection(i, crawlDirection);
					var fromJ = getNextJInDirection(j, crawlDirection);
					if (caster.isLarge && crawlDirection == LEFT)
						fromJ -= 1;
					final maxRange = getRange();	// Since we shift 1 J to the left, no need to increase range by 1
					Pathing.crawlDirectionWithFunction(validityMatrix, fromI, fromJ, maxRange, crawlDirection, stepFunc);
				}
			}
		}
		return validityMatrix;
	}
	override public function getDelayedTargetHighlightMatrix(caster: Unit, targetTile: TileSpace) {
		final direction = getSpellDirection(caster, targetTile);
		final firstTile = caster.tileOn.getNextTileInDirection(direction);
		if (firstTile == null) throwAndLogError('Null first tile! From ${targetTile.toString()}, caster ${caster.name} in direction ${directionToString(direction)}');
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		Pathing.crawlDirection(validityMatrix, firstTile.getI(), firstTile.getJ(), getRange(), direction, true);
		return validityMatrix;
	}
}
class Spell_SkillShot_Ghost extends Spell_SkillShot {

	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		final originTile = if (fromDelayedTile != null) fromDelayedTile else caster.tileOn;
		final missileFrom = originTile.getCenterPointForMissile();
		final direction = getSpellDirection(originTile, targetTile);														// Get direction
		final actualTargetTile = Pathing.getSkillShotTargetsTile(originTile, this, direction, caster.isLarge);				// Get the target tile
		var missileTo = actualTargetTile.getCenterPointForMissile();
		Spell.ensureCorrectMissilePosForSameX(caster, missileFrom, missileTo);
		trySendMissile(missileFrom, missileTo, () -> {
			if (actualTargetTile.hasUnit()) {
				applyOnTargetAndTile(caster, actualTargetTile);
				tryApplySlashEffect(missileFrom, missileTo);
				tryApplyTargetEffect(missileFrom, missileTo, () -> {});
			}	
		});
		final landingTile = targetTile.getNextTileInDirection(direction);
		if (landingTile == null) throwAndLogError('Landing tile should not have been null when targetTile = ${targetTile.toString()}!');
		caster.slideToTile(landingTile, () -> {
			if (doThis != null) doThis();
		});
	}
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?caster: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {
		final targetUnits = Battlefield.getAllAliveUnitsWithOwner(owner);
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		for (unit in targetUnits) {
			for (direction in getAllPossileDirections()) {
				if (canShootInDirection(direction)) {
					final castingTile = unit.tileOn.getNextTileInDirection(getOppositeDirection(direction));
					final landingTile = unit.tileOn.getNextTileInDirection(direction);
					if (landingTile == null || castingTile == null) continue;
					final isCastingTileEmpty = castingTile.hasUnit() == false;
					final isCastingTileNotEmptyButIsMe = caster != null && caster.tileOn == castingTile;
					if (landingTile.hasUnit()) continue;
					if (isCastingTileEmpty || isCastingTileNotEmptyButIsMe) {
						validityMatrix.set(landingTile.getI(), landingTile.getJ(), VALID);
						validityMatrix.set(castingTile.getI(), castingTile.getJ(), VALID);
					}
				}
			}
		}
		return validityMatrix;
	}
}
class Spell_SkillShotSplit extends Spell {
	// NOTE: Not implemented for Large units!

	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {	// Identical to SkillShot
		var validityMatrix = Pathing.tilesToValidityMatrix(Battlefield.tiles);
		var i = caster.getMatrixY();
		var j = caster.getMatrixX();
		if (getDirections().up) Pathing.crawlDirection(validityMatrix, i-1, j, getRange(), UP);
		if (getDirections().left) Pathing.crawlDirection(validityMatrix, i, j-1, getRange(), LEFT);
		if (getDirections().right) Pathing.crawlDirection(validityMatrix, i, j+1, getRange(), RIGHT);
		if (getDirections().down) Pathing.crawlDirection(validityMatrix, i+1, j, getRange(), DOWN);
		if (getDirections().upLeft) Pathing.crawlDirection(validityMatrix, i-1, j-1, getRange(), UP_LEFT);
		if (getDirections().upRight) Pathing.crawlDirection(validityMatrix, i-1, j+1, getRange(), UP_RIGHT);
		if (getDirections().downLeft) Pathing.crawlDirection(validityMatrix, i+1, j-1, getRange(), DOWN_LEFT);
		if (getDirections().downRight) Pathing.crawlDirection(validityMatrix, i+1, j+1, getRange(), DOWN_RIGHT);
		return validityMatrix;
	}
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		var missileFrom = getMissileOriginPoint(caster.tileOn);
		var direction = getSpellDirection(caster, targetTile);																// Get direction
		if (template.doJotAnimation)
			caster.jot(direction);
		var actualTargetTile = Pathing.getSkillShotTargetsTile(caster.tileOn, this, direction, caster.isLarge);				// Get the target tile
		var secondaryActualTargetTile1: TileSpace = null;	// Tile 1 reached after splitting in 2
		var secondaryActualTargetTile2: TileSpace = null;	// Tile 2 reached after splitting in 2
		switch (direction) {
			case LEFT:
				secondaryActualTargetTile1 = Pathing.getSkillShotTargetsTile(actualTargetTile, this, UP, false);
				secondaryActualTargetTile2 = Pathing.getSkillShotTargetsTile(actualTargetTile, this, DOWN, false);
			case RIGHT:
				secondaryActualTargetTile2 = Pathing.getSkillShotTargetsTile(actualTargetTile, this, DOWN, false);
				secondaryActualTargetTile1 = Pathing.getSkillShotTargetsTile(actualTargetTile, this, UP, false);
			case UP:
				secondaryActualTargetTile1 = Pathing.getSkillShotTargetsTile(actualTargetTile, this, LEFT, false);
				secondaryActualTargetTile2 = Pathing.getSkillShotTargetsTile(actualTargetTile, this, RIGHT, false);
			case DOWN:
				secondaryActualTargetTile2 = Pathing.getSkillShotTargetsTile(actualTargetTile, this, RIGHT, false);
				secondaryActualTargetTile1 = Pathing.getSkillShotTargetsTile(actualTargetTile, this, LEFT, false);
			default:
				U.throwAndLogError('Unkown direction for SkillShotSplit: ${Constants.directionToString(direction)}');
		}
		var missileTo = actualTargetTile.getCenterPointForMissile();
		Spell.ensureCorrectMissilePosForSameX(caster, missileFrom, missileTo);
		trySendMissile(missileFrom, missileTo, () -> {
			if (actualTargetTile.hasUnit()) {
				applyOnTargetAndTile(caster, actualTargetTile);
				tryApplySlashEffect(missileFrom, missileTo);
				tryApplyTargetEffect(missileFrom, missileTo);
				var secondMissileFrom = actualTargetTile.getCenterPointForMissile();
				var secondMissileTo1 = secondaryActualTargetTile1.getCenterPointForMissile();	// Should check null?
				var secondMissileTo2 = secondaryActualTargetTile2.getCenterPointForMissile();	// Should check null?
				trySendMissile(secondMissileFrom, secondMissileTo1, () -> {
					if (secondaryActualTargetTile1.hasUnit()) {
						applyOnTargetAndTile(caster, secondaryActualTargetTile1);
						tryApplySlashEffect(secondMissileFrom, secondMissileTo1);
						tryApplyTargetEffect(secondMissileFrom, secondMissileTo1);
					}
				});
				trySendMissile(secondMissileFrom, secondMissileTo2, () -> {
					if (secondaryActualTargetTile2.hasUnit()) {
						applyOnTargetAndTile(caster, secondaryActualTargetTile2);
						tryApplySlashEffect(secondMissileFrom, secondMissileTo2);
						tryApplyTargetEffect(secondMissileFrom, secondMissileTo2);
					}
				});
				if (doThis != null) doThis();
			} else
				if (doThis != null) doThis();
		});
	}

	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {
		var spell = this;
		var targetUnits = Battlefield.getAllAliveUnitsWithOwner(owner);
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		for (unit in targetUnits){
			var i = unit.getMatrixY();
			var j = unit.getMatrixX();
			if (spell.canShootDown()) Pathing.crawlDirection(validityMatrix, i-1, j, spell.getRange(), UP, false);
			if (spell.canShootUp()) Pathing.crawlDirection(validityMatrix, i+1, j, spell.getRange(), DOWN, false);
			if (spell.canShootRight())
				if (isCasterLarge) Pathing.crawlDirection(validityMatrix, i, j-2, spell.getRange(), LEFT, false);
				else Pathing.crawlDirection(validityMatrix, i, j-1, spell.getRange(), LEFT, false);
			if (spell.canShootLeft()) Pathing.crawlDirection(validityMatrix, i, j+1, spell.getRange(), RIGHT, false);
			if (spell.canShootDownLeft()) Pathing.crawlDirection(validityMatrix, i-1, j+1, spell.getRange(), UP_RIGHT, false);
			if (spell.canShootDownRight()) Pathing.crawlDirection(validityMatrix, i-1, j-1, spell.getRange(), UP_LEFT, false);
			if (spell.canShootUpLeft()) Pathing.crawlDirection(validityMatrix, i+1, j+1, spell.getRange(), DOWN_RIGHT, false);
			if (spell.canShootUpRight()) Pathing.crawlDirection(validityMatrix, i+1, j-1, spell.getRange(), DOWN_LEFT, false);
		}
		return validityMatrix;
	}
}
class Spell_MultiSkillShot extends Spell_SkillShot {
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		var allDirections = getAllPossileDirections();
		var missileFrom = getMissileOriginPoint(caster.tileOn);

		if (template.doJotAnimation)
			caster.jot(caster.tileOn.getDirectionToTile(targetTile));

		var tilesMarkedYellow: Array<TileSpace> = [];
		for (direction in allDirections) {
			if (caster.tileOn.getNextTileInDirection(direction) == null) continue;
			var actualTargetTile = Pathing.getSkillShotTargetsTile(caster.tileOn, this, direction, caster.isLarge);
			final firstTile = caster.tileOn.getNextTileInDirection(direction);
			final tilesMarkedYellowInDirection = firstTile.getAllTilesUntilIncluding(actualTargetTile);
			for (markedTile in tilesMarkedYellowInDirection) {
				tilesMarkedYellow.push(markedTile);
			}
			var missileTo = actualTargetTile.getCenterPointForMissile();
			Spell.ensureCorrectMissilePosForSameX(caster, missileFrom, missileTo);
			trySendMissile(missileFrom, missileTo, () -> {
				if (actualTargetTile.hasUnit()) {
					applyOnTargetAndTile(caster, actualTargetTile);
					tryApplySlashEffect(missileFrom, missileTo);
					tryApplyTargetEffect(missileFrom, missileTo, () -> {});
				} else {
					if (template.onMiss != null) template.onMiss(caster, actualTargetTile);
				}
			});
		}
		caster.showTargetedTiles(tilesMarkedYellow);
		doAfter(750, () -> {
			caster.hideTargetedTiles();
		});

		var delay = 0 + (if (hasMissile()) Battlefield.halfASecond else 0);
		doAfter(delay, () -> {
			if (doThis != null) doThis();
		});
	}
	override public function getDelayedTargetHighlightMatrix(caster: Unit, targetTile: TileSpace) {
		final allDirections = getAllPossileDirections();
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		for (direction in allDirections) {
			final firstTileInThatDirection = caster.tileOn.getNextTileInDirection(direction);
			if (firstTileInThatDirection == null) continue;
			Pathing.crawlDirection(validityMatrix, firstTileInThatDirection.getI(), firstTileInThatDirection.getJ(), getRange(), direction);
		}
		return validityMatrix;
	}
}
class Spell_AOEAround extends Spell {

	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {
		var i = caster.getMatrixY();
		var j = caster.getMatrixX();
		var validityMatrix = Pathing.crawlInRange(i, j, getRange(), {
			stopAtUnits: false,
			allowAllUnits: true,
			allowSelf: false
		});
		return validityMatrix;
	}
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		var allAffectedTiles = getDefaultTileHighlightMatrix(caster);
		var allAffectedUnitPositions = allAffectedTiles.filterToArrayIndices((i, j) -> allAffectedTiles.get(i, j) == Pathing.VALID && Battlefield.getTile(i, j).hasUnit());
		for (pos in allAffectedUnitPositions) {
			var unitOnIt = Battlefield.getTileByPos(pos).unitOnIt;
			var isSameOwner = unitOnIt.owner == caster.owner;
			if (isSameOwner && template.effect.aoeAround.allowAllies == false) continue;
			if (isSameOwner == false && template.effect.aoeAround.allowEnemies == false) continue;
			var missileFrom = getMissileOriginPoint(caster.tileOn);
			var missileTo = Battlefield.getTile(pos.i, pos.j).getCenterPointForMissile();
			Spell.ensureCorrectMissilePosForSameX(caster, missileFrom, missileTo);
			trySendMissile(missileFrom, missileTo, () -> {
				applyOnTargetAndTile(caster, Battlefield.getTile(pos.i, pos.j));
				tryApplyTargetEffect(missileFrom, missileTo, null);
			});
		}
		U.doAfter(Battlefield.halfASecond, doThis);
	}
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {
		return null;
	}

}
class Spell_TargetInRange extends Spell {

	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {
		var validityMatrix = Pathing.mapTilesForTargetInRange(caster.tileOn, getRange(), this.effect().targetInRange.allowSelf);
		return validityMatrix;
	}
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		var effectFrom = getMissileOriginPoint(caster.tileOn);
		var effectTo = targetTile.getCenterPointForMissile();
		Spell.ensureCorrectMissilePosForSameX(caster, effectFrom, effectTo);
		final jotDirection = caster.tileOn.getDirectionToTile(targetTile);
		if (template.doJotAnimation) {
			caster.jot(jotDirection);
		}
		trySendMissile(effectFrom, effectTo, () -> {
			if (targetTile.hasUnit()) {
				applyOnTargetAndTile(caster, targetTile);
				tryApplyTargetEffect(effectFrom, effectTo, doThis);
			} else
				if (doThis != null) doThis();
		});
	}
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {
		var spell = this;
		var targetUnits = Battlefield.getAllAliveUnitsWithOwner(owner);
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		for (unit in targetUnits) {
			var i = unit.getMatrixY();
			var j = unit.getMatrixX();
			Pathing.crawlInRangeWithFunction(validityMatrix, i, j, spell.getRange(), (stepData) -> {
				if (stepData.value != UNAVAILABLE)
					stepData.mark(VALID);
				return true;
			});
			validityMatrix.set(i, j, UNAVAILABLE);
		}
		return validityMatrix;
	}

}
class Spell_TileInRange extends Spell {

	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {
		var tilesAround = Pathing.mapTilesForTileInRange(caster.tileOn, getRange(), true);
		// if (template.effect.tileInRange.allowUnits) {
		// 	var unitTilesAround = Pathing.mapTilesForTargetInRange(caster.tileOn, getRange(), true);
		// 	trace('Found units:');
		// 	Matrix.traceIntMatrix(unitTilesAround);
		// 	tilesAround = Pathing.joinValidityMatrices(tilesAround, unitTilesAround);
		// }
		return tilesAround;
	}
	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		var effectFrom = getMissileOriginPoint(caster.tileOn);
		var effectTo = targetTile.getCenterPointForMissile();
		Spell.ensureCorrectMissilePosForSameX(caster, effectFrom, effectTo);
		if (template.doJotAnimation) {
			caster.jotTowards(targetTile);
		}
		trySendMissile(effectFrom, effectTo, () -> {
			applyOnTile(caster, targetTile);
			tryApplyTargetEffect(effectFrom, effectTo, doThis);
		});
	}
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {
		var targetUnits = Battlefield.getAllAliveUnitsWithOwner(owner);
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		for (unit in targetUnits) {
			var i = unit.getMatrixY();
			var j = unit.getMatrixX();
			Pathing.crawlInRangeWithFunction(validityMatrix, i, j, getRange(), (stepData) -> {
				if (stepData.value != UNAVAILABLE)
					stepData.mark(VALID);
				return true;
			});
			validityMatrix.set(i, j, UNAVAILABLE);
		}
		return validityMatrix;
	}

	override public function getDelayedTargetHighlightMatrix(caster : Unit, targetTile : TileSpace): Matrix<Int> {
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		validityMatrix.set(targetTile.getI(), targetTile.getJ(), Pathing.VALID);
		return validityMatrix;
	}

}
class Spell_AnyAlly extends Spell {

	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {
		if (caster.owner == ENEMY) {
			var validityMatrix = Pathing.mapTilesAllEnemies(Battlefield.tiles);
			if (this.effect().anyAlly.allowSelf == false)
				validityMatrix.set(caster.tileOn.matrixY, caster.tileOn.matrixX, Pathing.UNAVAILABLE);
			return validityMatrix;
		} else if (caster.owner == PLAYER) {
			var validityMatrix = Pathing.mapTilesAllPlayerCharacters(Battlefield.tiles);
			if (this.effect().anyAlly.allowSelf == false)
				validityMatrix.set(caster.tileOn.matrixY, caster.tileOn.matrixX, Pathing.UNAVAILABLE);
			return validityMatrix;
		}
		throw 'ERROR: For getDefaultTileHighlightMatrix, caster named ${caster.name}, spell ${getName()}, owner is ${caster.owner}';
	}

	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {

		var effectFrom	= getMissileOriginPoint(caster.tileOn);
		var effectTo	= targetTile.getCenterPointForMissile();
		Spell.ensureCorrectMissilePosForSameX(caster, effectFrom, effectTo);
		var direction 	= getSpellDirection(caster, targetTile);

		trySendMissile(effectFrom, effectTo, () -> {
			if (targetTile.hasUnit()) {
				applyOnTargetAndTile(caster, targetTile);
				tryApplyTargetEffect(effectFrom, effectTo, doThis);
			} else
				if (doThis != null) doThis();
		});
	}
	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {
		var validityMatrix = Pathing.battlefieldTilesToValidityMatrix();
		trace('WARNING: AnyAlly spell not implemented for locations from where can hit spell plm!');
		return validityMatrix;
	}

}
class Spell_Charge extends Spell {

	override public function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {
		var validityMatrix = Pathing.tilesToValidityMatrix(Battlefield.tiles);
		var i = caster.getMatrixY();
		var j = caster.getMatrixX();
		var ignoreUnits = false;
		if (getDirections().up) Pathing.crawlDirection(validityMatrix, i-1, j, getRange(), UP, ignoreUnits);
		if (getDirections().left) Pathing.crawlDirection(validityMatrix, i, j-1, getRange(), LEFT, ignoreUnits);
		if (getDirections().right) Pathing.crawlDirection(validityMatrix, i, j+1, getRange(), RIGHT, ignoreUnits);
		if (getDirections().down) Pathing.crawlDirection(validityMatrix, i+1, j, getRange(), DOWN, ignoreUnits);
		if (getDirections().upLeft) Pathing.crawlDirection(validityMatrix, i-1, j-1, getRange(), UP_LEFT, ignoreUnits);
		if (getDirections().upRight) Pathing.crawlDirection(validityMatrix, i-1, j+1, getRange(), UP_RIGHT, ignoreUnits);
		if (getDirections().downLeft) Pathing.crawlDirection(validityMatrix, i+1, j-1, getRange(), DOWN_LEFT, ignoreUnits);
		if (getDirections().downRight) Pathing.crawlDirection(validityMatrix, i+1, j+1, getRange(), DOWN_RIGHT, ignoreUnits);
		return validityMatrix;
	}

	override public function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		final previousTile = caster.tileOn;
		caster.slideToTile(targetTile, () -> {
			Battlefield.triggerOnUnitMoveEvents(caster, previousTile);
			var neighborTiles = targetTile.getNeighbors(true);
			var neighborUnits = neighborTiles.filter(tile -> tile.hasUnit()).map(tile -> tile.unitOnIt);
			for (unit in neighborUnits) {
				applyOnTargetAndTile(caster, unit.tileOn);
			}
			if (doThis != null) doThis();
		});
	}

	override public function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {	// NOT SUPPORTED FOR AI
		return null;
	}

}



// Instance of a spell
// Each Unit has an array of instances of Spell
// To create a spell, see SpellDatabase.hx
class Spell {

	public var template	: SpellTemplate;

	public var isWasted = false;
	public var cooldownRemaining = 0;

	public var isInfected = false;	// Some units can infect a spell; Visual is displayed differently for infected spells (see BattlefieldUI)
	
	public function new(_template) template = _template;


	// These methods will be overridden
	public /*virtual*/ function getDefaultTileHighlightMatrix(caster : Unit) : Matrix<Int> {
		warnLog('getDefaultTileHighlightMatrix not implemented for spell ${getName()} of type ${getEffectType()}');
		return Pathing.battlefieldTilesToValidityMatrix();
	};
	public /*virtual*/ function castByClickedTile(?fromDelayedTile: TileSpace, caster : Unit, targetTile : TileSpace, doThis : Void -> Void) {
		warnLog('castByClickedTile not implemented for spell ${getName()} of type ${getEffectType()}');
	}
	public /*virtual*/ function getDelayedTargetHighlightMatrix(caster : Unit, targetTile : TileSpace): Matrix<Int> {
		warnLog('getDelayedTargetHighlightMatrix not implemented for spell ${getName()} of type ${getEffectType()}');
		return Pathing.battlefieldTilesToValidityMatrix();
	}
	public /*virtual*/ function getLocationsFromWhereSpellCanHitUnitWithOwner(?unit: Unit, isCasterLarge : Bool = false, owner: Int = PLAYER) : Matrix<Int> {
		warnLog('getLocationsFromWhereSpellCanHitUnitWithOwner not implemented for spell ${getName()} of type ${getEffectType()}');
		return Pathing.battlefieldTilesToValidityMatrix();
	}
	
	public function getTileHighlightMatrix(caster: Unit): Matrix<Int> {
		if (template.overrideGetTileHighlightMatrix != null) {
			return template.overrideGetTileHighlightMatrix(caster);
		} else {
			return getDefaultTileHighlightMatrix(caster);
		}
	}

	// Factory function for creating a spell
	public static function createFromTemplate(t : SpellTemplate) : Spell {
		if (t.effect == null) throwAndLogError('Spell template ${t.name} has no effect??');
		var type = t.effect.type;
		switch (type) {
			case NO_EFFECT: return new Spell_NoEffect(t);
			case CUSTOM_EFFECT: return new Spell_CustomEffect(t);
			case NORMAL_MOVE: return new Spell_NormalMove(t);
			case FLY_MOVE: return new Spell_FlyMove(t);
			case CRYSTAL_MOVE: return new Spell_CrystalMove(t);
			case PLAYER_CRYSTAL_MOVE: return new Spell_PlayerCrystalMove(t);
			case HORSE_MOVE: return new Spell_HorseMove(t);
			case TELEPORT_MOVE: return new Spell_TeleportMove(t);
			case SKILL_SHOT: return new Spell_SkillShot(t);
			case MULTI_SKILL_SHOT: return new Spell_MultiSkillShot(t);
			case ANY_ALLY: return new Spell_AnyAlly(t);
			case END_TURN: return new Spell_EndTurn(t);
			case TARGET_IN_RANGE: return new Spell_TargetInRange(t);
			case TILE_IN_RANGE: return new Spell_TileInRange(t);
			case AOE_AROUND: return new Spell_AOEAround(t);
			case CHARGE: return new Spell_Charge(t);
			case SKILL_SHOT_SPLIT: return new Spell_SkillShotSplit(t);
			case SKILL_SHOT_PIERCING: return new Spell_SkillShotPiercing(t);
			case SKILL_SHOT_GHOST: return new Spell_SkillShot_Ghost(t);
			case TIDAL_WAVE: return new Spell_TidalWave(t);
			default: trace('ERROR: Spell type ${type} not handled in createFromTemplate');
		}
		return null;
	}


	public function applyOnTile(caster: Unit, tile: TileSpace) {
		if (tile == null) throw 'ERROR: Null tile given to applyOnTile. Spell is ${getName()}';
		if (template.onTargetedTile != null) template.onTargetedTile(caster, tile);
		else throwAndLogError('Spell ${getName()} has no "onTargetedTile" function.');
	}
	public function applyOnTargetAndTile(caster: Unit, tile: TileSpace) {
		if (template.onTargetedEnemy == null && template.onTargetedTile == null) {
			return;
		}
		if (template.onTargetedEnemy != null && tile.hasUnit()) {
			template.onTargetedEnemy(caster, tile.unitOnIt);
		}
		if (template.onTargetedTile != null) template.onTargetedTile(caster, tile);
		if (tile.hasUnit() && tile.unitOnIt.health <= 0) {
			caster.whenKillingAUnit(tile.unitOnIt);
		}
	}

	// If the spell has an effect/missile, does it. Continues with the callback regardless
	function trySendMissile(effectFrom, effectTo, ?callback = null): Float {	// Returns the time it took to do the missile
		if (hasAudioOnCast())
			playAudio(template.audio.onCast);
		if (hasMissile())
			return sendMissileAndThen(effectFrom, effectTo, callback);
		else if (callback != null) callback();
		return 0;

	}
	function tryApplyTargetEffect(effectFrom, effectTo, ?callback = null) {
		if (hasAudioOnHit())
			doAfter(randomIntBetween(0, 100), () -> { playAudio(template.audio.onHit); });
		else {
			trace('Spell ${getName()} has no onHit audio.');
		}
		if (hasTargetEffect())
			doTargetEffectAndThen(effectFrom, effectTo, callback)
		else if (callback != null) callback();
	}
	var slashEffectCount = 0;
	function tryApplySlashEffect(effectFrom, effectTo) {
		slashEffectCount++;
		trace('Doing slash effect for ${getName()}: this is the ${slashEffectCount}th.');
		if (hasSlashEffect()) doSlashEffect(effectFrom, effectTo);
	}


	function getSpellDirection(?fromTile: TileSpace, ?caster : Unit, targetTile : TileSpace) {
		final fromX = if (fromTile != null) fromTile.matrixX else caster.getMatrixX();
		final fromY = if (fromTile != null) fromTile.matrixY else caster.getMatrixY();
		inline function goesUp() return fromY > targetTile.matrixY;
		inline function goesDown() return fromY < targetTile.matrixY;
		inline function goesRight() return fromX < targetTile.matrixX;
		inline function goesLeft() return fromX > targetTile.matrixX;
		if (goesRight() && fromY == targetTile.matrixY) return RIGHT;
		if (goesLeft() && fromY == targetTile.matrixY) return LEFT;
		if (goesDown() && fromX == targetTile.matrixX) return DOWN;
		if (goesUp() && fromX == targetTile.matrixX) return UP;
		if (goesUp() && goesLeft())  return UP_LEFT;
		if (goesUp() && goesRight())  return UP_RIGHT;
		if (goesDown() && goesRight())  return DOWN_RIGHT;
		if (goesDown() && goesLeft())  return DOWN_LEFT;
		return NO_DIRECTION;
	}
	function getMissileOriginPoint(fromTile : TileSpace) {
		return fromTile.getCenterPointForMissile();
	}

	function sendMissileAndThen(from : Point, to : Point, doThis : Void -> Void): Float {	// Returns the time it took the missile to throw
		if (template.missile.isArced)
			return Effects.sendArcMissileAndThen(from, to, getMissileAnimationName(), getMissileSpeed(), doThis);
		else
			return Effects.sendMissileAndThen(from, to, getMissileAnimationName(), getMissileSpeed(), doThis);
	}
	function doTargetEffectAndThen(from : Point, to : Point, doThis : Void -> Void) {
		if (template.targetEffect.rotatesWithDirection == false)
			from = null;
		if (template.effect.hasNoCastDelay) {
			Effects.playParticleAndThen(from, to, getTargetEffectAnimationName(), getSpecialEffectDurationInMiliseconds(), () -> {});
			if (doThis != null) doThis();
		} else {
			Effects.playParticleAndThen(from, to, getTargetEffectAnimationName(), getSpecialEffectDurationInMiliseconds(), doThis);
		}
	}
	function doSlashEffect(from : Point, to : Point) {
		var options = {
			yCenter: from.y,
			xCenter: from.x + (to.x - from.x) / 2,
			flipHorizontally: if (from.x > to.x) true else false,
			durationInMiliseconds: template.slashEffect.duration * 1000
		};
		var slashActor = Effects.playActorParticle('SlashActor', getSlashEffectAnimationName(), options);
		slashActor.setActorValue('isFlippedHorizontally', options.flipHorizontally);	// Used for special effects fluff later
		slashActor.setActorValue('fromX', from.x); slashActor.setActorValue('fromY', from.y);
		slashActor.setActorValue('toX', to.x); slashActor.setActorValue('toY', to.y);
	}

	public static function doGenericSlashEffect(from: Point, to: Point, animationName: String, durationInSeconds: Float) {
		var options = {
			yCenter: from.y + (to.y - from.y) / 2,
			xCenter: from.x + (to.x - from.x) / 2,
			flipHorizontally: if (from.x > to.x) true else false,
			durationInMiliseconds: durationInSeconds * 1000
		};
		var slashActor = Effects.playActorParticle('SlashActor', animationName, options);
		slashActor.setActorValue('isFlippedHorizontally', options.flipHorizontally);	// Used for special effects fluff later
		slashActor.setActorValue('fromX', from.x); slashActor.setActorValue('fromY', from.y);
		slashActor.setActorValue('toX', to.x); slashActor.setActorValue('toY', to.y);
	}


	public inline function getName() return template.name;
	public inline function getDescription() return template.description;
	public inline function getRange() return template.range;
	public inline function getType() return template.effect.type;
	public inline function isFreeAction() return template.isFreeAction;
	public inline function isInstant() return template.isInstant;
	public inline function canAllowSelf() return template.effect.anyAlly.allowSelf;
	public inline function getSpecialEffectDurationInMiliseconds() return Std.int(template.targetEffect.duration * 1000);
	public inline function getMissileAnimationName() return template.missile.animationName;
	public inline function getMissileSpeed() return template.missile.speed;
	public inline function getTargetEffectAnimationName() return template.targetEffect.animationName;
	public inline function getSlashEffectAnimationName() return template.slashEffect.animationName;
	public inline function hasMissile() return template.hasMissile();
	public inline function hasTargetEffect() return template.hasTargetEffect();
	public inline function hasSlashEffect() return template.hasSlashEffect();
	public inline function isPassive() return template.isPassive;
	public inline function isDelayed() return template.effect.isDelayed;
	public inline function isFriendly() return template.isFriendly;
	public inline function aiIsUsableWhileSilenced() return template.aiFlags != null && template.aiFlags.isUsableWhileSilenced;
	public inline function getPreventTurningTowardsTile() return template.preventTurningTowardsTile;
	public function isMoveSpell() return isOfAnyType([NORMAL_MOVE, HORSE_MOVE, TELEPORT_MOVE, CRYSTAL_MOVE, PLAYER_CRYSTAL_MOVE]);

	public inline function doCombatStartEvent(caster) template.effect.events.combatStart(caster);
	public inline function doCombatEndEvent(caster) template.effect.events.combatEnd(caster);

	public inline function getEffectType() return template.effect.type;
	public inline function getDirections() return template.effect.directions;
	public function getAllPossileDirections() {
		var dirs = template.effect.directions;
		var possibleDirs: Array<Int> = [];
		if (dirs.up)		possibleDirs.push(UP);
		if (dirs.left)		possibleDirs.push(LEFT);
		if (dirs.down)		possibleDirs.push(DOWN);
		if (dirs.right)		possibleDirs.push(RIGHT);
		if (dirs.upLeft)	possibleDirs.push(UP_LEFT);
		if (dirs.upRight)	possibleDirs.push(UP_RIGHT);
		if (dirs.downRight)	possibleDirs.push(DOWN_RIGHT);
		if (dirs.downLeft)	possibleDirs.push(DOWN_LEFT);
		return possibleDirs;
	}
	public inline function canShootUp() return template.effect.directions.up;
	public inline function canShootDown() return template.effect.directions.down;
	public inline function canShootLeft() return template.effect.directions.left;
	public inline function canShootRight() return template.effect.directions.right;
	public inline function canShootUpRight() return template.effect.directions.upRight;
	public inline function canShootUpLeft() return template.effect.directions.upLeft;
	public inline function canShootDownRight() return template.effect.directions.downRight;
	public inline function canShootDownLeft() return template.effect.directions.downLeft;
	public function canShootInDirection(direction: Int) {
		switch (direction) {
			case UP: return canShootUp();
			case LEFT: return canShootLeft();
			case DOWN: return canShootDown();
			case RIGHT: return canShootRight();
			case UP_LEFT: return canShootUpLeft();
			case UP_RIGHT: return canShootUpRight();
			case DOWN_LEFT: return canShootDownLeft();
			case DOWN_RIGHT: return canShootDownRight();
			case NO_DIRECTION: return false;
			default: throwAndLogError('Unknown direction ${direction} given to shoot in direction.');
		}
		return false;
	}


	public inline function getManaCost() return template.manaCost;
	public inline function effect() return template.effect;
	public inline function isOfAnyType(types: Array<Int>) return types.indexOf(getType()) != -1;

	public inline function hasOnCastStart() return template.onCastStart != null;
	public inline function doOnCastStart(caster: Unit) template.onCastStart(caster);

	public inline function hasAudioOnCast() return template.audio.onCast != null && template.audio.onCast.length > 0;
	public inline function hasAudioOnHit() return template.audio.onHit != null && template.audio.onHit.length > 0;
	public inline function hasAudioOnPrepare() return template.audio.onPrepare != null && template.audio.onPrepare.length > 0;
	public inline function getIconPath() return template.getIconPath();

	public function ticksCooldowns() {
		if (isOfAnyType([NORMAL_MOVE, END_TURN, HORSE_MOVE, TELEPORT_MOVE, CRYSTAL_MOVE, PLAYER_CRYSTAL_MOVE])) return false;
		return true;
	}
	public static function ensureCorrectMissilePosForSameX(caster: Unit, missileFrom: Point, missileTo: Point) {
		if (missileFrom.x == missileTo.x) {
			if (caster.owner == PLAYER) {
				if (caster.isFlippedHorizontally) {		// Player unit is oriented towards LEFT
					missileTo.x --;
				} else {
					missileTo.x ++;
				}
			} else {
				if (caster.isFlippedHorizontally) {		// Enemy unit is oriented towards RIGHT
					missileTo.x ++;
				} else {
					missileTo.x --;
				}
			}
		}
	}
}


