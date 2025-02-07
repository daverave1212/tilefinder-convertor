
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

import Math.*;
import scripts.Constants.*;

class CharacterInTown
{

    public var actor			: Actor = null;
    public var playerCharacter  : PlayerCharacter;
    public var onClick          : Void -> Void;

    public inline function setX(x) actor.setX(x);
    public inline function setY(y) actor.setY(y);
    public inline function getX() return actor.getX();
    public inline function getY() return actor.getY();
    public inline function getWidth() return actor.getWidth();
    public inline function getHeight() return actor.getHeight();
	public inline function getEquippedItems() return playerCharacter.equippedItems;
    

    public function new(pc : PlayerCharacter){
		playerCharacter = pc;
        actor = U.createActor('UnitActor_Mirror', 'PlayerCharacters');
        actor.setAnimation(playerCharacter.getClassName());
        U.onClick(click, actor);
    }

    public function click(){
        if(onClick != null) onClick();
    }

    // Boilerplate for positioning
    public inline function getXScreen() return getX() - Std.int(getScreenX());
	public inline function getYScreen() return getY() - Std.int(getScreenY());
	public inline function setXScreen(x : Float) setX(getX() + Std.int(getScreenX()));
	public inline function setYScreen(y : Float) setY(getY() + Std.int(getScreenY()));
	public inline function addX(x : Float) setX(getX() + x);
	public inline function addY(y : Float) setY(getY() + y);
	public inline function setXY(x : Float, y : Float){ setX(x); setY(y); }
	public inline function setLeft(value : Float){ setX(getScreenX() + value); return this; }
	public inline function setLeftFrom(value : Float, offset : Float){ setX(value + offset); return this; }
	public inline function setRight(value : Float){ setX(getScreenX() + getScreenWidth() - getWidth() - value); return this; }
	public inline function setRightFrom(value : Float, offset : Float){ setX(offset - getWidth() - value); return this; }
	public inline function setTop(value : Float){ setY(getScreenY() + value); return this; }
	public inline function setTopFrom(value : Float, offset : Float){ setY(value + offset); return this; }
	public inline function setBottom(value : Float){ setY(getScreenY() + getScreenHeight() - getHeight() - value); return this; }
	public inline function setBottomFrom(value : Float, offset : Float){ setY(offset - getHeight() - value); return this; }
	public inline function getBottom() return getY() + getHeight();
	public inline function getRight() return getX() + getWidth();
	public inline function getLeft() return getX();
	public inline function getTop() return getY();
	public inline function centerVertically(){ setTop(getScreenHeight() / 2 - getHeight() / 2); return this; }
	public inline function centerHorizontally(){ setLeft(getScreenWidth() / 2 - getWidth() / 2); return this; }
	public inline function centerOnScreen(){
		setX(getScreenX() + (getScreenWidth() - getWidth()) / 2);
		setY(getScreenY() + (getScreenHeight() - getHeight()) / 2);
		return this;
	}

}












