package flixel.timeline;

import flixel.math.FlxMath;
import flixel.timeline.FlxTimeline;
import flixel.util.FlxDestroyUtil;

@:allow(flixel.timeline.FlxTimeline)
abstract class FlxEvent implements IFlxDestroyable {
	public var endTime(get, never):Float;
	public var startTime:Float;
	public var duration:Float;
	public var tag:Null<String> = null;
	public var fired(default, null):Bool;
	var _timeline:FlxTimeline;
	var _nextEvent:Null<FlxEvent> = null;
	function new(timeline:FlxTimeline, startTime:Float, duration:Float, tag:Null<String>) {
		this._timeline = timeline;
		this.startTime = startTime;
		if (duration < 0.0)
			duration = 0.0;
		this.duration = duration;
		this.tag = tag;
	}

	public abstract function updateByTime(time:Float):Void;

	public function destroy():Void
	{
		_nextEvent = null;
		_timeline = null;
		tag = null;
	}

	function _updateWithNextEvent(time:Float) {
		fired = startTime >= time;
		updateByTime(time);
		if  (_nextEvent != null)
			_nextEvent._updateWithNextEvent(time);
	}

	inline function get_endTime():Float return startTime + duration;
}