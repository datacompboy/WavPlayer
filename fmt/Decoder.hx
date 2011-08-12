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

package fmt;

// Generic sound-decoder interface.
interface Decoder {
	// Bytes size of one input chunk
	var sampleSize : Int;
	// Number of PCM samples in one input chunk
	var sampleLength : Int;
	// Decode one input chunk to PCM samples
	function decode( InBuf : haxe.io.BytesData, InOff: Int, Chan: Int, OutBuf : Array<Float>, OutOff: Int ) : Int;
}
