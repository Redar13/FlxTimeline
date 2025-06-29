package flixel.timeline.types;

import flixel.math.FlxMath;
import flixel.timeline.FlxEvent;
import flixel.timeline.FlxTimeline;

class SetEvent extends FlxEvent
{
	public var action:SetEvent->Void;
	public var totalRepeatTimes:Int = 1;
	public var repeatTime:Int = 0;

	var _forse:Bool = false;

	public function new(timeline:FlxTimeline, startTime:Float, action:SetEvent->Void, duration:Float, repeatTimes:Int, tag:Null<String>) {
		super(timeline, startTime, duration, tag);
		this.totalRepeatTimes = FlxMath.maxInt(repeatTimes, 0);
		this.action = action;
	}

	public function updateByTime(time:Float)
	{
		final isZeroDuraction = FlxMath.equal(duration, 0.0);
		if (time >= startTime && (isZeroDuraction || time < endTime) && (!isZeroDuraction || _nextEvent == null || time < _nextEvent.startTime))
		{
			var percent:Float = isZeroDuraction ? ((time - startTime) > 0 ? 1 : 0) : FlxMath.bound((time - startTime) / duration, 0.0, 1.0);
			var nextTime = Math.floor(percent * (totalRepeatTimes + 1));
			var left = nextTime - repeatTime;
			if (_forse || left != 0)
			{
				_forse = false;
				if (left == 0)
				{
					action(this);
				}
				else 
				{
					var elp:Int = FlxMath.signOf(left);
					do {
						repeatTime += elp;
						left -= elp;
						action(this);
					} while(left != 0);
				}
			}
		}
		else
		{
			repeatTime = 0;
			_forse = true;
		}
	}
	override function destroy():Void
	{
		super.destroy();
		action = null;
	}
}