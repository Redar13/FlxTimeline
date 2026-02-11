package flixel.timeline.internal;

class Tools
{
	public static inline function clamp(value:Float, min:Float, max:Float):Float
	{
		return value < min ? min : value > max ? max : value;
	}

	public static inline function inBounds(value:Float, min:Float, max:Float):Bool
	{
		return value >= min && value <= max;
	}

	public static function mod(a:Float, b:Float):Float
	{
		if (b < 0)
			b = -b;
		return a - b * Math.ffloor(a / b);
	}
}