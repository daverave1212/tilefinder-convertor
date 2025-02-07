
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

import U.*;
import Math.*;
import Std.int;
import haxe.Timer;

import scripts.SpecialEffectsFluff.sayBubble;
import scripts.Constants.*;
import scripts.UnitTemplate.*;

using U;
using Lambda;

class UnitBuffsComponent {
	public var unit: Unit;
	public var buffIcons: Array<ImageX> = [];
	public var isHidden = false;
	
	public function new(self: Unit) {
		unit = self;
	}

	public function update() {
		trace('Updating buffs for ${unit.name}');
		for (icon in buffIcons) {
			icon.kill();
		}
		buffIcons = [];
		if (unit.isDead) return;
		if (unit.activeBuffs == null || unit.activeBuffs.length == 0) return;
		trace('** Drawing ${unit.activeBuffs.length} buffs');
		for (i in 0...unit.activeBuffs.length) {
			final buff = unit.activeBuffs[i];
			if (buff == null) {
				Game.q('WARNING: Null buff on unit ${unit.name}');
			}
			final buffImage = new ImageX(buff.getIconPath(), 'HealthBarsFrames');
			// buffImage.setWidth(4);
			// buffImage.setHeight(4);
			buffIcons.push(buffImage);
		}
		updatePositions();
	}

	public function updatePositions() {
		var barsXCenter = unit.getXCenterForBars();
		var barsY =
			if (unit.tileOn != null) unit.tileOn.getYBottom() - 4
			else unit.actor.getY() + unit.actor.getHeight() + 5;
		
		final buffsY = barsY - 1 - 8 - 3;
		final buffsX = if (unit.isLarge == false) barsXCenter - 14 else (barsXCenter - 26);

		for (i in 0...buffIcons.length) {
			final buffIcon = buffIcons[i];
			buffIcon.setY(buffsY);
			buffIcon.setX(buffsX + i * 9);
		}
	}

	public function hide() {
		isHidden = true;
		for (b in buffIcons) {
			if (b != null) {
				b.hide();
			}
		}
	}
	public function show() {
		isHidden = false;
		for (b in buffIcons) {
			if (b != null) {
				b.show();
			}
		}
	}

	
}

class UnitAttachmentsComponent {

	public var unit: Unit;
	public var attachmentActors: Array<{actor: Actor, xOffset: Float, yOffset: Float}> = [];

	public function new(self: Unit) {
		unit = self;
	}

	public function hasAttachment(animationName: String) {
		final foundAttachments = attachmentActors.filter(a -> a.actor.getAnimation() == animationName);
		return foundAttachments.length != 0;
	}
	public function addAttachment(animationName: String, ?xOffset: Float = 0, ?yOffset: Float = 0) {
		if (unit.isDead) return;
		if (unit.actor.isAnimationPlaying() == false) {
			warnLog('Unit ${unit.name} is hidden and can not attach ${animationName}');
			return;
		}
		final attachment = createActor('UnitAttachmentActor', unit.actor.getLayerName());
		attachment.setAnimation(animationName);
		attachment.setXCenter(unit.actor.getXCenter() + xOffset);
		attachment.setYCenter(unit.actor.getYCenter() + yOffset);
		attachmentActors.push({actor: attachment, xOffset: xOffset, yOffset: yOffset});
	}
	public function getAttachment(animationName: String): Actor {
		final foundAttachments = attachmentActors.filter(a -> a.actor.getAnimation() == animationName);
		if (foundAttachments.length == 0) {
			warnLog('No attachment ${animationName} found on unit ${unit.name}');
			return null;
		}
		return foundAttachments[0].actor;
		
	}
	public function removeAttachment(animationName: String) {
		final foundAttachment: Actor = getAttachment(animationName);
		if (foundAttachment == null) return;
		attachmentActors = attachmentActors.filter(a -> a.actor != foundAttachment);
		foundAttachment.growTo(2, 2, 0.25, Easing.linear);
		foundAttachment.fadeTo(0, 0.25, Easing.linear);
		doAfter(250, () -> {
			recycleActor(foundAttachment);
		});
	}

	public function slideToActorPosition(actorDestinationX: Float, actorDestinationY: Float, time: Float) {
		for (a in attachmentActors) {
			if (time <= 0) {
				a.actor.setX(actorDestinationX + unit.actor.getWidth() / 2 - a.actor.getWidth() / 2 + a.xOffset);
				a.actor.setY(actorDestinationY + unit.actor.getHeight() / 2 - a.actor.getHeight() / 2 + a.yOffset);
			} else {
				a.actor.moveTo(
					actorDestinationX + unit.actor.getWidth() / 2 - a.actor.getWidth() / 2 + a.xOffset,
					actorDestinationY + unit.actor.getHeight() / 2 - a.actor.getHeight() / 2 + a.yOffset,
					time,
					Easing.expoOut
				);
			}
			a.actor.moveToLayer(engine.getLayerByName(unit.actor.getLayerName()));
		}
	}
	public function updatePosition() {
		for (a in attachmentActors) {
			a.actor.setXCenter(unit.actor.getXCenter() + a.xOffset);
			a.actor.setYCenter(unit.actor.getYCenter() + a.yOffset);
			a.actor.moveToLayer(engine.getLayerByName(unit.actor.getLayerName()));
		}
	}

	public function clear() {
		for (a in attachmentActors) {
			recycleActor(a.actor);
		}
		attachmentActors = [];
	}
	public function hide() {
		for (a in attachmentActors) {
			a.actor.disableActorDrawing();
		}
	}
	public function show() {
		for (a in attachmentActors) {
			a.actor.enableActorDrawing();
		}
	}



}

// Contains the functionality for the health bar above him
class UnitBarsComponent {

	public var unit : Unit;	// Unit containing this

	public var healthBar			: ResourceBar;
	public var manaBar				: ResourceBar;
	public var healthFrameActor 	: Actor;
	public var manaFrameActor		: Actor;
	public var healthBackgroundActor: Actor;
	public var manaBackgroundActor	: Actor;
	public var blockActor			: Actor;
	public var blockTextImage		: ImageX;
	public var healthTextImage		: ImageX;
	public var manaTextImage		: ImageX;

	inline function hasMana() return unit.stats.mana > 0;
	public function getManaBarPointForTutorialIndicator() return new Point(manaBar.getX() + manaBar.getWidth() + 2, manaBar.getY() - 2);
	function shouldDrawMana() return hasMana();

	public function new(_unit: Unit) {
		if (_unit == null) throwAndLogError('Null unit given to UnitBarsComponent');
		if (_unit.stats == null) throwAndLogError('Unit ${_unit.name} has null stats');
		unit = _unit;
		healthFrameActor = createActor("ResourceBarFrameActor", "HealthBarsFrames");
		healthBackgroundActor = createActor("ResourceBarBackgroundActor", "HealthBarsBackgrounds");
		if (unit.isLarge) {
			healthFrameActor.setAnimation('HealthLarge');
			healthBackgroundActor.setAnimation('HealthLarge');
		} else {
			healthFrameActor.setAnimation('Health');
			healthBackgroundActor.setAnimation('Health');
		}
		healthFrameActor.moveToTop();
		final healthBarAnimation = getHealthBarAnimationByOwner(unit.owner, unit.isLarge);
		healthBar = new ResourceBar("ResourceBarActor", "HealthBars", unit.stats.health, { initialAnimation: healthBarAnimation });
		if (shouldDrawMana()) {	// Only display mana for enemies if the player has a Mage to drain mana
			manaFrameActor = createActor("ResourceBarFrameActor", "HealthBarsFrames");
			manaBackgroundActor = createActor("ResourceBarBackgroundActor", "HealthBarsBackgrounds");
			manaFrameActor.setAnimation('Mana');
			manaBackgroundActor.setAnimation('Mana');
			manaFrameActor.moveToTop();
			manaBar = new ResourceBar("ResourceBarActor", "HealthBars", unit.stats.mana);
			manaBar.setAnimation('Blue');
		}
		blockActor = createActor('BlockActor', 'HealthBarsBlock');
		blockActor.disableActorDrawing();
		updateTexts();
	}

	function getHealthText() return '${unit.health}/${unit.stats.health}';
	function getManaText() return '${unit.mana}/${unit.stats.mana}';
	function getHealthWidth() return getFont(SHADED_FONT).getTextWidth(getHealthText()) / (Engine.SCALE * 2);
	function getManaWidth() return getFont(SHADED_FONT).getTextWidth(getManaText()) / (Engine.SCALE * 2);
	function getHealthManaHeight() return getFont(SHADED_FONT).getHeight() / (Engine.SCALE * 2);
	function recreateBlockText() {
		killBlockText();
		blockTextImage = U.createTextToImageX('${unit.block}', getFont(SHADED_FONT), 'HealthBarsBlock');
	}
	function killBlockText() {
		if (blockTextImage != null) {
			blockTextImage.kill();
			blockTextImage = null;
		}
	}
	public function updateTexts() {
		if (unit.block > 0) {
			recreateBlockText();
		}
		final health = getHealthText();
		if (healthTextImage != null) {
			healthTextImage.kill();
		}
		final font = getFont(SHADED_FONT);
		healthTextImage = U.createTextToImageX(health, font, 'HealthBars');
		healthTextImage.setWidth(getHealthWidth());				// Make it original width
		healthTextImage.setHeight(getHealthManaHeight());		// Make it original height
		
		if (shouldDrawMana()) {
			final mana = getManaText();
			if (manaTextImage != null) {
				manaTextImage.kill();
			}
			manaTextImage = U.createTextToImageX(mana, getFont(SHADED_FONT), 'HealthBars');
			manaTextImage.setWidth(getManaWidth());
			manaTextImage.setHeight(getHealthManaHeight());
		}
	}

	public static function getHealthBarAnimationByOwner(owner: Int, ?isLarge: Bool = false) {
		final healthBarAnimation =
			if (owner == PLAYER) 'Green'
			else if (owner == ENEMY && isLarge) 'RedLarge'
			else 'Red';
		return healthBarAnimation;
	}

	public function setMaxHealthValue(m: Float) {
		healthBar.reset(m);
		update();
	}
	public function update() {
		if (unit.isDead) {
			hide();
			return;
		}
		healthBar.set(unit.health);
		if (shouldDrawMana())
			manaBar.set(unit.mana);
		if (unit.block > 0) {
			blockActor.enableActorDrawing();
			recreateBlockText();
		} else {
			blockActor.disableActorDrawing();
			if (blockTextImage != null) {
				killBlockText();
			}
		}
		updateTexts();
		moveToUnit();
	}

	function moveToUnit() {
		var x = unit.getXCenterForBars();
		var y =
			if (unit.tileOn != null) unit.tileOn.getYBottom() - 4
			else unit.actor.getY() + unit.actor.getHeight() + 5;
		healthBar.setXCenter(x);
		healthBar.setYCenter(y);
		healthFrameActor.setXCenter(x);
		healthFrameActor.setYCenter(y);
		healthBackgroundActor.setXCenter(x);
		healthBackgroundActor.setYCenter(y);
		healthTextImage.setX(healthFrameActor.getXCenter() - getHealthWidth() / 2);
		healthTextImage.setY(healthFrameActor.getYCenter() - getHealthManaHeight() / 2 + 1);
		if (shouldDrawMana()) {
			manaFrameActor.setXCenter(x);
			manaFrameActor.setYCenter(y + healthFrameActor.getHeight() - 1);
			manaBackgroundActor.setXCenter(x);
			manaBackgroundActor.setYCenter(y + healthFrameActor.getHeight() - 2);
			manaBar.setXCenter(x + 1);
			manaBar.setYCenter(y + healthFrameActor.getHeight() - 1);
			manaTextImage.setX(manaFrameActor.getXCenter() - getManaWidth() / 2);
			manaTextImage.setY(manaFrameActor.getYCenter() - getHealthManaHeight() / 2 + 1);
		}
		if (unit.block > 0) {
			final yOffset = if (unit.owner == PLAYER) 0 else -2;	// If player, it's lower to account for mana bar; otherwise, it's higher.
			blockActor.setX(healthFrameActor.getX() - 6);
			blockActor.setY(healthFrameActor.getY() - 2 + yOffset);
			if (blockTextImage != null) {
				blockTextImage.setX(blockActor.getX() + blockActor.getWidth() / 2 - blockTextImage.getWidth() / 2);
				blockTextImage.setY(blockActor.getY() + blockActor.getHeight() / 2 - blockTextImage.getHeight() / 2 + 1);
			}
		}
	}

	public function hide() {
		healthBar.hide();
		healthFrameActor.disableActorDrawing();
		healthBackgroundActor.disableActorDrawing();
		healthTextImage.hide();
		if (shouldDrawMana()) {
			manaBar.hide();
			manaFrameActor.disableActorDrawing();
			manaBackgroundActor.disableActorDrawing();
			manaTextImage.hide();
		}
		blockActor.disableActorDrawing();
		killBlockText();
	}

	public function show() {
		if (unit.isDead) {
			trace('WARNING: Can not show bars when unit is dead.');
			return;
		}
		healthBar.show();
		healthFrameActor.enableActorDrawing();
		healthBackgroundActor.enableActorDrawing();
		healthTextImage.show();
		if (shouldDrawMana()) {
			manaBar.show();
			manaFrameActor.enableActorDrawing();
			manaBackgroundActor.enableActorDrawing();
			manaTextImage.show();
		}
		if (unit.block > 0) {
			blockActor.enableActorDrawing();
			recreateBlockText();
		}
	}

}

// A Unit is a creature (or rock, or barricade...) on the Battlefield
// EntityWithStats just means it has stats (Stats) and a name, health and mana
// Note: Unit makes no sense outside of Battlefield.
class Unit extends EntityWithStats
{

	public static var k = {
		slideToTileTime: 0.4,
		oneMoment: 750
	}

	public var uniqueID				 : Int = -1;
	static var uniqueIDCounter		 : Int = 1;

	public var damageVariation		 : Int = 0;

	public var actor				 : Actor = null;		// Actor representing the unit
	public var isFlippedHorizontally : Bool = false;
	public var actorScale			 : Float = 1.0;
	public var originalActorHeight	 : Float = 0;
	public var areMoveParticlesDisabledOnce = true;				// Enabled after unit is created

	public var doesIgnoreResistances : Bool = false;
	public var damageTakenMultiplier : Float = 1.0;			// Used for buffs for example, to reduce damage taken
	public var damageDoneMultiplier  : Float = 1.0;			// Used for buffs for example, to reduce damage done
	public var block				 : Int = 0;
	public var doesBlockDecay		 = true;				// Changed only by some spells

	public var isDead 				 : Bool  = false;
	public var owner				 : Int = NEUTRAL;
	public var tileOn				 : TileSpace;
	public var spells				 : Array<Spell>;		// Spells
	public var unitBarsComponent	 : UnitBarsComponent;
	public var unitBuffsComponent	 : UnitBuffsComponent;
	public var unitAttachmentsComponent: UnitAttachmentsComponent;
	public var isLarge 				 : Bool = false;

	public var isRooted				 : Bool = false;
	public var isImmuneToSilence	 : Bool = false;			// Only set to true by items and such
	public var isImmuneToRoot		 : Bool = false;			// Only set to true by items and such
	public var activeBuffs			 : Array<Buff>;
	
	public var originalY			 : Float = 0;				// Used for breathing
	var stopBreathing		 		 : Void -> Void;			// Assigned automatically by startBreathing

	public var unitTemplate			 : UnitTemplate = null;		// Exists only if it was made from a template
	public var playerCharacter		 : PlayerCharacter = null;	// Exists only if it was made from a player character
	public var playerMercenary		 : PlayerMercenary = null;	// Exists only if it was made from a player mercenary

	public var combatStartQuotes	 : Array<String>;
	public var killQuotes			 : Array<String>;
	
	public var defaultSayOffsetX 	 = 0;
	public var defaultSayOffsetY 	 = -40;

	public var spellBeingDelayed	 : Spell;
	public var tilesMarkedRed		 : Array<TileSpace> = [];
	public var spellBeingDelayedTargetTile: TileSpace;
	public var spellBeingDelayedOriginTile: TileSpace;

	public var damageUnitModifications : Array<Unit -> Int -> Int> = [];	// Target -> Old damage -> new damage

	public var aiData				 : Dynamic;
	public var tileWhereDied		 : TileSpace;
	public var currentAISpellIndex	 : Int = -1;
	public var customData = {
		ints: new Map<String, Int>(),
		strings: new Map<String, String>()
	}
	public function initCustomInt(propName: String, value: Int) {	// Sets that property if it doesn't exist
		if (!customData.ints.exists(propName)) {
			customData.ints[propName] = value;
		}
	}
	public function initCustomString(propName: String, value: String) {	// Sets that property if it doesn't exist
		if (!customData.strings.exists(propName)) {
			customData.strings[propName] = value;
		}
	}

	
	

	
	private function new(o: Int) {
		actor = createActor("UnitActor", 'Units4');
		owner = o;
		U.onClick(onClick, actor);
		U.onEnter(onEnter, actor);
		U.onExit(onExit, actor);
		activeBuffs = [];
		uniqueIDCounter ++;
		uniqueID = uniqueIDCounter;
		unitAttachmentsComponent = new UnitAttachmentsComponent(this);
		unitBuffsComponent = new UnitBuffsComponent(this);
	}

	public static function createFromUnitTemplate(unitTemplate: UnitTemplate, o: Int) {
		var unit = new Unit(o);

		unit.unitTemplate = unitTemplate;
		unit.name = unitTemplate.name;
		unit.damageVariation = unitTemplate.damageVariation;
		unit.stats = unitTemplate.stats.clone();
		unit.resistances = unitTemplate.resistances.clone();
		unit.amplifications = new Amplifications();	// Units from templates have no amplifications, because no point in that
		unit.spells = [for (s in unitTemplate.spells) Spell.createFromTemplate(SpellDatabase.get(s))];
		unit.combatStartQuotes = unitTemplate.getCombatStartQuotes();
		unit.killQuotes = unitTemplate.getKillQuotes();
		unit.isLarge = unitTemplate.isLarge;
		unit.health = unit.getMaxHealth();
		unit.mana = unit.getMaxMana();

		unit.setupActorAnimation();

		if (percentChance(50) && o == NEUTRAL && !unitTemplate.neverFlip) flipActorHorizontally(unit.actor);
		if (unitTemplate.isFlippedHorizontally == true) unit.flipHorizontally();
		if (o != NEUTRAL || unit.hasTag(NEUTRAL_WITH_HEALTH_BAR))
			unit.unitBarsComponent = new UnitBarsComponent(unit);
		return unit;
	}
	public static function createFromPlayerCharacter(playerCharacter: PlayerCharacter, o: Int) {
		var unit = new Unit(o);

		unit.playerCharacter = playerCharacter;
		unit.name = playerCharacter.getClassName();
		unit.stats = playerCharacter.stats.clone();
		unit.resistances = playerCharacter.resistances.clone();
		unit.amplifications = playerCharacter.amplifications.clone();
		unit.spells = [for (s in playerCharacter.equippedSpells) Spell.createFromTemplate(SpellDatabase.get(s))];
		unit.combatStartQuotes = playerCharacter.getCombatStartQuotes();
		unit.killQuotes = playerCharacter.getKillQuotes();
		unit.health = playerCharacter.health;
		unit.mana = unit.getMaxMana();
		if (o != NEUTRAL)
			unit.unitBarsComponent = new UnitBarsComponent(unit);

		unit.setupActorAnimation();
		return unit;
	}
	public static function createFromPlayerMercenary(playerMercenary: PlayerMercenary, o: Int) {
		var unit = createFromUnitTemplate(playerMercenary.unitTemplate, o);
		unit.playerMercenary = playerMercenary;
		unit.health = playerMercenary.health;
		return unit;
	}
	public function setupActorAnimation() {
		if (playerCharacter != null) {
			actor.setAnimation(playerCharacter.getClassName());
		} else if (unitTemplate != null) {	// Implicitly also playerMercenary, since they are also from templates
			actor.setAnimation(
				if (unitTemplate.animationUsed != null && unitTemplate.animationUsed.length > 0) unitTemplate.animationUsed
				else unitTemplate.name
			);
		} else {
			trace('WARNING: Unit ${name} has playerCharacter or unitTemplate');
		}
		originalActorHeight = actor.getHeight();
	}

	public function startBreathing() {
		actor.growTo(0.975, 1.05, 0, Easing.linear);
		actor.moveTo(actor.getX(), actor.getY() - actor.getHeight() * 0.025, 0, Easing.linear);
		var willStopBreathing = false;
		stopBreathing = function() {
			actor.growTo(1, 1, 0, Easing.linear);
			actor.moveTo(actor.getX(), originalY, 0, Easing.linear);
			willStopBreathing = true;
		}
		function keepBreathing() {
			actor.growTo(1.025, 0.95, 1, Easing.quadOut);
			actor.moveTo(actor.getX(), actor.getY() + actor.getHeight() * 0.05, 1, Easing.quadOut);
			doAfter(1250, function(): Void {
				if (willStopBreathing) return;
				actor.growTo(0.975, 1.05, 1, Easing.quadOut);
				actor.moveTo(actor.getX(), actor.getY() - actor.getHeight() * 0.05, 1, Easing.quadOut);
				doAfter(1250, () -> {
					if (willStopBreathing) return;
					keepBreathing();
				});
			});
		}
		keepBreathing();
	}
	




	public function sayRandomStartQuote() {
		if (combatStartQuotes.length == 0) return;
		say(combatStartQuotes[randomIndex(combatStartQuotes)]);
	}
	public function say(s : String, ?seconds : Float = 1, ?yOffset = 0, ?xOffset = 0) {
		if (isDead) {
			trace('WARNING: Trying to say ${s} from dead unit ${name}');
			return null;
		}
		final offsetX = if (unitTemplate != null) unitTemplate.sayOffsetX else if (playerCharacter != null) playerCharacter.characterClass.sayOffsetX else 0;
		final offsetY = if (unitTemplate != null) unitTemplate.sayOffsetY else if (playerCharacter != null) playerCharacter.characterClass.sayOffsetY else 0;
		var sayX =
			offsetX + xOffset +
			if (isLarge) (tileOn.getXCenter() + tileOn.getNextTileInDirection(RIGHT).getXCenter()) / 2
			else tileOn.getXCenter();
		var sayY = tileOn.tileActor.getYCenter() + defaultSayOffsetY + yOffset + offsetY;
		if (sayY < getScreenY() + 50) {
			sayY += 50;
			if (sayX < getScreenX() + getScreenWidth() / 2) {
				sayX += 60;
				return SpecialEffectsFluff.sayCustomBubble(s, sayX, sayY, seconds, 'SayerToRightBackgroundActor');
			} else {
				sayX -= 60;
				return SpecialEffectsFluff.sayCustomBubble(s, sayX, sayY, seconds, 'SayerToLeftBackgroundActor');
			}
		} else {
			return sayBubble(s, sayX, sayY, seconds);
		}
	}

		// Spells
	// Called when round starts, after their effect triggers, so we don't draw them
	// No worries, hasSpell still works because it checks the template/PC spells
	public function removePassiveSpells() spells = spells.filter(spell -> spell.isPassive() == false);
	public function removeSpell(spellName: String) {
		spells = spells.filter(spell -> spell.getName() != spellName);
	}
	public function unwasteAllSpells() {
		for (spell in spells) {
			if ((spell.isMoveSpell() && isRooted) == false) {
				spell.isWasted = false;
			} 
		}
	}
	public var lastSpellCast: Spell;
	public function castSpellAndThen(spell : Spell, clickedTile : TileSpace, ?options: {
		?preventTurningTowardsTile: Bool,
		?fromCustomTile: TileSpace
	}, doThis : Void->Void) {
		if (spell == null) throw 'Null spell given to unit ${name}';
		if (isDead) {
			doThis();
			return;
		}
		if (options == null) options = {};

		if (isDead) {
			doThis();
			return;
		}

		function maybeTurnTowardsTileAndThen(andThen) {
			if (clickedTile == null) {
				andThen();
				return;
			}
			if (options.preventTurningTowardsTile == true || spell.getPreventTurningTowardsTile() == true) {
				andThen();
				return;
			}
			final isToRight = getJ() < clickedTile.getJ();
			final isToLeft = clickedTile.getJ() < getJ();
			if (isEnemy()) {
				if (isToRight && !!!isFlippedHorizontally && doesFlipHorizontally()) {
					flipHorizontally(andThen);
				} else if (isToLeft && isFlippedHorizontally && doesFlipHorizontally()) {
					flipHorizontally(andThen);
				} else {
					andThen();
				}
			} else if (isPlayer()) {
				if (isToRight && isFlippedHorizontally && doesFlipHorizontally()) {
					flipHorizontally(andThen);
				} else if (isToLeft && !isFlippedHorizontally && doesFlipHorizontally()) {
					flipHorizontally(andThen);
				} else {
					andThen();
				}
			} else {
				andThen();
			}
		}
		function setupDelayedSpell() {
			var tileOnBackup = tileOn;
			if (options.fromCustomTile != null) {
				tileOn = options.fromCustomTile;
			}
			playAudio('TileDangerAudio');
			final redHighlightMatrix = spell.getDelayedTargetHighlightMatrix(this, clickedTile);			
			Battlefield.markTilesRed(redHighlightMatrix);
			tilesMarkedRed = Pathing.getAllValidPositions(redHighlightMatrix).map(pos -> Battlefield.getTileByPos(pos));
			spellBeingDelayed = spell;
			spellBeingDelayedTargetTile = clickedTile;
			spellBeingDelayedOriginTile = tileOn;
			if (spell.template.onDelayedSetup != null) {
				spell.template.onDelayedSetup(this, clickedTile);
			}
			if (spell.hasAudioOnPrepare()) {
				playAudio(spell.template.audio.onPrepare);
			}
			tileOn = tileOnBackup;
		}	

		mana -= spell.getManaCost();
		if (mana < 0) trace('ERROR: Unit mana below 0!!!');
		lastSpellCast = spell;
		spell.cooldownRemaining = spell.template.cooldown;
		
		try {
			maybeTurnTowardsTileAndThen(() -> {
				unitBarsComponent.update();
				unitBuffsComponent.update();
				if (spell.isDelayed()) {
					Battlefield.triggerOnUnitCastSpellEvents(this, spell, clickedTile);
					setupDelayedSpell();
					checkAndTryDealInfectedDamage(spell);
					doThis();
				} else {
					final wasSpellInfected = spell.isInfected;											// It might change meanwhile
					Battlefield.triggerOnUnitCastSpellEvents(this, spell, clickedTile);
					if (spell.hasOnCastStart()) spell.doOnCastStart(this);
					spell.castByClickedTile(this, clickedTile, () -> {
						Battlefield.triggerAfterUnitCastSpellEvents(this, spell, clickedTile);
						if (wasSpellInfected)															// If the spell was infected meanwhile, dont damage
							checkAndTryDealInfectedDamage(spell);
						if (spell.ticksCooldowns())
							tickSpellCooldownsOnSpellCast(spell);
						doThis();
					});
				}
			});
		} catch (e: Any) {
			Game.q('ERROR: Caught an exception in Unit ${name} castSpellAndThen(${spell.getName()}) on tile ${if (clickedTile != null) clickedTile.toString() else "null tile"}.');
			Game.q('${e}');
			Game.q('Continuing...');
			if (doThis != null) doThis();
		}
	}
	public function getAISpellSequence() if (hasAISpellSequence()) return unitTemplate.ai.spellSequence; else return null;
	public function hasAISpellSequence() return unitTemplate.ai.spellSequence != null && unitTemplate.ai.spellSequence.length > 0;
	public function nextSpellInSequence() {
		if (!hasAISpellSequence()) throwAndLogError('Unit ${name} has no spell sequence.');
		currentAISpellIndex++;
		if (currentAISpellIndex >= getAISpellSequence().length) {
			currentAISpellIndex = 0;
		}
		return getAISpellSequence()[currentAISpellIndex];
	}
	public function setSpellSequenceIndex(i: Int) currentAISpellIndex = i;
	public function hasOverrideSpellSequence() return unitTemplate != null && unitTemplate.ai.overrideSpellSequence != null;
	public function getOverrideSpellSequence() return unitTemplate.ai.overrideSpellSequence(this, currentAISpellIndex);	// Returns a spell name to cast instead; if it returns null, then it will not override
	

		// Events
	public function markTurnTile() {
		if (tileOn != null) tileOn.markForUnitTurn(this);
	}
	public function unmarkTurnTile() {
		if (tileOn != null) tileOn.unmarkForUnitTurn(this);
	}
	public function onTurnStart(andThen: Void -> Void) {
		function castDelayedSpell(andThen: Void -> Void) {
			unmarkAllDelayedTiles();
			if (spellBeingDelayed.hasOnCastStart()) spellBeingDelayed.doOnCastStart(this);
			spellBeingDelayed.castByClickedTile(spellBeingDelayedOriginTile, this, spellBeingDelayedTargetTile, () -> {
				doAfter(k.oneMoment, andThen);
			});
			spellBeingDelayed = null;
			spellBeingDelayedTargetTile = null;
			spellBeingDelayedOriginTile = null;
		}
		if (isDead) {
			andThen();
			return;
		}
		unwasteAllSpells();
		if (doesBlockDecay)
			block = 0;
		if (unitTemplate != null && unitTemplate.onTurnStart != null) {
			unitTemplate.onTurnStart(this);
		}
		tickSpellCooldowns();
		tickBuffs();		
		if (isDead) {
			andThen();
			return;
		}
		trace('Triggering trap.');
		if (isSittingOnTrap()) {
			final trap = tileOn.trapOnIt;
			if (trap.hasOnUnitStartTurnEvent()) {
				trap.onUnitStartTurn(trap, this);
			}
		}
		trace('Is dead? ${isDead}');
		if (isDead) {
			trace('Yep. Continuing...');
			andThen();
			return;
		}
		unitBuffsComponent.update();
		unitBuffsComponent.updatePositions();
		if (stats.manaRegeneration != 0) {
			replenish(stats.manaRegeneration);
		}
		if (isDead == false) {
			updateBars();
			if (spellBeingDelayed != null) {
				castDelayedSpell(andThen);
			} else {
				andThen();
			}
		} else {
			andThen();
		}
	}
	public function onTurnEnd() {
		if (owner == NEUTRAL || isDead) return;
		if (unitTemplate != null && unitTemplate.onTurnEnd != null) {
			unitTemplate.onTurnEnd(this);
		}
		for (buff in activeBuffs) {
			if (buff.onTurnEnd != null) buff.onTurnEnd(this);
		}
	}
	public function whenKillingAUnit(unitKilled : Unit) {
		if (killQuotes.length > 0) {
			doAfter(k.oneMoment, () -> { say(killQuotes.shift(), 1.25); });
		}
	}
	function onClick() {
		Battlefield.onClickOnUnit(this);
	}
	function onEnter() {
		Battlefield.onEnterUnit(this);
	}
	function onExit() {
		Battlefield.onExitUnit(this);
	}
	public inline function hasOnDeathEvent() return unitTemplate != null && unitTemplate.onDeath != null;
	public inline function hasOnRoundEndEvent() return unitTemplate != null && unitTemplate.onRoundEnd != null;
	public inline function hasOnStuckEvent() return unitTemplate != null && unitTemplate.onStuck != null;
	function doOnDeathEvent() { if (unitTemplate != null && unitTemplate.onDeath != null) unitTemplate.onDeath(this); }
	public function doAfterDeathEvent(tileWhereDied: TileSpace) { if (unitTemplate != null && unitTemplate.afterDeath != null) unitTemplate.afterDeath(this, tileWhereDied); }
	public function doOnRoundEndEvent() { if (unitTemplate != null && unitTemplate.onRoundEnd != null) unitTemplate.onRoundEnd(this); }
	public function doOnStuckEvent(callback) unitTemplate.onStuck(this, callback);
	public function doOnSpawnEvent() {
		if (unitTemplate != null && unitTemplate.onSpawn != null)
			unitTemplate.onSpawn(this);
	}

	// Damage Getters
	function getRandomCritMultiplier(): Float {
		final randomOutcome = randomInt(int(min(stats.crit, 0)), 100);
		if (randomOutcome < 0) return 0.5;
		if (randomOutcome < stats.crit) return 1.5;
		return 1;
	}
	public function getDamageWithVariation() return int(randomInt(stats.damage, stats.damage + damageVariation) * damageDoneMultiplier);
	public function getDamageFlat() return int(stats.damage * damageDoneMultiplier);
	public function getSpellPowerWithVariation(?damageType: Int) return int(
		randomInt(stats.spellPower, stats.spellPower + damageVariation)
		* damageDoneMultiplier
		* if (damageType != null) amplifications.get(damageType) else 1
	);

	// Damage
	public var wasLastDamageInstanceDodged = false;
	public function damage(amount : Int, damageType : Int = PHYSICAL, ?ignoreDodge = false, ?damageSource: Unit): Int {	// Returns amount of damage taken
		if (isDead) {
			trace('WARNING: Attempting to damage dead unit ${name} for ${amount} of type ${damageType}');
			return 0;
		}
		if (percentChance(stats.dodge)) {
			doAfter(50, () -> { playAudio('WooshEchoedAudio'); });
			Battlefield.floatingTextManager.pump('Dodge!', getScreenXCenter(), getScreenYCenter());
			wasLastDamageInstanceDodged = true;
			return 0;
		}
		wasLastDamageInstanceDodged = false;
		doAfter(50, () -> { playAudio('HitAudio'); });
		var damageToTake : Int = amount;
		if (damageType == PHYSICAL) {
			damageToTake = getDamageReducedByArmor(damageToTake);
		} else if (damageType == FIRE || damageType == COLD || damageType == DARK || damageType == SHOCK || damageType == MAGIC) {
			var elementalMultiplier = resistances.get(damageType);
			if (doesIgnoreResistances && elementalMultiplier < 1) {
				elementalMultiplier = 1;
			}
			damageToTake = int(damageToTake * elementalMultiplier);
		}
		damageToTake = int(damageToTake * damageTakenMultiplier);
		if (damageToTake <= 0) damageToTake = 1;
		if (unitTemplate != null && unitTemplate.onTakingDamage != null)
			unitTemplate.onTakingDamage(this, damageToTake);
		Battlefield.floatingTextManager.pump(damageToTake, getScreenXCenter(), getScreenYCenter());
		if (block > 0) {
			if (block > damageToTake) {
				block -= damageToTake;
				damageToTake = 0;
			} else {				
				damageToTake -= block;
				block = 0;
			}
		}
		health -= damageToTake;
		updateBars();
		if (health <= 0) {
			kill(damageSource);
		} else {
			if (hasAudioOnHit())
				playAudio(getAudioOnHit());
			flash();
		}

		Battlefield.triggerAfterUnitTakingDamageEvent(damageSource, this, amount, damageType);
		if (unitTemplate != null && unitTemplate.afterTakingDamage != null)
			unitTemplate.afterTakingDamage(this, damageToTake);
		return damageToTake;
	}
	public function damageUnit(target: Unit, damageAmount: Float, ?damageType: Int = PHYSICAL): Int {
		final critMultiplier = getRandomCritMultiplier();
		var actualDamage: Float = damageAmount * critMultiplier * target.damageTakenMultiplier;
		if (hasSpell('Fiery Presence')) {
			actualDamage += Math.ceil(playerCharacter.level / 2);
			Effects.playParticleAndThen(target.getCenterPoint(), target.getCenterPoint(), 'Fire Ball', 800, () -> {});
		}
		if (critMultiplier == 2) {
			SpecialEffectsFluff.shakeScreenShort();
		}
		if (damageUnitModifications != null && damageUnitModifications.length > 0) {
			for (modFunc in damageUnitModifications) {
				actualDamage = modFunc(target, int(actualDamage));
			}
		}
		return target.damage(int(actualDamage), damageType, false, this);
	}
	public function damageUnits(units: Array<Unit>, damageAmount: Float, ?damageType: Int = PHYSICAL) {
		for (unit in units) {
			damageUnit(unit, damageAmount, damageType);
		}
	}
	public function heal(amount : Int) {
		health += amount;
		if (health > stats.health) {
			health = stats.health;
		}
		scrollGreen('${amount}');
		updateBars();
	}
	public function replenish(amount : Int) {
		amount = if (stats.mana - mana >= amount) amount else (stats.mana - mana);
		mana += amount;
		if (amount != 0) {
			scrollBlue('${amount}');
			updateBars();
		}
	}
	public function deplete(amount: Int) {
		mana -= amount;
		if (mana < 0)
			mana = 0;
		scrollBlue('-${amount}');
		updateBars();
	}
	public function addBlock(blockAmount: Int, ?options: Dynamic) {
		block += blockAmount;
		if (block < 0)
			block = 0;
		final scrollDelay: Int = if (options != null && options.textDelay != null) options.textDelay else 0;
		doAfter(scrollDelay, () -> {
			scrollGreen('${blockAmount} BLOCK');
		});
		updateBars();
	}
	public var preventDeathAnimationOnce = false;	// Can be set true by certain events; if true, prevents death animation once
	public function kill(?killingUnit: Unit, ?doAnimation = true) {
		if (hasAudioOnDeath()) {
			playAudio(getAudioOnDeath());
		}
		doOnDeathEvent();
		Battlefield.triggerOnUnitDeathEvents(killingUnit, this);
		unmarkAllDelayedTiles();
		isDead = true;
		tileWhereDied = tileOn;
		detachFromBoard();
		hideBars();
		unitBuffsComponent.hide();
		if (doAnimation && preventDeathAnimationOnce == false) {
			flinch(() -> {
				recycleActor(actor);
			});
		}
		else
			recycleActor(actor);
		if (preventDeathAnimationOnce)
			preventDeathAnimationOnce = false;
		unitAttachmentsComponent.clear();
		doAfterDeathEvent(tileWhereDied);
		Battlefield.triggerAfterUnitDeathEvents(this, tileWhereDied);
		if (Battlefield.getCurrentlyActiveUnit() == this && owner == PLAYER) {
			Battlefield.nextTurn();
		} else {
			Battlefield.endCombatIfDone();
		}
	}
	public function remove() {
		unmarkAllDelayedTiles();
		isDead = true;
		unitAttachmentsComponent.clear();
		hideBars();
		unitBuffsComponent.hide();
		detachFromBoard();
		recycleActor(actor);
	}
	public function revive(onTile: TileSpace, healthRemaining: Int = 1) {
		isDead = false;
		health = Std.int(Math.min(healthRemaining, stats.health));
		actor = createActor("UnitActor", 'Units4');
		setupActorAnimation();
		U.onClick(onClick, actor);
		activeBuffs = [];
		putOnTile(onTile);
		showBars();
		unitBuffsComponent.show();
		unitBuffsComponent.update();
	}
	public function silence() {
		interrupt();
		if (isImmuneToSilence || hasTag(IMMUNE_TO_SILENCE)) {
			doAfter(500, () -> {
				if (isDead) return;
				Battlefield.floatingTextManager.pump('Immune', getScreenXCenter(), getScreenYCenter());
			});
			return;
		}
		playAudio('SilenceAudio');
		final duration = if (Battlefield.getCurrentlyActiveUnit() == this) 1 else 2;	// If you are silenced on your turn, lasts this turn only; else, last next turn only
		addBuff(new Buff('Silenced', duration, {}, {
			onTurnEnd: function(self: Unit) {
				self.removeBuff('Silenced');
			},
			onRemove: function(self: Unit) {
				final silenceAtt = getAttachment('Silenced');
				if (silenceAtt == null) {
					trace('WARNING: Wanting to remove the Silenced attachment but it does not exist on unit ${name}');
					return;
				}
				removeAttachment('Silenced');
			}
		}));
		for (spell in spells) {
			if ([NORMAL_MOVE, FLY_MOVE, CRYSTAL_MOVE, HORSE_MOVE, PLAYER_CRYSTAL_MOVE, END_TURN].indexOf(spell.getType()) != -1) continue;
			if (['Move', 'Melee Attack', 'Melee Attack Long', 'Shoot Arrow', 'Shoot Arrow Long', 'End Turn'].indexOf(spell.getName()) != -1) continue;
			if (spell.cooldownRemaining == 0) {		// If it has no coolown, give it a "2 turns cooldown", since 1 = no cooldown
				spell.cooldownRemaining = 2;
			} else {
				spell.cooldownRemaining += 1;		// If it already has a cooldown, increase it by 1
			}
		}
		addAttachment('Silenced');
	}
	public function isSilenced() {
		return hasBuff('Silenced');
	}
	public function infectRandomUninfectedSpell(): Spell {
		if (owner != PLAYER) return null;
		if (spells == null || spells.length == 0) return null;
		final availableSpells = spells.filter(spell -> spell.getName() != 'End Turn');
		var spell: Spell = randomOf(availableSpells);
		if (spell == null)
			return null;
		if (spell.isInfected == true) {
			for (s in availableSpells) {
				if (s.isInfected == false)
					spell = s;
			}
		}
		if (spell == null) return null;
		spell.isInfected = true;
		addBuff(new Buff('Infected', 2, {}, {		// Duration 2 so the buff is active during the unit's turn (since buffs tick on turn start)
			onRemove: function(fromUnit: Unit) {
				if (spell == null) return;
				spell.isInfected = false;
			}
		}));
		return spell;
	}
	public function clearInfectedSpells() {
		for (s in spells) s.isInfected = false;
	}
	function checkAndTryDealInfectedDamage(spellBeingCast: Spell) {
		if (isDead) return;
		if (spellBeingCast.isInfected == false) return;
		playEffect('Spores', 500);
		damage(2, PURE);
	}
	public inline function interrupt() cancelDelayedSpell();
	public function cancelDelayedSpell() {
		if (isInDownAnimation) {
			trace('Is in down up animaton yes');
			resetDownUpAnimation();
		} else {
			trace('NO IS NOT!');
		}
		if (spellBeingDelayed != null) {
			playAudio('InterruptAudio');
		}
		spellBeingDelayed = null;
		unmarkAllDelayedTiles();
	}
	public function stun() {
		if (owner == NEUTRAL) return;
		if (hasTag(IMMUNE_TO_STUN)) {
			doAfter(500, () -> {
				if (isDead) return;
				Battlefield.floatingTextManager.pump('Immune', getScreenXCenter(), getScreenYCenter());
			});
			return;
		}
		interrupt();
		addAttachment('Stunned');
		playAudio('StunAudio');
		addBuff(new Buff('Stunned', 2, {}, {
			onRemove: function(self: Unit) {
				final silenceAtt = getAttachment('Stunned');
				if (silenceAtt == null) {
					trace('WARNING: Wanting to remove the Stunned attachment but it does not exist on unit ${name}');
					return;
				}
				removeAttachment('Stunned');
			}
		}));
	}
	public function isStunned() return hasBuff('Stunned');
	public function unstun() removeBuff('Stunned');
	public function root() {
		if (isImmuneToRoot || hasTag(IMMUNE_TO_ROOT)) {
			doAfter(500, () -> {
				if (isDead) return;
				Battlefield.floatingTextManager.pump('Immune', getScreenXCenter(), getScreenYCenter());
			});
			return;
		}
		if (isRooted) return;
		isRooted = true;
		addAttachment('Rooted');
		addBuff(new Buff('Rooted', 2, {}, {
			onTurnEnd: function(self: Unit) {
				self.unroot();
			}
		}));
		if (hasMoveSpell() == false) return;
		final moveSpell = getMoveSpell();
		if (Battlefield.getCurrentlyActiveUnit() == this) {
			moveSpell.isWasted = true;
			if (GUI.isOpen('BattlefieldUI')) {
				BattlefieldUI.self.updateSpellButtons(this);
			}
		} else {
			moveSpell.isWasted = true;	// This will be checked on turn start, when unwasting spells
		}
	}
	public function unroot() {
		isRooted = false;
		final rootAtt = getAttachment('Rooted');
		if (rootAtt == null) {
			trace('WARNING: Wanting to remove the Rooted attachment but it does not exist on unit ${name}');
			return;
		}
		removeAttachment('Rooted');
		if (hasMoveSpell() == false) return;
		getMoveSpell().isWasted = false;
	}


	public function setMaxHealth(value: Int) {
		stats.health = value;
		if (health > value) {
			health = value;
		}
		if (unitBarsComponent != null) {
			unitBarsComponent.setMaxHealthValue(value);
		}
	}

	public function setOwner(nextOwner: Int) {
		this.owner = nextOwner;
		final healthBarAnimation = UnitBarsComponent.getHealthBarAnimationByOwner(nextOwner);
		if (unitBarsComponent != null) {
			unitBarsComponent.healthBar.actor.setAnimation(healthBarAnimation);
		}
	}
	
	// Buffs
	public function addBuff(buff: Buff) {
		activeBuffs.push(buff);
		if (buff.stats != null) {
			stats.add(buff.stats);
		}
		if (buff.onAdd != null) buff.onAdd(this);
		unitBuffsComponent.update();
	}
	public function removeBuff(buffName: String) {
		final buff = activeBuffs.find(b -> b.name == buffName);
		if (buff == null) {
			warnLog('No buff named ${buffName} found on unit ${name}');
			return;
		}
		activeBuffs = activeBuffs.filter(b -> b != buff);
		if (buff.onRemove != null)
			buff.onRemove(this);
		unitBuffsComponent.update();
	}
	function tickBuffs() {	// Buffs tick at the start of the unit's turn
		for (buff in activeBuffs) {
			if (isDead) continue;
			if (buff.onTick != null) buff.onTick(this);
			buff.remainingDuration--;
			if (buff.remainingDuration == 0) {
				if (buff.onRemove != null) buff.onRemove(this);
				if (buff.stats != null) {
					stats.subtract(buff.stats);
				}
			}
		}
		activeBuffs = activeBuffs.filter(buff -> buff.remainingDuration > 0);
		unitBuffsComponent.update();
	}
	public function resetSpellCooldowns() {
		for (spell in spells) {
			if (spell.cooldownRemaining > 0) {
				spell.cooldownRemaining = 0;
			}
		}
	}
	function tickSpellCooldowns() {
		for (spell in spells) {
			if (spell.cooldownRemaining > 0) {
				spell.cooldownRemaining --;
			}
		}
	}
	function tickSpellCooldownsOnSpellCast(spellBeingCast: Spell) {
		for (spell in spells) {
			if (spell != spellBeingCast && spell.cooldownRemaining > 0 && spell.isMoveSpell() == false) {
				spell.cooldownRemaining --;
			}
		}
	}
	public function getAttachment(animationName: String) return unitAttachmentsComponent.getAttachment(animationName);
	public function addAttachment(animationName: String, ?xOffset: Float = 0, ?yOffset: Float = 0) unitAttachmentsComponent.addAttachment(animationName, xOffset, yOffset);
	public function hasAttachment(animationName: String) return unitAttachmentsComponent.hasAttachment(animationName);
	public function removeAttachment(animationName: String) unitAttachmentsComponent.removeAttachment(animationName);


	// Movement
	public function putOnTile(tile : TileSpace){		// Instantly
		slideToTile(tile, null, true);
	}
	public function detachFromBoard() {
		if (tileOn != null) {			// Clear tile(s) unit is already on
			tileOn.unmarkForUnitTurn(this);
			tileOn.unitOnIt = null;
			if (isLarge) {
				if (tileOn.getRightTile() == null) throwAndLogError('Unit ${name} at tile ${tileOn.toString()} is on an invalid tile.');
				if (tileOn.getRightTile().unitOnIt != this) throwAndLogError('For unit ${name} at tile ${tileOn.toString()} with tile to the right being ${tileOn.getRightTile().toString()}, the tile to the right does not contain this unit as unit on it.');
				tileOn.getRightTile().unitOnIt = null;
			}
		}
		tileOn = null;
	}
	
	public function getHypotheticCoordinatesOnTile(tile : TileSpace): Point {	// Returns a Point, containing the real x and y of the actor, if the actor were on the respective tile
		var actorX = tile.getXCenter() - getWidth() / 2 + getActorOffsetX();
		var actorY = tile.getY() - getHeight() + tile.getHeight() - TileSpace.k.unitFeetSpace
			+ if (unitTemplate != null) unitTemplate.actorOffsetY else 0;
		var coordinates = new Point(actorX, actorY);
		return coordinates;
	}
	public function getHypotheticCoordinatesOnTileAsLargeUnit(tile : TileSpace) {
		if (tile.getRightTile() == null) throwAndLogError('The unit ${this.name} was not supposed to go to a right-most tile (${tile.toString()})!');
		var actorX = tile.getXCenter() + (TileSpace.k.width + TileSpace.k.spaceBetweenTiles) / 2 - getWidth() / 2
			+ getActorOffsetX();
		var actorY = tile.getY() - getHeight() + tile.getHeight() - TileSpace.k.unitFeetSpace
			+ if (unitTemplate != null) unitTemplate.actorOffsetY else 0;
		var coordinates = new Point(actorX, actorY);
		return coordinates;
	}
	public function slideToTileVisualOnly(tile: TileSpace, overTime: Float = 0.2, ?andThen: Void -> Void = null) {
		if (stopBreathing != null) stopBreathing();
		hideBars();
		unitBuffsComponent.hide();
		if (overTime > 0) {
			activateMoveParticles(int(overTime * 0.5));		// * 0.5 for effect, since it slows down at the end
		}
		actor.moveToLayer(engine.getLayerByName('Units${tileOn.getI()}'));
		final target = if (isLarge) getHypotheticCoordinatesOnTileAsLargeUnit(tile) else getHypotheticCoordinatesOnTile(tile);
		originalY = target.y;
		actor.moveTo(target.x, target.y, overTime, Easing.linear);
		unitAttachmentsComponent.slideToActorPosition(target.x, target.y, overTime);
		doAfter(overTime * 1000, function() {
			showBars();
			unitBuffsComponent.show();
			updateBars();
			if (andThen != null) andThen();
		});
	}
	public function slideToTile(tile : TileSpace, ?andThen : Void -> Void, isInstant = false) {
		if (isLarge && tile.getNextTileInDirection(RIGHT) == null) {
			trace('WARNING: Unit ${name} has no space on tile ${tile.toString()}');
		}
		if (stopBreathing != null) stopBreathing();
		hideBars();
		unitBuffsComponent.hide();
		final tileWasOn = tileOn;
		final wasTileOnMarked = tileWasOn != null && tileWasOn.isMarkedForTurn();
		detachFromBoard();									// The old one will stop flashing
		if (wasTileOnMarked) {
			tile.markForUnitTurn(this);						// Start flashing new tile
		}
		tileOn = tile;
		tileOn.unitOnIt = this;								// Setup tile(s) unit is moving to
		if (isLarge) {
			trace('Large unit: ${name}');
			if (tileOn.getRightTile().hasUnit()) throwAndLogError('Large unit ${name} is trying to move to tile ${tileOn.toString()}');
			tileOn.getRightTile().unitOnIt = this;
		}

		if (isInstant == false) {
			activateMoveParticles(int(k.slideToTileTime * 1000 * 0.5));			// * 0.5 for effect, since it slows down at the end
		}
		if (areMoveParticlesDisabledOnce) areMoveParticlesDisabledOnce = false;	
		actor.moveToLayer(engine.getLayerByName('Units${tileOn.getI()}'));

		final target = if (isLarge) getHypotheticCoordinatesOnTileAsLargeUnit(tile) else getHypotheticCoordinatesOnTile(tile);
		originalY = target.y;

		// doAfter(50, () -> {									// Requires a delay to configure breathing properly
			if (isInstant) {
				actor.setX(target.x);
				setY(int(target.y));
				unitBuffsComponent.show();
				unitBuffsComponent.updatePositions();
				showBars();
				updateBars();
				unitAttachmentsComponent.updatePosition();
				// if (owner != NEUTRAL) startBreathing();
			} else {
				// trace('Unit ${name}:');
				// trace('- Moving from ${actor.getX()}, ${actor.getY()} to ${target.x}, ${target.y} over ${k.slideToTileTime}');
				final time1 = Timer.stamp();
				actor.moveTo(target.x, target.y, k.slideToTileTime, Easing.expoOut);
				unitAttachmentsComponent.slideToActorPosition(target.x, target.y, k.slideToTileTime);
				doAfter(k.slideToTileTime * 1010, function() {
					// trace('- Landed at ${actor.getX()}, ${actor.getY()}... after ${Timer.stamp() - time1}');
					if (tile.hasTrap())
						tile.trapOnIt.trigger(this);
					showBars();
					updateBars();
					unitBuffsComponent.show();
					unitBuffsComponent.updatePositions();
					unitAttachmentsComponent.updatePosition();
					// if (owner != NEUTRAL) startBreathing();
					if (andThen != null) andThen();
				});
			}
		// });
	}
	public function pushInDirection(direction: Int, distance: Int): TileSpace {	// Returns tile the unit landed on
		trace('Pushing towards: ${direction}');
		if (hasTag(IMMUNE_TO_PUSH)) {
			doAfter(500, () -> {
				if (isDead) return;
				Battlefield.floatingTextManager.pump('Immune', getScreenXCenter(), getScreenYCenter());
			});
			return null;
		}
		final oldTileOn = tileOn;
		final startTile = tileOn.getNextTileInDirection(direction);
		if (isLarge == false || (isLarge && direction == LEFT)) {	// Coincidentally, if large and LEFT, then this normal method works
			if (startTile == null) return null;
			if (startTile.hasUnit()) return tileOn;
			var i = startTile.getI();
			var j = startTile.getJ();
			final lastEmptyTile = Pathing.getLastTileInDirection(i, j, distance, direction, (tile) -> tile.hasNoUnit());
			if (lastEmptyTile == null) return null;
			slideToTile(lastEmptyTile);
			Battlefield.triggerOnUnitPushedEvents(this);
			repositionDelayedSpellTiles(oldTileOn, lastEmptyTile);
			return lastEmptyTile;
		} else {
			final oldTileOn2 = tileOn.getNextTileInDirection(RIGHT);
			var currentTile1 = oldTileOn;
			var currentTile2 = oldTileOn2;
			if (currentTile1 == null || currentTile2 == null) { trace('WARNING: Unit:1098'); return null; }
			if ([UP, DOWN, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT].indexOf(direction) != -1) {
				var currentDistance = 0;
				while (currentDistance < distance) {
					final nextTile1 = currentTile1.getNextTileInDirection(direction);
					final nextTile2 = currentTile2.getNextTileInDirection(direction);
					if (nextTile1 == null || nextTile2 == null) break;
					if (nextTile1.hasUnit() || nextTile2.hasUnit()) break;
					currentDistance ++;
					currentTile1 = nextTile1;
					currentTile2 = nextTile2;
				}
				if (currentTile1 != oldTileOn) {
					slideToTile(currentTile1);
					Battlefield.triggerOnUnitPushedEvents(this);
					repositionDelayedSpellTiles(oldTileOn, currentTile1);
				}
			} else if (direction == RIGHT) {
				final mySecondTileI = startTile.getI();
				final mySecondTileJ = startTile.getJ();
				if (startTile.getNextTileInDirection(RIGHT) == null) return oldTileOn;
				if (startTile.getNextTileInDirection(RIGHT).hasUnit()) return oldTileOn;
				final lastEmptyTile = Pathing.getLastTileInDirection(mySecondTileI, mySecondTileJ + 1, distance, RIGHT, (tile) -> tile.hasNoUnit());
				if (lastEmptyTile == null) { trace('WARNING: Null here.'); return null; }
				final landingTile = lastEmptyTile.getNextTileInDirection(LEFT);
				if (landingTile != oldTileOn) {
					slideToTile(landingTile);
					Battlefield.triggerOnUnitPushedEvents(this);
					repositionDelayedSpellTiles(oldTileOn, landingTile);
				}
			}
			
			return currentTile1;
		}
	}
	public function pushTargetAwayFromMe(target: Unit, distance: Int): TileSpace {
		final pushDirection = target.getPushDirectionFromUnit(this);
		trace('Got push direction ${pushDirection}');
		final tileLandedOn = target.pushInDirection(pushDirection, distance);
		return tileLandedOn;
	}
	public function getPushDirectionFromUnit(from: Unit): Int {
		var pushDirection = NO_DIRECTION;
		final isSameJ = getJ() == from.getJ();
		final isLargeSecondarySameJ = isLarge && getJ() + 1 == from.getJ();
		final isSameRow = getI() == from.getI();
		if (isSameRow) {
			pushDirection = if (getJ() > from.getJ()) RIGHT else LEFT;
		} else if (isSameJ || (isLarge && isLargeSecondarySameJ)) {
			pushDirection = if (getI() > from.getI()) DOWN else UP;
		}
		return pushDirection;
	}
	public function getLocationsWhereCanMove() {
		return tileOn.getLocationsWhereCanMove(getSpeed(), isLarge);
	}
	public function __getDirectionTowardsUnit(unit: Unit) {
		if (unit == this) return NO_DIRECTION;
		final sameRow = getI() == unit.getI();
		final sameCol = getJ() == unit.getJ();
		final lefter = unit.getJ() < getJ();
		final righter = getJ() < unit.getJ();
		final upper = getI() < unit.getI();
		final downer = getI() > unit.getI();

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
		trace('WARNING: Could not find direction from ${this.name} to ${unit.name}');
		return NO_DIRECTION;
	}
	public function getDirectionTowardsUnit(unit: Unit) {
		if (unit.tileOn == null) {
			trace('WARNING: Direction towards: unit ${unit.name} has no tile!');
			return NO_DIRECTION;
		}
		return tileOn.getDirectionToPosition(unit.tileOn.getI(), unit.tileOn.getJ());
	}
	public function repositionDelayedSpellTiles(myOldTile: TileSpace, myNewTile: TileSpace) {
		final myOldPosition = myOldTile.getPosition();
		final myNewPosition = myNewTile.getPosition();
		final iOffset = myNewPosition.i - myOldPosition.i;
		final jOffset = myNewPosition.j - myOldPosition.j;

		if (spellBeingDelayedOriginTile != null) {
			spellBeingDelayedOriginTile = Battlefield.getTile(spellBeingDelayedOriginTile.getI() + iOffset, spellBeingDelayedOriginTile.getJ() + jOffset);
			if (spellBeingDelayedOriginTile == null) {
				interrupt();
				return;
			}
		}
		if (spellBeingDelayedTargetTile != null) {
			spellBeingDelayedTargetTile = Battlefield.getTile(spellBeingDelayedTargetTile.getI() + iOffset, spellBeingDelayedTargetTile.getJ() + jOffset);
			if (spellBeingDelayedTargetTile == null) {
				interrupt();
				return;
			}
		}
		if (tilesMarkedRed != null) {
			final tilesMarkedRedBackup = tilesMarkedRed;
			for (tile in tilesMarkedRed) tile.removeDangerMarker();
			tilesMarkedRed = tilesMarkedRedBackup.map(t -> Battlefield.getTile(t.getI() + iOffset, t.getJ() + jOffset)).filter(t -> t != null);
			for (tile in tilesMarkedRed) tile.addDangerMarker();
		}
	}
	public function markTileRed(tile: TileSpace) {
		tilesMarkedRed.push(tile);
		tile.addDangerMarker();
	}
	public function unmarkAllDelayedTiles() {
		if (tilesMarkedRed != null) {
			for (tile in tilesMarkedRed)
				tile.removeDangerMarker();
		}
		tilesMarkedRed = [];
	}
	var tilesMarkedYellow: Array<TileSpace> = [];
	public function showTargetedTiles(tiles: Array<TileSpace>) {
		playAudio('TileTargetAudio');
		for (tile in tiles) {
			if (tile.isMarkedColor('Yellow') == false) {
				tile.markColor('Yellow');
			}
		}
		tilesMarkedYellow = tiles;
	}
	public function hideTargetedTiles() {
		for (tile in tilesMarkedYellow) {
			if (tile.isMarkedColor('Yellow')) {
				tile.unmarkColor('Yellow');
			}
		}	
	}


	// Visual only methods
	public function jotTowards(?unit: Unit, ?tile: TileSpace) {
		if (isDead) {
			trace('WARNING: Trying to jot a dead unit ${name}');
			return;
		}
		if (actor == null || actor.isAnimationPlaying() == false) {
			trace('WARNING: Wanting to jot hidden unit ${name}');
			return;
		}
		if (unit != null) {
			tile = if (unit.isDead) unit.tileOn else unit.tileWhereDied;
		}
		if (tile == null) {
			trace('WARNING: Trying to jot towards null tile ${name}!');
		}
		final direction = tileOn.getDirectionToTile(tile);
		jot(direction);
	}
	public function jot(direction){
		Unit.jotActor(actor, direction);
	}
	public static function jotActor(actor: Actor, direction: Int) {
		var originalX = actor.getX();
		var originalY = actor.getY();
		var targetX = originalX + switch(direction) {
			case LEFT, DOWN_LEFT, UP_LEFT: -10; case RIGHT, DOWN_RIGHT, UP_RIGHT: 10;
			default: 0;
		};
		var targetY = originalY + switch(direction){
			case UP, UP_RIGHT, UP_LEFT: -10; case DOWN, DOWN_RIGHT, DOWN_LEFT: 10;
			default: 0;
		};
		actor.moveTo(targetX, targetY, 0.1, Easing.expoOut);
		doAfter(100, function() {
			if (actor == null || actor.isAlive() == false || actor.isAnimationPlaying() == false) return;
			actor.moveTo(originalX, originalY, 0.1, Easing.linear);
		});
	}
	public function flash() {
		U.flashWhite(actor, 150, () -> {
			//U.flashRed(actor, 100);
		});
	}
	public function flinch(?andThen: Void -> Void = null) {
		SpecialEffectsFluff.doFlinchAnimation(actor, andThen);
	}
	public function resetActorPosition() {
		actor.setAngle(0);
		final correctPosition = getHypotheticCoordinatesOnTile(tileOn);
		actor.setX(correctPosition.x);
		actor.setY(correctPosition.y);
	}
	public function growToScale(newScale: Float) {
		actorScale = newScale;
		if (isFlippedHorizontally)
			actor.growTo(-1 * newScale, newScale, 0, Easing.linear);
		else
			actor.growTo(newScale, newScale, 0, Easing.linear);
	}
	public function playEffect(effectName: String, duration: Int = 150) {
		return Effects.playEffectAt(getXCenter(), getYCenter(), effectName, duration);
	}
	public function scrollRed(text: String) {
		if (isDead) {
			trace('WARNING: Trying to scroll red text ${text} for dead unit ${name}');
			return;
		}
		Battlefield.scrollingTextManagerRed.pump(text, getScreenXCenter(), getScreenYCenter());
	}
	public function scrollBlue(text: String) {
		if (isDead) {
			trace('WARNING: Trying to scroll blue text ${text} for dead unit ${name}');
			return;
		}
		Battlefield.scrollingTextManagerBlue.pump(text, getScreenXCenter(), getScreenYCenter());
	}
	public function scrollGreen(text: String) {
		if (isDead) {
			trace('WARNING: Trying to scroll green text ${text} for dead unit ${name}');
			return;
		}
		Battlefield.scrollingTextManagerGreen.pump(text, getScreenXCenter(), getScreenYCenter());
	}
	public function growTo(scaleW: Float, scaleH: Float, seconds: Float, ?andThen: Void -> Void = null) {
		if (isDead) { trace('WARNING: Trying to grow dead unit ${name}'); return; }
		final originalY = tileOn.getHypotheticCoordinatesForActor(actor).y;
		actor.growTo(scaleW, scaleH, seconds, Easing.expoOut);
		final moveScale = (1 - scaleH) / 2;	// Grows taller -> moves up -> y decreases -> scaleH is negative
		actor.moveTo(getX(), originalY + moveScale * originalActorHeight, seconds, Easing.expoOut);	// To compensate for shrinking
		doAfter(seconds * 1000, if (andThen != null) andThen else () -> {});
	}
	public var isInDownAnimation = false;
	public function doDownUpAnimation(?andThen: Void -> Void) {
		if (isDead) { trace('WARNING: Trying to do down up animation for unit ${name}'); return; }
		final flipMod = if (isFlippedHorizontally) -1 else 1;
		final originX = getX();
		final originY = getY();
		growTo(1.1 * flipMod, 0.9, 0.05, () -> {
			growTo(0.9 * flipMod, 1.2, 0.35, () -> {
				growTo(1 * flipMod, 1, 0.45, () -> {
					isInDownAnimation = false;
					if (andThen != null) andThen();
				});
			});
		});
	}
	public function doDownAnimation(?andThen: Void -> Void) {
		if (isDead) { trace('WARNING: Trying to do down animation for dead unit ${name}'); return; }
		final flipMod = if (isFlippedHorizontally) -1 else 1;
		isInDownAnimation = true;
		growTo(1.1 * flipMod, 0.8, 0.5);
		if (andThen != null)
			doAfter(500, andThen);
	}
	public function resetDownUpAnimation() {
		trace('Resettung');
		final flipMod = if (isFlippedHorizontally) -1 else 1;
		isInDownAnimation = false;
		growTo(1 * flipMod, 1, 0.45);
	}
	public function activateMoveParticles(miliseconds: Int = 400) {
		function spawnParticle() {
			if (areMoveParticlesDisabledOnce) return;
			if (isDead) return;
			if (actor.isAnimationPlaying() == false) return;
			final moveParticle = createActor(
				'MoveParticleActor',
				actor.getLayerName(),
				actor.getXCenter() + randomIntBetween(-8, 8),
				actor.getY() + actor.getHeight() + randomIntBetween(-8, 8) - 8
			);
		}
		spawnParticle();
		doEveryUntil(25, miliseconds, () -> {
			spawnParticle();
		});
	}


	public inline function getCenterPoint() {
		if (isDead) { trace('WARNING: Trying to get Center Point for dead unit ${name}'); return new Point(0, 0); }
		return new Point(actor.getXCenter(), actor.getYCenter());
	}
	public inline function getCenterPointForMissile() {
		if (isDead) { trace('WARNING: tileOn does not exist for unit ${name}'); return new Point(0, 0); }
		return tileOn.getCenterPointForMissile();
	}
	public inline function getI() {
		if (tileOn != null) {
			return tileOn.matrixY;
		} else {
			Game.q('ERROR: Could not getI() for unit ${name}; tile is null.');
			return -1;
		}
	}
	public inline function getJ() {
		if (tileOn != null) {
			return tileOn.matrixX;
		} else {
			Game.q('ERROR: Could not getJ() for unit ${name}; tile is null.');
			return -1;
		}
	}
	public inline function getMatrixX() return tileOn.matrixX;
	public inline function getMatrixY() return tileOn.matrixY;
	public inline function getWidth() {
		if (assertVisible('setX')) return 0.01;
		return actor.getWidth();
	}
	public inline function getHeight()  {
		if (assertVisible('setX')) return 0.01;
		return actor.getHeight();
	}
	public inline function setXCenter(x) {
		if (!existsVisually()) { trace('WARNING: tileOn does not exist for unit ${name}'); return; }
		actor.setXCenter(x + getActorOffsetX());
	}
	public inline function setYCenter(y) {
		if (assertVisible('setYCenter')) return;
		actor.setYCenter(y + if (unitTemplate != null) unitTemplate.actorOffsetY else 0);
	}
	public inline function setX(x) {
		if (assertVisible('setX')) return;
		actor.setX(x + getActorOffsetX());
	}
	public inline function setY(y) {
		if (assertVisible('setY')) return;
		actor.setY(y + if (unitTemplate != null) unitTemplate.actorOffsetY else 0);
	}
	public inline function getArmor() return stats.armor;
	public function getArmorMultiplier(): Float return (1 - (stats.armor / 100));
	public function getDamageReducedByArmor(amount: Int): Int return int(amount * getArmorMultiplier());
	public inline function getMaxHealth() return stats.health;
	public inline function getMaxMana() return stats.mana;
	public inline function updateBars() if (owner != NEUTRAL || hasTag(NEUTRAL_WITH_HEALTH_BAR)) unitBarsComponent.update();
	public inline function hideBars() if (owner != NEUTRAL || hasTag(NEUTRAL_WITH_HEALTH_BAR)) unitBarsComponent.hide();
	public inline function showBars() if (owner != NEUTRAL || hasTag(NEUTRAL_WITH_HEALTH_BAR)) unitBarsComponent.show();
	public inline function getSpeed() return stats.speed;
	public inline function getXPAwarded() return unitTemplate.getXPAwarded();
	public inline function getX() {
		if (assertVisible('getX')) return 0.0;
		return actor.getX();
	}
	public inline function getY() {
		if (assertVisible('getY')) return 0.0;
		return actor.getY();
	}
	public inline function getXCenter() {
		if (assertVisible('getXCenter')) return 0.0;
		return actor.getXCenter();
	}
	public inline function getYCenter() {
		if (assertVisible('getYCenter')) return 0.0;
		return actor.getYCenter();
	}
	public inline function getScreenXCenter() return getXCenter() - getScreenX();
	public inline function getScreenYCenter() return getYCenter() - getScreenY();
	public inline function hasBuff(buffName: String) return activeBuffs.filter(buff -> buff.name == buffName).length > 0;
	public inline function getBuff(buffName: String) return activeBuffs.filter(buff -> buff.name == buffName)[0];
	public function hasSpell(spellName: String) {
		final spellsToSearch: Array<String> = if (unitTemplate != null) unitTemplate.spells else playerCharacter.equippedSpells;
		return spellsToSearch.filter(s -> s == spellName).length > 0;
	}
	public function getSpell(spellName: String) {
		final oneSpellFound = spells.filter(spell -> spell.getName() == spellName);
		if (oneSpellFound.length == 0) return null;
		else return oneSpellFound[0];
		
	}
	public inline function getAIType() return unitTemplate.ai.type;
	public function canMove() {
		if (isDead) return false;
		if (isRooted) return false;
		if (getSpeed() <= 0) return false;
		return hasMoveSpell();
	}
	public function hasMoveSpell() {
		for (s in spells)
			if ([NORMAL_MOVE, HORSE_MOVE, TELEPORT_MOVE, FLY_MOVE, CRYSTAL_MOVE].indexOf(s.getEffectType()) != -1) return true;
		return false;
	}
	public function getMoveSpell(): Spell {
		for (s in spells)
			if ([NORMAL_MOVE, HORSE_MOVE, TELEPORT_MOVE, FLY_MOVE, CRYSTAL_MOVE].indexOf(s.getEffectType()) != -1) return s;
		throw 'Unit ${name} does not have a Move spell.';
		return null;
	}
	public function getFirstSkillShotSpell() {
		for (spell in spells) {
			final spellType = spell.getType();
			if (spellType == SKILL_SHOT || spellType == MULTI_SKILL_SHOT || spellType == SKILL_SHOT_PIERCING) return spell;
		}
		return null;
	}
	public inline function isMercenary() return playerMercenary != null;
	public inline function isPlayerCharacter() return owner == PLAYER && unitTemplate == null && playerCharacter != null;
	public inline function isPlayer() return owner == PLAYER;
	public inline function isEnemy() return owner == ENEMY;
	public inline function isAlive() return !isDead;
	public function getAnySkillshotSpell(): Spell {
		for (s in spells) {
			if (s.getType() == SKILL_SHOT) return s;
		}
		return null;
	}
	public inline function isSittingOnTrap() return tileOn.hasTrap();
	public function isNearPlayerUnit() {
		final neighborUnits = tileOn.getNeighbors().filter(tile -> tile.hasUnit()).map(tile -> tile.unitOnIt);
		final neighborPlayers = neighborUnits.filter((unit: Unit) -> unit.isPlayerCharacter());
		return neighborPlayers.length > 0;
	}
	public function getNextTileInDirection(direction: Int) {
		return tileOn.getNextTileInDirection(direction);
	}
	public function getNextUnitInDirection(direction: Int) {
		if (getNextTileInDirection(direction) == null) return null;
		final tile = getNextTileInDirection(direction);
		if (tile.hasUnit() == false) return null;
		return tile.unitOnIt;
	}
	public function getNeighborPlayerUnits() {
		var playerUnits: Array<Unit> = [];
		for (tile in tileOn.getNeighbors()) {
			if (tile.hasUnit() && tile.unitOnIt.isPlayerCharacter())
				playerUnits.push(tile.unitOnIt);
		}
		return playerUnits;
	}
	public function getNeighborUnits(alsoDiagonally = false): Array<Unit> {
		if (isLarge == false)
			return tileOn.getNeighbors(alsoDiagonally).filter(t -> t.hasUnit()).map(t -> t.unitOnIt);
		else {
			final tile1Neighbors = tileOn.getNeighborsExceptRight(alsoDiagonally);
			final tile2 = tileOn.getNextTileInDirection(RIGHT);
			if (tile2 == null) {
				warnLog('Large Unit ${name} has no secondary tile!');
				return [];
			}
			final tile2Neighbors = tile2.getNeighborsSecondTileLargeUnit(alsoDiagonally);
			final allTiles = tile1Neighbors.concat(tile2Neighbors);
			final units = allTiles.filter(t -> t.hasUnit()).map(t -> t.unitOnIt);
			return units;
		}
	}
	public function getAudioOnHit(): String {
		if (unitTemplate != null) {
			if (unitTemplate.hasAudioOnHit()) return unitTemplate.audio.onHit;
		}
		if (playerCharacter != null) {
			if (playerCharacter.hasAudioOnHit()) return playerCharacter.getAudioOnHit();
		}
		return null;
	}
	public function getAudioOnDeath(): String {
		if (unitTemplate != null) {
			if (unitTemplate.hasAudioOnDeath()) return unitTemplate.audio.onDeath;
		}
		if (playerCharacter != null) {
			if (playerCharacter.hasAudioOnDeath()) return playerCharacter.getAudioOnDeath();
		}
		return null;
	}
	public function hasAudioOnHit() {
		if (unitTemplate != null) {
			return unitTemplate.hasAudioOnHit();
		}
		if (playerCharacter != null) {
			return playerCharacter.hasAudioOnHit();
		}
		return false;
	}
	public function hasAudioOnDeath() {
		if (unitTemplate != null) {
			return unitTemplate.hasAudioOnDeath();
		} else {
		}
		if (playerCharacter != null) {
			return playerCharacter.hasAudioOnDeath();
		}
		return false;
	}
	public function getTurnIndicatorIconPath(): String {
		if (unitTemplate != null) return unitTemplate.thumbnailPath;
		else return playerCharacter.characterClass.thumbnailPath;
	}
	public function flipHorizontallyInstantly() {
		final flipNum = if (isFlippedHorizontally) 1 else -1;
		isFlippedHorizontally = !isFlippedHorizontally;
		actor.growTo(flipNum * actorScale, 1 * actorScale, 0, Easing.expoOut);
	}
	public function flipHorizontally(?andThen: Void -> Void) {
		final flipNum = if (isFlippedHorizontally) 1 else -1;
		isFlippedHorizontally = !isFlippedHorizontally;
		actor.growTo(flipNum * actorScale, 1 * actorScale, 0.25, Easing.expoOut);
		doAfterSafe(250, () -> {
			if (isDead == false && actor != null) {
				actor.growTo(flipNum * actorScale, 1 * actorScale, 0);	// Make it flipped instantly to make sure it stays flipped
			}
			if (andThen != null) {
				andThen();
			}
		});
	}
	public function doesFlipHorizontally() return isPlayerCharacter() || (unitTemplate != null && unitTemplate.doesFlipHorizontally);
	public function hasTag(tag: Int) {
		if (unitTemplate == null) return false;
		if (unitTemplate.tags == null) return false;
		return unitTemplate.tags.indexOf(tag) != -1;
	}
	public function isWithinRangeOfUnit(unit: Unit, range: Int) {
		final deltai = int(Math.abs(unit.getI() - getI()));
		final deltaj = int(Math.abs(unit.getJ() - getJ()));
		return deltai + deltaj <= range;
	}
	public function isWithinRangeOfPlayerUnit(range: Int) {
		final allPlayerUnits = Battlefield.getAllAlivePlayerUnits();
		for (unit in allPlayerUnits) {
			if (isWithinRangeOfUnit(unit, range)) return true;
		}
		return false;
	}
	public function isHealthBelowPercent(percent: Int) {
		return health < ((percent / 100) * stats.health);
	}
	public function getXCenterForBars(): Float {
		if (isDead) {
			trace('WARNING: Trying to get x center for bars for dead unit ${name}');
			return 0;
		}
		var x = 
			if (isLarge)
				(tileOn.getXCenter() + tileOn.getNextTileInDirection(RIGHT).getXCenter()) / 2;
			else
				tileOn.getXCenter();
		return x;
	}
	public function getManaBarPointForTutorialIndicator() return unitBarsComponent.getManaBarPointForTutorialIndicator();
	public inline function hasManaForSpell(spell: Spell) return mana >= spell.getManaCost();
	public function getRandomTag(): Int {
		if (unitTemplate == null) return -1;
		if (unitTemplate.tags == null || unitTemplate.tags.length == 0) return -1;
		return randomOf(unitTemplate.tags);
	}
	public function getNextSpellInSequence() {
		if (unitTemplate == null) return null;
		if (unitTemplate.ai.spellSequence == null || unitTemplate.ai.spellSequence.length == 0) return null;
		final spellSequence = unitTemplate.ai.spellSequence;
        var currentAISpellIndex = currentAISpellIndex;
        if (currentAISpellIndex == spellSequence.length)
            currentAISpellIndex = 0;
        var nextAISpellIndex = currentAISpellIndex + 1;
        if (nextAISpellIndex == spellSequence.length)
            nextAISpellIndex = 0;
		return spellSequence[nextAISpellIndex];
	}
	public function getDescription() {
		function getBaseDescription() {
			if (unitTemplate != null) {
				if (unitTemplate.description != null) {
					return unitTemplate.description;
				} else {
					return '';
				}
			} else {
				if (owner == PLAYER) {
					return 'Hero owned by the player. That is you. \n Obviously.';
				} else {
					return '';
				}
			}
		}
		function hasResistances() {
			if (stats.dodge != 0) return true;
			if (stats.armor != 0) return true;
			var foundResistace = false;
			resistances.forEach((name, value) -> {
				if (value != 1) {
					foundResistace = true;
				}
			});
			return foundResistace;
		}
		function getResistancesDescription() {
			var desc = ' \n';
			if (stats.dodge != 0) {
				desc += ' \n ${stats.dodge}% DODGE';
			}
			if (stats.armor != 0) {
				desc += ' \n ${stats.armor}% ARMOR';
			}
			resistances.forEach(function(name: String, value: Float): Void {
				trace('For resistance ${name}, value=${value}, value==1.0 = ${value == 1.0}');
				if (value == 1.0) return;
				final keyword = if (value > 1) 'weakness' else 'resistance';
				final percentage = int(Math.abs((1 - value) * 100));
				desc += ' \n ${percentage}% ${name.toUpperCase()} ${keyword}';
			});
			return desc;
		}
		return getBaseDescription() + if (hasResistances()) getResistancesDescription() else '';
	}
	public function existsVisually() return actor != null && actor.isAnimationPlaying();
	public function assertVisible(?text: String) {	// Use as 	if (assertVisible()) return;
		if (!existsVisually()) {
			trace('WARNING: Unit ${name} does not exist visually${if (text != null) ": " + text else ""}');
			return true;
		}
		return false;
	}
	public function getActorOffsetX() {
		if (unitTemplate != null) {
			if (isFlippedHorizontally == false) {
				return unitTemplate.actorOffsetX;
			} else {
				return (-1) * unitTemplate.actorOffsetX;
			}
		} else {
			return 0;
		}
	}

	public function getInfo(whatInfo: String = 'pos') {
		switch (whatInfo) {
			case 'pos':	return '${name} (${if (tileOn != null) getI() + ", " + getJ() else "tileOn is null"}) (${if (actor != null) actor.getX() + ", " + actor.getY() else "actor is dead"})';
			case 'uniqueID': return '${uniqueID}';
			case 'actorScale': return '${actorScale}';
			case 'damageTakenMultiplier': return '${damageTakenMultiplier}';
			case 'damageDoneMultiplier': return '${damageDoneMultiplier}';
			case 'spells': return '[${spells.map(s -> s.getName()).join(', ')}]';
			case 'isLarge': return '$isLarge';
			case 'activeBuffs', 'buffs': return '${activeBuffs.map(b -> b.name + ': ' + b.remainingDuration).join(', ')}';
			case 'customData': return 'Use customData.ints or customData.strings';
			case 'customData.ints': return customData.ints.toString();
			case 'customData.strings': return customData.strings.toString();
			case 'owner': return '$owner';
			case 'isFlippedHorizontally': return '$isFlippedHorizontally';
			default: return 'Use pos, customData.ints, spells, etc';
		}
	}
	public function traceAllInfo() {
		final stringOwner = if (owner == PLAYER) 'PLAYER' else if (owner == ENEMY) 'ENEMY' else 'NEUTRAL';
		trace('Unit: ${name} of ${stringOwner}, id=${uniqueID}, isLarge=${isLarge}');
		trace('  o HP: ${health}/${stats.health}, MANA: ${mana}/${stats.mana}');
		trace('  o Stats: ${stats.toShortString()}');
		trace('  o ${getInfo('pos')}');
		trace('  o scale: ${actorScale}, isFlipped: ${isFlippedHorizontally}');
		trace('  o damageTakenMultiplier: ${damageTakenMultiplier}, damageDoneMultiplier: ${damageDoneMultiplier}');
		trace('  o spells: [${spells.map(s -> s.getName()).join(', ')}]');
		trace('  o activeBuffs: [${activeBuffs.map(b -> b.name + ': ' + b.remainingDuration).join(', ')}]');
		trace('  o customData.ints: ${customData.ints.toString()}');
		trace('  o customData.strings: ${customData.strings.toString()}');
		trace('  o spellBeingDelayed: ${if (spellBeingDelayed != null) spellBeingDelayed.getName() else "none"}');
		if (spellBeingDelayed != null) {
			if (spellBeingDelayedOriginTile != null) trace('    o Delayed from ${spellBeingDelayedOriginTile.toString()}');
			if (spellBeingDelayedTargetTile != null) trace('    o Delayed to ${spellBeingDelayedTargetTile.toString()}');
		}
	}
	public function toShortString() return '${name}(${getI()},${getJ()})';
	public function toSymbolString() {
		if (name == null) return '??';
		if (name.length >= 2) return name.substring(0, 2);
		return name;
	}

	public static function addFearfulEventMechanicToBattlefield() {	// Used ONLY in Battlefield
		Battlefield.addAfterUnitDeathEvent(function(dyingUnit: Unit, tileWhereDied: TileSpace) {
			if (dyingUnit.owner != ENEMY) return;
			final aliveEnemies = Battlefield.getAllAliveEnemyUnits();
			if (aliveEnemies.length == 0) return;

			final fearfulEnemies = aliveEnemies.filter(unit -> unit.hasTag(FEARFUL));

			if (fearfulEnemies.length == 0) return;
			
			final areAllAliveEnemiesFearful = aliveEnemies.length == fearfulEnemies.length;
			if (areAllAliveEnemiesFearful == false) return;


			playAudio('FearfulAudio');
			for (aliveEnemy in fearfulEnemies) {
				if (aliveEnemy.hasBuff('Fearful')) return;
				aliveEnemy.health = 1;
				aliveEnemy.updateBars();
				aliveEnemy.addAttachment('Fearful');
				aliveEnemy.addBuff(new Buff('Fearful', 99, {}, {}));
			}
		});
	}
	public static function doAfterUnit(unit: Unit, time: Int, func: Void -> Void) {	// A safe way to trigger doAfter
		function isOk() {
			if (func == null) return false;
			if (unit == null) return false;
			if (unit.isDead) return false;
			if (unit.actor == null || unit.actor.isAlive() == false || unit.actor.isAnimationPlaying() == false) return false;
			if (getCurrentSceneName() != 'BattlefieldScene') return false;
			return true;
		}
		if (isOk() == false) return;
		doAfter(time, () -> {
			if (isOk()){
				func();
			}
		});
	}
	
	public function addDamageUnitModificationEvent(modFunc: Unit -> Int -> Int) {
		damageUnitModifications.push(modFunc);
	}

}












