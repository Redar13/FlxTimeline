package flixel.timeline.types;

import flixel.timeline.FlxEvent;
import flixel.timeline.FlxTimeline;
import flixel.timeline.types.TweenEvent;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxArrayUtil;

class NumTweenEvent extends TweenEvent
{
	public var value(default, null):Float;

	var _tweenFunction:Float->Void;
	var _startNum:Float;
	var _rangeNum:Float;

	public function new(timeline:FlxTimeline, startTime:Float, fromValue:Float, toValue:Float, duration:Float, tweenFunction:Float->Void, options:Null<TweenEventOptions>, tag:Null<String>)
	{
		super(timeline, startTime, duration, options, tag);
		this._startNum = value = fromValue;
		this._rangeNum = toValue - value;
		this._tweenFunction = tweenFunction;
	}

	override function _update()
	{
		value = _startNum + _rangeNum * scale;

		_tweenFunction(value);
        super._update();
	}

	override function destroy():Void
	{
		super.destroy();
		_tweenFunction = null;
	}
}

private typedef TweenProperty =
{
	object:Dynamic,
	field:String,
	setter:Float->Void,
	startValue:Float,
	range:Float
}
