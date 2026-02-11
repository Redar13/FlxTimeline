package flixel.timeline.types;

import flixel.timeline.FlxEvent;
import flixel.timeline.FlxTimeline;
import flixel.timeline.types.TweenEvent;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxArrayUtil;

@:nullSafety
class VarTweenEvent extends TweenEvent // todo: improve time rewind
{
	var _object:Null<Dynamic>;
	var _properties:Dynamic;
	var _propertyInfos:Array<TweenProperty> = [];

	public function new(timeline:FlxTimeline, startTime:Float, object:Null<Dynamic>, properties:Null<Dynamic>, duration:Float, options:Null<TweenEventOptions>, tag:Null<String>)
	{
		super(timeline, startTime, duration, options, tag);
		this._object = object;
		this._properties = properties;
	}

	inline function _resetVars()
	{
		_initializeVars();
		_setStartValues();
	}

	@:nullSafety(Off)
	function _initializeVars():Void
	{
		_propertyInfos.resize(0);
		if (Reflect.isObject(_properties))
		{
			for (fieldPath in Reflect.fields(_properties))
			{
				var target = _object;
				var path = fieldPath.split(".");
				var field:String = path.pop();
				for (component in path)
				{
					target = Reflect.getProperty(target, component);
					if (!Reflect.isObject(target))
					{
						target = null;
						FlxG.log.warn('The object does not have the property "$component" in "$fieldPath"');
						break;
					}
				}
				if (target == null)
					continue;

				#if !js
				var setter:Null<Float->Float> = Reflect.field(target, 'set_$field');
				#end
				_propertyInfos.push({
					object: target,
					field: field,
					#if js
					setter: Reflect.setProperty.bind(target, field, _),
					#else
					setter: (setter == null ? Reflect.setField.bind(target, field, _) : setter),
					#end
					startValue: Reflect.getProperty(target, field),
					range: Reflect.getProperty(_properties, fieldPath)
				});
			}
		}
		else
			FlxG.log.warn("Unsupported properties container - use an object containing key/value pairs.");
	}

	override function _start(setupValues:Bool = true)
	{
		if (setupValues && _object != null && _properties != null)
			_resetVars();
        super._start(setupValues);
	}

	override function _update()
	{
		if (_propertyInfos.length != 0)
			for (info in _propertyInfos)
				// Reflect.setProperty(info.object, info.field, info.startValue + info.range * scale);
				info.setter(info.startValue + info.range * scale);
        super._update();
	}

	function _setStartValues()
	{
		for (info in _propertyInfos)
		{
			var value:Dynamic = Reflect.getProperty(info.object, info.field);
			if (value == null)
			{
				FlxG.log.warn('The object does not have the property "${info.field}"');
				continue;
			}
			if (Math.isNaN(value))
			{
				FlxG.log.warn('The property "${info.field}" is not numeric.');
				continue;
			}

			info.startValue = value;
			info.range = info.range - value;
		}
	}

	@:nullSafety(Off)
	override function destroy():Void
	{
		super.destroy();
		FlxArrayUtil.clearArray(_propertyInfos);
		_propertyInfos = null;
		_object = null;
		_properties = null;
	}
}

@:structInit
class TweenProperty
{
	public var object:Dynamic;
	public var field:String;
	public var setter:Float->Void;
	public var startValue:Float;
	public var range:Float;
}
