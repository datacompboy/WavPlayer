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

// Generic file stream scanner interface
interface File {
	var last: Bool;
	// Push data from audio stream to decoder
	function push(bytes: flash.utils.IDataInput, last:Bool): Void;
	// Require decoder to populate at least <samples> samples from audio stream
	function populate(samples: Int): Void;
	// Returns is stream ready to operate: header readed (1), not ready (0), error(-1)
	function ready(): Int;
	// Get sound samplerate is Hz
	function getRate(): Int;
	// Get sound channels
	function getChannels(): Int;
    // Set known full file length
    function setSize(size: Int): Void;
	// Get estimated sound length
	function getEtaLength(): Null<Float>;
	// Get loaded sound length
	function getLoadedLength(): Float;
	// Get count of complete samples available
	function samplesAvailable(): Int;
	// Get complete samples as array of channel samples
	function getSamples(): Array<Array<Float>>;
}
