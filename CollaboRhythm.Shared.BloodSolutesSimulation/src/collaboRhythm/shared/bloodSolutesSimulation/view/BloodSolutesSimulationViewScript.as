/**
 * Copyright 2011 John Moore, Scott Gilroy
 *
 * This file is part of CollaboRhythm.
 *
 * CollaboRhythm is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later
 * version.
 *
 * CollaboRhythm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with CollaboRhythm.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

import Box2D.Collision.*;
import Box2D.Collision.Shapes.*;
import Box2D.Common.Math.*;
import Box2D.Dynamics.*;
import Box2D.Dynamics.Joints.b2Joint;
import Box2D.Dynamics.Joints.b2MouseJoint;
import Box2D.Dynamics.Joints.b2MouseJointDef;
import Box2D.Dynamics.Joints.b2WeldJoint;
import Box2D.Dynamics.Joints.b2WeldJointDef;

import flash.display.Sprite;
import flash.utils.getQualifiedClassName;

import mx.core.IButton;
import mx.core.IVisualElement;
import mx.core.UIComponent;
import mx.events.FlexEvent;
import mx.events.ResizeEvent;

import spark.components.supportClasses.ButtonBase;
import spark.primitives.Rect;

private var _world:b2World;
private var _velocityIterations:int = 10;
private var _positionIterations:int = 10;
private var _timeStep:Number = 1.0 / 30.0;
private var _showDebug:Boolean = false;
private var _debugSprite:Sprite;
private var _soluteSprites:Vector.<Sprite> = new Vector.<Sprite>();
private var _plugSprites:Vector.<Sprite> = new Vector.<Sprite>();
private var _antibodySprites:Vector.<Sprite> = new Vector.<Sprite>();
private var _wallSprites:Vector.<Sprite> = new Vector.<Sprite>();
private var _wallRects:Vector.<Rect> = new Vector.<Rect>();
private var _pumps:Vector.<b2Vec2> = new Vector.<b2Vec2>();
private var pumpSpacing:Number;

// Box2D uses meters for measurement, AS3 uses pixels.  1 meter = 30 pixels
public static const _worldRatio:int = 30;

private var _plugRatio:Number = 0.5;
private var _antibodyRatio:Number = 0;
private var _soluteInBloodRatio:Number = 0.25;
private var _bloodAreaPercentWidth:Number = 0.5;

[Bindable]
public function get bloodAreaPercentWidth():Number
{
	return _bloodAreaPercentWidth;
}

public function set bloodAreaPercentWidth(value:Number):void
{
	if (_bloodAreaPercentWidth != value)
	{
		_bloodAreaPercentWidth = value;
		resizeWorld();
	}
}

private var _soluteConcentration:Number = 1; // bodies per square meter (in world space)

private var _soluteBodies:Vector.<b2Body> = new Vector.<b2Body>();
private var _plugBodies:Vector.<b2Body> = new Vector.<b2Body>();
private var _antibodyBodies:Vector.<b2Body> = new Vector.<b2Body>();
private var _wallBodies:Vector.<b2Body> = new Vector.<b2Body>();
private static const soluteWidth:Number = 8; // in pixels; size in meters is soluteWidth / _worldRatio
private static const soluteRadius:Number = soluteWidth / 2;
private static const flowVelocity:Number = 4;
private static const gapSize:Number = soluteWidth * 2.5;
private var numGaps:int;
private var plugWidth:Number = gapSize * 0.4; // width of the plug (length along x-axis) of the plug in pixels
private var plugHeight:Number = gapSize * 1.6; // height (longest edge) of the plug in pixels
private var antibodyWidth:Number = gapSize * 1.1; // width of the antibody (length along x-axis) of the antibody in pixels
private var antibodyHeight:Number = gapSize * 1.6; // height (longest edge) of the antibody in pixels
private var antibodyThickness:Number = gapSize * 0.2; // thickness of the "branches" of the antibody shape
private static const minWorldWidth:Number = 20 * soluteWidth / _worldRatio;
private static const minWorldHeight:Number = 10 * soluteWidth / _worldRatio;

private const verticalRecycleMinimum:Number = -10;

// world mouse position
public var m_mouseJoint:b2MouseJoint;
static public var mouseXWorldPhys:Number;
static public var mouseYWorldPhys:Number;
static public var mouseXWorld:Number;
static public var mouseYWorld:Number;

private var mousePVec:b2Vec2 = new b2Vec2();

private var snapDistanceEpsilon:Number = plugWidth * 0.5 / _worldRatio;
private var snapAngleEpsilon:Number = 2 * Math.PI * 0.1;
private const stuckDisplacementEpsilon:Number = soluteWidth * 0.25 / _worldRatio;
private const plugStuckTimeThreshold:Number = 3.0;
private const plugStuckTimePassThroughWallThreshold:Number = 0.5;
private const soluteStuckTimeThreshold:Number = 1.0;

private const plugMaskBits:uint = 0xffff; // collide with everything
//			private const plugMaskBits:uint = 0xffff & ~0x0002; // don't collide with walls
//			private const plugMaskBits:uint = 0xffff & ~0x0004; // don't collide with other plugs
//			private const plugMaskBits:uint = 0xffff & ~0x0002 & ~0x0004; // don't collide with walls or other plugs

private var pumpZoneLeft:Number;
private var pumpZoneRight:Number;

private var _isRunning:Boolean = false;

private var _fractionSolutesAsBoxes:Number = 1.0; // 0.5 for half boxes; 1.0 for all boxes

private var _soluteCount:int = NaN;
private var _antibodyCount:int = NaN;

private var _soluteFillColorRatio:Number = 0.5;
private var _soluteFillColor1:uint = 0xa9a5d2;
private var _soluteFillColor2:uint = 0xdcb0d2;
private var _plugFillColor:uint = 0x00a651;
private var _antibodyFillColor:uint = 0x00a651;

[Bindable]
public function get soluteFillColorRatio():Number
{
	return _soluteFillColorRatio;
}

public function set soluteFillColorRatio(value:Number):void
{
	_soluteFillColorRatio = value;
}

[Bindable]
public function get soluteFillColor1():uint
{
	return _soluteFillColor1;
}

public function set soluteFillColor1(value:uint):void
{
	_soluteFillColor1 = value;
}

[Bindable]
public function get soluteFillColor2():uint
{
	return _soluteFillColor2;
}

public function set soluteFillColor2(value:uint):void
{
	_soluteFillColor2 = value;
}

[Bindable]
public function get plugFillColor():uint
{
	return _plugFillColor;
}

public function set plugFillColor(value:uint):void
{
	_plugFillColor = value;
}

[Bindable]
public function get antibodyFillColor():uint
{
	return _antibodyFillColor;
}

public function set antibodyFillColor(value:uint):void
{
	_antibodyFillColor = value;
}

[Bindable]
public function get soluteCount():int
{
	return _soluteCount;
}

public function set soluteCount(value:int):void
{
	_soluteCount = value;
	_soluteConcentration = NaN;
	if (_world)
	{
		changeSoluteBodiesPopulation(calculateNumSoluteBodies());
		changeAntibodyBodiesPopulation(calculateNumAntibodies());
	}
}

[Bindable]
public function get antibodyCount():int
{
	return _antibodyCount;
}

public function set antibodyCount(value:int):void
{
	_antibodyCount = value;
	_antibodyRatio = NaN;
	if (_world)
	{
		changeSoluteBodiesPopulation(calculateNumSoluteBodies());
		changeAntibodyBodiesPopulation(calculateNumAntibodies());
	}
}

[Bindable]
public function get soluteConcentration():Number
{
	return _soluteConcentration;
}

public function set soluteConcentration(value:Number):void
{
	_soluteConcentration = value;
	if (_world)
	{
		changeSoluteBodiesPopulation(calculateNumSoluteBodies());
		changeAntibodyBodiesPopulation(calculateNumAntibodies());
	}
}

/**
 * Fraction of the solute bodies which should be boxes. Valid range is 0 to 1.
 * If the value is 0, all solutes will be circles (no boxes).
 * If the value is 1, all solutes will be boxes (no circles).
 */
[Bindable]
public function get fractionSolutesAsBoxes():Number
{
	return _fractionSolutesAsBoxes;
}

public function set fractionSolutesAsBoxes(value:Number):void
{
	_fractionSolutesAsBoxes = value;
}

[Bindable]
public function get rightAreaBackgroundColor():uint
{
	return (rightAreaBackgroundRect.fill as SolidColor).color;
}

public function set rightAreaBackgroundColor(value:uint):void
{
	(rightAreaBackgroundRect.fill as SolidColor).color = value;
}

[Bindable]
public function get bloodAreaBackgroundColor():uint
{
	return (bloodAreaBackgroundRect.fill as SolidColor).color;
}

public function set bloodAreaBackgroundColor(value:uint):void
{
	(bloodAreaBackgroundRect.fill as SolidColor).color = value;
}

public function get soluteInBloodRatio():Number
{
	return _soluteInBloodRatio;
}

public function set soluteInBloodRatio(value:Number):void
{
	_soluteInBloodRatio = value;
}

public function get plugRatio():Number
{
	return _plugRatio;
}

public function set plugRatio(value:Number):void
{
	_plugRatio = value;

	changePlugBodiesPopulation(calculateNumPlugs());
}

private function calculateNumPlugs():Number
{
	return Math.floor(numGaps * _plugRatio);
}

public function get antibodyRatio():Number
{
	return _antibodyRatio;
}

public function set antibodyRatio(value:Number):void
{
	_antibodyRatio = value;

	changeAntibodyBodiesPopulation(calculateNumAntibodies());
}

private function calculateNumAntibodies():int
{
	if (isNaN(antibodyRatio))
		return antibodyCount;
	else
		return Math.floor(_soluteBodies.length * _antibodyRatio);
}

public function get showDebug():Boolean
{
	return _showDebug;
}

public function set showDebug(value:Boolean):void
{
	_showDebug = value;
	if (!_showDebug)
	{
		_debugSprite.graphics.clear();
	}
	for each (var sprite:Sprite in _soluteSprites)
	{
		sprite.visible = !_showDebug;
	}
	for each (sprite in _plugSprites)
	{
		sprite.visible = !_showDebug;
	}
	for each (sprite in _antibodySprites)
	{
		sprite.visible = !_showDebug;
	}
	for each (sprite in _wallSprites)
	{
		sprite.visible = !_showDebug;
	}
	for each (var wallRect:Rect in _wallRects)
	{
		wallRect.visible = !_showDebug;
	}
}

public function get isRunning():Boolean
{
	return _isRunning;
}

public function set isRunning(value:Boolean):void
{
	if (_isRunning != value)
	{
		_isRunning = value;

		if (_isRunning)
			this.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		else
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);

//					trace("Debug trace for performance issues: " + getQualifiedClassName(this) + " " + this.id + " isRunning", _isRunning);
	}
}


protected function creationCompleteHandler(event:FlexEvent):void
{
	initializeDynamicElements();
}

private function initializeDynamicElements():void
{
	this.addEventListener(MouseEvent.CLICK, mouseClickHandler);
//				this.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);

	// Define the gravity vector
	var gravity:b2Vec2 = new b2Vec2(0.0, 0.0);

	// Allow bodies to sleep
	var doSleep:Boolean = true;

	// Construct a world object
	_world = new b2World(gravity, doSleep);

	_world.SetContactListener(new BloodSolutesContactListener());

	// set debug draw
	var debugDraw:b2DebugDraw = new b2DebugDraw();
	_debugSprite = new Sprite();
	spriteContainer.addChild(_debugSprite);
	debugDraw.SetSprite(_debugSprite);
	debugDraw.SetDrawScale(_worldRatio);
	debugDraw.SetFillAlpha(0.5);
	debugDraw.SetLineThickness(2);
	debugDraw.SetAlpha(1);
	debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit);
	_world.SetDebugDraw(debugDraw);

	calculateNumGaps();
	createDynamicWallRects();
	createWallBodies();

	var numSoluteBodies:int = calculateNumSoluteBodies();
	createSoluteBodies(numSoluteBodies);
//				createPlugBodies(4);
	changePlugBodiesPopulation(calculateNumPlugs());
	changeAntibodyBodiesPopulation(calculateNumAntibodies());

	// enable view source
	//			ViewSource.addMenuItem(this, "srcview/index.html");
	//			var text:TextField = new TextField();
	//			text.text = "Right click to view source";
	//			text.setTextFormat(new TextFormat("arial", 14, 0, true));
	//			text.x = 20;
	//			text.y = 20;
	//			text.width = 200;
	//			spriteContainer.addChild(text);

	this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);

//				showDebug = false;
}

private var mouseDragX:Number;
private var mouseDragY:Number;
private var mouseDown:Boolean;

private function mouseDownHandler(event:MouseEvent):void
{
	if (event.target is IButton || event.target is ButtonBase)
		return;

	if (!isRunning || !_world)
		return;

	// mouse press
	if (m_mouseJoint)
		throw new Error("Mouse joint was not null on mouse down");

//				_mouseDownX = event.stageX;
//				_mouseDownY = event.stageY;
	updateMouseWorld(event.stageX, event.stageY);

	var body:b2Body = getBodyAtMouse();
	if (body)
	{
		// remove plug joint
		var bodyInfo:BodyInfo = body.GetUserData() as BodyInfo;
		if (bodyInfo != null && bodyInfo.isPlug && bodyInfo.plugJoint)
		{
			destroyJoint(bodyInfo);
		}

		var md:b2MouseJointDef = new b2MouseJointDef();
		md.bodyA = _world.GetGroundBody();
		md.bodyB = body;
		md.target.Set(mouseXWorldPhys, mouseYWorldPhys);
		md.collideConnected = true;
		md.maxForce = 300.0 * body.GetMass();
		m_mouseJoint = _world.CreateJoint(md) as b2MouseJoint;
		body.SetAwake(true);

		event.stopImmediatePropagation();

		this.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
		this.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);

		mouseDown = true;
	}
}

protected function mouseMoveHandler(event:MouseEvent):void
{
	updateMouseWorld(event.stageX, event.stageY);

	// Note that enterFrameHandler will take care of updating the joint (if any), so we don't do that here

	if (m_mouseJoint)
		event.stopImmediatePropagation();
}

protected function mouseUpHandler(event:MouseEvent):void
{
	this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
	this.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
	mouseDown = false;

	// mouse release
	if (m_mouseJoint)
	{
		_world.DestroyJoint(m_mouseJoint);
		m_mouseJoint = null;
		event.stopImmediatePropagation();
	}
}

private function calculateNumSoluteBodies():int
{
	if (isNaN(soluteConcentration))
		return soluteCount;
	else
		return this.width * this.height / (_worldRatio * _worldRatio) * soluteConcentration;
}

private function createSoluteBodies(numSoluteBodies:int):void
{
	// Vars used to create bodies
	var body:b2Body;
	var bodyDef:b2BodyDef;
	var boxShape:b2PolygonShape;
	var circleShape:b2CircleShape;
	var fixtureDef:b2FixtureDef;

	// Adding sprite variable for dynamically creating body userData
	var sprite:Sprite;

	// Add some objects
	for (var i:int = 0; i < numSoluteBodies; i++)
	{
		// create generic body definition
		bodyDef = new b2BodyDef();
		bodyDef.type = b2Body.b2_dynamicBody;
		bodyDef.position.x = getBodyPosX(soluteInBloodRatio);
		bodyDef.position.y = Math.random() * this.height / _worldRatio;
		bodyDef.linearVelocity.y = flowVelocity;
		bodyDef.linearVelocity.x = 0;
		bodyDef.angle = Math.random() * Math.PI;

		var rX:Number = soluteRadius / _worldRatio;
		var rY:Number = rX;
		var spriteWidth:Number = rX * _worldRatio * 2;
		var spriteHeight:Number = rY * _worldRatio * 2;

		var color:uint;
		if (Math.random() < soluteFillColorRatio)
			color = soluteFillColor1;
		else
			color = soluteFillColor2;

		// Box
		if (Math.random() <= fractionSolutesAsBoxes)
		{
			sprite = new Sprite();
			sprite.graphics.lineStyle(1);

			sprite.graphics.beginFill(color);
			sprite.graphics.drawRect(-spriteWidth/2, -spriteHeight/2, spriteWidth, spriteHeight);
			sprite.graphics.endFill();

			boxShape = new b2PolygonShape();
			boxShape.SetAsBox(rX, rY);

			fixtureDef = new b2FixtureDef();
			fixtureDef.shape = boxShape;
		}
		// Circle
		else
		{
			sprite = new Sprite();
			sprite.graphics.lineStyle(1);
			sprite.graphics.beginFill(color);
			sprite.graphics.drawCircle(0, 0, spriteWidth/2);
			sprite.graphics.endFill();

			circleShape = new b2CircleShape(rX);

			fixtureDef = new b2FixtureDef();
			fixtureDef.shape = circleShape;
		}

		var bodyInfo:BodyInfo = new BodyInfo();
		bodyInfo.index = _soluteBodies.length;
		bodyInfo.sprite = sprite;
		bodyInfo.isSolute = true;
		bodyInfo.pumpAffinity = pickSolutePumpAffinity();
		bodyDef.userData = bodyInfo;

		fixtureDef.density = 1.0;
		fixtureDef.friction = 0.5;
		fixtureDef.restitution = 0.2;

		body = _world.CreateBody(bodyDef);
		bodyInfo.body = body;
		body.CreateFixture(fixtureDef);

		updateSpriteFromBody(body, bodyDef.position, sprite);

		_soluteBodies.push(body);
		_soluteSprites.push(sprite);
		spriteContainer.addChild(sprite);
	}
}

private function pickSolutePumpAffinity():int
{
	return Math.round(Math.random() * numGaps);
}

/**
 * Finds and reuses (un-destroys) plugs which have been marked for destruction, up to numPlugBodies. Returns the
 * number of plug bodies that still need to be created.
 */
private function reusePlugBodies(numPlugBodies:int):int
{
	// Apply forces
	for (var body:b2Body = _world.GetBodyList(); body && numPlugBodies > 0; body = body.GetNext())
	{
		if (body.GetMass() > 0 && body.GetUserData() is BodyInfo)
		{
			var bodyInfo:BodyInfo = body.GetUserData() as BodyInfo;

			if (bodyInfo.isPlug && bodyInfo.shouldBeDestroyed)
			{
				bodyInfo.shouldBeDestroyed = false;
				bodyInfo.index = _plugBodies.length;
				_plugBodies.push(body);
				_plugSprites.push(bodyInfo.sprite);
				numPlugBodies--;
			}
		}
	}

	return numPlugBodies;
}

private function createPlugBodies(numPlugBodies:int):void
{
	// Vars used to create bodies
	var body:b2Body;
	var bodyDef:b2BodyDef;
	var shape:b2PolygonShape;
	var fixtureDef:b2FixtureDef;

	// Adding sprite variable for dynamically creating body userData
	var sprite:Sprite;

	// Add some objects
	for (var i:int = 0; i < numPlugBodies; i++)
	{
		var shapeWidth:Number = plugWidth / _worldRatio;
		var shapeHeight:Number = plugHeight / _worldRatio;

		// create generic body definition
		bodyDef = new b2BodyDef();
		bodyDef.type = b2Body.b2_dynamicBody;
		// plug (medication) enters through the left stream (blood)
		bodyDef.position.x = getBodyPosX(0);
		bodyDef.position.y = -shapeHeight; // start above top edge
		bodyDef.linearVelocity.y = flowVelocity;
		bodyDef.linearVelocity.x = 0;

		// Trapezoid shape with vertices in the following order (turned on it's side here for convenience):
		//   0---3    +->Y
		//  /  +  \   V
		// 1-------2  X

		shape = new b2PolygonShape();
		var vertices:Vector.<b2Vec2> = new Vector.<b2Vec2>();
		vertices.push(new b2Vec2(-shapeWidth/2, -shapeHeight/4));
		vertices.push(new b2Vec2(+shapeWidth/2, -shapeHeight/2));
		vertices.push(new b2Vec2(+shapeWidth/2, +shapeHeight/2));
		vertices.push(new b2Vec2(-shapeWidth/2, +shapeHeight/4));
		shape.SetAsVector(vertices, 4);

		sprite = new Sprite();
		sprite.graphics.lineStyle(1);
		sprite.graphics.beginFill(plugFillColor);
		drawVertices(sprite.graphics, vertices, _worldRatio);
		sprite.graphics.endFill();

		var bodyInfo:BodyInfo = new BodyInfo();
		bodyInfo.index = _plugBodies.length;
		bodyInfo.sprite = sprite;
		bodyInfo.isPlug = true;
		bodyInfo.pumpAffinity = pickPlugPumpAffinity(bodyInfo);
		bodyDef.userData = bodyInfo;

		fixtureDef = new b2FixtureDef();
		fixtureDef.shape = shape;
		fixtureDef.density = 20.0;
		fixtureDef.friction = 0.5;
		fixtureDef.restitution = 0.2;
		fixtureDef.filter.categoryBits = 0x0004;
		fixtureDef.filter.maskBits  = plugMaskBits;

		body = _world.CreateBody(bodyDef);
		bodyInfo.body = body;
		body.CreateFixture(fixtureDef);

		updateSpriteFromBody(body, bodyDef.position, sprite);

		_plugBodies.push(body);
		_plugSprites.push(sprite);
		spriteContainer.addChild(sprite);
	}
}

/**
 * Finds and reuses (un-destroys) antibodies which have been marked for destruction, up to numAntibodyBodies. Returns the
 * number of antibody bodies that still need to be created.
 */
private function reuseAntibodyBodies(numAntibodyBodies:int):int
{
	// Apply forces
	for (var body:b2Body = _world.GetBodyList(); body && numAntibodyBodies > 0; body = body.GetNext())
	{
		if (body.GetMass() > 0 && body.GetUserData() is BodyInfo)
		{
			var bodyInfo:BodyInfo = body.GetUserData() as BodyInfo;

			if (bodyInfo.isAntibody && bodyInfo.shouldBeDestroyed)
			{
				bodyInfo.shouldBeDestroyed = false;
				bodyInfo.index = _antibodyBodies.length;
				_antibodyBodies.push(body);
				_antibodySprites.push(bodyInfo.sprite);
				numAntibodyBodies--;
			}
		}
	}

	return numAntibodyBodies;
}

private function createAntibodyBodies(numAntibodyBodies:int):void
{
	// Vars used to create bodies
	var body:b2Body;
	var bodyDef:b2BodyDef;
	var shape:b2PolygonShape;
	var fixtureDef:b2FixtureDef;

	// Adding sprite variable for dynamically creating body userData
	var sprite:Sprite;

	// Add some objects
	for (var i:int = 0; i < numAntibodyBodies; i++)
	{
		var shapeWidth:Number = antibodyWidth / _worldRatio;
		var shapeHeight:Number = antibodyHeight / _worldRatio;
		var shapeThickness:Number = antibodyThickness / _worldRatio;

		// create generic body definition
		bodyDef = new b2BodyDef();
		bodyDef.type = b2Body.b2_dynamicBody;
		// antibody (medication) enters through the left stream (blood)
		bodyDef.position.x = getBodyPosX(1);
		bodyDef.position.y = Math.random() * this.height / _worldRatio;
		bodyDef.linearVelocity.y = flowVelocity;
		bodyDef.linearVelocity.x = 0;

		// Y shape with vertices in the following order
		//6---5   3---2        1.0
		//  \  \+/  /          0.9
		//   \  4  /
		//    7   1            0.7
		//    |   |    Y
		//    |   |    ^
		//    |   |    |
		//    8-+-0    +->X    0.0

		shape = new b2PolygonShape();
		var vertices:Vector.<b2Vec2> = getAntibodyVertices(shapeWidth, shapeHeight, shapeThickness, true);

		shape.SetAsVector(vertices, vertices.length);

		sprite = new Sprite();
		sprite.graphics.lineStyle(1);
		sprite.graphics.beginFill(antibodyFillColor);
		drawVertices(sprite.graphics, getAntibodyVertices(shapeWidth, shapeHeight, shapeThickness, false), _worldRatio);
		sprite.graphics.endFill();

		var bodyInfo:BodyInfo = new BodyInfo();
		bodyInfo.index = _antibodyBodies.length;
		bodyInfo.sprite = sprite;
		bodyInfo.isAntibody = true;
		bodyInfo.pumpAffinity = -1;
		bodyDef.userData = bodyInfo;

		fixtureDef = new b2FixtureDef();
		fixtureDef.shape = shape;
		fixtureDef.density = 1.0;
		fixtureDef.friction = 0.5;
		fixtureDef.restitution = 0.2;
//					fixtureDef.filter.categoryBits = 0x0008;
//					fixtureDef.filter.maskBits  = antibodyMaskBits;

		body = _world.CreateBody(bodyDef);
		bodyInfo.body = body;
		body.CreateFixture(fixtureDef);

		updateSpriteFromBody(body, bodyDef.position, sprite);

		_antibodyBodies.push(body);
		_antibodySprites.push(sprite);
		spriteContainer.addChild(sprite);
	}
}

private function getAntibodyVertices(shapeWidth:Number, shapeHeight:Number, shapeThickness:Number, makeConvex:Boolean):Vector.<b2Vec2>
{
	var vertices:Vector.<b2Vec2> = new Vector.<b2Vec2>();

	const v:Number = -0.9;

	vertices.push(new b2Vec2(+shapeThickness/2, v * shapeHeight));
	if (!makeConvex)
		vertices.push(new b2Vec2(+shapeThickness/2, (v + 0.7) * shapeHeight));
	vertices.push(new b2Vec2(+shapeWidth/2, (v + 1) * shapeHeight));
	if (!makeConvex)
	{
		vertices.push(new b2Vec2(+shapeWidth/2 - shapeThickness, (v + 1) * shapeHeight));
		vertices.push(new b2Vec2(0, (v + 0.7) * shapeHeight + shapeThickness / 2));
		vertices.push(new b2Vec2(-shapeWidth/2 + shapeThickness, (v + 1) * shapeHeight));
	}
	vertices.push(new b2Vec2(-shapeWidth/2, (v + 1) * shapeHeight));
	if (!makeConvex)
		vertices.push(new b2Vec2(-shapeThickness/2, (v + 0.7) * shapeHeight));
	vertices.push(new b2Vec2(-shapeThickness/2, v * shapeHeight));

	return vertices;
}

private function drawVertices(targetGraphics:Graphics, vertices:Vector.<b2Vec2>, scaleFactor:Number):void
{
	var lastVertex:b2Vec2 = vertices[vertices.length - 1];
	targetGraphics.moveTo(lastVertex.x * scaleFactor, lastVertex.y * scaleFactor);

	for each (var vertex:b2Vec2 in vertices)
	{
		targetGraphics.lineTo(vertex.x * scaleFactor, vertex.y * scaleFactor);
	}
}

private function pickPlugPumpAffinity(bodyInfo:BodyInfo):int
{
	// numGaps -> index order
	//       4 -> 1, 3, 0, 2
	//       5 -> 1, 3, 0, 2, 4
	//       6 -> 1, 3, 5, 0, 2, 4
	if (bodyInfo.index * 2 + 1 < numGaps)
		return bodyInfo.index * 2 + 1;
	else
		return (bodyInfo.index - Math.floor(numGaps / 2)) * 2;
}

private function removeSoluteBodies(numBodiesToRemove:int, delayDestruction:Boolean = true):void
{
	for (var i:int = 0; i < numBodiesToRemove; i++)
	{
		var body:b2Body = _soluteBodies.pop();
		var sprite:Sprite = _soluteSprites.pop();
		var bodyInfo:BodyInfo = body.GetUserData() as BodyInfo;

		if (bodyInfo == null || bodyInfo.sprite != sprite)
		{
			trace("Unable to remove solute body; sprite did not match. Bodies:", _soluteBodies.length, "Sprites:", _soluteSprites.length);
			_soluteBodies.push(body);
			_soluteSprites.push(sprite);
			return;
		}
		else
		{
			if (delayDestruction)
			{
				bodyInfo.shouldBeDestroyed = true;
				bodyInfo.pumpAffinity = -1;
			}
			else
			{
				destroyBodyInfo(bodyInfo);
			}
		}
	}
}

private function destroyBodyInfo(bodyInfo:BodyInfo):void
{
	var body:b2Body = bodyInfo.body;
	var sprite:Sprite = bodyInfo.sprite;

	destroyJoint(bodyInfo);

	spriteContainer.removeChild(sprite);
	bodyInfo.sprite = null;

	_world.DestroyBody(body);
	bodyInfo.body = null;

	// now the bodyInfo should have no references to Box2D objects, and should be ready for garbage collection itself
}

private function destroyJoint(bodyInfo:BodyInfo):void
{
	// destroy any associated joint safely, removing any reference from the other body
	if (bodyInfo.plugJoint)
	{
		var weldJoint:b2WeldJoint = bodyInfo.plugJoint as b2WeldJoint;
		if (weldJoint)
		{
			// the other body might have a reference to this same joint; if so, remove the reference
			var otherBody:b2Body = weldJoint.GetBodyA();
			if (otherBody == bodyInfo.body)
				otherBody = weldJoint.GetBodyB();

			var otherBodyInfo:BodyInfo = otherBody.GetUserData() as BodyInfo;
			if (otherBodyInfo && otherBodyInfo.plugJoint == bodyInfo.plugJoint)
			{
				otherBodyInfo.plugJoint = null;
			}
		}
		_world.DestroyJoint(bodyInfo.plugJoint);
		bodyInfo.plugJoint = null;
	}
}

//			private function destroyBodyAndSprite(body:b2Body, sprite:Sprite):void
//			{
//				spriteContainer.removeChild(sprite);
//				_world.DestroyBody(body);
//			}

private function removePlugBodies(numBodiesToRemove:int, delayDestruction:Boolean = true):void
{
	for (var i:int = 0; i < numBodiesToRemove; i++)
	{
		var body:b2Body = _plugBodies.pop();
		var sprite:Sprite = _plugSprites.pop();
		var bodyInfo:BodyInfo = body.GetUserData() as BodyInfo;

		if (bodyInfo == null || bodyInfo.sprite != sprite)
		{
			trace("Unable to remove plug body; sprite did not match. Bodies:", _plugBodies.length, "Sprites:", _plugSprites.length);
			_plugBodies.push(body);
			_plugSprites.push(sprite);
			return;
		}
		else
		{
			if (bodyInfo.plugJoint != null)
			{
				destroyJoint(bodyInfo);

				if (delayDestruction)
				{
					var pos:b2Vec2 = body.GetPosition();

					// eject the plug incase it is stuck in the wall
					body.SetPosition(new b2Vec2(pos.x + 0.1, pos.y));
				}
			}

			if (delayDestruction)
			{
				bodyInfo.shouldBeDestroyed = true;
			}
			else
			{
				destroyBodyInfo(bodyInfo);
			}
		}
	}
}

private function removeAntibodyBodies(numBodiesToRemove:int, delayDestruction:Boolean = true):void
{
	for (var i:int = 0; i < numBodiesToRemove; i++)
	{
		var body:b2Body = _antibodyBodies.pop();
		var sprite:Sprite = _antibodySprites.pop();
		var bodyInfo:BodyInfo = body.GetUserData() as BodyInfo;

		if (bodyInfo == null || bodyInfo.sprite != sprite)
		{
			trace("Unable to remove antibody body; sprite did not match. Bodies:", _antibodyBodies.length, "Sprites:", _antibodySprites.length);
			_antibodyBodies.push(body);
			_antibodySprites.push(sprite);
			return;
		}
		else
		{
			if (bodyInfo.plugJoint != null)
			{
				destroyJoint(bodyInfo);

				if (delayDestruction)
				{
					var pos:b2Vec2 = body.GetPosition();

					// eject the antibody incase it is stuck in the wall
					body.SetPosition(new b2Vec2(pos.x + 0.1, pos.y));
				}
			}

			if (delayDestruction)
			{
				bodyInfo.shouldBeDestroyed = true;
			}
			else
			{
				destroyBodyInfo(bodyInfo);
			}
		}
	}
}

protected function group1_keyDownHandler(event:KeyboardEvent):void
{
	// TODO: figure out why this event is not firing and fix it; currently this event handler is never executed
	super.keyDownHandler(event);

	if (!event.altKey && !event.ctrlKey)
	{
		var numBodies:int = NaN;

		if (event.keyCode == Keyboard.NUMBER_0)
			numBodies = 0;
		else if (event.keyCode == Keyboard.NUMBER_1)
			numBodies = 1;
		else if (event.keyCode == Keyboard.NUMBER_2)
			numBodies = 2;
		else if (event.keyCode == Keyboard.NUMBER_3)
			numBodies = 3;
		else if (event.keyCode == Keyboard.NUMBER_4)
			numBodies = 20;
		else if (event.keyCode == Keyboard.NUMBER_5)
			numBodies = 50;
		else if (event.keyCode == Keyboard.NUMBER_6)
			numBodies = 100;
		else if (event.keyCode == Keyboard.NUMBER_7)
			numBodies = 1000;

		if (!isNaN(numBodies))
		{
			changeSoluteBodiesPopulation(numBodies);
			changeAntibodyBodiesPopulation(calculateNumAntibodies());
		}
	}
}

private function changeSoluteBodiesPopulation(targetNumSoluteBodies:int):void
{
	var delta:int = targetNumSoluteBodies - _soluteBodies.length;

	if (delta > 0)
	{
		// add bodies
		createSoluteBodies(delta);
	}
	else if (delta < 0)
	{
		// remove bodies
		removeSoluteBodies(-delta, false);
	}
}

private function changePlugBodiesPopulation(targetNumPlugBodies:int):void
{
	var delta:int = targetNumPlugBodies - _plugBodies.length;

	if (delta > 0)
	{
		// find and re-use as many "to-be-destroyed" plugs as possible
		delta = reusePlugBodies(delta);

		// reset pump affinities on existing plugs
		resetPlugPumpAffinities();

		// add bodies
		createPlugBodies(delta);
	}
	else if (delta < 0)
	{
		// remove bodies
		removePlugBodies(-delta);

		// reset pump affinities on existing plugs
		resetPlugPumpAffinities();
	}
}

private function changeAntibodyBodiesPopulation(targetNumAntibodyBodies:int):void
{
	var delta:int = targetNumAntibodyBodies - _antibodyBodies.length;

	if (delta > 0)
	{
		// find and re-use as many "to-be-destroyed" antibodies as possible
		delta = reuseAntibodyBodies(delta);

		// add bodies
		createAntibodyBodies(delta);
	}
	else if (delta < 0)
	{
		// remove bodies
		removeAntibodyBodies(-delta);
	}
}

private function resetPlugPumpAffinities():void
{
	for each (var body:b2Body in _plugBodies)
	{
		var bodyInfo:BodyInfo = body.GetUserData() as BodyInfo;
		if (bodyInfo != null)
			bodyInfo.pumpAffinity = pickPlugPumpAffinity(bodyInfo);
	}
}

private function calculateNumGaps():void
{
	var minGapSpace:Number = gapSize * 1.8;
	numGaps = Math.floor(wallsGroup.height / minGapSpace);
}

private function createDynamicWallRects():void
{
	removeDynamicWallRects();

	if (wallsGroup.height == 0 || numGaps == 0)
		return;

	var numWallPieces:int = numGaps + 1;

	var gapToGapSpacing:Number = wallsGroup.height / numGaps;
	pumpSpacing = gapToGapSpacing;
	var wallHeight:Number = gapToGapSpacing - plugHeight;
	var wallTaper:Number = plugHeight / 4;

	var currentY:Number = -wallHeight / 2;

	_pumps = new Vector.<b2Vec2>();
	for (var i:int = 0; i < numWallPieces; i++)
	{
		var wallX:Number = wallsGroup.width * bloodAreaPercentWidth;
		var wallY:Number = currentY + wallHeight / 2;

		var wallSprite:Sprite = new Sprite();
		var vertices:Vector.<b2Vec2> = createWallBody(wallX, wallY, plugWidth, wallHeight, wallTaper, wallSprite);
		createWallVisual(wallX, wallY, vertices, wallSprite);
		currentY += gapToGapSpacing;

		if (currentY < wallsGroup.height)
		{
			var pumpPos:b2Vec2 = new b2Vec2();
			pumpPos.x = (wallsGroup.width * bloodAreaPercentWidth) / _worldRatio;
			pumpPos.y = (currentY - plugHeight / 2) / _worldRatio;
			_pumps.push(pumpPos);
		}
	}
}

private function removeDynamicWallRects():void
{
	for (var i:int = wallsGroup.numElements - 1; i >= 0; i--)
	{
		var wallRect:Rect = wallsGroup.getElementAt(i) as Rect;
		// dynamic wall rects have no id
		if (wallRect != null && wallRect.id == null)
		{
			wallsGroup.removeElementAt(i);
		}
	}
}

private function createWall(wallX:Number, wallY:Number, wallHeight:Number):void
{
	var wallRect:Rect = new Rect();

	wallRect.width = 1;
	wallRect.x = wallX - wallRect.width / 2;
	wallRect.y = wallY;
	wallRect.height = wallHeight;
	wallRect.stroke = new SolidColorStroke(0x222222, 3);

	wallsGroup.addElement(wallRect);
}

private function createWallBody(wallX:Number, wallY:Number, wallWidth:Number, wallHeight:Number, wallTaper:Number, wallSprite:Sprite):Vector.<b2Vec2>
{
	var shapeWidth:Number = wallWidth / _worldRatio;
	var shapeHeight:Number = wallHeight / _worldRatio;
	var shapeTaper:Number = wallTaper / _worldRatio;

	// create generic body definition
	var bodyDef:b2BodyDef = new b2BodyDef();
	bodyDef.type = b2Body.b2_staticBody;
	bodyDef.position.Set(wallX / _worldRatio, wallY / _worldRatio);
	bodyDef.userData = wallSprite;

	// Trapezoid shape with vertices in the following order (turned on it's side here for convenience):
	// 0-------3  +->Y
	//  \  +  /   V
	//   1---2    X

	var shape:b2PolygonShape = new b2PolygonShape();
	var vertices:Vector.<b2Vec2> = new Vector.<b2Vec2>();
	vertices.push(new b2Vec2(-shapeWidth/2, -shapeHeight/2 - (pumpDirectionReversed ? 0 : shapeTaper)));
	vertices.push(new b2Vec2(+shapeWidth/2, -shapeHeight/2 - (pumpDirectionReversed ? shapeTaper : 0)));
	vertices.push(new b2Vec2(+shapeWidth/2, +shapeHeight/2 + (pumpDirectionReversed ? shapeTaper : 0)));
	vertices.push(new b2Vec2(-shapeWidth/2, +shapeHeight/2 + (pumpDirectionReversed ? 0 : shapeTaper)));
	shape.SetAsVector(vertices, 4);

	var fixtureDef:b2FixtureDef = new b2FixtureDef();
	fixtureDef.shape = shape;
	fixtureDef.friction = 0.3;
	fixtureDef.density = 0; // static bodies require zero density
	fixtureDef.filter.categoryBits = 0x0002;

	var body:b2Body = _world.CreateBody(bodyDef);
	body.CreateFixture(fixtureDef);

	_wallBodies.push(body);

	return vertices;
}

private function createWallVisual(wallX:Number, wallY:Number, vertices:Vector.<b2Vec2>, sprite:Sprite):void
{
	sprite.graphics.lineStyle(1);
	var color:uint = 0x444444;
	sprite.graphics.beginFill(color);
	drawVertices(sprite.graphics, vertices, _worldRatio);
	sprite.graphics.endFill();

	sprite.x = wallX;
	sprite.y = wallY;

	_wallSprites.push(sprite);
	spriteContainer.addChild(sprite);
}

private function createWallBodies():void
{
	var body:b2Body;
	var bodyDef:b2BodyDef;
	var boxShape:b2PolygonShape;

	_wallRects = new Vector.<Rect>();

	for (var i:int = 0; i < wallsGroup.numElements; i++)
	{
		var wallRect:Rect = wallsGroup.getElementAt(i) as Rect;
		if (wallRect != null)
		{
			_wallRects.push(wallRect);

			bodyDef = new b2BodyDef();
			bodyDef.type = b2Body.b2_staticBody;
			bodyDef.position.Set((wallRect.x + wallRect.width / 2) / _worldRatio, (wallRect.y + wallRect.height / 2) / _worldRatio);
			bodyDef.userData = wallRect;

			boxShape = new b2PolygonShape();
			boxShape.SetAsBox(wallRect.width/_worldRatio/2, wallRect.height/_worldRatio/2);

			var fixtureDef:b2FixtureDef = new b2FixtureDef();
			fixtureDef.shape = boxShape;
			fixtureDef.friction = 0.3;
			fixtureDef.density = 0; // static bodies require zero density
			fixtureDef.filter.categoryBits = 0x0002;

			body = _world.CreateBody(bodyDef);
			body.CreateFixture(fixtureDef);
		}
	}
}

private function removeWallBodies():void
{
	// Go through body list and update body positions/sizes
	for (var body:b2Body = _world.GetBodyList(); body; body = body.GetNext())
	{
		if (body.GetUserData() is IVisualElement)
		{
			_world.DestroyBody(body);
		}
	}

	for (var i:int = 0; _wallBodies.length > 0; i++)
	{
		body = _wallBodies.pop();
		var sprite:Sprite = _wallSprites.pop();

		if (body.GetUserData() as Sprite != sprite)
		{
			trace("Unable to remove wall body; sprite did not match. Bodies:", _wallBodies.length, "Sprites:", _wallSprites.length);
			_wallBodies.push(body);
			_wallSprites.push(sprite);
			return;
		}
		else
		{
			spriteContainer.removeChild(sprite);
			_world.DestroyBody(body);
		}
	}
}

private function mouseClickHandler(e:MouseEvent):void
{
//				showDebug = !showDebug;
}

private function get verticalRecycleMaximum():Number
{
	return this.height + 10;
}

public function enterFrameHandler(e:Event):void
{
	if (isWorldBigEnough && _world)
	{
		// Update mouse joint
		mouseDrag();

		pumpZoneLeft = wallsGroup.width * bloodAreaPercentWidth - plugWidth / 2 - soluteWidth * 0.6;
		pumpZoneRight = wallsGroup.width * bloodAreaPercentWidth + plugWidth / 2 + soluteWidth * 0.6;

		applyForces();

		_world.Step(_timeStep, _velocityIterations, _positionIterations);
		if (_showDebug) {
			_world.DrawDebugData();
		}
		_world.ClearForces();

		updatePositions();
	}
}

private function applyForces():void
{
	// Apply forces
	for (var body:b2Body = _world.GetBodyList(); body; body = body.GetNext())
	{
		if (body.GetMass() > 0 && body.GetUserData() is BodyInfo)
		{
			var bodyInfo:BodyInfo = body.GetUserData() as BodyInfo;

			if (bodyInfo.plugJoint && bodyInfo.isPlug)
			{
				// no forces for a plug that has a joint (just leave it in place)
			}
			else
			{
				updateBodyStuckTime(body, bodyInfo);

				unstickPlug(body, bodyInfo);

				if (bodyInfo.isPlug)
				{
					// reset damping
					body.SetAngularDamping(0);
					body.SetLinearDamping(0);
				}

				applyFlowForce(body, bodyInfo);

				applyTurbulenceImpulse(body, bodyInfo);

				applyPumpForce(body, bodyInfo);
			}
		}
	}
}

private function applyFlowForce(body:b2Body, bodyInfo:BodyInfo):void
{
	// flow force
	var flowForce:b2Vec2 = new b2Vec2();
	flowForce.y = (flowVelocity - body.GetLinearVelocity().y) * body.GetMass() * _timeStep;
	// trace("Position:", body.GetPosition().y.toFixed(2), "Velocity:", body.GetLinearVelocity().y.toFixed(2), "Force:", flowForce.y.toFixed(2));
	if (Math.abs(flowForce.y) > 0.00001)
		body.ApplyImpulse(flowForce, body.GetWorldCenter());
}

private function applyTurbulenceImpulse(body:b2Body, bodyInfo:BodyInfo):void
{
	if (Math.random() >= 0.05)
	{
		const maxTurbulence:Number = 5;
		var turbulenceImpulse:b2Vec2 = new b2Vec2();
		turbulenceImpulse.x = (Math.random() * maxTurbulence - (maxTurbulence / 2)) * body.GetMass() * _timeStep;
		turbulenceImpulse.y = (Math.random() * maxTurbulence - (maxTurbulence / 2)) * body.GetMass() * _timeStep;
		var turbulenceLocation:b2Vec2 = body.GetWorldCenter();
		//							turbulenceLocation.y -= 0.5;
		//							turbulenceLocation.y += Math.random() * 2 - 1; // TODO: make sure location is relative to body size

		body.ApplyImpulse(turbulenceImpulse, turbulenceLocation);
	}
}

private function unstickPlug(body:b2Body, bodyInfo:BodyInfo):void
{
	if (bodyInfo.isPlug && bodyInfo.stuckTime > plugStuckTimePassThroughWallThreshold)
	{
		var filter:b2FilterData = body.GetFixtureList().GetFilterData();
		filter.maskBits = 0; // don't collide with anything
		body.GetFixtureList().SetFilterData(filter);

		// toggle active state to ensure that any existing contacts are reset
		body.SetActive(false);
		body.SetActive(true);
	}
}

public function get pumpDirectionReversed():Boolean
{
	return pumpDirectionFactor == -1;
}

public function set pumpDirectionReversed(value:Boolean):void
{
	pumpDirectionFactor = value ? -1 : 1;
}

private var pumpDirectionFactor:Number = 1;

private function applyPumpForce(body:b2Body, bodyInfo:BodyInfo):void
{
	var pos:b2Vec2 = body.GetPosition();
	if (_pumps.length > 0)
	{
		var pumpPos:b2Vec2;
		if (!bodyInfo.hasBeenBlocked && bodyInfo.pumpAffinity > -1 && bodyInfo.pumpAffinity < _pumps.length)
		{
			if (bodyInfo.isSolute)
			{
				// change pump affinity if the solute is very near/inside the wall (accidentally within another pump)
				if (pos.x > pumpZoneLeft / _worldRatio &&
					pos.y < pumpZoneRight / _worldRatio)
					bodyInfo.pumpAffinity = getNearestPumpIndex(pos);
			}

			pumpPos = _pumps[bodyInfo.pumpAffinity];

			var pumpForce:b2Vec2 = new b2Vec2();
			pumpForce.SetV(pumpPos);
			pumpForce.Subtract(pos);
			var distance:Number = pumpForce.Normalize();

			var pumpRange:Number = 2;
			var pumpStrength:Number = 20;
			if (bodyInfo.isSolute)
			{
				if (isBodyOnOutputSideOfPump(pos, pumpPos))
				{
					pumpRange = 0.5;
					pumpStrength = -10;
				}
			}
			else
			{
				if (bodyInfo.shouldBeDestroyed && !isBodyOnOutputSideOfPump(pos, pumpPos))
				{
					pumpStrength = -1;
				}
				else
				{
					pumpRange = wallsGroup.width * bloodAreaPercentWidth / _worldRatio;
					pumpStrength = 60;

					if (!bodyInfo.shouldBeDestroyed)
					{
						// angular force to ensure the plug is oriented correctly
						var maxTorque:Number = body.GetMass() * _timeStep;
						var minTorque:Number = -maxTorque;
						var torqueStrength:Number = 200;

						var targetAngle:Number = 0;
						if (isBodyOnOutputSideOfPump(pos, pumpPos))
							targetAngle = -Math.PI / 2;

						var currentAngle:Number = body.GetAngle();
						if (currentAngle > Math.PI)
							currentAngle -= 2 * Math.PI;

						var torque:Number = Math.max(minTorque, Math.min(maxTorque, (targetAngle - currentAngle) * body.GetMass() * _timeStep)) * torqueStrength;
						body.ApplyTorque(torque);

						body.SetAngularDamping(10);
						body.SetLinearDamping(Math.max(0, pumpRange - distance) / pumpRange * 10);
					}
					//									trace("body.GetAngularDamping()", body.GetAngularDamping(), "body.GetLinearDamping()", body.GetLinearDamping());

					if (!bodyInfo.shouldBeDestroyed && distance < snapDistanceEpsilon)
					{
						joinPlugToPump(body, pumpPos, bodyInfo);
						resetPlugMaskBits(body, bodyInfo);
					}
				}
			}

			pumpForce.Multiply(Math.max(0, (pumpRange - distance) / pumpRange) * pumpStrength * body.GetMass() * _timeStep);

			body.ApplyImpulse(pumpForce, body.GetWorldCenter());
		}
	}
}

private function isBodyOnOutputSideOfPump(pos:b2Vec2, pumpPos:b2Vec2):Boolean
{
	if (pumpDirectionReversed)
		return pos.x > pumpPos.x;
	else
		return pos.x < pumpPos.x;
}

private function updatePositions():void
{
	// Go through body list and update sprite positions/rotations
	for (var body:b2Body = _world.GetBodyList(); body; body = body.GetNext())
	{
		if (body.GetMass() > 0 && body.GetUserData() is BodyInfo)
		{
			var bodyInfo:BodyInfo = body.GetUserData() as BodyInfo;
			var sprite:Sprite = bodyInfo.sprite;
			var pos:b2Vec2 = body.GetPosition();
			var wasDestroyed:Boolean = false;

			// loop
			if (pos.y * _worldRatio > verticalRecycleMaximum || bodyIsStuck(body, bodyInfo))
			{
				bodyInfo.stuckTime = 0;
				if (bodyInfo.shouldBeDestroyed)
				{
					destroyBodyInfo(bodyInfo);
					wasDestroyed = true;
				}
				else
				{
					if (bodyInfo.isSolute)
					{
						bodyInfo.hasBeenBlocked = false;
						bodyInfo.pumpAffinity = pickSolutePumpAffinity();
					}

					recycleBody(body, bodyInfo);
				}
			}
			else if (pos.y * _worldRatio < verticalRecycleMinimum)
			{
				recycleBody(body, bodyInfo);
			}

			if (!wasDestroyed)
			{
				updateSpriteFromBody(body, pos, sprite);
			}
		}
	}
}

private function updateSpriteFromBody(body:b2Body, pos:b2Vec2, sprite:Sprite):void
{
	sprite.x = pos.x * _worldRatio;
	sprite.y = pos.y * _worldRatio;
	sprite.rotation = body.GetAngle() * (180 / Math.PI);
}

private function recycleBody(body:b2Body, bodyInfo:BodyInfo):void
{
	var pos:b2Vec2 = new b2Vec2();
	pos.y = verticalRecycleMinimum / _worldRatio;

	// evenly distribute bodies horizontally when recycling
	pos.x = getBodyPosX(bodyInfo.isSolute ? soluteInBloodRatio : (bodyInfo.isPlug ? 0 : 1));
	body.SetPosition(pos);

	body.SetLinearVelocity(new b2Vec2(0, flowVelocity));

	body.SetAngle(Math.random() * Math.PI);

	resetPlugMaskBits(body, bodyInfo);
}

private function updateBodyStuckTime(body:b2Body, bodyInfo:BodyInfo):void
{
	var displacement:b2Vec2;
	if (bodyInfo.stuckPosition != null)
	{
		displacement = body.GetPosition().Copy();
		displacement.Subtract(bodyInfo.stuckPosition);
	}

	// body is considered stuck if it has been near the same location for too long
	if (bodyInfo.plugJoint == null && m_mouseJoint == null && displacement != null && displacement.LengthSquared() < stuckDisplacementEpsilon * stuckDisplacementEpsilon)
	{
		bodyInfo.stuckTime += _timeStep;
	}
	else
	{
		bodyInfo.stuckTime = 0;
		bodyInfo.stuckPosition = body.GetPosition().Copy();
	}
}

private function bodyIsStuck(body:b2Body, bodyInfo:BodyInfo):Boolean
{
	return (bodyInfo.stuckTime > (bodyInfo.isPlug ? plugStuckTimeThreshold : soluteStuckTimeThreshold));
}

private function joinPlugToPump(body:b2Body, pumpPos:b2Vec2, plugBodyInfo:BodyInfo):void
{
	if (plugBodyInfo.plugJoint == null && !hasMouseJoint(body))
	{
		var jointDef:b2WeldJointDef = new b2WeldJointDef();
		jointDef.bodyA = _world.GetGroundBody();
		jointDef.bodyB = body;
		jointDef.localAnchorA = pumpPos;
		jointDef.collideConnected = false;
		var joint:b2Joint = _world.CreateJoint(jointDef);

		plugBodyInfo.plugJoint = joint;
	}
}

private function resetPlugMaskBits(body:b2Body, bodyInfo:BodyInfo):void
{
	if (bodyInfo.isPlug)
	{
		var filter:b2FilterData = body.GetFixtureList().GetFilterData();
		if (filter.maskBits != plugMaskBits)
		{
//						trace("plug maskBits reset");
			filter.maskBits = plugMaskBits;
			body.GetFixtureList().SetFilterData(filter);
		}
	}
}

private function hasMouseJoint(body:b2Body):Boolean
{
	return m_mouseJoint != null && m_mouseJoint.GetBodyB() == body;
}

private function getBodyPosX(ratioOnLeft:Number):Number
{
	if (Math.random() <= ratioOnLeft)
		return (Math.random() * bloodAreaPercentWidth) * this.width / _worldRatio;
	else
		return (bloodAreaPercentWidth + Math.random() * (1 - bloodAreaPercentWidth)) * this.width / _worldRatio;
}

private function getNearestPump(pos:b2Vec2):b2Vec2
{
	return _pumps[getNearestPumpIndex(pos)];
}

private function getNearestPumpIndex(pos:b2Vec2):int
{
	// guess the index based on the fact that the gaps/pumps are evenly spaced
	return Math.max(0, Math.min(_pumps.length - 1, Math.floor(pos.y / (pumpSpacing / _worldRatio))));
}

public function updateMouseWorld(mouseStageX:Number, mouseStageY:Number):void
{
	var mouseStage:Point = new Point(mouseStageX, mouseStageY);
	var mouseLocal:Point = this.globalToLocal(mouseStage);

	mouseDragX = mouseLocal.x;
	mouseDragY = mouseLocal.y;

	// constrain mouse to masked area of this component
	mouseDragX = Math.max(0, Math.min(this.width, mouseDragX));
	mouseDragY = Math.max(0, Math.min(this.height, mouseDragY));

	mouseXWorldPhys = (mouseDragX)/_worldRatio;
	mouseYWorldPhys = (mouseDragY)/_worldRatio;

	mouseXWorld = (mouseDragX);
	mouseYWorld = (mouseDragY);
}

public function mouseDrag():void
{
	// mouse move
	if (mouseDown && m_mouseJoint)
	{
		var p2:b2Vec2 = new b2Vec2(mouseXWorldPhys, mouseYWorldPhys);
		m_mouseJoint.SetTarget(p2);
	}
}

public function getBodyAtMouse(includeStatic:Boolean = false):b2Body
{
	// Make a small box.
	mousePVec.Set(mouseXWorldPhys, mouseYWorldPhys);
	var aabb:b2AABB = new b2AABB();
	aabb.lowerBound.Set(mouseXWorldPhys - 0.001, mouseYWorldPhys - 0.001);
	aabb.upperBound.Set(mouseXWorldPhys + 0.001, mouseYWorldPhys + 0.001);
	var body:b2Body = null;
	var fixture:b2Fixture;

	// Query the world for overlapping shapes.
	function getBodyCallback(fixture:b2Fixture):Boolean
	{
		var shape:b2Shape = fixture.GetShape();
		if (fixture.GetBody().GetType() != b2Body.b2_staticBody || includeStatic)
		{
			var inside:Boolean = shape.TestPoint(fixture.GetBody().GetTransform(), mousePVec);
			if (inside)
			{
				body = fixture.GetBody();
				return false;
			}
		}
		return true;
	}
	_world.QueryAABB(getBodyCallback, aabb);
	return body;
}

protected function wallsGroup_resizeHandler(event:ResizeEvent):void
{
	callLater(resizeWorld);
}

private function resizeWorld():void
{
	if (_world != null)
	{
		if (isWorldBigEnough)
		{
			var oldWidth:Number = this.wallsGroup.width;
			var oldHeight:Number = this.wallsGroup.height;

			removeWallBodies();
			calculateNumGaps();
			createDynamicWallRects();
			createWallBodies();

			moveDynamicBodiesAfterResize(this.wallsGroup.width / oldWidth, this.wallsGroup.height / oldHeight);
			changePlugBodiesPopulation(calculateNumPlugs());
			// TODO: move the existing plugs to appropriate positions so we don't have to re-create them all
//					removePlugBodies(_plugBodies.length, false);
//					createPlugBodies(calculateNumPlugs());
			changeSoluteBodiesPopulation(calculateNumSoluteBodies());
			changeAntibodyBodiesPopulation(calculateNumAntibodies());
		}
	}
}

private function get isWorldBigEnough():Boolean
{
	return this.wallsGroup.width / _worldRatio >= minWorldWidth && this.wallsGroup.height / _worldRatio >= minWorldHeight;
}

private function moveDynamicBodiesAfterResize(resizeFactorX:Number, resizeFactorY:Number):void
{
	// Go through body list and update sprite positions/rotations
	for (var body:b2Body = _world.GetBodyList(); body; body = body.GetNext())
	{
		if (body.GetMass() > 0 && body.GetUserData() is BodyInfo)
		{
			var bodyInfo:BodyInfo = body.GetUserData() as BodyInfo;
			var sprite:Sprite = bodyInfo.sprite;
			var pos:b2Vec2 = body.GetPosition();

			if (bodyInfo != null && bodyInfo.plugJoint)
			{
				destroyJoint(bodyInfo);
			}

			pos.x *= resizeFactorX;
			pos.y *= resizeFactorY;
			body.SetPosition(pos);

			updateSpriteFromBody(body, pos, sprite);
		}
	}
}

protected function addedToStageHandler(event:Event):void
{
	isRunning = true;
}

protected function removedFromStageHandler(event:Event):void
{
	isRunning = false;
	this.removeEventListener(MouseEvent.CLICK, mouseClickHandler);
	this.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
}