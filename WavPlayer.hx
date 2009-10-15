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

// Main user interface: play / stop buttons & ExternalInterface
class WavPlayer {
	static var player : Player;
	static var sprite;
	static var state : String = PlayerEvent.STOPPED;
	static function main() {
		trace("WavPlayer - startup");
        var fvs : Dynamic<String> = flash.Lib.current.loaderInfo.parameters;

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

		if( !flash.external.ExternalInterface.available )
			throw "External Interface not available";
		try flash.external.ExternalInterface.addCallback("doPlay",doPlay) catch( e : Dynamic ) {};
		try flash.external.ExternalInterface.addCallback("doStop",doStop) catch( e : Dynamic ) {};

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
		drawBuffering();
	}
	static function handlePlaying(event:flash.events.Event) {
		trace("Playing event: "+event);
		state = event.type;
		drawPlaying();
	}
	static function handleStopped(event:flash.events.Event) {
		trace("Stopped event: "+event);
		state = event.type;
		drawStopped();
	}
	static function handlePaused(event:flash.events.Event) {
		trace("Paused event: "+event);
		state = event.type;
		drawPaused();
	}

	static function doPlay( ?fname: String ) {
		player.play(fname);
	}
	static function doStop( ) {
		player.stop();
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
