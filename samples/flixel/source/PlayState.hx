import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;
import flixel.timeline.FlxTimeline;
import flixel.timeline.types.TweenEvent;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.util.FlxColor;

class PlayState extends FlxState {
	var timeline:FlxTimeline;
	var bgTimeline:FlxTimeline;
	var loopedTimeline:FlxTimeline;
	var topBarTimeline:FlxTimeline;
	var bottomBarTimeline:FlxTimeline;

	var statText:FlxText;

	inline function getTimeByFrame(frame:Int)
	{
		return frame / 24;
	}

	override function create()
	{
		add(timeline = new FlxTimeline());
		bgTimeline = timeline.addChild("bg");
		loopedTimeline = timeline.addChild("loopedThing");
		topBarTimeline = timeline.addChild("topBar");
		bottomBarTimeline = timeline.addChild("bottomBar");

		var bgSpr = new FlxSprite(-360, 360).loadGraphic(null); // load HaxeFlixel logo
		add(bgSpr);
		bgSpr.scale.set(5, 5);
		bgSpr.screenCenter();

		var topBar = new FlxSprite(-360, 0).makeGraphic(2000, 360);
		add(topBar);

		var bottomBar = new FlxSprite(-360, 360).makeGraphic(2000, 360);
		add(bottomBar);

		// timeline.framerate = 12;
		timeline.animLength = getTimeByFrame(180);
		timeline.looped = true;

		loopedTimeline.framerate = 12;
		loopedTimeline.animLength = timeline.animLength / 4;
		loopedTimeline.looped = true;

		loopedTimeline.addNumTweenEvent(0.0, bgSpr.y, bgSpr.y + 50, loopedTimeline.animLength / 2, i -> bgSpr.y = i, {ease:FlxEase.quadInOut}, "looped");
		loopedTimeline.addNumTweenEvent(loopedTimeline.animLength / 2, bgSpr.y + 50, bgSpr.y, loopedTimeline.animLength / 2, i -> bgSpr.y = i, {ease:FlxEase.quadInOut}, "looped");

		bgTimeline.addNumTweenEvent(0.0, 0.5, 1.0, getTimeByFrame(40), @:privateAccess camera.set_alpha, {ease: FlxEase.cubeOut});
		bgTimeline.addNumTweenEvent(timeline.animLength - getTimeByFrame(40), 1.0, 0.5, getTimeByFrame(40), @:privateAccess camera.set_alpha, {ease: FlxEase.cubeOut});

		bgTimeline.addSetEvent(0, i -> {
			camera.bgColor = i.repeatTime % 2 == 0 ? FlxColor.BLACK : FlxColor.BLUE;
		}, timeline.animLength / 3.5, 5);
		bgTimeline.addSetEvent(timeline.animLength / 2, _ -> {
			camera.bgColor = FlxColor.BLUE;
		});
		bgTimeline.addSetEvent(getTimeByFrame(114), _ -> {
			camera.bgColor = FlxColor.RED;
		});

		topBarTimeline.addTweenEvent(0.0,					topBar,		{y: -280, angle: 0},			getTimeByFrame(20),	{ease: FlxEase.cubeOut});
		bottomBarTimeline.addTweenEvent(0.0,				bottomBar,	{y: 640, angle: 0},				getTimeByFrame(20),	{ease: FlxEase.cubeOut});
		topBarTimeline.addTweenEvent(getTimeByFrame(40),	topBar,		{y: -280 + 60, angle: 10.0},	getTimeByFrame(20),	{ease: FlxEase.quadInOut});
		bottomBarTimeline.addTweenEvent(getTimeByFrame(40),	bottomBar,	{y: 640 - 60, angle: 10.0},		getTimeByFrame(20),	{ease: FlxEase.quadInOut});
		topBarTimeline.addTweenEvent(getTimeByFrame(80),	topBar,		{y: -280 + 120, angle: -10.0},	getTimeByFrame(20),	{ease: FlxEase.quadInOut});
		bottomBarTimeline.addTweenEvent(getTimeByFrame(80),	bottomBar,	{y: 640 - 120, angle: -10.0},	getTimeByFrame(20),	{ease: FlxEase.quadInOut});
		topBarTimeline.addTweenEvent(getTimeByFrame(114),	topBar,		{y: -280, angle: 0}, 			getTimeByFrame(10),	{ease: FlxEase.quadOut});
		bottomBarTimeline.addTweenEvent(getTimeByFrame(114),bottomBar,  {y: 640, angle: 0},				getTimeByFrame(10),	{ease: FlxEase.quadOut});
		topBarTimeline.addTweenEvent(getTimeByFrame(124),	topBar,		{y: 0, angle: 0},				getTimeByFrame(30),	{ease: FlxEase.bounceOut});
		bottomBarTimeline.addTweenEvent(getTimeByFrame(124),bottomBar,  {y: 360, angle: 0},				getTimeByFrame(30),	{ease: FlxEase.bounceOut});

		timeline.play();
		// timeline.getTime = () -> FlxG.mouse.x / FlxG.width * timeline.animLength;

		add(statText = new FlxText(20, 30));
		statText.setFormat(null, 14, FlxColor.BLACK);
	}

	public override function update(elapsed:Float)
	{
		var mult = 1.5;
		if (FlxG.keys.pressed.SHIFT)
			mult *= 3.0;
		if (FlxG.keys.anyPressed([A, LEFT]))
		{
			timeline.pause();
			timeline.animTime -= elapsed * mult;
		}
		if (FlxG.keys.anyPressed([D, RIGHT]))
		{
			timeline.pause();
			timeline.animTime += elapsed * mult;
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			timeline.paused = !timeline.paused;
		}

		if (FlxG.keys.justPressed.R)
		{
			timeline.reversed = !timeline.reversed;
		}

		var justPressed = FlxG.keys.firstJustPressed();
		if (FlxMath.inBounds(justPressed, FlxKey.ONE, FlxKey.NINE))
		{
			timeline.pause();
			timeline.percent = FlxMath.remapToRange(justPressed, FlxKey.ONE, FlxKey.NINE, 0, 1);
		}

		super.update(elapsed);

		statText.text = '${FlxMath.roundDecimal(timeline.animTime, 2)} / ${timeline.animLength} SEC';
		statText.screenCenter(X);
	}
}