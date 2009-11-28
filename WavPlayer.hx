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

class WavPlayerGui extends flash.events.EventDispatcher {
	var length: Float;
	var ready: Float;
	var position: Float;
	public function drawStopped(): Void { throw("Try to instantiate interface"); }
	public function drawBuffering(): Void { throw("Try to instantiate interface"); }
	public function drawPlaying(): Void { throw("Try to instantiate interface"); }
	public function drawPaused(): Void { throw("Try to instantiate interface"); }
	public function setLength(length: Float) { this.length = length; }
	public function setReady(ready: Float)	 { this.ready = ready; }
	public function setPosition(pos: Float) { this.position = pos; }
	function Sizer(x:Float,y:Float,color=0xFF0000,alpha:Float=0) {
		var sprite = new flash.display.Sprite();
		Rect(sprite,x,y,color,alpha);
		return sprite;
	}
	function Rect(sprite,x:Float,y:Float,color,alpha:Float=100) {
		var g:flash.display.Graphics = sprite.graphics;
		g.clear();
		g.lineStyle(1, color, alpha);
		g.beginFill(color, alpha);
		g.moveTo(0, 0);
		g.lineTo(0, y-1);
		g.lineTo(x-1, y-1);
		g.lineTo(x-1, 0);
		g.endFill();
	}
}
class WavPlayerGuiEvent extends flash.events.Event {
   static public inline var CLICKED : String = "PLAYERGUI_CLICKED";
   public function new(type : String, ?bubbles : Bool, ?cancelable : Bool) {
	   super(type, bubbles, cancelable);
   }
}

class WavPlayerGui_Mini extends WavPlayerGui {
	var sprite: flash.display.Sprite;
	public inline function new(root, myMenu, zoom:Float=1, x:Float=0, y:Float=0) {
		super();
		sprite = new flash.display.MovieClip();
		sprite.contextMenu = myMenu;
		sprite.addEventListener(flash.events.MouseEvent.CLICK, handleClicked);
		sprite.useHandCursor = true;
		sprite.buttonMode = true;
		sprite.scaleX = zoom;
		sprite.scaleY = zoom;
		sprite.scaleZ = 1;
		sprite.x = x;
		sprite.y = y;
		sprite.addChild(Sizer(40,40));
		root.addChild(sprite);
	}
	public override function drawStopped() {
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
	public override function drawBuffering() {
		var g:flash.display.Graphics = sprite.graphics;
		g.clear();
		g.lineStyle(4, 0x808080, 1, false, flash.display.LineScaleMode.NORMAL,
					flash.display.CapsStyle.ROUND, flash.display.JointStyle.ROUND);
		g.drawCircle(20, 20, 10);
	}
	public override function drawPlaying() {
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
	public override function drawPaused() {
		var g:flash.display.Graphics = sprite.graphics;
		g.clear();
		g.lineStyle(8, 0x808080, 1, false, flash.display.LineScaleMode.NORMAL,
					flash.display.CapsStyle.ROUND, flash.display.JointStyle.ROUND);
		g.moveTo(12, 8);
		g.lineTo(12, 32);
		g.moveTo(28, 8);
		g.lineTo(28, 32);
	}
	function handleClicked(event:flash.events.Event) {
		dispatchEvent(new WavPlayerGuiEvent(WavPlayerGuiEvent.CLICKED));
	}
}
class WavPlayerGui_Full extends WavPlayerGui {
	var GuiMini: WavPlayerGui;
	var sprite: flash.display.Sprite;
	var rectFile: flash.display.Sprite;
	var rectReady: flash.display.Sprite;
	var rectMark: flash.display.Sprite;
	var width: Float;
	var timer: flash.utils.Timer;
	var lastTime: Float;
	public inline function new(root : flash.display.Sprite, myMenu, zoom:Float=1, size:Float=10) {
		super();
		sprite = new flash.display.MovieClip();
		sprite.contextMenu = myMenu;
		sprite.scaleX = zoom;
		sprite.scaleY = zoom;
		sprite.scaleZ = 1;
		sprite.addEventListener(flash.events.MouseEvent.CLICK, handleClicked);
		sprite.useHandCursor = true;
		sprite.buttonMode = true;
		sprite.x = 40*zoom;
		sprite.y = 0;
		sprite.addChild(Sizer(40.0*size,40.0));
		GuiMini = new WavPlayerGui_Mini(sprite, myMenu, 1, -40);
		GuiMini.addEventListener(WavPlayerGuiEvent.CLICKED, proxyClicked);

		rectFile = new flash.display.MovieClip();
		rectFile.scaleX = 1;
		rectFile.scaleY = 1;
		rectFile.scaleZ = 1;
		rectFile.addChild(Sizer(40.0*size+3,26.0,0x303030,1));
		sprite.addChild(rectFile);
		rectFile.x = -2;
		rectFile.y = 7;

		rectReady = new flash.display.MovieClip();
		rectReady.scaleX = 1;
		rectReady.scaleY = 1;
		rectReady.scaleZ = 1;
		rectReady.addChild(Sizer(40.0*size,10.0,0xA0A0A0,1));
		sprite.addChild(rectReady);
		rectReady.x = 0;
		rectReady.y = 15;
		rectReady.scaleX = 0.0;

		rectMark = new flash.display.MovieClip();
		rectMark.scaleX = 1;
		rectMark.scaleY = 1;
		rectMark.scaleZ = 1;
		rectMark.addChild(Sizer(5.0,40.0,0x7FA03F,1));
		sprite.addChild(rectMark);
		width = 40.0*size;
		rectMark.x = width*0.0-3;
		rectMark.y = 0;
		rectMark.scaleX = 0.7;

		root.addChild(sprite);
		timer = new flash.utils.Timer(100);
		timer.addEventListener( flash.events.TimerEvent.TIMER, delay );
		timer.stop();
	}
	public override function setReady(ready: Float) {
		super.setReady(ready);
		if (length > 0) rectReady.scaleX = ready / length;
	}
	public override function setPosition(pos: Float) { 
		super.setPosition(pos);
		if (length > 0) rectMark.x = width*(position/length)-3;
	}
	public override function drawStopped() {
		GuiMini.drawStopped();
		timer.stop();
	}
	public override function drawBuffering() {
		GuiMini.drawBuffering();
		timer.stop();
	}
	public override function drawPlaying() {
		GuiMini.drawPlaying();
		lastTime = haxe.Timer.stamp();
		timer.reset();
		timer.start();
	}
	public override function drawPaused() {
		GuiMini.drawPaused();
		timer.stop();
	}
	function delay(evt : flash.events.TimerEvent) {
		var ts = haxe.Timer.stamp();
		setPosition(position + (ts-lastTime));
		lastTime = ts;
	}
	function proxyClicked(event:flash.events.Event) {
		dispatchEvent(event);
	}
	function handleClicked(event:flash.events.Event) {
		trace("Clicked event: "+event);
		//dispatchEvent(new WavPlayerGuiEvent(WavPlayerGuiEvent.CLICKED));
	}
}

// Main user interface: play / stop buttons & ExternalInterface
class WavPlayer {
	static var Version = 1.5;
	static var player : Player;
	static var state : String = PlayerEvent.STOPPED;
	static var handlers : List<JsEventHandler>;
	static var handlerId : Int;
	static var lastNotifyProgress : Float;
	static var lastNotifyLoad : Float;
	static var iface : WavPlayerGui;
	static function main() {
		trace("WavPlayer "+Version+" - startup");
		var myMenu = new flash.ui.ContextMenu();
		var ciVer = new flash.ui.ContextMenuItem("WavPlayer "+Version);
		var ciCop = new flash.ui.ContextMenuItem("Licensed under GPL");
		myMenu.customItems.push(ciVer);
		myMenu.customItems.push(ciCop);

		var fvs : Dynamic<String> = flash.Lib.current.loaderInfo.parameters;
		handlers = new List<JsEventHandler>();
		handlerId = 0;

		lastNotifyProgress = 0;
		lastNotifyLoad = 0;

		var zoom:Float = Std.parseInt(fvs.h); zoom = (zoom>0?zoom:40.0) / 40.0;
		trace("zoom="+zoom);
		if (fvs.gui == "full") {
			var width:Float = Std.parseInt(fvs.w); width = (width>0?width:40.0) / zoom / 40.0;
			trace("width="+width);
			iface = new WavPlayerGui_Full(flash.Lib.current, myMenu, zoom, width-1);
		} else {
			iface = new WavPlayerGui_Mini(flash.Lib.current, myMenu, zoom);
		}
		iface.addEventListener(WavPlayerGuiEvent.CLICKED, handleClicked);
		trace("WavPlayer - gui started " + WavPlayerGui_Full);

		iface.drawStopped(); //iface.drawPaused(); //iface.drawPlaying(); //iface.drawBuffering();

		player = new Player(fvs.sound);
		player.addEventListener(PlayerEvent.BUFFERING, handleBuffering);
		player.addEventListener(PlayerEvent.PLAYING, handlePlaying);
		player.addEventListener(PlayerEvent.STOPPED, handleStopped);
		player.addEventListener(PlayerEvent.PAUSED, handlePaused);
		player.addEventListener(flash.events.ProgressEvent.PROGRESS, handleProgress);
		player.addEventListener(PlayerLoadEvent.LOAD, handleLoad);

		if( !flash.external.ExternalInterface.available )
			throw "External Interface not available";
		try flash.external.ExternalInterface.addCallback("getVersion",doGetVer) catch( e : Dynamic ) {};
		try flash.external.ExternalInterface.addCallback("doPlay",doPlay) catch( e : Dynamic ) {};
		try flash.external.ExternalInterface.addCallback("doStop",doStop) catch( e : Dynamic ) {};
		try flash.external.ExternalInterface.addCallback("attachHandler",doAttach) catch ( e : Dynamic ) {};
		try flash.external.ExternalInterface.addCallback("detachHandler",doDetach) catch ( e : Dynamic ) {};
		try flash.external.ExternalInterface.addCallback("removeHandler",doRemove) catch ( e : Dynamic ) {};
	}
	static function handleClicked(event:flash.events.Event) {
		trace("Clicked event: "+event);
		switch( state ) {
		  case PlayerEvent.STOPPED:   iface.setPosition(0); player.play();
		  case PlayerEvent.BUFFERING: player.stop();
		  case PlayerEvent.PLAYING:   player.stop();
		  case PlayerEvent.PAUSED:	  player.play();
		}
	}
	static function handleBuffering(event:flash.events.Event) {
		trace("Buffering event: "+event);
		state = event.type;
		iface.drawBuffering();
		fireJsEvent(event.type);
	}
	static function handlePlaying(event:flash.events.Event) {
		trace("Playing event: "+event);
		state = event.type;
		iface.drawPlaying();
		fireJsEvent(event.type);
	}
	static function handleStopped(event:flash.events.Event) {
		trace("Stopped event: "+event);
		state = event.type;
		iface.drawStopped();
		fireJsEvent(event.type);
	}
	static function handlePaused(event:flash.events.Event) {
		trace("Paused event: "+event);
		state = event.type;
		iface.drawPaused();
		fireJsEvent(event.type);
	}
	static function handleLoad(event:PlayerLoadEvent) {
		trace("Load event: "+event);
		var now = Date.now().getTime();
		iface.setLength(event.SecondsTotal);
		iface.setReady(event.SecondsLoaded);
		if (lastNotifyLoad==0 || event.SecondsTotal-event.SecondsLoaded < 1e-4 || now - lastNotifyLoad > 500) {
			lastNotifyLoad = now;
			fireJsEvent(event.type, event.SecondsLoaded, event.SecondsTotal);
		}
	}
	static function handleProgress(event:flash.events.ProgressEvent) {
		trace("Progress event: "+event);
		var now = Date.now().getTime();
		if (lastNotifyProgress==0 || event.bytesLoaded == event.bytesTotal || now - lastNotifyProgress > 500) {
			lastNotifyProgress = now;
			fireJsEvent(event.type, event.bytesLoaded, event.bytesTotal);
		}
	}

	static function doGetVer( ) {
		return Version;
	}
	static function doPlay( ?fname: String ) {
		player.stop();
		lastNotifyProgress = 0;
		lastNotifyLoad = 0;
		iface.setPosition(0); 
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
}
