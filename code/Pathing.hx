
package scripts;

import com.stencyl.Engine;

import scripts.Constants.*;
import U.*;
using U;



class Pathing
{

	// ---------------------------------- Constants ---------------------------------

	public static inline var EMPTY = 0;			// Initial value of the matrix. Nothing is on that tile
	public static inline var UNIT = 1;			// Initial value of the matrix. Nothing is on that tile

	public static inline var UNAVAILABLE = -1;	// Initial or final value. For example, if can't be cast on self
	public static inline var VALID = 7;		// Final value for the matrix. Depends on the case.

	public static inline var STOP = 0;		// Signal for stopping all iteration and returning
	public static inline var BLOCKED = 1;	// Signal for not continuing down the path, but keep iterating in other directions
	public static inline var CONTINUE = 2;	// Signal for continuing down the road









	// ----------------------------- Crawling and Mapping ----------------------------

	public static function battlefieldTilesToValidityMatrix() return tilesToValidityMatrix(Battlefield.tiles);
	public static function tilesToValidityMatrix(tiles : Matrix<TileSpace>){		// Returns a matrix of EMPTY, UNIT
		var validityMatrix = new Matrix<Int>(tiles.nRows, tiles.nCols);
		tiles.forEachIndices(function(i, j){
			if(tiles.get(i,j).unitOnIt == null)
				validityMatrix.set(i, j, EMPTY);
			else
				validityMatrix.set(i, j, UNIT);
		});
		return validityMatrix;
	}
	// Executes stepFunc for every tile. The parameter is an object containing everything related to the iteration.
	// If it returns false, then the tree branch stops there. Otherwise, it continues to expand.
	public static function crawlInRangeWithFunction(?matrix: Matrix<Int>, i: Int, j: Int, radius: Int, stepFunc: Dynamic->Bool) {
		final NOT_VISITED = 0, VISITED = 1;
		final visitedMatrix = battlefieldTilesToValidityMatrix().setAll(NOT_VISITED);
		final validityMatrix = if (matrix != null) matrix else battlefieldTilesToValidityMatrix();
		final positionsToVisit: Array<CrawlObject> = [];
		function tryQueue(i: Int, j: Int, radius: Int) {
			if (visitedMatrix.isOutOfBounds(i, j)) return;
			if (radius <= 0) return;
			if (visitedMatrix.get(i, j) == VISITED) return;
			visitedMatrix.set(i, j, VISITED);
			positionsToVisit.push({ i: i, j: j, radius: radius });
		}
		tryQueue(i-1, j, radius);
		tryQueue(i+1, j, radius);
		tryQueue(i, j+1, radius);
		tryQueue(i, j-1, radius);
		while (positionsToVisit.length > 0) {
			final iter = positionsToVisit.shift();
			final i = iter.i, j = iter.j, radius = iter.radius;
			final mark = function(withWhat: Int) validityMatrix.set(i, j, withWhat);
			final isNotBlockedHere = stepFunc({ i: i, j: j, radius: radius, value: validityMatrix.get(i, j), mark: mark });
			if (isNotBlockedHere) {
				tryQueue(i-1, j, radius-1);
				tryQueue(i+1, j, radius-1);
				tryQueue(i, j+1, radius-1);
				tryQueue(i, j-1, radius-1);
			}
		}
		return validityMatrix;
	}
	// The most useful function for mapping tiles in range
	public static function crawlInRange(?matrix : Matrix<Int>, i : Int, j : Int, radius : Int, parameters : Dynamic) {
		var stopAtUnits 	 = if (parameters.stopAtUnits != null) parameters.stopAtUnits else false;
		var allowEnemyUnits	 = if (parameters.allowEnemies != null) parameters.allowEnemyUnits else false;
		var allowPlayerUnits = if (parameters.allowPlayerUnits != null) parameters.allowPlayerUnits else false;
		var allowAllUnits	 = if (parameters.allowAllUnits != null) parameters.allowAllUnits else false;
		var allowSelf		 = if (parameters.allowSelf != null) parameters.allowSelf else false;
		var allowEmptySpace	 = if (parameters.allowEmptySpace != null) parameters.allowEmptySpace else false;

		function doCrawlInRange(matrix : Matrix<Int>, i : Int, j : Int, radius : Int) {
			inline function mark() matrix.set(i, j, VALID);
			if (!matrix.isInBounds(i, j)) return;
			if (radius <= 0) return;	// Can be < 0 if the given radius is -1 (which is acceptable)
			var spot = matrix.get(i, j);
			switch (spot) {
				case UNIT:
					var owner = Battlefield.tiles.get(i, j).unitOnIt.owner;
					if (allowEnemyUnits && owner == ENEMY) mark();
					else if (allowPlayerUnits && owner == PLAYER) mark();
					else if (allowAllUnits) mark();
					if (stopAtUnits) return;
				case EMPTY:
					if (allowEmptySpace) mark();
				case UNAVAILABLE:
					return;
			}
			doCrawlInRange(matrix, i-1, j, radius-1);
			doCrawlInRange(matrix, i+1, j, radius-1);
			doCrawlInRange(matrix, i, j+1, radius-1);
			doCrawlInRange(matrix, i, j-1, radius-1);
		}

		var validityMatrix : Matrix<Int>;
		if (matrix != null) validityMatrix = matrix;
		else validityMatrix = battlefieldTilesToValidityMatrix();
		doCrawlInRange(validityMatrix, i-1, j, radius);
		doCrawlInRange(validityMatrix, i+1, j, radius);
		doCrawlInRange(validityMatrix, i, j+1, radius);
		doCrawlInRange(validityMatrix, i, j-1, radius);

		if (parameters.allowSelf == false) {
			validityMatrix.set(i, j, UNAVAILABLE);
		}
		return validityMatrix;
	}
	// If at an EMPTY position, marks it VALID, then goes to the next one
	// Otherwise, it stops
	public static function crawlDirection(matrix : Matrix<Int>, i : Int, j : Int, range : Int, direction : Int, ?ignoreUnits : Bool = true) {
		if (!matrix.isInBounds(i, j)) return;
		if (range == 0) return;
		if (!ignoreUnits && matrix.get(i,j) == UNIT){
			return;
		} else {
			matrix.set(i, j, VALID);
		}
		if (direction == UP) 			crawlDirection(matrix, i-1, j, range-1, UP, ignoreUnits);
		if (direction == DOWN)			crawlDirection(matrix, i+1, j, range-1, DOWN, ignoreUnits);
		if (direction == LEFT)			crawlDirection(matrix, i, j-1, range-1, LEFT, ignoreUnits);
		if (direction == RIGHT)			crawlDirection(matrix, i, j+1, range-1, RIGHT, ignoreUnits);
		if (direction == UP_LEFT) 		crawlDirection(matrix, i-1, j-1, range-1, UP_LEFT, ignoreUnits);
		if (direction == UP_RIGHT) 		crawlDirection(matrix, i-1, j+1, range-1, UP_RIGHT, ignoreUnits);
		if (direction == DOWN_LEFT)		crawlDirection(matrix, i+1, j-1, range-1, DOWN_LEFT, ignoreUnits);
		if (direction == DOWN_RIGHT)	crawlDirection(matrix, i+1, j+1, range-1, DOWN_RIGHT, ignoreUnits);
	}
	public static function crawlDirectionWithFunction(matrix: Matrix<Int>, i : Int, j : Int, range : Int, direction : Int, stepFunc: Dynamic -> Bool) {
		if (!matrix.isInBounds(i, j)) return;
		if (range == 0) return;
		function mark(withWhat: Int) matrix.set(i, j, withWhat);
		final willContinue = stepFunc({ i: i, j: j, value: matrix.get(i, j), mark: mark, radius: range });
		if (!!!willContinue) return;
		if (direction == UP) 			crawlDirectionWithFunction(matrix, i-1, j, range-1, UP, stepFunc);
		if (direction == DOWN)			crawlDirectionWithFunction(matrix, i+1, j, range-1, DOWN, stepFunc);
		if (direction == LEFT)			crawlDirectionWithFunction(matrix, i, j-1, range-1, LEFT, stepFunc);
		if (direction == RIGHT)			crawlDirectionWithFunction(matrix, i, j+1, range-1, RIGHT, stepFunc);
		if (direction == UP_LEFT) 		crawlDirectionWithFunction(matrix, i-1, j-1, range-1, UP_LEFT, stepFunc);
		if (direction == UP_RIGHT) 		crawlDirectionWithFunction(matrix, i-1, j+1, range-1, UP_RIGHT, stepFunc);
		if (direction == DOWN_LEFT)		crawlDirectionWithFunction(matrix, i+1, j-1, range-1, DOWN_LEFT, stepFunc);
		if (direction == DOWN_RIGHT)	crawlDirectionWithFunction(matrix, i+1, j+1, range-1, DOWN_RIGHT, stepFunc);
	}
	
	public static function markAllLeftsOfUnitsUnavailableExceptMe(validityMatrix: Matrix<Int>, myTile: TileSpace) {
		validityMatrix.forEachIndices((stepI, stepJ) -> {
			final isUnitHere = Battlefield.getTile(stepI, stepJ).hasUnit();
			final isThisMe = myTile.getI() == stepI && myTile.getJ() == stepJ;
			if (isUnitHere && isThisMe == false) {
				final leftOfThisIsEmpty = () -> validityMatrix.get(stepI, stepJ-1) == EMPTY;
				final leftOfThisIsInBounds = validityMatrix.isInBounds(stepI, stepJ-1);
				if (leftOfThisIsInBounds && leftOfThisIsEmpty()) {
					validityMatrix.set(stepI, stepJ-1, UNAVAILABLE);
				}
			}
		});
	}


	public static function mapTilesForMove(?tiles : Matrix<TileSpace>, from : TileSpace, radius : Int, isUnitLarge : Bool = false) {
		if (tiles == null) tiles = Battlefield.tiles;
		var validityMatrix = tilesToValidityMatrix(tiles);
		var originI = from.matrixY;
		var originJ = from.matrixX;
		if (isUnitLarge) {
			trace('Yes is large');
			validityMatrix.set(originI, originJ + 1, EMPTY);
			markAllLeftsOfUnitsUnavailableExceptMe(validityMatrix, from);
			validityMatrix.forEachIndices((i, j) -> {			// Make right-most column unavailable
				if (j == validityMatrix.nCols - 1) {
					if (validityMatrix.get(i, j) == EMPTY) {
						validityMatrix.set(i, j, UNAVAILABLE);
					}
				}
			});
			Matrix.traceIntMatrix(validityMatrix, 'Intermediary matrix');
		} else {
			trace('no large?');
		}
		crawlInRangeWithFunction(validityMatrix, originI, originJ, radius, (stepData) -> {
            if (stepData.value == EMPTY) {
				stepData.mark(VALID);
				return true;
			}
            if (stepData.value == VALID)
                return true;
            return false;
		});
		Matrix.traceIntMatrix(validityMatrix, 'Final matrix');
		return validityMatrix;
	}
	public static function mapTilesForFlyMove(?tiles : Matrix<TileSpace>, from : TileSpace, radius : Int, isUnitLarge : Bool = false) {
		trace('Mapping tiles for FlyMove from ${from.toString()} radius ${radius} isLarge=${isUnitLarge}');
		if (tiles == null) tiles = Battlefield.tiles;
		var validityMatrix = tilesToValidityMatrix(tiles);
		var originI = from.matrixY;
		var originJ = from.matrixX;
		if (isUnitLarge) {
			validityMatrix.set(originI, originJ + 1, EMPTY);
			markAllLeftsOfUnitsUnavailableExceptMe(validityMatrix, from);
			validityMatrix.forEachIndices((i, j) -> {		// Make right-most column unavailable
				if (j == validityMatrix.nCols - 1) validityMatrix.set(i, j, UNAVAILABLE);
			});
		}
		crawlInRangeWithFunction(validityMatrix, originI, originJ, radius, (stepData: Dynamic) -> {
            if (stepData.value == EMPTY) {
				stepData.mark(VALID);
				return true;
			}
            if (stepData.value == VALID || stepData.value == UNIT)
                return true;
            return false;
		});
		Matrix.traceIntMatrix(validityMatrix, 'Got the move matrix:');
		return validityMatrix;
	}
	public static function mapTilesForHorseMove(from: TileSpace) {	// Does not take a 'speed' because the movement is always constant in the shape of L
		var validityMatrix = tilesToValidityMatrix(Battlefield.tiles);
		var i = from.getI();
		var j = from.getJ();
		function ifInBoundsAndEmptyMark(_i, _j) {
			if (Battlefield.tiles.isInBounds(_i, _j) && !Battlefield.getTile(_i, _j).hasUnit()) {
				validityMatrix.set(_i, _j, VALID);
			}
		}
		ifInBoundsAndEmptyMark(i-1, j-2);	// These positions are respective to a Horse in chess
		ifInBoundsAndEmptyMark(i-2, j-1);
		ifInBoundsAndEmptyMark(i-2, j+1);
		ifInBoundsAndEmptyMark(i-1, j+2);
		ifInBoundsAndEmptyMark(i+1, j+2);
		ifInBoundsAndEmptyMark(i+2, j+1);
		ifInBoundsAndEmptyMark(i+2, j-1);
		ifInBoundsAndEmptyMark(i+1, j-2);
		return validityMatrix;
	}
	public static function mapTilesForTargetInRange(from : TileSpace, radius : Int, ?allowSelf = true){
		var validityMatrix = tilesToValidityMatrix(Battlefield.tiles);
		crawlInRangeWithFunction(validityMatrix, from.getI(), from.getJ(), radius, (data) -> {
			if (data.value == UNIT)
				data.mark(VALID);
			return true;
		});
		if (allowSelf == false)
			validityMatrix.set(from.getI(), from.getJ(), UNAVAILABLE);
		else
			validityMatrix.set(from.getI(), from.getJ(), VALID);
		return validityMatrix;
	}
	public static function mapTilesForTileInRange(from: TileSpace, radius: Int, ?allowUnits = true) {
		var validityMatrix = tilesToValidityMatrix(Battlefield.tiles);
		crawlInRangeWithFunction(validityMatrix, from.getI(), from.getJ(), radius, (data) -> {
			if (data.value == UNIT) {
				if (allowUnits)
					data.mark(VALID);
			} else {
				data.mark(VALID);
			}
			return true;
		});
		return validityMatrix;
	}
	public static function mapTilesForPlayerUnitsInRange(from : TileSpace, radius : Int) {
		var validityMatrix = tilesToValidityMatrix(Battlefield.tiles);
		validityMatrix.set(from.getI(), from.getJ(), UNAVAILABLE);
		crawlInRangeWithFunction(validityMatrix, from.getI(), from.getJ(), radius, (stepData) -> {
			if (stepData.value == EMPTY)
				return true;
			if (stepData.value == UNIT) {
				if (Battlefield.getTile(stepData.i, stepData.j).unitOnIt.owner == PLAYER)
					stepData.mark(VALID);
				return true;
			}
			return false;
		});
		// crawlInRange(validityMatrix, from.matrixY, from.matrixX, radius, {
		// 	allowPlayerUnits: true,
		// 	allowEmptySpace: true,
		// 	allowEnemyUnits: false,
		// 	allowSelf: false
		// });
		return validityMatrix;
	}
	public static function mapTilesAllEnemies(tiles) {
		var validityMatrix = new Matrix<Int>(tiles.nRows, tiles.nCols);
		tiles.forEachIndices(function(i, j){
			if(tiles.get(i,j).unitOnIt != null && tiles.get(i, j).unitOnIt.owner == ENEMY)
				validityMatrix.set(i, j, VALID);
		});
		return validityMatrix;
	}
	public static function mapTilesAllPlayerCharacters(tiles) {
		var validityMatrix = new Matrix<Int>(tiles.nRows, tiles.nCols);
		tiles.forEachIndices(function(i, j){
			if(tiles.get(i,j).unitOnIt != null && tiles.get(i, j).unitOnIt.owner == PLAYER)
				validityMatrix.set(i, j, VALID);
		});
		return validityMatrix;
	}


	
	





	// ----------------------------- Getters and Finders -----------------------------

	static function isTherePlayerUnitOnRight(i, j) {
		return
			Battlefield.tiles.isInBounds(i, j+1) &&
			Battlefield.getTile(i, j+1).hasUnit() &&
			Battlefield.getTile(i, j+1).unitOnIt.owner == PLAYER;
	}
	public static function findShortestPath(from: TileSpace, isUnitLarge: Bool = false, stopCondition: Int -> Int -> Int): Array<Position> {
		final startingPos  = new Position(from.getI(), from.getJ());
		final startingNode = new PathNode(startingPos);
		var nodeMatrix   = new Matrix<PathNode>(Battlefield.tiles.nRows, Battlefield.tiles.nCols);
		nodeMatrix.set(startingPos.i, startingPos.j, startingNode);
		var nodesToVisit = [startingPos];
		var currentPosition : Position = null;
		var illegalPositions : Matrix<Int>;
		var visitedMatrix = new Matrix<Int>(nodeMatrix.nRows, nodeMatrix.nCols);
		final NOT_VISITED = 0; final VISITED = 1;
		visitedMatrix.setAll(NOT_VISITED);


		if (isUnitLarge) {
			illegalPositions = battlefieldTilesToValidityMatrix();
			illegalPositions.forEachIndices((i, j) -> {
				if (j == nodeMatrix.nCols - 1) illegalPositions.set(i, j, UNAVAILABLE);			// Make right-most row unavailable
				else {																			// Make the left tile near all units (except me) unavailable
					final thereIsUnitOnRight = Battlefield.tiles.get(i, j + 1).hasUnit();
					final thatUnitIsMe	   	 = startingPos.equals(i, j + 1);
					if (thereIsUnitOnRight && !thatUnitIsMe) {
						illegalPositions.set(i, j, UNAVAILABLE);
					}
				}
			});
		}
		

		var didFind = false;
		while (nodesToVisit.length > 0) {
			currentPosition = nodesToVisit.shift();			// First position in the queue
			final i = currentPosition.i;
			final j = currentPosition.j;
			final currentNode = nodeMatrix.get(i, j);		// Should never be null
			
			function stepTowards(i: Int, j: Int): Int {

				function queueToVisitThisNode() {
					nodeMatrix.set(i, j, new PathNode(currentPosition));
					nodesToVisit.push(new Position(i,j));
					visitedMatrix.set(i, j, VISITED);
				}
				
				
				if (!nodeMatrix.isInBounds(i, j)) return BLOCKED;
				if (visitedMatrix.get(i, j) == VISITED) return BLOCKED;

				if (isUnitLarge) {
					final isThisActuallyMe = i == startingPos.i && j == startingPos.j + 1;
					if (illegalPositions.get(i, j) == UNAVAILABLE) {
						return stopCondition(i, j);
					}
					if (isThisActuallyMe) {
						queueToVisitThisNode();
						return CONTINUE;
					}
				}
				
				final signal = stopCondition(i, j);
				
				if (signal == STOP) return STOP;
				else if (signal == BLOCKED) return BLOCKED;
				else if (signal == CONTINUE) {
					if (nodeMatrix.get(i, j) == null) {			// If this node was NOT already setup and queued to visit
						queueToVisitThisNode();
					}
					return CONTINUE;
				} else {
					throwAndLogError('No such signal: ${signal}');
					return CONTINUE;
				}
			}
			
			if (stepTowards(i, j-1) == STOP) { didFind = true; break; }
			if (stepTowards(i-1, j) == STOP) { didFind = true; break; }
			if (stepTowards(i+1, j) == STOP) { didFind = true; break; }
			if (stepTowards(i, j+1) == STOP) { didFind = true; break; }
		}
		
		if (!didFind)
			return null;

		var positionSequence: Array<Position> = [];		// An array of positions = a sequence of tile positions a unit can follow to reach a PLAYER unit
		while (!currentPosition.equalsPosition(startingPos)) {
			positionSequence.push(currentPosition);
			var currentNode = nodeMatrix.get(currentPosition.i, currentPosition.j);
			currentPosition = currentNode.gotHereFrom;
		}
		positionSequence.reverse();
		return positionSequence;
	}
	public static function findShortestPathToAPlayerJumpOverUnits(from: TileSpace, isUnitLarge: Bool = false) {
		return findShortestPath(from, isUnitLarge, (i, j) -> {
			if (isUnitLarge && isTherePlayerUnitOnRight(i, j)) return STOP;
			final unitThere = Battlefield.getTile(i, j).unitOnIt;
			if (unitThere != null && unitThere.owner == PLAYER) return STOP;
			return CONTINUE;
		});
	}
	public static function findShortestPathToAPlayerWithBlockAtUnits(from: TileSpace, isUnitLarge: Bool = false) {
		return findShortestPath(from, isUnitLarge, (i, j) -> {
			if (isUnitLarge && isTherePlayerUnitOnRight(i, j)) return STOP;
			final unitThere = Battlefield.getTile(i, j).unitOnIt;
			if (unitThere != null) {
				if (unitThere.owner == PLAYER) return STOP;
				else return BLOCKED;
			} else return CONTINUE;
		});
	}

	// Returns the last found tile in that direction that matches the given function
	public static function getLastTileInDirection(i: Int, j: Int, range: Int = 0, direction: Int, funcThatMatchesLastTile: TileSpace -> Bool) {
		var previousTile: TileSpace = null;
		var tileIterator = Battlefield.getTile(i, j);
		if (tileIterator == null) return null;
		if (funcThatMatchesLastTile(tileIterator) == false) return null;
		var currentRange = 1;
		while (tileIterator != null && funcThatMatchesLastTile(tileIterator) && currentRange < range) {
			previousTile = tileIterator;
			tileIterator = tileIterator.getNextTileInDirection(direction);
		}
		if (tileIterator != null && funcThatMatchesLastTile(tileIterator)) return tileIterator;
		if (previousTile != null) return previousTile;
		return null;
	}
	public static function getAllTilesInDirection(firstTile: TileSpace, range: Int = 0, direction: Int): Array<TileSpace> {
		if (range == 0 || firstTile == null) return [];
		var tileIterator = firstTile;
		var remainingRange = range;
		final tiles: Array<TileSpace> = [];
		while (remainingRange > 0 && tileIterator != null) {
			tiles.push(tileIterator);
			final nextTile = tileIterator.getNextTileInDirection(direction);
			if (nextTile == null)
				break;
			tileIterator = nextTile;
			remainingRange--;
		}
		return tiles;
	}
	public static function getRandomValidPosition(validityMatrix: Matrix<Int>) {
		final validPositions = validityMatrix.filterToArrayIndices(
			(i, j) -> validityMatrix.get(i, j) == VALID
		);
		if (validPositions == null || validPositions.length == 0)
			return null;
		final randomValidPos = validPositions[randomIntBetween(0, validPositions.length - 1)];
		return randomValidPos;
	}
	public static function getSkillShotTargetsTile(fromTile : TileSpace, spell : Spell, direction : Int, casterIsLarge : Bool = false) : TileSpace{	// Returns first unit in its path
		// TODO: Does this work with large units?
		var currentTile    = if (casterIsLarge && direction == RIGHT) fromTile.getRightTile() else fromTile;
		var remainingRange = spell.getRange();
		while (remainingRange > 0) {
			var nextTile = currentTile.getNextTileInDirection(direction);
			if (nextTile == null) {
				return currentTile;
			}
			if (nextTile.unitOnIt != null) {
				return nextTile;
			}
			currentTile = nextTile;
			remainingRange--;
		}
		return currentTile;	// If it hits thin air, return the last one
	}
	public static function getSkillShotTargetsTileNoSpell(fromTile : TileSpace, range: Int, direction : Int, casterIsLarge : Bool = false) : TileSpace{	// Returns first unit in its path
		// TODO: Does this work with large units?
		var currentTile    = if (casterIsLarge && direction == RIGHT) fromTile.getRightTile() else fromTile;
		var remainingRange = range;
		while (remainingRange > 0) {
			var nextTile = currentTile.getNextTileInDirection(direction);
			if (nextTile == null) {
				return currentTile;
			}
			if (nextTile.unitOnIt != null) {
				return nextTile;
			}
			currentTile = nextTile;
			remainingRange--;
		}
		return currentTile;	// If it hits thin air, return the last one
	}
	public static function getFirstValidPosition(m : Matrix<Int>) : Position {
		for(i in 0...m.nRows){
			for(j in 0...m.nCols){
				if(m.get(i,j) == VALID) return new Position(i, j);
			}
		}
		return null;
	}
	public static function getAllValidPositions(m: Matrix<Int>): Array<Position> {
		return m.filterToArrayIndices((i, j) -> m.get(i, j) == VALID);
	}
	
	public static function intersectValidityMatrices(m1 : Matrix<Int>, m2 : Matrix<Int>) {	// Returns a matrix with VALID at a position only if both m1 and m2 have VALID at that same position; otherwise 0
		var m3 = new Matrix<Int>(m1.nRows, m1.nCols);
		m3.setAll(0);
		m1.forEachIndices(function(i,j){
			if(m1.get(i,j) == m2.get(i,j) && m1.get(i,j) == VALID)
				m3.set(i, j, VALID);
		});
		return m3;
	}
	public static function joinValidityMatrices(primaryMatrix: Matrix<Int>, secondaryMatrix: Matrix<Int>) {
		// Returns the 'unification' of primaryMatrix and secondaryMatrix
		// (aka primaryMatrix OR secondaryMatrix)
		// Default values for the returned matrix are from primaryMatrix
		var newMatrix = new Matrix<Int>(primaryMatrix.nRows, secondaryMatrix.nCols);
		primaryMatrix.forEachIndices((i, j) -> {
			if (primaryMatrix.get(i, j) == VALID || secondaryMatrix.get(i, j) == VALID) {
				newMatrix.set(i, j, VALID);
			} else {
				newMatrix.set(i, j, primaryMatrix.get(i, j));
			}
		});
		return newMatrix;
	}
	public static function subtractValidityMatrices(primaryMatrix: Matrix<Int>, secondaryMatrix: Matrix<Int>) {
		var newMatrix = new Matrix<Int>(primaryMatrix.nRows, secondaryMatrix.nCols);
		primaryMatrix.forEachIndices((i, j) -> {
			if (primaryMatrix.get(i, j) == VALID && secondaryMatrix.get(i, j) == VALID) {
				newMatrix.set(i, j, UNAVAILABLE);
			} else {
				newMatrix.set(i, j, primaryMatrix.get(i, j));
			}
		});
		return newMatrix;
	}
	public static function traceValidityMatrix(m: Matrix<Int>, ?message: String) {
		for (i in 0...m.nRows) {
			var line = "";
			for (j in 0...m.nCols) {
				final pos = m.get(i, j);
				final symbol =
					if (pos == VALID) 'O' else
					if (pos == EMPTY) '_' else
					if (pos == UNIT) 'T' else
					if (pos == UNAVAILABLE) 'x'
					else '?';
				line += symbol + " ";
			}
			if (i == 0 && message != null) {
				trace(line + '\t| ${message}');
			} else {
				trace(line);
			}
		}
	}

	
}

typedef CrawlObject = { i: Int, j: Int, radius: Int }
class PathNode { // Used in findShortestPath algorithm
	public var gotHereFrom : Position;
	public function new(from) gotHereFrom = from;
}
