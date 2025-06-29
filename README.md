# <p align="center"> FlxTimeline </p>
An attempt to implement a dynamic timeline in HaxeFlixel.
Features:
* Events:
    * **SetEvent** - calls the specified function
    * **NumTweenEvent** - works like [NumTween](https://api.haxeflixel.com/flixel/tweens/FlxTween.html#num), but is bound to the timeline
    * **VarTweenEvent** - works like [VarTween](https://api.haxeflixel.com/flixel/tweens/FlxTween.html#tween), but is bound to the timeline
* Ability to store child timelines
* Framerate support
---

## Example Of Use:
```haxe
import flixel.timeline.FlxTimeline;

// Creates a timeline
var timeline:FlxTimeline = new FlxTimeline();

var duration = 0.5;
var startTime = 0.1;
// Add VarTweenEvent
timeline.addTweenEvent(startTime, mySprite, {angle: 45}, duration);
// Add NumTweenEvent
timeline.addNumTweenEvent(startTime, 0, 1.0, i -> trace(i), duration);
// Add SetEvent
timeline.addSetEvent(startTime, i -> trace("HelloWorld"), duration);

// Starts animation
timeline.play();

// Ability to link time to your function.
timeline.getTime = () -> return FlxG.sound.music.time;

// Create a child timeline from the previous timeline
timeline.addChild("Child Timeline");
// You can also give your timeline a name to make it easier to navigate among other timelines.
var childTimeLine:FlxTimeline = timeline.getChild("Child Timeline");
timeline.removeChild("Child Timeline");
```

---

## Installation 

1. First, run the following command in a terminal:
   - For the latest stable version: `haxelib install flxtimeline`
   - For the latest development: `haxelib git flxtimeline https://github.com/Redar13/FlxTimeline`

2. Include the library in your Project.xml: `<haxelib name="flxtimeline" />`

---

## TODOS (For now only for TweenEvent):
1. Improve [TweenEvent](flixel/timeline/types/TweenEvent.hx) rewind
2. Implement [FlxTweenType](https://api.haxeflixel.com/flixel/tweens/FlxTweenType.html) for [TweenEvent](flixel/timeline/types/TweenEvent.hx)
3. Implement [Motion](https://api.haxeflixel.com/flixel/tweens/motion/Motion.html) and its child classes
