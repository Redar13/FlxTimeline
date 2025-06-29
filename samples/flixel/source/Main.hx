import flixel.FlxGame;
import openfl.Lib;
import openfl.display.FPS;

class Main
{
	public static function main()
	{
		var stage = Lib.current.stage;

	    // var framerate:Int = 360;
	    // var framerate:Int = 240;
	    // var framerate:Int = 144;
	    var framerate:Int = 60;
		#if html5
		framerate = 60;
		#end
		var game = new FlxGame(1280, 720, PlayState, framerate, framerate, true, false);
		stage.addChild(game);
		game.addChild(new FPS());
	}
}