
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
using U;

import scripts.Constants.*;
import scripts.SpecialEffectsFluff.sayAlert;





class BattlefieldDialogueEvent
{
    
    public var text             : String = 'Default.';

    public var from     : String;               // 'player' or 'enemy'
    public var fromName : String;               // 'any' or an actual unit name
    
    public var isHint   : Bool = false;         // If true, will not consider 'from' and 'fromName, but always at fixed position
    public var blurRest : Bool = false;         // If true, it will blur the rest of the screen except the hint message

    public var tag      : String;               // Used to hardcode certain interactions. See BattlefieldTutorial (in Battlefield.hx)

    public static var k = {
        hintY: 70
    }

    public function new() {}

    public function trigger() {
        if (!isHint) {
            var possibleUnits : Array<Unit>;
            if (from == 'player') possibleUnits = Battlefield.getAllAlivePlayerUnits();
            else possibleUnits = Battlefield.unitsOnBattlefield.filter(unit -> unit.owner == ENEMY && unit.isDead == false);

            var fromUnit : Unit;
            if (fromName == 'any') fromUnit = possibleUnits[randomInt(0, possibleUnits.length - 1)];
            else {
                var foundUnits = possibleUnits.filter(unit -> unit.name == fromName);
                if (foundUnits.length == 0) throwAndLogError('ERROR: Unit with fromName ${fromName} not found.');
                fromUnit = foundUnits[0];
            };
            return fromUnit.say(text, -1);
        } else {
            return sayAlert(text, getSceneWidth() / 2, k.hintY, -1);
        }
    }



    public static function createFromDynamic(bde : Dynamic) {
        if (bde == null) trace('ERROR: Null bde given.');
        if (bde.text == null) trace('ERROR: Null text given.');
        var it = new BattlefieldDialogueEvent();
        it.text = bde.text;
        if (bde.tag != null) it.tag = bde.tag;
        if (bde.isHint == false || bde.isHint == null) {
            if (bde.from == null) trace('ERROR: Null from given');
            it.from = bde.from;
            it.fromName = if (bde.fromName == null) 'any' else bde.fromName;
            return it;
        } else {
            it.isHint = true;
            return it;
        }
    }



}