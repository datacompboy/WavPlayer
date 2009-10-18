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

// Main player class: loads stream, process it by appropriate file decoder,
// that will initialize correct sound decoder. Decoded audio samples 
// resample to 44100 and play via AudioSink
class Player extends flash.events.EventDispatcher {
	var File : flash.net.URLStream;
	var Sound : fmt.File;
	var Resampler : com.sun.media.sound.SoftAbstractResampler;
	var pitch : Array<Float>;
	var asink : org.xiph.system.AudioSink;
	var buffer : Array<Array<Float>>;
	var padding : Array<Float>;
	var in_off : Array<Float>;
	var fname : String;

	public function new(?path : String) {
		super();
		fname = path;
	}

	public function play(?path : String) {
		if (path != null) fname = path;
		if (fname == null) throw "No sound URL given";
		// To-do: re-play already loaded stream
		pitch = new Array<Float>();
		trace("Player for "+fname);
		if ((~/[.]au$/i).match(fname)) {
			Sound = new fmt.FileAu();
		} else
		if ((~/[.]wav$/i).match(fname)) {
			Sound = new fmt.FileWav();
		} else
		if ((~/[.]gsm$/i).match(fname)) {
			Sound = new fmt.FileGsm();
		} else {
			trace("Unsupported file type");
			throw "Unsupported file type";
		}
		Resampler = new com.sun.media.sound.SoftLanczosResampler();
		try {
			asink = new org.xiph.system.AudioSink(8192, true, 132300);
			asink.addEventListener(PlayerEvent.PLAYING, playingEvent);
			asink.addEventListener(PlayerEvent.STOPPED, stoppedEvent);
		} catch (error : Dynamic) {
			trace("Unable to load: "+error);
			trace(haxe.Stack.exceptionStack());
			throw error;
		}
		try {
			File = new flash.net.URLStream();
			var Req = new flash.net.URLRequest(fname);
			File.addEventListener(flash.events.Event.COMPLETE, completeHandler);
			File.addEventListener(flash.events.ProgressEvent.PROGRESS, progressHandler);
			trace("Load begin!");
			File.load(Req);
			dispatchEvent(new PlayerEvent(PlayerEvent.BUFFERING));
		}
		catch (error : Dynamic) {
			trace("Unable to load: "+error);
			throw error;
		}
	}

	public function playingEvent(event:flash.events.Event) {
		dispatchEvent(event);
	}
	public function stoppedEvent(event:flash.events.Event) {
		dispatchEvent(event);
	}

	public function stop() {
		asink.stop();
	}

	function completeHandler(event:flash.events.Event) {
		trace("completeHandler: " + event);
		read(true);
		dispatchEvent(event);
	}
	function progressHandler(event:flash.events.Event) {
		trace("progressHandler: " + event);
		read(false);
		dispatchEvent(event);
	}
	function read(last: Bool) {
		Sound.push( File, last );
		trace("Sound ready = "+Sound.ready()+"; rate="+Sound.getRate()+"; channels="+Sound.getChannels()+"; samples="+Sound.samplesAvailable());
		if (Sound.samplesAvailable()>0) {
			if (Sound.getRate() == 44100) {
				var Samples = Sound.getSamples();
				var ind = new Array<Int>(); ind[0] = 0;
				var cnt = Samples[0].length;
				asink.write(Samples, ind, cnt);
			} else {
				var Samples = Sound.getSamples();
				if (pitch.length != 1) {
					pitch[0] = Sound.getRate() / 44100.0;
					trace("Resample with "+pitch[0]+" pitch");
					buffer = new Array<Array<Float>>();
					padding = new Array<Float>();
					for( k in 0...Resampler.getPadding() )
						padding.push( 0.0 ); // Fill startup padding
					for( c in 0...Sound.getChannels() ) {
						// Fill with double padding
						buffer.push( padding.copy() );
						buffer[c] = buffer[c].concat( padding );
					}
					in_off = new Array<Float>();
					in_off[0] = Resampler.getPadding();
				}
				var Res = new Array<Array<Float>>();
				var out_off = new Array<Int>();
				var inOff = in_off[0];
				// Conversion needs padding samples before and padding samples after
				// So, for last pack we need to add one more padding zone
				for( c in 0...Sound.getChannels() ) {
					buffer[c] = buffer[c].concat( Samples[c] );
					if (last)
						buffer[c] = buffer[c].concat( padding );
					Res.push( new Array<Float>() );
					in_off[0] = inOff;
					out_off[0] = 0;
					// Note: number of last element, not count!
					// Always hold 1 padding left and 1 padding right
					var in_end: Float = buffer[c].length-padding.length;
					var out_end: Int = (Std.int( buffer[0].length / pitch[0] + 1 )+Resampler.getPadding())*2;
					Resampler.interpolate(buffer[c], in_off, in_end, pitch, 0, Res[c], out_off, out_end);
					trace("Interpolate in_off="+in_off[0]+"; out_off="+out_off[0]+"; out_end="+out_end);
				}

				// Write resampled sound
				var ind = new Array<Int>(); ind[0] = 0;
				asink.write(Res, ind, out_off[0]);

				// Shift buffers
				for( c in 0...Sound.getChannels() ) {
					buffer[c].splice(0, Std.int( in_off[0] )-2*padding.length );
				}
				in_off[0] -= Std.int( in_off[0]-2*padding.length );
			}
		}
		if (last) asink.play();
	}
}
