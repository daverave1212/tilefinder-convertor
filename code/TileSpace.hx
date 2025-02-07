
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

import Math.abs;
import Std.int;

import scripts.Constants.*;
import U.*;

import scripts.Pathing.*;


class TileSpace extends SceneScript
{
	public static var k = {
		width : 50,
		height : 30,
		unitFeetSpace : 10,		// Y Offset for units
		//bottomSpace : 55,		// Y Offset of the tile matrix
		spaceBetweenTiles : 4
	}
	
	public var tileActor : Actor;
	public var matrixX : Int = 0;
	public var matrixY : Int = 0;
	public var unitOnIt : Unit = null;
	public var trapOnIt : Trap = null;
	public var isHighlighted = false;
	public var click: Void -> Void = null;
	
	private function onEnter() Battlefield.onEnterTile(this);
	private function onExit() Battlefield.onExitTile(this);
	private function onClick() {
		if (click != null) click();
		Battlefield.onClickOnTile(this);
	}



	public function new(x : Float, y : Float) {
		super();
		tileActor = U.createActor("TileSpaceActor", "TileSpaces", x, y);
		U.onClick(this.onClick, tileActor);
		U.onEnter(this.onEnter, tileActor);
		U.onExit(this.onExit, tileActor);
		U.doEvery(10, () -> {
			if (!isTinting) return;
			tickTint();
		});
	}

	public function makeGreen() {
		tileActor.setAnimation('Green');
	}
	public function makeNormal() {
		tileActor.setAnimation('Unhighlighted');
	}
	public function playEffect(effectName: String, duration: Int = 150) {
		Effects.playEffectAt(getXCenter(), getYCenter(), effectName, duration);
	}


	var previousAnimation: String;
	public function highlight() {
		previousAnimation = tileActor.getAnimation();
		tileActor.setAnimation("Highlighted");
		isHighlighted = true;
	}
	public function unhighlight() {
		tileActor.setAnimation(previousAnimation);
		isHighlighted = false;
	}
	public function isMarkedForTurn() {
		return isMarkedColor('Blue') || isMarkedColor('Red');	// Blue for my turn, Red for enemy turn
	}
	public function isMarkedColor(?markerName: String = 'Blue'): Bool {
		if (colorMarkers.exists(markerName) && colorMarkers[markerName].numberOfMarkers >= 1) {
			return true;
		}
		return false;
	}
	var colorMarkers: Map<String, {actor: Actor, numberOfMarkers: Int}> = [];
	public function markColor(markerName: String) {
		final isAlreadyMarked = () -> colorMarkers.exists(markerName) && colorMarkers[markerName].numberOfMarkers >= 1;

		if (isAlreadyMarked()) {
			colorMarkers[markerName].numberOfMarkers ++;
			return;
		}

		final colorMarker = createActor('TileMarkerActor', 'TileMarkers');
		colorMarker.setAnimation(markerName);
		colorMarker.setX(tileActor.getX()); colorMarker.setY(tileActor.getY());
		colorMarkers[markerName] = {
			actor: colorMarker,
			numberOfMarkers: 1
		}
	}
	public function unmarkColor(markerName: String) {	// Returns true if successfully removed the marker
		if (!isMarkedColor(markerName)) return false;
		if (colorMarkers[markerName].numberOfMarkers == 1) {
			recycleActor(colorMarkers[markerName].actor);
			colorMarkers[markerName].numberOfMarkers = 0;
			return true;
		} else {
			colorMarkers[markerName].numberOfMarkers --;
			return true;
		}
	}
	public function markForUnitTurn(unit: Unit) {
		final color = if (unit.owner == PLAYER) 'Blue' else 'Red';
		markColor(color);
		if (unit.isLarge) {
			getNextTileInDirection(RIGHT).markColor(color);
		}
	}
	public function unmarkForUnitTurn(unit: Unit) {
		final color = if (unit.owner == PLAYER) 'Blue' else 'Red';
		unmarkColor(color);
		if (unit.isLarge) {
			getNextTileInDirection(RIGHT).unmarkColor(color);
		}
	}

	public function flashTargeted() {
		markColor('Red2');
		doAfter(500, () -> {
			unmarkColor('Red2');
		});
	}


	var dangerMarker: Actor = null;
	public var nRedMarkers = 0;
	public function addDangerMarker(?otherColor: String='RedMarker') {
		if (nRedMarkers == 0) {
			dangerMarker = createActor('TileMarkerActor', 'TileMarkers');
			dangerMarker.setAnimation(otherColor);
			dangerMarker.setX(tileActor.getX()); dangerMarker.setY(tileActor.getY());
		}
		nRedMarkers++;
	}
	public function removeDangerMarker() {
		if (nRedMarkers <= 0) return;
		nRedMarkers--;
		if (nRedMarkers == 0) {
			recycleActor(dangerMarker);
			dangerMarker = null;
		}
	}
	public function hasDangerMarker() return nRedMarkers > 0;




	// Tint functionality
	public function startFlashingGreen() {
		isTinting = true;
		isTintIncreasing = true;
		currentTint = 0.0;
	}
	public function stopFlashingGreen() {	// When a unit moves, it automatically stops flashing
		tileActor.clearFilters();
		isTinting = false;
	}
	public function isFlashing() return isTinting;
	var isTinting = false;
	var isTintIncreasing = true;
	var currentTint = 0.0;	// 0 to 1.0
	public function tickTint() {
		tileActor.clearFilters();
		tileActor.setFilter([createTintFilter(Utils.getColorRGB(75, 255, 0), currentTint)]);
		if (isTintIncreasing) {
			currentTint += 0.01;
			if (currentTint >= 1) isTintIncreasing = false;
		} else {
			currentTint -= 0.01;
			if (currentTint <= 0) isTintIncreasing = true;
		}
	}


	// Friendly Fire Indicator
	var ffIndicatorID = 0;	// For checks, for the animation
	var friendlyFireIndicatorActor: Actor = null;
	public function showFriendlyFireIndicator() {
		if (friendlyFireIndicatorActor != null) return;	// Already has indicator
		ffIndicatorID += 1;
		final thisFFIndicatorID = ffIndicatorID;
		friendlyFireIndicatorActor = createActor('FriendlyFireIndicatorActor', 'Particles');
		friendlyFireIndicatorActor.setXCenter(getXCenter());
		friendlyFireIndicatorActor.setY(getY() - 15);
		// Animation
		friendlyFireIndicatorActor.growTo(0, 0, 0);
		friendlyFireIndicatorActor.growTo(1, 1, 0.25, Easing.expoOut);
		function isOk() return friendlyFireIndicatorActor != null && thisFFIndicatorID == ffIndicatorID;
		doAfterSafe(200, function() {
			if (isOk() == false) return;
			friendlyFireIndicatorActor.spinBy(10, 0.05, Easing.linear);
			doAfter(50, function() {
				if (isOk() == false) return;
				friendlyFireIndicatorActor.spinBy(-20, 0.05, Easing.linear);
				doAfter(50, function() {
					if (isOk() == false) return;
					friendlyFireIndicatorActor.spinTo(0, 0.05, Easing.linear);
					doAfter(50, function(){
						if (isOk() == false) return;
						friendlyFireIndicatorActor.growTo(1, 1, 0, Easing.linear);
					});
				});
			});
		});
	}
	public function hideFriendlyFireIndicator() {
		if (friendlyFireIndicatorActor == null) return;
		final ffia = friendlyFireIndicatorActor;
		friendlyFireIndicatorActor = null;
		ffia.growTo(0, 0, 0.2);
		doAfterSafe(200, () -> {
			if (ffia != null) {
				recycleActor(ffia);
			}
		});
	}
	


	// Returns a validity matrix
	public function getLocationsWhereCanMove(radius: Int, isUnitLarge = false): Matrix<Int> {
		final tiles = Battlefield.tiles;
		var validityMatrix = Pathing.tilesToValidityMatrix(tiles);
		var originI = getI();
		var originJ = getJ();
		if (isUnitLarge) {
			validityMatrix.forEachIndices((i, j) -> {		// Make right-most column unavailable
				if (j == validityMatrix.nCols - 1) validityMatrix.set(i, j, UNAVAILABLE);
			});
			Pathing.markAllLeftsOfUnitsUnavailableExceptMe(validityMatrix, this);
			validityMatrix.set(originI, originJ + 1, EMPTY);
		}
		Pathing.crawlInRangeWithFunction(validityMatrix, originI, originJ, radius, (stepData) -> {
            if (stepData.value == EMPTY) {
				stepData.mark(VALID);
				return true;
			}
            if (stepData.value == VALID)
                return true;
            return false;
		});
		return validityMatrix;
	}


	public inline function toString() return matrixY + ', ' + matrixX;
	public inline function toSymbolString() return '[${if (hasTrap()) trapOnIt.toSymbolString() else "  "}, ${if (hasUnit()) unitOnIt.toSymbolString() else "  "}]';
	public function getUpTile() return if (matrixY == 0) null else Battlefield.getTile(matrixY - 1, matrixX);
	public function getDownTile() return if (matrixY == Battlefield.k.nTileRows - 1) null else Battlefield.getTile(matrixY + 1, matrixX);
	public function getRightTile() return if (matrixX == Battlefield.k.nTileCols - 1) null else Battlefield.getTile(matrixY, matrixX + 1);
	public function getLeftTile() return if (matrixX == 0) null else Battlefield.getTile(matrixY, matrixX - 1);
	public function getUpRightTile() return if (matrixY == 0 || matrixX == Battlefield.k.nTileCols - 1) null else Battlefield.getTile(matrixY - 1, matrixX + 1);
	public function getUpLeftTile() return if (matrixY == 0 || matrixX == 0) null else Battlefield.getTile(matrixY - 1, matrixX - 1);
	// public function getDownRightTile() return if (matrixY == Battlefield.k.nTileRows - 1 || matrixX == Battlefield.k.nTileCols - 1) null else Battlefield.getTile(matrixY + 1, matrixX + 1);
	public function getDownRightTile() return if (Battlefield.tiles.isOutOfBounds(getI() + 1, getJ() + 1)) null else Battlefield.getTile(getI() + 1, getJ() + 1);
	public function getDownLeftTile() return if (matrixY == Battlefield.k.nTileRows - 1 || matrixX == 0) null else Battlefield.getTile(matrixY + 1, matrixX - 1);	
	public function getNextTileJoined(vertical: Int, horizontal: Int) {
		if (vertical == UP) {
			if (horizontal == LEFT) return getNextTileInDirection(UP_LEFT);
			else return getNextTileInDirection(UP_RIGHT);
		} else {
			if (horizontal == LEFT) return getNextTileInDirection(DOWN_LEFT);
			else return getNextTileInDirection(DOWN_RIGHT);
		}
		return null;
	}
	public inline function getXCenter() return tileActor.getXCenter();
	public inline function getYCenter() return tileActor.getYCenter();
	public inline function getYBottom() return tileActor.getY() + tileActor.getHeight();
	public inline function getI() return matrixY;
	public inline function getJ() return matrixX;
	public inline function getX() return tileActor.getX();
	public inline function getPosition() return new Position(getI(), getJ());
	public inline function getY() return tileActor.getY();
	public inline function getWidth()  return TileSpace.k.width;
	public inline function getHeight() return TileSpace.k.height;
	public inline function getCenterPoint() return new Point(getXCenter(), getYCenter());
	public function getCenterPointForMissile(?direction: Int = NO_DIRECTION) {	// RIGHT = left to RIGHT, LEFT = right to LEFT
		final missileTo = getCenterPoint();
		missileTo.y += -22;
		if (direction == RIGHT) {
			missileTo.x += -20;
		} else if (direction == LEFT) {
			missileTo.x += 20;
		}
		return missileTo;
	}
	public inline function getOwner() return if (unitOnIt == null) NOBODY else unitOnIt.owner;
	public function getAvailableNeighbors() {
		var neighborTiles: Array<TileSpace> = getNeighbors(true);
		var emptyNeighborTiles = neighborTiles.filter((tile: TileSpace) -> tile.hasUnit() == false);
		return emptyNeighborTiles;
	}
	public function getEmptyNeighbors(?diagonallyToo=true) {
		var neighborTiles: Array<TileSpace> = getNeighbors(diagonallyToo);
		var emptyNeighborTiles = neighborTiles.filter((tile: TileSpace) -> tile.hasNoUnitAndTrap());
		return emptyNeighborTiles;
	}
	public function getRandomShootLocationNeighbor() {
		final neighbors = getNeighbors(true);
		final okNeighbors = neighbors.filter(t -> t.hasUnit() == false || (t.unitOnIt != null && ['Vase', 'Explosive Barrel'].indexOf(t.unitOnIt.name) != -1));
		if (okNeighbors.length == 0) return null;
		final nonTrapNeighbors = okNeighbors.filter(t -> t.hasTrap() == false);
		final chosenTile: TileSpace = if (nonTrapNeighbors.length > 0) randomOf(nonTrapNeighbors) else randomOf(okNeighbors);
		return chosenTile;
	}
	public function getRandomEmptyNeighbor(?diagonallyToo=true) {
		var emptyNeighborTiles = getEmptyNeighbors(diagonallyToo);
		if (emptyNeighborTiles.length > 0)
			return emptyNeighborTiles[randomIntBetween(0, emptyNeighborTiles.length - 1)];
		else
			return null;
	}
	public function getRandomNeighbor(?diagonallyToo=true) {
		final neighborTiles: Array<TileSpace> = getNeighbors(diagonallyToo);
		return neighborTiles[randomIntBetween(0, neighborTiles.length - 1)];
	}
	public inline function hasUnit() return (unitOnIt != null);
	public inline function hasNoUnit() return !hasUnit();
	public inline function hasTrap(trapName: String = null) return if (trapName == null) (trapOnIt != null) else (trapOnIt != null && trapOnIt.name == trapName);
	public inline function hasNoUnitAndTrap() return !hasUnit() && !hasTrap();
	public inline function igniteIfHasOil() {
		if (hasTrap('Oil')) {
			trapOnIt.kill();
			Battlefield.spawnTrap('Oil', this);
		}
	}
	public function getDirectionToTile(tile: TileSpace) {
		return getDirectionToPosition(tile.getI(), tile.getJ());
	}
	public function getDirectionToPosition(i: Int, j: Int) {
		final myI = getI();
		final myJ = getJ();
		final sameRow = i == myI;
		final sameCol = j == myJ;
		final lefter = j < myJ;
		final righter = j > myJ;
		final upper = i < myI;
		final downer = i > myI;
		if (sameRow) {
			if (sameCol) return NO_DIRECTION;
			if (righter) return RIGHT;
			if (lefter) return LEFT;
		} else if (sameCol) {
			if (upper) return UP;
			if (downer) return DOWN;
		} else {
			if (upper) {
				if (righter) return UP_RIGHT;
				if (lefter) return UP_LEFT;
			}
			if (downer) {
				if (righter) return DOWN_RIGHT;
				if (lefter) return DOWN_LEFT;
			}
		}
		return NO_DIRECTION;
	}
	public function getNextTileInDirection(direction : Int) : TileSpace {
		switch(direction) {
			case RIGHT: return getRightTile();
			case LEFT: return getLeftTile();
			case UP: return getUpTile();
			case DOWN: return getDownTile();
			case UP_RIGHT: return getUpRightTile();
			case UP_LEFT: return getUpLeftTile();
			case DOWN_RIGHT: return getDownRightTile();
			case DOWN_LEFT: return getDownLeftTile();
			case NO_DIRECTION: return null;
			default:
				trace('ERROR: Unknown direction $direction given to getNextTileInDirection');
				return null;
		}
	}
	public function getNeighbors(alsoDiagonally = false) : Array<TileSpace> {
		if (alsoDiagonally)
			return [
				getUpTile(), getUpRightTile(), getRightTile(), getDownRightTile(),
				getDownTile(), getDownLeftTile(), getLeftTile(), getUpLeftTile()
			].filter(tile -> tile != null);
		else return [getUpTile(), getRightTile(), getDownTile(), getLeftTile()].filter(tile -> tile != null);
	}
	public function getNeighborsExceptRight(alsoDiagonally = false) : Array<TileSpace> {	// Just like getNeighbors but doesn't reutrn the RIGHT tile. Used for large units.
		if (alsoDiagonally)
			return [
				getUpTile(), getUpRightTile(), null, getDownRightTile(),
				getDownTile(), getDownLeftTile(), getLeftTile(), getUpLeftTile()
			].filter(tile -> tile != null);
		else return [getUpTile(), null, getDownTile(), getLeftTile()].filter(tile -> tile != null);
	}
	public function getNeighborsSecondTileLargeUnit(alsoDiagonally = false): Array<TileSpace> {
		if (alsoDiagonally)
			return [
				getUpRightTile(), getRightTile(), getDownRightTile()
			].filter(tile -> tile != null);
		else return [getRightTile()].filter(tile -> tile != null);
	}
	public function getNeighborUnits(alsoDiagonally = false) {
		return getNeighbors(alsoDiagonally).filter(t -> t.hasUnit()).map(t -> t.unitOnIt);
	}
	public function isNeighborOf(tile: TileSpace, ?diagonallyToo: Bool = false) {
		final leftRight = getI() == tile.getI() && abs(getJ() - tile.getJ()) == 1;
		final upDown    = abs(getI() - tile.getI()) == 1 && getJ() == tile.getJ();
		final diagonally = abs(getI() - tile.getI()) == 1 && abs(getJ() - tile.getJ()) == 1;
		return (leftRight || upDown) || (diagonallyToo && diagonally);
	}
	public function getHypotheticCoordinatesForActor(actor: Actor): Point {
		var actorX = getXCenter() - actor.getWidth() / 2;
		var actorY = getY() - actor.getHeight() + getHeight() - k.unitFeetSpace;
		var coordinates = new Point(actorX, actorY);
		return coordinates;
	}
	public function getAllTilesUntilIncluding(tile: TileSpace) {
		if (tile == null) {
			trace('WARNING: Given tile for getAllTilesUntilIncluding is null!');
			return [];
		}
		if (tile == this)
			return [this];

		final direction = getDirectionToTile(tile);
		final tiles: Array<TileSpace> = [this];
		var tileIter = this;
		while (tileIter != tile) {
			tileIter = tileIter.getNextTileInDirection(direction);
			tiles.push(tileIter);
		}
		return tiles;
	}
	public function getAllTilesInDirectionIncluding(direction: Int, nTilesMax: Int = 1) {
		final tiles = [this];
		var tileIter = this.getNextTileInDirection(direction);
		while (tileIter != null && tiles.length < nTilesMax) {
			tiles.push(tileIter);
			tileIter = tileIter.getNextTileInDirection(direction);
		}
		return tiles;
	}
	public function getDistanceToTile(tile: TileSpace): Int {
		if (tile == null) {
			Game.q('ERROR: Given a null tile to getDistanceToTile');
			return 1;
		}
		return int(Math.abs(getI() - tile.getI()) + Math.abs(getJ() - tile.getJ()));
	}


	public static function getTileByMouseCoordinates() {
		trace('Getting...');
		final x = getScreenX() + getMouseX(), y = getScreenY() + getMouseY();
		final firstTile = Battlefield.tiles.get(0, 0);
		final startX = firstTile.getX(), startY = firstTile.getY();
		final totalTileWidth = Battlefield.tiles.nCols * (TileSpace.k.width + TileSpace.k.spaceBetweenTiles) - TileSpace.k.spaceBetweenTiles;
		final totalTileHeight = Battlefield.tiles.nRows * (TileSpace.k.height + TileSpace.k.spaceBetweenTiles) - TileSpace.k.spaceBetweenTiles;
		if (x < startX || x > startX + totalTileWidth) return null;
		if (y < startY || y > startY + totalTileHeight) return null;

		final mouseXOffset = x - startX, mouseYOffset = y - startY;
		final tileI = Std.int(mouseYOffset / (TileSpace.k.height + TileSpace.k.spaceBetweenTiles));
		final tileJ = Std.int(mouseXOffset / (TileSpace.k.width + TileSpace.k.spaceBetweenTiles));
		final mouseXOffsetInTile = mouseXOffset - tileJ * (TileSpace.k.width + TileSpace.k.spaceBetweenTiles);
		final mouseYOffsetInTile = mouseYOffset - tileI * (TileSpace.k.height + TileSpace.k.spaceBetweenTiles);
		if (mouseXOffsetInTile > TileSpace.k.width) return null;
		if (mouseYOffsetInTile > TileSpace.k.height) return null;
		trace('Gought.');
		return Battlefield.tiles.get(tileI, tileJ);
	}
}
