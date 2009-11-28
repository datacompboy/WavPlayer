//
// AudioSink
// Generated sound player from FOGG project
// http://bazaar.launchpad.net/~arkadini/fogg/trunk/files
// Licensed under GPL
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
package org.xiph.system;

//import org.xiph.system.Bytes;

import flash.Vector;

import flash.media.Sound;
import flash.media.SoundChannel;
import flash.events.SampleDataEvent;


class AudioSink extends flash.events.EventDispatcher {
	var buffer : Bytes;
	public var available : Int;
	var triggered : Bool;
	var trigger : Int;
	var fill : Bool;
	var size : Int;

	var s : Sound;
	var sch : SoundChannel;

	public function new(chunk_size : Int, fill = true, trigger = 0) {
		super();
		size = chunk_size;
		this.fill = fill;
		this.trigger = trigger;
		if (this.trigger == -1)
			this.trigger = size;
		triggered = false;

		buffer = new Bytes();
		available = 0;
		s = new Sound();
		sch = null;
	}

	public function play() : Void {
		if (triggered) return;
		triggered = true;
		//trace("adding callback");
		s.addEventListener("sampleData", _data_cb);
		trace("playing");
		sch = s.play();
		//trace(sch);
		sch.addEventListener(flash.events.Event.SOUND_COMPLETE, soundCompleteHandler);
		dispatchEvent(new PlayerEvent(PlayerEvent.PLAYING));
	}

	public function soundCompleteHandler(e:flash.events.Event):Void {
		sch = null;
		dispatchEvent(new PlayerEvent(PlayerEvent.STOPPED));
	}

	public function stop() : Void {
		if (sch != null) {
			sch.stop();
			dispatchEvent(new PlayerEvent(PlayerEvent.STOPPED));
			sch = null;
		}
	}

	function _data_cb(event : SampleDataEvent) : Void {
		var i : Int;
		var to_write : Int = available > size ? size : available;
		var missing = to_write < size ? size - to_write : 0;
		var bytes : Int = to_write * 8;
		if (to_write > 0) {
			//trace("Write to sync bytes " + to_write);
			event.data.writeBytes(buffer, 0, bytes);
			available -= to_write;
			System.bytescopy(buffer, bytes, buffer, 0, available * 8);
		}
		i = 0;
		if (missing > 0 && missing != size && fill) {
			trace("samples data underrun: " + missing);
			while (i < missing) {
				untyped {
				event.data.writeFloat(0.0);
				event.data.writeFloat(0.0);
				};
				i++;
			}
		} else if (missing > 0) {
			trace("not enough data, stopping");
			//stop();
		}
	}

	public function write(pcm : Array<Array<Float>>, index : Array<Int>,
						  samples : Int) : Void {
		var i : Int;
		var end : Int;
		buffer.position = available * 8; // 2 ch * 4 bytes per sample (float)
		if (pcm.length == 1) {
			// one channel
			var c = pcm[0];
			var s : Float;
			i = index[0];
			end = i + samples;
			while (i < samples) {
				s = c[i++];
				buffer.writeFloat(s);
				buffer.writeFloat(s);
			}
		} else if (pcm.length == 2) {
			// two channels
			var c1 = pcm[0];
			var c2 = pcm[1];
			i = index[0];
			var i2 = index[1];
			end = i + samples;
			while (i < end) {
				buffer.writeFloat(c1[i]);
				buffer.writeFloat(c2[i2++]);
				i++;
			}
		} else {
			throw "-EWRONGNUMCHANNELS";
		}

		available += samples;
		if (!triggered && trigger > 0 && available > trigger) {
			play();
		}
	}
}
