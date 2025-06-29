package flixel.timeline.types;

import flixel.timeline.FlxEvent;
import flixel.timeline.FlxTimeline;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxArrayUtil;

// TODO: Improve support reversed time

class TweenEvent extends FlxEvent
{
	public var ease:EaseFunction;
	public var scale(default, null):Float;
	public var onStart:TweenCallback;
	public var onUpdate:TweenCallback;
	public var onComplete:TweenCallback;
	public var backward:Bool;

	var _prevPercent:Float = -1;

	var _active:Bool = false;

	public function new(timeline:FlxTimeline, startTime:Float, duration:Float, options:Null<TweenEventOptions>, tag:Null<String>)
	{
		super(timeline, startTime, duration, tag);
		if (options != null)
		{
			this.ease = options.ease == null ? FlxEase.linear : options.ease;
			this.onStart = options.onStart;
			this.onUpdate = options.onUpdate;
			this.onComplete = options.onComplete;
		}
		else
		{
			this.ease = FlxEase.linear;
		}
	}

	public function updateByTime(time:Float)
	{
		var isActivated = time >= startTime && time < endTime;
		// var newPercent = FlxMath.bound((time - startTime) / duration, 0.0, 1.0);
		var newPercent = (time - startTime) / duration;
		if (!fired && !FlxMath.equal(_prevPercent, newPercent))
		{
			var prevActive = _active;
			_active = isActivated;
			if (prevActive || isActivated)
			{
				scale = ease(FlxMath.bound(newPercent, 0, 1));
				if (backward) 
					scale = 1 - scale;
			}
			if (!prevActive && isActivated)
			{
				_start(_prevPercent < newPercent);
			}

			if (prevActive || isActivated)
			{
				_update();
			}

			if (prevActive && !isActivated)
			{
				_complete();
			}
			_prevPercent = newPercent;
		}
		else
		{
			_active = isActivated;
		}
	}

	function _start(setupValues:Bool = true)
	{
		if (onStart != null)
		{
			onStart(this);
		}
	}

	function _update()
	{
		if (onUpdate != null)
		{
			onUpdate(this);
		}
	}

	function _complete()
	{
		if (onComplete != null)
		{
			onComplete(this);
		}
	}
}

typedef TweenCallback = TweenEvent->Void;

typedef TweenEventOptions =
{
	@:optional var ease:EaseFunction;

	@:optional var onStart:TweenCallback;

	@:optional var onUpdate:TweenCallback;

	@:optional var onComplete:TweenCallback;
}