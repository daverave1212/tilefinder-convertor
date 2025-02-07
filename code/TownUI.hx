

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
import U.*;
using U;


class TownUI extends SimpleUI
{
	
	public static var self : TownUI;
	public var k = {
		padding : 6
	}
	public function new(){
		super("TownUI");
		self = this;
	}
	
	public var inventoryButton:		SUIButton;
	public var arrowLeft: 			SUIButton;
	public var arrowRight: 			SUIButton;

	
	public override function load(){
		inventoryButton = new SUIButton("GeneralButtonActor", "UI", "Inventory");
		inventoryButton.setRight(k.padding).setBottom(k.padding);
		inventoryButton.click = onClickOnInventory;
		arrowLeft  = new SUIButton('ArrowActor', 'UI', 'ArrowLeft');
		arrowLeft.centerVertically();
		arrowLeft.setLeft(k.padding);
		arrowLeft.click = onClickOnArrowLeft;
		arrowRight = new SUIButton('ArrowActor', 'UI', 'ArrowRight');
		arrowRight.centerVertically();
		arrowRight.setRight(k.padding);
		arrowRight.click = onClickOnArrowRight;
	}
	
	// Never meant to be closed.
	public override function open(?metadata : Array<Dynamic>){};
	public override function close() {};

	public function hideArrowLeft() arrowLeft.hide();
	public function showArrowLeft() arrowLeft.show();
	public function hideArrowRight() arrowRight.hide();
	public function showArrowRight() arrowRight.show();
	
	
	function onClickOnInventory() Town.onClickOnInventoryButton();	// WHen the button to open inv is clicked
	function onClickOnArrowLeft() Town.onClickOnArrowLeft();
	function onClickOnArrowRight() Town.onClickOnArrowRight();
	
}




