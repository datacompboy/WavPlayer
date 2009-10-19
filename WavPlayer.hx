//
// WAV/AU Flash player with resampler
// 
// Copyright (c) 2009, Anton Fedorov <datacompboy@call2ru.com>
//
/* This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 */

class JsEventHandler {
	public var Id: Int;
	public var Event: String;
	public var Handler: String;
	public var User: Null<String>;
	public inline function new(id:Int, event:String, handler:String, ?user:String) {
		Id = id;
		Event = event;
		Handler = handler;
		User = user;
	}
}

// Main user interface: play / stop buttons & ExternalInterface
class WavPlayer {
	static var player : Player;
	static var sprite;
	static var state : String = PlayerEvent.STOPPED;
	static var handlers : List<JsEventHandler>;
	static var handlerId : Int;
	static function main() {
		trace("WavPlayer - startup");
        var fvs : Dynamic<String> = flash.Lib.current.loaderInfo.parameters;
		handlers = new List<JsEventHandler>();
		handlerId = 0;

		sprite = new flash.display.MovieClip(); // flash.display.Sprite();
		sprite.width = 20;
		sprite.height = 20;
		sprite.addEventListener(flash.events.MouseEvent.CLICK, handleClicked);
		sprite.useHandCursor = true;
		sprite.buttonMode = true;
		sprite.x = 0;
		sprite.y = 0;
		sprite.z = 10;
		sprite.scaleX = 1;
		sprite.scaleY = 1;
		sprite.scaleZ = 1;
		var mc:flash.display.MovieClip = flash.Lib.current;
		mc.addChild(sprite);

		drawStopped(); //drawPaused(); //drawPlaying(); //drawBuffering();

		player = new Player(fvs.sound);
		player.addEventListener(PlayerEvent.BUFFERING, handleBuffering);
		player.addEventListener(PlayerEvent.PLAYING, handlePlaying);
		player.addEventListener(PlayerEvent.STOPPED, handleStopped);
		player.addEventListener(PlayerEvent.PAUSED, handlePaused);
		player.addEventListener(flash.events.ProgressEvent.PROGRESS, handleProgress);
		player.addEventListener(PlayerLoadEvent.LOAD, handleLoad);

		if( !flash.external.ExternalInterface.available )
			throw "External Interface not available";
		try flash.external.ExternalInterface.addCallback("doPlay",doPlay) catch( e : Dynamic ) {};
		try flash.external.ExternalInterface.addCallback("doStop",doStop) catch( e : Dynamic ) {};
		try flash.external.ExternalInterface.addCallback("attachHandler",doAttach) catch ( e : Dynamic ) {};
		try flash.external.ExternalInterface.addCallback("detachHandler",doDetach) catch ( e : Dynamic ) {};
		try flash.external.ExternalInterface.addCallback("removeHandler",doRemove) catch ( e : Dynamic ) {};

		//player.play("test-vf-44100.au");
		//var Player = new Player("test-vf.au");
		//var Player = new Player("test-vf-stereo.au");
		//var Player = new Player("9691.wav");
		//var Player = new Player("9691-16000.wav");
		//var Player = new Player("9691-8bit.wav");
		//var Player = new Player("9691-stereo.wav");
		//var Player = new Player("9691-uLaw.wav");
		//var Player = new Player("9691-24bit.wav");
		//var Player = new Player("9691-24bit-stereo.wav");
	}
	static function handleClicked(event:flash.events.Event) {
		trace("Clicked event: "+event);
		switch( state ) {
		  case PlayerEvent.STOPPED:   player.play();
		  case PlayerEvent.BUFFERING: player.stop();
		  case PlayerEvent.PLAYING:   player.stop();
		  case PlayerEvent.PAUSED:	  player.play();
		}
	}
	static function handleBuffering(event:flash.events.Event) {
		trace("Buffering event: "+event);
		state = event.type;
		fireJsEvent(event.type);
		drawBuffering();
	}
	static function handlePlaying(event:flash.events.Event) {
		trace("Playing event: "+event);
		state = event.type;
		fireJsEvent(event.type);
		drawPlaying();
	}
	static function handleStopped(event:flash.events.Event) {
		trace("Stopped event: "+event);
		state = event.type;
		fireJsEvent(event.type);
		drawStopped();
	}
	static function handlePaused(event:flash.events.Event) {
		trace("Paused event: "+event);
		state = event.type;
		fireJsEvent(event.type);
		drawPaused();
	}
	static function handleLoad(event:PlayerLoadEvent) {
		trace("Load event: "+event);
		fireJsEvent(event.type, event.SecondsLoaded, event.SecondsTotal);
	}
	static function handleProgress(event:flash.events.ProgressEvent) {
		trace("Progress event: "+event);
		fireJsEvent(event.type, event.bytesLoaded, event.bytesTotal);
	}

	static function doPlay( ?fname: String ) {
		player.play(fname);
	}
	static function doStop( ) {
		player.stop();
	}
    static function doAttach( event: String, handler: String, ?user: String ) {
		var id = handlerId++;
		handlers.push(new JsEventHandler(id, event, handler, user));
		return id;
    }
	static function doDetach( event: String, handler: String, ?user: String ) {
		handlers = handlers.filter(function(h: JsEventHandler): Bool {
			return !(h.Event==event && h.Handler == handler && h.User==user);
		});
	}
	static function doRemove( handler: Int ) {
		handlers = handlers.filter(function(h: JsEventHandler): Bool {
			return h.Id != handler;
		});
	}
	static function fireJsEvent( event: String, ?p1: Dynamic, ?p2: Dynamic) {
		for (h in handlers) {
			if (h.Event == event) {
				if (h.User != null) flash.external.ExternalInterface.call(h.Handler, h.User, p1, p2);
				else flash.external.ExternalInterface.call(h.Handler, p1, p2);
			} else 
			if (h.Event == '*') {
				if (h.User != null) flash.external.ExternalInterface.call(h.Handler, event, h.User, p1, p2);
				else flash.external.ExternalInterface.call(h.Handler, event, p1, p2);
			}
		}
	}

	static function drawStopped() {
		var g:flash.display.Graphics = sprite.graphics;
		g.clear();
		g.lineStyle(4, 0x808080, 1, false, flash.display.LineScaleMode.NORMAL,
					flash.display.CapsStyle.ROUND, flash.display.JointStyle.ROUND);
		g.beginFill(0x808080);
		g.moveTo(8, 6);
		g.lineTo(30, 20);
		g.lineTo(8, 34);
		g.lineTo(8, 6);
		g.endFill();
	}
	static function drawBuffering() {
		var g:flash.display.Graphics = sprite.graphics;
		g.clear();
		g.lineStyle(4, 0x808080, 1, false, flash.display.LineScaleMode.NORMAL,
					flash.display.CapsStyle.ROUND, flash.display.JointStyle.ROUND);
		g.drawCircle(20, 20, 10);
	}
	static function drawPlaying() {
		var g:flash.display.Graphics = sprite.graphics;
		g.clear();
		g.lineStyle(6, 0x808080, 1, false, flash.display.LineScaleMode.NORMAL,
					flash.display.CapsStyle.ROUND, flash.display.JointStyle.ROUND);
		g.beginFill(0x808080);
		g.moveTo(8, 8);
		g.lineTo(32, 8);
		g.lineTo(32, 32);
		g.lineTo(8, 32);
		g.lineTo(8, 8);
		g.endFill();
	}
	static function drawPaused() {
		var g:flash.display.Graphics = sprite.graphics;
		g.clear();
		g.lineStyle(8, 0x808080, 1, false, flash.display.LineScaleMode.NORMAL,
					flash.display.CapsStyle.ROUND, flash.display.JointStyle.ROUND);
		g.moveTo(12, 8);
		g.lineTo(12, 32);
		g.moveTo(28, 8);
		g.lineTo(28, 32);
	}
}
