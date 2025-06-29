package flixel.timeline;

import flixel.timeline.FlxEvent;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.timeline.types.VarTweenEvent;
import flixel.timeline.types.NumTweenEvent;
import flixel.timeline.types.TweenEvent.TweenEventOptions;
import flixel.timeline.types.SetEvent;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;

using StringTools;

class FlxTimeline extends FlxTypedGroup<FlxTimeline>
{
	public var name:String;

	public var getTime:Null<Void->Float> = null;
	public var animTime(get, set):Float;
	public var animLength(default, set):Float;
	public var timescale:Float = 1.0;
	public var loopPoint:Float = 0.0;
	public var percent(get, set):Float;
	public var framerate(default, set):Float;
	public var curFrame(get, set):Int;
	public var numFrames(get, never):Int;
	public var forseUpdate:Bool = false;

	public final onFinish = new FlxTypedSignal<FlxTimeline->Void>();
	public final onLoop = new FlxTypedSignal<FlxTimeline->Void>();
	public final onFrameChange = new FlxTypedSignal<(instance:FlxTimeline, frameNumber:Int)->Void>();

	public var playing(get, set):Bool;
	public var paused:Bool = true;
	public var finished(default, null):Bool = true;
	public var looped:Bool = false;
	public var reversed:Bool = false;

	public var events:Array<FlxEvent> = [];

	public var parent(default, null):Null<FlxTimeline> = null;

	var _dirtyEventsSort:Bool = false;

	var __curTime:Float = 0;
	@:noCompletion var __prevTime:Float = -1;
	@:noCompletion var __prevFrameTime:Float = -1;
	@:noCompletion var __dispatchFinish:Bool = false;
	@:noCompletion var __dispatchLoop:Bool = false;

	public function new(MaxSize:Int = 0, ?Name:String)
	{
		super(MaxSize);
		if (Name != null)
			this.name = Name;
		else
			this.name = 'Unnamed($ID)';
		visible = false;
		framerate = -1;
		animLength = -1;
	}

	public inline function sortEvents()
	{
		_dirtyEventsSort = true;
		_sortEvents();
	}

	public function play(Force:Bool = false, Reversed:Bool = false, Time:Float = 0):Void
	{
		if (!Force && !finished && reversed == Reversed)
		{
			paused = false;
			return;
		}

		reversed = Reversed;
		paused = finished = false;

		if (Time < 0)
		{
			animTime = FlxG.random.float(0, animLength);
		}
		else
		{
			if (Time < 0)			Time = 0;
			else if (Time > animLength)	Time = animLength;
			animTime = (reversed ? animLength - Time : Time); 
		}
	}
	public function restart():Void
	{
		play(true, reversed);
	}

	public function stop():Void
	{
		finished = paused = true;
	}

	public function reset():Void
	{
		stop();
		animTime = (reversed ? animLength : 0);
	}

	public function finish():Void
	{
		stop();
		animTime = (reversed ? 0 : animLength);
	}

	public inline function pause():Void
	{
		paused = true;
	}
	public inline function resume():Void
	{
		paused = false;
	}
	
	public function reverse():Void
	{
		reversed = !reversed;
		if (finished)
			play(false, reversed);
	}


	public inline function addSetEvent(time:Float, action:SetEvent->Void, ?duration:Null<Float>, ?repeatTimes:Null<Int>, ?tag:String):SetEvent
	{
		return addEvent(new SetEvent(this, time, action, duration == null ? 0 : duration, repeatTimes == null ? 1 : repeatTimes, tag));
	}
	
	public inline function addTweenEvent(time:Float, object:Null<Dynamic>, properties:Null<Dynamic>, duration:Float, ?options:TweenEventOptions, ?tag:String):VarTweenEvent
	{
		return addEvent(new VarTweenEvent(this, time, object, properties, duration, options, tag));
	}

	public inline function addNumTweenEvent(time:Float, fromValue:Float, toValue:Float, duration:Float, tweenFunction:Float->Void, ?options:TweenEventOptions, ?tag:String):NumTweenEvent
	{
		return addEvent(new NumTweenEvent(this, time, fromValue, toValue, duration, tweenFunction, options, tag));
	}
	
	public function addEvent<E:FlxEvent>(Event:E):E
	{
		_dirtyEventsSort = true;
		events.push(Event);
		return Event;
	}
	public function removeEvent<E:FlxEvent>(Event:E):E
	{
		if (events.remove(Event))
			_dirtyEventsSort = true;
		return Event;
	}
	public function removeEvents<E:FlxEvent>(Events:Array<E>):Array<E>
	{
		if (Events.length > 0)
		{
			_dirtyEventsSort = true;
			for (i in Events)
				removeEvent(i);
		}
		return Events;
	}
	public inline function removeEventByName(Name:String):Array<FlxEvent>
	{
		return removeEvents(getEvents(Name));
	}
	public inline function removeEventsByTimes(?StartTime:Null<Float>, ?EndTime:Null<Float>):Array<FlxEvent>
	{
		return removeEvents(getEventsAtTimes(StartTime, EndTime));
	}

	public function getEvent(Name:Null<String>):Null<FlxEvent>
	{
		var i:Int = 0;
		var event;
		while (i < events.length) {
			event = events[i++];
			if (event != null && event.tag == Name)
			{
				return events[i];
			}
		}
		return null;
	}
	
	public inline function getFirstEvent():Null<FlxEvent>
	{
		return events[0];
	}

	public function findLastEvent(Name:Null<String>):Null<FlxEvent>
	{
		var i:Int = events.length - 1;
		var event;
		while (i >= 0) {
			event = events[i];
			if (event != null && event.tag == Name)
			{
				return events[i];
			}
			i--;
		}
		return null;
	}
	public inline function getLastEvent():Null<FlxEvent>
	{
		return events[events.length - 1];
	}

	public inline function getEvents(Name:Null<String>):Array<FlxEvent>
	{
		return events.filter(event -> event != null && event.tag == Name);
	}

	public function getEventsAtTimes(?StartTime:Null<Float>, ?EndTime:Null<Float>):Array<FlxEvent>
	{
		return if (StartTime == null && EndTime == null)
			events.copy();
		else
			events.filter(event -> event != null && (FlxMath.inBounds(event.startTime, StartTime, EndTime) || FlxMath.inBounds(event.endTime, StartTime, EndTime)));
	}

	public inline function forEachEvents(Job:FlxEvent->Void):Void
	{
		for (event in events)
			if (event != null)
				Job(event);
	}


	public inline function addChild(Name:Null<String> = null, MaxSize:Int = 0):FlxTimeline
	{
		return add(new FlxTimeline(MaxSize, Name));
	}

	public function getChild(Name:String):Null<FlxTimeline>
	{
		var count:Int = 0;
		while (count < length)
		{
			final child = members[count++];
			if (child != null && child.name == Name)
			{
				return child;
			}
		}
		return null;
	}

	public function getChildren(Name:String):Array<FlxTimeline>
	{
		var _children:Array<FlxTimeline> = [];
		var count:Int = 0;
		while (count < length)
		{
			final child = members[count++];
			if (child != null && child.name == Name)
			{
				_children.push(child);
			}
		}
		return _children;
	}


	public function removeChild(Name:String, ?Splice:Bool = false):Bool
	{
		var _children:Null<Array<FlxTimeline>> = getChildren(Name);
		if (_children.length != 0)
			for (i in _children)
				remove(i, Splice);
		return _children.length != 0;
	}


	public function sortChildrenByName(order = FlxSort.ASCENDING)
	{
		sort((Order:Int, A:FlxTimeline, B:FlxTimeline) -> {
			var A = A.name.toLowerCase();
			var B = B.name.toLowerCase();
			if (A < B)
				return Order;
			else if (A > B)
				return -Order;
			else
				return 0;
		}, order);
	}

	override function update(elapsed:Float)
	{
		if (parent == null)
			updateAnimation(elapsed);
		// super.update(elapsed);
	}

	function updateAnimation(elapsed:Float)
	{
		if (getTime != null)
		{
			var time = getTime();
			// if (parent == null)
			// 	time *= timescale;
			if (reversed)
				time = animLength - time;
			animTime = time;
		}
		else if (parent != null || playing && !finished)
		{
			if (reversed)
				elapsed = -elapsed; 
			if (parent == null)
				elapsed *= timescale;
			animTime += elapsed;
		}
	}

	static inline function mod(a:Float, b:Float):Float
	{
		return a - b * Math.ffloor(a / b);
	}
	public function updateTimeline(time:Float, forse:Bool = false)
	{
		if (!forse && FlxMath.equal(__curTime, time)) return;
		__curTime = time;
		if (looped)
		{
			if (__curTime < __prevTime)
			{
				if (__curTime < loopPoint)
				{
					__curTime = mod(__curTime, animLength - loopPoint) + loopPoint;
					// do {
					// 	__curTime += animLength - loopPoint;
					// } while(__curTime < loopPoint);
					__dispatchLoop = true;
				}
			}
			else
			{
				if (__curTime >= animLength)
				{
					__curTime = mod(__curTime, animLength);
					// do {
					// 	__curTime -= animLength - loopPoint;
					// } while(__curTime > animLength);
					__dispatchLoop = true;
				}
			}
		}
		else
		{
			if (!finished && (
				__curTime > __prevTime && __curTime >= animLength ||
				__curTime < __prevTime && __curTime <= 0
			))
			{
				finished = true;
				__dispatchFinish = true;
				__curTime = __curTime > __prevTime ? 0 : animLength;
			}
		}

		if (__dispatchLoop)
		{
			onLoop.dispatch(this);
			__dispatchLoop = false;
		}
		if (__dispatchFinish)
		{
			onFinish.dispatch(this);
			__dispatchFinish = false;
		}

		var frameAnimTime = formatTimeByFramerate(__curTime, framerate);
		var neededUpdate = Math.abs(frameAnimTime - __prevFrameTime) >= getFrameDuration();
		if (neededUpdate)
		{
			onFrameChange.dispatch(this, curFrame);
		}
		if (forse || neededUpdate)
		{
			_sortEvents();
			_updateEvents(frameAnimTime);
			__prevTime = __curTime;
			if (neededUpdate)
				__prevFrameTime = frameAnimTime;
			if (members.length != 0)
			{
				for (child in members)
				{
					if (child != null && child.exists && child.active)
					{
						child.updateTimeline(time, forse);
					}
				}
			}
		}
	}
	

	inline function _updateEvents(time:Float)
	{
		if (events.length != 0)
			events[0]._updateWithNextEvent(time);
	}

	function _sortEvents()
	{
		if (!_dirtyEventsSort) return;
		_dirtyEventsSort = false;
		events.sort(sortEventsMethod);
		var i:Int = 0;
		while (i < events.length) {
			events[i]._nextEvent = events[i+1];
			i++;
		}
	}

	override function onMemberAdd(member:FlxTimeline)
	{
		member.parent = this;
		super.onMemberAdd(member);
	}
	
	override function onMemberRemove(member:FlxTimeline)
	{
		if (member.parent == this)
			member.parent = null;
		super.onMemberRemove(member);
	}

	override function destroy()
	{
		super.destroy();
		FlxDestroyUtil.destroy(onFrameChange);
		FlxDestroyUtil.destroy(onFinish);
		FlxDestroyUtil.destroy(onLoop);
		events = FlxDestroyUtil.destroyArray(events);
		parent = null;
	}

	inline function sortEventsMethod(a:FlxEvent, b:FlxEvent)
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.startTime, b.startTime);
	}

	inline function getFrameDuration()
	{
		return 1 / framerate;
	}

	public inline function formatTimeByFramerate(time:Float, framerate:Float):Float
	{
		return Math.ffloor(time * framerate) / framerate;
	}

	inline function get_percent():Float
	{
		return FlxMath.remapToRange(animTime, 0, animLength, 0, 1);
	}
	inline function set_percent(i:Float):Float
	{
		animTime = animLength * i;
		return i;
	}

	inline function get_playing():Bool
	{
		return !paused;
	}
	inline function set_playing(i:Bool):Bool
	{
		return paused = !i;
	}

	inline function get_numFrames():Int
	{
		return Math.floor(animLength / getFrameDuration());
	}

	inline function get_curFrame():Int
	{
		return Math.floor(animTime / getFrameDuration());
	}
	inline function set_curFrame(i:Int):Int
	{
		animTime = i * getFrameDuration();
		return i;
	}

	inline function get_animTime():Float
	{
		return __curTime;
	}
	inline function set_animTime(i:Float):Float
	{
		updateTimeline(i, forseUpdate);
		return __curTime;
	}

	function set_animLength(i:Float):Float
	{
		if (i < 0)
			i = FlxMath.MAX_VALUE_FLOAT + i;
		return animLength = i;
	}

	function set_framerate(i:Float):Float
	{
		if (i < 0)
			i = 1 / FlxMath.EPSILON;
		return framerate = i;
	}
}
